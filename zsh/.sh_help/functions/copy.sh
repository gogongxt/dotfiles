#!/bin/bash
#
# Unified clipboard functions for local (macOS, Linux) and remote (SSH/OSC52) sessions.
#
# Usage:
#   - Copy a file's content:
#       copy /path/to/my_file.txt
#
#   - Copy from standard input (pipe):
#       echo "Some text" | copy
#       cat report.log | copy
#
#   - Paste from the clipboard:
#       paste > new_file.txt
#       my_variable=$(paste)

# Merged and improved 'copy' function
# Combines file/pipe input with intelligent environment detection.
copy() {
    local content
    local input_source

    # 1. Determine the source of the content (file argument or standard input)
    if [[ -n "$1" ]]; then
        if [[ ! -f "$1" ]]; then
            echo "Error: File '$1' not found." >&2
            return 1
        fi
        input_source="$1"
    else
        # If no argument, read from standard input.
        # This works for pipes: echo "hello" | copy
        input_source="/dev/stdin"
    fi

    # Read the content into a variable
    # Using cat is a robust way to handle both files and stdin.
    content=$(cat "$input_source")
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to read content from '$input_source'." >&2
        return 1
    fi

    # 2. Choose the best copy method based on the environment
    # If in an SSH session, always use OSC52 for remote clipboard access.
    if [[ -n "$SSH_CONNECTION" || -n "$SSH_CLIENT" ]]; then
        printf '\033]52;c;%s\a' "$(echo -n "$content" | base64 -w 0)"
        return 0
    fi

    # If local, try native clipboard tools first.
    if command -v pbcopy &>/dev/null; then # macOS
        echo -n "$content" | pbcopy
    elif command -v wl-copy &>/dev/null; then # Wayland
        echo -n "$content" | wl-copy
    elif command -v xclip &>/dev/null; then # Linux/X11
        echo -n "$content" | xclip -selection clipboard
    elif command -v xsel &>/dev/null; then # Linux/X11 (alternative)
        echo -n "$content" | xsel --clipboard --input
    else
        # Fallback to OSC52 if no local tools are found.
        # This is useful for modern terminals that support it locally.
        printf '\033]52;c;%s\a' "$(echo -n "$content" | base64 -w 0)"
    fi
}

get_from_clipboard() {
    # Pasting from the host machine's clipboard in a remote SSH session is
    # a feature of the *terminal emulator* (e.g., iTerm2, Kitty, WezTerm),
    # not something the remote shell can initiate. OSC52 does not have a "get" command.
    # Therefore, this function only works for the local system's clipboard.
    if command -v pbpaste &>/dev/null; then # macOS
        pbpaste
    elif command -v wl-paste &>/dev/null; then # Wayland
        wl-paste --no-newline
    elif command -v xclip &>/dev/null; then # Linux/X11
        xclip -o -selection clipboard
    elif command -v xsel &>/dev/null; then # Linux/X11 (alternative)
        xsel --clipboard --output
    else
        echo "Error: No clipboard tool found." >&2
        echo "Please install pbpaste (macOS), wl-paste (Wayland), or xclip/xsel (X11)." >&2
        return 1
    fi
}
