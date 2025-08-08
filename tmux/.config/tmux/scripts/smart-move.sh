#!/usr/bin/env bash

# 智能 Tmux Pane 移动脚本
# 完全模仿 Vim 的 C-w + H/J/K/L 行为逻辑
# 1. 如果目标方向有相邻窗格，则交换(swap)。
# 2. 如果目标方向没有相邻窗格 (需变更新局)，则重排(re-layout)。

# 获取基本信息
direction="$1"
cur_id=$(tmux display-message -p "#{pane_id}")

# 将 Vim 按键转换为 tmux 方向参数 (-L, -R, -U, -D)
case "$direction" in
H) direction="L" ;;
J) direction="D" ;;
K) direction="U" ;;
L) direction="R" ;;
*) direction="" ;; # 无效输入
esac

[ -z "$direction" ] && exit 1

# 查找主要方向的目标窗格
target_id=$(tmux select-pane -${direction} -Z \; display-message -p "#{pane_id}")

# 查找后，立即移回原始窗格，后续操作以 cur_id 为准
tmux select-pane -t "${cur_id}" -Z

# 检查是否在窗口边缘。如果在边缘，选择目标窗格时 target_id 会和 cur_id 相同
is_edge=false
if [ "$cur_id" = "$target_id" ]; then
	is_edge=true
fi

# 获取当前窗格和目标窗格的几何信息，用于 is_adjacent 判断
cur_left=$(tmux display-message -p '#{pane_left}')
cur_top=$(tmux display-message -p '#{pane_top}')
cur_right=$((cur_left + $(tmux display-message -p '#{pane_width}')))
cur_bottom=$((cur_top + $(tmux display-message -p '#{pane_height}')))

tgt_left=$(tmux display-message -p -t "$target_id" '#{pane_left}')
tgt_top=$(tmux display-message -p -t "$target_id" '#{pane_top}')
tgt_right=$((tgt_left + $(tmux display-message -p -t "$target_id" '#{pane_width}')))
tgt_bottom=$((tgt_top + $(tmux display-message -p -t "$target_id" '#{pane_height}')))

# 改变分割方向
# 参数: <要移动的窗格ID> <目标窗格ID> <合并模式 v|h> [before_flag]
move_and_join() {
	local move_id="$1"
	local dest_id="$2"
	local mode="$3"        # v for vertical, h for horizontal
	local before_flag="$4" # "-b" 或空字符串，用于 join-pane

	[ -z "$dest_id" ] || [ "$move_id" = "$dest_id" ] && return

	is_zoomed=$(tmux display-message -p '#{window_zoomed_flag}')

	tmux break-pane -s "$move_id"
	tmux join-pane ${before_flag} -"$mode" -s "$move_id" -t "$dest_id"
	tmux select-pane -t "$move_id" -Z

	[ "$is_zoomed" -eq 1 ] && tmux resize-pane -Z
}

# 检查窗格是否相邻
is_adjacent() {
	# The check must be e.g. cur_bottom + 1 == tgt_top
	case "$direction" in
	L)
		# 检查左边: 当前窗格左边界 = 目标窗格右边界+1，且垂直重叠
		((cur_left == tgt_right + 1 && cur_top < tgt_bottom && tgt_top < cur_bottom))
		;;
	R)
		# 检查右边: 当前窗格右边界+1 = 目标窗格左边界，且垂直重叠
		((cur_right + 1 == tgt_left && cur_top < tgt_bottom && tgt_top < cur_bottom))
		;;
	U)
		# 检查上边: 当前窗格上边界 = 目标窗格下边界+1，且水平重叠
		((cur_top == tgt_bottom + 1 && cur_left < tgt_right && tgt_left < cur_right))
		;;
	D)
		# 检查下边: 当前窗格下边界+1 = 目标窗格上边界，且水平重叠
		((cur_bottom + 1 == tgt_top && cur_left < tgt_right && tgt_left < cur_right))
		;;
	esac
}

# --- 主要逻辑 ---
case "$direction" in
L | R) # 水平移动 H 或 L
	if ! $is_edge && is_adjacent; then
		# 简单情况: 左右相邻，直接交换
		tmux swap-pane -s "$cur_id" -t "$target_id"
	else
		# 复杂情况: 改变分割方向
		other_id=$(tmux select-pane -D -Z \; display-message -p '#{pane_id}')
		[ "$cur_id" = "$other_id" ] && other_id=$(tmux select-pane -U -Z \; display-message -p '#{pane_id}')
		tmux select-pane -t "$cur_id" -Z

		if [ "$cur_id" != "$other_id" ]; then
			if [ "$direction" = "L" ]; then
				move_and_join "$cur_id" "$other_id" "h" "-b" # 移到左边 (before)
			else
				move_and_join "$cur_id" "$other_id" "h" "" # 移到右边 (after)
			fi
		fi
	fi
	;;
U | D) # 垂直移动 K 或 J
	if ! $is_edge && is_adjacent; then
		# 简单情况: 上下相邻，直接交换
		tmux swap-pane -s "$cur_id" -t "$target_id"
	else
		# 复杂情况: 改变分割方向
		other_id=$(tmux select-pane -R -Z \; display-message -p '#{pane_id}')
		[ "$cur_id" = "$other_id" ] && other_id=$(tmux select-pane -L -Z \; display-message -p '#{pane_id}')
		tmux select-pane -t "$cur_id" -Z

		if [ "$cur_id" != "$other_id" ]; then
			if [ "$direction" = "U" ]; then
				move_and_join "$cur_id" "$other_id" "v" "-b" # 移到上边 (before)
			else
				move_and_join "$cur_id" "$other_id" "v" "" # 移到下边 (after)
			fi
		fi
	fi
	;;
esac

# 确保焦点在移动后的当前窗格上
tmux select-pane -t "$cur_id" -Z
