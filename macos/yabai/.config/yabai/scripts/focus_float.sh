#!/bin/bash

# 获取方向参数
direction=$1

# 获取当前窗口信息
current_window=$(yabai -m query --windows --window)
is_floating=$(echo "$current_window" | jq -r '.["is-floating"]')

# 如果不是浮动窗口，使用 yabai 原生命令
if [[ "$is_floating" == "false" ]]; then
    yabai -m window --focus "$direction"
    exit 0
fi

# 获取当前窗口的 frame 和 ID
current_id=$(echo "$current_window" | jq -r '.id')
current_frame=$(echo "$current_window" | jq -r '.frame')

# 获取当前 space 的所有浮动窗口
floating_windows=$(yabai -m query --windows --space | jq -c '[.[] | select(.["is-floating"] == true and .id != '"$current_id"')]')

# 解析当前窗口 frame
current_x=$(echo "$current_frame" | jq -r '.x')
current_y=$(echo "$current_frame" | jq -r '.y')
current_w=$(echo "$current_frame" | jq -r '.w')
current_h=$(echo "$current_frame" | jq -r '.h')
# 转换为整数并计算中心点
current_x=${current_x%.*}  # 去掉小数部分
current_y=${current_y%.*}
current_w=${current_w%.*}
current_h=${current_h%.*}
current_center_x=$((current_x + current_w / 2))
current_center_y=$((current_y + current_h / 2))

# 初始化变量
closest_window_id=0
min_distance=999999

# 计算距离和方向
for window in $(echo "$floating_windows" | jq -c '.[]'); do
    window_id=$(echo "$window" | jq -r '.id')
    window_frame=$(echo "$window" | jq -r '.frame')
    
    window_x=$(echo "$window_frame" | jq -r '.x')
    window_y=$(echo "$window_frame" | jq -r '.y')
    window_w=$(echo "$window_frame" | jq -r '.w')
    window_h=$(echo "$window_frame" | jq -r '.h')
    # 转换为整数
    window_x=${window_x%.*}
    window_y=${window_y%.*}
    window_w=${window_w%.*}
    window_h=${window_h%.*}
    window_center_x=$((window_x + window_w / 2))
    window_center_y=$((window_y + window_h / 2))
    
    # 计算相对位置
    dx=$((window_center_x - current_center_x))
    dy=$((window_center_y - current_center_y))
    
    # 根据方向筛选窗口
    case $direction in
        "north"|"up")
            if [[ $dy -ge 0 ]]; then continue; fi  # 必须在当前窗口上方
            distance=$(( (dx * dx) + (dy * dy) ))
            ;;
        "south"|"down")
            if [[ $dy -le 0 ]]; then continue; fi  # 必须在当前窗口下方
            distance=$(( (dx * dx) + (dy * dy) ))
            ;;
        "west"|"left")
            if [[ $dx -ge 0 ]]; then continue; fi  # 必须在当前窗口左侧
            distance=$(( (dx * dx) + (dy * dy) ))
            ;;
        "east"|"right")
            if [[ $dx -le 0 ]]; then continue; fi  # 必须在当前窗口右侧
            distance=$(( (dx * dx) + (dy * dy) ))
            ;;
        *)
            echo "Invalid direction: $direction"
            exit 1
            ;;
    esac
    
    # 更新最近窗口
    if [[ $distance -lt $min_distance ]]; then
        min_distance=$distance
        closest_window_id=$window_id
    fi
done

# 如果有符合条件的窗口，则聚焦
if [[ $closest_window_id -ne 0 ]]; then
    yabai -m window --focus "$closest_window_id"
else
    # 没有找到窗口，可以播放提示音或显示通知
    osascript -e 'display notification "No window in that direction" with title "Yabai Focus"'
fi
