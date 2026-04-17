#!/bin/bash
#
# macOS 通知脚本 - 支持 local 和 SSH 环境
#
# 用法:
#   notify.sh [options]
#
# 选项:
#   -title VALUE        通知标题 (默认: "Terminal")
#   -subtitle VALUE     通知副标题
#   -message VALUE      通知内容 (必需，除非使用 -remove 或 -list)
#   -sound NAME         声音名称 (如 "Glass", "default")，见 /System/Library/Sounds
#   -group ID           分组ID，同组通知会替换旧通知
#   -activate ID        点击时激活的应用 bundle identifier
#   -open URL           点击时打开的 URL
#   -execute COMMAND    点击时执行的 shell 命令
#   -sender ID          显示为发送者的应用 bundle identifier
#   -appIcon URL        自定义应用图标 URL
#   -contentImage URL   通知内容图片 URL
#   -ignoreDnD          忽略勿扰模式
#   -remove ID          移除指定分组的通知 (使用 "ALL" 移除所有)
#   -list ID            列出指定分组的通知 (使用 "ALL" 列出所有)
#   -timeout SECONDS    通知显示超时 (秒)
#   -port PORT          SSH 环境下的转发端口 (默认: 7770)
#   -json               输出 JSON 格式 (用于 -list)
#
# 示例:
#   # 基本通知
#   notify.sh -title "Build" -message "编译完成" -sound default
#
#   # 分组通知 (同组只保留最新)
#   notify.sh -group "myapp" -title "状态" -message "步骤1完成"
#
#   # 点击打开 URL
#   notify.sh -title "新消息" -message "点击查看" -open "https://github.com"
#
#   # 点击激活应用
#   notify.sh -title "提醒" -message "查看邮件" -activate "com.apple.Mail"
#
#   # 移除通知
#   notify.sh -remove "myapp"
#

# 默认值
NOTIFY_PORT="${NOTIFY_PORT:-7770}"

# 解析参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        -title)       NOTIFY_TITLE="$2"; shift 2 ;;
        -subtitle)    NOTIFY_SUBTITLE="$2"; shift 2 ;;
        -message)     NOTIFY_MESSAGE="$2"; shift 2 ;;
        -sound)       NOTIFY_SOUND="$2"; shift 2 ;;
        -group)       NOTIFY_GROUP="$2"; shift 2 ;;
        -activate)    NOTIFY_ACTIVATE="$2"; shift 2 ;;
        -open)        NOTIFY_OPEN="$2"; shift 2 ;;
        -execute)     NOTIFY_EXECUTE="$2"; shift 2 ;;
        -sender)      NOTIFY_SENDER="$2"; shift 2 ;;
        -appIcon)     NOTIFY_APPICON="$2"; shift 2 ;;
        -contentImage) NOTIFY_CONTENTIMAGE="$2"; shift 2 ;;
        -ignoreDnD)   NOTIFY_IGNOREDND=1; shift ;;
        -remove)      NOTIFY_REMOVE="$2"; shift 2 ;;
        -list)        NOTIFY_LIST="$2"; shift 2 ;;
        -timeout)     NOTIFY_TIMEOUT="$2"; shift 2 ;;
        -port)        NOTIFY_PORT="$2"; shift 2 ;;
        -json)        NOTIFY_JSON=1; shift ;;
        *)            shift ;;
    esac
done

