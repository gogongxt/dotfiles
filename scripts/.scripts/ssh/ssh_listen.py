#!/usr/bin/env python3
"""
命令转发服务 - 在 macOS 本地运行，监听端口 7770
接收来自 SSH 远程转发的 shell 命令并执行

用法:
    python3 ssh_listen.py

SSH 端口转发配置 (在远程服务器上):
    ssh -R 7770:localhost:7770 user@remote

协议:
    发送: CMD:<shell命令>
    示例: CMD:open https://github.com
          CMD:bash ~/.scripts/macos/notify.sh -title "Test" -message "Hello"
"""

import os
import socket
import subprocess
import sys
import threading


def handle_client(conn: socket.socket, addr: tuple):
    """处理客户端连接"""
    try:
        data = b""
        while True:
            chunk = conn.recv(1024)
            if not chunk:
                break
            data += chunk

        data_str = data.decode("utf-8").strip()

        if data_str.startswith("CMD:"):
            cmd = data_str[4:]
            # 展开 ~ 为本地 home 目录（处理 \~ 转义形式）
            home = os.path.expanduser("~")
            cmd = cmd.replace("\\~", home)
            print(f"[执行] {cmd}")
            subprocess.run(cmd, shell=True, check=False)
        else:
            print(f"[未知格式] {data_str[:100]}")
    except Exception as e:
        print(f"处理错误: {e}")
    finally:
        conn.close()


def main():
    port = 7770
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind(("localhost", port))
        s.listen(5)
        print(f"命令转发服务运行中，监听端口 {port}...")
        print("按 Ctrl+C 停止")

        while True:
            try:
                conn, addr = s.accept()
                thread = threading.Thread(
                    target=handle_client, args=(conn, addr), daemon=True
                )
                thread.start()
            except Exception as e:
                print(f"接受连接错误: {e}")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n服务已停止")
        sys.exit(0)
    except OSError as e:
        if "Address already in use" in str(e):
            print(f"错误: 端口 7770 已被占用")
            print("可能已有实例在运行，或端口转发已建立")
        else:
            print(f"启动失败: {e}")
        sys.exit(1)
