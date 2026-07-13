#!/bin/bash

# Claude Code 通知脚本
# 用法: notify.sh <event_type> [notification_text]
# event_type: "stop" 或 "notification"

# ============================================================
# TODO: Stop hook 在子 agent 任务中多次触发通知的问题 (待修复)
# ============================================================
# 现象:
#   一个任务里启动多个子 agent (Agent/Task tool) 时, Stop hook 会触发多次,
#   导致桌面通知发多次. 期望是整个任务真正完成时只通知一次.
#
# 调查结论 (2026-06-29):
#   1. settings.json 里只注册了 Stop, 没注册 SubagentStop. 按文档子 agent
#      完成本不该触发 Stop. 所以多次触发不是子 agent 直接触发的.
#   2. 真正原因: Stop 的语义是"每一轮响应结束", 不是"整个任务结束".
#      多个子 agent 顺序执行时, 主会话经历多轮"结束响应", 每轮都触发 Stop.
#      这是文档化行为, 不是 bug.
#   3. 另有已知 regression #70151 (v2.1.178 之后): 主会话 Stop 时
#      SubagentStop 会被错误地一起触发. 但本脚本只挂了 Stop, 与此无关.
#
# 相关 issue (GitHub anthropics/claude-code):
#   - #70151 SubagentStop hook fires on main session/agent (regression, OPEN)
#     https://github.com/anthropics/claude-code/issues/70151
#   - #59719 SubagentStop hook: missing agent_type + orphan Stop events (CLOSED)
#     https://github.com/anthropics/claude-code/issues/59719
#     含社区验证的 workaround: 用 transcript_path basename 区分主会话 vs 子 agent
#   - #7881  SubagentStop hook cannot identify which subagent finished (OPEN)
#     https://github.com/anthropics/claude-code/issues/7881
#   - #65169 PostToolUse hook does not fire for Agent tool completions (OPEN)
#     https://github.com/anthropics/claude-code/issues/65169
#
# hook 机制限制:
#   Stop hook 层面无法区分"中间停止" vs "任务最终停止". 因为每次 Stop 都是
#   主会话结束响应, 你无法预知 Claude 会不会再启动一轮.
#
# 待修复方案 (等 Claude Code 版本更新后重新评估):
#   方案 A (推荐, 社区验证): 读 stdin 的 JSON, 用 transcript_path basename
#     vs session_id 区分主会话 vs 子 agent. 主会话 basename == session_id.
#     - 参考 #59719 里 @Andrew-Chen-Wang 的 Python 实现.
#     - 需要 jq 解析 stdin (当前脚本没读 stdin).
#   方案 B (务实去重): 同 session 短时间内已通知过则跳过 (状态文件).
#     不是纯防抖, 而是"同一会话同一轮只通知一次".
#   方案 C (最精确, 复杂): 结合 UserPromptSubmit (任务开始) + Stop (每轮结束)
#     + 状态文件判断"是否为该 prompt 后最后一次 Stop". 有竞态.
#
# 注意: 修复前先跑 /hooks 确认 Stop/SubagentStop 的实际注册来源
#       (User/Project/Local/Plugin), 排除 sentry-skills 插件挂的 hook.
# ============================================================

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
        -group "com.claudecode.notification" \
        -contentImage "~/.claude/claude.webp"
else
    echo "警告: 通知脚本不存在或不可执行: $NOTIFY_SCRIPT" >&2
fi
