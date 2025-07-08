#!/bin/bash

get_current_dir() {
  local script_path
  if [ -n "$BASH_VERSION" ]; then
    # 对于Bash，使用BASH_SOURCE数组获取最底层调用的脚本路径
    script_path="${BASH_SOURCE[0]}"
    while [ -L "$script_path" ]; do
      script_path=$(readlink -f "$script_path")
    done
  elif [ -n "$ZSH_VERSION" ]; then
    script_path="${(%):-%x}" || script_path="$0"
  else
    echo "Unsupported shell" >&2
    return 1
  fi
  # 解析目录路径
  local dir_path
  if command -v realpath >/dev/null 2>&1; then
    dir_path=$(dirname "$(realpath "$script_path")")
  else
    # 如果没有realpath，使用cd和pwd组合
    dir_path=$(cd "$(dirname "$script_path")" && pwd -P)
  fi
  echo "$dir_path"
}

CUR_SHELL="$1"
if [ -z "$CUR_SHELL" ]; then
  if [ -n "$ZSH_VERSION" ]; then
    CUR_SHELL="zsh"
  elif [ -n "$BASH_VERSION" ]; then
    CUR_SHELL="bash"
  else
    echo "⚠️ [ERROR] unknown shell，neither zsh and Bash"
    exit 1
  fi
fi

CUR_DIR="$(get_current_dir)"

source "$CUR_DIR/functions/copy.sh"
source "$CUR_DIR/functions/proxy.sh"
source "$CUR_DIR/completion/nsys.sh"
source "$CUR_DIR/completion/tmux.sh"

case "$CUR_SHELL" in
zsh)
  source "$CUR_DIR/zsh/zsh-vi-mode.zsh"
  ;;

bash)
  # source "$CUR_DIR/bash/init.sh"
  ;;

*)
  echo "错误：无效的参数 '$1'。请输入 'zsh' 或 'bash'。"
  exit 1
  ;;
esac

unset -f get_current_dir
unset CUR_DIR
unset CUR_SHELL
