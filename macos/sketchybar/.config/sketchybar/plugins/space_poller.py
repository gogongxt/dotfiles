#!/usr/bin/env python3

import json
import subprocess
import sys
from typing import Any, Dict, List

exclude_title = ["scratchpad"]
exclude_app = ["WeChat", "D-Chat", "ripdrag", "NetEaseMusic"]


def get_display_grouping_factor() -> int:
    """Get the number of spaces per display based on current monitor count.

    Returns:
        int: 10 if single monitor, 5 if multiple monitors.
    """
    try:
        display_count_json = subprocess.check_output(
            ["/opt/homebrew/bin/yabai", "-m", "query", "--displays"]
        ).decode("utf-8")
        displays = json.loads(display_count_json)
        display_count = len(displays)
        return 10 if display_count == 1 else 5
    except (subprocess.CalledProcessError, json.JSONDecodeError):
        return 5  # fallback to 5 if query fails


def remove_outdated_windows(space_id: int, current_window_ids: List[str]) -> None:
    """Remove sketchybar items for windows that are no longer present.

    Args:
        space_id: The space ID we're working with.
        current_window_ids: List of window IDs that should remain.
    """
    try:
        shown_ones_json = subprocess.check_output(
            ["/opt/homebrew/bin/sketchybar", "--query", f"win.{space_id}"]
        ).decode("utf-8")

        shown_ones = json.loads(shown_ones_json)
        to_be_removed = []

        for shown_one in shown_ones.get("bracket", []):
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


def add_window_items(
    space_id: int, windows: List[Dict[str, Any]], selected: bool
) -> List[str]:
    """Add or update sketchybar items for each window in the space.

    Args:
        space_id: The space ID we're working with.
        windows: List of window dictionaries to display.
        selected: Whether this space is currently selected.

    Returns:
        List of window item IDs that were created.
    """
    window_ids = []
    k = get_display_grouping_factor()
    display_id = int((int(space_id) - 1) / k) + 1

    for index, win in enumerate(windows):
        item_id = f"win.{int(space_id)}.{win['id']}"
        window_ids.append(item_id)

        # Check if item already exists
        try:
            subprocess.check_output(
                ["/opt/homebrew/bin/sketchybar", "--query", item_id],
                stderr=subprocess.DEVNULL,
            )
            # Item exists, just update its properties
            yabai_change_space = f"bash -c 'yabai -m space --focus {int(space_id)}'"
            cmd = [
                "/opt/homebrew/bin/sketchybar",
                "--set",
                item_id,
                f"icon.color={'0xffffffff' if selected else '0x80ffffff'}",
                f"background.padding_right=2",
                f"background.image=app.{win['app']}",
            ]
            subprocess.run(cmd, check=True, capture_output=True)
        except subprocess.CalledProcessError:
            # Item doesn't exist, create it
            yabai_change_space = f"bash -c 'yabai -m space --focus {int(space_id)}'"
            cmd = [
                "/opt/homebrew/bin/sketchybar",
                "--add",
                "item",
                item_id,
                "center",
                "--set",
                item_id,
                f"icon.color={'0xffffffff' if selected else '0x80ffffff'}",
                f"background.padding_left=2",
                f"background.padding_right=2",
                f"display={display_id}",
                "background.drawing=true",
                "background.height=10",
                "background.image.scale=0.75",
                f"background.image=app.{win['app']}",
                f"click_script={yabai_change_space}",
                "--move",
                item_id,
                "after",
                f"space.{int(space_id)}",
            ]
            subprocess.run(cmd, check=True)

    return window_ids


