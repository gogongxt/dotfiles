#!/bin/bash
#
# net_speed.sh - network traffic monitor (Linux netdev + InfiniBand)
#
# Usage: net_speed.sh [interval_seconds]
#   interval_seconds  refresh period in seconds (default: 1)
#
# Refreshes the terminal in place (no `clear` flicker, keeps scrollback)
# and compensates for the script's own runtime so consecutive frames are
# exactly one interval apart.

INTERVAL=${1:-1}

declare -A RX_NOW TX_NOW RX_LAST TX_LAST

# Epoch time in nanoseconds (works on RHEL8 / bash 4, no EPOCHREALTIME)
now_ns() { date +%s%N; }

# Print delta bytes as "X.XX" MB/s, clamping negatives (counter resets)
speed() {
    local v=$(($1 * 100 / 1048576))
    ((v < 0)) && v=0
    printf "%d.%02d" $((v / 100)) $((v % 100))
}

# In-place refresh only when attached to a terminal; plain output otherwise
if [[ -t 1 ]]; then
    REFRESH=$'\e[H\e[J' # cursor home + clear to end of screen
    printf '\e[?25l'    # hide cursor
    trap 'printf "\e[?25h"; exit 0' INT TERM EXIT
fi

# Next frame boundary (nanoseconds)
tick=$(($(now_ns) + INTERVAL * 1000000000))

while true; do
    printf '%s' "$REFRESH"

    echo "===== $(date '+%F %T') ====="
    printf "%-15s %15s %15s %10s\n" "DEVICE" "RX(MB/s)" "TX(MB/s)" "TYPE"
    echo "------------------------------------------------------------"

    RX_NOW=()
    TX_NOW=()

    # Linux network devices (skip IPoIB virtual nics ib*)
    for dev in /sys/class/net/*; do
        name=${dev##*/}
        [[ $name == ib* ]] && continue

        rx_file=$dev/statistics/rx_bytes
        tx_file=$dev/statistics/tx_bytes
        [[ -f $rx_file ]] || continue

        read -r rx <"$rx_file"
        read -r tx <"$tx_file"
        RX_NOW[$name]=$rx
        TX_NOW[$name]=$tx

        if [[ -n ${RX_LAST[$name]:-} ]]; then
            printf "%-15s %15s %15s %10s\n" \
                "$name" \
                "$(speed $((rx - RX_LAST[$name])))" \
                "$(speed $((tx - TX_LAST[$name])))" \
                "NET"
        fi
    done

    # InfiniBand devices (counters are in 4-byte words)
    for dev in /sys/class/infiniband/mlx5_*; do
        name=${dev##*/}
        counter=$dev/ports/1/counters
        [[ -f $counter/port_xmit_data ]] || continue

        read -r tx <"$counter/port_xmit_data"
        read -r rx <"$counter/port_rcv_data"
        RX_NOW[$name]=$rx
        TX_NOW[$name]=$tx

        if [[ -n ${RX_LAST[$name]:-} ]]; then
            printf "%-15s %15s %15s %10s\n" \
                "$name" \
                "$(speed $(((rx - RX_LAST[$name]) * 4)))" \
                "$(speed $(((tx - TX_LAST[$name]) * 4)))" \
                "IB"
        fi
    done

    # snapshot for next frame
    RX_LAST=()
    TX_LAST=()
    for k in "${!RX_NOW[@]}"; do RX_LAST[$k]=${RX_NOW[$k]}; done
    for k in "${!TX_NOW[@]}"; do TX_LAST[$k]=${TX_NOW[$k]}; done

    # wait until the next boundary, compensating for this frame's runtime
    remain=$((tick - $(now_ns)))
    if ((remain > 0)); then
        sec=$((remain / 1000000000))
        ms=$(((remain % 1000000000) / 1000000))
        printf -v ms "%03d" "$ms"
        sleep "$sec.$ms"
    fi
    tick=$((tick + INTERVAL * 1000000000))
done
