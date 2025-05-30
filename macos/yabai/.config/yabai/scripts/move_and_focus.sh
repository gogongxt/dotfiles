#!/bin/bash

# 功能：将当前窗口移动到指定 space，并确保 focus 正确
# 用法：./move_and_focus.sh <space_number>

# 检查参数
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <space_number (1-10)>"
    exit 1
fi

bash $HOME/.config/yabai/scripts/safe_focus_space.sh check "$1"

target_space="$1"

# 获取当前窗口 ID
window_id=$(yabai -m query --windows --window | jq -r '.id')
if [ -z "$window_id" ]; then
    echo "Error: Could not get current window ID"
    exit 1
fi


# 执行操作
yabai -m window --space "$target_space"    # 移动窗口
yabai -m space --focus "$target_space"    # 切换 space
yabai -m window --focus "$window_id"      # 重新 focus 窗口

exit 0
