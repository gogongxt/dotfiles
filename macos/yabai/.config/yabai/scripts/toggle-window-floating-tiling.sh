#!/usr/bin/env bash

# Toggle a window between floating and tiling.
# Only works when the workspace layout is bsp, i.e., the windows in it are tiled.

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
    echo $(yabai -m query --windows --window | jq .frame) >> $tmpfile
    yabai -m window --toggle float

  # If the window is tiling, toggle it to be floating.
  # If it is floating before, restore its previous position and size. Otherwise, place
  # the floating window to the center of the display. (Its position and size have been
  # calculated and stored in temp files (based on the different sizes of monitors) when
  # yabai is initialized. See yabairc)
  else
    yabai -m window --toggle float
    # [ $border = 'on' ] && yabai -m window --toggle border
    if [ -e $tmpfile ]; then
      read -r x y w h <<< $(echo $(cat $tmpfile | jq '.x, .y, .w, .h'))
      yabai -m window --move abs:$x:$y
      yabai -m window --resize abs:$w:$h
      rm $tmpfile
    else
      display_info=$(yabai -m query --displays --display $display)
      display_width=$(echo $display_info | jq .frame.w)
      display_height=$(echo $display_info | jq .frame.h)
      display_width=${display_width%.*}
      display_height=${display_height%.*}
      # 计算 50% 宽高
      window_width=$((display_width * 60 /100))
      window_width=${window_width%.*}
      window_height=$((display_height * 60 /100))
      window_height=${window_height%.*}
      # 计算居中位置
      pos_x=$(( (display_width - window_width) / 2 ))
      pos_x=${pos_x%.*}
      pos_y=$(( (display_height - window_height) / 2 ))
      pos_y=${pos_y%.*}
      yabai -m window --resize abs:$window_width:$window_height
      yabai -m window --move abs:$pos_x:$pos_y
    fi
  fi

fi
