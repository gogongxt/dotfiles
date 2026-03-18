# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a [SketchyBar](https://github.com/FelixKratz/SketchyBar) configuration for macOS. It provides a status bar at the bottom of the screen with space indicators, window previews, and music/lyric display integration with NetEase Cloud Music.

## Architecture

### Main Configuration

- **`sketchybarrc`** - Main shell configuration script that initializes the bar, creates space items, and launches plugins. Uses dynamic space grouping: 10 spaces per display for single monitor, 5 spaces per display for multi-monitor setups.

### Plugin System

The `plugins/` directory contains both shell and Python scripts:

- **`lyric.py`** - Core music/lyric display plugin

  - Connects to local NetEase Cloud Music API (port 3123)
  - Streams media control events via `media-control stream --micros`
  - Fetches lyrics from NetEase API and caches them in `~/.cache/sketchybar/lyrics/`
  - Updates sketchybar items: `music_artwork`, `song_title`, `lyric`, `lyric_next`
  - Supports collapsed/expanded state via `~/.cache/sketchybar/lyric.state`

- **`space_display.py`** - Displays window icons in each space

  - Queries yabai for window information
  - Creates bracket groups combining space + window items
  - Shows focused space with green highlight (`0xff89b482`)
  - Filters excluded apps: `WeChat`, `D-Chat`, `ripdrag`, `NetEaseMusic`
  - Filters excluded titles: `scratchpad`

- **`space_poller.py`** - Polling daemon that updates all spaces

  - Runs in background, queries yabai periodically
  - Imports and reuses functions from `space_display.py` for efficiency

- **`yabai.py`** - Legacy helper script for yabai integration

- **Shell scripts** (legacy/not currently used): `clock.sh`, `battery.sh`, `volume.sh`, `front_app.sh`, `space.sh`

### Key Dependencies

- **sketchybar** - Status bar application
- **yabai** - Window manager (query via `/opt/homebrew/bin/yabai -m query`)
- **media-control** - For streaming media playback events
- **NeteaseCloudMusicApi** - Node.js API server for lyric fetching (launched on startup)
- **jq** - JSON processing for display count detection

## Common Tasks

### Reload Configuration

```bash
sketchybar --reload
```

### Restart a Specific Plugin

```bash
# Restart lyric plugin
pkill -f lyric.py && python3 "$CONFIG_DIR/plugins/lyric.py" &

# Restart space poller
pkill -f space_poller.py && python3 "$CONFIG_DIR/plugins/space_poller.py" &
```

### Debug Plugin Output

```bash
# Run lyric plugin in foreground to see output
python3 plugins/lyric.py
```

### Check Yabai Query

```bash
# Query current spaces
/opt/homebrew/bin/yabai -m query --spaces

# Query windows
/opt/homebrew/bin/yabai -m query --windows

# Query displays
/opt/homebrew/bin/yabai -m query --displays
```

## Item Naming Convention

- Space items: `space.1`, `space.2`, ..., `space.15`
- Space spacers: `space.{i}.spacer`
- Window items: `win.{space_id}.{window_id}`
- Bracket groups: `win.{space_id}`
- Music items: `music_artwork`, `song_title`, `lyric`, `lyric_next`

## Color Conventions

- Active/focused: `0xffffffff` (white)
- Inactive: `0x80ffffff` (semi-transparent white)
- Playing: `0xdd00ff00` (green)
- Background: `0x40000000` (semi-transparent black)
- Selected space highlight: `0xff89b482` (green)
