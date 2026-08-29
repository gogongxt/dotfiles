#!/usr/bin/env python3

import argparse
import base64
import fcntl
import importlib.util
import logging
import os
import re
import shutil
import signal
import struct
import subprocess
import sys
import termios
import time
from pathlib import Path

import pexpect

# --- 从 password.py 模块导入需要的类 ---
from password import DEFAULT_KEY_FILE, EnhancedPasswordManager

# ANSI 颜色代码
YELLOW = "\033[33m"
CYAN = "\033[36m"
RESET = "\033[0m"  # 重置颜色

# 真正的 shell 提示符：行尾的 $/#/>/%/]，容忍行尾的 ANSI 颜色码
# （如 ~$<ESC>[00m<空格>）。用于判定登录成功 / shell 就绪。
PROMPT_RE = "[$#>%\\]](\\x1b\\[[0-9;]*m)?\\s*$"

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
    required_tools = ["fzf"]
    missing_tools = []

    for tool in required_tools:
        if not shutil.which(tool):
            missing_tools.append(tool)

    if missing_tools:
        print(f"Please install the following tools first: {', '.join(missing_tools)}")
        sys.exit(1)


def load_config_module(config_file):
    """动态加载 Python 配置文件（servers.py），返回其中的 SERVERS 列表。

    配置文件改为可执行的 Python，便于在其中编写任意匹配逻辑
    （例如把 response 设为 callable，由主程序在运行时调用）。
    """
    script_dir = Path(__file__).parent.resolve()
    config_path = script_dir / config_file

    if not config_path.exists():
        print(f"配置文件不存在: {config_path}")
        sys.exit(1)

    spec = importlib.util.spec_from_file_location("servers_config", config_path)
    config_module = importlib.util.module_from_spec(spec)
    sys.modules["servers_config"] = config_module
    spec.loader.exec_module(config_module)

    return getattr(config_module, "SERVERS", [])


