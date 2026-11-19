#🔽🔽🔽
# TMUX config
# if set this , home and end in tmux will be strange, need remap home and end in tmux.
# export TERM=xterm-256color
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
        command tmux attach -t "$first_session" \; choose-window
    else
        # 已经在 tmux 中，直接执行 choose-window
        command tmux choose-window
    fi
}
# Help for this wrapper. tmux's own help is reached with `tmux -- -h`.
_tmux_help() {
    local BOLD=$'\033[1m' CYAN=$'\033[0;36m' YELLOW=$'\033[1;33m' DIM=$'\033[2m' NC=$'\033[0m'
    # Leave plain text for pipes, redirects and NO_COLOR users.
    if [[ ! -t 1 || -n "$NO_COLOR" || "$TERM" == "dumb" ]]; then
        BOLD='' CYAN='' YELLOW='' DIM='' NC=''
    fi
    cat <<EOF
${BOLD}Usage:${NC} tmux [subcommand] [args]

  ${CYAN}(no args)${NC}             start a new session in the current directory
  ${CYAN}<session> [dir]${NC}       attach to <session>, creating it if missing
  ${CYAN}ls | l | ll${NC}           list sessions
  ${CYAN}rm | kill <session>${NC}   kill a session
  ${CYAN}sw${NC}                    pick a window across sessions
  ${CYAN}cd [path]${NC}             show or set TMUX_WORKING_DIR used by new windows
  ${CYAN}save [file]${NC}           save the current pane's content to a file
  ${CYAN}reboot${NC}                restart the tmux server (discards every session)
  ${CYAN}rescue [server-pid]${NC}   rebuild the socket after its directory was deleted
  ${CYAN}-h | --help | help${NC}    show this help
  ${CYAN}-- <args>${NC}             pass <args> to tmux itself, e.g. tmux -- -h

${YELLOW}rescue:${NC}
  A tmux socket is only a connection endpoint; sessions live in the server
  process. If /tmp/tmux-UID is deleted, the server and its sessions keep
  running but new clients cannot connect. ${BOLD}tmux rescue${NC} recreates the
  directory and sends SIGUSR1 so the server binds its socket again, instead
  of ${DIM}pkill tmux${NC}, which would discard every session.
EOF
}

