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

# 获取当前聚焦的工作区
focused_workspace=$(aerospace list-workspaces --focused | awk '{print $1}')
if [ -z "$focused_workspace" ]; then
    echo "Error: Could not determine focused workspace"
    exit 1
fi

# 获取当前聚焦的窗口ID
cur_window_id=$(aerospace list-windows --focused | awk '{print $1}')

# 获取所有窗口信息
windows=$(aerospace list-windows --all)
found_window=false

# 遍历每一行窗口信息
while IFS= read -r line; do
    # 提取窗口ID、应用名和标题
    window_id=$(echo "$line" | awk '{print $1}')
    app_name=$(echo "$line" | awk -F '|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
    title=$(echo "$line" | awk -F '|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}')
    
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
            # 如果当前窗口已经是匹配的窗口，则移动到工作区q
            aerospace move-node-to-workspace --window-id "$window_id" q
            found_window=true
            break
        else
            # 否则移动到当前工作区并聚焦
            echo "Moving window $window_id (app: $app_name, title: $title) to workspace $focused_workspace"
            aerospace move-node-to-workspace --window-id "$window_id" "$focused_workspace"
            aerospace focus --window-id "$window_id"
            found_window=true
            break
        fi
    fi
done <<< "$windows"

# 如果没有找到匹配的窗口且提供了命令，则执行指定的命令
if [ "$found_window" = false ] && [ -n "$not_found_command" ]; then
    echo "No matching window found, executing command: $not_found_command"
    eval "$not_found_command"
elif [ "$found_window" = false ]; then
    echo "No matching window found (no command specified)"
fi
