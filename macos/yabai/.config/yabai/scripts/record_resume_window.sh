#!/bin/bash

# yabai 窗口状态管理脚本
# 功能: record - 记录窗口状态 | resume - 恢复窗口状态
# 依赖: yabai, jq

CONFIG_DIR="$HOME/.config/yabai"
WINDOW_STATE_FILE="$CONFIG_DIR/.window_states.json"

# 确保配置目录存在
mkdir -p "$CONFIG_DIR"

function record_window_states() {
    # 删除旧的状态文件
    rm -f "$WINDOW_STATE_FILE"
    
    # 获取所有窗口信息
    windows=$(yabai -m query --windows)
    
    # 提取每个窗口的 id, workspace, 浮动状态和位置信息
    echo "$windows" | jq -c 'map({
        id: .id, 
        workspace: .space, 
        is_floating: ."is-floating",
        frame: .frame
    })' > "$WINDOW_STATE_FILE"
    
    echo "窗口状态已记录到 $WINDOW_STATE_FILE"
    terminal-notifier -title "yabai" -message "窗口状态已记录到 $WINDOW_STATE_FILE" -sound "default" -activate "com.apple.Terminal"
}

function resume_window_states() {
    if [[ ! -f "$WINDOW_STATE_FILE" ]]; then
        echo "错误: 未找到窗口状态记录文件 $WINDOW_STATE_FILE"
        exit 1
    fi
    
    # 读取记录的窗口状态
    recorded_states=$(cat "$WINDOW_STATE_FILE" | jq -c '.')
    
    # 获取当前所有窗口
    current_windows=$(yabai -m query --windows | jq -c 'map(.id)')
    
    # 遍历记录的窗口状态
    for row in $(echo "$recorded_states" | jq -r '.[] | @base64'); do
        _jq() {
            echo ${row} | base64 --decode | jq -r ${1}
        }
        
        window_id=$(_jq '.id')
        target_space=$(_jq '.workspace')
        is_floating=$(_jq '.is_floating')
        frame_x=$(_jq '.frame.x')
        frame_y=$(_jq '.frame.y')
        frame_w=$(_jq '.frame.w')
        frame_h=$(_jq '.frame.h')
        
        # 检查窗口是否存在
        if [[ $(echo "$current_windows" | jq "contains([$window_id])") == "true" ]]; then
            # 移动窗口到原工作空间
            yabai -m window $window_id --space $target_space
            
            # 恢复浮动状态和位置
            if [[ "$is_floating" == "true" ]]; then
                # 如果窗口不是浮动状态，先切换为浮动
                if [[ $(yabai -m query --windows --window $window_id | jq '.["is-floating"]') == "false" ]]; then
                    yabai -m window $window_id --toggle float
                fi
                # 设置窗口位置和大小
                yabai -m window $window_id --move abs:$frame_x:$frame_y
                yabai -m window $window_id --resize abs:$frame_w:$frame_h
            else
                # 如果窗口是浮动状态，切换为非浮动
                if [[ $(yabai -m query --windows --window $window_id | jq '.["is-floating"]') == "true" ]]; then
                    yabai -m window $window_id --toggle float
                fi
            fi
            
            echo "已恢复窗口 $window_id 到工作空间 $target_space (浮动: $is_floating)"
            if [[ "$is_floating" == "true" ]]; then
                echo "  位置: x=$frame_x, y=$frame_y, 大小: w=$frame_w, h=$frame_h"
            fi
        else
            echo "警告: 窗口 $window_id 不存在"
        fi
    done
    
    echo "窗口状态恢复完成"

    # reflush sketchybar
    sleep 0.1
    brew services restart sketchybar

    terminal-notifier -title "yabai" -message "窗口状态恢复完成" -sound "default" -activate "com.apple.Terminal"

}

# 主程序
case "$1" in
    "record")
        record_window_states
        ;;
    "resume")
        resume_window_states
        ;;
    *)
        echo "用法: $0 [record|resume]"
        echo "  record - 记录当前窗口状态"
        echo "  resume - 恢复之前记录的窗口状态"
        exit 1
        ;;
esac
