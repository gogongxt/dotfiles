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

# Get initial terminal size
set rows [stty rows]
set cols [stty columns]

spawn ssh -p $port $ssh_user@$host

# Setup trap for window resize
trap {
    set rows [stty rows]
    set cols [stty columns]
    stty rows \$rows columns \$cols < \$spawn_out(slave,name)
} WINCH

expect {
    -exact "$username_prompt" {
        send -- "$username\r"
        exp_continue
    }
    -re "(?i)$password_prompt" {
        send -- "$password\r"
        exp_continue
    }
    "Are you sure you want to continue connecting (yes/no)?" {
        send -- "yes\r"
        exp_continue
    }
    -re {Last login:|[$#%>\\]]\s*$} {
        # Send initial resize in case window was resized during connection
        stty rows \$rows columns \$cols < \$spawn_out(slave,name)
        interact {
            # Keep handling window resizes during interaction
            WINCH {
                stty rows [stty rows] columns [stty columns] < \$spawn_out(slave,name)
            }
        }
        exit 0
    }
    "Permission denied" {
        puts stderr "Authentication failed: Permission denied"
        exit 1
    }
    timeout {
        puts stderr "Connection timed out"
        exit 1
    }
    eof {
        puts stderr "Connection closed or SSH command failed (EOF)"
        exit 1
    }
}
EOF
)

# Create a temporary expect script file
temp_expect_script="/tmp/ssh_connect.$$.exp"
echo "$expect_script" > "$temp_expect_script"
chmod +x "$temp_expect_script"

# Execute the expect script
"$temp_expect_script"

# Clean up the temporary script
rm "$temp_expect_script"
