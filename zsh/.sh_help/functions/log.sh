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
        printf '\033[1;33mmylog\033[0m — run a command and save its output to a timestamped log file\n\n' >&2
        printf '\033[1mUSAGE\033[0m\n' >&2
        printf '  mylog <command> [args...]                          # basic mode\n' >&2
        printf '  mylog -- [logfile] -- <command> [args...]          # custom log path\n' >&2
        printf '  mylog -- --nohup [logfile] -- <command> [args...]  # background mode\n' >&2
        printf '\n\033[1mMODES\033[0m\n' >&2
        printf '  \033[36mbasic\033[0m      Log file is auto-named: ~/logs/log_YYYYMMDD_HHmmSS_mmm_<cmd>.log\n' >&2
        printf '             Output is shown in terminal AND saved to the log file.\n' >&2
        printf '             ANSI color codes are stripped from the log (requires ansi2txt).\n' >&2
        printf '\n' >&2
        printf '  \033[36mcustom\033[0m     Wrap args with -- ... -- to set a custom log file path.\n' >&2
        printf '             If no path is given, auto-naming is used but without cmd suffix.\n' >&2
        printf '\n' >&2
        printf '  \033[36m--nohup\033[0m    Run the command in the background (detached, like nohup).\n' >&2
        printf '             Output is NOT shown in terminal; only written to the log file.\n' >&2
        printf '             Prints the background PID immediately.\n' >&2
        printf '\n\033[1mOPTIONS\033[0m\n' >&2
        printf '  --nohup    Background mode (must appear between the two -- separators)\n' >&2
        printf '  -h/--help  Show this help\n' >&2
        printf '\n\033[1mEXAMPLES\033[0m\n' >&2
        printf '  \033[90m# Basic: auto-named log, output mirrored to terminal\033[0m\n' >&2
        printf '  mylog make build\n' >&2
        printf '\n' >&2
        printf '  \033[90m# Custom log path\033[0m\n' >&2
        printf '  mylog -- /tmp/build.log -- make build\n' >&2
        printf '\n' >&2
        printf '  \033[90m# Auto-named log (no cmd suffix), still foreground\033[0m\n' >&2
        printf '  mylog -- -- make build\n' >&2
        printf '\n' >&2
        printf '  \033[90m# Background mode: detach, write to auto-named log\033[0m\n' >&2
        printf '  mylog -- --nohup -- python train.py\n' >&2
        printf '\n' >&2
        printf '  \033[90m# Background mode with custom log path\033[0m\n' >&2
        printf '  mylog -- --nohup /tmp/train.log -- python train.py\n' >&2
        printf '\n\033[1mNOTES\033[0m\n' >&2
        printf '  • Logs are saved to ~/logs/ by default\n' >&2
        printf '  • If the log file already exists, you will be prompted before overwriting\n' >&2
        printf '  • Ctrl+C during foreground execution still saves the log\n' >&2
        printf '  • ansi2txt (colorized-logs) strips ANSI codes from saved files\n' >&2
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
            logfile="$log_dir/log_$(date +%Y%m%d_%H%M%S)_${ms}.log"
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
        logfile="$log_dir/log_$(date +%Y%m%d_%H%M%S)_${ms}_${1##*/}.log"
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

    local latest_link
    latest_link="$(dirname "$logfile")/log_latest.log"
    ln -sf "$(basename "$logfile")" "$latest_link"
    local _mylog_printed=false
    trap '[[ "$_mylog_printed" == false ]] && printf "\033[90m================================\033[0m\n\033[32mLog saved: %s\033[0m\n    \033[32mlink → %s\033[0m\n" "$logfile" "$latest_link"' EXIT

    # 构建日志头部
    local log_header
    log_header=$(printf '%s\n%s\n\n%s\n%s\n%s\n%s\n%s\n' \
        "========= Command Logger =========" \
        "Time: $(date '+%F %T').${ms}" \
        "Command: ${cmd[*]}" \
        "User: $(whoami)" \
        "Directory: $(pwd)" \
        "Log saved: $logfile" \
        "    link → $latest_link")

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
            PYTHONUNBUFFERED=1 "${cmd[@]}" 2>&1
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
    fi

    trap - EXIT
    _mylog_printed=true
    printf "\033[90m================================\033[0m\n\033[32mLog saved: %s\033[0m\n    \033[32mlink → %s\033[0m\n" "$logfile" "$latest_link"
    return $exit_code
}

