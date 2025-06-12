#!/usr/bin/env python3

import subprocess
import json
import os
import sys

"""
这个脚本的自动执行发生在切换space的时候
会执行两次，比如从1切换到2
第一次SID=2,SELECTED=true
第二次SID=1,SELECTED=false
也就是会针对关联的两个space都做执行
"""

# print("="*10)

def get_current_space():
    try:
        output = subprocess.check_output(["/opt/homebrew/bin/yabai", "-m", "query", "--spaces"])
        spaces = json.loads(output)
        for space in spaces:
            if space['has-focus']:
                return space['index']
        return 1  # fallback to space 1 if none has focus
    except:
        return 1  # fallback to space 1 if query fails


def main():
    # 表示需要刷新第几个space
    if len(sys.argv) > 1:
        SID = sys.argv[1]
    else:
        SID = get_current_space()

    # 表示刷新的是否是当前的space（影响背景颜色）
    if len(sys.argv) > 2:
        SELECTED = sys.argv[2]
    else:
        SELECTED = 'true'

    # SID = int(os.getenv('SID'))
    # SELECTED = os.getenv('SELECTED') == 'true'
    # Get SID and SELECTED from env or use defaults
    # SID = int(os.getenv('SID', get_current_space()))  # space id
    # SELECTED = os.getenv('SELECTED', 'true').lower() == 'true' # 表示是否是当前选中的id
    # SID = int(os.getenv('YABAI_SPACE_ID', get_current_space()))  # space id
    # SELECTED = os.getenv('SELECTED', 'true').lower() == 'true' # 表示是否是当前选中的id
    # SELECTED = 'true'
    
    # print({ 'SID': SID, 'SELECTED': SELECTED })
    
    # Get windows info from yabai
    windows_json = subprocess.check_output(["/opt/homebrew/bin/yabai", "-m", "query", "--windows"]).decode('utf-8')
    windows = json.loads(windows_json)
    
    # Filter windows for current space
    space_windows = [w for w in windows 
                    if w['space'] == SID 
                    and w['has-ax-reference'] 
                    and not w['is-hidden']
                    and not w['is-minimized']
                    and w['title'] not in ["scratchpad"]
                    and w['app'] not in ["WeChat","D-Chat"]]
    
    window_ids = [f"win.{SID}.{w['id']}" for w in space_windows]
    # print("window_ids", window_ids)
    
    # Remove previous group if selected
    # if SELECTED:
    #     try:
    #         subprocess.run(["/opt/homebrew/bin/sketchybar", "--remove", f"win.{SID}"], check=True)
    #     except subprocess.CalledProcessError:
    #         pass
    
    # Remove outdated windows
    try:
        shown_ones_json = subprocess.check_output([
            "/opt/homebrew/bin/sketchybar",
            "--query",
            f"win.{SID}"
        ]).decode('utf-8')
        # print("shown_ones_json", shown_ones_json)
        shown_ones = json.loads(shown_ones_json)
        # print(shown_ones['bracket'])
        
        to_be_removed = []
        for shown_one in shown_ones['bracket']:
            if shown_one == f"space.{SID}" or shown_one in window_ids:
                continue
            to_be_removed.append(shown_one)
        
        # print({'to_be_removed': to_be_removed})
        
        if to_be_removed:
            remove_cmd = ["/opt/homebrew/bin/sketchybar"] + [arg for item in to_be_removed for arg in ["--remove", item]]
            subprocess.run(remove_cmd, check=True)
            
    except subprocess.CalledProcessError:
        pass
    
    # Add windows
    for index, win in enumerate(space_windows):
        item_id = f"win.{SID}.{win['id']}"
        item_pos = "center"
        
        cmd = [
            "/opt/homebrew/bin/sketchybar",
            "--add", "item", item_id, item_pos,
            "--set", f"space.{SID}",
            # f"icon.color={'0xa0ffffff' if SELECTED else '0x80ffffff'}",
            f"icon.color={'0xffffffff' if SELECTED else '0x80ffffff'}",
            "--set", item_id,
            f"background.padding_right={'5' if index == 0 else '0'}",
            "background.drawing=true",
            "background.height=10",
            "background.image.scale=0.75",
            f"background.image=app.{win['app']}",
            "--move", item_id, "after", f"space.{SID}"
        ]
        subprocess.run(cmd, check=True)
    
    # Prepare items to include in the bracket
    bracket_items = [f"space.{SID}"] + window_ids
    
    # Remove existing bracket if exists
    try:
        subprocess.run(["/opt/homebrew/bin/sketchybar", "--remove", f"win.{SID}"], check=True)
    except subprocess.CalledProcessError:
        pass
    
    # Add group containing space indicator and window items
    if bracket_items:
        cmd = [
            "/opt/homebrew/bin/sketchybar",
            "--add", "bracket", f"win.{SID}",
        ] + bracket_items + [
            "--set", f"win.{SID}",
            "background.height=28",
            f"background.border_width={'0' if SELECTED else '1'}",
            "background.border_color=0x80ffffff",
            f"background.corner_radius={'5' if SELECTED else '5'}",
            f"background.color={'0xff89b482' if SELECTED else '0x00ffffff'}"
        ]
        subprocess.run(cmd, check=True)

if __name__ == "__main__":
    main()
