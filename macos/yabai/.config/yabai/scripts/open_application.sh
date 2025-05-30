#!/bin/bash

# bash $HOME/.config/yabai/scripts/open_application.sh "app_name" app_start 8

if [ $# -lt 2 ]; then
    echo "Error: Not enough arguments"
    echo "Usage: $0 <app_name> <command> [workspace]"
    exit 1
fi

app_name=$1
command=$2
workspace=$3

# Focus on the target workspace
bash $HOME/.config/yabai/scripts/safe_focus_space.sh "focus" "$workspace"
# yabai -m space --focus "$workspace"

# Check if the app is already running on the specified workspace
app_found=$(yabai -m query --windows --space "$workspace" | jq ".[] | select(.app == \"$app_name\")" | wc -l)

if [ "$app_found" -eq 0 ]; then
    # If not found, launch the application
    echo "Launching $app_name ($command) on space $workspace"
    eval "$command"
else
    # If found, do nothing
    echo "$app_name is already running on space $workspace - not launching"
fi


##===========#===========#======================

# Attempt to focus the window of the application
# This works for both newly launched and already running applications
app_window_id=$(yabai -m query --windows --space "$workspace" | jq -r ".[] | select(.app == \"$app_name\") | .id")
if [ -n "$app_window_id" ]; then
    echo "Focusing on $app_name window (ID: $app_window_id)"
    yabai -m window --focus "$app_window_id"
else
    echo "Could not find a window for $app_name on space $workspace to focus."
fi
