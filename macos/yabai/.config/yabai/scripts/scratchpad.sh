#!/bin/bash

# Usage:
# 输入三个参数(第三个参数可以缺省)
# - 第一个参数是"title"、"app_name"或"user"
# - 第二个参数第一个参数对应的字符串
# - 第三个参数是如果没有找到对应的窗口就执行的命令。

# 检查参数数量
if [ "$#" -lt 2 ]; then
	echo "Usage: $0 <match_type> <match_string> [not_found_command]"
	echo "Example: $0 title scratchpad '/Applications/kitty.app/Contents/MACOS/kitty -T scratchpad tmux'"
	echo "Example: $0 app_name kitty"
	echo "Example: $0 user user_matcher"
	exit 1
fi

match_type=$1
match_string=$2
not_found_command=${3:-}

user_d_chat() {
	local window_id="$1"
	local app_name="$2"
	local title="$3"
	local space="$4"
	if [[ "$app_name" == "D-Chat" ]] && [[ "$title" == "" ]]; then
		return 0
	else
		return 1
	fi
}

user_neteasemusic() {
	# 没见过网易云这里🌶︎🐔的软件
	# cmd+w会让网易云不可见，并且cmd+w后没法通过yabai的yabai window --focus $id 进行聚焦
	# 可见状态下app_name="NetEaseMusic" && title =="NetEaseMusic"
	# cmd+w后变成app_name="NeteaseMusic" && title =="NetEaseMusic"(注意app_name的大小写变了)
	# 歌词窗口是app_name="NetEaseMusic" && title ==""
	# 所以hack的方式就是下面这样，首先可以筛选掉歌词窗口，可以选中可见的网易云，对于不可见直接触发open -a打开窗口
	local window_id="$1"
	local app_name="$2"
	local title="$3"
	local space="$4"
	# if ([[ "$app_name" == "NetEaseMusic" ]] || [[ "$app_name" == "NeteaseMusic" ]]) && [[ "$title" == "NetEaseMusic" ]]; then
	if [[ "$app_name" == "NetEaseMusic" ]] && [[ "$title" == "NetEaseMusic" ]]; then
		return 0
	else
		return 1
	fi
}

# 如果使用user匹配类型，加载用户自定义匹配函数
if [ "$match_type" = "user" ]; then
	# 检查匹配函数是否存在
	if ! declare -f "$match_string" >/dev/null; then
		echo "Error: User matcher function '$match_string'"
		exit 1
	fi
fi

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
	space=$(echo "$window" | jq -r '.space')

	# 根据匹配类型检查是否匹配
	case $match_type in
	"title")
		match_field="$title"
		if [[ "$match_field" =~ $match_string ]]; then
			match_result=true
		else
			match_result=false
		fi
		;;
	"app_name")
		match_field="$app_name"
		if [[ "$match_field" =~ $match_string ]]; then
			match_result=true
		else
			match_result=false
		fi
		;;
	"user")
		# 调用用户自定义匹配函数
		if $match_string "$window_id" "$app_name" "$title" "$space"; then
			match_result=true
		else
			match_result=false
		fi
		;;
	*)
		echo "Error: Invalid match type. Use 'title', 'app_name' or 'user'"
		exit 1
		;;
	esac

	# 检查是否匹配
	if [ "$match_result" = true ]; then
		if [ "$window_id" == "$cur_window_id" ]; then
			# 如果当前窗口已经是匹配的窗口，则移动到空间10
			bash $HOME/.config/yabai/scripts/safe_focus_space.sh "check" "10"
			yabai -m window --space 10
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
done <<<"$(echo "$windows" | jq -c '.[]')"

# 如果没有找到匹配的窗口且提供了命令，则执行指定的命令
if [ "$found_window" = false ] && [ -n "$not_found_command" ]; then
	echo "No matching window found, executing command: $not_found_command"
	eval "$not_found_command"
elif [ "$found_window" = false ]; then
	echo "No matching window found (no command specified)"
fi
