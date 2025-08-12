#!/bin/bash

# This script automates the installation of a PyTorch tensor string presentation fix for VS Code's debugger

# Determine the correct extensions folder based on local or remote (SSH)
if [ -d "$HOME/.vscode-server" ]; then
	EXTENSIONS_DIR="$HOME/.vscode-server/extensions"
	echo "Detected remote (SSH) VS Code installation"
else
	EXTENSIONS_DIR="$HOME/.vscode/extensions"
	echo "Detected local VS Code installation"
fi

# Find the debugpy extension directory
DEBUGPY_DIR=$(find "$EXTENSIONS_DIR" -maxdepth 1 -type d -name "ms-python.debugpy-*" | head -n 1)

if [ -z "$DEBUGPY_DIR" ]; then
	echo "Error: Could not find debugpy extension directory in $EXTENSIONS_DIR"
	exit 1
fi

echo "Found debugpy directory: $DEBUGPY_DIR"

# Target directory for the plugin
TARGET_DIR="$DEBUGPY_DIR/bundled/libs/debugpy/_vendored/pydevd/pydevd_plugins/extensions/types"

# Create the target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Create the plugin file
PLUGIN_FILE="$TARGET_DIR/pydevd_plugin_pytorch_tensor_str.py"

cat >"$PLUGIN_FILE" <<'EOF'
"""
gogongxt:
ref:
- https://github.com/microsoft/debugpy/issues/1525#issuecomment-2316653751
- https://www.zhihu.com/question/560178647
"""

from _pydevd_bundle.pydevd_extension_api import StrPresentationProvider
from .pydevd_helpers import find_mod_attr

class SizedShapeStr:
    """Displays the size of a Sized object before displaying its value."""

    def can_provide(self, type_object, type_name):
        sized_obj = find_mod_attr("collections.abc", "Sized")
        return sized_obj is not None and issubclass(type_object, sized_obj)

    def get_str(self, val):
        if hasattr(val, "shape"):
            return f"shape: {val.shape}, value: {val}"
        return f"len: {len(val)}, value: {val}"

import sys

if not sys.platform.startswith("java"):
    StrPresentationProvider.register(SizedShapeStr)
EOF

echo "Successfully created plugin file at: $PLUGIN_FILE"
echo "You may need to restart VS Code for changes to take effect"
