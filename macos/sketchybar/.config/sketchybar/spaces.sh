#!/bin/bash

echo "=========="

main() {
    local SID=$((10#${SID})) # space id (force base 10)
    local SELECTED=$([ "$SELECTED" = "true" ] && echo true || echo false) # whether it's the currently selected id
    
    echo "{\"SID\": $SID, \"SELECTED\": $SELECTED}"
    
    # Get windows info from yabai
    local windows_json=$(/opt/homebrew/bin/yabai -m query --windows)
    local windows=$(echo "$windows_json" | jq -c '.[]')
    
    # Filter windows for current space
    local space_windows=()
    while IFS= read -r window; do
        local space=$(echo "$window" | jq -r '.space')
        local has_ax_ref=$(echo "$window" | jq -r '.["has-ax-reference"]')
        local is_hidden=$(echo "$window" | jq -r '.["is-hidden"]')
        local is_minimized=$(echo "$window" | jq -r '.["is-minimized"]')
        
        if [ "$space" -eq "$SID" ] && [ "$has_ax_ref" = "true" ] && \
           [ "$is_hidden" = "false" ] && [ "$is_minimized" = "false" ]; then
            space_windows+=("$window")
        fi
    done <<< "$windows"
    
    local window_ids=()
    for window in "${space_windows[@]}"; do
        local id=$(echo "$window" | jq -r '.id')
        window_ids+=("win.$SID.$id")
    done
    echo "window_ids ${window_ids[@]}"
    
    # Remove previous group if selected
    if [ "$SELECTED" = true ]; then
        /opt/homebrew/bin/sketchybar --remove "win.$SID" || true
    fi
    
    echo "debug point1"
    
    # Remove outdated windows
    echo "debug point2"
    echo "win.$SID"
    /opt/homebrew/bin/sketchybar --query win.3
    if shown_ones_json=$(/opt/homebrew/bin/sketchybar --query "win.$SID" 2>/dev/null); then
        echo "debug point3"
        echo "shown_ones_json $shown_ones_json"
        local bracket=$(echo "$shown_ones_json" | jq -r '.bracket[]')
        
        local to_be_removed=()
        for shown_one in $bracket; do
            if [ "$shown_one" = "space.$SID" ] || [[ " ${window_ids[@]} " =~ " $shown_one " ]]; then
                continue
            fi
            to_be_removed+=("$shown_one")
        done
        
        echo "{\"to_be_removed\": [${to_be_removed[@]}]}"
        
        if [ ${#to_be_removed[@]} -gt 0 ]; then
            for item in "${to_be_removed[@]}"; do
                /opt/homebrew/bin/sketchybar --remove "$item"
            done
        fi
    fi
    
    # Add windows
    local index=0
    for window in "${space_windows[@]}"; do
        local id=$(echo "$window" | jq -r '.id')
        local app=$(echo "$window" | jq -r '.app')
        local item_id="win.$SID.$id"
        local item_pos=$([ "$SID" -gt 5 ] && echo "e" || echo "q") # right or left
        
        /opt/homebrew/bin/sketchybar \
            --add item "$item_id" "$item_pos" \
            --set "space.$SID" \
            "icon.color=$([ "$SELECTED" = true ] && echo "0xa0ffffff" || echo "0x80ffffff")" \
            --set "$item_id" \
            "background.padding_right=$([ "$index" -eq 0 ] && echo "5" || echo "0")" \
            "background.drawing=true" \
            "background.height=10" \
            "background.image.scale=0.75" \
            "background.image=app.$app" \
            --move "$item_id" $([ "$SID" -gt 5 ] && echo "after" || echo "before") "space.$SID"
        
        ((index++))
    done
    
    # Add group containing space indicator and window items
    /opt/homebrew/bin/sketchybar \
        --add bracket "win.$SID" "space.$SID" "/win\\.$SID.*/" \
        --set "win.$SID" \
        "background.height=28" \
        "background.border_width=$([ "$SELECTED" = true ] && echo "0" || echo "1")" \
        "background.border_color=0x80ffffff" \
        "background.corner_radius=5" \
        "background.color=$([ "$SELECTED" = true ] && echo "0x80ffffff" || echo "0x00ffffff")"
}

# Get environment variables
SID=${SID:-0}
SELECTED=${SELECTED:-false}

main "$@"
