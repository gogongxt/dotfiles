# mylog() {
#     if [[ $# -eq 0 ]]; then
#         echo "Usage: mylog <command> [args...]" >&2
#         return 1
#     fi
#     local log_dir="${HOME}/logs"
#     mkdir -p "$log_dir"
#     ms=$(printf '%03d' "$(($(date +%s%N) / 1000000 % 1000))")
#     local logfile="${log_dir}/$(date +%Y%m%d_%H%M%S)_${ms}_${1##*/}.log"
#     # ------------------------
#     {
#         echo "=== Command Logger ==="
#         echo "Time: $(date '+%Y-%m-%d %H:%M:%S').${ms}"
#         echo "Command: $@"
#         echo "Directory: $(pwd)"
#         echo "User: $(whoami)"
#         echo "Log saved: $logfile"
#         echo "================================"
#         time "$@" 2>&1
#         echo "================================"
#         echo "Exit code: $?"
#     } | {
#         if command -v ansi2txt &>/dev/null; then
#             tee >(ansi2txt >"$logfile")
#         else
#             tee "$logfile"
#         fi
#     }
#     echo "Log saved: $logfile"
# }

mylog() {
    [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]] && {
        printf '\033[31mUsage:\033[0m mylog <command> [args...]\n' >&2
        printf '\033[31mUsage:\033[0m mylog -- <logfile> -- <command> [args...]\n' >&2
        return 1
    }

    local ms
    ms=$(printf '%03d' "$(($(date +%s%N) / 1000000 % 1000))")
    local logfile
    local cmd

    # 检查是否使用自定义日志文件名: mylog -- filename -- command args...
    if [[ "$1" == "--" ]]; then
        [[ $# -lt 4 ]] && {
            printf '\033[31mUsage:\033[0m mylog -- <logfile> -- <command> [args...]\n' >&2
            return 1
        }
        [[ "$3" != "--" ]] && {
            printf '\033[31mError:\033[0m Third argument must be "--"\n' >&2
            return 1
        }
        # 扩展文件路径（支持 ~ 和相对路径）
        logfile="${2:a}"
        # 如果是相对路径，相对于当前目录
        [[ "$2" != /* ]] && [[ "$2" != ~* ]] && logfile="$(pwd)/$2"
        # 创建日志文件所在的目录
        local log_path_dir
        log_path_dir="$(dirname "$logfile")"
        [[ "$log_path_dir" != "." ]] && mkdir -p "$log_path_dir"
        cmd=("${@:4}") # 从第4个参数开始是命令
    else
        # 默认模式：自动生成文件名
        local log_dir="$HOME/logs"
        mkdir -p "$log_dir"
        logfile="$log_dir/$(date +%Y%m%d_%H%M%S)_${ms}_${1##*/}.log"
        cmd=("$@")
    fi

    if [[ -e "$logfile" ]]; then
        printf '\033[33mLog file already exists:\033[0m %s\033[0m\n' "$logfile"
        printf '\033[33mOverwrite?\033[0m \033[32m[y]\033[0m/\033[31m[N]\033[0m: '
        read -r answer
        case "$answer" in
        [yY] | [yY][eE][sS])
            printf '\033[32m→ Overwriting\033[0m\n'
            ;;
        *)
            printf '\033[31m→ Aborted.\033[0m\n'
            return 1
            ;;
        esac
    fi

    # 设置 trap 以捕获 Ctrl+C，确保打印日志位置
    trap 'printf "\n\033[32mLog saved: %s\033[0m\n" "$logfile"; return 130' INT

    {
        printf '\033[90m========= Command Logger =========\033[0m\n'
        printf '\033[90mTime: %s.%s\033[0m\n' "$(date '+%F %T')" "$ms"
        printf '\033[90mCommand: %s\033[0m\n' "${cmd[*]}"
        echo
        printf '\033[90mUser: %s\033[0m\n' "$(whoami)"
        printf '\033[90mDirectory: %s\033[0m\n' "$(pwd)"
        printf '\033[90mLog saved: %s\033[0m\n' "$logfile"
        printf '\033[90m================================\033[0m\n'
        "${cmd[@]}" 2>&1
        printf '\033[90m================================\033[0m\n'
        printf '\033[90mExit code: %d\033[0m\n' "$?"
    } | {
        if command -v ansi2txt &>/dev/null; then
            tee >(ansi2txt >"$logfile")
        else
            tee "$logfile"
        fi
    }

    local exit_code=$?
    trap - INT # 清除 trap
    printf '\033[32mLog saved: %s\033[0m\n' "$logfile"
    return $exit_code
}
