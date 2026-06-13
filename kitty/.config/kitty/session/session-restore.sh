#!/bin/bash
# Restore kitty session from the latest tmp_*.session file
SESSION_DIR="$HOME/.config/kitty/session"

# Find the latest session file (highest number, glob sorted)
latest=""
for f in "$SESSION_DIR"/tmp_*.session; do
    [ -f "$f" ] && latest="$f"
done

if [ -z "$latest" ]; then
    terminal-notifier -title "Kitty Session" -message "Restore failed: no session files found"
    exit 1
fi

names=()
while read -r line; do
    case "$line" in
        new_tab\ *)
            name="${line#new_tab }"
            names+=("$name")
            ;;
    esac
done <"$latest"

slot=$(basename "$latest" | sed 's/tmp_\([0-9]*\)\.session/\1/')
kitty --session "$latest" &>/dev/null &

count=${#names[@]}
list=$(
    IFS=', '
    echo "${names[*]}"
)
terminal-notifier -title "Kitty Session Restored (#${slot})" -message "${count} session(s): ${list}"
