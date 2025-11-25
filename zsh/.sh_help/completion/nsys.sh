#!/bin/bash
# -----------------------------------------------------------------------------
# Bash + Zsh 补全脚本: 为 nsys 提供命令行补全支持
# 作者: gogongxt
# 版本: 2.6
# -----------------------------------------------------------------------------

# ---------------- Bash 补全定义 ----------------
_nsys_completion_bash() {
    local cur prev words cword
    _get_comp_words_by_ref -n : cur prev words cword

    local nsys_commands="profile sessions start stop stats analyze launch report --help --version"
    local command="${words[1]}"

    if [ "$cword" -eq 1 ]; then
        COMPREPLY=($(compgen -W "${nsys_commands}" -- "${cur}"))
        return 0
    fi

    case "$command" in
    profile)
        local opts="--trace -t --output -o --stats --force-overwrite -f --delay -d --duration --kill --show-output --capture-range --capture-range-end --help"
        if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
        else
            _filedir -x
        fi
        ;;
    sessions)
        local subcmds="list export"
        if [ "$cword" -eq 2 ]; then
            COMPREPLY=($(compgen -W "${subcmds}" -- "${cur}"))
        fi
        ;;
    stats | analyze | report)
        _filedir -f
        ;;
    start)
        if [[ "$prev" == "--session" || "$prev" == "--session=" ]]; then
            local running_sessions
            running_sessions=$(nsys sessions list 2>/dev/null | awk '/^[[:space:]]*[0-9]/ { $1=$2=$3=$4=""; sub(/^[[:space:]]+/, ""); print }')
            if [[ -n "$running_sessions" ]]; then
                mapfile -t COMPREPLY < <(compgen -W "${running_sessions}" -- "$cur")
            fi
            return 0
        fi
        if [[ "$prev" == "--output" || "$prev" == "--output=" ]]; then
            _filedir
            return 0
        fi
        if [[ "--session" == "$cur"* ]]; then
            COMPREPLY=(--session)
        elif [[ "--output" == "$cur"* ]]; then
            COMPREPLY=(--output)
        fi
        ;;
    stop)
        if [[ "$prev" == "--session" || "$prev" == "--session=" ]]; then
            local running_sessions
            running_sessions=$(nsys sessions list 2>/dev/null | awk '/^[[:space:]]*[0-9]/ { $1=$2=$3=$4=""; sub(/^[[:space:]]+/, ""); print }')
            if [[ -n "$running_sessions" ]]; then
                mapfile -t COMPREPLY < <(compgen -W "${running_sessions}" -- "$cur")
            fi
            return 0
        fi
        if [[ "--session" == "$cur"* ]]; then
            COMPREPLY=(--session)
        fi
        ;;
    esac
}

# ---------------- Zsh 补全定义 ----------------
_nsys_completion_zsh() {
    local context state state_descr line
    typeset -A opt_args

    local -a subcommands
    subcommands=(
        'profile:Start profiling'
        'sessions:Session management'
        'start:Start profiling session'
        'stop:Stop profiling session'
        'stats:Generate stats from result'
        'analyze:Open report'
        'launch:Launch application'
        'report:Generate reports'
        '--help:Show help'
        '--version:Show version'
    )

    _arguments -C \
        '1:subcommand:->subcmd' \
        '*::arg:->args'

    case $state in
    subcmd)
        _describe 'nsys commands' subcommands
        ;;
    args)
        case $words[1] in
        profile)
            _arguments \
                '--trace=-t[Specify trace type]' \
                '--output=-o[Specify output file]' \
                '--stats[Enable statistics]' \
                '--force-overwrite=-f[Force overwrite]' \
                '--help[Show help]' \
                '*:filename:_files'
            ;;
        sessions)
            _values 'sessions command' list export
            ;;
        start)
            local -a sessions
            sessions=($(nsys sessions list 2>/dev/null | awk '/^[[:space:]]*[0-9]/ { $1=$2=$3=$4=""; sub(/^[[:space:]]+/, ""); print }'))
            _arguments \
                '--session[Specify session]:session name:(${sessions})' \
                '--output[Specify output file]:output file:_files'
            ;;
        stop)
            local -a sessions
            sessions=($(nsys sessions list 2>/dev/null | awk '/^[[:space:]]*[0-9]/ { $1=$2=$3=$4=""; sub(/^[[:space:]]+/, ""); print }'))
            _arguments \
                '--session[Specify session to stop]:session name:(${sessions})'
            ;;
        stats | analyze | report)
            _files
            ;;
        esac
        ;;
    esac
}

# ---------------- 自动注册补全 ----------------
if [[ -n ${ZSH_VERSION:+zsh} ]]; then
    # 注册 zsh 补全
    compdef _nsys_completion_zsh nsys
elif [[ -n ${BASH_VERSION:+bash} ]]; then
    # 确保 bash-completion 可用
    if type -t _command &>/dev/null; then
        complete -F _nsys_completion_bash nsys
    else
        echo "警告: bash-completion 未安装，nsys 补全不可用。" >&2
    fi
fi
