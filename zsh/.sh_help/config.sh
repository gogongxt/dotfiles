CURRENT_SHELL=$(basename $(ps -p $$ -o comm= | sed 's/^-//')) # zsh or bash
case $CURRENT_SHELL in
zsh | bash) ;;
*) echo "Unsupported shell: $CURRENT_SHELL" >&2 ;;
esac

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="/usr/local/go/bin:$PATH"
export XDG_CONFIG_HOME="$HOME/.config"

#🔽🔽🔽
#git
alias g="gitui"
# alias serie="serie -p kitty"
# unalias serie
alias gg="serie"
alias gs="git status"
alias gr="git remote -v"
alias gt='
tag=$(
  git tag --sort=-creatordate | fzf \
    --ansi \
    --preview "git --no-pager log --color=always --pretty=format:\"%C(auto)%h %C(cyan)(%cd) %C(green)%cn %C(reset)%s\" --date=format:\"%Y-%m-%d %H:%M:%S\" -80 {}" \
    --preview-window=down:70%
)
if [ -n "$tag" ]; then
  echo -e "\033[33m❯ git checkout $tag\033[0m"
  git checkout "$tag"
fi
'
alias gb='
current=$(git branch --show-current)
branch=$(
  {
    echo "$current"
    git branch --format="%(refname:short)" | grep -v "^$current$"
  } | fzf \
    --ansi \
    --preview "git --no-pager log --color=always --pretty=format:\"%C(auto)%h %C(cyan)(%cd) %C(green)%cn %C(reset)%s\" --date=format:\"%Y-%m-%d %H:%M:%S\" -80 {}" \
    --preview-window=down:70%
)
if [ -z "$branch" ]; then
  return
elif [ "$branch" = "$current" ]; then
  echo "Already on branch: $current"
else
  echo -e "\033[33m❯ git checkout $branch\033[0m"
  git checkout "$branch"
fi
'
unalias gl gll glll gllll 2>/dev/null
_gl() {
  local count="$1"
  git --no-pager log --pretty=format:'%C(auto)%h%d %C(cyan)(%cd) %C(green)%cn %C(reset)%s' --date=format:'%Y-%m-%d %H:%M:%S' --all --graph --abbrev-commit "-${count}"
}
gl()   { _gl "${1:-10}"; }
gll()  { _gl "${1:-20}"; }
glll() { _gl "${1:-40}"; }
gllll() {
  git --no-pager log --color=always --pretty=format:'%C(auto)%h%d %C(cyan)(%cd) %C(green)%cn %C(reset)%s' --date=format:'%Y-%m-%d %H:%M:%S' --all --graph --abbrev-commit | fzf --ansi --no-preview
}
alias gam='git add . && echo "exec git add all" && git commit -m '
alias gcm='git commit --amend'
#🔼🔼🔼

#🔽🔽🔽
if command -v nvim >/dev/null 2>&1; then
  if [ -z "$NVIM_APPNAME" ] && [ ! -d "$HOME/.config/nvim" ] && [ -f "$HOME/.vimrc" ]; then
    MY_VIM_CMD="nvim -u ~/.vimrc"
  else
    MY_VIM_CMD="nvim"
  fi
elif command -v vim >/dev/null 2>&1; then
  MY_VIM_CMD="vim"
else
  MY_VIM_CMD="vi"
