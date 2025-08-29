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

def get_safe_spaces_to_remove(spaces_by_display):
    """获取可以安全删除的空间列表（不是显示器上的最后一个空间）"""
    safe_to_remove = []
    for display_idx, spaces in spaces_by_display.items():
        # 只有当显示器上有多个空间时，才能删除其中一个
        if len(spaces) > 1:
            # 按索引排序，选择最大的索引（通常是最后创建的空间）
            sorted_spaces = sorted(spaces, key=lambda x: x['index'], reverse=True)
            safe_to_remove.extend(sorted_spaces[:len(sorted_spaces) - 1])  # 保留至少一个空间
    
    # 按索引降序排列，这样我们先删除索引较大的空间
    return sorted(safe_to_remove, key=lambda x: x['index'], reverse=True)

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

    # 按显示器分组空间
    spaces_by_display = defaultdict(list)
    for space in all_spaces:
        spaces_by_display[space['display']].append(space)

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
        
        # 获取可以安全删除的空间列表
        safe_spaces_to_remove = get_safe_spaces_to_remove(spaces_by_display)
        
        if len(safe_spaces_to_remove) < num_to_destroy:
            print(f"⚠️ 警告: 只能安全删除 {len(safe_spaces_to_remove)} 个空间，但需要删除 {num_to_destroy} 个。")
            print("   将先删除可安全删除的空间，剩余的空间将在阶段二中通过移动来调整。")
            num_to_destroy = len(safe_spaces_to_remove)
        
        removed_count = 0
        for i in range(num_to_destroy):
            space_to_remove = safe_spaces_to_remove[i]
            print(f"   正在删除空间 #{space_to_remove['index']} (第 {i+1}/{num_to_destroy} 次操作)...")
            try:
                run_command(["yabai", "-m", "space", str(space_to_remove['index']), "--destroy"], is_json=False)
                removed_count += 1
            except subprocess.CalledProcessError as e:
                print(f"   ⚠️ 删除空间 #{space_to_remove['index']} 失败: {e.stderr.strip()}")
                # 继续尝试删除其他空间
        
        print(f"✅ 成功删除了 {removed_count} 个空间。")

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
    needs_moving = any(len(spaces) != DESIRED_SPACES_PER_DISPLAY for display_idx, spaces in spaces_by_display.items())
    if not needs_moving:
        print("👍 所有显示器的空间分布已正确，无需移动。")
        print("-" * 40)
        print("🎉 所有任务完成！")
        return
        
    print("🚚 检测到空间分布不均，开始智能调度...")
    
    # 首先，计算每个显示器需要多少空间
    display_needs = {}
    for display in displays:
        display_idx = display['index']
        current_count = len(spaces_by_display.get(display_idx, []))
        needed = DESIRED_SPACES_PER_DISPLAY - current_count
        display_needs[display_idx] = needed
    
    # 移动空间以满足需求
    moved_count = 0
    for target_display_idx, needed_count in display_needs.items():
        if needed_count > 0:
            print(f"🖥️ 显示器 {target_display_idx} 需要 {needed_count} 个空间。")
            for i in range(needed_count):
                source_display_idx = find_source_display(spaces_by_display)
                
                if source_display_idx is None:
                    print("🚨 错误：找不到有多余空间的源显示器了，但仍有显示器需要空间。")
                    break
                
                # 从源显示器获取一个空间（不是最后一个空间）
                if len(spaces_by_display[source_display_idx]) > 1:
                    # 选择索引最大的空间（通常是最后创建的空间）
                    space_to_move = max(spaces_by_display[source_display_idx], key=lambda x: x['index'])
                    spaces_by_display[source_display_idx].remove(space_to_move)
                    
                    print(f"   (第 {moved_count+1} 步) 将空间 #{space_to_move['index']} 从显示器 {source_display_idx} 移动到显示器 {target_display_idx}...")
                    
                    run_command([
                        "yabai", "-m", "space", str(space_to_move['index']),
                        "--display", str(target_display_idx)
                    ], is_json=False)
                    
                    spaces_by_display[target_display_idx].append(space_to_move)
                    moved_count += 1
                else:
                    print(f"   ⚠️ 无法从显示器 {source_display_idx} 移动空间，因为它是该显示器上最后一个空间。")
                    break

    print("✅ 空间移动和分配完成。")
    print("-" * 40)
    print("🎉 所有显示器的空间已检查并调整完毕！")


if __name__ == "__main__":
    manage_linear_spaces()
