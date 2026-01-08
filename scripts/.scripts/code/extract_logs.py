#!/usr/bin/env python3
import argparse
import os
import re
from datetime import datetime

from tqdm import tqdm

# === 正则模式 ===
# 提取时间格式: 2025-11-03 11:00:23
TIME_PATTERN = re.compile(r"(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})")


ANSI_ESCAPE = re.compile(r"\x1B\[[0-9;]*[A-Za-z]")  # 去除颜色控制符


def strip_ansi(s: str) -> str:
    """移除终端颜色控制符"""
    return ANSI_ESCAPE.sub("", s)


def get_default_output_path(input_path):
    """生成默认输出路径：原始文件名_extract.log"""
    dir_name = os.path.dirname(input_path)
    base_name = os.path.basename(input_path)
    name, ext = os.path.splitext(base_name)
    default_name = f"{name}_extract{ext}"
    return os.path.join(dir_name, default_name)


def extract_logs(input_path, output_path, start, end):
    """提取指定时间范围的日志（带进度条）"""
    total_size = os.path.getsize(input_path)
    count = 0

    with open(input_path, "r", encoding="utf-8", errors="ignore") as fin, open(
        output_path, "w", encoding="utf-8"
    ) as fout, tqdm(
        total=total_size, unit="B", unit_scale=True, desc="Processing", ncols=100
    ) as pbar:

        for line in fin:
            pbar.update(len(line))  # 更新进度

            match = TIME_PATTERN.search(line)
            if not match:
                continue

            try:
                t = datetime.strptime(match.group(1), "%Y-%m-%d %H:%M:%S")
            except ValueError:
                continue

            if start <= t <= end:
                clean_line = strip_ansi(line)  # 只有在时间范围内才去除颜色控制符
                fout.write(clean_line)
                count += 1
                pbar.set_postfix({"extracted": count})  # 动态显示已提取条数

    print(f"\n✅ 提取完成，共写入 {count} 行日志到：{output_path}")


def main():
    parser = argparse.ArgumentParser(
        description="从大型日志文件中提取指定时间范围的日志（支持颜色过滤与进度显示）"
    )
    parser.add_argument("-i", "--input", required=True, help="输入日志文件路径")
    parser.add_argument(
        "-o", "--output", help="输出文件路径（默认：原始文件名_extract.log）"
    )
    parser.add_argument("--start", required=True, help="开始时间：YYYY-MM-DD HH:MM:SS")
    parser.add_argument("--end", required=True, help="结束时间：YYYY-MM-DD HH:MM:SS")

    args = parser.parse_args()

    # 设置默认输出文件名
    if not args.output:
        args.output = get_default_output_path(args.input)

    try:
        start_time = datetime.strptime(args.start, "%Y-%m-%d %H:%M:%S")
        end_time = datetime.strptime(args.end, "%Y-%m-%d %H:%M:%S")
    except ValueError:
        parser.error("时间格式错误，请使用 YYYY-MM-DD HH:MM:SS")

    if start_time > end_time:
        parser.error("开始时间不能晚于结束时间")

    extract_logs(args.input, args.output, start_time, end_time)


if __name__ == "__main__":
    main()
