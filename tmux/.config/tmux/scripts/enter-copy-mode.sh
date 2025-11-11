#!/bin/bash
# 获取当前窗口的所有pane ID，并让它们都进入复制模式
tmux list-panes -F "#{pane_id}" | xargs -I{} tmux copy-mode -t {}
