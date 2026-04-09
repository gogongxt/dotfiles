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
    local nohup_mode=false

    # 检查是否使用自定义日志文件名: mylog -- [options] -- command args...
    # 支持的 options:
    #   --nohup: 不输出到终端，只保存到日志文件
    #   filepath: 自定义日志文件路径
    if [[ "$1" == "--" ]]; then
        # 找到最后一个 -- 的位置
        local last_dash_idx=0
        for ((i=2; i<=$#; i++)); do
            if [[ "${(P)i}" == "--" ]]; then
                last_dash_idx=$i
            fi
        done

        # 必须有至少一个 -- 用于分隔 mylog 选项和命令
        [[ $last_dash_idx -eq 0 || $last_dash_idx -le 2 ]] && {
            printf '\033[31mUsage:\033[0m mylog -- [options] -- <command> [args...]\n' >&2
            printf '\033[31mOptions:\033[0m --nohup (do not output to terminal)\n' >&2
            return 1
        }

        # 解析 mylog 选项 (从 $2 到 $last_dash_idx-1)
        local mylog_args=("${@:2:$((last_dash_idx - 2))}")
        for arg in "${mylog_args[@]}"; do
            case "$arg" in
                --nohup)
                    nohup_mode=true
                    ;;
                -*)
                    # 可能是日志文件路径 (以 - 开头但不是 --nohup)
                    if [[ -z "$logfile" ]]; then
                        logfile="$arg"
                    else
                        printf '\033[31mError:\033[0m Unknown option: %s\n' "$arg" >&2
                        return 1
                    fi
                    ;;
                *)
                    if [[ -z "$logfile" ]]; then
                        logfile="$arg"
                    else
                        printf '\033[31mError:\033[0m Unexpected argument: %s\n' "$arg" >&2
                        return 1
                    fi
                    ;;
            esac
        done

        # 如果没有指定 logfile，使用默认
        if [[ -z "$logfile" ]]; then
            local log_dir="$HOME/logs"
            mkdir -p "$log_dir"
            logfile="$log_dir/$(date +%Y%m%d_%H%M%S)_${ms}.log"
        else
            mkdir -p "$(dirname "$logfile")"
        fi

        # 命令从最后一个 -- 之后开始
        cmd=("${@:$((last_dash_idx + 1))}")
        [[ ${#cmd[@]} -eq 0 ]] && {
            printf '\033[31mError:\033[0m No command specified\n' >&2
            return 1
        }
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

    # 构建日志头部
    local log_header
    log_header=$(printf '%s\n%s\n\n%s\n%s\n%s\n%s\n' \
        "========= Command Logger =========" \
        "Time: $(date '+%F %T').${ms}" \
        "Command: ${cmd[*]}" \
        "User: $(whoami)" \
        "Directory: $(pwd)" \
        "Log saved: $logfile")

    if [[ "$nohup_mode" == true ]]; then
        # nohup 模式: 后台运行，不输出到终端，日志写入文件
        {
            print "$log_header"
            print "================================"
            print "Running in background with nohup..."
        } > "$logfile"

        # 使用 nohup 后台运行，输出重定向到日志文件
        nohup "${cmd[@]}" >> "$logfile" 2>&1 &
        local bg_pid=$!

        {
            print "================================"
            print "Started PID: $bg_pid"
            print "================================"
        } >> "$logfile"

        printf '\033[32m[Background] PID: %d\033[0m\n' "$bg_pid"
        local exit_code=0
    else
        # 正常模式: 输出到终端和文件
        {
            printf '\033[90m%s\033[0m\n' "$log_header"
            printf '\033[90m================================\033[0m\n'
            "${cmd[@]}" 2>&1
            printf '\033[90m================================\033[0m\n'
            printf '\033[90mExit code: %d\033[0m\n' "$?"
        } | {
            if command -v ansi2txt &>/dev/null; then
                tee >(ansi2txt >"$logfile")
            else
                tee -a "$logfile"
            fi
        }
        local exit_code=$?
    fi

    trap - INT # 清除 trap
    printf '\033[32mLog saved: %s\033[0m\n' "$logfile"
    return $exit_code
}
