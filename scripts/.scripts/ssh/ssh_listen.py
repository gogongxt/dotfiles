#!/usr/bin/env python3
"""
通知转发服务 - 在 macOS 本地运行，监听端口 7770
接收来自 SSH 远程转发的请求：
    - 打开网页链接
    - 显示消息通知

用法:
    python3 ssh_forward.py

SSH 端口转发配置 (在远程服务器上):
    ssh -R 7770:localhost:7770 user@remote
"""

import json
import os
import socket
import subprocess
import sys
import threading

# 通用通知脚本路径
NOTIFY_SCRIPT = os.path.expanduser("~/.scripts/macos/notify.sh")


def show_macos_notification(payload: dict):
    """使用通用通知脚本显示 macOS 通知"""
    # 处理 contentImage 路径：将远程路径转换为本地路径
    # 常见模式：将任何用户的 .claude 目录映射到本地
    local_home = os.path.expanduser("~")
    if "contentImage" in payload:
        img_path = payload["contentImage"]
        # 提取相对路径部分（如 .claude/claude.webp）
        if "/.claude/" in img_path:
            rel_path = img_path.split("/.claude/")[1]
            payload["contentImage"] = f"{local_home}/.claude/{rel_path}"
        elif img_path.startswith("~/.claude/"):
            rel_path = img_path[len("~/.claude/") :]
            payload["contentImage"] = f"{local_home}/.claude/{rel_path}"

    # 调用通用脚本，传递所有参数
    cmd = [NOTIFY_SCRIPT]
    for key, value in payload.items():
        if value is None or value is False:
            continue
        if value is True:
            cmd.append(f"-{key}")
        else:
            cmd.extend([f"-{key}", str(value)])

    try:
        subprocess.run(cmd, check=False)
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
                # 清理 null 值
                payload = {
                    k: v for k, v in payload.items() if v is not None and v != ""
                }
                # 设置默认值
                payload.setdefault("title", "Unknown")
                payload.setdefault("sound", "Glass")
                print(
                    f"[通知] {payload.get('title', '')}: {payload.get('message', '')[:50]}..."
                )
                show_macos_notification(payload)
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
