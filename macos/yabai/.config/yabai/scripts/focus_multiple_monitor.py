#!/usr/bin/env python3

"""
这个Python脚本是一个增强版的窗口聚焦工具，专为macOS的yabai窗口管理器设计，实现了智能的窗口聚焦和记忆功能。下面我将详细讲解它的实现逻辑和优先级。

优先看上次的反方向的记忆，有记忆就直接跳转。
这个会手机所有可见display的所有窗口进行计算距离，然后移动，也就是可以不用关注display就可以跨越。
"""

import subprocess
import json
import sys
import math
import os

# 状态文件路径
STATE_FILE = "/tmp/yabai_focus_memory.json"
# 定义方向的对应关系
OPPOSITE_DIRECTION = {
    'north': 'south',
    'south': 'north',
    'west': 'east',
    'east': 'west',
}

# --- 状态管理辅助函数 ---
def read_state():
    """读取状态文件"""
    if not os.path.exists(STATE_FILE):
        return None
    try:
        with open(STATE_FILE, 'r') as f:
            return json.load(f)
    except (json.JSONDecodeError, FileNotFoundError):
        return None

def write_state(origin_id, dest_id, direction):
    """将完整的行程写入状态文件"""
    state = {
        'origin_id': origin_id,
        'destination_id': dest_id,
        'direction': direction
    }
    with open(STATE_FILE, 'w') as f:
        json.dump(state, f)

def clear_state():
    """如果存在，则删除状态文件"""
    if os.path.exists(STATE_FILE):
        os.remove(STATE_FILE)

# --- Yabai 命令执行函数 ---
def run_yabai_command(args):
    """执行 yabai 命令并返回 JSON 输出"""
    try:
        result = subprocess.run(['yabai', '-m'] + args, capture_output=True, text=True, check=True)
        return json.loads(result.stdout) if result.stdout.strip() else None
    except (subprocess.CalledProcessError, json.JSONDecodeError) as e:
        if "cannot focus window" not in str(e):
             print(f"Error executing yabai command: {e}", file=sys.stderr)
        return None

def get_all_windows():
    return run_yabai_command(['query', '--windows'])

def get_focused_window():
    return run_yabai_command(['query', '--windows', '--window'])

def is_window_valid_candidate(window, focused_window_id):
    return window['is-visible'] and window['id'] != focused_window_id

def main():
    """主函数，处理聚焦逻辑"""
    if len(sys.argv) != 2:
        print("Usage: python focus.py <direction>", file=sys.stderr)
        print("Direction can be: north, south, east, west", file=sys.stderr)
        sys.exit(1)

    direction = sys.argv[1]
    last_state = read_state()
    current_window = get_focused_window()

    if not current_window:
        clear_state()
        sys.exit(1)

    # --- 升级版记忆功能：检查是否为有效的返回操作 ---
    if (last_state and
            direction == OPPOSITE_DIRECTION.get(last_state['direction']) and
            current_window['id'] == last_state['destination_id']):
        
        # 检查出发窗口是否还存在
        return_target_id = last_state['origin_id']
        all_windows = get_all_windows()
        if any(w['id'] == return_target_id and w['is-visible'] for w in all_windows or []):
            run_yabai_command(['window', '--focus', str(return_target_id)])
            clear_state()  # 返程票已使用，清除记忆
            return

    # 如果不是有效的返回操作，则将旧记忆视为作废，准备记录新行程
    origin_id = current_window['id']

    # --- 常规聚焦逻辑 ---
    # 1. 尝试原生 yabai 命令
    try:
        subprocess.run(['yabai', '-m', 'window', '--focus', direction], check=True, stderr=subprocess.PIPE)
        newly_focused_window = get_focused_window()
        # 如果焦点确实改变了，记录这次成功的行程
        if newly_focused_window and newly_focused_window['id'] != origin_id:
            write_state(origin_id, newly_focused_window['id'], direction)
        else: # 焦点未变，清除旧记忆
            clear_state()
        return
    except subprocess.CalledProcessError:
        pass  # 碰到屏幕边缘，正常，继续执行自定义逻辑

    # 2. 自定义跨显示器逻辑
    all_windows = get_all_windows()
    focused_frame = current_window['frame']
    focused_pos = {'x': focused_frame['x'], 'y': focused_frame['y']}

    candidates = []
    for window in all_windows or []:
        if is_window_valid_candidate(window, origin_id):
            candidate_frame = window['frame']
            candidate_pos = {'x': candidate_frame['x'], 'y': candidate_frame['y']}
            
            is_directional_candidate = False
            # 根据方向筛选候选窗口
            if direction == 'north' and candidate_pos['y'] < focused_pos['y']: is_directional_candidate = True
            elif direction == 'south' and candidate_pos['y'] > focused_pos['y']: is_directional_candidate = True
            elif direction == 'west' and candidate_pos['x'] < focused_pos['x']: is_directional_candidate = True
            elif direction == 'east' and candidate_pos['x'] > focused_pos['x']: is_directional_candidate = True
            
            if is_directional_candidate:
                distance = math.sqrt((candidate_pos['x'] - focused_pos['x'])**2 + (candidate_pos['y'] - focused_pos['y'])**2)
                candidates.append({'id': window['id'], 'distance': distance})

    if not candidates:
        clear_state()  # 未找到目标，没有发生移动，清除记忆
        return

    best_candidate = min(candidates, key=lambda c: c['distance'])
    
    # 在执行移动前，记录这次的行程
    write_state(origin_id, best_candidate['id'], direction)
    run_yabai_command(['window', '--focus', str(best_candidate['id'])])


if __name__ == "__main__":
    main()
