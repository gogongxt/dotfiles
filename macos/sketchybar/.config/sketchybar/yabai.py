#!/usr/bin/env python3

import subprocess
import json

def get_active_space_id():
    """获取当前聚焦的 space ID"""
    spaces = json.loads(subprocess.check_output(["/opt/homebrew/bin/yabai", "-m", "query", "--spaces"]))
    for space in spaces:
        if space["has-focus"]:
            return space["index"]
    return 1  # 默认 fallback

def main():
    active_sid = get_active_space_id()
    
    # 获取所有窗口
    windows = json.loads(subprocess.check_output(["/opt/homebrew/bin/yabai", "-m", "query", "--windows"]))
    
    # 按 space 分组窗口
    space_windows = {}
    for win in windows:
        if not win["is-visible"] or win["is-minimized"]:
            continue
        sid = win["space"]
        if sid not in space_windows:
            space_windows[sid] = []
        space_windows[sid].append(win)
    
    # 为每个 space 更新 sketchybar
    for sid, wins in space_windows.items():
        window_ids = [f"win.{sid}.{w['id']}" for w in wins]
        
        # 先清理旧项目
        subprocess.run(["/opt/homebrew/bin/sketchybar", "--remove", f"win.{sid}"], stderr=subprocess.DEVNULL)
        
        # 添加窗口图标
        for win in wins:
            subprocess.run([
                "/opt/homebrew/bin/sketchybar",
                "--add", "item", f"win.{sid}.{win['id']}", "center",
                "--set", f"win.{sid}.{win['id']}",
                f"background.image=app.{win['app']}",
                "background.drawing=on",
                "background.image.scale=0.75"
            ])
        
        # 创建 bracket 分组
        if window_ids:
            bracket_items = [f"space.{sid}"] + window_ids  # 先合并列表
            cmd = [
                "/opt/homebrew/bin/sketchybar",
                "--add", "bracket", f"win.{sid}",
            ] + bracket_items + [  # 再拼接其他参数
                "--set", f"win.{sid}",
                f"background.color={'0x80ffffff' if sid == active_sid else '0x00ffffff'}",
                "background.height=28"
            ]
            subprocess.run(cmd, check=True)

    # subprocess.run(cmd, check=True)
    #     if window_ids:
    #         subprocess.run([
    #             "/opt/homebrew/bin/sketchybar",
    #             "--add", "bracket", f"win.{sid}", f"space.{sid}" ] + window_ids,
    #             "--set", f"win.{sid}",
    #             f"background.color={'0x80ffffff' if sid == active_sid else '0x00ffffff'}",
    #             "background.height=28"
    #         ])

if __name__ == "__main__":
    main()
