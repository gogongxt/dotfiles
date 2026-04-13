#!/bin/bash

# Claude Code 通知脚本
# 用法: notify.sh <event_type> [notification_text]
# event_type: "stop" 或 "notification"

EVENT_TYPE="${1:-stop}"
NOTIFICATION_TEXT="${2:-}"

# 获取 tmux 会话名称
get_tmux_session() {
    if [[ -n "$TMUX" ]]; then
        tmux display-message -p '#S'
    else
        echo "无"
    fi
}

# 收集信息
PATH_FULL="${PWD}"
SESSION=$(get_tmux_session)

# 构建通知
if [[ "$EVENT_TYPE" == "stop" ]]; then
    TITLE="✅ Claude Code 完成"
    SOUND="Glass"
else
    TITLE="⚠️ Claude Code 需确认"
    SOUND="Submarine"
fi

# 使用 subtitle 高亮 tmux 会话
SUBTITLE="🖥️ tmux: ${SESSION}"

# 消息内容
MESSAGE="📂 ${PATH_FULL}"

if [[ "$EVENT_TYPE" != "stop" && -n "$NOTIFICATION_TEXT" ]]; then
    MESSAGE="${NOTIFICATION_TEXT}

${MESSAGE}"
fi

# 发送通知的函数
send_notification() {
    local title="$1"
    local subtitle="$2"
    local message="$3"
    local sound="$4"

    if [[ -n "$SSH_CONNECTION" ]]; then
        # SSH 环境：通过端口转发发送到本地
        # 使用 JSON 格式传输，便于解析
        local payload="{\"title\":\"${title}\",\"subtitle\":\"${subtitle}\",\"message\":\"${message}\",\"sound\":\"${sound}\"}"
        # 转义换行符
        payload=$(echo "$payload" | tr '\n' ' ')

        # 使用 python3 发送 (最可靠)
        python3 -c "
import socket
s = socket.socket()
try:
    s.connect(('localhost', 7770))
    s.send('NOTIFY:${payload}'.encode('utf-8'))
    s.close()
except:
    pass
" &
    else
        # 本地环境：直接使用 terminal-notifier
        terminal-notifier \
            -title "$title" \
            -subtitle "$subtitle" \
            -message "$message" \
            -sound "$sound" \
            -group "com.claudecode.notification"
    fi
}

send_notification "$TITLE" "$SUBTITLE" "$MESSAGE" "$SOUND"
