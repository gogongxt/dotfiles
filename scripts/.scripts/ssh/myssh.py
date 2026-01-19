#!/usr/bin/env python3

import argparse
import base64
import fcntl
import logging
import os
import re
import shutil
import signal
import struct
import subprocess
import sys
import termios
from pathlib import Path

import pexpect
import yaml

# --- 从 password.py 模块导入需要的类 ---
from password import EnhancedPasswordManager

# ANSI 颜色代码
YELLOW = "\033[33m"
CYAN = "\033[36m"
RESET = "\033[0m"  # 重置颜色

# 基本配置
logging.basicConfig(
    level=logging.DEBUG,
    format=f"{YELLOW}%(filename)s{CYAN}:%(lineno)d{RESET} - %(message)s",
)
logger = logging.getLogger(__name__)


def is_encrypted_password(password_str):
    """
    检测密码是否为加密格式。

    加密密码特征：
    1. 使用 base64.urlsafe_b64encode() 编码
    2. 包含 IV(16字节) + 加密数据(至少16字节) = 至少32字节
    3. Base64 编码后长度 >= 44 字符 (32 * 4/3，向上取整到4的倍数)
    4. 只包含 Base64 字符 (a-zA-Z0-9_-) 和可能的填充 (=)
    5. 通常以 = 或 == 结尾（Base64 填充）

    Args:
        password_str: 要检测的密码字符串

    Returns:
        bool: 如果是加密密码返回 True，否则返回 False
    """
    if not password_str or not isinstance(password_str, str):
        return False

    # 检查长度：加密密码通常至少 44 个字符
    if len(password_str) < 44:
        return False

    # 检查是否为有效的 Base64 字符（包括 URL-safe 的 - 和 _）
    # 同时允许末尾有 = 填充
    base64_pattern = r"^[A-Za-z0-9_-]+={0,2}$"
    if not re.match(base64_pattern, password_str):
        return False

    # 尝试 Base64 解码验证
    try:
        decoded = base64.urlsafe_b64decode(password_str)
        # 解码后长度应该至少是 32 字节 (16字节IV + 至少16字节加密数据)
        # 并且是 16 的倍数（AES 块大小）
        if len(decoded) >= 32 and len(decoded) % 16 == 0:
            return True
    except Exception:
        return False

    return False


def install_required_tools():
    required_tools = ["yq", "fzf"]
    missing_tools = []

    for tool in required_tools:
        if not shutil.which(tool):
            missing_tools.append(tool)

    if missing_tools:
        print(f"Please install the following tools first: {', '.join(missing_tools)}")
        sys.exit(1)