# Strip ANSI escape sequences from stdin, write plain text to stdout.
# Covers: CSI (ESC[...m), OSC (ESC]...BEL/ST), single-char escapes, bare BEL.
# Drop-in replacement for the ansi2txt binary when it's not installed.
# ansi2txt() {
#     sed -u $'s/\033\\[[0-9;?]*[A-Za-z]//g;'$'s/\033][^\007]*\007//g;'$'s/\033][^\033]*\033\\\\//g;'$'s/\033.//g;'$'s/\007//g'
# }
# Strip ANSI escape sequences from stdin, write plain text to stdout.
# Covers: CSI (ESC[...m), OSC (ESC]...BEL/ST), single-char escapes, bare BEL.
# Drop-in replacement for the ansi2txt binary when it's not installed.
ansi2txt() {
    # 放弃 sed 改用 perl：sed 会等待 \n 导致 \r 进度条被阻塞。
    # perl 配合 $|=1 和 sysread 可以实现真正的底层数据块实时无缓冲转发。
    perl -e '
    $| = 1; # 开启无缓冲实时输出 (Auto-flush)
    my $buf = "";
    # 每次读取可用数据块，最大 8192 字节，无须等待换行符
    while (sysread(STDIN, my $chunk, 8192)) {
        $buf .= $chunk;
        
        # 1. 过滤标准 CSI 序列 (如 \033[31m, \033[?25l)
        $buf =~ s/\e\[[\d;?]*[A-Za-z]//g;
        # 2. 过滤带 BEL(\a) 结尾的 OSC 序列 (如 \033]0;title\007)
        $buf =~ s/\e\][^\a]*\a//g;
        # 3. 过滤带 ST(\e\\) 结尾的 OSC 序列
        $buf =~ s/\e\][^\e]*\e\\//g;
        # 4. 过滤 2 字节控制码 (如 \eM)，注意排除掉 [ 和 ] 防止误伤还没读全的序列
        $buf =~ s/\e[^\[\]]//g;
        # 5. 过滤孤立的 BEL
        $buf =~ s/\a//g;

        # 处理网络延迟/管道造成的 ANSI 码截断（即 \e 被切在数据块尾部的情况）
        # 如果缓存中还有 \e，说明有个序列还没接收完，暂时扣留在 $buf 中等下个 chunk
        my $idx = index($buf, "\e");
        if ($idx >= 0) {
            print substr($buf, 0, $idx);    # 打印 \e 前面的安全内容
            $buf = substr($buf, $idx);      # 扣留 \e 开始的部分
        } else {
            print $buf;
            $buf = "";
        }
    }
    # 打印收尾时遗留的数据
    print $buf if $buf ne "";
    '
}
ansi2txt_test() {
    local pass=0 fail=0
    _assert() {
        local desc="$1" expected="$2" actual="$3"
        if [[ "$actual" == "$expected" ]]; then
            printf '  \033[32m✓\033[0m %s\n' "$desc"
            ((pass++))
        else
            printf '  \033[31m✗\033[0m %s\n' "$desc"
            printf '    expected: %q\n' "$expected"
            printf '    actual:   %q\n' "$actual"
            ((fail++))
        fi
    }
    printf '\033[1mansi2txt test suite\033[0m\n'
    _assert "SGR colors stripped" \
        "green bold normal red" \
        "$(printf '\033[1;32mgreen bold\033[0m normal \033[31mred\033[0m' | ansi2txt)"
    _assert "SGR reset only (ESC[m)" \
        "plain" \
        "$(printf '\033[mplain' | ansi2txt)"
    _assert "256-color fg/bg" \
        "text" \
        "$(printf '\033[38;5;196mtext\033[0m' | ansi2txt)"
    _assert "truecolor (ESC[38;2;r;g;bm)" \
        "orange" \
        "$(printf '\033[38;2;255;128;0morange\033[0m' | ansi2txt)"
    _assert "CSI cursor movement (ESC[A)" \
        " up" \
        "$(printf '\033[A up' | ansi2txt)"
    _assert "CSI with ? param (ESC[?25l hide cursor)" \
        "text" \
        "$(printf '\033[?25ltext\033[?25h' | ansi2txt)"
    _assert "CSI clear screen (ESC[2J)" \
        " ok" \
        "$(printf '\033[2J ok' | ansi2txt)"
    _assert "OSC window title with BEL terminator" \
        " after" \
        "$(printf '\033]0;title\007 after' | ansi2txt)"
    _assert "OSC hyperlink with ST terminator (ESC\\\\)" \
        "link text" \
        "$(printf '\033]8;;https://example.com\033\\link text\033]8;;\033\\' | ansi2txt)"
    _assert "single-char escape (ESC M reverse index)" \
        " text" \
        "$(printf '\033M text' | ansi2txt)"
    _assert "bare BEL removed" \
        "no bell" \
        "$(printf '\007no bell' | ansi2txt)"
    _assert "plain text unchanged" \
        "hello world 123 !@#" \
        "$(printf 'hello world 123 !@#' | ansi2txt)"
    _assert "multi-line input" \
        $'line1\nline2' \
        "$(printf '\033[32mline1\033[0m\n\033[31mline2\033[0m' | ansi2txt)"
    printf '\n\033[1mResults:\033[0m %d passed, %d failed\n' "$pass" "$fail"
    [[ $fail -eq 0 ]]
}

