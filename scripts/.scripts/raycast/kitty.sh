#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Kitty Create New Window
# @raycast.mode compact

# Optional parameters:
# @raycast.icon images/kitty.png


open -na Kitty --args --single-instance -d ~ --title "kitty"