def select_server(config_file):
    try:
        script_dir = Path(__file__).parent.resolve()
        config_path = script_dir / config_file

        cmd = [
            "yq",
            "e",
            '.servers[] | .name + " ➔ " + .ssh_user + "@" + .host + ":" + (.port|tostring)',
            str(config_path),
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            raise RuntimeError(f"yq command failed: {result.stderr}")

        server_list = result.stdout.strip().split("\n")

        if not server_list or server_list == [""]:
            raise RuntimeError("No servers found in config file")

        fzf_cmd = ["fzf", "--height", "40%", "--prompt=Select server: ", "--no-preview"]
        with subprocess.Popen(
            fzf_cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        ) as proc:
            proc.stdin.write("\n".join(server_list))
            proc.stdin.close()
            selected = proc.stdout.read().strip()
            err = proc.stderr.read().strip()

            if err:
                logger.debug(f"fzf stderr: {err}")

            if not selected:
                print("No server selected. Exiting.")
                sys.exit(0)

            return selected.split(" ➔ ")[0]

    except Exception as e:
        print(f"Error selecting server: {e}")
        sys.exit(1)


def get_server_details(config_file, server_name):
    """
    获取服务器详情，智能识别并解密加密字段。

    Args:
        config_file: 配置文件路径
        server_name: 服务器名称

    Returns:
        dict: 包含服务器连接信息的字典，所有加密字段已解密
    """
    try:
        script_dir = Path(__file__).parent.resolve()
        config_path = script_dir / config_file

        with open(config_path, "r") as f:
            config = yaml.safe_load(f)

        found_server = None
        for server in config.get("servers", []):
            if server.get("name") == server_name:
                found_server = server
                break

        if not found_server:
            raise ValueError(f"Server '{server_name}' not found in config")

        # 获取认证提示列表（auth 字段直接是列表）
        prompts = found_server.get("auth", [])

        # 智能检测并解密加密字段
        processed_prompts = []
        if prompts:
            pwd_manager = None
            for item in prompts:
                prompt = item.get("prompt", "")
                response = item.get("response", "")

                # 自动检测并解密加密字段
                if response and is_encrypted_password(response):
                    if pwd_manager is None:
                        logger.debug("检测到加密字段，需要输入主密码进行解密...")
                        key_file = script_dir / "encrypted_key.bin"
                        salt_file = script_dir / "salt.bin"
                        pwd_manager = EnhancedPasswordManager(
                            key_file=str(key_file), salt_file=str(salt_file)
                        )
                    try:
                        response = pwd_manager.decrypt_to_real_password(response)
                        print(f"字段解密成功: {prompt}")
                    except Exception as e:
                        print(f"字段解密失败 ({prompt}): {e}", file=sys.stderr)
                        sys.exit(1)

                processed_prompts.append({"prompt": prompt, "response": response})

        details = {
            "host": found_server["host"],
            "ssh_user": found_server["ssh_user"],
            "port": str(found_server.get("port", 22)),
            "add": found_server.get("add", ""),
            "auth_prompts": processed_prompts,
        }

        return details
    except KeyError as e:
        raise ValueError(f"配置错误: 服务器 '{server_name}' 缺少必需的键 '{e.args[0]}'")
    except Exception as e:
        print(f"Error getting server details: {e}")
        sys.exit(1)


def get_terminal_size():
    try:
        # 获取终端大小
        h, w, hp, wp = struct.unpack(
            "HHHH", fcntl.ioctl(0, termios.TIOCGWINSZ, struct.pack("HHHH", 0, 0, 0, 0))
        )
        return h, w
    except:
        return 24, 80  # 默认值


def sigwinch_handler(signum, frame):
    global child
    if child and child.isalive():
        rows, cols = get_terminal_size()
        child.setwinsize(rows, cols)


def connect_to_server(server_details):
    """
    连接到服务器，支持动态认证提示列表。

    Args:
        server_details: 包含服务器连接信息的字典，包括 auth_prompts 列表
    """
    global child
    try:
        cmd = f"ssh {server_details['add']} -p {server_details['port']} {server_details['ssh_user']}@{server_details['host']}"
        env = os.environ.copy()
        env["TERM"] = "xterm-256color"

        child = pexpect.spawn(cmd, encoding="utf-8", env=env)

        rows, cols = get_terminal_size()
        child.setwinsize(rows, cols)
        signal.signal(signal.SIGWINCH, sigwinch_handler)

        child.logfile_read = sys.stdout

        # 获取认证提示列表
        auth_prompts = server_details.get("auth_prompts", [])

        while True:
            # 构建 expect 列表：
            # 1. 所有配置的认证提示
            # 2. 固定的系统提示（SSH 验证、登录成功、错误等）
            # 3. 特殊交互提示（动态口令等）
            expect_patterns = [p["prompt"] for p in auth_prompts]
            base_index = len(expect_patterns)  # 记录认证提示的数量

            # 添加固定模式
            expect_patterns.extend(
                [
                    "Are you sure you want to continue connecting.*",  # base_index + 0: SSH host verification
                    "(Last login:|[$#>%\\]]\\s*$)",  # base_index + 1: successful login
                    "Ubuntu comes with ABSOLUTELY NO WARRANTY.*",  # base_index + 2: successful login
                    "Permission denied",  # base_index + 3: auth failed
                    "Dkey shield code:",  # base_index + 4: dynamic code
                    "Option>:",  # base_index + 5: special prompt
                    pexpect.TIMEOUT,  # base_index + 6
                    pexpect.EOF,  # base_index + 7
                ]
            )

            index = child.expect(expect_patterns, timeout=60)

            # 处理认证提示（动态部分）
            if index < base_index:
                # 匹配到某个配置的认证提示
                child.sendline(str(auth_prompts[index]["response"]))

            # 处理固定的系统提示
            elif index == base_index + 0:  # SSH host verification
                child.sendline("yes")

            elif index in (base_index + 1, base_index + 2):  # successful login
                child.logfile_read = None
                child.interact()
                break

            elif index == base_index + 3:  # Permission denied
                sys.exit(1)

            elif index == base_index + 4:  # Dkey shield code (动态口令)
                # 暂时关闭日志，避免用户输入时出现奇怪的回显
                child.logfile_read = None

                # 进入交互模式，设置"回车"为退出字符
                child.interact(escape_character="\r")

                # 用户按下回车后，发送回车给服务器
                child.sendline("")

                # 重新开启日志
                child.logfile_read = sys.stdout

                # 继续下一次循环，等待下一个提示
                continue

            elif index == base_index + 5:  # Special prompt like "Option>:"
                child.sendline("3")
                child.logfile_read = None
                child.interact()
                break

            elif index == base_index + 6:  # Timeout
                sys.exit(1)

            elif index == base_index + 7:  # EOF
                break

    except Exception as e:
        print(f"\\nAn error occurred: {e}", file=sys.stderr)
    finally:
        signal.signal(signal.SIGWINCH, signal.SIG_DFL)
        if child and child.isalive():
            child.close(force=True)
        print("--- Connection closed. ---", file=sys.stderr)


def main():
    """主函数，解析参数并启动连接。"""
    install_required_tools()

    parser = argparse.ArgumentParser(description="集成了密码安全管理的SSH连接工具")
    parser.add_argument(
        "server",
        nargs="?",
        default=None,
        help="要直接连接的服务器名称 (在YAML文件中定义)",
    )
    parser.add_argument(
        "--config",
        default="servers.yaml",
        help="服务器YAML配置文件路径",
    )
    args = parser.parse_args()

    config_file = args.config
    server_name = args.server

    if server_name:
        print(f"参数指定服务器: {server_name}")
    else:
        server_name = select_server(config_file)
        if not server_name:
            print("未选择任何服务器，程序退出。")
            sys.exit(0)

    print(f"正在获取 '{server_name}' 的详细信息...")
    server_details = get_server_details(config_file, server_name)
    connect_to_server(server_details)


if __name__ == "__main__":
    main()
