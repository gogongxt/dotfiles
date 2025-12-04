#!/bin/bash

# 重新编号session中的所有窗口为连续编号
renumber_windows() {
    local session="$1"
    local windows=$(tmux list-windows -t "$session" -F "#{window_index}:#{window_id}")
    local index=1

    echo "$windows" | while IFS=: read current_index window_id; do
        if [ "$current_index" -ne "$index" ]; then
            tmux move-window -s "$session:$current_index" -t "$session:$index" 2>/dev/null
        fi
        index=$((index + 1))
    done
}

# 检查是否提供了目标session名称
if [ -z "$1" ]; then
    echo "Usage: $0 <session-name>"
    echo "Available sessions:"
    tmux list-sessions -F "#{session_name}"
    exit 1
fi

target_session="$1"

# 检查session是否存在
if tmux list-sessions -F "#{session_name}" | grep -q "^${target_session}$"; then
    session_existed=true
else
    session_existed=false
fi

# 获取当前session信息
current_session=$(tmux display-message -p '#S')
current_pane_id=$(tmux display-message -p '#D')

# 将当前pane break成新window（这会创建一个只包含该pane的新window）
tmux break-pane -s "${current_pane_id}" -d

# 获取刚创建的新window编号（在当前session中最后创建的window）
new_window=$(tmux list-windows -t "${current_session}" | tail -n 1 | cut -d: -f1)

if [ "$session_existed" = true ]; then
    # Session存在，移动window到目标session
    tmux move-window -s "${current_session}:${new_window}" -t "${target_session}:"
    if [ $? -eq 0 ]; then
        # echo "Pane moved to existing session '${target_session}' as new window"
        # 重新编号当前session的窗口
        renumber_windows "${current_session}"
        # 重新编号目标session的窗口
        renumber_windows "${target_session}"
    else
        echo "Failed to move pane to session '${target_session}'"
        # 将window移回原session以避免丢失
        tmux move-window -s "${current_session}:${new_window}" -t "${current_session}:"
        exit 1
    fi
else
    # Session不存在，先创建新session，然后移动window
    # 创建一个新的空session
    tmux new-session -d -s "${target_session}"
    if [ $? -ne 0 ]; then
        echo "Failed to create session '${target_session}'"
        # 将window移回原session以避免丢失
        tmux move-window -s "${current_session}:${new_window}" -t "${current_session}:"
        exit 1
    fi

    # 移动window到新创建的session
    tmux move-window -s "${current_session}:${new_window}" -t "${target_session}:"
    if [ $? -eq 0 ]; then
        # echo "Pane moved to newly created session '${target_session}' as new window"
        # 重新编号当前session的窗口
        renumber_windows "${current_session}"
        # 重新编号目标session的窗口
        renumber_windows "${target_session}"
    else
        echo "Failed to move pane to newly created session '${target_session}'"
        # 清理创建的空session
        tmux kill-session -t "${target_session}"
        # 将window移回原session以避免丢失
        tmux move-window -s "${current_session}:${new_window}" -t "${current_session}:"
        exit 1
    fi
fi