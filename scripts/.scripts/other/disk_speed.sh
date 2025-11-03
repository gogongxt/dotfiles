#!/bin/bash
# ==========================================
# 磁盘性能测试脚本
# 作者: gogongxt
# ==========================================

set -e

# 检测操作系统
detect_os() {
    case "$(uname -s)" in
        Darwin*) OS="macos" ;;
        Linux*) OS="linux" ;;
        *) OS="unknown" ;;
    esac
}

# 初始化操作系统检测
detect_os

# 默认参数
DIR="."
THREADS=4
BLOCK_SIZE="1G"
COUNT=1
MODE="both" # 可选: write | read | both

# 结果变量
SINGLE_WRITE_SPEED=""
SINGLE_READ_SPEED=""
MULTI_WRITE_TOTAL=0
MULTI_READ_TOTAL=0
WRITE_DURATION=0
READ_DURATION=0

# 打印帮助信息
usage() {
    cat <<EOF
用法: $0 [选项]

选项:
  -d, --dir <路径>          指定测试目录 (默认: 当前目录)
  -t, --threads <数量>      并发线程数 (默认: 4)
  -b, --block-size <大小>   单块大小 (默认: 1G)
  -c, --count <数量>        每线程块数量 (默认: 1)
  -m, --mode <模式>         测试模式: write | read | both (默认: both)
  -h, --help                显示此帮助信息

示例:
  $0 --dir /data --threads 8 --block-size 512M --count 2
EOF
    exit 0
}

# 参数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -d | --dir)
            DIR="$2"
            shift 2
            ;;
        -t | --threads)
            THREADS="$2"
            shift 2
            ;;
        -b | --block-size)
            BLOCK_SIZE="$2"
            shift 2
            ;;
        -c | --count)
            COUNT="$2"
            shift 2
            ;;
        -m | --mode)
            MODE="$2"
            shift 2
            ;;
        -h | --help) usage ;;
        *)
            echo "未知参数: $1"
            usage
            ;;
    esac
done

# 检查目录
if [ ! -d "$DIR" ]; then
    echo "错误: 路径 '$DIR' 不存在或不是目录"
    exit 1
fi

# 输出基本信息
echo "====================="
echo "磁盘性能测试"
echo "操作系统: $OS"
echo "测试目录: $DIR"
echo "线程数: $THREADS"
echo "块大小: $BLOCK_SIZE"
echo "块数量: $COUNT"
echo "测试模式: $MODE"
echo "====================="

# 函数：单位换算为 MB/s
to_mb() {
    local num=$1
    local unit=$2
    case $unit in
        GB/s) awk "BEGIN {print $num * 1024}" ;;
        MB/s) awk "BEGIN {print $num}" ;;
        KB/s) awk "BEGIN {print $num / 1024}" ;;
        B/s) awk "BEGIN {print $num / 1048576}" ;;
        *) echo 0 ;;
    esac
}

# 函数：执行 dd 并抓取速度，统一返回 MB/s 数值
run_dd_write() {
    local file="$1"
    local dd_output
    local speed=0
    # dd 参数
    local dd_params="oflag=direct"
    dd_output=$(dd if=/dev/zero of="$file" bs="$BLOCK_SIZE" count="$COUNT" $dd_params 2>&1)
    speed=$(parse_dd_speed "$dd_output")
    printf "%.1f\n" "$speed"
}

run_dd_read() {
    local file="$1"
    local dd_output
    local speed=0
    # dd 参数
    local dd_params="iflag=direct"
    dd_output=$(dd if="$file" of=/dev/null bs="$BLOCK_SIZE" count="$COUNT" $dd_params 2>&1)
    speed=$(parse_dd_speed "$dd_output")
    printf "%.1f\n" "$speed"
}

