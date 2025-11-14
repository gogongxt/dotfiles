#!/bin/sh

# Solve bug when use flameshot with picom and tiling window(i3)
# Ref: https://github.com/flameshot-org/flameshot/issues/784

focusedwindow_before=$(xdotool getactivewindow)
flameshot gui
[ "$focusedwindow_before" = "$(xdotool getactivewindow)" ] && xdotool windowfocus $focusedwindow_before
