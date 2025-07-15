#!/bin/bash

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ $# -eq 0 ]; then
  python3 "$CUR_DIR/myssh_password.py"
else
  python3 "$CUR_DIR/myssh_plain_password.py" "$@"
fi
