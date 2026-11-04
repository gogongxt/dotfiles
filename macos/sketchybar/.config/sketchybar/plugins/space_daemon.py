#!/usr/bin/env python3
"""常驻 space/窗口图标守护进程。

取代旧的「每个 sketchybar 事件 spawn 一次 python」模式（每次事件 ~150ms
全是进程创建开销，桌面重排等事件风暴会排队把 bar 拖卡）。本进程常驻：

- 直连 yabai unix socket（/tmp/yabai_$USER.socket）。报文格式与 yabai CLI
  客户端一致：int32 长度前缀(小端) + NUL 分隔参数 + 双 NUL 结尾。注意：
  必须带长度前缀，裸 JSON 会被当成长度解析直接把 yabai 打崩。
  单次查询 ~6ms，不 spawn 进程。
- yabai signal（space_changed / window_* / display_* 等）直接 SIGUSR1 唤醒
  本进程——yabai 是切换的执行者，信号零延迟；yabai 重启后自动补注册。
- sketchybar 的 space_change / space_windows_change / display_change 事件
  通过 space_nudge.sh 再发一次 SIGUSR1 作冗余唤醒。
- 另外每 POLL_INTERVAL 秒兜底轮询一次：漏信号、后台 space 的窗口增删、
  最小化等也能在轮询里被修正（准确率优先）。
- 内存中保存上次渲染状态，diff 后仅在变化时把全部命令合并成一条链式
  sketchybar 调用（实测链中单条失败不中断整条链）。

生命周期：sketchybarrc 每次加载都会 pkill 旧实例再启动新实例，因此重启
后通过 --query win.<sid> 重新种子化 item 状态，避免 --add 撞已存在的名字。
"""

import atexit
import json
import os
import select
import signal
import socket
import struct
import subprocess
import sys
import time
from typing import Any, Dict, List, Optional, Set

USER = os.environ.get("USER", "")
YABAI_SOCKET = f"/tmp/yabai_{USER}.socket"
SKETCHYBAR = "/opt/homebrew/bin/sketchybar"
PIDFILE = f"/tmp/space_daemon_{os.getuid()}.pid"
DEBUG = bool(os.environ.get("DEBUG"))

SPACE_POS = os.environ.get("SPACE_POS", "left")
TOTAL_SPACES = 15  # sketchybarrc N=15
POLL_INTERVAL = 1.0  # 兜底轮询间隔（yabai signal / sketchybar 事件唤醒不受此限制）
QUERY_TIMEOUT = 2.0
SIGNAL_REREGISTER = 60.0  # yabai 重启会清空 signal，定期补注册

# yabai signal 事件集：切换/窗口增删移动最小化/显示器变化/调度中心
SIGNAL_EVENTS = [
    "space_changed",
    "window_created",
    "window_destroyed",
    "window_moved",
    "window_minimized",
    "window_deminimized",
    "display_added",
    "display_removed",
    "display_moved",
    "display_resized",
    "mission_control_enter",
    "mission_control_exit",
]

# 与 sketchybarrc 一致：单显示器每屏 10 个 space，多显示器 5 个
K_SINGLE = 10
K_MULTI = 5

# Excluded apps and titles
exclude_title = ["scratchpad"]
exclude_app = ["WeChat", "D-Chat", "ripdrag", "NetEaseMusic"]

SEL_COLOR = "0xffffffff"
DIM_COLOR = "0x80ffffff"
SEL_BG = "0xff89b482"
DIM_BG = "0x00ffffff"


def log(msg: str) -> None:
    print(f"[{time.strftime('%H:%M:%S')}] {msg}", file=sys.stderr, flush=True)


def yabai_query(*args: str) -> Optional[List[Dict[str, Any]]]:
    """One request over a fresh connection (yabai closes the socket after reply)."""
    payload = b"".join(a.encode() + b"\0" for a in args) + b"\0"
    s = None
    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.settimeout(QUERY_TIMEOUT)
        s.connect(YABAI_SOCKET)
        s.sendall(struct.pack("i", len(payload)) + payload)
        s.shutdown(socket.SHUT_WR)
        chunks = []
        while True:
            chunk = s.recv(65536)
            if not chunk:
                break
            chunks.append(chunk)
        data = json.loads(b"".join(chunks))
        return data if isinstance(data, list) else None
    except (OSError, ValueError):
        return None
    finally:
        if s is not None:
            s.close()


def yabai_exec(*args: str) -> bool:
    """Fire-and-forget command over the socket (e.g. signal --add)."""
    payload = b"".join(a.encode() + b"\0" for a in args) + b"\0"
    s = None
    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.settimeout(QUERY_TIMEOUT)
        s.connect(YABAI_SOCKET)
        s.sendall(struct.pack("i", len(payload)) + payload)
        s.shutdown(socket.SHUT_WR)
        while s.recv(4096):
            pass
        return True
    except OSError:
        return False
    finally:
        if s is not None:
            s.close()


