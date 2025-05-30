#!/bin/bash

# 检查参数数量是否正确
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <check|focus> <space_number (1-10)>"
    exit 1
fi

action="$1"
target_space="$2"

# 检查 space 参数是否有效（1-10 的数字）
if ! [[ "$target_space" =~ ^[0-9]+$ ]] || (( target_space < 1 || target_space > 10 )); then
    echo "Error: Space number must be between 1 and 10."
    exit 1
fi

# 检查 action 参数是否有效
if [[ "$action" != "check" && "$action" != "focus" ]]; then
    echo "Error: First argument must be 'check' or 'focus'."
    exit 1
fi

# 获取当前最大的 space 索引
current_max=$(yabai -m query --spaces | jq 'map(.index) | max')

# 如果目标 space 大于当前最大 space，则创建新的 space 直到达到目标
while [[ "$current_max" -lt "$target_space" ]]; do
    yabai -m space --create
    current_max=$((current_max + 1))
done

# 如果是 "focus" 才切换 space
if [[ "$action" == "focus" ]]; then
    yabai -m space --focus "$target_space"
    # 可选：更换壁纸（如果需要）
    # ~/.config/yabai/change-random-wallpaper.sh
fi
