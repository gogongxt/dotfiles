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
#🔼🔼🔼

#🔽🔽🔽
# TMUX config
# if set this , home and end in tmux will be strange, need remap home and end in tmux.
export TERM=xterm-256color

alias tmux="tmux -u"
alias tmux-ls="tmux list-sessions"
alias tmux-cd="tmux -u attach-session -t"
alias tmux-rm="tmux kill-session -t"
alias tmux-reboot="tmux kill-server && tmux || tmux"

# default set TMUX in tmux. 
# if [[ -v TMUX ]];
# then
#     # unset TMUX
# fi
#🔼🔼🔼

#🔽🔽🔽
#git
alias g="gitui"
alias gl="git --no-pager log --pretty=format:'%C(auto)%h%d %C(cyan)(%ci) %C(green)%cn %C(reset)%s'  --all --graph --abbrev-commit -5"
alias gll="git --no-pager log --pretty=format:'%C(auto)%h%d %C(cyan)(%ci) %C(green)%cn %C(reset)%s'  --all --graph --abbrev-commit -10"
alias glll="git --no-pager log --pretty=format:'%C(auto)%h%d %C(cyan)(%ci) %C(green)%cn %C(reset)%s'  --all --graph --abbrev-commit -20"
alias gllll="git --no-pager log --pretty=format:'%C(auto)%h%d %C(cyan)(%ci) %C(green)%cn %C(reset)%s'  --all --graph --abbrev-commit"
alias gam='git add . && echo "exec git add all" && git commit -m '
#🔼🔼🔼

#🔽🔽🔽
# proxychains / proxyhains4
hash proxychains4 2>/dev/null && { alias pro='proxychains4'; }
hash proxychains 2>/dev/null && { alias pro='proxychains'; }
#🔼🔼🔼

#🔽🔽🔽
# set proxy
# reference https://wiki.archlinux.org/title/Proxy_server
local proxy="127.0.0.1:7890"
function proxy_on() {
    if (( $# > 0 )); then
        # get "ip:port" format
        valid=$(echo $@ | sed -E 's/([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}):([0-9]+)/\1:\2/')
        if [[ $valid != $@ ]]; then
            >&2 echo "Invalid address"
            return 1
        fi
        local proxy=$1
    fi

    export http_proxy=$proxy \
           https_proxy=$proxy \
           HTTP_PROXY=$proxy \
           HTTPS_PROXY=$proxy \
           ftp_proxy=$proxy \
           FTP_PROXY=$proxy \
           rsync_proxy=$proxy \
           RSYNC_PROXY=$proxy
    echo -e "Proxy environment variable seted."
    echo "Note that sudo will not use proxy"
    echo "proxy=$proxy"
}
function proxy_off(){
    unset http_proxy https_proxy ftp_proxy rsync_proxy \
          HTTP_PROXY HTTPS_PROXY FTP_PROXY RSYNC_PROXY
    echo -e "Proxy environment variable removed."
}
function proxy_status(){
    if [ -z ${http_proxy+x} ] && [ -z ${https_proxy+x} ] ;
    then
    	echo -e "No Proxy environment."
    else
    	echo -e "Have Proxy environment."
    fi 
    echo -e "http_proxy: ${http_proxy}"
    echo -e "HTTP_PROXY: ${HTTP_PROXY}"
    echo -e "https_proxy: ${https_proxy}"
    echo -e "HTTPS_PROXY: ${HTTPS_PROXY}"
    echo -e "ftp_proxy: ${ftp_proxy}"
    echo -e "FTP_PROXY: ${FTP_PROXY}"
    echo -e "rsync_proxy: ${rsync_proxy}"
    echo -e "RSYNC_PROXY: ${RSYNC_PROXY}"
}
#🔼🔼🔼

#🔽🔽🔽
# alias
alias r="ranger"
alias e="extract"
command -v lolcat &>/dev/null && alias neofetch="neofetch | lolcat"
# 依次检测bat/cat是否存在，存在替换成对应的，推荐使用bat，并且使用--style=plain更朴素一点
# command -v ccat &>/dev/null && alias cat="ccat"
alias cat='bash -c '\''my_cat=""; if command -v bat >/dev/null 2>&1; then my_cat="bat --style=plain"; else if command -v ccat >/dev/null 2>&1; then my_cat="ccat"; else my_cat="cat"; fi; fi; if [ $# -gt 0 ]; then $my_cat "$@"; else $my_cat .; fi'\'' bash'
# 依次检测lvim/nvim是否存在，存在替换成对应的
alias v='bash -c '\''my_vim=""; if command -v nvim >/dev/null 2>&1; then my_vim="nvim"; else if command -v lvim >/dev/null 2>&1; then my_vim="lvim"; else my_vim="vim"; fi; fi; if [ $# -gt 0 ]; then $my_vim "$@"; else $my_vim .; fi'\'' bash'
alias vim='bash -c '\''my_vim=""; if command -v nvim >/dev/null 2>&1; then my_vim="nvim"; else if command -v lvim >/dev/null 2>&1; then my_vim="lvim"; else my_vim="vim"; fi; fi; if [ $# -gt 0 ]; then $my_vim "$@"; else $my_vim .; fi'\'' bash'
#🔼🔼🔼

#🔽🔽🔽
# neovim
export EDITOR=$(bash -c 'if command -v nvim >/dev/null 2>&1; then echo "nvim"; elif command -v lvim >/dev/null 2>&1; then echo "lvim"; else echo "vim"; fi')
# export EDITOR='nvim'
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
alias myssh='bash ~/.scripts/ssh/myssh.sh'
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

# solve bug ssh zsh-vi-mode will caplitalizes the last character
unset zle_bracketed_paste
