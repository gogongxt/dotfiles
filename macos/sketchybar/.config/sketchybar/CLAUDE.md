# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a SketchyBar configuration for macOS that integrates with yabai (window manager) to create a dynamic status bar with space indicators and live window previews. The configuration automatically adapts to single or multi-monitor setups.

## Common Commands

### Reloading Configuration
```bash
# Reload sketchybar after config changes
sketchybar --reload
```

### Testing Python Scripts
```bash
# Test space display update for a specific space
python3 ~/.config/sketchybar/plugins/space_display.py <space_id> <True|False>

# Example: update space 2 as selected
python3 ~/.config/sketchybar/plugins/space_display.py 2 True

# Test spaces.py with environment variables (for space change events)
YABAI_SPACE_INDEX=2 YABAI_RECENT_SPACE_INDEX=1 python3 ~/.config/sketchybar/plugins/spaces.py
```

### Yabai Queries
```bash
# Query all displays
yabai -m query --displays

# Query all spaces
yabai -m query --spaces

# Query all windows
yabai -m query --windows

# Focus a specific space
yabai -m space --focus <space_id>
```

## Architecture

### Dynamic Space Grouping

The configuration automatically adjusts the number of spaces per display based on monitor count:
- **Single monitor**: 10 spaces per screen (spaces 1-10)
- **Multiple monitors**: 5 spaces per screen (spaces 1-5 on display 1, 6-10 on display 2, etc.)

This is controlled by the `K` variable in `sketchybarrc` (lines 44-50) and the `get_display_grouping_factor()` function in `space_display.py`.

### Item Naming Convention

- **Space items**: `space.<number>` (e.g., `space.1`, `space.2`)
- **Window items**: `win.<space_id>.<window_id>` (e.g., `win.1.1234`)
- **Spacer items**: `space.<number>.spacer`
- **Bracket groups**: `win.<space_id>` (groups space item with its windows)

### Main Configuration Flow

1. **Initialization** (`sketchybarrc` lines 53-86):
   - Queries yabai for display count
   - Creates N space items (default: 15)
   - Assigns each space to a display based on grouping factor
   - Sets up click scripts and update scripts for each space

2. **Space Updates** (`plugins/space_display.py`):
   - Called when a space is clicked or focus changes
   - Queries yabai for windows in the target space
   - Filters out hidden/minimized windows and excluded apps (line 9-10)
   - Removes outdated window items
   - Creates new window preview items with app icons
   - Creates bracket groups for visual grouping

3. **Event Handling** (`plugins/spaces.py`):
   - Designed to be called from yabai signals or manually
   - Reads environment variables `YABAI_SPACE_INDEX` and `YABAI_RECENT_SPACE_INDEX`
   - Updates both current and previous space displays

### Exclusion Lists

Windows are filtered based on:
- **Titles**: `["scratchpad"]` (line 9 in `space_display.py`)
- **Apps**: `["WeChat", "D-Chat", "ripdrag"]` (line 10 in `space_display.py`)

Modify these lists to include/exclude specific windows from the bar.

### Dependencies

- **SketchyBar**: `/opt/homebrew/bin/sketchybar`
- **yabai**: `/opt/homebrew/bin/yabai`
- **Python 3**: Required for space/window management scripts
- **jq**: JSON parsing for display count queries
- **Hack Nerd Font**: Icon font for labels
- **sketchybar-app-font**: App icon font

## Color Scheme

- **Active space**: `0xff89b482` (green-ish background)
- **Active icon**: `0xffffffff` (white)
- **Inactive icon**: `0x80ffffff` (50% transparent white)
- **Border**: `0x80ffffff` (50% transparent white)

## Visual Properties

- **Bar height**: 30px
- **Bar position**: bottom
- **Blur radius**: 20px
- **Bracket corner radius**: 5px
- **Window icon scale**: 0.75
- **Window item height**: 10px
- **Bracket group height**: 28px
