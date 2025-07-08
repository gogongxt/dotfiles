# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH="$HOME/.local/bin":$PATH
export PATH="$HOME/.cargo/bin":$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="ys"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

#历史纪录条目数量
export HISTSIZE=10000
export SAVEHIST=10000
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
	git
	zsh-autosuggestions
	zsh-syntax-highlighting
    sudo
	extract
	zsh-vi-mode
)
command -v fzf &>/dev/null && plugins+=(fzf)

# plugin: zsh-vi-mode
ZVM_VI_INSERT_ESCAPE_BINDKEY=jk # press "jk" to enter normal mode
ZVM_ESCAPE_TIMEOUT=0.1 # wait time for escape bind key (default is 0.3s)
ZVM_VI_EDITOR=nvim # visual mode "vv" use editor to edit cmd
ZVM_INIT_MODE=sourcing

# plugin: zsh-autosuggestions
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"


#🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽
################################################
################################################
### Under is my config #########################
################################################
################################################

# source my other config zsh file
#🔽🔽🔽
if [ -f $HOME/.arch.zsh ]; then  
    source $HOME/.arch.zsh  
fi
if [ -f $HOME/.user.zsh ]; then  
    source $HOME/.user.zsh  
fi
if [ -f $HOME/.sh_help/init.sh ]; then  
    source $HOME/.sh_help/init.sh  
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
# neovim
export EDITOR=$(bash -c 'if command -v nvim >/dev/null 2>&1; then echo "nvim"; elif command -v lvim >/dev/null 2>&1; then echo "lvim"; else echo "vim"; fi')
# export EDITOR='nvim'
#🔼🔼🔼

#🔽🔽🔽
# alias
command -v yazi &>/dev/null && alias r="yazi" || alias r="ranger"
alias y="yazi"
alias e="extract"
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
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
# __conda_setup="$('/home/gxt_kt/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
__conda_setup="$($HOME/miniconda3/bin/conda shell.zsh hook 2>/dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
        . "$HOME/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="$HOME/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
#🔼🔼🔼

#🔽🔽🔽
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
#🔼🔼🔼

#🔽🔽🔽
# scripts alias
alias cmr='bash ~/.scripts/cmake/compile.sh cmr'
alias mr='bash ~/.scripts/cmake/compile.sh mr'
alias dump='bash ~/.scripts/code/dump.sh'
alias count_lines='python3 ~/.scripts/code/count_lines.py'
alias words_to_mp3='python3 ~/.scripts/english_helper/generate_mp3_from_words.py'
# alias myssh='bash ~/.scripts/ssh/myssh.sh'
alias myssh='python3 ~/.scripts/ssh/myssh.py'
alias password='python3 ~/.scripts/ssh/password.py'
alias myssh-edit='$EDITOR ~/.scripts/ssh/servers.yaml'
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

# zoxide
#🔽🔽🔽
if command -v zoxide &> /dev/null; then  
    eval "$(zoxide init zsh)"
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

# set direnv
#🔽🔽🔽
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"
#🔼🔼🔼

