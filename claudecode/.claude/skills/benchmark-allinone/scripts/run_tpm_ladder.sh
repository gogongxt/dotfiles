#!/bin/bash
# ---------------------------------------------------------------------------
# TPM 阶梯压测：逐档创建 timestamp_replay 任务，直到定位 avg TTFT 拐点。
#
#   run_tpm_ladder.sh <tier_w> [tier_w ...]     例: run_tpm_ladder.sh 1200 1000 800
#
# 每档创建一个任务：单客户端、按数据集原始时间戳回放、窗口可配（默认 2h）。
# 每档结束（done/failed/abort）打印一行 RESULT 并追加到 JSONL；全部结束后
# 打印汇总表，标出是否越过 SLO（默认 avg TTFT 10s）。
#
# 依赖：bash + curl + python3（不需要 jq）。失败的任务不会中断后续档位。
# ---------------------------------------------------------------------------
set -euo pipefail

PLATFORM=${PLATFORM:-https://ifx-llm-benchmark.intra.xiaojukeji.com}
TARGET_HOST=${TARGET_HOST:?usage: TARGET_HOST=<host> TARGET_PORT=<port> run_tpm_ladder.sh <tier...>}
TARGET_PORT=${TARGET_PORT:?TARGET_PORT required}
MODEL_NAME=${MODEL_NAME:-}          # 空 = 执行时向目标 /v1/models 取第一个
MODEL_PATH=${MODEL_PATH:-}          # 平台侧 tokenizer 路径（必需，平台主机可读）
DATASET_PATH=${DATASET_PATH:-/home/luban/ShareGPT_V3_unfiltered_cleaned_split.json}
DATASET=${DATASET:-dsv4_flash_mixed_length}
WINDOW=${WINDOW:-7200}              # 回放窗口秒数；不超过数据集族的时长上限（1m/200k=3600，其余=7200）
OUTPUT_MODE=${OUTPUT_MODE:-manual}  # manual | output_token | dataset_max_tokens
OUT_LEN=${OUT_LEN:-1}               # OUTPUT_MODE=manual 时的每轮输出上限；1 = 纯 prefill / TTFT
TAG=${TAG:-slo}
POLL=${POLL:-30}
SLO_AVG_S=${SLO_AVG_S:-10}          # 汇总表的 SLO 判定阈值（avg TTFT，秒）

WORK=${WORK:-$HOME/slo_runs}
mkdir -p "$WORK"
RESULTS="$WORK/tpm_ladder_$(date +%m%d_%H%M%S).jsonl"
echo "results_file=$RESULTS" >&2

if [ "$#" -eq 0 ]; then echo "usage: run_tpm_ladder.sh <tier_w> [tier_w ...]" >&2; exit 2; fi

for TPM in "$@"; do
    name="slo-${TARGET_HOST##*.}-${TPM}w-${TAG}-$(date +%m%d_%H%M%S)"
    body=$(python3 - "$name" "$TARGET_HOST" "$TARGET_PORT" "$MODEL_NAME" \
                      "$MODEL_PATH" "$DATASET_PATH" "$WINDOW" "$TPM" \
                      "$DATASET" "$OUTPUT_MODE" "$OUT_LEN" <<'PYEOF'
import json, sys
(name, host, port, model, mpath, dpath, window, tpm, dataset, omode, outlen) = sys.argv[1:12]
body = {
    "name": name, "connection_mode": "host_port",
    "host": host, "port": int(port),
    "model_path": mpath, "dataset_path": dpath,
    "test_mode": "multi_turn",
    # [L, S, O, C, T, P]: T = 窗口秒数（timestamp_replay），P = 名义 TPM 档位
    "mt_combos": [[20480, 10240, int(outlen), 1, int(window), int(tpm)]],
    "mt_num_clients": 1, "mt_num_rounds": 5, "mt_range_ratio": 0.5,
    "mt_max_context_length": 0, "mt_init_interval": 0.2,
    "mt_request_timeout_seconds": 1800, "mt_total_requests": int(window),
    "mt_seed": 42, "mt_api_format": "openai",
    "mt_enable_session_key": True, "mt_enable_cache_nonce": True,
    "mt_replay_output_mode": omode, "mt_replay_thinking_mode": "dataset",
    "mt_workload_mode": "timestamp_replay",
    "mt_replay_dataset_path": dataset,
    "mt_request_rate": 0.0,
}
if model:
    body["request_model"] = model
else:
    body["model_name_mode"] = "auto"
print(json.dumps(body))
PYEOF
)
    resp=$(curl -s --max-time 30 -X POST "$PLATFORM/api/task" \
                -H 'Content-Type: application/json' -d "$body")
    tid=$(python3 -c 'import json,sys;print(json.loads(sys.argv[1]).get("task_id",""))' "$resp" 2>/dev/null || true)
    if [ -z "$tid" ]; then
        echo "create failed (tpm=${TPM}W): $resp" >&2
        continue
    fi
    echo "=== tpm=${TPM}W task_id=$tid name=$name window=${WINDOW}s ==="
    curl -s -X POST "$PLATFORM/api/task/$tid/run" > /dev/null

    deadline=$(( $(date +%s) + WINDOW + 3600 ))
    while [ "$(date +%s)" -lt "$deadline" ]; do
        sleep "$POLL"
        st=$(curl -s --max-time 10 "$PLATFORM/api/task/$tid" \
             | python3 -c 'import json,sys;print(json.load(sys.stdin)["task"]["status"])' 2>/dev/null || echo unknown)
        echo "$(date +%H:%M:%S) tpm=${TPM}W status=$st"
        case "$st" in
            done|failed|abort)
                curl -s --max-time 20 "$PLATFORM/api/task/$tid" > "$WORK/task_${tid}.json"
                python3 - "$WORK/task_${tid}.json" "$TPM" "$tid" "$RESULTS" <<'PYEOF'