# 发送通知
send_notification() {
    if [[ -n "$SSH_CONNECTION" ]]; then
        # SSH 环境：通过端口转发发送到本地
        # 导出变量供 Python 读取
        export NOTIFY_TITLE NOTIFY_SUBTITLE NOTIFY_MESSAGE NOTIFY_SOUND
        export NOTIFY_GROUP NOTIFY_ACTIVATE NOTIFY_OPEN NOTIFY_EXECUTE
        export NOTIFY_SENDER NOTIFY_APPICON NOTIFY_CONTENTIMAGE NOTIFY_IGNOREDND
        export NOTIFY_REMOVE NOTIFY_LIST

        # 使用 Python 构建和发送 JSON，避免 shell 转义问题
        python3 -c "
import socket
import json
import os

payload = {
    'title': os.environ.get('NOTIFY_TITLE', ''),
    'subtitle': os.environ.get('NOTIFY_SUBTITLE', ''),
    'message': os.environ.get('NOTIFY_MESSAGE', ''),
    'sound': os.environ.get('NOTIFY_SOUND', 'Glass'),
    'group': os.environ.get('NOTIFY_GROUP', ''),
    'activate': os.environ.get('NOTIFY_ACTIVATE', ''),
    'open': os.environ.get('NOTIFY_OPEN', ''),
    'execute': os.environ.get('NOTIFY_EXECUTE', ''),
    'sender': os.environ.get('NOTIFY_SENDER', ''),
    'appIcon': os.environ.get('NOTIFY_APPICON', ''),
    'contentImage': os.environ.get('NOTIFY_CONTENTIMAGE', ''),
    'ignoreDnD': os.environ.get('NOTIFY_IGNOREDND', '') == '1',
    'remove': os.environ.get('NOTIFY_REMOVE', ''),
    'list': os.environ.get('NOTIFY_LIST', ''),
}

# 清理空值
payload = {k: v for k, v in payload.items() if v}

try:
    s = socket.socket()
    s.connect(('localhost', ${NOTIFY_PORT}))
    s.send(('NOTIFY:' + json.dumps(payload)).encode('utf-8'))
    s.close()
except:
    pass
" &
    else
        # 本地环境：直接使用 terminal-notifier
        local cmd=(terminal-notifier)

        # 必需或操作参数
        [[ -n "$NOTIFY_REMOVE" ]] && cmd+=(-remove "$NOTIFY_REMOVE")
        [[ -n "$NOTIFY_LIST" ]] && cmd+=(-list "$NOTIFY_LIST")

        # 内容参数
        [[ -n "$NOTIFY_TITLE" ]] && cmd+=(-title "$NOTIFY_TITLE")
        [[ -n "$NOTIFY_SUBTITLE" ]] && cmd+=(-subtitle "$NOTIFY_SUBTITLE")
        [[ -n "$NOTIFY_MESSAGE" ]] && cmd+=(-message "$NOTIFY_MESSAGE")
        [[ -n "$NOTIFY_SOUND" ]] && cmd+=(-sound "$NOTIFY_SOUND")

        # 分组和交互参数
        [[ -n "$NOTIFY_GROUP" ]] && cmd+=(-group "$NOTIFY_GROUP")
        [[ -n "$NOTIFY_ACTIVATE" ]] && cmd+=(-activate "$NOTIFY_ACTIVATE")
        [[ -n "$NOTIFY_OPEN" ]] && cmd+=(-open "$NOTIFY_OPEN")
        [[ -n "$NOTIFY_EXECUTE" ]] && cmd+=(-execute "$NOTIFY_EXECUTE")

        # 高级参数
        [[ -n "$NOTIFY_SENDER" ]] && cmd+=(-sender "$NOTIFY_SENDER")
        [[ -n "$NOTIFY_APPICON" ]] && cmd+=(-appIcon "$NOTIFY_APPICON")
        [[ -n "$NOTIFY_CONTENTIMAGE" ]] && cmd+=(-contentImage "$NOTIFY_CONTENTIMAGE")
        [[ -n "$NOTIFY_IGNOREDND" ]] && cmd+=(-ignoreDnD)
        [[ -n "$NOTIFY_TIMEOUT" ]] && cmd+=(-timeout "$NOTIFY_TIMEOUT")

        if [[ -n "$NOTIFY_JSON" && -n "$NOTIFY_LIST" ]]; then
            # JSON 输出模式
            cmd+=(-json)
            "${cmd[@]}" 2>/dev/null || "${cmd[@]::${#cmd[@]}-1}"
        else
            "${cmd[@]}"
        fi
    fi
}

send_notification
