#!/bin/sh
# sketchybar 事件 → SIGUSR1 即时唤醒常驻 space_daemon.py（~4ms）。
# 真实状态由 daemon 自己查 yabai 渲染，这里只负责唤醒。
PIDFILE="/tmp/space_daemon_$(id -u).pid"
[ -f "$PIDFILE" ] && kill -USR1 "$(cat "$PIDFILE")" 2>/dev/null
exit 0