import json, sys
path, tpm, tid, out = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4]
d = json.load(open(path))
row = {"tpm": tpm, "task_id": tid, "task_status": d["task"]["status"]}
def secs(pr, key):
    v = pr.get(key)
    return None if v is None else round(float(v) / 1000, 3)
for r in d.get("runs", []):
    pr = r.get("parsed_result") or "{}"
    if isinstance(pr, str):
        try: pr = json.loads(pr)
        except Exception: pr = {}
    row.update({
        "run_status": r.get("status"),
        "ok": pr.get("Successful requests"),
        "total": pr.get("Total requests"),
        "ttft_avg_s": secs(pr, "Average TTFT (ms)"),
        "ttft_med_s": secs(pr, "Median TTFT (ms)"),
        "ttft_p90_s": secs(pr, "P90 TTFT (ms)"),
        "ttft_p99_s": secs(pr, "P99 TTFT (ms)"),
        "delivered_tpm_w": pr.get("Window completed TPM (10k tok/min)"),
        "prompt_avg": pr.get("Average Prompt Length"),
        "in_tok_s": pr.get("Input token throughput (tok/s)"),
    })
print("RESULT", json.dumps(row, ensure_ascii=False))
open(out, "a").write(json.dumps(row, ensure_ascii=False) + "\n")
PYEOF
                break
                ;;
        esac
    done
done

echo "=== ladder summary (SLO: avg TTFT <= ${SLO_AVG_S}s) ==="
[ -s "$RESULTS" ] || { echo "no completed runs"; exit 0; }
python3 - "$RESULTS" "$SLO_AVG_S" <<'PYEOF'
import json, sys
rows = [json.loads(l) for l in open(sys.argv[1])]
slo = float(sys.argv[2])
def f(v, w, p=2):
    return (f"{v:>{w}.{p}f}" if isinstance(v, (int, float)) else f"{'-':>{w}}")
print(f"{'tier':>6} {'deliv':>7} {'ok/tot':>12} {'avg':>7} {'med':>7} {'p90':>8} {'p99':>8} {'verdict':>9}  task")
for r in rows:
    ok = f"{r.get('ok')}/{r.get('total')}" if r.get('total') else '-'
    avg = r.get('ttft_avg_s')
    if r.get('task_status') != 'done' or avg is None:
        verdict = 'ABORT' if r.get('task_status') == 'abort' else 'N/A'
    elif avg <= slo:
        verdict = 'ok'
    else:
        verdict = 'OVER'
    print(f"{r['tpm']:>5}W {f(r.get('delivered_tpm_w'),7,1)} {ok:>12} "
          f"{f(avg,7)} {f(r.get('ttft_med_s'),7)} {f(r.get('ttft_p90_s'),8)} "
          f"{f(r.get('ttft_p99_s'),8)} {verdict:>9}  {r['task_id']}")
PYEOF