#!/usr/bin/env bash

# Reference:
#   https://code.claude.com/docs/en/statusline
#   https://code.claude.com/docs/en/settings
#
# ── Statusline JSON fields wired into this script ────────────────────
# Documented at https://code.claude.com/docs/en/statusline#available-data
#
# Used on line 1:
#   model.display_name                      current model
#   context_window.used_percentage          pre-calculated, INPUT-ONLY
#                                           (input + cache_creation + cache_read;
#                                           output_tokens is excluded)
#   context_window.total_input_tokens       same input-only total, authoritative
#   context_window.context_window_size      max window (200k default, 1M extended)
#   rate_limits.five_hour.used_percentage   0-100 rolling 5h quota
#   rate_limits.five_hour.resets_at         Unix epoch seconds
#   rate_limits.seven_day.*                 same pair for the 7d window
#   rate_limits.spend_limit.*               Claude apps gateway only; >100% possible
#   workspace.current_dir                   via $current_dir, git fallback
#   workspace.git_worktree                  worktree name for ANY linked worktree
#                                           (worktree.* only exists in a worktree
#                                           SESSION, so this is the broader field)
#
# Used on line 2:
#   session_id                              stable per session; rendered as its
#                                           first 8 chars so a session maps to its
#                                           SpecStory transcript (header comment
#                                           reads "<!-- Claude Code Session <uuid> -->")
#   effort.level                            low|medium|high|xhigh|max
#   thinking.enabled                        extended thinking on/off
#   fast_mode                               fast mode on/off
#   vim.mode                                NORMAL|INSERT|VISUAL|VISUAL LINE
#                                           (set hideVimModeIndicator:true to
#                                           drop the built-in "-- INSERT --")
#   output_style.name                       non-default output styles only
#   pr.number / pr.review_state             approved|pending|changes_requested
#                                           |draft; pr.kind=="mr" for GitLab
#   worktree.name / worktree.branch         worktree session only
#   cost.total_lines_added/_removed         session diffstat
#   cost.total_duration_ms                  wall clock, survives --resume
#   cost.total_api_duration_ms              time waiting on the API
#   prompt_cache.warm / .hit_ratio          cache state; last_miss_cause.causes
#                                           names the reason (tools_changed,
#                                           idle, system_changed, ...)
#   version                                 Claude Code version
#
# Deliberately not rendered (parsed nowhere, kept for reference):
#   cost.total_cost_usd                     cost display is disabled below
#   exceeds_200k_tokens                     fixed 200k threshold, ignores the
#                                           real window size — misleading on 1M
#   workspace.repo.*                        origin remote host/owner/name
#   workspace.added_dirs                    /add-dir list
#   prompt_id, thinking.* (beyond .enabled), prompt_cache.* (beyond the three
#   above), pr.url, cost.total_api_duration_ms in the bar
#
# ────────────────────────────────────────────────────────────────────

# Ensure jq is available
if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found" >&2
    exit 1
fi
# Colors
readonly RST='\033[0m'
readonly C_MODEL='\033[38;2;255;184;108m'
readonly C_CTX_OK='\033[38;2;80;250;123m'
readonly C_CTX_WARN='\033[38;2;241;250;140m'
readonly C_CTX_LOW='\033[38;2;255;85;85m'
readonly C_BAR_EMPTY='\033[38;2;68;71;90m'
readonly C_SESSION_ID='\033[38;2;139;233;253m'
readonly C_GIT='\033[38;2;255;184;108m'
readonly C_API='\033[38;2;189;147;249m'
readonly C_GIT_DIRTY='\033[38;2;241;250;140m'
readonly C_VIM='\033[38;2;241;250;140m'
readonly C_WORKTREE='\033[38;2;255;121;198m'
readonly C_STYLE='\033[38;2;189;147;249m'
readonly C_EFFORT_HIGH='\033[38;2;255;85;85m'
readonly C_EFFORT_MED='\033[38;2;241;250;140m'
readonly C_EFFORT_LOW='\033[38;2;80;250;123m'
readonly C_EFFORT_OFF='\033[2;38;2;98;114;164m'
readonly C_LINES_ADD='\033[38;2;80;250;123m'
readonly C_LINES_DEL='\033[38;2;255;85;85m'
readonly C_VERSION='\033[2;38;2;98;114;164m'
readonly C_SEP='\033[38;2;98;114;164m'
# Added for the fields wired in above
readonly C_RATE='\033[38;2;189;147;249m'
readonly C_RATE_WARN='\033[38;2;241;250;140m'
readonly C_RATE_LOW='\033[38;2;255;85;85m'
readonly C_THINK='\033[38;2;189;147;249m'
readonly C_FAST='\033[38;2;255;184;108m'
readonly C_PR='\033[38;2;80;250;123m'
readonly C_PR_WARN='\033[38;2;241;250;140m'
readonly C_PR_LOW='\033[38;2;255;85;85m'
readonly C_CACHE_OK='\033[38;2;80;250;123m'
readonly C_CACHE_WARN='\033[38;2;241;250;140m'
readonly C_TIME='\033[2;38;2;98;114;164m'

