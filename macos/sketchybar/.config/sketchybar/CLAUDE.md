# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a [SketchyBar](https://github.com/FelixKratz/SketchyBar) configuration for macOS. SketchyBar is a status bar for macOS that can be customized with items and plugins.

## Commands

- **Reload configuration**: `sketchybar --reload`
- **Update all items**: `sketchybar --update`
- **Query item state**: `sketchybar --query <item_name>`
- **Start sketchybar**: `sketchybar` (from config directory)

## Architecture

The configuration consists of:

1. **`sketchybarrc`** - Main configuration entry point that creates all bar items and subscribes to events. Run with `sketchybar` to load.

2. **`plugins/`** - Custom plugins for dynamic content:
   - **`lyric.py`** - Displays lyrics from NetEase Cloud Music. Requires `NeteaseCloudMusicApi` running on port 3123. Uses `media-control stream --micros` to listen for playback events.
   - **`space_daemon.py`** - Resident daemon that renders app icons on space items (brackets `win.<space>`). Talks to yabai's unix socket directly (int32 length prefix + NUL-separated args + double NUL — never send raw JSON, it crashes yabai). Woken instantly by yabai signals (SIGUSR1 via `signal --add`, auto re-registered after yabai restarts) and by sketchybar events via `space_nudge.sh`; 1s poll as safety net. Keeps last-rendered state in memory, diffs, and pushes all changes as ONE chained sketchybar call (per-command errors don't abort the chain). Log: `/tmp/space_daemon.log`. Signal wakeups use `signal.set_wakeup_fd` — never call `Event.set()` in a signal handler (deadlocks inside `Event.wait()`'s lock window).
   - **`space_nudge.sh`** - sketchybar event → SIGUSR1 to space_daemon (redundant wake path).
   - **`space_poller.py`** - Legacy predecessor (unused).
   - **`*.sh`** - Simple shell script plugins (clock, battery, volume, front_app, space) triggered by sketchybar events.

3. **`yabai.py`** - Legacy helper for querying yabai window data (mostly superseded by space_handler.py).

## Key Behaviors

- **Dynamic space count**: Single monitor shows 10 spaces per display, multi-monitor shows 5 spaces per display (configured in sketchybarrc lines 45-50).
- **Lyric display**: Shows current playing song lyrics from NetEase Music. Click to toggle collapsed/expanded state.
- **Window icons**: App icons displayed on space items showing windows in that space.
- **Excluded apps**: TencentMeeting windows are filtered (except some levels), plus WeChat, D-Chat, ripdrag, NetEase app in `exclude_app` list (`space_daemon.py` `group_windows_by_space`).

## Dependencies

- sketchybar (`brew install sketchybar`)
- yabai (`brew install yabai`)
- `media-control` (comes with sketchybar)
- `NeteaseCloudMusicApi` (npm package for lyric fetching)
- `jq` (for parsing JSON in shell scripts)
