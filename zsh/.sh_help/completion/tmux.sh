#🔽🔽🔽
# TMUX config
# if set this , home and end in tmux will be strange, need remap home and end in tmux.
export TERM=xterm-256color
export TMUX_EXEC=$(which tmux) # remember tmux executable path
tmux_choose_window() {
    # 检查是否在 tmux 中
    if [[ -z "$TMUX" ]]; then
        # 不在 tmux 中，检查是否有可用的会话
        sessions=$(tmux ls 2>/dev/null)
        if [[ -z "$sessions" ]]; then
            echo "no server running"
            return 1
        fi
        # 获取第一个会话的名称
        first_session=$(echo "$sessions" | head -n 1 | cut -d: -f1)
        echo $first_session
        # 附加到会话并执行 choose-window
        $TMUX_EXEC attach -t "$first_session" \; choose-window
    else
        # 已经在 tmux 中，直接执行 choose-window
        $TMUX_EXEC choose-window
    fi
}
tmux() {
    case "$1" in
        rm|kill)
            shift
            command tmux kill-session -t "$@"
            ;;
        ls)
            shift
            command tmux ls
            ;;
        sw)
            shift
            tmux_choose_window
            ;;
        reboot)
            shift
            command tmux kill-server && command tmux || command tmux
            ;;
        save)
            shift
            command tmux capture-pane -p -S - > tmux.txt && echo 'content saved to ./tmux.txt'
            ;;
        *)
            if [[ $# -eq 0 ]]; then
                command tmux -u
                return
            fi
            local session_name="$1"
            local start_directory="$2"
            if [[ -n "$TMUX" ]]; then
                if command tmux has-session -t "$session_name" 2>/dev/null; then
                    command tmux switch-client -t "$session_name"
                else
                    if [[ -n "$start_directory" ]]; then
                        command tmux new-session -s "$session_name" -c "$start_directory"
                    else
                        command tmux new-session -s "$session_name"
                    fi
                fi
            else
                if command tmux -u attach-session -t "$session_name" 2>/dev/null; then
                    # On success, do nothing.
                    :
                else
                    # If attach fails, the session doesn't exist, so create it.
                    if [[ -n "$start_directory" ]]; then
                        command tmux -u new-session -s "$session_name" -c "$start_directory"
                    else
                        command tmux -u new-session -s "$session_name"
                    fi
                fi
            fi
            ;;
    esac
}

# ---------------- Bash 补全函数 ----------------
_tmux_completion_bash() {
    local cur prev words cword
    _get_comp_words_by_ref -n : cur prev words cword

    local subcommands="ls rm kill sw reboot save"
    local sessions=$(command tmux ls -F '#S' 2>/dev/null)

    if [ "$cword" -eq 1 ]; then
        # 第一个参数可以是会话名或子命令
        COMPREPLY=($(compgen -W "${subcommands} ${sessions}" -- "${cur}"))
        return 0
    fi

    case "${words[1]}" in
        rm|kill)
            # rm/kill 命令需要会话名作为参数
            COMPREPLY=($(compgen -W "${sessions}" -- "${cur}"))
            ;;
    esac
}

# ---------------- Zsh 补全函数 ----------------
_tmux_completion_zsh() {
    local -a subcommands
    local state
    # 定义静态子命令和它们的描述
    subcommands=(
        'ls:List active sessions'
        'rm:Kill a session'
        'kill:Kill a session (alias for rm)'
        'sw:Switch window'
        'reboot:Kill and restart tmux server'
        'save:Save pane content to a file'
    )
    # 动态获取会话列表
    # 使用 -F '#S' 可以只输出会话名称，更稳定
    local -a sessions
    sessions=($(command tmux ls -F '#S' 2>/dev/null))
    # Zsh 补全的核心逻辑
    _arguments -C \
        '1: :->first_arg' \
        '2: :->second_arg'
    case $state in
        first_arg)
            # 当补全第一个参数时，同时提供子命令和会话列表
            _describe 'session to attach' sessions
            _describe 'subcommand' subcommands
            ;;
        second_arg)
            # 当补全第二个参数时，根据第一个参数的内容决定补全项
            case "$words[2]" in
                rm|kill)
                    _describe 'session to kill' sessions
                    ;;
            esac
            ;;
    esac
    return 0
}

# ---------------- 自动注册补全 ----------------
if [[ -n ${ZSH_VERSION:+zsh} ]]; then
    compdef _tmux_completion_zsh tmux
elif [[ -n ${BASH_VERSION:+bash} ]]; then
    if type -t _command &>/dev/null; then
        complete -F _tmux_completion_bash tmux
    else
        echo "警告: bash-completion 未安装，tmux 补全不可用。" >&2
    fi
fi