readonly SEP=" | "

# Read JSON from stdin
input=$(cat)

# One jq pass for every scalar we need. The previous version shelled out to jq
# 15 times per invocation, and this script runs on every redraw.
#
# Each field is emitted as "key<TAB>value" and read back into an associative
# array, so nothing depends on positional order. Add a row to READ consistently
# below and the two cannot drift apart; reordering is free.
#
# Note `| tostring` rather than `// "":` jq's alternative operator treats false
# as empty, so (.prompt_cache.warm // "") would silently drop a false value.
declare -A READ
while IFS=$'\t' read -r _k _v; do
    [ -n "$_k" ] && READ[$_k]=$_v
done < <(printf '%s' "$input" | jq -r '
  def emit($k; v): "\($k)\t\(v | tostring | gsub("\n"; " "))";
  emit("model";          .model.display_name // ""),
  emit("used_pct";       .context_window.used_percentage // ""),
  emit("total_tokens";   .context_window.context_window_size // ""),
  emit("session_id";     .session_id // "default"),
  emit("lines_added";    .cost.total_lines_added // 0),
  emit("lines_removed";  .cost.total_lines_removed // 0),
  emit("duration_ms";    .cost.total_duration_ms // 0),
  emit("thinking";       .thinking.enabled),
  emit("fast_mode";      .fast_mode),
  emit("effort";         .effort.level // ""),
  emit("output_style";   .output_style.name // ""),
  emit("current_dir";    .workspace.current_dir // ""),
  emit("worktree_name";  .worktree.name // ""),
  emit("worktree_branch"; .worktree.branch // ""),
  emit("git_worktree";   .workspace.git_worktree // ""),
  emit("vim_mode";       .vim.mode // ""),
  emit("pr_number";      .pr.number // ""),
  emit("pr_state";       .pr.review_state // ""),
  emit("cc_version";     .version // ""),
  emit("cache_warm";     .prompt_cache.warm),
  emit("cache_hit";      .prompt_cache.hit_ratio // ""),
  emit("cache_miss";     (.prompt_cache.last_miss_cause.causes // []) | join(",")),
  emit("rl5_pct";        .rate_limits.five_hour.used_percentage // ""),
  emit("rl5_reset";      .rate_limits.five_hour.resets_at // ""),
  emit("rl7_pct";        .rate_limits.seven_day.used_percentage // ""),
  emit("rl7_reset";      .rate_limits.seven_day.resets_at // ""),
  emit("used_tokens";    .context_window.total_input_tokens // "")
' 2>/dev/null)
# ^^ jq's stderr is dropped: malformed or truncated stdin should degrade to a
# blank status line rather than print a parse error into the bar.

model=${READ[model]:-}
used_pct=${READ[used_pct]:-}
total_tokens=${READ[total_tokens]:-}
session_id=${READ[session_id]:-default}
lines_added=${READ[lines_added]:-0}
lines_removed=${READ[lines_removed]:-0}
duration_ms=${READ[duration_ms]:-0}
thinking=${READ[thinking]:-}
fast_mode=${READ[fast_mode]:-}
effort=${READ[effort]:-}
output_style=${READ[output_style]:-}
current_dir=${READ[current_dir]:-}
worktree_name=${READ[worktree_name]:-}
worktree_branch=${READ[worktree_branch]:-}
git_worktree=${READ[git_worktree]:-}
vim_mode=${READ[vim_mode]:-}
pr_number=${READ[pr_number]:-}
pr_state=${READ[pr_state]:-}
cc_version=${READ[cc_version]:-}
cache_warm=${READ[cache_warm]:-}
cache_hit=${READ[cache_hit]:-}
cache_miss=${READ[cache_miss]:-}
rl5_pct=${READ[rl5_pct]:-}
rl5_reset=${READ[rl5_reset]:-}
rl7_pct=${READ[rl7_pct]:-}
rl7_reset=${READ[rl7_reset]:-}
used_tokens=${READ[used_tokens]:-}

# workspace.git_worktree covers every linked worktree, so it can fill in the
# name before the git-CLI fallback below runs.
if [ -z "$worktree_name" ] && [ -n "$git_worktree" ]; then
    worktree_name="$git_worktree"
    is_worktree_hint=1
else
    is_worktree_hint=0
fi

# Only an *absent* percentage is unknown. A real 0 is a legitimate reading —
# right after /clear or /compact the context is genuinely empty — and the old
# test lumped "0" in with "null", so a stale pre-compact figure stuck to the
# bar until the next API response.
#
# There is deliberately no on-disk fallback. used_percentage is derivable from
# total_input_tokens / context_window_size whenever it is null: the size is a
# static model property, and total_input_tokens is 0 (not null) before the
# first API response, so this always succeeds. A cache here would only ever
# replay a stale figure after /compact, race other statusline processes over
# the same file, and accumulate one file per session forever.
if [ -z "$used_pct" ] || [ "$used_pct" = "null" ]; then
    if [ -n "$used_tokens" ] && [ "$used_tokens" != "null" ] &&
        [ -n "$total_tokens" ] && [ "$total_tokens" != "null" ] &&
        [ "$total_tokens" -gt 0 ] 2>/dev/null; then
        used_pct=$(awk -v u="$used_tokens" -v t="$total_tokens" 'BEGIN { printf "%.0f", u / t * 100 }')
    fi
fi
# Round to integer — API may return a float (e.g. 4.5) which breaks
# bash arithmetic and the -gt/-lt comparisons below.
[ -n "$used_pct" ] && [ "$used_pct" != "null" ] && used_pct=$(printf '%.0f' "$used_pct" 2>/dev/null)

# ── Git ──────────────────────────────────────────────────────────────
# Everything here comes from TWO git invocations when a repo is present,
# none otherwise. The previous version forked seven, three of which were the
# same `rev-parse --git-dir` probe repeated.
#
# `rev-parse --git-dir --git-common-dir` returns both in one call: in the main
# working tree they are equal, and inside a linked worktree the per-worktree
# dir differs from the shared one. That pair is the worktree test.
#
# The branch deliberately does NOT use `rev-parse --abbrev-ref HEAD`, which
# exits 128 on an unborn HEAD (a freshly `git init`ed repo). `symbolic-ref
# --short HEAD` reports the pending branch there and exits non-zero only when
# HEAD is detached — and both of those exit codes are fine here, since the
# probe below has already established that this is a repository.
git_branch="$worktree_branch"
git_dirty=0
is_worktree=$is_worktree_hint
if [ -z "$current_dir" ]; then
    :
elif _gitinfo=$(git -C "$current_dir" --no-optional-locks \
    rev-parse --git-dir --git-common-dir 2>/dev/null); then
    _gd=${_gitinfo%%$'\n'*}
    _gcd=${_gitinfo##*$'\n'}
    if [ -n "$_gd" ] && [ -n "$_gcd" ] && [ "$_gd" != "$_gcd" ]; then
        is_worktree=1
        if [ -z "$worktree_name" ]; then
            # Use parent dir basename as worktree id (e.g. ~/.codex/worktrees/46a6/clawmaster -> 46a6)
            _parent=$(basename "$(dirname "$current_dir")")
            # Fall back to the dir's own name when the parent is a generic bucket
            case "$_parent" in
                worktrees | wt | .codex | .claude) _parent=$(basename "$current_dir") ;;
            esac
            worktree_name="$_parent"
        fi
    fi

    if [ -z "$git_branch" ]; then
        git_branch=$(git -C "$current_dir" --no-optional-locks \
            symbolic-ref --short HEAD 2>/dev/null)
    fi
    # A detached HEAD yields an empty branch; say so rather than showing a
    # bare repo icon with nothing after it.
    [ -z "$git_branch" ] && git_branch="(detached)"

    # Two diff probes, ~170ms together on a cold NFS checkout, and they only
    # run once there is a branch to colour. Untracked files are not counted —
    # `diff` sees tracked changes only.
    if ! git -C "$current_dir" --no-optional-locks diff --quiet 2>/dev/null ||
        ! git -C "$current_dir" --no-optional-locks diff --cached --quiet 2>/dev/null; then
        git_dirty=1
    fi
fi

# Format a "time until" duration from an epoch timestamp: 47m / 3h / 2d.
# Prints nothing when the stamp is absent or already past.
fmt_until() {
    local at="$1" now d h
    [ -z "$at" ] || [ "$at" = "null" ] && return
    now=$(date +%s)
    d=$((at - now))
    [ "$d" -le 0 ] 2>/dev/null && return
    h=$((d / 3600))
    if [ "$h" -ge 24 ]; then
        printf '%dd' "$((h / 24))"
    elif [ "$h" -ge 1 ]; then
        printf '%dh' "$h"
    else
        printf '%dm' "$((d / 60))"
    fi
}

# Format elapsed milliseconds as 47m / 3h12m / 3h. Under a minute prints
# nothing, so a session that just started doesn't claim "0m", and a whole
# number of hours drops the trailing "0m".
fmt_elapsed() {
    local ms="$1" s h m
    [ -z "$ms" ] || [ "$ms" = "null" ] && return
    [ "$ms" -ge 60000 ] 2>/dev/null || return
    s=$((ms / 1000))
    h=$((s / 3600))
    m=$(((s % 3600) / 60))
    if [ "$h" -ge 1 ]; then
        [ "$m" -eq 0 ] && printf '%dh' "$h" || printf '%dh%dm' "$h" "$m"
    else
        printf '%dm' "$m"
    fi
}

# Progress bar (color scales with context usage)
bar=""
readonly BAR_WIDTH=15
if [ -n "$used_pct" ] && [ "$used_pct" != "null" ]; then
    # Ceiling: any non-zero usage rounds up to at least 1 block.
    filled=$(((used_pct * BAR_WIDTH + 99) / 100))
    [ "$filled" -eq 0 ] && [ "$used_pct" -gt 0 ] && filled=1
    [ "$filled" -gt "$BAR_WIDTH" ] && filled=$BAR_WIDTH
    empty=$((BAR_WIDTH - filled))
    if [ "$used_pct" -gt 80 ]; then
        ctx_color="$C_CTX_LOW"
    elif [ "$used_pct" -gt 50 ]; then
        ctx_color="$C_CTX_WARN"
    else
        ctx_color="$C_CTX_OK"
    fi
    bar="${ctx_color}[${RST}"
    # ░▒▓█
    for ((i = 0; i < filled; i++)); do bar+="${ctx_color}█${RST}"; done
    for ((i = 0; i < empty; i++)); do bar+="${C_BAR_EMPTY}░${RST}"; done
    # Token counts after the bar (30.3k/200k); 0 is a valid reading, not missing data
    ctx_label=""
    if [ -n "$used_tokens" ] && [ "$used_tokens" != "null" ] && [ "$total_tokens" ] && [ "$total_tokens" != "null" ] && [ "$used_tokens" -ge 0 ] 2>/dev/null; then
        if [ "$used_tokens" -ge 1000 ]; then
            used_k=$(awk -v v="$used_tokens" 'BEGIN { printf "%.1fk", v/1000 }')
        else
            used_k="${used_tokens}"
        fi
        if [ "$total_tokens" -ge 1000 ]; then
            total_k=$(awk -v v="$total_tokens" 'BEGIN { printf "%.0fk", v/1000 }')
        else
            total_k="${total_tokens}"
        fi
        ctx_label=" ${ctx_color}${used_k}/${total_k}${RST}"
    fi
    bar+="${ctx_color}]${RST}${ctx_label}"
fi

# Assemble — Line 1: API base URL + model + rate limits + context bar
# ANTHROPIC_BASE_URL is inherited from Claude Code's environment.
# Show only when set (i.e. not the official api.anthropic.com endpoint).
parts1=()

# host[:port] with path stripped, then shortened:
#   domain -> last two labels (token-plan-cn.xiaomimimo.com -> xiaomimimo.com)
#   IP     -> kept whole, port included (127.0.0.1:8088)
base_host=""
if [ -n "$ANTHROPIC_BASE_URL" ]; then
    _hp=$(printf '%s' "$ANTHROPIC_BASE_URL" | sed -e 's|^[a-zA-Z][a-zA-Z0-9+.-]*://||' -e 's|/.*||')
    _host=${_hp%%:*}
    _port=""
    case "$_hp" in *:*) _port=":${_hp##*:}" ;; esac
    case "$_host" in
        *[!0-9.]*) # not a plain IPv4 — keep last two domain labels
            _first=${_host%.*.*}
            if [ "$_first" = "$_host" ]; then
                base_host="$_hp" # fewer than 3 labels, keep as-is
            else
                base_host="${_host#"${_first}".}$_port"
            fi
            ;;
        *) base_host="$_hp" ;; # IPv4 (or empty): host[:port] verbatim
    esac
fi
if [ -n "$base_host" ]; then
    parts1+=("${C_API}󰒍 ${base_host}${RST}")
fi

if [ -n "$model" ]; then
    parts1+=("${C_MODEL}󰥖 ${model}${RST}")
fi

# Subscription quota. Present only for claude.ai Pro/Max subscribers (or a
# gateway spend limit), and only once the session has had one API response.
# The 5h window is the one that actually throttles you mid-session, so it leads;
# the 7d window rides along whenever it is reported. Both use the same
# >80% warn / >95% pressure tiers as the context bar.
_rl_part=""
_rl_add() {
    local label="$1" pct="$2" reset="$3" p eta
    [ -z "$pct" ] || [ "$pct" = "null" ] && return
    p=$(printf '%.0f' "$pct" 2>/dev/null) || return
    if [ "$p" -ge 95 ] 2>/dev/null; then
        eta="$C_RATE_LOW"
    elif [ "$p" -ge 80 ] 2>/dev/null; then
        eta="$C_RATE_WARN"
    else
        eta="$C_RATE"
    fi
    local chunk="${eta}${label} ${p}%"
    local left
    left=$(fmt_until "$reset")
    [ -n "$left" ] && chunk+=" ${C_VERSION}(${left})${RST}${eta}"
    if [ -n "$_rl_part" ]; then
        _rl_part+=" "
    fi
    _rl_part+="${chunk}${RST}"
}
_rl_add "5h" "$rl5_pct" "$rl5_reset"
_rl_add "7d" "$rl7_pct" "$rl7_reset"
if [ -n "$_rl_part" ]; then
    parts1+=(" ${_rl_part}")
fi

if [ -n "$bar" ]; then
    parts1+=("${ctx_color}${RST} ${bar}")
fi

# Assemble — Line 2: session, effort, thinking, style, PR, worktree, git
parts2=()

# Session id, truncated to 8 chars. Deliberately not session_name: the short id
# is what matches a SpecStory transcript's header comment, which is how you get
# from a running session to its saved markdown file.
if [ -n "$session_id" ]; then
    session_short="${session_id:0:8}"
    parts2+=("${C_SESSION_ID} ${session_short}${RST}")
fi

# Color effort by level (max/xhigh/high share the bold-red pressure tier)
if [ -n "$effort" ]; then
    case "$effort" in
        max | MAX | Max | xhigh | XHIGH | XHigh | high | High | HIGH) effort_color="$C_EFFORT_HIGH" ;;
        medium | Medium | MEDIUM) effort_color="$C_EFFORT_MED" ;;
        low | Low | LOW | xlow | XLow | XLOW | minimal | Minimal) effort_color="$C_EFFORT_LOW" ;;
        *) effort_color="$C_EFFORT_OFF" ;;
    esac
    parts2+=("${effort_color} ${effort}${RST}")
fi

# Extended thinking and fast mode. Only the "on" state is worth the columns.
if [ "$thinking" = "true" ]; then
    parts2+=("${C_THINK}✻ think${RST}")
fi
if [ "$fast_mode" = "true" ]; then
    parts2+=("${C_FAST}⚡ fast${RST}")
fi

# Vim mode. Set hideVimModeIndicator:true in settings.json so the built-in
# "-- INSERT --" line below the prompt doesn't duplicate this.
if [ -n "$vim_mode" ] && [ "$vim_mode" != "null" ]; then
    parts2+=("${C_VIM} ${vim_mode}${RST}")
fi

if [ -n "$output_style" ] && [ "$output_style" != "default" ]; then
    parts2+=("${C_STYLE}❋ ${output_style}${RST}")
fi

# Open PR / merge request for the current branch. review_state can lag behind
# pr.number, so fall back to a bare number when it is absent.
if [ -n "$pr_number" ] && [ "$pr_number" != "null" ]; then
    case "$pr_state" in
        approved) pr_color="$C_PR" ;;
        pending) pr_color="$C_PR_WARN" ;;
        changes_requested | draft) pr_color="$C_PR_LOW" ;;
        *) pr_color="$C_PR" ;;
    esac
    if [ -n "$pr_state" ] && [ "$pr_state" != "null" ]; then
        parts2+=("${pr_color} #${pr_number} ${pr_state}${RST}")
    else
        parts2+=("${pr_color} #${pr_number}${RST}")
    fi
fi

if [ -n "$git_branch" ]; then
    if [ "$git_dirty" -eq 1 ]; then
        parts2+=("${C_GIT_DIRTY} ${git_branch}${RST}")
    else
        parts2+=("${C_GIT} ${git_branch}${RST}")
    fi
fi

if [ "$is_worktree" -eq 1 ] && [ -n "$worktree_name" ]; then
    parts2+=("${C_WORKTREE} ${worktree_name}${RST}")
fi

# Lines changed this session, shown as one "+added/-removed" component.
# Only appears when there's any change (added or removed). Missing side is omitted
# (e.g. only deletions → "-30", only additions → "+123").
_lines_add_ok=0
_lines_del_ok=0
[ -n "$lines_added" ] && [ "$lines_added" != "null" ] && [ "$lines_added" -gt 0 ] 2>/dev/null && _lines_add_ok=1
[ -n "$lines_removed" ] && [ "$lines_removed" != "null" ] && [ "$lines_removed" -gt 0 ] 2>/dev/null && _lines_del_ok=1
if [ "$_lines_add_ok" -eq 1 ] || [ "$_lines_del_ok" -eq 1 ]; then
    _lines=""
    [ "$_lines_add_ok" -eq 1 ] && _lines+="${C_LINES_ADD}+${lines_added}${RST}"
    [ "$_lines_add_ok" -eq 1 ] && [ "$_lines_del_ok" -eq 1 ] && _lines+=" "
    [ "$_lines_del_ok" -eq 1 ] && _lines+="${C_LINES_DEL}-${lines_removed}${RST}"
    parts2+=("$_lines")
fi

# Prompt cache. A cold cache is the actionable state — every tool definition or
# system-prompt change, or an idle gap past the TTL, forces a full re-write.
# Show the reason there; otherwise just the hit ratio.
if [ "$cache_warm" = "false" ]; then
    _cache="${C_CACHE_WARN}◐ cache cold"
    [ -n "$cache_miss" ] && [ "$cache_miss" != "null" ] && _cache+=" (${cache_miss})"
    parts2+=("${_cache}${RST}")
elif [ -n "$cache_hit" ] && [ "$cache_hit" != "null" ]; then
    _hit=$(awk -v v="$cache_hit" 'BEGIN { printf "%.0f", v * 100 }')
    if [ "$_hit" -ge 80 ] 2>/dev/null; then
        parts2+=("${C_CACHE_OK}◐ ${_hit}%${RST}")
    elif [ "$_hit" -gt 0 ] 2>/dev/null; then
        parts2+=("${C_CACHE_WARN}◐ ${_hit}%${RST}")
    fi
fi

# Session wall-clock time (accumulates across --resume)
_dur=$(fmt_elapsed "$duration_ms")
[ -n "$_dur" ] && parts2+=("${C_TIME} ${_dur}${RST}")

# Claude Code version (dim, last on the line)
if [ -n "$cc_version" ] && [ "$cc_version" != "null" ]; then
    parts2+=("${C_VERSION}v${cc_version}${RST}")
fi

# Join parts with separator and interpret escape codes
assemble() {
    local parts=("$@")
    local out=""
    local i
    for i in "${!parts[@]}"; do
        if [ "$i" -gt 0 ]; then
            out+="${C_SEP}${SEP}${RST}"
        fi
        out+="${parts[$i]}"
    done
    printf "%b" "$out"
}

line1=$(assemble "${parts1[@]}")
line2=$(assemble "${parts2[@]}")

# Two-line output: each printf/echo creates a separate row
if [ -n "$line2" ]; then
    printf "%b\n%b" "$line1" "$line2"
else
    printf "%b" "$line1"
fi
