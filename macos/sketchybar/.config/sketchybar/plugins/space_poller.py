#!/usr/bin/env python3

import subprocess
import json
import sys
from typing import Dict, List, Any

# Import functions from space_display
from space_display import (
    exclude_title,
    exclude_app,
    get_display_grouping_factor,
    remove_outdated_windows,
    add_window_items,
    create_window_group,
)

def query_all_data():
    """Query yabai once for all needed data.

    Returns:
        tuple: (displays, spaces, windows) - three lists of data
    """
    try:
        displays = json.loads(subprocess.check_output([
            "/opt/homebrew/bin/yabai", "-m", "query", "--displays"
        ]))

        spaces = json.loads(subprocess.check_output([
            "/opt/homebrew/bin/yabai", "-m", "query", "--spaces"
        ]))

        windows = json.loads(subprocess.check_output([
            "/opt/homebrew/bin/yabai", "-m", "query", "--windows"
        ]))

        return displays, spaces, windows

    except (subprocess.CalledProcessError, json.JSONDecodeError) as e:
        print(f"Error querying yabai: {e}", file=sys.stderr)
        return [], [], []

def group_windows_by_space(windows: List[Dict]) -> Dict[int, List[Dict]]:
    """Group windows by space ID with filtering.

    Args:
        windows: List of all window dictionaries

    Returns:
        Dictionary mapping space ID to list of filtered windows
    """
    windows_by_space = {}

    for window in windows:
        # Apply same filters as get_space_windows in space_display.py
        if (not window.get('has-ax-reference', False) or
            window.get('is-hidden', False) or
            window.get('is-minimized', False) or
            window.get('title', '') in exclude_title or
            window.get('app', '') in exclude_app):
            continue

        space_id = window.get('space')
        if space_id is None:
            continue

        if space_id not in windows_by_space:
            windows_by_space[space_id] = []
        windows_by_space[space_id].append(window)

    return windows_by_space

def find_focused_space(spaces: List[Dict]) -> int:
    """Find the currently focused space index.

    Args:
        spaces: List of space dictionaries

    Returns:
        int: The index of the focused space, defaults to 1
    """
    for space in spaces:
        if space.get('has-focus', False):
            return space.get('index', 1)
    return 1  # fallback

def update_space_display_with_windows(space_id: int, windows: List[Dict], selected: bool) -> None:
    """Update display for a single space with pre-fetched windows.

    Args:
        space_id: The space ID to update
        windows: Pre-filtered list of windows for this space
        selected: Whether this space is currently selected
    """
    # Update space icon color
    change_space_icon_color_cmd = (
        f"/opt/homebrew/bin/sketchybar --set space.{int(space_id)} "
        f"icon.color={'0xffffffff' if selected else '0x80ffffff'}"
    )
    try:
        subprocess.run(change_space_icon_color_cmd, check=True, shell=True, text=True, capture_output=True)
    except subprocess.CalledProcessError:
        pass  # Silently handle errors

    # Get current window IDs from the windows list
    window_ids = [f"win.{space_id}.{w['id']}" for w in windows]

    # Remove outdated windows
    remove_outdated_windows(space_id, window_ids)

    # Add window items
    created_window_ids = add_window_items(space_id, windows, selected)

    # Create bracket group
    create_window_group(space_id, created_window_ids, selected)

def main():
    """Main polling function."""
    # Query all data once
    displays, spaces, windows = query_all_data()

    if not displays or not spaces:
        # Query failed, skip this cycle
        return

    # Determine configuration
    # Based on logic in sketchybarrc: single monitor = 10 spaces per screen, multi = 5
    display_count = len(displays)
    total_spaces = 15  # From sketchybarrc N=15

    # Find focused space
    focused_index = find_focused_space(spaces)

    # Group windows by space
    windows_by_space = group_windows_by_space(windows)

    # Update each space
    for space_id in range(1, total_spaces + 1):
        is_selected = (space_id == focused_index)
        space_windows = windows_by_space.get(space_id, [])

        # Update this space with cached window data
        update_space_display_with_windows(space_id, space_windows, is_selected)

if __name__ == "__main__":
    main()