# 命令执行通知函数
notify() {
    [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]] && {
        printf '\033[1;33mnotify\033[0m — run a command with macOS start/end notifications\n\n' >&2
        printf '\033[1mUSAGE\033[0m\n' >&2
        printf '  notify <command> [args...]\n' >&2
        printf '\n\033[1mBEHAVIOR\033[0m\n' >&2
        printf '  1. Sends a \033[36m"🚀 开始执行"\033[0m notification before running the command\n' >&2
        printf '  2. Runs the command in the foreground (stdin/stdout/stderr are passed through)\n' >&2
        printf '  3. On success: sends \033[32m"✅ 执行完成"\033[0m with elapsed time\n' >&2
        printf '  4. On failure: sends \033[31m"❌ 执行失败"\033[0m with exit code and elapsed time\n' >&2
        printf '  5. Returns the original exit code of the command\n' >&2
        printf '\n\033[1mNOTES\033[0m\n' >&2
        printf '  • Requires ~/.scripts/macos/notify.sh to be present and executable\n' >&2
        printf '  • Elapsed time is formatted as Xh Xm Xs (hours/minutes omitted if zero)\n' >&2
        printf '  • Notification sound: Glass (success) / Basso (failure)\n' >&2
        printf '\n\033[1mEXAMPLES\033[0m\n' >&2
        printf '  \033[90m# Notify when a long build finishes\033[0m\n' >&2
        printf '  notify make build\n' >&2
        printf '\n' >&2
        printf '  \033[90m# Notify on a slow test suite\033[0m\n' >&2
        printf '  notify pytest tests/\n' >&2
        printf '\n' >&2
        printf '  \033[90m# Combine with mylog to get both a log file and a notification\033[0m\n' >&2
        printf '  notify mylog make build\n' >&2
        return 1
    }
    local notify_script="$HOME/.scripts/macos/notify.sh"
    [[ ! -x "$notify_script" ]] && {
        printf '\033[31mError:\033[0m notify script not found: %s\n' "$notify_script" >&2
        return 1
    }
    local cmd_name="$*"
    local work_dir="$(pwd)"
    local start_time
    start_time=$(date +%s)
    # 开始执行通知
    "$notify_script" -title "🚀 开始执行" -message "$cmd_name" -subtitle "📁 $work_dir" -sound "Glass" &>/dev/null
    # 执行命令
    "$@"
    local exit_code=$?
    local end_time duration
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    # 格式化耗时
    local duration_str
    if [[ $duration -ge 3600 ]]; then
        duration_str="$((duration / 3600))h$(((duration % 3600) / 60))m$((duration % 60))s"
    elif [[ $duration -ge 60 ]]; then
        duration_str="$((duration / 60))m$((duration % 60))s"
    else
        duration_str="${duration}s"
    fi
    # 完成通知
    if [[ $exit_code -eq 0 ]]; then
        "$notify_script" -title "✅ 执行完成" \
            -message "$cmd_name (耗时: $duration_str)" \
            -subtitle "📁 $work_dir" \
            -sound "Glass" &>/dev/null
    else
        "$notify_script" -title "❌ 执行失败" \
            -message "$cmd_name (退出码: $exit_code, 耗时: $duration_str)" \
            -subtitle "📁 $work_dir" \
            -sound "Basso" &>/dev/null
    fi
    return $exit_code
}
