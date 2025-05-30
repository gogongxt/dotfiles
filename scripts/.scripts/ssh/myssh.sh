#!/bin/bash

# Install required tools if needed
if ! command -v yq &> /dev/null; then
    echo "please install yq first"
    exit 1; 
fi

if ! command -v fzf &> /dev/null; then
    echo "please install fzf first"
    exit 1; 
fi

# Parse YAML and prepare FZF selection
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
CONFIG_FILE="$SCRIPT_DIR/servers.yaml"

selected=$(yq e '.servers[] | .name + " ➔ " + .ssh_user + "@" + .host + ":" + (.port|tostring)' "$CONFIG_FILE" | fzf --height 40% --prompt="Select server: " --no-preview)

if [ -z "$selected" ]; then
    echo "No server selected. Exiting."
    exit 0
fi

# Extract server name from selection
server_name=$(echo "$selected" | awk -F ' ➔ ' '{print $1}')

# Get server details from YAML
host=$(yq e ".servers[] | select(.name == \"$server_name\") | .host" "$CONFIG_FILE")
port=$(yq e ".servers[] | select(.name == \"$server_name\") | .port" "$CONFIG_FILE")
ssh_user=$(yq e ".servers[] | select(.name == \"$server_name\") | .ssh_user" "$CONFIG_FILE")
username=$(yq e ".servers[] | select(.name == \"$server_name\") | .auth.username" "$CONFIG_FILE")
password=$(yq e ".servers[] | select(.name == \"$server_name\") | .auth.password" "$CONFIG_FILE")
username_prompt=$(yq e ".servers[] | select(.name == \"$server_name\") | .auth.username_prompt" "$CONFIG_FILE")
password_prompt=$(yq e ".servers[] | select(.name == \"$server_name\") | .auth.password_prompt" "$CONFIG_FILE")

# Generate and execute Expect script
expect_script=$(cat <<EOF
#!/usr/bin/expect -f
set timeout 20
spawn ssh -p $port $ssh_user@$host

expect {
    -exact "$username_prompt" {
        send -- "$username\r"
        exp_continue
    }
    -re "(?i)$password_prompt" {
        send -- "$password\r"
    }
    "Are you sure you want to continue connecting (yes/no)?" {
        send -- "yes\r"
        exp_continue
    }
    "Last login:" {
        interact
        exit 0
    }
    "Permission denied" {
        puts "Authentication failed"
        exit 1
    }
    timeout {
        puts "Connection timed out"
        exit 1
    }
    eof {
        puts "Connection closed"
        exit 1
    }
}
interact
EOF
)

echo "$expect_script" > /tmp/ssh_connect.exp
chmod +x /tmp/ssh_connect.exp
/tmp/ssh_connect.exp
rm /tmp/ssh_connect.exp
