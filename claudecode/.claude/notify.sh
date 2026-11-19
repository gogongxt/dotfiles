#!/bin/bash

# Claude Code 通知脚本
# 用法: notify.sh <event_type> [notification_text]
# event_type: "stop" 或 "notification"

# ============================================================
# Stop 事件的判定：后台 agent 类任务全部跑完才发"完成"通知
# ============================================================
# Stop 的 stdin 里有 background_tasks（2.1.145+），列出 running/pending 的后台任务，
# 用于区分"会话完成"和"会话在等后台工作唤醒自己"。
#
#   - 只算 subagent / workflow / cloud session：这类任务结束后会唤醒主会话，
#     期间的 Stop 只是主 agent 空转。
#   - 不算 shell / monitor：留个 dev server 或 watcher 时仍要能收到完成提醒。
#   - 不算 teammate：#109427 下空闲 teammate 会永久以 running 留在数组里，
#     计入会让通知永久失效。
#
# 已知上游误报窗口（未修复）：#102617（任务刚完成、通知未消费时数组为空）、
# #102765（subagent 等自己的后台 shell 时会掉出数组）。
# ============================================================

EVENT_TYPE="${1:-stop}"
NOTIFICATION_TEXT="${2:-}"

# 读取 hook 的 stdin JSON。手动在终端执行时 stdin 是 tty，避免 cat 卡住。
HOOK_INPUT=""
if [[ ! -t 0 ]]; then
    HOOK_INPUT=$(cat 2>/dev/null)
fi

# 判断是否还有"会自己唤醒主会话"的后台 agent 类任务在跑。
# 返回 0 = 仍在忙（应静默）；1 = 可视为完成（应通知）。
background_agents_running() {
    [[ -z "$HOOK_INPUT" ]] && return 1
    command -v jq >/dev/null 2>&1 || return 1

    local count
    count=$(printf '%s' "$HOOK_INPUT" | jq -r '
        [ (.background_tasks // [])[]
          | select(.status == "running" or .status == "pending")
          | select(.type == "subagent" or .type == "workflow" or .type == "cloud session")
        ] | length' 2>/dev/null)

    [[ "$count" =~ ^[0-9]+$ ]] || return 1
    [[ "$count" -gt 0 ]]
}

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
    # 后台还有 agent 类任务在跑：这一轮只是主会话空转，任务并未完成。
    if background_agents_running; then
        exit 0
    fi
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
        -group "com.claudecode.notification" \
        -contentImage "~/.claude/claude.webp"
else
    echo "警告: 通知脚本不存在或不可执行: $NOTIFY_SCRIPT" >&2
fi