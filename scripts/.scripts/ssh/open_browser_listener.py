#!/usr/bin/env python3
"""
通知转发服务 - 在 macOS 本地运行，监听端口 7770
接收来自 SSH 远程转发的通知请求并显示 macOS 通知

用法:
    python3 notification_forwarder.py

SSH 端口转发配置 (在远程服务器上):
    ssh -R 7770:localhost:7770 user@remote
"""

import json
import socket
import subprocess
import sys
import threading


def show_macos_notification(title: str, subtitle: str, message: str, sound: str):
    """使用 terminal-notifier 显示 macOS 通知"""
    cmd = [
        "terminal-notifier",
        "-title",
        title,
        "-subtitle",
        subtitle,
        "-message",
        message,
        "-sound",
        sound,
        "-group",
        "com.claudecode.notification",
    ]
    try:
        subprocess.run(cmd, check=False)
    except FileNotFoundError:
        print("错误: terminal-notifier 未安装，请运行: brew install terminal-notifier")
    except Exception as e:
        print(f"通知发送失败: {e}")


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

        if data_str.startswith("NOTIFY:"):
            payload_str = data_str[7:]  # 去掉 "NOTIFY:" 前缀
            try:
                payload = json.loads(payload_str)
                title = payload.get("title", "Claude Code")
                subtitle = payload.get("subtitle", "")
                message = payload.get("message", "")
                sound = payload.get("sound", "Glass")

                print(f"[通知] {title}: {message[:50]}...")
                show_macos_notification(title, subtitle, message, sound)
            except json.JSONDecodeError as e:
                print(f"JSON 解析失败: {e}")
        elif data_str.startswith("http"):
            # 兼容原有的浏览器打开功能
            print(f"打开: {data_str}")
            import webbrowser

            webbrowser.open(data_str)
        else:
            print(f"未知消息: {data_str[:100]}")
    except Exception as e:
        print(f"处理连接错误: {e}")
    finally:
        conn.close()


def notification_listener(port: int = 7770):
    """监听端口，接收通知请求"""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind(("localhost", port))
        s.listen(5)
        print(f"通知转发服务运行中，监听端口 {port}...")
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


def main():
    try:
        notification_listener()
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


if __name__ == "__main__":
    main()
