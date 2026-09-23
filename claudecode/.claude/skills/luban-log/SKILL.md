---
name: luban-log
description: Download logs from the Luban platform via luban-log-downloader. Use when the user wants to fetch/pull/download or analyze logs for a Luban deployment (appid like k8s-sv1/sv0/sv2/k8s-job/k8s-vj/k8s-serverless), with optional pod names and time range.
disable-model-invocation: true
---

> ref: https://cooper.didichuxing.com/didocs/2209761958693

# Luban Log Downloader

Fetches serving/job logs from the Luban platform (ES-backed, paginated).

## Credentials

Real credentials live in `~/.claude/skills/luban-log/.env.local`.

Every Bash call is a new shell, so ALWAYS inline the env prefix:

```bash
source ~/.claude/skills/luban-log/.env.local && luban-log-downloader <args>
```

## What the user provides

Only two things are required:

1. **appid** (required), e.g. `k8s-sv1-fuhdba-1789476287590-decode`
2. **pod name(s)** (optional but recommended, comma-separated to skip pod discovery)

Optional: time range (`-s`/`-e`), output dir (`-o`), keyword search (`--search`).

## Standard command

```bash
source ~/.claude/skills/luban-log/.env.local && luban-log-downloader \
  -a <appid> \
  --pod-name "<pod1>,<pod2>,<pod3>" \
  -s "YYYY-MM-DD HH:MM:SS" -e "YYYY-MM-DD HH:MM:SS" \
  -o logs_<label>
```

Time formats accepted by `-s`/`-e`: epoch ms, `"2026-02-26 06:14:05"`, ISO `"2026-02-26T06:14:05"`, or date only. **No time range = defaults to last 3 days.**

## PD serving naming convention (this project)

A disaggregated serving deployment splits into multiple appids:

```
k8s-sv1-<name>-<ts>-prefill   → prefill pods (e.g. 3 replicas)
k8s-sv1-<name>-<ts>-decode    → decode pods
k8s-sv1-<name>-<ts>-lb        → router/lb pods (sglang-router, Rust)
```

Pod names look like `<appid>-<hash>-master-0`. If the user gives an appid without
pods and discovery is unreliable, list pods with `kubectl`-style naming or ask.

## Rules

1. **Always use a distinct `-o` dir per time window** (e.g. `logs`, `logs_early`).
   Output files are named by pod name only — re-downloading the same pod for a
   different window into the same dir silently overwrites the previous file.
2. **Run in background** when downloading multiple pods or a window > 1 hour
   (each pod can be 50–60 MB per 3 h; pagination takes a while).
3. **Verify after download**: `ls -lh <dir>` plus `head -1` / `tail -1` of one
   file to confirm the time range actually covered.
4. If exact pod names are unknown, omit `--pod-name` to let the tool discover
   pods (it prints them); or ask the user.

## Post-download analysis quick wins

- Every line has TWO timestamps: `[collection time CST] [container time UTC]`
  — they differ by 8 h. Always use the first (collection, Beijing time).
- Error triage:
  ```bash
  grep -icE 'error|exception|fail|timeout|refused|abort' <log>
  grep -iE 'error|exception|fail' <log> | sed -E "s/[0-9]+/N/g" | sort | uniq -c | sort -rn   # dedup message types
  ```
- Timeline of a keyword per minute: `grep '<keyword>' <log> | grep -oE '^\[[0-9-]+ [0-9]{2}:[0-9]{2}' | uniq -c`
- Prefer writing intermediate analysis output to /tmp files and reading them,
  instead of piping huge grep results straight to stdout.

## Examples

# One decode pod, 3-hour window
source ~/.claude/skills/luban-log/.env.local && luban-log-downloader -a k8s-sv1-xxx-decode \
  --pod-name "k8s-sv1-xxx-decode-cb5b02-master-0" \
  -s "2026-09-18 17:00:00" -e "2026-09-18 20:00:00"

# All 3 prefill pods at once, separate output dir
source ~/.claude/skills/luban-log/.env.local && luban-log-downloader -a k8s-sv1-xxx-prefill \
  --pod-name "pod-a,pod-b,pod-c" -s "2026-09-18 17:00:00" -e "2026-09-18 20:00:00" \
  -o logs_prefill

# Search mode: find keyword, then download ±2 h context around matches
source ~/.claude/skills/luban-log/.env.local && luban-log-downloader -a k8s-sv1-xxx-decode --search "OOM" --context-hours 2

## Reference

- `luban-log-downloader -h` for full flags (`--page-size`, `--region`, `--luban-url`)
- Default API: `http://api-ml.intra.xiaojukeji.com` (env `LUBAN_URL` to override)
