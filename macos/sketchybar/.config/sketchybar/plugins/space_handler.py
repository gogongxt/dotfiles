#!/usr/bin/env python3

import json
import os
import subprocess
import sys
from typing import Any, Dict, List

# Excluded apps and titles
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
        shown_ones_json = (
            subprocess.check_output(
                ["/opt/homebrew/bin/sketchybar", "--query", f"win.{space_id}"],
                stderr=subprocess.DEVNULL,
            )
            .decode("utf-8")
            .strip()
        )

        if not shown_ones_json:
            return

        shown_ones = json.loads(shown_ones_json)
        to_be_removed = []

        for shown_one in shown_ones.get("bracket", []):
            if shown_one == f"space.{space_id}" or shown_one in current_window_ids:
                continue
            to_be_removed.append(shown_one)

        if to_be_removed:
            remove_cmd = ["/opt/homebrew/bin/sketchybar"] + [
                arg for item in to_be_removed for arg in ["--remove", item]
            ]
            subprocess.run(remove_cmd, check=True, capture_output=True)

    except (subprocess.CalledProcessError, json.JSONDecodeError):
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
                ["/opt/homebrew/bin/sketchybar", "--query", bracket_name],
                stderr=subprocess.DEVNULL,
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
            if window.get("level") == 1001:  # 悬浮窗
                continue
            if window.get("title") == "腾讯会议" and not window.get(
                "is-visible"
            ):  # 主页面（非会议屏幕共享页面）
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


def handle_space_change(info: Dict) -> None:
    """Handle space_change event - update visual highlight for all displays.

    Args:
        info: Event info containing focused space per display (e.g., {"display-1": 1, "display-2": 11})
    """
    # Parse focused spaces from info
    focused_spaces = {}
    for key, value in info.items():
        if key.startswith("display-"):
            try:
                display_id = int(key.split("-")[1])
                focused_spaces[display_id] = value
            except (ValueError, IndexError):
                continue

    # Update visual highlight for all spaces
    k = get_display_grouping_factor()
    total_spaces = 15  # From sketchybarrc N=15

    for space_id in range(1, total_spaces + 1):
        # Determine which display this space belongs to
        display_id = int((space_id - 1) / k) + 1

        # Check if this space is focused on its display
        is_selected = focused_spaces.get(display_id) == space_id

        # Update space icon color (fast)
        try:
            subprocess.run(
                [
                    "/opt/homebrew/bin/sketchybar",
                    "--set",
                    f"space.{space_id}",
                    f"icon.color={'0xffffffff' if is_selected else '0x80ffffff'}",
                ],
                check=True,
                capture_output=True,
            )
        except subprocess.CalledProcessError:
            pass

        # Update bracket background color (fast)
        bracket_name = f"win.{space_id}"
        try:
            subprocess.run(
                [
                    "/opt/homebrew/bin/sketchybar",
                    "--set",
                    bracket_name,
                    f"background.border_width={'0' if is_selected else '1'}",
                    f"background.color={'0xff89b482' if is_selected else '0x00ffffff'}",
                ],
                check=True,
                capture_output=True,
            )
        except subprocess.CalledProcessError:
            pass


def handle_space_windows_change(info: Dict) -> None:
    """Handle space_windows_change event - update specific space.

    Args:
        info: Event info containing space ID and apps
    """
    space_id = info.get("space")
    if space_id is None:
        return

    # Query all data to get current state
    displays, spaces, windows = query_all_data()

    if not displays or not spaces:
        return

    # Find focused space
    focused_index = find_focused_space(spaces)

    # Group windows by space
    windows_by_space = group_windows_by_space(windows)

    # Update only the changed space
    is_selected = space_id == focused_index
    space_windows = windows_by_space.get(space_id, [])

    update_space_display_with_windows(space_id, space_windows, is_selected)


def handle_display_change(info: Dict) -> None:
    """Handle display_change event - update all displays.

    Args:
        info: Event info (display ID that changed)
    """
    # Query all data to get current state for all displays
    displays, spaces, windows = query_all_data()

    if not displays or not spaces:
        return

    # Build a mapping of display ID to focused space index
    display_focused_spaces = {}
    for space in spaces:
        if space.get("has-focus", False):
            display_id = space.get("display")
            if display_id is not None:
                display_focused_spaces[display_id] = space.get("index")

    # Group windows by space
    windows_by_space = group_windows_by_space(windows)

    # Update all spaces with their appropriate display and selection state
    k = get_display_grouping_factor()
    total_spaces = 15  # From sketchybarrc N=15

    for space_id in range(1, total_spaces + 1):
        # Determine which display this space belongs to
        display_id = int((space_id - 1) / k) + 1

        # Check if this space is focused on its display
        is_selected = display_focused_spaces.get(display_id) == space_id

        # Get windows for this space
        space_windows = windows_by_space.get(space_id, [])

        # Update the space display
        update_space_display_with_windows(space_id, space_windows, is_selected)


def main():
    """Main event handler - process sketchybar events directly."""
    sender = os.environ.get("SENDER", "")
    info_str = os.environ.get("INFO", "{}")

    try:
        info = json.loads(info_str)
    except json.JSONDecodeError:
        return

    # Process event directly
    if sender == "space_change":
        handle_space_change(info)
    elif sender == "space_windows_change":
        handle_space_windows_change(info)
    elif sender == "display_change":
        handle_display_change(info)


if __name__ == "__main__":
    main()
