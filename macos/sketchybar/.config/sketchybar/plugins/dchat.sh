#!/bin/bash

# D-Chat status label
sketchybar --add item dchat right \
    --set dchat \
    update_freq=3 \
    icon.drawing=off \
    label.font="Hack Nerd Font:Bold:13.0" \
    label.color="0xffdddddd" \
    label.padding_left=0 \
    label.padding_right=4 \
    script="bash $PLUGIN_DIR/app_status.sh" \
    click_script="open -a D-Chat"

# D-Chat icon (image only)
sketchybar --add item dchat_icon right \
    --set dchat_icon \
    icon.drawing=off \
    label.drawing=off \
    background.drawing=on \
    background.image="$CONFIG_DIR/icons/dchat.png" \
    background.image.scale=0.12 \
    background.height=20 \
    background.width=20 \
    background.color=0x00000000 \
    padding_left=0 \
    padding_right=0 \
    click_script="open -a D-Chat"

# D-Chat bracket
sketchybar --add bracket dchat_bracket dchat dchat_icon \
    --set dchat_bracket background.drawing=on background.color=0x30aaaaaa background.height=20 background.corner_radius=10 background.padding_left=5 background.padding_right=5
sketchybar --add item dchat_bracket.spacer right \
    --set dchat_bracket.spacer padding_left=0 padding_right=0
