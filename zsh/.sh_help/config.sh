export PATH="$HOME/.local/bin":$PATH
export PATH="$HOME/.cargo/bin":$PATH

# source my other config zsh file
#🔽🔽🔽
if [ -f $HOME/.arch.zsh ]; then  
    source $HOME/.arch.zsh  
fi
if [ -f $HOME/.user.zsh ]; then  
    source $HOME/.user.zsh  
fi
#🔼🔼🔼

#🔽🔽🔽
#git
alias g="gitui"
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
command -v yazi &>/dev/null && alias r="yazi" || alias r="ranger"
alias y="yazi"
alias e="extract"
alias c="clear"
command -v lolcat &>/dev/null && alias neofetch="neofetch | lolcat"
# 依次检测bat/cat是否存在，存在替换成对应的，推荐使用bat，并且使用--style=plain更朴素一点
# command -v ccat &>/dev/null && alias cat="ccat"
alias cat='bash -c '\''my_cat=""; if command -v bat >/dev/null 2>&1; then my_cat="bat --style=plain"; else if command -v ccat >/dev/null 2>&1; then my_cat="ccat"; else my_cat="cat"; fi; fi; if [ $# -gt 0 ]; then $my_cat "$@"; else $my_cat .; fi'\'' bash'
# 依次检测lvim/nvim是否存在，存在替换成对应的
alias v='bash -c '\''my_vim=""; if command -v nvim >/dev/null 2>&1; then my_vim="nvim"; else if command -v lvim >/dev/null 2>&1; then my_vim="lvim"; else my_vim="vim"; fi; fi; if [ $# -gt 0 ]; then $my_vim "$@"; else $my_vim .; fi'\'' bash'
alias vim='bash -c '\''my_vim=""; if command -v nvim >/dev/null 2>&1; then my_vim="nvim"; else if command -v lvim >/dev/null 2>&1; then my_vim="lvim"; else my_vim="vim"; fi; fi; if [ $# -gt 0 ]; then $my_vim "$@"; else $my_vim .; fi'\'' bash'
alias v-edit="$EDITOR $HOME/.config/nvim"
alias vim-edit="$EDITOR $HOME/.config/nvim"
alias nvim-edit="$EDITOR $HOME/.config/nvim"
#🔼🔼🔼

#🔽🔽🔽
# fzf
local fzf_ignore=".wine,.git,.idea,.vscode,node_modules,build"
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
command -v fzf &>/dev/null && source <(fzf --zsh)
#🔼🔼🔼

#🔽🔽🔽
# docker display
xhost +&>/dev/null
#🔼🔼🔼

#🔽🔽🔽
# scripts alias
alias cmr='bash ~/.scripts/cmake/compile.sh cmr'
alias mr='bash ~/.scripts/cmake/compile.sh mr'
alias dump='bash ~/.scripts/code/dump.sh'
alias count_lines='python3 ~/.scripts/code/count_lines.py'
alias words_to_mp3='python3 ~/.scripts/english_helper/generate_mp3_from_words.py'
# alias myssh='bash ~/.scripts/ssh/myssh.sh'
alias myssh='bash ~/.scripts/ssh/myssh.sh'
alias password='python3 ~/.scripts/ssh/password.py'
alias documents='python3 ~/.scripts/code/documents.py'
#🔼🔼🔼

# enable cmake generate compile json file
#🔽🔽🔽
export CMAKE_EXPORT_COMPILE_COMMANDS=1
#🔼🔼🔼

# trash-cli alis : https://github.com/andreafrancia/trash-cli
#🔽🔽🔽
alias rm='bash -c '\''my_rm=""; if command -v trash-put >/dev/null 2>&1; then my_rm="trash-put"; else my_rm="rm"; fi; if [ "$#" -gt 0 ]; then $my_rm "$@"; fi'\'' _'
alias trash-autoclean='trash-empty 30'
alias trash-cd='cd ${HOME}/.local/share/Trash'
alias trash-ls='trash-list'
alias trash-ll='trash-ls'
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
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"
#🔼🔼🔼

