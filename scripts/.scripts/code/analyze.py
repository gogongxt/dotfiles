#!/usr/bin/env python3
import argparse
import re
import statistics
from typing import Any, Callable, Dict, List, Optional

PATTERNS = [
    r"latency=([\d.]+(?:us|ms|s)?)",
    r"Size: ([\d.]+)",
]


# ----------------------
# 统一的数值解析函数
# ----------------------
def parse_value(value: str) -> Optional[float]:
    """可以解析时间(us/ms/s)，其他普通数值则直接 float()"""
    value = value.strip()
    # 时间格式：自动识别单位
    time_match = re.match(r"^([\d.]+)\s*(us|ms|s)$", value)
    if time_match:
        num, unit = time_match.groups()
        num = float(num)
        if unit == "ms":
            return num / 1000
        elif unit == "us":
            return num / 1_000_000
        return num  # 秒
    # 普通数字
    number_match = re.match(r"^([\d.]+)$", value)
    if number_match:
        try:
            return float(number_match.group(1))
        except ValueError:
            return None
    return None


# ----------------------
# 打印统计信息
# ----------------------
def analyze_latencies(values: List[float], pattern_name: str = "") -> None:
    if not values:
        print(f"\n{pattern_name}: 未找到任何数据")
        return

    values.sort()
    count = len(values)
    avg = statistics.mean(values)
    median = statistics.median(values)
    p95 = values[int(count * 0.95) - 1]
    p99 = values[int(count * 0.99) - 1]
    min_v = values[0]
    max_v = values[-1]

    print(f"\n{'=' * 80}")
    print(f"模式: {pattern_name}")
    print(f"{'=' * 80}")
    print(f"数据数量: {count}")

    # 动态判断是否是时间（用阈值 10 秒以内）
    is_time = max_v < 10 and any(v < 1 for v in values)

    if is_time:
        fmt = lambda v: f"{v:.6f}s"
    else:
        fmt = lambda v: f"{v:.3f}"

    print(f"最小值: {fmt(min_v)}")
    print(f"最大值: {fmt(max_v)}")
    print(f"平均值: {fmt(avg)}")
    print(f"中位数: {fmt(median)}")
    print(f"P95: {fmt(p95)}")
    print(f"P99: {fmt(p99)}")


def main():
    parser = argparse.ArgumentParser(description="从日志中统计参数值")
    parser.add_argument("--input", "-i", required=True, help="输入日志文件路径")
    parser.add_argument(
        "--patterns",
        "-p",
        action="append",
        help="正则表达式，捕获组中应包含数值，如：'latency=([\\d.]+(?:us|ms|s)?)' 或 'Size: ([\\d]+)'",
    )
    args = parser.parse_args()

    patterns = args.patterns if args.patterns else PATTERNS

    pattern_data: Dict[str, List[float]] = {}
    pattern_compiled = {}

    for p in patterns:
        pattern_data[p] = []
        try:
            pattern_compiled[p] = re.compile(p)
        except re.error as e:
            print(f"错误: 正则表达式 '{p}' 无效: {e}")
            return

    # 读取文件
    total_lines = 0
    with open(args.input, "r", encoding="utf-8") as f:
        for line in f:
            total_lines += 1
            for p_str, pat in pattern_compiled.items():
                matches = pat.findall(line)
                for m in matches:
                    if isinstance(m, tuple):
                        groups = [g for g in m if g]
                        if not groups:
                            continue
                        m = groups[0]
                    val = parse_value(str(m))
                    if val is not None:
                        pattern_data[p_str].append(val)

    print(f"{'=' * 80}")
    print("文件分析报告")
    print(f"{'=' * 80}")
    print(f"输入文件: {args.input}")
    print(f"总行数: {total_lines}")
    print(f"分析的模式数量: {len(patterns)}")

    found_any = False
    for p_str, values in pattern_data.items():
        analyze_latencies(values, p_str)
        if values:
            found_any = True

    if not found_any:
        print("\n没有找到任何符合的数据，请检查正则/日志格式\n")


if __name__ == "__main__":
    main()
