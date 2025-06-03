#!/bin/bash

# 用法: move_float.sh <direction> [pixels]
# 示例: move_float.sh east 100    # 向右移动100像素
#       move_float.sh west        # 使用默认移动量(30像素)

direction=$1
pixels=${2:-30}  # 默认移动30像素

# 获取当前窗口信息
current_window=$(yabai -m query --windows --window)
is_floating=$(echo "$current_window" | jq -r '.["is-floating"]')
current_id=$(echo "$current_window" | jq -r '.id')

# 如果不是浮动窗口，使用 yabai 原生 warp 命令
if [[ "$is_floating" == "false" ]]; then
    case $direction in
        north|up)    yabai -m window --warp north ;;
        south|down)  yabai -m window --warp south ;;
        west|left)   yabai -m window --warp west ;;
        east|right)  yabai -m window --warp east ;;
        *) echo "无效方向: $direction"; exit 1 ;;
    esac
    exit 0
fi

# 浮动窗口处理 - 获取当前窗口位置
current_frame=$(echo "$current_window" | jq -r '.frame')

# 使用 awk 处理浮点数转整数
x=$(echo "$current_frame" | jq -r '.x' | awk '{printf "%d", $1}')
y=$(echo "$current_frame" | jq -r '.y' | awk '{printf "%d", $1}')
w=$(echo "$current_frame" | jq -r '.w' | awk '{printf "%d", $1}')
h=$(echo "$current_frame" | jq -r '.h' | awk '{printf "%d", $1}')

# 调试输出位置信息（可选）
# echo "当前位置: x=$x, y=$y, w=$w, h=$h"

# 根据方向计算新位置
case $direction in
    north|up)
        new_y=$((y - pixels))
        yabai -m window $current_id --move abs:$x:$new_y
        ;;
    south|down)
        new_y=$((y + pixels))
        yabai -m window $current_id --move abs:$x:$new_y
        ;;
    west|left)
        new_x=$((x - pixels))
        yabai -m window $current_id --move abs:$new_x:$y
        ;;
    east|right)
        new_x=$((x + pixels))
        yabai -m window $current_id --move abs:$new_x:$y
        ;;
    *)
        echo "Invalid direction: $direction"
        exit 1
        ;;
esac