def register_signals(pid: int) -> None:
    """让 yabai 在事件发生时直接 SIGUSR1 唤醒本进程（比 sketchybar 事件快）。

    yabai 重启后 signal 清空，由 main 循环定期补注册。
    """
    for event in SIGNAL_EVENTS:
        label = f"space_daemon_{event}"
        yabai_exec("signal", "--remove", label)  # 幂等：先删旧的同名注册
        yabai_exec(
            "signal",
            "--add",
            f"label={label}",
            f"event={event}",
            f"action=kill -USR1 {pid}",
        )


def group_windows_by_space(windows: List[Dict]) -> Dict[int, List[Dict]]:
    """Group windows by space ID with filtering (与旧 space_handler 一致)."""
    windows_by_space: Dict[int, List[Dict]] = {}
    for window in windows:
        if window.get("app") != "TencentMeeting":
            if (
                not window.get("has-ax-reference", False)
                or window.get("is-hidden", False)
                or window.get("is-minimized", False)
                or window.get("title", "") in exclude_title
                or window.get("app", "") in exclude_app
            ):
                continue
        else:
            if window.get("level") == 1001:  # 悬浮窗
                continue
            if window.get("title") == "腾讯会议" and not window.get(
                "is-visible"
            ):  # 主页面（非会议屏幕共享页面）
                continue

        space_id = window.get("space")
        if space_id is None:
            continue
        windows_by_space.setdefault(space_id, []).append(window)
    return windows_by_space


def compute_focused(spaces: List[Dict]) -> Dict[int, int]:
    """每块显示器当前所在的 space：is-visible 定基线，has-focus 覆盖。

    比「只看 has-focus」更准：多显示器下非聚焦屏也有自己的高亮。
    """
    focused: Dict[int, int] = {}
    for space in spaces:
        if space.get("is-visible") and space.get("display") and space.get("index"):
            focused[int(space["display"])] = int(space["index"])
    for space in spaces:
        if space.get("has-focus") and space.get("display") and space.get("index"):
            focused[int(space["display"])] = int(space["index"])
    return focused


def bracket_members_of(space_id: int) -> Optional[Set[str]]:
    """Query sketchybar for the member set of win.<sid> bracket (None if absent)."""
    try:
        out = (
            subprocess.check_output(
                [SKETCHYBAR, "--query", f"win.{space_id}"],
                stderr=subprocess.DEVNULL,
                timeout=5,
            )
            .decode()
            .strip()
        )
        if not out:
            return None
        return set(json.loads(out).get("bracket", []))
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, ValueError):
        return None


