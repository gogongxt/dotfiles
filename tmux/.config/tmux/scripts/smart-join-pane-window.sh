#!/bin/bash

# 检查是否提供了目标window名称
if [ -z "$1" ]; then
    echo "Usage: $0 <window-number>"
    exit 1
fi

target_number="$1"

# 检查window是否存在
if tmux list-windows -F "#I" | grep -q "^${target_number}$"; then
    # 如果存在，直接join
    tmux join-pane -t ":${target_number}"
else
    # 如果不存在，break-pane
    tmux break-pane
fi
