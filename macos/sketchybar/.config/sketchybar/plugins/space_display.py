#!/usr/bin/env python3

import subprocess
import json
import sys
from typing import List, Dict, Any, Optional

exclude_title = ["scratchpad"]
exclude_app = ["WeChat", "D-Chat", "ripdrag"]

def get_current_space() -> int:
    """Get the currently focused space index using yabai.
    
    Returns:
        int: The index of the currently focused space, defaults to 1 if query fails.
    """
    try:
        output = subprocess.check_output(["/opt/homebrew/bin/yabai", "-m", "query", "--spaces"])
        spaces = json.loads(output)
        for space in spaces:
            if space['has-focus']:
                return space['index']
        return 1  # fallback to space 1 if none has focus
    except (subprocess.CalledProcessError, json.JSONDecodeError):
        return 1  # fallback to space 1 if query fails

def get_space_windows(space_id: int) -> List[Dict[str, Any]]:
    """Get visible windows for a specific space.
    
    Args:
        space_id: The space ID to query windows for.
    
    Returns:
        List of window dictionaries that match the criteria.
    """
    try:
        windows_json = subprocess.check_output(
            ["/opt/homebrew/bin/yabai", "-m", "query", "--windows"]
        ).decode('utf-8')
        windows = json.loads(windows_json)
        
        res_w = [w for w in windows 
                if w['space'] == int(space_id)
                and w['has-ax-reference'] 
                and not w['is-hidden']
                and not w['is-minimized']
                and w['title'] not in exclude_title
                and w['app'] not in exclude_app 
        ]
        return res_w
    except (subprocess.CalledProcessError, json.JSONDecodeError):
        print("error!!!!!!")
        return []

def remove_outdated_windows(space_id: int, current_window_ids: List[str]) -> None:
    """Remove sketchybar items for windows that are no longer present.
    
    Args:
        space_id: The space ID we're working with.
        current_window_ids: List of window IDs that should remain.
    """
    try:
        shown_ones_json = subprocess.check_output([
            "/opt/homebrew/bin/sketchybar",
            "--query",
            f"win.{space_id}"
        ]).decode('utf-8')
        
        shown_ones = json.loads(shown_ones_json)
        to_be_removed = []
        
        for shown_one in shown_ones.get('bracket', []):
            if shown_one == f"space.{space_id}" or shown_one in current_window_ids:
                continue
            to_be_removed.append(shown_one)
        
        # print("to_be_removed",to_be_removed)
        if to_be_removed:
            remove_cmd = ["/opt/homebrew/bin/sketchybar"] + [
                arg for item in to_be_removed for arg in ["--remove", item]
            ]
            subprocess.run(remove_cmd, check=True)
            
    except subprocess.CalledProcessError:
        pass

def add_window_items(space_id: int, windows: List[Dict[str, Any]], selected: bool) -> List[str]:
    """Add sketchybar items for each window in the space.
    
    Args:
        space_id: The space ID we're working with.
        windows: List of window dictionaries to display.
        selected: Whether this space is currently selected.
    
    Returns:
        List of window item IDs that were created.
    """
    # print("windows",windows)
    window_ids = []
    for index, win in enumerate(windows):
        item_id = f"win.{int(space_id)}.{win['id']}"
        window_ids.append(item_id)

        
        display_id = int((int(space_id)-1)/5)+1
        yabai_change_space = f"bash -c 'yabai -m space --focus {int(space_id)}'"
        cmd = [
            "/opt/homebrew/bin/sketchybar",
            "--add", "item", item_id, "center",
            "--set", item_id, 
            f"icon.color={'0xffffffff' if selected else '0x80ffffff'}",
            f"background.padding_right={'5' if index == 0 else '0'}",
            f"display={display_id}",
            "background.drawing=true",
            "background.height=10",
            "background.image.scale=0.75",
            f"background.image=app.{win['app']}",
            f"click_script={yabai_change_space}",
            "--move", item_id, "after", f"space.{int(space_id)}",
        ]
        subprocess.run(cmd, check=True)
    
    # print("window_ids",window_ids)
    return window_ids

def create_window_group(space_id: int, window_ids: List[str], selected: bool) -> None:
    """Create the main bracket group containing space and window items.
    
    Args:
        space_id: The space ID we're working with.
        window_ids: List of window item IDs to include.
        selected: Whether this space is currently selected.
    """
    bracket_items = [f"space.{int(space_id)}"] + window_ids
    # print(bracket_items)
    
    # Remove existing bracket if exists
    try:
        subprocess.run(
            ["/opt/homebrew/bin/sketchybar", "--remove", f"win.{int(space_id)}"],
            check=True
        )
    except subprocess.CalledProcessError:
        pass
    
    display_id = int((int(space_id)-1)/5)+1
    if bracket_items:
        cmd = [
            "/opt/homebrew/bin/sketchybar",
            "--add", "bracket", f"win.{int(space_id)}",
        ] + bracket_items + [
            "--set", f"win.{int(space_id)}",
            "background.height=28",
            f"background.border_width={'0' if selected else '1'}",
            "background.border_color=0x80ffffff",
            f"background.corner_radius={'5' if selected else '5'}",
            f"background.color={'0xff89b482' if selected else '0x00ffffff'}",
            f"display={display_id}",
            f"click_script='yabai -m space --focus {int(space_id)}'",
        ]
        # print("cmd",cmd)
        subprocess.run(cmd, check=True)

def update_space_display(space_id: Optional[int] = None, selected: Optional[bool] = None) -> None:
    """Main function to update the display for a space.
    
    Args:
        space_id: The space ID to update. If None, gets current space.
        selected: Whether this space is currently selected. If None, defaults to True.
    """
    if space_id is None:
        space_id = get_current_space()
    if selected is None:
        selected = True
    # print("space_id",space_id)
    # print("selected",selected)

    windows = get_space_windows(space_id)
    # print(windows)
    window_ids = [f"win.{space_id}.{w['id']}" for w in windows]

    change_space_icon_color_cmd = f"/opt/homebrew/bin/sketchybar --set space.{int(space_id)} icon.color={'0xffffffff' if selected else '0x80ffffff'}"
    try:
        subprocess.run(change_space_icon_color_cmd, check=True, shell=True, text=True, capture_output=True)
    except subprocess.CalledProcessError as e:
        print(f"STDOUT: {e.stdout}")
    except Exception as e:
        print(f"Unexpected error: {e}")

    remove_outdated_windows(space_id, window_ids)
    created_window_ids = add_window_items(space_id, windows, selected)
    create_window_group(space_id, created_window_ids, selected)


def main() -> None:
    """Entry point when called directly from command line."""
    # Parse command line arguments
    space_id = None
    selected = True
    
    if len(sys.argv) > 1:
        try:
            space_id = int(sys.argv[1])
        except ValueError:
            print(f"Invalid space ID: {sys.argv[1]}", file=sys.stderr)
            sys.exit(1)
    
    if len(sys.argv) > 2:
        selected = sys.argv[2].lower() == 'true'
    
    update_space_display(space_id, selected)

if __name__ == "__main__":
    main()
