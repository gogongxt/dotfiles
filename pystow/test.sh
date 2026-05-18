#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "==> Running pystow tests"
python -m pytest test_main.py -v "$@"
