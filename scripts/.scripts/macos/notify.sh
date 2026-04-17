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

# 构建通知参数
build_notifier_args() {
    local args=()

    # 必需或操作参数
    [[ -n "$NOTIFY_REMOVE" ]] && args+=(-remove "$NOTIFY_REMOVE")
    [[ -n "$NOTIFY_LIST" ]] && args+=(-list "$NOTIFY_LIST")

    # 内容参数
    [[ -n "$NOTIFY_TITLE" ]] && args+=(-title "$NOTIFY_TITLE")
    [[ -n "$NOTIFY_SUBTITLE" ]] && args+=(-subtitle "$NOTIFY_SUBTITLE")
    [[ -n "$NOTIFY_MESSAGE" ]] && args+=(-message "$NOTIFY_MESSAGE")
    [[ -n "$NOTIFY_SOUND" ]] && args+=(-sound "$NOTIFY_SOUND")

    # 分组和交互参数
    [[ -n "$NOTIFY_GROUP" ]] && args+=(-group "$NOTIFY_GROUP")
    [[ -n "$NOTIFY_ACTIVATE" ]] && args+=(-activate "$NOTIFY_ACTIVATE")
    [[ -n "$NOTIFY_OPEN" ]] && args+=(-open "$NOTIFY_OPEN")
    [[ -n "$NOTIFY_EXECUTE" ]] && args+=(-execute "$NOTIFY_EXECUTE")

    # 高级参数
    [[ -n "$NOTIFY_SENDER" ]] && args+=(-sender "$NOTIFY_SENDER")
    [[ -n "$NOTIFY_APPICON" ]] && args+=(-appIcon "$NOTIFY_APPICON")
    [[ -n "$NOTIFY_CONTENTIMAGE" ]] && args+=(-contentImage "$NOTIFY_CONTENTIMAGE")
    [[ -n "$NOTIFY_IGNOREDND" ]] && args+=(-ignoreDnD)
    [[ -n "$NOTIFY_TIMEOUT" ]] && args+=(-timeout "$NOTIFY_TIMEOUT")

    echo "${args[@]}"
}

# 发送通知
send_notification() {
    if [[ -n "$SSH_CONNECTION" ]]; then
        # SSH 环境：通过端口转发发送到本地
        local payload
        payload=$(cat <<EOF
{
    "title": "${NOTIFY_TITLE}",
    "subtitle": "${NOTIFY_SUBTITLE}",
    "message": "${NOTIFY_MESSAGE}",
    "sound": "${NOTIFY_SOUND}",
    "group": "${NOTIFY_GROUP}",
    "activate": "${NOTIFY_ACTIVATE}",
    "open": "${NOTIFY_OPEN}",
    "execute": "${NOTIFY_EXECUTE}",
    "sender": "${NOTIFY_SENDER}",
    "appIcon": "${NOTIFY_APPICON}",
    "contentImage": "${NOTIFY_CONTENTIMAGE}",
    "ignoreDnD": ${NOTIFY_IGNOREDND:-false},
    "remove": "${NOTIFY_REMOVE}",
    "list": "${NOTIFY_LIST}",
    "timeout": ${NOTIFY_TIMEOUT:-null}
}
EOF
)
        # 压缩 JSON (移除换行和多余空格)
        payload=$(echo "$payload" | tr '\n' ' ' | sed 's/  */ /g')

        # 使用 python3 发送
        python3 -c "
import socket
import sys
s = socket.socket()
try:
    s.connect(('localhost', ${NOTIFY_PORT}))
    s.send('NOTIFY:${payload}'.encode('utf-8'))
    s.close()
except:
    pass
" &
    else
        # 本地环境：直接使用 terminal-notifier
        local args
        args=$(build_notifier_args)

        if [[ -n "$NOTIFY_JSON" && -n "$NOTIFY_LIST" ]]; then
            # JSON 输出模式
            terminal-notifier $args -json 2>/dev/null || terminal-notifier $args
        else
            terminal-notifier $args
        fi
    fi
}

send_notification
