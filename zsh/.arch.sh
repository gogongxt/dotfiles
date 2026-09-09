macos() {
    export TMUX_SHOW_STATUS_RIGHT="true"
    export HOMEBREW_NO_AUTO_UPDATE=1 # disable brew autoupdate when install package
    export PATH="/opt/homebrew/bin:$PATH"
    alias updatedb="/usr/libexec/locate.update"
    alias docker_start="open /Applications/Docker.app"

    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8

    # header search file path
    export C_INCLUDE_PATH=${C_INCLUDE_PATH}:/opt/homebrew/include/
    export CPLUS_INCLUDE_PATH=${CPLUS_INCLUDE_PATH}:/opt/homebrew/include/
    # set cmake header path
    export CMAKE_INCLUDE_PATH=${CMAKE_INCLUDE_PATH}:/opt/homebrew/include/
    # compiling lib search file path
    export LIBRARY_PATH=${LIBRARY_PATH}:/opt/homebrew/lib/
    # running lib search file path
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/homebrew/lib/

    # add llvm lib
    export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
    export LDFLAGS=" -L/opt/homebrew/opt/Llvm/lib"
    export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"

    # change c/cxx compile
    export CC="/opt/homebrew/opt/llvm/bin/clang"
    export CXX="/opt/homebrew/opt/llvm/bin/clang++"

    # add openmp lib
    # export LDFLAGS=" -L/opt/homebrew/opt/libomp/lib"
    # export CPPFLAGS="-I/opt/homebrew/opt/libomp/include"}

    # alias gcc="/opt/homebrew/bin/aarch64-apple-darwin23-gcc-14"
    # alias g++="/opt/homebrew/bin/aarch64-apple-darwin23-g++-14"
    # alias clang="/opt/homebrew/bin/aarch64-apple-darwin23-gcc-14"
    # alias clang++="/opt/homebrew/bin/aarch64-apple-darwin23-g++-14"
    # alias gcc="/opt/homebrew/opt/llvm/bin/clang"
    # alias g++="/opt/homebrew/opt/llvm/bin/clang++"
    # alias clang="/opt/homebrew/opt/llvm/bin/clang"
    # alias clang++="/opt/homebrew/opt/llvm/bin/clang++"
    # alias ld="/opt/homebrew/bin/"

    # support trash-cli trash-put
    export PATH="/opt/homebrew/opt/trash-cli/bin:$PATH"

    if [ -f ~/.venv/base/bin/activate ]; then
        source ~/.venv/base/bin/activate
    fi

    # fixaudio: 修复 macOS CoreAudio 卡死（蓝牙耳机切换/腾讯会议等触发 coreaudiod 挂起，
    # 表现为 system_profiler SPAudioDataType 卡死、无声、声音卡顿），无需重启系统
    # 用法:
    #   fixaudio          重启 coreaudiod（解决绝大多数卡死）
    #   fixaudio full     连同其他音频守护进程和占用音频的 App 一起重启（声音异常/杂音时用，
    #                     会关闭浏览器、播放器等所有占用音频的进程）
    #   fixaudio status   查看 coreaudiod 状态并测试音频系统是否响应
    #🔽🔽🔽
    fixaudio_status() {
        local pid
        pid=$(pgrep -x coreaudiod | head -1)
        if [ -z "$pid" ]; then
            echo "❌ coreaudiod not running"
            return 1
        fi
        echo "coreaudiod: $(ps -p "$pid" -o state=,pcpu=,etime= | head -1)"
        # 挂起时 system_profiler 会一直阻塞，必须带 -timeout
        if system_profiler -timeout 5 SPAudioDataType >/dev/null 2>&1; then
            echo "✅ audio OK"
        else
            echo "⚠️ audio query hanging, run: fixaudio"
            return 1
        fi
    }
    fixaudio() {
        case "$1" in
            status)
                fixaudio_status
                ;;
            full)
                echo ">>> restarting coreaudiod + all audio daemons ..."
                sudo killall -9 coreaudiod 2>/dev/null
                sudo killall -9 audiomxd audioclocksyncd audioanalyticsd audioaccessoryd AudioComponentRegistrar 2>/dev/null
                echo ">>> killing CoreAudio client processes ..."
                local protect='coreaudiod|audiomxd|audioclocksyncd|audioanalyticsd|audioaccessoryd|AudioComponentRegistrar|ParrotAudioPlugin|DriverHelper|SandboxHelper|WindowServer|loginwindow|Terminal|iTerm2|zsh|sshd'
                lsof 2>/dev/null | awk '/CoreAudio/ {print $1, $2}' | sort -u | grep -viE "$protect" | while read name pid; do
                    kill -9 "$pid" 2>/dev/null && echo "    killed $name ($pid)"
                done
                sleep 2
                fixaudio_status
                ;;
            "" | restart)
                echo ">>> restarting coreaudiod ..."
                sudo killall -9 coreaudiod 2>/dev/null
                sleep 2
                fixaudio_status
                ;;
            *)
                echo "Usage: fixaudio [restart|full|status]"
                ;;
        esac
    }
    #🔼🔼🔼
}

archlinux() {
    #🔽🔽🔽
    # Autostart X at login
    # Ref : https://wiki.archlinux.org/title/Xinit#Autostart_X_at_login
    if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
        exec startx
    fi
    #🔼🔼🔼

    # soft ware
    #🔽🔽🔽
    alias clion='nohup /opt/clion/clion-2023.2.1/bin/clion.sh&>/dev/null'
    #🔼🔼🔼
}

ubuntu() {

    # add nvm (npm and nodejs)
    # export NVM_DIR="$HOME/.nvm"
    # [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    # [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

    #🔽🔽🔽
    # nvm lazy load
    # pre load install binary
    if [ -z "$NVM_DIR" ]; then
        export NVM_DIR="$HOME/.nvm"
    fi
    if [ -d "$NVM_DIR" ]; then
        LATEST_NODE_PATH=$(ls -dv "$NVM_DIR"/versions/node/* 2>/dev/null | sort -V | tail -n1)
        if [ -n "$LATEST_NODE_PATH" ]; then
            export PATH="$LATEST_NODE_PATH/bin:$PATH"
        fi
        unset LATEST_NODE_PATH
        # Ref: https://github.com/nvm-sh/nvm/issues/2724#issuecomment-1336537635
        lazy_load_nvm() {
            unset -f npm node nvm
            [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
            [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
        }
        npm() {
            lazy_load_nvm
            npm $@
        }
        node() {
            lazy_load_nvm
            node $@
        }
        nvm() {
            lazy_load_nvm
            nvm $@
        }
    fi
    #🔼🔼🔼

}

if [ -f "/etc/os-release" ]; then
    # Detect whether current is Archlinux
    if [ "$(grep -E '^ID=' /etc/os-release | cut -d'=' -f2)" = "arch" ]; then
        archlinux
    fi
    # Detect whether current is Ubuntu
    if [ "$(grep -E '^ID=' /etc/os-release | cut -d'=' -f2)" = "ubuntu" ]; then
        ubuntu
    fi
fi

# Detect whether current is macos
if [ "$(uname)" = "Darwin" ]; then
    macos
fi

unfunction macos
unfunction ubuntu
unfunction archlinux
