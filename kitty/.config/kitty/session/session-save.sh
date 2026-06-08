#!/bin/bash
# Save current kitty tabs matching "tmux *" to a session file
SESSION_FILE="$HOME/.config/kitty/session/tmp.session"
TMP_TITLES=$(mktemp)

SOCKET=$(ls /tmp/mykitty-* 2>/dev/null | head -1)
if [ -z "$SOCKET" ]; then
  terminal-notifier -title "Kitty Session" -message "Save failed: no kitty socket found"
  rm -f "$TMP_TITLES"
  exit 1
fi

kitten @ --to "unix:$SOCKET" ls 2>/dev/null | jq -r '.[].tabs[].title' > "$TMP_TITLES"

> "$SESSION_FILE"
names=()

while read -r title; do
  case "$title" in
    tmux\ *)
      tmux_name="${title#tmux }"
      names+=("$tmux_name")
      cat <<EOF >> "$SESSION_FILE"
new_tab $title
launch zsh -ic "myssh A800x2 -c 'tmux $tmux_name'"

EOF
      ;;
  esac
done < "$TMP_TITLES"

rm -f "$TMP_TITLES"

count=${#names[@]}
if [ "$count" -gt 0 ]; then
  list=$(IFS=', '; echo "${names[*]}")
  terminal-notifier -title "Kitty Session Saved" -message "${count} session(s): ${list}"
else
  terminal-notifier -title "Kitty Session Saved" -message "No tmux sessions found"
fi
