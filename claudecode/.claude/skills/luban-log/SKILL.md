---
name: luban-log
description: Download logs from the Luban platform via luban-log-downloader. Use when the user wants to fetch/pull/download or analyze logs for a Luban deployment (appid like k8s-sv1/sv0/sv2/k8s-job/k8s-vj/k8s-serverless), with optional pod names and time range.
disable-model-invocation: true
---

> ref: https://cooper.didichuxing.com/didocs/2209761958693

# Luban Log Downloader

Fetches serving/job logs from the Luban platform (ES-backed, paginated).

## TL;DR — you usually only need the appid

```bash
~/.claude/skills/luban-log/luban-project-log <appid> \
  -s "YYYY-MM-DD HH:MM:SS" -e "YYYY-MM-DD HH:MM:SS" -o logs_<label>
```

The wrapper figures out the rest on its own:

| needs | how it is resolved |
|---|---|
| pod names | ES `terms` agg on `kubernetes.pod_name` |
| project uuid | ES `kubernetes.namespace_name` = `jianshu-serving-ns-<uuid>` |
| region (`-r`) | suffix of ES `kubernetes.host` (`ml-xxx.nmg03` → `nmg03`) |
| credentials | `projects.tsv`; **omitted entirely** when the project is unknown |

The ES path needs **no Luban API credentials at all** — it is the reliable
route. Project credentials only buy the faster live-discovery API, and they
must belong to the project that owns the appid.

## Credentials (never inline them)

All secrets live in `~/.claude/skills/luban-log/.env.local` (mode 600):

```bash
USER_UUID=...        # identifies YOU; the same for every project
PROJECT_UUID=...     # default project
PROJECT_TOKEN=...    # bound to PROJECT_UUID (see below)
ES_URL=...
ES_AUTH=...          # Basic auth for the ES index
```

- **`USER_UUID` is not per-project.** It is your account id and stays constant.
- **`PROJECT_UUID` + `PROJECT_TOKEN` are a per-project pair.** A token from
  another project fails discovery with `code=3000 … 您操作的服务不属于当前项目`
  or `invalid token`. That is expected, not a bug — the wrapper falls back to ES.
- Additional projects go in `projects.tsv`, one tab-separated line:
  `<project-name>\t<project-uuid>\t<project-token>\t<note>`
- `.env.local` and `projects.tsv` are git-ignored (`.gitignore` in this dir).
  Never paste a uuid/token into SKILL.md, a command line, or a commit.

Everything is a fresh shell, so source the env when calling the raw downloader:

```bash
source ~/.claude/skills/luban-log/.env.local && luban-log-downloader <args>
```

## The helper

```bash
~/.claude/skills/luban-log/luban-project-log <appid> [flags...]          # preferred
~/.claude/skills/luban-log/luban-project-log <project> <appid> [flags...] # legacy
~/.claude/skills/luban-log/luban-project-log auto <appid> [flags...]      # force auto-detect
```

`<project>` is a name / uuid / uuid-prefix from `projects.tsv`. An explicit
project wins over the ES-derived one, with a warning if they disagree.

Flags are passed through to the downloader (`-s/-e/-o/-r/--search/...`).
Exit codes: `0` ok · `2` bad args · `3` unknown project · `5` no pods in ES.

Behaviour:

1. Query ES for the pod set, the project uuid, and the region.
2. If the project is in `projects.tsv`, try live discovery first; otherwise, or
   on failure, download straight from the ES pod names.
3. `-r` is only needed when ES cannot supply it.

ES `time` is UTC, the downloader and `-s`/`-e` are CST — the helper converts.
No `-s`/`-e` means the last 3 days. ES keeps roughly 7 days.

## What the user provides

1. **appid** (required), e.g. `k8s-sv1-fuhdba-1789476287590-decode`.
2. Pod names (optional) — omit them; ES already knows.
3. Time range (optional, strongly recommended for a large appid).

## Standard command (raw downloader)

```bash
source ~/.claude/skills/luban-log/.env.local && luban-log-downloader \
  -a <appid> --pod-name "<pod1>,<pod2>" \
  -s "YYYY-MM-DD HH:MM:SS" -e "YYYY-MM-DD HH:MM:SS" -o logs_<label>
```

