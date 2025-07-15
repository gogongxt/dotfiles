#!/usr/bin/env python3

import os
import sys
import pexpect
import yaml
import argparse
import shutil
import signal
import fcntl
import termios
import struct
from pathlib import Path
import logging
import subprocess

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
# logging.basicConfig(
#     level=logging.DEBUG,
#     filename='debug.log',      # 日志文件名
#     filemode='w',              # 每次运行都覆盖旧日志
#     format='%(asctime)s - %(levelname)s - %(message)s'
# )
logger = logging.getLogger(__name__)


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


def get_server_details(config_file, server_name, pwd_manager: EnhancedPasswordManager):
    try:
        script_dir = Path(__file__).parent.resolve()
        config_path = script_dir / config_file

        with open(config_path, "r") as f:
            config = yaml.safe_load(f)

        found_server = None
        for server in config.get("servers", []):  # 安全地获取 servers 列表
            if server.get("name") == server_name:
                found_server = server
                break

        if not found_server:
            raise ValueError(f"Server '{server_name}' not found in config")

        auth_details = found_server.get("auth", {})
        details = {
            "host": found_server["host"],
            "ssh_user": found_server["ssh_user"],
            "port": str(found_server.get("port", 22)),
            "username": auth_details.get("username"),
            "password": auth_details.get("password"),
            "username_prompt": auth_details.get("username_prompt", "Username: "),
            "password_prompt": auth_details.get("password_prompt", "Password: "),
        }

        # --- 使用传入的 pwd_manager 进行解密 ---
        encrypted_pass = details.get("password")
        if encrypted_pass:
            print("检测到加密密码，需要输入主密码进行解密...")
            try:
                decrypted_pass = pwd_manager.decrypt_to_real_password(encrypted_pass)
                details["password"] = decrypted_pass
                print("密码解密成功。")
            except Exception as e:
                print(f"密码解密失败: {e}", file=sys.stderr)
                sys.exit(1)

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
    global child
    try:
        cmd = f"ssh -p {server_details['port']} {server_details['ssh_user']}@{server_details['host']}"
        env = os.environ.copy()
        env["TERM"] = "xterm-256color"

        child = pexpect.spawn(cmd, encoding="utf-8", env=env)

        rows, cols = get_terminal_size()
        child.setwinsize(rows, cols)
        signal.signal(signal.SIGWINCH, sigwinch_handler)

        child.logfile_read = sys.stdout

        while True:
            # 在 expect 列表中，确保 "Dkey shield code:" 存在
            index = child.expect(
                [
                    server_details["username_prompt"],  # 0
                    "(?i)" + server_details["password_prompt"],  # 1
                    "Are you sure you want to continue connecting.*",  # 2
                    "(Last login:|[$#>%\\]]\\s*$)",  # 3
                    "Ubuntu comes with ABSOLUTELY NO WARRANTY.*",  # 4
                    "Permission denied",  # 5
                    "Dkey shield code:",  # 6
                    "Luban LES Password:",  # 7
                    "Option>:",  # 8
                    pexpect.TIMEOUT,  # 9
                    pexpect.EOF,  # 10
                ],
                timeout=60,  # 动态口令可能需要更长的等待时间
            )

            # (可选) 打印调试信息
            # print(f"DEBUG: Matched pattern index = {index}", file=sys.stderr)

            if index == 0:  # username prompt
                child.sendline(str(server_details["username"]))
            elif index == 1:  # password prompt
                child.sendline(str(server_details["password"]))
            elif index == 2:  # SSH host verification
                child.sendline("yes")
            elif index in (3, 4):  # successful login patterns
                # print("\n--- Login successful. Entering interactive mode. ---", file=sys.stderr)
                child.logfile_read = None
                child.interact()
                break
            elif index == 5:  # Permission denied
                # print("\nAuthentication failed: Permission denied", file=sys.stderr)
                sys.exit(1)

            # --- 新增的逻辑：处理动态口令 ---
            elif index == 6:  # Matched "Dkey shield code:"
                # print("\n\n--- PLEASE ENTER YOUR DYNAMIC CODE AND PRESS ENTER ---", file=sys.stderr)

                # 暂时关闭日志，避免用户输入时出现奇怪的回显
                child.logfile_read = None

                # 进入交互模式，但设置“回车”为退出字符
                child.interact(escape_character="\r")

                # 用户按下回车后，interact返回，我们立即把回车本身发送给服务器
                # (interact 在退出时不会发送那个退出字符)
                child.sendline("")  # 或者 child.send('\r')

                # print("--- Code sent. Resuming automation... ---\n", file=sys.stderr)

                # 重新开启日志，以便看到后续的自动化过程
                child.logfile_read = sys.stdout

                # 继续下一次循环，等待服务器的新提示（比如 username_prompt）
                continue
            # --- 新逻辑结束 ---

            elif index == 7:  # Special cases like "Luban LES Password:"
                child.sendline(str(server_details["password"]))
            elif index == 8:  # Special cases like "Option>:"
                # print("\n--- Special prompt detected. Handing over to user. ---", file=sys.stderr)
                child.logfile_read = None
                child.interact()
                break
            elif index == 9:  # Timeout
                # print("\nConnection timed out", file=sys.stderr)
                sys.exit(1)
            elif index == 10:  # EOF
                # print("\nConnection closed (EOF)", file=sys.stderr)
                break

    # ... except and finally blocks ...
    except Exception as e:
        print(f"\nAn error occurred: {e}", file=sys.stderr)
    finally:
        signal.signal(signal.SIGWINCH, signal.SIG_DFL)
        if child and child.isalive():
            child.close(force=True)
        print("--- Connection closed. ---", file=sys.stderr)


def main():
    install_required_tools()

    parser = argparse.ArgumentParser(description="集成了密码安全管理的SSH连接工具")
    parser.add_argument(
        "--config", default="servers_password.yaml", help="服务器YAML配置文件路径"
    )
    args = parser.parse_args()

    # --- 初始化密码管理器 ---
    # 路径将与 ssh_login.py 脚本在同一目录
    script_dir = Path(__file__).parent.resolve()
    key_file = script_dir / "encrypted_key.bin"
    salt_file = script_dir / "salt.bin"

    try:
        pwd_manager = EnhancedPasswordManager(
            key_file=str(key_file), salt_file=str(salt_file)
        )
    except Exception as e:
        print(f"初始化密码管理器失败: {e}", file=sys.stderr)
        sys.exit(1)

    server_name = select_server(args.config)
    server_details = get_server_details(args.config, server_name, pwd_manager)
    connect_to_server(server_details)


if __name__ == "__main__":
    main()
