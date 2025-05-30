#!/usr/bin/env bash

# Toggle a window between floating and tiling.
# Only works when the workspace layout is bsp, i.e., the windows in it are tiled.

forceCenter=${1:-}

spaceType=$(yabai -m query --spaces --space | jq .type)
if [ $spaceType = '"bsp"' ]; then

  read -r id floating <<< $(echo $(yabai -m query --windows --window | jq '.id, ."is-floating"'))
  tmpfile=/tmp/yabai/yabai-tiling-floating-toggle/$id
  mkdir -p /tmp/yabai/yabai-tiling-floating-toggle

  # border=$(yabai -m config window_border)

  # If the window is floating, record its position and size into a temp file and toggle it to be tiling.
  if [[ $floating = true ]]
  then
    [ -e $tmpfile ] && rm $tmpfile

    if [ ! -z $forceCenter ]; then
      display=$(yabai -m query --windows --window | jq .display)
      . /tmp/yabai-tiling-floating-toggle/display-$display
      yabai -m window --move abs:$x:$y
      yabai -m window --resize abs:$w:$h
    else
      echo $(yabai -m query --windows --window | jq .frame) >> $tmpfile
      yabai -m window --toggle float
    fi

    # [ $border = 'on' ] && yabai -m window --toggle border

  # If the window is tiling, toggle it to be floating.
  # If it is floating before, restore its previous position and size. Otherwise, place
  # the floating window to the center of the display. (Its position and size have been
  # calculated and stored in temp files (based on the different sizes of monitors) when
  # yabai is initialized. See yabairc)
  else
    yabai -m window --toggle float
    # [ $border = 'on' ] && yabai -m window --toggle border
    if [ ! -z $forceCenter ]; then
      display=$(yabai -m query --windows --window | jq .display)
      . /tmp/yabai-tiling-floating-toggle/display-$display
      yabai -m window --move abs:$x:$y
      yabai -m window --resize abs:$w:$h
      echo $(yabai -m query --windows --window | jq .frame) >> $tmpfile
    elif [ -e $tmpfile ]
    then
      read -r x y w h <<< $(echo $(cat $tmpfile | jq '.x, .y, .w, .h'))
      yabai -m window --move abs:$x:$y
      yabai -m window --resize abs:$w:$h
      rm $tmpfile
    else
      display=$(yabai -m query --windows --window | jq .display)
      . /tmp/yabai-tiling-floating-toggle/display-$display
      yabai -m window --move abs:$x:$y
      yabai -m window --resize abs:$w:$h
    fi
  fi

fi
