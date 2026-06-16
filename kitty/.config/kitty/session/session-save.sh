#!/bin/bash
# Save current kitty tabs matching "tmux *" to a circular buffer of session files
SESSION_DIR="$HOME/.config/kitty/session"
MAX_SLOTS=9
TMP_TITLES=$(mktemp)

if [ -z "$KITTY_LISTEN_ON" ]; then
    terminal-notifier -title "Kitty Session" -message "Save failed: KITTY_LISTEN_ON not set"
    rm -f "$TMP_TITLES"
    exit 1
fi

kitten @ --to "$KITTY_LISTEN_ON" ls 2>/dev/null | jq -r '.[].tabs[].title' >"$TMP_TITLES"

# Collect tmux session names first
names=()
while read -r title; do
    case "$title" in
        tmux\ *)
            names+=("${title#tmux }")
            ;;
    esac
done <"$TMP_TITLES"

if [ ${#names[@]} -eq 0 ]; then
    rm -f "$TMP_TITLES"
    terminal-notifier -title "Kitty Session" -message "No tmux sessions found"
    exit 0
fi

# Compact: renumber existing files to fill gaps (e.g. delete tmp_1 -> tmp_2 becomes tmp_1)
slot=1
for ((i = 1; i <= MAX_SLOTS; i++)); do
    src="$SESSION_DIR/tmp_${i}.session"
    if [ -f "$src" ]; then
        if [ "$slot" -ne "$i" ]; then
            mv "$src" "$SESSION_DIR/tmp_${slot}.session"
        fi
        slot=$((slot + 1))
    fi
done
count=$((slot - 1))

# Rotate if buffer is full (drop oldest, everything shifts down by 1)
if [ "$count" -ge "$MAX_SLOTS" ]; then
    rm -f "$SESSION_DIR/tmp_1.session"
    for ((i = 2; i <= MAX_SLOTS; i++)); do
        src="$SESSION_DIR/tmp_${i}.session"
        [ -f "$src" ] && mv "$src" "$SESSION_DIR/tmp_$((i - 1)).session"
    done
    target_slot=$MAX_SLOTS
else
    target_slot=$slot
fi

# Write session file
SESSION_FILE="$SESSION_DIR/tmp_${target_slot}.session"
while read -r title; do
    case "$title" in
        tmux\ *)
            tmux_name="${title#tmux }"
            cat <<EOF >>"$SESSION_FILE"
new_tab $title
launch zsh -ic "myssh A800x2 -c 'tmux $tmux_name'"

EOF
            ;;
    esac
done <"$TMP_TITLES"

rm -f "$TMP_TITLES"

list=$(
    IFS=', '
    echo "${names[*]}"
)
terminal-notifier -title "Kitty Session Saved (#${target_slot}/${MAX_SLOTS})" -message "${#names[@]} session(s): ${list}"
