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

# Count existing session files
count=0
for f in "$SESSION_DIR"/tmp_*.session; do
    [ -f "$f" ] && count=$((count + 1))
done

# Rotate if buffer is full
if [ "$count" -ge "$MAX_SLOTS" ]; then
    rm -f "$SESSION_DIR/tmp_1.session"
    for ((i = 2; i <= MAX_SLOTS; i++)); do
        src="$SESSION_DIR/tmp_${i}.session"
        [ -f "$src" ] && mv "$src" "$SESSION_DIR/tmp_$((i - 1)).session"
    done
    target_slot=$MAX_SLOTS
else
    target_slot=$((count + 1))
fi

SESSION_FILE="$SESSION_DIR/tmp_${target_slot}.session"
>"$SESSION_FILE"

names=()
while read -r title; do
    case "$title" in
        tmux\ *)
            tmux_name="${title#tmux }"
            names+=("$tmux_name")
            cat <<EOF >>"$SESSION_FILE"
new_tab $title
launch zsh -ic "myssh A800x2 -c 'tmux $tmux_name'"

EOF
            ;;
    esac
done <"$TMP_TITLES"

rm -f "$TMP_TITLES"

if [ ${#names[@]} -gt 0 ]; then
    list=$(
        IFS=', '
        echo "${names[*]}"
    )
    terminal-notifier -title "Kitty Session Saved (#${target_slot}/${MAX_SLOTS})" -message "${#names[@]} session(s): ${list}"
else
    terminal-notifier -title "Kitty Session Saved" -message "No tmux sessions found"
fi
