#!/usr/bin/env python3

import os
from datetime import datetime

def main():
    # 获取当前时间
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # 尝试从环境变量获取参数，如果通过信号传递
    yabai_space_id = os.getenv('YABAI_SPACE_ID')
    yabai_space_index = os.getenv('YABAI_SPACE_INDEX')
    yabai_recent_space_id = os.getenv('YABAI_RECENT_SPACE_ID')
    yabai_recent_space_index = os.getenv('YABAI_RECENT_SPACE_INDEX')
    
    # 打印结果
    print(f"[{now}] Space changed event received:")
    print(f"Current Space ID: {yabai_space_id}")
    print(f"Current Space Index: {yabai_space_index}")
    print(f"Previous Space ID: {yabai_recent_space_id}")
    print(f"Previous Space Index: {yabai_recent_space_index}")
    print("-" * 40)

if __name__ == "__main__":
    main()
