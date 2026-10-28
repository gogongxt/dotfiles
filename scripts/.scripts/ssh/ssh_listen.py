#!/usr/bin/env python3
r"""
命令转发服务 (HTTP) - 在 macOS 本地运行，监听端口 7770
接收来自 SSH 远程转发的通知/命令请求并执行

用法:
    python3 ssh_listen.py
    端口可用 SSH_LISTEN_PORT 环境变量覆盖 (仅测试用)

SSH 端口转发配置 (在远程服务器上):
    ssh -R 7770:localhost:7770 user@remote

HTTP API (请求体 JSON, 认证头 Authorization: Bearer <token>):
    GET  /health                 探活, 无需认证
    POST /exec    {cmd: "..."}   执行 shell 命令 (\~ 展开为 home)

    响应: 200 {"ok": true, "rc": 0, "stdout": "...", "stderr": "..."}
          400 参数错误 / 401 认证失败 / 404 未知路径
          413 请求体超长 / 504 命令超时 / 503 并发忙

curl 示例:
    curl -s -H "Authorization: Bearer $(cat ssh_listen_token)" \
         -d '{"cmd":"open https://github.com"}' \
         http://localhost:7770/exec

token 保存在脚本同目录的 ssh_listen_token (首次运行自动生成, 可自行替换);
所有连接与执行记录写入同目录的 ssh_listen_audit.log
"""

import hmac
import json
import os
import secrets
import socket
import subprocess
import sys
import threading
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse

PORT = int(os.environ.get("SSH_LISTEN_PORT", "7770"))
MAX_BODY = 64 * 1024    # 请求体最大字节数
CMD_TIMEOUT = 60        # 命令执行超时秒数
MAX_WORKERS = 8         # 最大并发执行数

# realpath: 通过 stow 软链 (~/.scripts/ssh) 启动时, token/日志仍落在仓库目录
BASE_DIR = os.path.dirname(os.path.realpath(__file__))
TOKEN_PATH = os.path.join(BASE_DIR, "ssh_listen_token")
AUDIT_PATH = os.path.join(BASE_DIR, "ssh_listen_audit.log")

TOKEN = ""
_audit_lock = threading.Lock()
_exec_slots = threading.BoundedSemaphore(MAX_WORKERS)


def load_token() -> str:
    """读取 token, 文件不存在时自动生成"""
    if not os.path.exists(TOKEN_PATH):
        with open(TOKEN_PATH, "w") as f:
            f.write(secrets.token_urlsafe(32) + "\n")
        os.chmod(TOKEN_PATH, 0o600)
        print(f"[初始化] 已生成 token 文件: {TOKEN_PATH}")
    if os.stat(TOKEN_PATH).st_mode & 0o077:
        print(f"[警告] {TOKEN_PATH} 权限过宽, 建议 chmod 600")
    with open(TOKEN_PATH) as f:
        token = f.read().strip()
    if not token:
        sys.exit(f"错误: token 文件为空: {TOKEN_PATH}")
    return token


def audit(event: str, peer: str, detail: str = ""):
    """追加一行审计日志 (线程安全)"""
    detail = str(detail).replace("\n", "\\n")[:500]
    line = f"{datetime.now():%Y-%m-%d %H:%M:%S} [{event}] {peer} {detail}".rstrip()
    with _audit_lock:
        with open(AUDIT_PATH, "a", encoding="utf-8") as f:
            f.write(line + "\n")