def create_window_group(space_id: int, window_ids: List[str], selected: bool) -> None:
    """Create or update the main bracket group containing space and window items.

    Args:
        space_id: The space ID we're working with.
        window_ids: List of window item IDs to include.
        selected: Whether this space is currently selected.
    """
    bracket_items = [f"space.{int(space_id)}"] + window_ids

    k = get_display_grouping_factor()
    display_id = int((int(space_id) - 1) / k) + 1
    bracket_name = f"win.{int(space_id)}"

    # Check if bracket already exists and get its current items
    current_items = []
    try:
        bracket_info = json.loads(
            subprocess.check_output(
                ["/opt/homebrew/bin/sketchybar", "--query", bracket_name]
            ).decode("utf-8")
        )
        current_items = bracket_info.get("bracket", [])
    except (subprocess.CalledProcessError, json.JSONDecodeError):
        pass

    # Check if items or selection state actually changed
    items_changed = set(current_items) != set(bracket_items)

    if items_changed:
        # Only remove and recreate if content actually changed
        try:
            subprocess.run(
                ["/opt/homebrew/bin/sketchybar", "--remove", bracket_name],
                check=True,
                capture_output=True,
            )
        except subprocess.CalledProcessError:
            pass

        if bracket_items:
            cmd = (
                [
                    "/opt/homebrew/bin/sketchybar",
                    "--add",
                    "bracket",
                    bracket_name,
                ]
                + bracket_items
                + [
                    "--set",
                    bracket_name,
                    "background.height=28",
                    f"background.border_width={'0' if selected else '1'}",
                    "background.border_color=0x80ffffff",
                    f"background.corner_radius={'5' if selected else '5'}",
                    f"background.color={'0xff89b482' if selected else '0x00ffffff'}",
                    f"display={display_id}",
                    f"click_script='yabai -m space --focus {int(space_id)}'",
                ]
            )
            subprocess.run(cmd, check=True)
    else:
        # Just update the visual properties without recreating
        cmd = [
            "/opt/homebrew/bin/sketchybar",
            "--set",
            bracket_name,
            f"background.border_width={'0' if selected else '1'}",
            f"background.color={'0xff89b482' if selected else '0x00ffffff'}",
        ]
        try:
            subprocess.run(cmd, check=True, capture_output=True)
        except subprocess.CalledProcessError:
            # If update fails, bracket might not exist, recreate it
            if bracket_items:
                cmd = (
                    [
                        "/opt/homebrew/bin/sketchybar",
                        "--add",
                        "bracket",
                        bracket_name,
                    ]
                    + bracket_items
                    + [
                        "--set",
                        bracket_name,
                        "background.height=28",
                        f"background.border_width={'0' if selected else '1'}",
                        "background.border_color=0x80ffffff",
                        f"background.corner_radius={'5' if selected else '5'}",
                        f"background.color={'0xff89b482' if selected else '0x00ffffff'}",
                        f"display={display_id}",
                        f"click_script='yabai -m space --focus {int(space_id)}'",
                    ]
                )
                subprocess.run(cmd, check=True)


def query_all_data():
    """Query yabai once for all needed data.

    Returns:
        tuple: (displays, spaces, windows) - three lists of data
    """
    try:
        displays = json.loads(
            subprocess.check_output(
                ["/opt/homebrew/bin/yabai", "-m", "query", "--displays"]
            )
        )

        spaces = json.loads(
            subprocess.check_output(
                ["/opt/homebrew/bin/yabai", "-m", "query", "--spaces"]
            )
        )

        windows = json.loads(
            subprocess.check_output(
                ["/opt/homebrew/bin/yabai", "-m", "query", "--windows"]
            )
        )

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
        if window.get("app") != "TencentMeeting":
            if (
                not window.get("has-ax-reference", False)
                or window.get("is-hidden", False)
                or window.get("is-minimized", False)
                or window.get("title", "") in exclude_title
                or window.get("app", "") in exclude_app
            ):
                continue
        else:
            if window.get("level") == 1001: # 悬浮窗
                continue
            if window.get('title') == '腾讯会议' and not window.get('is-visible'): # 主页面（非会议屏幕共享页面）
                continue
            pass

        space_id = window.get("space")
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
        if space.get("has-focus", False):
            return space.get("index", 1)
    return 1  # fallback


def update_space_display_with_windows(
    space_id: int, windows: List[Dict], selected: bool
) -> None:
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
        subprocess.run(
            change_space_icon_color_cmd,
            check=True,
            shell=True,
            text=True,
            capture_output=True,
        )
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
        is_selected = space_id == focused_index
        space_windows = windows_by_space.get(space_id, [])

        # Update this space with cached window data
        update_space_display_with_windows(space_id, space_windows, is_selected)


if __name__ == "__main__":
    main()
