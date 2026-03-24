#!/bin/bash

if lsappinfo -all list | grep $NAME >>/dev/null; then
	LABEL=$(lsappinfo -all list | grep $NAME | egrep -o "\"StatusLabel\"=\{ \"label\"=\"?(.*?)\"? \}" | sed 's/\"StatusLabel\"={ \"label\"=\(.*\) }/\1/g')
	if [[ $LABEL =~ ^\".*\"$ ]]; then
		LABEL=$(echo $LABEL | sed 's/^"//' | sed 's/"$//')
		if [ -z "$LABEL" ]; then
			LABEL=0
		fi
	else
		LABEL=0
	fi
else
	LABEL="-"
fi

sketchybar --set $NAME label=$LABEL

# Update bracket background color and label color based on message count
if [ "$NAME" = "dchat" ]; then
	if [[ "$LABEL" != "0" && "$LABEL" != "-" ]]; then
		sketchybar --set dchat_bracket background.color=0xffdc8a78
		sketchybar --set dchat label.color=0xffffffff
	else
		sketchybar --set dchat_bracket background.color=0x30aaaaaa
		sketchybar --set dchat label.color=0xffdddddd
	fi
fi