# Recreate a deleted tmux socket (directory + socket) without losing sessions.
# SIGUSR1 makes the server unlink and re-bind its own socket_path.
_tmux_rescue() {
    local pid="${1:-}" sockpath="" sockdir=""
    local -a pids=()

    if [[ "$pid" == "-h" || "$pid" == "--help" ]]; then
        local BOLD=$'\033[1m' CYAN=$'\033[0;36m' DIM=$'\033[2m' NC=$'\033[0m'
        if [[ ! -t 1 || -n "$NO_COLOR" || "$TERM" == "dumb" ]]; then
            BOLD='' CYAN='' DIM='' NC=''
        fi
        cat <<EOF
${BOLD}Usage:${NC} tmux rescue [server-pid]

Rebuild the tmux socket after /tmp/tmux-UID was deleted, without losing any
session. The server process keeps running when only the socket file or its
directory goes away; ${BOLD}SIGUSR1${NC} makes it unlink and re-bind the original path.

  ${CYAN}tmux rescue${NC}            pick the oldest running server (ppid 1), or the
                         server of the current pane when run inside tmux
  ${CYAN}tmux rescue <pid>${NC}      target a specific server process

Run it from a pane that still works, or from any shell. Afterwards clients
can attach again with ${DIM}tmux ls${NC} / ${DIM}tmux attach${NC}.
EOF
        return 0
    fi

    # Inside tmux, $TMUX is <socket path>,<server pid>,<pane id>.
    if [[ -z "$pid" && -n "$TMUX" ]]; then
        sockpath="$(printf '%s' "$TMUX" | cut -d, -f1)"
        pid="$(printf '%s' "$TMUX" | cut -d, -f2)"
        kill -0 "$pid" 2>/dev/null || { pid=""; sockpath=""; }
    fi

    # Not inside tmux: pick the oldest long-lived server (ppid 1), since that
    # is the one likely still holding the sessions.
    if [[ -z "$pid" ]]; then
        while IFS= read -r p; do
            [[ -n "$p" ]] && pids+=("$p")
        done < <(
            ps -Ao pid=,ppid=,etime=,comm= 2>/dev/null | awk '
                $2 == 1 && ($4 == "tmux" || $4 ~ /\/tmux$/) {
                    e = $3; d = 0
                    if (index(e, "-") > 0) { split(e, a, "-"); d = a[1]; e = a[2] }
                    n = split(e, t, ":")
                    s = d * 86400 + (n == 3 ? t[1] * 3600 + t[2] * 60 + t[3] : t[1] * 60 + t[2])
                    print s, $1
                }' | sort -rn | awk '{print $2}'
        )
        [[ ${#pids[@]} -gt 0 ]] && pid="${pids[1]}"
    fi

    if [[ -z "$pid" ]]; then
        echo "tmux rescue: no running tmux server found" >&2
        return 1
    fi

    # Read the socket path from the server's open fds: it still reports the
    # original path even after the file itself was unlinked.
    if [[ -z "$sockpath" ]] && command -v lsof >/dev/null 2>&1; then
        sockpath="$(lsof -U -a -p "$pid" -Fn 2>/dev/null |
            sed -n 's|^n\(/.*\)$|\1|p' | head -1)"
    fi
    [[ -z "$sockpath" ]] && sockpath="${TMUX_TMPDIR:-/tmp}/tmux-$(id -u)/default"
    sockdir="${sockpath%/*}"

    # tmux only accepts a socket directory with mode 700.
    if [[ ! -d "$sockdir" ]]; then
        mkdir -m 700 -p "$sockdir" || return 1
        echo "tmux rescue: recreated $sockdir"
    fi
    chmod 700 "$sockdir" 2>/dev/null

    if ! kill -USR1 "$pid" 2>/dev/null; then
        echo "tmux rescue: cannot signal server $pid" >&2
        return 1
    fi
    sleep 0.3

    if [[ -S "$sockpath" ]] && command tmux -S "$sockpath" ls 2>/dev/null; then
        # A second server may still be running after a stray session was
        # started while the socket was missing; it no longer owns the path.
        local others
        others="$(ps -Ao pid=,ppid=,comm= 2>/dev/null | awk -v self="$pid" '
            $2 == 1 && ($3 == "tmux" || $3 ~ /\/tmux$/) && $1 != self { printf "%s ", $1 }')"
        if [[ -n "${others// /}" ]]; then
            echo "note: other tmux server(s) still running: ${others% }" >&2
        fi
        return 0
    fi
    echo "tmux rescue: server $pid did not recreate $sockpath" >&2
    return 1
}

# Start a new detached tmux session, then send cd command separately so the
# working directory path never appears in the tmux server process's argv
# (which would cause `pkill -f <dirname>` to kill the tmux server).
_tmux_new_session() {
    local session_flag=() name="$1" dir="$2"
    [[ -n "$name" ]] && session_flag=(-s "$name")
    local tmux_bin
    tmux_bin="$(command -v tmux)"
    TMUX_WORKING_DIR="$dir"
    TERM=xterm-256color "$tmux_bin" -u new-session "${session_flag[@]}" -d
    command tmux set-environment TMUX_WORKING_DIR "$dir"
    command tmux send-keys -t "${name:-}" "cd '$dir' && /usr/bin/clear" Enter
    if [[ -n "$TMUX" ]]; then
        command tmux switch-client -t "${name:-}"
    else
        command tmux attach-session -t "${name:-}"
    fi
}

tmux() {
    case "$1" in
        -h | --help | help)
            shift
            _tmux_help
            ;;
        rescue)
            shift
            _tmux_rescue "$@"
            ;;
        --)
            shift
            command tmux "$@"
            ;;
        rm | kill)
            shift
            command tmux kill-session -t "$@"
            ;;
        ls | l | ll)
            shift
            command tmux ls
            ;;
        cd)
            shift
            if [ $# -eq 0 ]; then
                # echo "current TMUX_WORKING_DIR=$TMUX_WORKING_DIR"
                command tmux show-environment TMUX_WORKING_DIR
            else
                # 必须且只能 1 个参数
                if [ $# -ne 1 ]; then
                    echo "Error: only one path argument is allowed" >&2
                    return 1
                fi
                input_path="$1"
                # 判断路径是否存在
                if [ ! -e "$input_path" ]; then
                    echo "Error: path '$input_path' does not exist" >&2
                    return 1
                fi
                # ---- 将相对路径转换为绝对路径 ----
                if [ -d "$input_path" ]; then
                    # 目录：cd 后 pwd
                    abs_path="$(cd "$input_path" && pwd)"
                else
                    # 文件：进入父目录再拼接文件名
                    abs_path="$(cd "$(dirname "$input_path")" && pwd)/$(basename "$input_path")"
                fi
                # ---------------------------------
                export TMUX_WORKING_DIR="$abs_path"
                command tmux set-environment TMUX_WORKING_DIR "$abs_path"
                command tmux show-environment TMUX_WORKING_DIR
            fi
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
            local filename="${1:-tmux.txt}"
            if [[ -e "$filename" ]]; then
                echo -e "\033[31mError: File '$filename' already exists. Please change save file name.\033[0m"
                return 1
            fi
            command tmux capture-pane -p -S - >"$filename" && echo -e "\033[32mContent saved to $filename\033[0m"
            ;;
        *)
            # 如果参数以 - 开头，直接执行原生 tmux 命令
            if [[ "$1" == -* ]]; then
                command tmux "$@"
                return
            fi
            if [[ $# -eq 0 ]]; then
                _tmux_new_session "" "$(pwd)"
                return
            fi
            local session_name="$1"
            local start_directory="$2"
            if [[ -n "$TMUX" ]]; then
                if command tmux has-session -t "=$session_name" 2>/dev/null; then
                    command tmux switch-client -t "=$session_name"
                else
                    if [[ -n "$start_directory" ]]; then
                        _tmux_new_session "$session_name" "$start_directory"
                    else
                        _tmux_new_session "$session_name" "$(pwd)"
                    fi
                fi
            else
                if command tmux -u attach-session -t "=$session_name" 2>/dev/null; then
                    # On success, do nothing.
                    :
                else
                    # If attach fails, the session doesn't exist, so create it.
                    if [[ -n "$start_directory" ]]; then
                        _tmux_new_session "$session_name" "$start_directory"
                    else
                        _tmux_new_session "$session_name" "$(pwd)"
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

    local subcommands="ls l ll rm kill sw reboot save cd rescue help --"
    local sessions=$(command tmux ls -F '#S' 2>/dev/null)

    if [ "$cword" -eq 1 ]; then
        # 第一个参数可以是会话名或子命令
        COMPREPLY=($(compgen -W "${subcommands} ${sessions}" -- "${cur}"))
        return 0
    fi

    case "${words[1]}" in
        rm | kill)
            # rm/kill 命令需要会话名作为参数
            COMPREPLY=($(compgen -W "${sessions}" -- "${cur}"))
            ;;
        cd)
            # cd 命令补全目录
            compopt -o nospace
            COMPREPLY=($(compgen -d -- "${cur}"))
            ;;
        --)
            # -- 命令补全所有 tmux 子命令
            local tmux_cmds=$(command tmux list-commands 2>/dev/null | awk '{print $1}')
            COMPREPLY=($(compgen -W "${tmux_cmds}" -- "${cur}"))
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
        'l:List active sessions (alias for ls)'
        'll:List active sessions (alias for ls)'
        'rm:Kill a session'
        'kill:Kill a session (alias for rm)'
        'sw:Switch window'
        'reboot:Kill and restart tmux server'
        'save:Save pane content to a file'
        'cd:Set TMUX_WORKING_DIR environment'
        'rescue:Rebuild a deleted tmux socket without losing sessions'
        'help:Show this wrapper help'
        '--:Pass through arguments to tmux command'
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
                rm | kill)
                    _describe 'session to kill' sessions
                    ;;
                rescue)
                    _message 'server pid (default: the running server)'
                    ;;
                cd)
                    # cd 命令补全目录
                    _path_files -/
                    ;;
                --)
                    # -- 命令补全所有 tmux 子命令
                    local -a tmux_cmds
                    tmux_cmds=($(command tmux list-commands 2>/dev/null | awk '{print $1}'))
                    _describe 'tmux command' tmux_cmds
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