def select_server(config_file):
    try:
        servers = load_config_module(config_file)
        if not servers:
            raise RuntimeError("No servers found in config file")

        # 直接用 Python 列表推导式生成菜单，不再依赖 yq
        server_list = [
            f"{s.get('name', 'Unknown')} ➔ {s.get('ssh_user', 'user')}@{s.get('host', 'ip')}:{s.get('port', 22)}"
            for s in servers
        ]

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

    response 既可能是字符串（明文或加密后的 base64），也可能是函数对象
    （callable(before_text) -> str | None，用于动态解析菜单等）。
    函数对象跳过加密检测与解密。

    Args:
        config_file: 配置文件路径
        server_name: 服务器名称

    Returns:
        dict: 包含服务器连接信息的字典，所有加密字段已解密
    """
    try:
        servers = load_config_module(config_file)

        found_server = None
        for server in servers:
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
                # prompt_interact: 匹配后进入交互模式，无自动响应
                if "prompt_interact" in item:
                    processed_prompts.append(
                        {"prompt": item["prompt_interact"], "interact": True}
                    )
                    continue

                prompt = item.get("prompt", "")
                response = item.get("response", "")

                # response 是函数时，跳过加密检测/解密，交给主程序运行时调用
                if (
                    isinstance(response, str)
                    and response
                    and is_encrypted_password(response)
                ):
                    if pwd_manager is None:
                        # logger.debug("检测到加密字段，使用本地密钥文件解密...")
                        pwd_manager = EnhancedPasswordManager(key_file=DEFAULT_KEY_FILE)
                    try:
                        response = pwd_manager.decrypt_to_real_password(response)
                    except Exception as e:
                        print(f"字段解密失败 ({prompt}): {e}", file=sys.stderr)
                        sys.exit(1)

                processed_prompts.append(
                    {"prompt": prompt, "response": response, "interact": False}
                )

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


def connect_to_server(
    server_details,
    auto_command=None,
    interact_cmd=None,
):
    """
    连接服务器并完成动态认证。

    Args:
        server_details: 含 auth_prompts 的连接信息
        auto_command: 非交互模式——登录后执行该命令并流式输出，结束即退出
        interact_cmd: 交互模式——登录后先发该命令（如 `dssh <host>` 跳板）再 interact
    """
    global child
    try:
        cmd = f"ssh {server_details['add']} -p {server_details['port']} {server_details['ssh_user']}@{server_details['host']}"
        if auto_command is None:
            print(cmd)
        env = os.environ.copy()
        env["TERM"] = "xterm-256color"

        child = pexpect.spawn(cmd, encoding="utf-8", env=env)

        rows, cols = get_terminal_size()
        child.setwinsize(rows, cols)
        signal.signal(signal.SIGWINCH, sigwinch_handler)

        # -c（auto_command）即非交互机器模式：整条链路都不透传到 stdout。
        machine_mode = auto_command is not None
        child.logfile_read = None if machine_mode else sys.stdout

        # 获取认证提示列表
        auth_prompts = server_details.get("auth_prompts", [])

        # 定义系统提示模式及其处理函数
        def handle_ssh_host_verification():
            child.sendline("yes")

        def handle_successful_login():
            # 匹配到的是 Last login:/Ubuntu 横幅而非真提示符时，说明 MOTD 还在刷屏、
            # shell 未就绪；立刻 sendline 会被 pty 换行回显破坏。先等真提示符。
            if str(child.after) == "Last login:" or str(child.after).startswith(
                "Ubuntu comes with ABSOLUTELY NO WARRANTY"
            ):
                try:
                    child.expect([PROMPT_RE, pexpect.TIMEOUT], timeout=1.0)
                except pexpect.EOF:
                    pass

            # 跳板模式：先发跳转命令（如 `dssh <host>`）再 interact，落到目标机 shell。
            if interact_cmd:
                time.sleep(0.5)
                # interact 前必须关掉 logfile_read（encoding=utf-8 下会 bytes 报错）。
                child.logfile_read = None
                child.sendline(interact_cmd)
                child.interact()
                return "break"
            if auto_command:
                time.sleep(0.5)
                child.logfile_read = None
                # 机器模式：先把提示符覆盖为一个唯一的字面量标记，再 expect 该标记来
                # 丢弃 `stty -echo` 的回显、旧提示符和换行噪声。不能靠 PROMPT_RE 匹配
                # 真实提示符——有的 bashrc 会在 `$` 后追加时间戳（如 `Thu Aug 13 ...`），
                # 行尾锚定的 PROMPT_RE 匹配不上便会超时，导致 stty 回显 + 整个转义提示符
                # 泄漏进命令输出（见制造集成观测到的噪声）。覆盖 PS1 后标记是唯一的，
                # expect 精确命中，无论 bashrc 装饰成什么样都能清干净。
                ready = f"__CP_MYSSH_READY_{os.urandom(8).hex()}__"
                # PS1 就是标记本身（不带尾随空格），expect 命中即把整个“就绪提示符”连同
                # 之前的 stty 回显、旧提示符、OSC 标题、颜色码一起清掉，不留任何残留。
                child.sendline(f"stty -echo; PS1='{ready}'; PS2=''; echo {ready}")
                try:
                    child.expect(ready, timeout=10)
                except (pexpect.TIMEOUT, pexpect.EOF):
                    pass  # 朴素防御：即使标记未打印，也继续（输出可能带一点噪声）

                # `; exit` 退不回堡垒机菜单，改用随机哨兵标记命令结束，命中即退出。
                # 哨兵后紧跟 $?：PTY 链路上读不到远端进程的真实退出码，哨兵随
                # stdout 回传是唯一可靠通道，myssh 以该码退出，调用方（面板
                # exec/runs/SSE）才能据此判定命令成败。
                #
                # 哨兵来源两种：
                # - MYSSH_SENTINEL 环境变量（面板注入）：命令里已嵌好
                #   「<cmd>; echo <哨兵>$?」且位于跳板模板内侧——echo 在最终机器
                #   上执行，退出码随 stdout 流回。dssh 这类中转会把非零退出码
                #   坍缩成 1，落地层追加 echo 的 $? 拿不到真实值，所以这里只负责
                #   检测哨兵、解析随行数字，不再自行追加。
                # - 无环境变量（人工直连）：在本层 shell 追加 echo，$? 即命令
                #   退出码（直连场景没有中转坍缩问题）。
                sentinel = os.environ.get("MYSSH_SENTINEL") or None
                if sentinel:
                    child.sendline(auto_command)
                else:
                    sentinel = f"___MYSSH_DONE_{os.urandom(8).hex()}___"
                    child.sendline(f"{auto_command}; echo {sentinel}$?")

                def held_len(s):
                    # 哨兵可能被拆在两次 read 之间：只需扣住「恰好是哨兵前缀」的
                    # 结尾后缀，其余全部立刻输出（固定扣 len-1 会把短输出憋到下一段）。
                    return max(
                        (
                            k
                            for k in range(min(len(s), len(sentinel) - 1), 0, -1)
                            if s.endswith(sentinel[:k])
                        ),
                        default=0,
                    )

                tail = ""
                rc_text = ""  # 哨兵之后的内容：开头是退出码数字（可能拆包未到齐）
                while True:
                    try:
                        data = child.read_nonblocking(size=65536, timeout=1.0)
                    except pexpect.TIMEOUT:
                        continue
                    except pexpect.EOF:
                        break
                    if not data:
                        continue
                    chunk = tail + data
                    # 哨兵含随机 hex、全文只出现一次；用最右匹配，避免把结尾
                    # 恰好是哨兵前缀（如 '___'）的正文吃进哨兵。
                    i = chunk.rfind(sentinel)
                    if i >= 0:
                        sys.stdout.write(chunk[:i])  # 哨兵之后是噪声
                        sys.stdout.flush()
                        # 退出码数字可能拆在下一段 read 才到；echo 的输出必然是
                        # 「数字+换行」，攒到出现行尾即齐（EOF/超时就用现有内容）。
                        rc_text = chunk[i + len(sentinel) :]
                        for _ in range(3):
                            if re.search(r"[\r\n]", rc_text):
                                break
                            try:
                                rc_text += child.read_nonblocking(
                                    size=4096, timeout=1.0
                                )
                            except (pexpect.TIMEOUT, pexpect.EOF):
                                break
                        break
                    keep = held_len(chunk)
                    tail = chunk[len(chunk) - keep :] if keep else ""
                    if keep < len(chunk):
                        sys.stdout.write(chunk[: len(chunk) - keep])
                        sys.stdout.flush()
                # 以远端命令的退出码退出（& 0xFF 防御异常值）。哨兵未出现（EOF，
                # 会话中途断掉）时退出码不可知，维持旧行为退出 0。
                m = re.match(r"\d+", rc_text)
                sys.exit(int(m.group()) & 0xFF if m else 0)
            else:
                child.logfile_read = None
                child.interact()
            return "break"

        def handle_permission_denied():
            sys.exit(1)

        def handle_dynamic_code():
            # 暂时关闭日志，避免用户输入时出现奇怪的回显
            child.logfile_read = None
            # 进入交互模式，设置"回车"为退出字符
            child.interact(escape_character="\r")
            # 用户按下回车后，发送回车给服务器
            child.sendline("")
            # 重新开启日志
            child.logfile_read = sys.stdout
            # 继续下一次循环，等待下一个提示
            return "continue"

        def handle_timeout():
            sys.exit(1)

        def handle_eof():
            return "break"

        # 系统模式列表：(模式, 处理函数)
        system_patterns = [
            (
                "Are you sure you want to continue connecting.*",
                handle_ssh_host_verification,
            ),
            # 真正的 shell 提示符（容忍行尾 ANSI 颜色码），或 Last login: 登录横幅。
            # Last login: 只代表登录开始，MOTD 还在刷屏、shell 未就绪 ——
            # handle_successful_login 里会先等提示符 / 输出静默再发命令。
            ("(Last login:[^\r\n]*|" + PROMPT_RE + ")", handle_successful_login),
            ("Ubuntu comes with ABSOLUTELY NO WARRANTY.*", handle_successful_login),
            ("Permission denied", handle_permission_denied),
            ("Dkey shield code:", handle_dynamic_code),
            (pexpect.TIMEOUT, handle_timeout),
            (pexpect.EOF, handle_eof),
        ]

        while True:
            # 构建 expect 列表：
            # 1. 所有配置的认证提示
            # 2. 固定的系统提示（SSH 验证、登录成功、错误等）
            # 3. 特殊交互提示（动态口令等）
            expect_patterns = [p["prompt"] for p in auth_prompts]
            auth_count = len(expect_patterns)  # 记录认证提示的数量

            # 添加系统模式
            for pattern, _ in system_patterns:
                expect_patterns.append(pattern)

            index = child.expect(expect_patterns, timeout=60)

            # 处理认证提示（动态部分）
            if index < auth_count:
                matched = auth_prompts[index]
                if matched.get("interact"):
                    result = handle_dynamic_code()
                    if result == "break":
                        break
                    elif result == "continue":
                        continue
                else:
                    response_val = matched["response"]

                    # response 为函数（callable）：传入 child.before 供其解析，
                    # 返回非空字符串则发送；返回 None 则降级为手动交互
                    if callable(response_val):
                        dynamic_response = response_val(child.before)
                        if dynamic_response is not None:
                            child.sendline(str(dynamic_response))
                        else:
                            # 机器模式（-c）下无法回退到真人交互：返回 None 只能
                            # 快速失败，让后端知道「登录失败」而不是卡死等输入。
                            if machine_mode:
                                print(
                                    "\n[自定义函数返回空] 机器模式无法交互，登录失败",
                                    file=sys.stderr,
                                )
                                sys.exit(1)
                            print("\n[自定义函数返回空] 转为手动模式处理。")
                            child.interact(escape_character="\r")
                            child.sendline("")
                    else:
                        child.sendline(str(response_val))

            # 处理系统提示
            else:
                system_index = index - auth_count
                pattern, handler = system_patterns[system_index]
                result = handler()
                if result == "break":
                    break
                elif result == "continue":
                    continue

    except Exception as e:
        print(f"\\nAn error occurred: {e}", file=sys.stderr)
    finally:
        signal.signal(signal.SIGWINCH, signal.SIG_DFL)
        if child and child.isalive():
            child.close(force=True)


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
        default="servers.py",
        help="服务器配置文件路径（可执行的 Python 模块，需暴露 SERVERS 列表）",
    )
    parser.add_argument(
        "-c",
        "--command",
        default=None,
        help="SSH连接成功后自动执行的命令，执行完成后会退出myssh",
    )
    parser.add_argument(
        "--interact-cmd",
        default=None,
        help="和-c/--command类似，不过执行完成后不退出myssh，留在交互模式，适用于执行命令还需要手动执行别的",
    )
    args = parser.parse_args()

    config_file = args.config
    server_name = args.server

    # -c（command）即非交互机器模式：抑制所有 chatter。
    machine_mode = args.command is not None

    if not machine_mode and server_name:
        print(f"参数指定服务器: {server_name}")
    elif server_name is None and not machine_mode:
        server_name = select_server(config_file)
        if not server_name:
            print("未选择任何服务器，程序退出。")
            sys.exit(0)

    if not machine_mode:
        print(f"正在获取 '{server_name}' 的详细信息...")
    server_details = get_server_details(config_file, server_name)
    connect_to_server(
        server_details,
        args.command,
        interact_cmd=args.interact_cmd,
    )


if __name__ == "__main__":
    main()
