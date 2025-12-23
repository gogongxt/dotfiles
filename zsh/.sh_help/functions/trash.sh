# trash-cli alis : https://github.com/andreafrancia/trash-cli
#🔽🔽🔽
command -v trash-put &>/dev/null && {
	alias rm="trash-put"
	alias trash-autoclean='trash-empty 30'
	alias trash-ls='trash-list'
	alias trash-ll='trash-ls'
}
#🔼🔼🔼

# How to use:
#   1. 列出回收站内容并筛选：trash-ls | grep gogongxt > tmp_trash_remove.txt
#   2. 编辑 tmp_trash_remove.txt，保留要删除的行
#   3. 执行： trash-delete tmp_trash_remove.txt
#      → 将逐一调用 trash-rm 永久删除文件
trash-delete() {
	# 定义颜色代码
	local RED='\033[0;31m'
	local GREEN='\033[0;32m'
	local YELLOW='\033[1;33m'
	local BLUE='\033[0;34m'
	local CYAN='\033[0;36m'
	local BOLD='\033[1m'
	local NC='\033[0m' # No Color

	# 显示帮助信息
	show_help() {
		echo -e "${CYAN}trash-delete${NC} - Permanently delete items from trash using a file list"
		echo ""
		echo -e "${BOLD}Usage:${NC}"
		echo "  trash-delete <filename>"
		echo "  trash-delete -h|--help"
		echo ""
		echo -e "${BOLD}Description:${NC}"
		echo "  Reads a file containing trash-list output and permanently removes"
		echo "  the specified items from the trash using trash-rm."
		echo ""
		echo -e "${BOLD}How to use:${NC}"
		echo "  1. List trash contents and filter:"
		echo "     ${YELLOW}trash-ls | grep pattern > tmp_trash_remove.txt${NC}"
		echo "  2. Edit the file to keep only lines you want to delete"
		echo "  3. Run:"
		echo "     ${YELLOW}trash-delete tmp_trash_remove.txt${NC}"
		echo ""
		echo -e "${BOLD}Options:${NC}"
		echo "  -h, --help    Show this help message"
	}

	# 检查帮助参数
	if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
		show_help
		return 0
	fi

	# 检查是否提供了参数
	if [ $# -ne 1 ]; then
		echo -e "${RED}Usage: trash-delete <filename>${NC}"
		echo -e "Use ${CYAN}-h${NC} or ${CYAN}--help${NC} for more information."
		return 1
	fi

	local file="$1"
	local -a trash_paths=()
	local confirmation

	# 检查文件是否存在
	if [ ! -f "$file" ]; then
		echo -e "${RED}Error: File '$file' does not exist${NC}"
		return 1
	fi

	# 使用awk提取路径（去掉前两个字段）
	local -a trash_paths=($(awk '{print substr($0, index($0,$3))}' "$file"))

	# 检查是否有要删除的路径
	if [ ${#trash_paths[@]} -eq 0 ]; then
		echo -e "${YELLOW}No paths to delete found in the file.${NC}"
		return 0
	fi

	# 显示将要执行的删除命令
	echo -e "${CYAN}The following trash items will be permanently removed from trash:${NC}"
	i=1
	while [ $i -le ${#trash_paths} ]; do
		echo -e "  ${BOLD}trash-rm \"${trash_paths[i]}\"${NC}"
		((i++))
	done

	# 二次确认
	echo -e -n "${YELLOW}Are you sure you want to permanently delete these items from trash? (y/N): ${NC}"
	read -r confirmation

	if [[ "$confirmation" =~ ^[Yy]$ ]]; then
		# 执行删除操作 - 使用trash-rm从回收站中删除
		i=1
		while [ $i -le ${#trash_paths} ]; do
			if command trash-rm "${trash_paths[i]}"; then
				echo -e "${GREEN}✓ Removed from trash: ${trash_paths[i]}${NC}"
			else
				echo -e "${RED}✗ Warning: Could not remove from trash or item not found: ${trash_paths[i]}${NC}"
			fi
			((i++))
		done
		echo -e "${GREEN}Deletion from trash completed.${NC}"
	else
		echo -e "${BLUE}Deletion cancelled.${NC}"
	fi
}
