#!/bin/bash

# Generate TMUX_HOST_NAME: <device>_<hostname>_<ip>
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

# Strict IPv4 check: 4 dotted parts 0-255, no IPv6, no 127.*
valid_ipv4() {
    local ip="$1" o
    [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
    [[ "$ip" == 127.* ]] && return 1
    IFS='.' read -r -a o <<< "$ip"
    for o in "${o[@]}"; do
        (( 10#$o <= 255 )) || return 1
    done
    return 0
}

# Get IP address — the routable NIC's IPv4: 
# default-route src → UDP connect (no packets leave the host) → hostname -I → public-IP curl
# each candidate validated before use.
get_ip_address() {
    local ip="" tok url
    if [ "$(uname -s)" = "Darwin" ]; then
        ip=$(ifconfig 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -n1)
    else
        ip=$(ip route get 1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -n1)
        if ! valid_ipv4 "$ip" && command -v python3 &>/dev/null; then
            ip=$(python3 -c 'import socket
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.connect(("8.8.8.8", 80))
print(s.getsockname()[0])' 2>/dev/null)
        fi
        if ! valid_ipv4 "$ip"; then
            for tok in $(hostname -I 2>/dev/null); do
                valid_ipv4 "$tok" && { ip="$tok"; break; }
            done
        fi
        if ! valid_ipv4 "$ip"; then
            for url in ifconfig.me api.ipify.org; do
                ip=$(curl -s --connect-timeout 1 "$url" 2>/dev/null | tr -d '[:space:]')
                valid_ipv4 "$ip" && break
                ip=""
            done
        fi
    fi
    echo "$ip"
}

echo "$(get_device_name)_$(hostname)_$(get_ip_address)"