fi
myvim() {
  if [ $# -gt 0 ]; then
    local first_arg="$1"
    local use_vim=0
    # 检查第一个参数是否是文件
    if [ -f "$first_arg" ]; then
      # 获取文件大小 (字节)
      local file_size=$(stat -c%s "$first_arg" 2>/dev/null || stat -f%z "$first_arg" 2>/dev/null)
      local size_mb=$((file_size / 1024 / 1024))
      # 获取文件行数
      local line_count=$(wc -l < "$first_arg" 2>/dev/null | tr -d ' ')
      # 获取最大单行长度 (扫描前1000行)
      local max_line_length=$(head -n 1000 "$first_arg" | awk '{ if (length > max) max = length } END { print max+0 }')
      # 如果文件大于10MB 或行数大于100000 或单行超过5000字符，使用vim
      if [ "$size_mb" -gt 10 ] || [ "$line_count" -gt 100000 ] || [ "$max_line_length" -gt 5000 ]; then
        use_vim=1
      fi
    fi
    if [ "$use_vim" -eq 1 ]; then
      if command -v vim >/dev/null 2>&1; then
        vim "$@"
      else
        eval "$MY_VIM_CMD \"\$@\""
      fi
    else
      eval "$MY_VIM_CMD \"\$@\""
    fi
  else
    eval "$MY_VIM_CMD ."
  fi
}
alias v="myvim"
alias vim="myvim"
export EDITOR="$MY_VIM_CMD"
# export EDITOR='nvim'
# export VISUAL="$EDITOR --cmd 'let g:flatten_wait=1'"
# export VISUAL="" # not set to null string otherwise cause git edit problem
#🔼🔼🔼

#🔽🔽🔽
# alias
command -v python &>/dev/null || alias python="python3"
command -v yazi &>/dev/null && alias r="yazi" || alias r="ranger"
command -v fastfetch &>/dev/null && alias neofetch="fastfetch"
command -v lolcat &>/dev/null && alias fastfetch="fastfetch | lolcat"
alias mycp="rsync -avz --progress"
alias mycp_parallel="rclone copy --transfers 32 --create-empty-src-dirs --progress --copy-links"
alias mycp_parallel_4="rclone copy --transfers 32 --create-empty-src-dirs --progress --copy-links --multi-thread-streams=4 --local-no-check-updated"
# alias mycp_parallel="rclone copy --transfers 32 --create-empty-src-dirs --progress --copy-links --multi-thread-streams=4 --multi-thread-chunk-size 1024M --multi-thread-write-buffer-size 512M --local-no-check-updated"
alias mywget="aria2c -x 16 -s 16"
export BAT_THEME="Catppuccin Frappe"
command -v bat &>/dev/null && alias cat="bat --style=plain"
command -v eza &>/dev/null && {
  unset LS_COLORS
  export EZA_CONFIG_DIR="$HOME/.config/eza"
  EZA_PREFIX=(
    --group 
    # --git
    # --icons 
  )
	alias ls="eza $EZA_PREFIX"
	alias ll="eza $EZA_PREFIX -l"
	alias la="eza $EZA_PREFIX -a"
	alias lla="eza $EZA_PREFIX -la"
	unset EZA_PREFIX
}
# alias clear="printf '\033c'"
# alias c="printf '\033c'"
alias c="/usr/bin/clear"
alias b="btop"
alias h="htop"
command -v nvidia-smi &>/dev/null && alias nv="watch -d -n 1 nvidia-smi"
command -v npu-smi &>/dev/null && alias nv="watch -d -n 1 'npu-smi info'"
#🔼🔼🔼

#🔽🔽🔽
# fzf
fzf_ignore=".wine,.git,.idea,.vscode,node_modules,build"
export FZF_DEFAULT_COMMAND="fd --hidden --follow --exclude={${fzf_ignore}} "
export FZF_DEFAULT_OPTS="--height 80% --layout=reverse --preview 'echo {} | ~/.sh_help/functions/fzf_preview.py' --preview-window=down --border \
  --bind 'ctrl-d:page-down,ctrl-u:page-up' \
  --bind 'ctrl-f:preview-half-page-down,ctrl-b:preview-half-page-up' \
  --bind 'alt-p:change-preview-window(right|hidden|down)' \
  --color=bg+:#555555
"
export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window=down:wrap
"
# for zoxide
export _ZO_FZF_OPTS="
  $FZF_DEFAULT_OPTS
  --header='   =:increment   -:decrement   C-x:delete'
  --bind '=:reload(zoxide edit increment {2..})'
  --bind '-:reload(zoxide edit decrement {2..})'
  --bind 'ctrl-x:reload(zoxide edit delete {2..})'
  --preview 'ls -aC --color=always {2}'
"
# _fzf_compgen_path() {
#   fd --hidden --follow --exclude={${fzf_ignore}}
# }
# _fzf_compgen_dir() {
#   fd --type d --hidden --exclude={${fzf_ignore}}
# }
# optimizer fzf for zsh or bash
command -v fzf &>/dev/null && source <(fzf --${CURRENT_SHELL})
unset fzf_ignore
#🔼🔼🔼

#🔽🔽🔽
# docker display
command -v xhost &>/dev/null && xhost + &>/dev/null
# docker proxy 
# Ref: https://github.com/DaoCloud/public-image-mirror
# usage: sudo docker pull $DOCKER_PROXY/lmsysorg/sglang:blackwell
export DOCKER_PROXY="docker.m.daocloud.io"
#🔼🔼🔼

#🔽🔽🔽
# scripts alias
alias cmr='bash ~/.scripts/cmake/compile.sh cmr'
alias mr='bash ~/.scripts/cmake/compile.sh mr'
alias dump='bash ~/.scripts/code/dump.sh'
alias count_lines='python3 ~/.scripts/code/count_lines.py'
alias words_to_mp3='python3 ~/.scripts/english_helper/generate_mp3_from_words.py'
alias myssh='python3 ~/.scripts/ssh/myssh.py'
alias disk_speed='bash ~/.scripts/other/disk_speed.sh'
alias password='python3 ~/.scripts/ssh/password.py'
alias documents='python3 ~/.scripts/code/documents.py'
alias specstory_clean='python3 ~/.scripts/code/specstory_clean.py'
if command -v claude >/dev/null 2>&1; then
  claude() {
    local args=("$@")
    (
      set --
      source ~/.zshrc
      proxy off >/dev/null 2>&1
      CMD=("${CLAUDE_CMD[@]:-claude}")
      if command -v specstory >/dev/null 2>&1; then
        # specstory run claude -c 'ccr code' --no-cloud-sync "$@"
        local quoted_args=("${(@qq)args}")
        specstory run claude --no-cloud-sync -c "${CMD[*]} ${quoted_args[*]}"
      else
        command "${CMD[@]}" "${args[@]}"
      fi
    )
  }
fi
alias claude_init='claude -p "/init"'
#🔼🔼🔼

# rust cargo
#🔽🔽🔽
command -v sccache &>/dev/null && export RUSTC_WRAPPER="`which sccache`"
#🔼🔼🔼

# cmake
#🔽🔽🔽
export CMAKE_EXPORT_COMPILE_COMMANDS=1 # enable cmake generate compile json file
alias cmake_build='cmake -S. -Bbuild && cmake --build build -j'
alias cmake_build_debug='cmake -S. -Bbuild/debug -DCMAKE_BUILD_TYPE=Debug && cmake --build build/debug -j'
alias cmake_build_release='cmake -S. -Bbuild/release -DCMAKE_BUILD_TYPE=Release && cmake --build build/release -j'
alias cmake_install='sudo cmake --install build'
alias cmake_install_debug='sudo cmake --install build/debug'
alias cmake_install_release='sudo cmake --install build/release'
#🔼🔼🔼

# set direnv
#🔽🔽🔽
command -v direnv &>/dev/null && eval "$(direnv hook ${CURRENT_SHELL})"
#🔼🔼🔼

# zoxide
#🔽🔽🔽
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init ${CURRENT_SHELL})"
  z() {
    if [[ $# -eq 0 ]]; then
      __zoxide_zi
    else
      __zoxide_z $@
    fi
  }
  j() {
    z $@
  }
fi
#🔼🔼🔼

# pycd: cd to python lib packages path
#🔽🔽🔽
pycd() {
  # 获取当前Python解释器的路径
  python3 --version 2>/dev/null || python --version 2>/dev/null
  which python3 2>/dev/null || which python 2>/dev/null
  local python_path=$(which python3 2>/dev/null || which python 2>/dev/null)
  if [ -z "$python_path" ]; then
    echo "Error: Python not found in PATH" >&2
    return 1
  fi
  # 检查是否是conda环境
  if [[ "$python_path" == *"conda"* ]] || [[ "$python_path" == *"miniconda"* ]] || [ -n "$CONDA_PREFIX" ]; then
    # Conda环境处理
    local conda_env_path=""
    if [ -n "$CONDA_PREFIX" ]; then
        conda_env_path="$CONDA_PREFIX"
    else
        # 如果不是通过conda activate激活的环境，尝试从路径中提取
        conda_env_path=$(dirname $(dirname "$python_path"))
    fi
    local site_packages="$conda_env_path/lib/python$($python_path -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")/site-packages"
    if [ -d "$site_packages" ]; then
        cd "$site_packages"
        echo "Changed to conda site-packages: $site_packages"
    else
        echo "Error: Conda site-packages directory not found: $site_packages" >&2
        return 1
    fi
  else
    # 系统Python或虚拟环境处理
    local python_lib=$($python_path -c "import sysconfig; print(sysconfig.get_path('purelib'))")
    if [ -d "$python_lib" ]; then
        cd "$python_lib"
        echo "Changed to Python site-packages: $python_lib"
    else
        echo "Error: Python site-packages directory not found: $python_lib" >&2
        return 1
    fi
  fi
}
#🔼🔼🔼

# ======================================================                                                    
#  Lazy Load Conda for Faster Shell Startup                                                                 
# ======================================================                                                    
#🔽🔽🔽
function conda() {
  # 确定 conda 安装路径
  local conda_path
  if [ -n "$CONDA_PATH" ]; then
    conda_path="$CONDA_PATH"
  elif [ -d "$HOME/miniconda3" ]; then
    conda_path="$HOME/miniconda3"
  else
    echo "Error: Neither CONDA_PATH is set nor $HOME/miniconda3 exists." >&2
    return 1
  fi
  # 检查 conda_path 是否存在且是有效目录
  if [ ! -d "$conda_path" ]; then
    echo "Error: Conda path '$conda_path' is not a valid directory." >&2
    return 1
  fi
  # 检查 conda 二进制文件是否存在
  local conda_bin="$conda_path/bin/conda"
  if [ ! -f "$conda_bin" ]; then
    echo "Error: Conda binary not found at '$conda_bin'. Please check your conda installation." >&2
    return 1
  fi
  # 移除这个临时的 conda 函数定义，以便后续直接调用真正的 conda 命令
  unset -f conda
  # --- Conda 初始化核心逻辑 ---
  # 这部分逻辑直接取自 'conda init'，确保与官方行为一致
  local conda_bin="$conda_path/bin/conda"
  __conda_setup="$('$conda_bin' 'shell.zsh' 'hook' 2>/dev/null)"
  if [ $? -eq 0 ]; then
    eval "$__conda_setup"
  else
    local conda_sh_path="$conda_path/etc/profile.d/conda.sh"
    if [ -f "$conda_sh_path" ]; then
      . "$conda_sh_path"
    else
      export PATH="$conda_path/bin:$PATH"
    fi
  fi
  unset __conda_setup
  # --- Conda 初始化结束 ---
  # 现在 Conda 已经初始化完毕，执行你最初想要运行的命令
  # "$@" 会将所有传递给此函数的参数原封不动地传递给真正的 conda 命令
  # 例如，你输入 "conda activate base"，"$@" 就是 "activate base"
  conda "$@"
}
#🔼🔼🔼

#🔽🔽🔽
# Custom ctrl+w / ctrl+shift+w backward delete word
if [ -n "$ZSH_VERSION" ]; then
  ## keep default
  # WORDCHARS=''
  # my-backward-delete-word() {
  #   zle backward-delete-word
  # }
  # zle -N my-backward-delete-word
  # bindkey '^W' my-backward-delete-word
  my-backward-delete-whole-word() {
    local WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>:'
    zle backward-delete-word
  }
  zle -N my-backward-delete-whole-word
  # default CSIu keymap for c-s-w
  bindkey "\e[119;6u" my-backward-delete-whole-word
  # hack with kitty set keymap
  bindkey "\e[500~" my-backward-delete-whole-word
fi
#🔼🔼🔼
