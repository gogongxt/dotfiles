#!/bin/bash

# Usage: 
# 输入三个参数(第三个参数可以缺省)
# - 第一个参数是"title"或者是"app_name"
# - 第二个参数第一个参数对应的字符串
# - 第三个参数是如果没有找到对应的窗口就执行的命令。

# 检查参数数量
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <match_type> <match_string> [not_found_command]"
    echo "Example: $0 title scratchpad '/Applications/kitty.app/Contents/MACOS/kitty -T scratchpad tmux'"
    echo "Example: $0 app_name kitty"
    exit 1
fi

match_type=$1
match_string=$2
not_found_command=${3:-}

# 获取当前聚焦的空间
focused_space=$(yabai -m query --spaces --space | jq -r '.index')
if [ -z "$focused_space" ]; then
    echo "Error: Could not determine focused space"
    exit 1
fi

# 获取当前聚焦的窗口ID
cur_window_id=$(yabai -m query --windows --window | jq -r '.id')

# 获取所有窗口信息
windows=$(yabai -m query --windows)
found_window=false

# 使用jq处理JSON数据
while IFS= read -r window; do
    # 提取窗口信息
    window_id=$(echo "$window" | jq -r '.id')
    app_name=$(echo "$window" | jq -r '.app')
    title=$(echo "$window" | jq -r '.title')
    
    # 根据匹配类型检查是否匹配
    case $match_type in
        "title")
            match_field="$title"
            ;;
        "app_name")
            match_field="$app_name"
            ;;
        *)
            echo "Error: Invalid match type. Use 'title' or 'app_name'"
            exit 1
            ;;
    esac
    
    # 检查是否匹配（不区分大小写）
    if [[ "$match_field" =~ $match_string ]]; then
        if [ "$window_id" == "$cur_window_id" ]; then
            # 如果当前窗口已经是匹配的窗口，则移动到空间q
            bash $HOME/.config/yabai/scripts/safe_focus_space.sh "check" "9"
            yabai -m window --space 9
            # yabai -m space --focus 9
            found_window=true
            break
        else
            # 否则移动到当前空间并聚焦
            echo "Moving window $window_id (app: $app_name, title: $title) to space $focused_space"
            yabai -m window $window_id --space "$focused_space"
            yabai -m window --focus "$window_id"
            found_window=true
            break
        fi
    fi
done <<< "$(echo "$windows" | jq -c '.[]')"

# 如果没有找到匹配的窗口且提供了命令，则执行指定的命令
if [ "$found_window" = false ] && [ -n "$not_found_command" ]; then
    echo "No matching window found, executing command: $not_found_command"
    eval "$not_found_command"
elif [ "$found_window" = false ]; then
    echo "No matching window found (no command specified)"
fi
