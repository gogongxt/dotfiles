#!/bin/bash
# Restore kitty session from tmp.session and send notification
SESSION_FILE="$HOME/.config/kitty/session/tmp.session"

if [ ! -s "$SESSION_FILE" ]; then
  terminal-notifier -title "Kitty Session" -message "Restore failed: tmp.session is empty"
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
done < "$SESSION_FILE"

kitty --session "$SESSION_FILE" &>/dev/null &

count=${#names[@]}
list=$(IFS=', '; echo "${names[*]}")
terminal-notifier -title "Kitty Session Restored" -message "${count} session(s): ${list}"
