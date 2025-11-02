CURRENT_SHELL=$(basename $(ps -p $$ -o comm= | sed 's/^-//')) # zsh or bash
case $CURRENT_SHELL in
zsh | bash) ;;
*) echo "Unsupported shell: $CURRENT_SHELL" >&2 ;;
esac

export PATH="$HOME/.local/bin":$PATH
export PATH="$HOME/.cargo/bin":$PATH

#🔽🔽🔽
#git
alias g="gitui"
alias serie="serie -p kitty"
alias gg="serie"
alias gs="git status"
alias gl="git --no-pager log --pretty=format:'%C(auto)%h%d %C(cyan)(%ci) %C(green)%cn %C(reset)%s'  --all --graph --abbrev-commit -5"
alias gll="git --no-pager log --pretty=format:'%C(auto)%h%d %C(cyan)(%ci) %C(green)%cn %C(reset)%s'  --all --graph --abbrev-commit -10"
alias glll="git --no-pager log --pretty=format:'%C(auto)%h%d %C(cyan)(%ci) %C(green)%cn %C(reset)%s'  --all --graph --abbrev-commit -20"
alias gllll="git --no-pager log --pretty=format:'%C(auto)%h%d %C(cyan)(%ci) %C(green)%cn %C(reset)%s'  --all --graph --abbrev-commit"
alias gam='git add . && echo "exec git add all" && git commit -m '
alias gcm='git commit --amend'
function gsp() {
  local stashed_something=0
  # 检查工作区和暂存区是否有未提交的更改, git diff-index --quiet HEAD -- 会在有更改时返回1，没有更改时返回0
  if ! git diff-index --quiet HEAD --; then
    echo " stash (储藏本地更改)..."
    # 使用 git stash push 并附带一条信息，方便识别 -u 参数表示同时储藏未被追踪的文件
    if git stash push -u -m "gsp-stash-$(date +%s)"; then
      stashed_something=1
    else
      echo " 'git stash' failed. Aborting. " >&2
      return 1
    fi
  else
    echo " Working directory is clean. No need to stash."
  fi
  echo " pull $@ ..."
  # 将所有传递给函数的参数 ($@) 传递给 git pull
  if ! git pull "$@"; then
    echo " 'git pull' failed." >&2
    # 如果拉取失败，并且我们之前确实储藏了东西，就尝试恢复它
    if [ "$stashed_something" -eq 1 ]; then
      echo " Attempting to restore your stashed changes..."
      git stash pop
    fi
    return 1
  fi
  if [ "$stashed_something" -eq 1 ]; then # 如果我们之前储藏了更改，现在就把它恢复回来
    echo " apply stash ..."
    # 使用 pop 会在成功应用后删除该储藏，保持储藏列表干净
    if ! git stash pop; then
      echo " Warning: Could not automatically apply stash." >&2
      echo " Your changes are still in the stash list." >&2
      echo " Please resolve conflicts manually and then run 'git stash drop'. " >&2
      return 1
    fi
  fi
  echo " Done. Your branch is up-to-date and your changes are restored."
}
#🔼🔼🔼

#🔽🔽🔽
export EDITOR=$(bash -c 'if command -v nvim >/dev/null 2>&1; then echo "nvim"; elif command -v lvim >/dev/null 2>&1; then echo "lvim"; else echo "vim"; fi')
# export EDITOR='nvim'
#🔼🔼🔼

#🔽🔽🔽
# alias
command -v python &>/dev/null || alias python="python3"
command -v yazi &>/dev/null && alias r="yazi" || alias r="ranger"
command -v fastfetch &>/dev/null && alias neofetch="fastfetch"
command -v lolcat &>/dev/null && alias fastfetch="fastfetch | lolcat"
alias mycp="rsync -avz --progress"
alias mycp_parallel="rclone copy --create-empty-src-dirs --progress --copy-links"
alias mywget="aria2c -x 16 -s 16"
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
alias nv="watch -d -n 1 nvidia-smi"
vim() {
  local my_vim
  if command -v nvim >/dev/null 2>&1; then
    my_vim="nvim"
    if [ -z "$NVIM_APPNAME" ] && [ ! -d "$HOME/.config/nvim" ] && [ -f "$HOME/.vimrc" ]; then
        my_vim="nvim -u ~/.vimrc"
    fi
  else
    my_vim="vim"
  fi
  if [ $# -gt 0 ]; then
    eval "$my_vim \"\$@\""
  else
    eval "$my_vim ."
  fi
}
v() {
  vim "$@"
}
#🔼🔼🔼

#🔽🔽🔽
# fzf
fzf_ignore=".wine,.git,.idea,.vscode,node_modules,build"
export FZF_DEFAULT_COMMAND="fd --hidden --follow --exclude={${fzf_ignore}} "
export FZF_DEFAULT_OPTS="--height 80% --layout=reverse --preview 'echo {} | ~/.config/fzf/fzf_preview.py' --preview-window=down --border \
  --bind ctrl-d:page-down,ctrl-u:page-up \
  "
# _fzf_compgen_path() {
#   fd --hidden --follow --exclude={${fzf_ignore}}
# }
# _fzf_compgen_dir() {
#   fd --type d --hidden --exclude={${fzf_ignore}}
# }
# optimizer fzf for zsh
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
# alias myssh='bash ~/.scripts/ssh/myssh.sh'
alias myssh='python3 ~/.scripts/ssh/myssh_password.py'
alias myssh_plain='python3 ~/.scripts/ssh/myssh_plain_password.py'
alias password='python3 ~/.scripts/ssh/password.py'
alias documents='python3 ~/.scripts/code/documents.py'
#🔼🔼🔼

# enable cmake generate compile json file
#🔽🔽🔽
export CMAKE_EXPORT_COMPILE_COMMANDS=1
#🔼🔼🔼

# rust cargo
#🔽🔽🔽
command -v sccache &>/dev/null && export RUSTC_WRAPPER="`which sccache`"
#🔼🔼🔼

# cmake
#🔽🔽🔽
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
