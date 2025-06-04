#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import subprocess
import json
import sys
from collections import defaultdict

# --- 配置 ---
DESIRED_SPACES_PER_DISPLAY = 5

def run_command(command, is_json=True):
    """执行 shell 命令并根据需要返回其输出"""
    try:
        # 确保命令是列表形式，以正确处理带参数的命令
        if not isinstance(command, list):
            command_list = command.split()
        else:
            command_list = command
            
        result = subprocess.run(command_list, capture_output=True, text=True, check=True)
        if is_json:
            if not result.stdout:
                print(f"❌ 命令 '{' '.join(command_list)}' 没有返回任何输出。请检查 yabai 是否正在运行。")
                sys.exit(1)
            return json.loads(result.stdout)
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"❌ 执行命令时出错: {' '.join(e.cmd)}")
        print(f"   错误输出: {e.stderr.strip()}")
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"❌ 解析 JSON 失败。命令: '{' '.join(command_list)}'")
        sys.exit(1)
    except FileNotFoundError:
        print(f"❌ 'yabai' 命令未找到。请确保 yabai 已经安装并且在你的 PATH 中。")
        sys.exit(1)

def find_source_display(spaces_map):
    """在内部状态中查找一个有多余空间的显示器"""
    for display_idx, spaces in spaces_map.items():
        if len(spaces) > DESIRED_SPACES_PER_DISPLAY:
            return display_idx
    return None

def manage_linear_spaces():
    """
    主函数，专门用于管理线性空间模式 (macOS 的 "Displays have separate Spaces" 关闭时)。
    分两步执行：1. 确保空间总数正确。 2. 将空间移动到正确的显示器上。
    """
    print("🚀 开始 Yabai 线性空间管理...")
    
    displays = run_command(["yabai", "-m", "query", "--displays"])
    num_displays = len(displays)
    
    if num_displays == 0:
        print("🤷 没有找到任何显示器。")
        return

    print(f"检测到 {num_displays} 个显示器。")
    target_total_spaces = DESIRED_SPACES_PER_DISPLAY * num_displays
    print(f"🎯 目标空间总数: {num_displays} 个显示器 * {DESIRED_SPACES_PER_DISPLAY} = {target_total_spaces} 个")
    print("-" * 40)

    # =========================================================================
    # 阶段一: 调整空间总数
    # =========================================================================
    print("--- 阶段一: 检查并调整空间总数 ---")
    
    all_spaces = run_command(["yabai", "-m", "query", "--spaces"])
    current_total_spaces = len(all_spaces)
    print(f"当前空间总数: {current_total_spaces}")

    diff = current_total_spaces - target_total_spaces

    if diff < 0:
        num_to_create = abs(diff)
        print(f"➕ 检测到空间不足，需要创建 {num_to_create} 个新空间。")
        for i in range(num_to_create):
            print(f"   正在创建第 {i+1}/{num_to_create} 个新空间...")
            run_command(["yabai", "-m", "space", "--create"], is_json=False)
        print("✅ 空间总数已调整完毕。")

    elif diff > 0:
        # --- 修正后的删除逻辑 ---
        num_to_destroy = diff
        print(f"➖ 检测到空间过多，需要删除 {num_to_destroy} 个空间。")
        for i in range(num_to_destroy):
            # 安全检查：确保我们不会删除系统上最后一个空间
            if (current_total_spaces - i) > 1:
                print(f"   正在删除最后一个空间 (第 {i+1}/{num_to_destroy} 次操作)...")
                # 使用 'last' 选择器，让 yabai 自己找到最后一个空间并删除
                run_command(["yabai", "-m", "space", "last", "--destroy"], is_json=False)
            else:
                print("⚠️ 警告：无法删除最后一个空间。脚本中止。")
                break 
        print("✅ 空间总数已调整完毕。")

    else:
        print("👍 空间总数正确，无需操作。")

    print("-" * 40)

    # =========================================================================
    # 阶段二: 分配和移动空间
    # =========================================================================
    print("--- 阶段二: 重新分配各显示器的空间 ---")
    
    print("🔎 正在获取最新的空间分布...")
    all_spaces = run_command(["yabai", "-m", "query", "--spaces"])

    spaces_by_display = defaultdict(list)
    for space in all_spaces:
        spaces_by_display[space['display']].append(space)
    
    # 检查是否真的需要移动，以防万一
    needs_moving = any(len(s) != DESIRED_SPACES_PER_DISPLAY for d_idx in spaces_by_display for s in [spaces_by_display[d_idx]] if d_idx in [d['index'] for d in displays])
    if not needs_moving:
        print("👍 所有显示器的空间分布已正确，无需移动。")
        print("-" * 40)
        print("🎉 所有任务完成！")
        return
        
    print("🚚 检测到空间分布不均，开始智能调度...")
    
    for display in displays:
        target_display_index = display['index']
        needed_count = DESIRED_SPACES_PER_DISPLAY - len(spaces_by_display[target_display_index])
        
        if needed_count > 0:
            print(f"🖥️ 显示器 {target_display_index} 需要 {needed_count} 个空间。")
            for i in range(needed_count):
                source_display_index = find_source_display(spaces_by_display)
                
                if source_display_index is None:
                    print("🚨 错误：找不到有多余空间的源显示器了，但仍有显示器需要空间。任务中止。")
                    return
                
                space_to_move = spaces_by_display[source_display_index].pop()
                
                print(f"   (第 {i+1}/{needed_count} 步) 将空间 #{space_to_move['index']} 从显示器 {source_display_index} 移动到显示器 {target_display_index}...")
                
                run_command([
                    "yabai", "-m", "space", str(space_to_move['index']),
                    "--display", str(target_display_index)
                ], is_json=False)
                
                spaces_by_display[target_display_index].append(space_to_move)

    print("✅ 空间移动和分配完成。")
    print("-" * 40)
    print("🎉 所有显示器的空间已检查并调整完毕！")


if __name__ == "__main__":
    manage_linear_spaces()
