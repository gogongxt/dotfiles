#🔽🔽🔽
# proxychains / proxyhains4
hash proxychains4 2>/dev/null && { alias pro='proxychains4'; }
hash proxychains 2>/dev/null && { alias pro='proxychains'; }
#🔼🔼🔼

: ${PROXY_DEFAULT:=127.0.0.1:7890}

#🔽🔽🔽
# set proxy
# reference https://wiki.archlinux.org/title/Proxy_server
function proxy_on() {
    local proxy="${PROXY:-$PROXY_DEFAULT}"
    if (($# > 0)); then
        # get "ip:port" format
        valid=$(echo $@ | sed -E 's/([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}):([0-9]+)/\1:\2/')
        if [[ $valid != $@ ]]; then
            >&2 echo "Invalid address"
            return 1
        fi
        proxy=$1
    fi
    export http_proxy=$proxy \
        https_proxy=$proxy \
        HTTP_PROXY=$proxy \
        HTTPS_PROXY=$proxy \
        ftp_proxy=$proxy \
        FTP_PROXY=$proxy \
        rsync_proxy=$proxy \
        RSYNC_PROXY=$proxy
    echo -e "Proxy environment variable seted."
    echo "Note that sudo will not use proxy"
    echo "proxy=$proxy"
}
function proxy_off() {
    unset http_proxy https_proxy ftp_proxy rsync_proxy \
        HTTP_PROXY HTTPS_PROXY FTP_PROXY RSYNC_PROXY
    echo -e "Proxy environment variable removed."
}
function proxy_status() {
    if [ -z ${http_proxy+x} ] && [ -z ${https_proxy+x} ]; then
        echo -e "No Proxy environment."
    else
        echo -e "Have Proxy environment."
    fi
    echo -e "http_proxy: ${http_proxy}"
    echo -e "HTTP_PROXY: ${HTTP_PROXY}"
    echo -e "https_proxy: ${https_proxy}"
    echo -e "HTTPS_PROXY: ${HTTPS_PROXY}"
    echo -e "ftp_proxy: ${ftp_proxy}"
    echo -e "FTP_PROXY: ${FTP_PROXY}"
    echo -e "rsync_proxy: ${rsync_proxy}"
    echo -e "RSYNC_PROXY: ${RSYNC_PROXY}"
}
proxy() {
    case "$1" in
        on)
            shift
            echo "========================================"
            proxy_on "$@"
            echo "========================================"
            proxy_status
            ;;
        off)
            shift
            echo "========================================"
            proxy_off
            echo "========================================"
            proxy_status
            ;;
        toggle)
            shift
            echo "========================================"
            if [ -z ${http_proxy+x} ] && [ -z ${https_proxy+x} ]; then
                echo "Currently no proxy, turning proxy on..."
                proxy_on "$@"
            else
                echo "Currently proxy is on, turning proxy off..."
                proxy_off
            fi
            echo "========================================"
            proxy_status
            ;;
        status)
            shift
            proxy_status
            ;;
        *)
            echo "Error: unknown command proxy $1"
            ;;
    esac
}
alias pt="proxy toggle"
#🔼🔼🔼

# pip install package use http proxy rather than other source
pip_proxy() {
    local proxy="${PROXY:-$PROXY_DEFAULT}"
    http_proxy="$proxy" https_proxy="$proxy" PIP_INDEX_URL="https://pypi.org/simple" pip "$@"
}
pip_proxy_10099() {
    PROXY=10.77.22.11:10099 pip_proxy "$@"
}
alias pip_tsinghua="http_proxy= https_proxy= PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple pip"
alias pip_aliyun="http_proxy= https_proxy= PIP_INDEX_URL=https://mirrors.aliyun.com/pypi/simple pip"
alias pip_tencent="http_proxy= https_proxy= PIP_INDEX_URL=https://mirrors.cloud.tencent.com/pypi/simple pip"
