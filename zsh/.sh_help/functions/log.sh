mylog() {
	if [[ $# -eq 0 ]]; then
		echo "Usage: mylog <command> [args...]" >&2
		return 1
	fi
	local log_dir="${HOME}/logs"
	mkdir -p "$log_dir"
	ms=$(printf '%03d' "$(($(date +%s%N) / 1000000 % 1000))")
	local logfile="${log_dir}/$(date +%Y%m%d_%H%M%S)_${ms}_${1##*/}.log"
	# ------------------------
	{
		echo "=== Command Logger ==="
		echo "Time: $(date '+%Y-%m-%d %H:%M:%S').${ms}"
		echo "Command: $@"
		echo "Directory: $(pwd)"
		echo "User: $(whoami)"
		echo "Log saved: $logfile"
		echo "================================"
		time "$@" 2>&1
		echo "================================"
		echo "Exit code: $?"
	} | tee "$logfile"
	echo "Log saved: $logfile"
}
