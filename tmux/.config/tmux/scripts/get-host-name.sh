#!/bin/bash

# Generate TMUX_HOST_NAME: <device>-<hostname>-<ip>
# Used by tmux status bar when TMUX_HOST_NAME is not set in shell environment

# Get device name (GPU/NPU)
get_device_name() {
    local name=""
    if command -v nvidia-smi &>/dev/null; then
        name=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | sed -n 's/^NVIDIA[[:space:]]\+//p' | head -n1)
    elif command -v npu-smi &>/dev/null; then
        name=$(npu-smi info 2>/dev/null | grep -oP 'Ascend\d+' | head -n1)
    elif [ "$(uname -s)" = "Darwin" ]; then
        name=$(system_profiler SPDisplaysDataType 2>/dev/null | grep -Eo 'Apple M[0-9]+( Pro| Max| Ultra)?|AMD [[:alnum:]]+|Intel [[:alnum:]]+' | head -n1)
    fi
    echo "${name:-unknown}" | tr ' ' '-'
}

# Get IP address
get_ip_address() {
    local ip=""
    if [ "$(uname -s)" = "Darwin" ]; then
        ip=$(ifconfig 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -n1)
    else
        ip=$(hostname -I 2>/dev/null | cut -d' ' -f1)
        if [ -z "$ip" ] || [ "$ip" = "127.0.0.1" ]; then
            ip=$(ip route get 1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')
        fi
    fi
    echo "$ip"
}

echo "$(get_device_name)_$(hostname)_$(get_ip_address)"