# 统一的 dd 速度解析函数
parse_dd_speed() {
    local dd_output="$1"
    local speed=0
    if [[ "$OS" == "macos" ]]; then
        # macOS 格式: bytes transferred in X secs (Y bytes/sec)
        local bytes_per_sec=$(echo "$dd_output" | grep -o '([0-9.]* bytes/sec)' | grep -o '[0-9.]*')
        if [ -n "$bytes_per_sec" ] && [[ "$bytes_per_sec" =~ ^[0-9]+\.?[0-9]*$ ]]; then
            speed=$(awk "BEGIN {printf \"%.1f\", $bytes_per_sec / 1048576}")
        fi
    elif [[ "$OS" == "linux" ]]; then
        # Linux 格式: 尝试匹配 MB/s, GB/s 等
        local speed_str=$(echo "$dd_output" | grep -o '[0-9.]* [GMK]*B/s')
        if [ -n "$speed_str" ]; then
            local num=$(echo "$speed_str" | awk '{print $1}')
            local unit=$(echo "$speed_str" | awk '{print $2}')
            speed=$(to_mb "$num" "$unit")
        fi
    else
        # 未知系统，尝试通用解析
        local speed_str=$(echo "$dd_output" | grep -o '[0-9.]* [GMK]*B/s')
        if [ -n "$speed_str" ]; then
            local num=$(echo "$speed_str" | awk '{print $1}')
            local unit=$(echo "$speed_str" | awk '{print $2}')
            speed=$(to_mb "$num" "$unit")
        fi
    fi
    echo "$speed"
}

# 并发创建测试文件（用于读取测试）
create_test_files() {
    echo "并发创建 $THREADS 个测试文件中..."
    local start_time=$(date +%s)

    # 根据 OS 选择合适的 dd 参数
    local dd_params="oflag=direct"
    if [[ "$OS" == "macos" ]]; then
        dd_params="oflag=direct"
    elif [[ "$OS" == "linux" ]]; then
        dd_params="oflag=direct status=none"
    fi

    for i in $(seq 1 "$THREADS"); do
        local file="$DIR/dd_test_file_$i"
        if [ ! -f "$file" ]; then
            dd if=/dev/zero of="$file" bs="$BLOCK_SIZE" count="$COUNT" $dd_params 2>/dev/null &
        else
            echo "文件已存在: $file"
        fi
    done

    wait
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo "测试文件创建完成，耗时: ${duration} 秒"
}

# 清理测试文件
cleanup_test_files() {
    rm -f "$DIR"/dd_test_file_* /tmp/dd_write_*.txt /tmp/dd_read_*.txt 2>/dev/null || true
}

# 显示测试结果汇总
show_summary() {
    echo ""
    echo "==========================================="
    echo "             测试结果汇总"
    echo "==========================================="
    echo "测试目录: $DIR"
    echo "线程数: $THREADS"
    echo "块大小: $BLOCK_SIZE"
    echo "块数量: $COUNT"
    echo "测试模式: $MODE"
    echo "-------------------------------------------"

    if [[ "$MODE" == "write" || "$MODE" == "both" ]]; then
        echo "写入性能:"
        if [ -n "$SINGLE_WRITE_SPEED" ]; then
            echo "  • 单线程写入: ${SINGLE_WRITE_SPEED} MB/s"
        fi
        if [ "$MULTI_WRITE_TOTAL" != "0" ]; then
            echo "  • 多线程写入: ${MULTI_WRITE_TOTAL} MB/s ($THREADS 线程)"
            if [ "$WRITE_DURATION" -gt 0 ]; then
                echo "  • 写入耗时: ${WRITE_DURATION} 秒"
            fi
        fi
    fi

    if [[ "$MODE" == "read" || "$MODE" == "both" ]]; then
        echo "读取性能:"
        if [ -n "$SINGLE_READ_SPEED" ]; then
            echo "  • 单线程读取: ${SINGLE_READ_SPEED} MB/s"
        fi
        if [ "$MULTI_READ_TOTAL" != "0" ]; then
            echo "  • 多线程读取: ${MULTI_READ_TOTAL} MB/s ($THREADS 线程)"
            if [ "$READ_DURATION" -gt 0 ]; then
                echo "  • 读取耗时: ${READ_DURATION} 秒"
            fi
        fi
    fi

    # 并发效率分析
    if [[ "$MODE" == "both" && -n "$SINGLE_WRITE_SPEED" && "$MULTI_WRITE_TOTAL" != "0" ]]; then
        local write_efficiency=$(awk "BEGIN {printf \"%.1f\", ($MULTI_WRITE_TOTAL / $SINGLE_WRITE_SPEED / $THREADS) * 100}")
        echo "-------------------------------------------"
        echo "并发效率分析:"
        echo "  • 写入并发效率: ${write_efficiency}% (相对单线程)"
    fi

    if [[ "$MODE" == "both" && -n "$SINGLE_READ_SPEED" && "$MULTI_READ_TOTAL" != "0" ]]; then
        local read_efficiency=$(awk "BEGIN {printf \"%.1f\", ($MULTI_READ_TOTAL / $SINGLE_READ_SPEED / $THREADS) * 100}")
        echo "  • 读取并发效率: ${read_efficiency}% (相对单线程)"
    fi

    echo "==========================================="
}

