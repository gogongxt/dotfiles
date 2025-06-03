#!/bin/bash

# 功能：将当前窗口移动到指定 space，并确保 focus 正确，额外是针对多个display，默认输入是针对当前display所在的space排序

# 用法：./move_and_focus.sh <space_number>

# 检查参数
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <space_number (1-5)>"
    exit 1
fi

# 获取当前显示器的 space 列表
SPACES=($(yabai -m query --displays --display | jq '.spaces[]'))
if [ ${#SPACES[@]} -eq 0 ]; then
    echo "Error: Could not get spaces for current display"
    exit 1
fi

# 检查请求的 space 是否有效（注意数组是从0开始还是1开始）
index=$(($1 - 1))  # 假设输入是1-based
if [ $index -lt 0 ] || [ $index -ge ${#SPACES[@]} ]; then
    echo "Error: Invalid space number $1 (valid range: 1-${#SPACES[@]})"
    exit 1
fi

target_space=${SPACES[$index]}

bash $HOME/.config/yabai/scripts/safe_focus_space.sh check "$target_space"

# 获取当前窗口 ID
window_id=$(yabai -m query --windows --window | jq -r '.id')
if [ -z "$window_id" ]; then
    echo "Error: Could not get current window ID"
    exit 1
fi

# 执行操作
yabai -m window --space "$target_space"    # 移动窗口
yabai -m space --focus "$target_space"     # 切换 space
yabai -m window --focus "$window_id"       # 重新 focus 窗口

exit 0
