# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

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

#🔽🔽🔽
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
#🔼🔼🔼

# source my other config zsh file
#🔽🔽🔽
if [ -f $HOME/.sh_help/init.sh ]; then  
    source $HOME/.sh_help/init.sh  
fi
#🔼🔼🔼

#🔽🔽🔽
# # >>> conda initialize >>>                                                                                
# # !! Contents within this block are managed by 'conda init' !!                                            
# __conda_setup="$('/nfs/volume-1757-3/user/gogongxt/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
# if [ $? -eq 0 ]; then                                                                                     
#     eval "$__conda_setup"
# else                                                                                                      
#     if [ -f "/nfs/volume-1757-3/user/gogongxt/miniconda3/etc/profile.d/conda.sh" ]; then                  
#         . "/nfs/volume-1757-3/user/gogongxt/miniconda3/etc/profile.d/conda.sh"                            
#     else                                                                                                  
#         export PATH="/nfs/volume-1757-3/user/gogongxt/miniconda3/bin:$PATH"                               
#     fi                                                                                                    
# fi                                                                                                        
# unset __conda_setup                                                                                       
# # <<< conda initialize <<<                                                                                
#🔼🔼🔼                                                                                                     
# ======================================================                                                    
#  Lazy Load Conda for Faster Shell Startup                                                                 
# ======================================================                                                    
function conda() {                                                                                          
    # 移除这个临时的 conda 函数定义，以便后续直接调用真正的 conda 命令                                      
    unset -f conda                                                                                          
    # --- Conda 初始化核心逻辑 ---                                                                          
    # 这部分逻辑直接取自 'conda init'，确保与官方行为一致                                                   
    local conda_bin="/nfs/volume-1757-3/user/gogongxt/miniconda3/bin/conda"                                 
    __conda_setup="$('$conda_bin' 'shell.zsh' 'hook' 2> /dev/null)"                                         
    if [ $? -eq 0 ]; then                                                                                   
        eval "$__conda_setup"                                                                               
    else                                                                                                    
        local conda_sh_path="/nfs/volume-1757-3/user/gogongxt/miniconda3/etc/profile.d/conda.sh"            
        if [ -f "$conda_sh_path" ]; then                                                                    
            . "$conda_sh_path"                                                                              
        else                                                                                                
            export PATH="/nfs/volume-1757-3/user/gogongxt/miniconda3/bin:$PATH"                             
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