# 单线程测试
single_thread_test() {
    local file="$DIR/dd_test_single"
    echo ""
    echo ">>> [单线程测试]"

    if [[ "$MODE" == "read" || "$MODE" == "both" ]]; then
        if [ ! -f "$file" ]; then
            echo "创建单线程测试文件: $file"
            # 根据 OS 选择合适的 dd 参数
            local dd_params="oflag=direct"
            if [[ "$OS" == "macos" ]]; then
                dd_params="oflag=direct"
            elif [[ "$OS" == "linux" ]]; then
                dd_params="oflag=direct status=none"
            fi
            dd if=/dev/zero of="$file" bs="$BLOCK_SIZE" count="$COUNT" $dd_params 2>/dev/null
        fi
    fi

    if [[ "$MODE" == "write" || "$MODE" == "both" ]]; then
        SINGLE_WRITE_SPEED=$(run_dd_write "$file")
        echo "单线程写入速度: ${SINGLE_WRITE_SPEED} MB/s"
    fi

    if [[ "$MODE" == "read" || "$MODE" == "both" ]]; then
        SINGLE_READ_SPEED=$(run_dd_read "$file")
        echo "单线程读取速度: ${SINGLE_READ_SPEED} MB/s"
    fi

    rm -f "$file"
}

# 多线程测试
multi_thread_test() {
    echo ""
    echo ">>> [多线程测试]"
    echo "启动 $THREADS 个并发任务..."

    if [[ "$MODE" == "read" || "$MODE" == "both" ]]; then
        create_test_files
    fi

    if [[ "$MODE" == "write" || "$MODE" == "both" ]]; then
        echo "执行并行写入测试..."
        local write_start=$(date +%s)
        for i in $(seq 1 "$THREADS"); do
            run_dd_write "$DIR/dd_test_file_$i" >"/tmp/dd_write_$i.txt" &
        done
        wait
        local write_end=$(date +%s)
        WRITE_DURATION=$((write_end - write_start))

        for i in $(seq 1 "$THREADS"); do
            if [ -f "/tmp/dd_write_$i.txt" ]; then
                mb=$(cat "/tmp/dd_write_$i.txt")
                MULTI_WRITE_TOTAL=$(awk "BEGIN {print $MULTI_WRITE_TOTAL + $mb}")
            fi
        done
        echo "多线程写入总速度: ${MULTI_WRITE_TOTAL} MB/s (耗时: ${WRITE_DURATION} 秒)"
    fi

    if [[ "$MODE" == "read" || "$MODE" == "both" ]]; then
        echo "执行并行读取测试..."
        local read_start=$(date +%s)
        for i in $(seq 1 "$THREADS"); do
            run_dd_read "$DIR/dd_test_file_$i" >"/tmp/dd_read_$i.txt" &
        done
        wait
        local read_end=$(date +%s)
        READ_DURATION=$((read_end - read_start))

        for i in $(seq 1 "$THREADS"); do
            if [ -f "/tmp/dd_read_$i.txt" ]; then
                mb=$(cat "/tmp/dd_read_$i.txt")
                MULTI_READ_TOTAL=$(awk "BEGIN {print $MULTI_READ_TOTAL + $mb}")
            fi
        done
        echo "多线程读取总速度: ${MULTI_READ_TOTAL} MB/s (耗时: ${READ_DURATION} 秒)"
    fi

    cleanup_test_files
}

# 设置退出时清理
trap cleanup_test_files EXIT INT TERM

# 主逻辑
single_thread_test
multi_thread_test
show_summary