class SpaceDaemon:
    """Holds last-rendered state; renders diffs as batched sketchybar commands."""

    def __init__(self) -> None:
        self.win_items: Dict[int, Set[int]] = {
            sid: set() for sid in range(1, TOTAL_SPACES + 1)
        }
        self.bracket_members: Dict[int, Set[str]] = {}
        self.last_win_ids: Dict[int, List[int]] = {}
        self.last_sel: Dict[int, bool] = {}
        self.k = K_SINGLE

    def seed(self) -> None:
        """从 sketchybar 读回现存的窗口 item，重启后避免 --add 撞名。"""
        for sid in range(1, TOTAL_SPACES + 1):
            members = bracket_members_of(sid)
            if members is None:
                continue
            self.bracket_members[sid] = members
            for member in members:
                if member == f"space.{sid}":
                    continue
                try:
                    self.win_items[sid].add(int(member.rsplit(".", 1)[1]))
                except (ValueError, IndexError):
                    pass
        log(
            f"seeded: {sum(len(v) for v in self.win_items.values())} win items, "
            f"{len(self.bracket_members)} brackets"
        )

    def space_group(
        self,
        sid: int,
        wins: List[Dict[str, Any]],
        sel: bool,
        display_id: int,
        rebuild_bracket: bool,
    ) -> List[str]:
        """Commands to bring one space's icon + window items + bracket up to date."""
        icon_color = SEL_COLOR if sel else DIM_COLOR
        bg = SEL_BG if sel else DIM_BG
        border = "0" if sel else "1"
        space_item = f"space.{sid}"
        bracket = f"win.{sid}"

        cmd = ["--set", space_item, f"icon.color={icon_color}"]

        existing = self.win_items[sid]
        desired_ids = [int(w["id"]) for w in wins]

        for wid in list(existing):
            if wid not in desired_ids:
                cmd += ["--remove", f"win.{sid}.{wid}"]

        for win in wins:
            wid = int(win["id"])
            item = f"win.{sid}.{wid}"
            if wid in existing:
                cmd += [
                    "--set",
                    item,
                    f"icon.color={icon_color}",
                    "background.padding_right=2",
                    f"background.image=app.{win['app']}",
                ]
            else:
                click = f"bash -c 'yabai -m space --focus {sid}'"
                cmd += [
                    "--add",
                    "item",
                    item,
                    SPACE_POS,
                    "--set",
                    item,
                    f"icon.color={icon_color}",
                    "background.padding_left=2",
                    "background.padding_right=2",
                    f"display={display_id}",
                    "background.drawing=true",
                    "background.height=10",
                    "background.image.scale=0.75",
                    f"background.image=app.{win['app']}",
                    f"click_script={click}",
                    "--move",
                    item,
                    "after",
                    space_item,
                ]

        bracket_list = [space_item] + [f"win.{sid}.{wid}" for wid in desired_ids]
        member_set = set(bracket_list)
        if (
            rebuild_bracket
            or sid not in self.bracket_members
            or self.bracket_members.get(sid) != member_set
        ):
            cmd += [
                "--remove",
                bracket,
                "--add",
                "bracket",
                bracket,
                *bracket_list,
                "--set",
                bracket,
                "background.height=28",
                f"background.border_width={border}",
                "background.border_color=0x80ffffff",
                "background.corner_radius=5",
                f"background.color={bg}",
                f"display={display_id}",
                f"click_script='yabai -m space --focus {sid}'",
            ]
        else:
            cmd += [
                "--set",
                bracket,
                f"background.border_width={border}",
                f"background.color={bg}",
            ]

        # 提交成功后更新内存状态（单条失败不中断整链，个别 item 由轮询自愈）
        self.win_items[sid] = set(desired_ids)
        self.bracket_members[sid] = member_set
        return cmd

    def tick(self) -> str:
        """Query yabai, diff against last render, push one batched update."""
        t0 = time.time()
        spaces = yabai_query("query", "--spaces")
        displays = yabai_query("query", "--displays")
        windows = yabai_query("query", "--windows")
        if spaces is None or displays is None or windows is None:
            return "yabai-unavailable"

        focused = compute_focused(spaces)
        k = K_MULTI if len(displays) > 1 else K_SINGLE
        k_changed = k != self.k
        first = not self.last_win_ids
        self.k = k

        def display_of(sid: int) -> int:
            return (sid - 1) // k + 1

        windows_by_space = group_windows_by_space(windows)
        cmd: List[str] = []

        if k_changed:  # 显示器数量变了：space item 的 display 分组也要刷新
            for sid in range(1, TOTAL_SPACES + 1):
                cmd += ["--set", f"space.{sid}", f"display={display_of(sid)}"]

        for sid in range(1, TOTAL_SPACES + 1):
            wins = windows_by_space.get(sid, [])
            sel = focused.get(display_of(sid)) == sid
            win_changed = [int(w["id"]) for w in wins] != self.last_win_ids.get(sid)
            if not (first or k_changed or win_changed or self.last_sel.get(sid) != sel):
                continue
            cmd += self.space_group(sid, wins, sel, display_of(sid), rebuild_bracket=k_changed)
            self.last_win_ids[sid] = [int(w["id"]) for w in wins]
            self.last_sel[sid] = sel

        if not cmd:
            return "noop"

        try:
            subprocess.run([SKETCHYBAR] + cmd, capture_output=True, timeout=5)
        except (subprocess.TimeoutExpired, OSError):
            return "sketchybar-error"
        elapsed = (time.time() - t0) * 1000
        return f"render {elapsed:.0f}ms ({len(cmd)} args)"


def main() -> None:
    # 登录时 yabai launch agent 可能晚于 sketchybar：等 socket 就绪
    waited = 0
    while yabai_query("query", "--displays") is None:
        if waited == 0:
            log("waiting for yabai socket...")
        waited += 1
        time.sleep(1)

    daemon = SpaceDaemon()
    daemon.seed()

    with open(PIDFILE, "w") as f:
        f.write(str(os.getpid()))
    atexit.register(lambda: os.path.exists(PIDFILE) and os.remove(PIDFILE))

    register_signals(os.getpid())
    last_reg = time.time()

    # SIGUSR1 唤醒：处理器里不能碰任何 Python 锁（Event.set() 会在
    # Event.wait() 持锁窗口内自死锁），改用 set_wakeup_fd 由 C 层写管道，
    # 主循环 select 管道可读即被唤醒。SIGTERM 保持默认终止行为。
    wake_r, wake_w = os.pipe()
    os.set_blocking(wake_w, False)
    signal.set_wakeup_fd(wake_w)
    signal.signal(signal.SIGUSR1, lambda *_: None)

    log(f"started (poll={POLL_INTERVAL}s, pos={SPACE_POS}, signals={len(SIGNAL_EVENTS)})")
    was_down = False
    while True:
        ready, _, _ = select.select([wake_r], [], [], POLL_INTERVAL)
        if ready:
            try:
                os.read(wake_r, 4096)  # drain
            except OSError:
                pass
        try:
            status = daemon.tick()
        except Exception as exc:  # 单轮异常不退出
            status = f"error: {exc}"
        now = time.time()
        if status == "yabai-unavailable":
            was_down = True
        elif was_down:
            # yabai 可能重启过（signal 注册被清空），恢复后立刻补注册
            was_down = False
            register_signals(os.getpid())
            last_reg = now
        elif now - last_reg > SIGNAL_REREGISTER:
            register_signals(os.getpid())
            last_reg = now
        if status != "noop" or DEBUG:
            log(status)


if __name__ == "__main__":
    main()
