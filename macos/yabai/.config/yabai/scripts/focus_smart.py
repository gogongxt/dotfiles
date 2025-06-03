#!/usr/bin/env python3

import subprocess
import json
import sys
import math
import os

"""
首先是只在当前space中进行窗口距离排序和选择(包含float窗口)，（依旧保有记忆功能），
如果当前space中无法移动，比如碰到了墙壁还要继续移动，
就执行切换display的命令yabai -m display --focus west等。
"""

# State file path
STATE_FILE = "/tmp/yabai_focus_memory.json"
# Defines the mapping for opposite directions
OPPOSITE_DIRECTION = {
    'north': 'south',
    'south': 'north',
    'west': 'east',
    'east': 'west',
}

# --- State Management Helper Functions ---
def read_state():
    """Reads the state file"""
    if not os.path.exists(STATE_FILE):
        return None
    try:
        with open(STATE_FILE, 'r') as f:
            return json.load(f)
    except (json.JSONDecodeError, FileNotFoundError):
        return None

def write_state(origin_id, dest_id, direction):
    """Writes the complete journey to the state file"""
    state = {
        'origin_id': origin_id,
        'destination_id': dest_id,
        'direction': direction
    }
    with open(STATE_FILE, 'w') as f:
        json.dump(state, f)

def clear_state():
    """Deletes the state file if it exists"""
    if os.path.exists(STATE_FILE):
        os.remove(STATE_FILE)

# --- Yabai Command Execution Functions ---
def run_yabai_command(args):
    """Executes a yabai command and returns JSON output"""
    try:
        command = ['yabai', '-m'] + args
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        return json.loads(result.stdout) if result.stdout.strip() else None
    except (subprocess.CalledProcessError, json.JSONDecodeError) as e:
        if "cannot focus window" not in str(e):
             print(f"Error executing yabai command {' '.join(command)}: {e}", file=sys.stderr)
        return None

def get_focused_window():
    """Gets the currently focused window"""
    return run_yabai_command(['query', '--windows', '--window'])

def is_window_valid_candidate(window, focused_window_id):
    """Checks if a window is a valid target for focusing"""
    return window['is-visible'] and not window['is-minimized'] and window['id'] != focused_window_id

def main():
    """Main function to handle all focus logic."""
    if len(sys.argv) != 2:
        print("Usage: python focus.py <direction>", file=sys.stderr)
        print("Direction can be: north, south, east, west", file=sys.stderr)
        sys.exit(1)

    direction = sys.argv[1]
    current_window = get_focused_window()

    # --- Case 1: A window is currently focused ---
    if current_window:
        origin_id = current_window['id']
        last_state = read_state()

        # Memory Feature: Check for a valid return trip
        if (last_state and
                direction == OPPOSITE_DIRECTION.get(last_state['direction']) and
                current_window['id'] == last_state['destination_id']):
            
            return_target_id = last_state['origin_id']
            all_windows = run_yabai_command(['query', '--windows'])
            if any(w['id'] == return_target_id and w['is-visible'] for w in all_windows or []):
                run_yabai_command(['window', '--focus', str(return_target_id)])
                clear_state()
                return

        # --- In-space navigation logic ---
        windows_in_space = run_yabai_command(['query', '--windows', '--space'])
        focused_frame = current_window['frame']
        focused_pos = {'x': focused_frame['x'] + focused_frame['w'] / 2, 'y': focused_frame['y'] + focused_frame['h'] / 2}

        candidates = []
        for window in windows_in_space or []:
            if is_window_valid_candidate(window, origin_id):
                candidate_frame = window['frame']
                candidate_pos = {'x': candidate_frame['x'] + candidate_frame['w'] / 2, 'y': candidate_frame['y'] + candidate_frame['h'] / 2}
                
                is_directional_candidate = False
                if direction == 'north' and candidate_pos['y'] < focused_pos['y']: is_directional_candidate = True
                elif direction == 'south' and candidate_pos['y'] > focused_pos['y']: is_directional_candidate = True
                elif direction == 'west' and candidate_pos['x'] < focused_pos['x']: is_directional_candidate = True
                elif direction == 'east' and candidate_pos['x'] > focused_pos['x']: is_directional_candidate = True
                
                if is_directional_candidate:
                    distance = math.sqrt((candidate_pos['x'] - focused_pos['x'])**2 + (candidate_pos['y'] - focused_pos['y'])**2)
                    candidates.append({'id': window['id'], 'distance': distance})
        
        if candidates:
            # Found a target in the space, move focus.
            best_candidate = min(candidates, key=lambda c: c['distance'])
            write_state(origin_id, best_candidate['id'], direction)
            run_yabai_command(['window', '--focus', str(best_candidate['id'])])
        else:
            # No candidate in space, switch display.
            clear_state()
            subprocess.run(['yabai', '-m', 'display', '--focus', direction], check=False)

    # --- Case 2: No window is focused (e.g., focus is on desktop) ---
    else:
        # Interpret directional commands as space/display navigation.
        print(f"No window focused. Interpreting '{direction}' as a navigation command.", file=sys.stderr)
        clear_state() # No memory needed for this action.
        
        if direction == 'west':
            # Switch to the previous space
            subprocess.run(['yabai', '-m', 'space', '--focus', 'prev'], check=False)
        elif direction == 'east':
            # Switch to the next space
            subprocess.run(['yabai', '-m', 'space', '--focus', 'next'], check=False)
        elif direction in ['north', 'south']:
            # Switch to the display above/below
            subprocess.run(['yabai', '-m', 'display', '--focus', direction], check=False)


if __name__ == "__main__":
    main()
