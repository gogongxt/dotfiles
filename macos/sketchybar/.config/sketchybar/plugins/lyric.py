#!/usr/bin/env python3
# Lyric display plugin for SketchyBar
# Displays current playing song lyric on the left side of the bar

import argparse
import json
import os
import re
import subprocess
import sys
import threading
import time

API_BASE = "http://localhost:3123"
STATE_FILE = os.path.expanduser("~/.cache/sketchybar/lyric.state")
LYRIC_CACHE_DIR = os.path.expanduser("~/.cache/sketchybar/lyrics")
TIME_INTERVAL_S = 0.1
TIME_BIAS_S = 0.1


def get_collapsed():
    """Get collapsed state from file"""
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE, "r") as f:
            return f.read().strip() == "collapsed"
    return False


def set_collapsed(collapsed):
    """Save collapsed state to file"""
    with open(STATE_FILE, "w") as f:
        f.write("collapsed" if collapsed else "expanded")


def handle_click():
    """Toggle collapsed state when clicked"""
    state_dir = os.path.dirname(STATE_FILE)
    if not os.path.exists(state_dir):
        os.makedirs(state_dir)

    collapsed = get_collapsed()
    set_collapsed(not collapsed)
    print(f"Toggled to: {'collapsed' if not collapsed else 'expanded'}")
    sys.exit(0)


# Ensure the directory and file exist
def ensure_state_file():
    """Create directory and state file if they don't exist"""
    state_dir = os.path.dirname(STATE_FILE)
    if not os.path.exists(state_dir):
        os.makedirs(state_dir)
    if not os.path.exists(STATE_FILE):
        with open(STATE_FILE, "w") as f:
            f.write("expanded")


ensure_state_file()


# Parse command line arguments
parser = argparse.ArgumentParser()
parser.add_argument("--click", action="store_true", help="Toggle collapsed state")
args = parser.parse_args()

if args.click:
    handle_click()


# Default values
defaults = {
    "title": "No Music",
    "artist": "",
    "timestampEpochMicros": int(time.time() * 1000000),
    "elapsedTimeMicros": 0,
    "playing": False,
    "durationMicros": 0,
}

live = dict(defaults)
current_lyric = []
current_song_id = None
lyric_index = 0  # 增量指针，记录当前歌词索引
lyric_index_song_id = None  # 跟踪当前索引对应的歌曲ID


def parse_lrc(lrc_text):
    """Parse lrc lyrics, return (time, lyric) list"""
    if not lrc_text or lrc_text == "":
        return []

    pattern = re.compile(r"\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)")
    lyrics = []

    for match in pattern.finditer(lrc_text):
        minutes = int(match.group(1))
        seconds = int(match.group(2))
        millis_str = match.group(3)
        if len(millis_str) == 2:
            millis = int(millis_str) * 10
        else:
            millis = int(millis_str)

        time_micros = (minutes * 60 + seconds) * 1000000 + millis * 1000
        text = match.group(4).strip()

        if text:
            lyrics.append((time_micros, text))

    lyrics.sort(key=lambda x: x[0])
    return lyrics


def get_cache_file_path(title, artist):
    """Get the cache file path for a song based on title and artist"""
    # Create a safe filename from title and artist
    safe_name = f"{title}_{artist}".replace("/", "_").replace("\\", "_")
    safe_name = "".join(c for c in safe_name if c.isalnum() or c in " _-").strip()
    # Limit filename length
    safe_name = safe_name[:100]
    return os.path.join(LYRIC_CACHE_DIR, f"{safe_name}.lrc")


def load_lyric_from_cache(title, artist):
    """Load lyrics from cache file if exists"""
    if not title or title == "?" or not artist or artist == "?":
        return None

    cache_file = get_cache_file_path(title, artist)
    if os.path.exists(cache_file):
        try:
            with open(cache_file, "r") as f:
                lrc_text = f.read()
            return parse_lrc(lrc_text)
        except Exception as e:
            print(f"Failed to load cached lyric: {e}", file=sys.stderr)
    return None


def save_lyric_to_cache(title, artist, lrc_text):
    """Save lyrics to cache file"""
    if not title or title == "?" or not artist or artist == "?":
        return

    try:
        # Ensure cache directory exists
        if not os.path.exists(LYRIC_CACHE_DIR):
            os.makedirs(LYRIC_CACHE_DIR)

        cache_file = get_cache_file_path(title, artist)
        with open(cache_file, "w") as f:
            f.write(lrc_text)
    except Exception as e:
        print(f"Failed to save lyric to cache: {e}", file=sys.stderr)


