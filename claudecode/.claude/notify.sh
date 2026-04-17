#!/bin/bash

# Claude Code 通知脚本
# 用法: notify.sh <event_type> [notification_text]
# event_type: "stop" 或 "notification"

EVENT_TYPE="${1:-stop}"
NOTIFICATION_TEXT="${2:-}"

# 获取 tmux 会话名称
get_tmux_session() {
    if [[ -n "$TMUX" ]]; then
        command tmux display-message -p '#S'
    else
        echo "无"
    fi
}

# 获取当前窗口信息（使用 TMUX_PANE 获取实际运行命令的窗口）
get_tmux_window() {
    if [[ -n "$TMUX" && -n "$TMUX_PANE" ]]; then
        # -t 指定目标 pane，获取该 pane 所在的窗口信息
        local index=$(command tmux display-message -t "$TMUX_PANE" -p '#I')
        local name=$(command tmux display-message -t "$TMUX_PANE" -p '#W')
        echo "${index}:${name}"
    else
        echo ""
    fi
}

# 收集信息
PATH_FULL="${PWD}"
SESSION=$(get_tmux_session)
WINDOW=$(get_tmux_window)

# 构建通知
if [[ "$EVENT_TYPE" == "stop" ]]; then
    TITLE="✅ Claude Code 完成"
    SOUND="Glass"
else
    TITLE="⚠️ Claude Code 需确认"
    SOUND="Submarine"
fi

# 使用 subtitle 高亮 tmux 会话和当前窗口
if [[ -n "$WINDOW" ]]; then
    SUBTITLE="🖥️ ${SESSION} [${WINDOW}]"
else
    SUBTITLE="🖥️ ${SESSION}"
fi

# 消息内容
MESSAGE="📂 ${PATH_FULL}"

if [[ "$EVENT_TYPE" != "stop" && -n "$NOTIFICATION_TEXT" ]]; then
    MESSAGE="${MESSAGE}
    ${NOTIFICATION_TEXT}
"
fi

# 调用通用通知脚本
NOTIFY_SCRIPT="$HOME/.scripts/macos/notify.sh"

if [[ -x "$NOTIFY_SCRIPT" ]]; then
    "$NOTIFY_SCRIPT" \
        -title "$TITLE" \
        -subtitle "$SUBTITLE" \
        -message "$MESSAGE" \
        -sound "$SOUND" \
        -group "com.claudecode.notification"
else
    echo "警告: 通知脚本不存在或不可执行: $NOTIFY_SCRIPT" >&2
fi
