#!/bin/sh

# The volume_change event supplies a $INFO variable in which the current volume
# percentage is passed to the script.

if [ "$SENDER" = "volume_change" ]; then
  VOLUME="$INFO"

  # Detect if current output device is Bluetooth (headphones)
  IS_BLUETOOTH=false

  # Get Default Output Device transport type
  TRANSPORT=$(system_profiler SPAudioDataType 2>/dev/null | grep -A 5 "Default Output Device: Yes" | grep "Transport:" | awk '{print $2}')

  if [ "$TRANSPORT" = "Bluetooth" ]; then
    IS_BLUETOOTH=true
  fi

  # Set icon based on device type and volume
  if [ "$IS_BLUETOOTH" = true ]; then
    ICON=""
  else
    if [ "$VOLUME" = "0" ]; then
      ICON="󰖁"
    else
      ICON="󰕾"
    fi
  fi

  sketchybar --set "$NAME" icon="$ICON" label="$VOLUME%"
fi