With `--pod-name` you may omit the project credentials entirely.

Time formats for `-s`/`-e`: epoch ms, `"2026-02-26 06:14:05"`, ISO, or a date.

## PD serving naming convention

A disaggregated deployment splits into several appids:

```
k8s-sv1-<name>-<ts>-prefill   → prefill pods
k8s-sv1-<name>-<ts>-decode    → decode pods
k8s-sv1-<name>-<ts>-lb        → router/lb pods (sglang-router, Rust)
```

Pod names look like `<appid>-<hash>-master-0`.

## Rules

1. **One `-o` dir per time window** (e.g. `logs`, `logs_early`). Files are named
   by pod only — the same pod + a new window in the same dir overwrites.
2. **Run in background** for multiple pods or a window > 1 h (each pod can be
   50–60 MB per 3 h).
3. **Verify after download**: `ls -lh <dir>`, then `head -1` / `tail -1` of one
   file to confirm the range.
4. Never widen a window "just in case" — a whole day of a busy LB pod is huge.

## Post-download analysis quick wins

- Each line has TWO timestamps: `[collection CST] [container UTC]`, 8 h apart.
  Use the first (Beijing time).
- Error triage:
  ```bash
  grep -icE 'error|exception|fail|timeout|refused|abort' <log>
  grep -iE 'error|exception|fail' <log> | sed -E "s/[0-9]+/N/g" | sort | uniq -c | sort -rn
  ```
- Timeline of a keyword per minute:
  `grep '<keyword>' <log> | grep -oE '^\[[0-9-]+ [0-9]{2}:[0-9]{2}' | uniq -c`
- Write intermediate analysis to `/tmp` files rather than piping huge greps
  to stdout.

### Aggregating measurements (important for this ES index)

`log` is mapped as **`text` with no `.keyword` sub-field**, so ES cannot
aggregate or sort that text. Bucket by `kubernetes.pod_name`, `time`,
`kubernetes.host`, etc., then parse `log` locally (Python/regex). A `terms` agg
on `log.keyword` will fail with `unrecognized field`.

### Crashes / OOM restarts

- `exit status 137` / `router_status=137` / `Killed` in a `sglang_router_bin.sh`
  line is the container's OOM-kill signature (128+9).
- The restart cliff shows up as per-minute log volume collapsing to a near-flat
  heartbeat (~17 lines/min):
  ```bash
  grep -oE '^\[[0-9-]+ [0-9]{2}:[0-9]{2}' <log> | uniq -c | tail -60
  ```
- Locate the restart banner (`执行启动脚本: .../sglang_router_bin.sh`,
  `START_PARAM:`, `正在启动 sglang 推理服务...`) with `grep -n`.
- `All N workers are healthy` after restart confirms recovery.
- A restarted LB pod leaves live discovery empty; the ES pod-name path above
  still returns the old pod's logs.

## Examples

```bash
# Only the appid — project and region auto-detected
~/.claude/skills/luban-log/luban-project-log k8s-sv1-yfvafq-1794471903234-lb \
  -s "2026-11-26 16:55:00" -e "2026-11-26 17:00:00" -o logs_lb

# A project you have credentials for (faster live discovery)
~/.claude/skills/luban-log/luban-project-log tokenservice-online k8s-sv1-xxx-decode \
  -s "2026-11-26 17:00:00" -e "2026-11-26 20:00:00" -o logs_decode

# All prefill pods, raw downloader with source'd creds
source ~/.claude/skills/luban-log/.env.local && luban-log-downloader -a k8s-sv1-xxx-prefill \
  --pod-name "pod-a,pod-b,pod-c" -s "2026-11-26 17:00:00" -e "2026-11-26 20:00:00" -o logs_prefill
```

## Reference

- `luban-log-downloader -h` for every flag (`--page-size`, `--search`,
  `--context-hours`, `--luban-url`).
- Default API: `http://api-ml.intra.xiaojukeji.com` (`LUBAN_URL` overrides).
- ES index: `<ES_URL>/cn_ml_luban_log_<YYYY-MM-DD>_v<N>`.