def fetch_lyric(title, artist):
    """Fetch lyrics from cache or NetEase cloud API"""
    global current_song_id, current_lyric

    if not title or title == "?" or not artist or artist == "?":
        return None

    # First check cache
    cached_lyric = load_lyric_from_cache(title, artist)
    if cached_lyric is not None:
        current_lyric = cached_lyric
        # Generate a fake song_id to prevent re-fetching
        current_song_id = f"cached_{title}_{artist}"
        return current_lyric

    # If not in cache, fetch from API
    keywords = f"{title} {artist}"

    search_cmd = [
        "curl",
        "-s",
        "-G",
        f"{API_BASE}/cloudsearch",
        "--data-urlencode",
        f"keywords={keywords}",
    ]
    search_result = subprocess.run(
        search_cmd, capture_output=True, text=True, timeout=10
    )

    if not search_result.stdout:
        return None

    try:
        search_data = json.loads(search_result.stdout)
    except json.JSONDecodeError:
        return None

    songs = search_data.get("result", {}).get("songs", [])

    if not songs:
        return None

    song_id = songs[0]["id"]

    # Skip if same song
    if song_id == current_song_id:
        return current_lyric

    current_song_id = song_id

    # Get lyrics
    lyric_cmd = ["curl", "-s", f"{API_BASE}/lyric?id={song_id}"]
    lyric_result = subprocess.run(lyric_cmd, capture_output=True, text=True, timeout=10)

    if not lyric_result.stdout:
        return None

    try:
        lyric_data = json.loads(lyric_result.stdout)
    except json.JSONDecodeError:
        return None

    lrc_text = lyric_data.get("lrc", {}).get("lyric", "")

    # Save to cache
    save_lyric_to_cache(title, artist, lrc_text)

    current_lyric = parse_lrc(lrc_text)

    return current_lyric


def get_current_lyric_line(lyrics, index):
    """Get lyric at given index"""
    if not lyrics or index >= len(lyrics):
        return None
    return lyrics[index][1]


def get_current_time_micros():
    """Calculate actual playback position in microseconds"""
    current_epoch = int(time.time() * 1000000)
    time_diff = current_epoch - live["timestampEpochMicros"]
    total_time = live["elapsedTimeMicros"] + live["playing"] * time_diff
    return total_time


def stream():
    """Background thread to listen for media control events"""
    global live

    process = subprocess.Popen(
        ["media-control", "stream", "--micros"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    for line_bytes in process.stdout:
        try:
            d = json.loads(line_bytes)
            p = d["payload"]
            if not d["diff"] and len(p) == 0:
                live = dict(defaults)
            else:
                p = {k: v for k, v in p.items() if v is not None}
                live.update(p)
        except (json.JSONDecodeError, KeyError):
            pass


def update_sketchybar(lyric_text, playing, title, artist):
    """Update sketchybar item with current lyric"""
    item_name = "lyric"

    # Check collapsed state
    collapsed = get_collapsed()

    # Format the display text
    if playing:
        icon = ">"
    else:
        icon = "||"

    if collapsed:
        # Only show icon when collapsed
        display_text = ""
    else:
        # Show full lyric
        display_text = lyric_text[:50] if lyric_text else "..."

    # Build full label: icon + lyric
    label = f"{icon} {display_text}"

    # Update sketchybar
    cmd = ["sketchybar", "--set", item_name, f"label={label}"]

    # If not playing or collapsed, dim the item
    if not playing or collapsed:
        cmd.extend(["label.color=0x80ffffff"])
    else:
        cmd.extend(["label.color=0xddffffff"])

    subprocess.run(cmd, capture_output=True)


def main():
    """Main loop"""
    global current_lyric

    # Start background thread for media events
    threading.Thread(target=stream, daemon=True).start()

    # Wait a bit for initial data
    time.sleep(0.5)

    last_lyric = None
    last_update = 0
    last_collapsed = get_collapsed()

    while True:
        # Calculate current playback time
        elapsed_micros = get_current_time_micros()

        title = live.get("title", "?")
        artist = live.get("artist", "?")
        playing = live["playing"]

        # Fetch new lyrics when song changes or starts playing
        if playing and title != "?" and artist != "?":
            fetch_lyric(title, artist)

        # Update lyric index (incremental: O(1) since time always increases)
        global lyric_index, lyric_index_song_id
        if current_song_id != lyric_index_song_id:
            lyric_index = 0
            lyric_index_song_id = current_song_id

        # Get current lyric line
        current_text = get_current_lyric_line(current_lyric, lyric_index)
        print(current_text)

        # Check collapsed state change
        current_collapsed = get_collapsed()

        # Update if: lyric changed, collapsed state changed, or every 5 seconds
        current_time = time.time()
        if (
            current_text != last_lyric
            or current_collapsed != last_collapsed
            or (current_time - last_update) > 5
        ):
            update_sketchybar(current_text, playing, title, artist)
            last_lyric = current_text
            last_collapsed = current_collapsed
            last_update = current_time

        # Update lyric index if needed
        while lyric_index < len(current_lyric) - 1:
            if (
                current_lyric[lyric_index + 1][0]
                <= elapsed_micros + TIME_BIAS_S * 1000000
            ):
                lyric_index += 1
            else:
                break

        time.sleep(TIME_INTERVAL_S)


if __name__ == "__main__":
    main()