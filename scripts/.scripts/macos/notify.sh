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
#   -port PORT          SSH 环境下的转发端口 (默认: 7770)
#
# SSH 模式认证:
#   将本机 ssh_listen.py 的 token 复制到远程 ~/.ssh_listen_token
#   (或通过 RCE_TOKEN 环境变量指定), 缺失时报错退出
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
RCE_PORT="${RCE_PORT:-7770}"

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
        -port)        RCE_PORT="$2"; shift 2 ;;
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

        # 构建命令并发送到本地执行
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

        # 读取 token: 优先 RCE_TOKEN 环境变量, 其次 ~/.ssh_listen_token 文件
        local token="${RCE_TOKEN:-}"
        if [[ -z "$token" && -f "$HOME/.ssh_listen_token" ]]; then
            token="$(<"$HOME/.ssh_listen_token")"
        fi
        if [[ -z "$token" ]]; then
            echo "notify.sh: 缺少 token (RCE_TOKEN 或 ~/.ssh_listen_token), 无法发送" >&2
            return 1
        fi

        # 走本机 ssh_listen.py 的 HTTP /exec 接口, 参数经 argv 传入,
        # 由 shlex.join 负责转义 (需 python3 >= 3.8)
        python3 -c '
import json, shlex, sys, urllib.request

token = sys.argv[1].strip()
port = sys.argv[2]
args = sys.argv[3:]
req = urllib.request.Request(
    "http://localhost:%s/exec" % port,
    data=json.dumps({"cmd": shlex.join(args)}).encode(),
    headers={"Authorization": "Bearer " + token},
)
# 强制直连: 绕过 http_proxy 等代理环境变量, 否则 localhost 请求会被
# 代理接管, "localhost" 在代理链另一端不再指本机 (表现为 502)
opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
try:
    resp = opener.open(req, timeout=15)
    result = json.loads(resp.read().decode())
    if result.get("rc", 1) != 0:
        print("notify.sh: 远端执行失败: %s" % result, file=sys.stderr)
        sys.exit(1)
except Exception as e:
    print("notify.sh: 发送失败: %s" % e, file=sys.stderr)
    sys.exit(1)
' "$token" "${RCE_PORT:-7770}" "${cmd[@]}"
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

        "${cmd[@]}"
    fi
}

send_notification
