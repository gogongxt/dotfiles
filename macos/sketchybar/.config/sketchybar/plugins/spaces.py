#!/usr/bin/env python3

import subprocess
import json
import os
import sys
from space_display import update_space_display


def main():
    # 尝试从环境变量获取参数，如果通过信号传递
    # yabai_space_id = os.getenv("YABAI_SPACE_ID")
    yabai_space_index = os.getenv("YABAI_SPACE_INDEX")
    # yabai_recent_space_id = os.getenv("YABAI_RECENT_SPACE_ID")
    yabai_recent_space_index = os.getenv("YABAI_RECENT_SPACE_INDEX")

    print("="*10)
    if yabai_space_index and yabai_recent_space_index:
        # Update display for space 2, selected
        update_space_display(space_id=yabai_space_index, selected=True)
        update_space_display(space_id=yabai_recent_space_index, selected=False)
    else:
        update_space_display()


if __name__ == "__main__":
    main()