class Handler(BaseHTTPRequestHandler):
    server_version = "ssh_listen/2.0"
    sys_version = ""  # 响应头不暴露 Python 版本
    timeout = 30  # 空闲/慢连接保护

    def log_message(self, fmt, *args):
        pass  # 访问日志由 audit() 记录

    # ---------- 基础工具 ----------

    @property
    def peer(self) -> str:
        host, port = self.client_address[:2]
        return f"{host}:{port}"

    def send_json(self, code: int, obj: dict):
        data = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def authorized(self) -> bool:
        auth = self.headers.get("Authorization", "").strip()
        return hmac.compare_digest(auth.encode(), f"Bearer {TOKEN}".encode())

    def read_json(self):
        """读取并解析请求体, 失败时已发送错误响应并返回 None"""
        if self.headers.get("Transfer-Encoding"):
            self.close_connection = True
            self.send_json(400, {"ok": False, "error": "chunked not supported"})
            return None
        try:
            length = int(self.headers.get("Content-Length", ""))
        except ValueError:
            self.close_connection = True
            self.send_json(400, {"ok": False, "error": "Content-Length required"})
            return None
        if length > MAX_BODY:
            self.close_connection = True
            audit("TOO_LARGE", self.peer, f"length={length}")
            self.send_json(413, {"ok": False, "error": "body too large"})
            return None
        try:
            body = json.loads(self.rfile.read(length).decode("utf-8"))
        except (ValueError, UnicodeDecodeError):
            audit("BAD_JSON", self.peer)
            self.send_json(400, {"ok": False, "error": "invalid json"})
            return None
        if not isinstance(body, dict):
            self.send_json(400, {"ok": False, "error": "json object required"})
            return None
        return body

    def run_cmd(self, cmd: str, event: str, detail: str):
        """带并发限制与超时执行 shell 命令; 失败时已发送错误响应并返回 None"""
        if not _exec_slots.acquire(blocking=False):
            audit("BUSY", self.peer, event)
            self.send_json(503, {"ok": False, "error": "busy"})
            return None
        try:
            return subprocess.run(
                cmd, shell=True, check=False, timeout=CMD_TIMEOUT,
                capture_output=True, text=True, errors="replace",
            )
        except subprocess.TimeoutExpired:
            audit("CMD_TIMEOUT", self.peer, detail)
            self.send_json(504, {"ok": False, "error": "cmd timeout"})
            return None
        except OSError as e:
            audit("ERROR", self.peer, f"{event} {e}")
            self.send_json(500, {"ok": False, "error": str(e)})
            return None
        finally:
            _exec_slots.release()

    # ---------- 路由 ----------

    def do_GET(self):
        if urlparse(self.path).path == "/health":
            self.send_json(200, {"ok": True})
        else:
            self.send_json(404, {"ok": False, "error": "not found"})

    def do_POST(self):
        try:
            self._dispatch_post()
        except (socket.timeout, TimeoutError):
            self.close_connection = True
            audit("CONN_TIMEOUT", self.peer)
        except (BrokenPipeError, ConnectionResetError):
            self.close_connection = True  # 客户端提前断开, 无需处理

    def _dispatch_post(self):
        path = urlparse(self.path).path
        if not self.authorized():
            # 未认证请求不读请求体, 直接断开
            self.close_connection = True
            print(f"[拒绝] 认证失败 {self.peer} {path}")
            audit("AUTH_FAIL", self.peer, path)
            self.send_json(401, {"ok": False, "error": "auth"})
            return
        body = self.read_json()
        if body is None:
            return
        if path == "/exec":
            self.handle_exec(body)
        else:
            audit("NOT_FOUND", self.peer, path)
            self.send_json(404, {"ok": False, "error": "not found"})

    # ---------- 各端点 ----------

    def handle_exec(self, body: dict):
        cmd = body.get("cmd")
        if not isinstance(cmd, str) or not cmd.strip():
            self.send_json(
                400, {"ok": False, "error": "field cmd must be non-empty str"}
            )
            return
        # 展开 ~ 为本地 home 目录（处理 \~ 转义形式）
        cmd = cmd.replace("\\~", os.path.expanduser("~"))
        print(f"[执行] {cmd[:100]}")
        result = self.run_cmd(cmd, event="EXEC", detail=cmd)
        if result is None:
            return
        audit("EXEC", self.peer, f"rc={result.returncode} {cmd}")
        self.send_json(200, {
            "ok": True,
            "rc": result.returncode,
            "stdout": result.stdout[-2000:],
            "stderr": result.stderr[-2000:],
        })


def main():
    global TOKEN
    TOKEN = load_token()
    server = ThreadingHTTPServer(("localhost", PORT), Handler)
    print(f"命令转发服务(HTTP)运行中，监听端口 {PORT}...")
    print("接口: GET /health | POST /exec  (Bearer token 认证)")
    print("按 Ctrl+C 停止")
    try:
        server.serve_forever()
    finally:
        server.server_close()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n服务已停止")
        sys.exit(0)
    except OSError as e:
        if "Address already in use" in str(e):
            print(f"错误: 端口 {PORT} 已被占用")
            print("可能已有实例在运行，或端口转发已建立")
        else:
            print(f"启动失败: {e}")
        sys.exit(1)
