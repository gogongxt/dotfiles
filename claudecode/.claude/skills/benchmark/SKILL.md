---
name: benchmark
description: Run LLM serving benchmarks (sglang/vllm) on remote GPU machines - environment check, service launch, benchmark execution, and result collection
user-invocable: true
---

# LLM Serving Benchmark

Automate LLM serving benchmarks on GPU machines. Handles environment validation, service lifecycle (start/health-check/stop), benchmark execution across concurrency levels, and result collection with full logging.

## When to Use

- Benchmark sglang or vllm serving throughput/latency on a GPU machine
- Run systematic concurrency sweep tests (1, 2, 4, 8, ... up to max)
- Compare performance across models, TP configs, or input/output length combos

## Required User Inputs

Before starting, the user MUST provide the following information. **Do not assume or guess any path — always ask the user if not specified.**

| Parameter          | Description                                                             | Example                                              |
| ------------------ | ----------------------------------------------------------------------- | ---------------------------------------------------- |
| `BENCH_SH`         | Path to bench.sh script                                                 | `/path/to/benchmark/bench.sh`                        |
| `BENCH_SERVING_PY` | Path to bench_serving.py script                                         | `/path/to/benchmark/bench_serving.py`                |
| `DATASET_PATH`     | Path to ShareGPT dataset JSON file                                      | `/path/to/ShareGPT_V3_unfiltered_cleaned_split.json` |
| `MODEL_PATHS`      | One or more model weight paths to test                                  | `/path/to/Qwen3-8B`                                  |
| `HOST`             | Target machine SSH address                                              | `root@10.0.0.1` or SSH alias                         |
| `PORT`             | SSH port (default: 22)                                                  | `22`                                                 |
| `SERVE_PORT`       | Serving port for the LLM service (default: 8055)                        | `8055`                                               |
| `CONTAINER`        | (Optional) Docker container name to exec into for launch/bench          | `my-sglang-container`                                |
| `LOG_DIR`          | (Optional) Directory for log files on target machine (default: `$HOME`) | `/data/logs`                                         |

For `MODEL_PATHS`, the user may specify:

- A single model path → test that model only
- Multiple model paths with TP values → test each with specified TP (e.g., "Qwen3-8B tp1, Qwen3-32B tp2")

If the user only describes the GPU specs (e.g., "2x A100 80GB") without specifying models, suggest models based on the VRAM rules below and ask for confirmation.

### Model Selection Guidance (when user doesn't specify)

Based on **total available GPU VRAM** (sum of all GPUs), suggest:

| Total VRAM | Suggested Models                                           | TP      |
| ---------- | ---------------------------------------------------------- | ------- |
| < 40 GB    | Qwen3-8B                                                   | tp=1    |
| 40–100 GB  | Qwen3-8B (tp=1) + Qwen3-32B (tp=2)                         | 1, 2    |
| > 100 GB   | Qwen3-8B (tp=1) + Qwen3-32B (tp=2) + DeepSeek-V3/R1 (tp=8) | 1, 2, 8 |

**Always ask the user to confirm model paths before proceeding.** These are suggestions only.

## Required Files Check

Using the user-provided paths, verify each file exists on the target machine before proceeding:

```bash
# Without container
ssh <host> "test -f <BENCH_SH> && echo 'bench.sh OK' || echo 'bench.sh MISSING'"
ssh <host> "test -f <BENCH_SERVING_PY> && echo 'bench_serving.py OK' || echo 'bench_serving.py MISSING'"
ssh <host> "test -f <DATASET_PATH> && echo 'dataset OK' || echo 'dataset MISSING'"
ssh <host> "test -d <MODEL_PATH> && echo 'model OK' || echo 'model MISSING'"

# With container — prepend docker exec
ssh <host> "docker exec <CONTAINER> test -f <BENCH_SH> && echo 'bench.sh OK' || echo 'bench.sh MISSING'"
# ... same pattern for other files
```

If any file is MISSING, **stop and report** — do not proceed. Ask the user for the correct path.

## Framework Detection

Before launching, determine which framework is installed on the target machine:

```bash
# Without container
ssh <host> "pip show sglang 2>/dev/null | head -2; pip show vllm 2>/dev/null | head -2"

# With container
ssh <host> "docker exec <CONTAINER> bash -c 'pip show sglang 2>/dev/null | head -2; pip show vllm 2>/dev/null | head -2'"
```

If exist two framework at the same time, please use the sglang framework.

The framework determines the launch command:

### SGLang

```bash
python3 -m sglang.launch_server \
  --model-path <MODEL_PATH> \
  --tp <tp> \
  --host 0.0.0.0 \
  --port <SERVE_PORT>
```

Health check: `http://127.0.0.1:<SERVE_PORT>/health`

### vLLM

```bash
vllm serve <MODEL_PATH> \
  --host 0.0.0.0 \
  --port <SERVE_PORT> \
  --tensor-parallel-size <tp>
```

Health check: `http://127.0.0.1:<SERVE_PORT>/health`

**If neither framework is detected, report to the user and stop.**

## Test Configurations

For each model+TP combo, run two benchmark configs:

| Config Name | Input Len | Output Len |
| ----------- | --------- | ---------- |
| 2k1k        | 2048      | 1024       |
| 8k2k        | 8192      | 2048       |

`--num-prompt-times` uses default value (10). Concurrency is a power-of-2 sweep (see below).

## Max Concurrency Calculation

The maximum concurrency is bounded by KV cache capacity:

```
max_concurrency = floor(total_kv_cache_tokens / (input_len + output_len))
```

**Getting KV cache capacity:** After the serving process starts and passes health check, grep the service log:

```bash
# For sglang, look for a line like:
# "[2026-05-12 20:19:43] KV Cache is allocated. #tokens: 309031, K size: 21.22 GB, V size: 21.22 GB"
#
# For vllm, look for a line like:
# "(EngineCore pid=3931606) INFO 05-13 18:08:50 [kv_cache_utils.py:1316] GPU KV cache size: 82,304 tokens"
#
# Try broader pattern first, then fall back to exact pattern
ssh <host> "grep -i 'kv cache\|tokens' <service_log> | tail -5"
```

If the grep returns no results, try checking the full log for any line mentioning capacity or allocation:

If KV cache info still cannot be found, report to the user — do not guess the max concurrency.

**Concurrency sweep rule:**

- Start from 1, double each step: 1, 2, 4, 8, 16, 32, ...
- Stop at `min(max_concurrency, 128)`
- Example: if KV cache = 600k tokens, 8k2k needs 10k per request → max 60 → sweep: 1, 2, 4, 8, 16, 32

## Log File Naming Convention

All logs go to `<LOG_DIR>` on the target machine (defaults to `$HOME` if not specified by user).

| Type         | Pattern                                                                    | Example                                                          |
| ------------ | -------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| Service log  | `<LOG_DIR>/serve-<YYYYMMDD-HHmmss>-<model>-tp<n>.log`                      | `<LOG_DIR>/serve-20260512-143025-qwen3-8b-tp1.log`               |
| Bench output | `<LOG_DIR>/benchmark-<YYYYMMDD-HHmmss>-<model>-tp<n>-<input>-<output>.txt` | `<LOG_DIR>/benchmark-20260512-143025-qwen3-8b-tp1-2048-1024.txt` |

**Every test round must produce both logs.** If a log is empty or missing, report it.

## Full Workflow

Follow these steps **in order** for each model+TP+config combination. If parallel mode is enabled (see [Parallel Benchmark Mode](#parallel-benchmark-mode)), adapt the workflow as described in the Parallel Workflow section — launching multiple services concurrently, using explicit ports and `CUDA_VISIBLE_DEVICES`, and killing by PID only.

**Important: Restart the service before every bench.sh run**, even if the model+TP is the same (e.g., testing 2k1k then 8k2k on the same model). This clears KV cache and other state to ensure clean results.

### Step 1: Gather Inputs & Pre-flight Checks

1. Ask the user for all required inputs (BENCH_SH, BENCH_SERVING_PY, DATASET_PATH, MODEL_PATHS, HOST, etc.) if not already provided
2. Verify all files exist on the target machine
3. Detect framework (sglang vs vllm)
4. Check GPU VRAM to confirm model+TP selection is feasible

```bash
ssh <host> "nvidia-smi --query-gpu=index,name,memory.total --format=csv,noheader,nounits"
```

### Step 2: GPU Clearance Check

Before starting any service, verify GPUs are free:

```bash
ssh <host> "nvidia-smi --query-gpu=index,memory.used,memory.free,utilization.gpu --format=csv,noheader,nounits"
```

**Rules:**

- If GPU memory is occupied by a process **you started previously** (check PID against your records): kill it, wait 10s, re-check
- If GPU memory is occupied by an **unknown process**: **do NOT kill it** — report to the user and ask how to proceed
- Only proceed when all target GPUs show < 100 MB used and < 5% utilization

### Step 3: Start Serving Service

Generate a log file name: `<LOG_DIR>/serve-<YYYYMMDD-HHmmss>-<model_name>-tp<tp>.log`

Example: `<LOG_DIR>/serve-20260512-143025-qwen3-8b-tp1.log`

If `CONTAINER` is specified, use `docker exec <CONTAINER>` for all commands inside the container (launch, bench, grep log, kill process). Health check curl and GPU checks stay on the host since ports are mapped and GPUs are visible from host.

```bash
# Without container — sglang
ssh <host> "nohup python3 -m sglang.launch_server --model-path <MODEL_PATH> --tp <tp> --host 0.0.0.0 --port <SERVE_PORT> > <LOG_DIR>/serve-$(date +%Y%m%d-%H%M%S)-<model>-tp<tp>.log 2>&1 & echo \$!"

# Without container — vllm
ssh <host> "nohup vllm serve <MODEL_PATH> --host 0.0.0.0 --port <SERVE_PORT> --tensor-parallel-size <tp> > <LOG_DIR>/serve-$(date +%Y%m%d-%H%M%S)-<model>-tp<tp>.log 2>&1 & echo \$!"

# With container — sglang
ssh <host> "docker exec -d <CONTAINER> bash -c 'python3 -m sglang.launch_server --model-path <MODEL_PATH> --tp <tp> --host 0.0.0.0 --port <SERVE_PORT> > <LOG_DIR>/serve-$(date +%Y%m%d-%H%M%S)-<model>-tp<tp>.log 2>&1'"

# With container — vllm
ssh <host> "docker exec -d <CONTAINER> bash -c 'vllm serve <MODEL_PATH> --host 0.0.0.0 --port <SERVE_PORT> --tensor-parallel-size <tp> > <LOG_DIR>/serve-$(date +%Y%m%d-%H%M%S)-<model>-tp<tp>.log 2>&1'"
```

Record the PID for later cleanup.

### Step 4: Wait for Health Check

Poll the health endpoint until ready (max 10 minutes, check every 5s):

```bash
for i in $(seq 1 120); do
  if ssh <host> "curl -sf http://127.0.0.1:<SERVE_PORT>/health"; then
    echo "Service is ready"
    break
  fi
  sleep 5
done
```

If timeout after 10 minutes, check the log for errors:

```bash
# Without container
ssh <host> "tail -50 <LOG_DIR>/serve-<timestamp>-<model>-tp<tp>.log"

# With container
ssh <host> "docker exec <CONTAINER> tail -50 <LOG_DIR>/serve-<timestamp>-<model>-tp<tp>.log"
```

Report the error. Optionally retry once (kill the process and restart).

**Service startup failure handling:**

- **Port conflict** (e.g., "Address already in use"): Try a different SERVE_PORT (e.g., 8056, 8057, ...), then restart the service
- **Model path error** (e.g., "No such file or directory", "Model not found"): Verify the model path on the target machine, correct it, and retry
- **OOM / CUDA error**: Check GPU memory, confirm model fits in available VRAM with the given TP, and retry once
- **Unknown error**: Restart the service once. If it fails again, **skip this model+TP+config combo** and report the error to the user — do not spend time on repeated retries, as the root cause may require human investigation

### Step 5: Determine Max Concurrency

After the service is healthy, extract KV cache capacity from the log:

```bash
# Without container — sglang: "KV Cache is allocated. #tokens: 309031"
#                      vllm:  "GPU KV cache size: 82,304 tokens"
ssh <host> "grep -i 'kv cache\|tokens' <LOG_DIR>/serve-<timestamp>-<model>-tp<tp>.log | tail -5"

# With container
ssh <host> "docker exec <CONTAINER> grep -i 'kv cache\|tokens' <LOG_DIR>/serve-<timestamp>-<model>-tp<tp>.log | tail -5"
```

If the grep returns no results, try checking the full log for any line mentioning capacity or allocation:

If KV cache info still cannot be found, report to the user — do not guess the max concurrency.

Calculate:

```
max_conc = floor(kv_cache_tokens / (input_len + output_len))
final_max = min(max_conc, 128)
```

Build the concurrency list: powers of 2 up to `final_max`.
Example: final_max=60 → concurrency list = 1, 2, 4, 8, 16, 32

**Log the KV cache info and calculated max concurrency.**

### Step 6: Run Benchmark

Execute `bench.sh` with appropriate parameters. Redirect output to a log file:

`<LOG_DIR>/benchmark-<YYYYMMDD-HHmmss>-<model_name>-tp<tp>-<input_len>-<output_len>.txt`

```bash
# Without container
# Derive BENCH_DIR from BENCH_SH path (directory containing bench.sh)
ssh <host> "cd <BENCH_DIR> && \
  bash <BENCH_SH> \
    --bench-script <BENCH_SERVING_PY> \
    --tokenizer <MODEL_PATH> \
    --host 127.0.0.1 \
    --port <SERVE_PORT> \
    --dataset-path <DATASET_PATH> \
    --random-input-len <input_len> \
    --random-output-len <output_len> \
    --concurrency 1 2 4 8 16 32 \
    > <LOG_DIR>/benchmark-$(date +%Y%m%d-%H%M%S)-<model>-tp<tp>-<input_len>-<output_len>.txt 2>&1"

# With container
ssh <host> "docker exec <CONTAINER> bash -c 'cd <BENCH_DIR> && \
  bash <BENCH_SH> \
    --bench-script <BENCH_SERVING_PY> \
    --tokenizer <MODEL_PATH> \
    --host 127.0.0.1 \
    --port <SERVE_PORT> \
    --dataset-path <DATASET_PATH> \
    --random-input-len <input_len> \
    --random-output-len <output_len> \
    --concurrency 1 2 4 8 16 32 \
    > <LOG_DIR>/benchmark-$(date +%Y%m%d-%H%M%S)-<model>-tp<tp>-<input_len>-<output_len>.txt 2>&1'"
```

Note: `bench.sh` auto-detects the model name from the `/v1/models` endpoint.

Wait for the benchmark to complete (runs synchronously).

**Benchmark failure handling:**

If `bench.sh` fails (non-zero exit, OOM, timeout, service crash, etc.):

1. Stop the current service (Step 7)
2. Restart the service from scratch (Step 3 → Step 4)
3. Re-run the benchmark once
4. If it fails again, **skip this model+TP+config combo** and move to the next one. Report the failure details to the user — the root cause may be a deeper issue (e.g., insufficient VRAM, framework bug, hardware problem) that requires human investigation
5. Do not spend time on more than one retry — quickly move on to the next test

### Step 7: Stop Service and Verify Cleanup

**In parallel mode: always kill by PID only — never use `pkill`**, as it will kill all running services, not just the one you intend to stop.

```bash
# Without container — kill by PID (from Step 3)
ssh <host> "kill <pid> 2>/dev/null; sleep 5"

# With container — kill by PID inside container
ssh <host> "docker exec <CONTAINER> kill <pid> 2>/dev/null; sleep 5"
```

**Fallback (sequential mode only, when PID is lost):**

```bash
# Without container — if PID lost and NOT in parallel mode
ssh <host> "pkill -f 'python.*sglang.*launch_server.*--port <SERVE_PORT>' || pkill -f 'vllm serve.*--port <SERVE_PORT>' || true"

# With container — if PID lost and NOT in parallel mode
ssh <host> "docker exec <CONTAINER> bash -c 'pkill -f \"python.*sglang.*launch_server.*--port <SERVE_PORT>\" || pkill -f \"vllm serve.*--port <SERVE_PORT>\" || true'"
```

**If PID is lost in parallel mode**, ask the user how to proceed — do not use `pkill` as it may kill other running services. You can identify the correct process by matching the port:

```bash
ssh <host> "ps aux | grep '<SERVE_PORT>' | grep -v grep"
```

Then kill by the discovered PID.

# Verify GPUs are free (always from host)

```
ssh <host> "nvidia-smi --query-gpu=index,memory.used --format=csv,noheader,nounits"
```

All GPUs should show < 100 MB used. If not, investigate and report.

### Step 8: Summary

After all model+TP+config combos have been tested (or skipped), present a summary to the user:

| Model    | TP  | Config | Status                | Serve Log                    | Bench Log                     | Notes                     |
| -------- | --- | ------ | --------------------- | ---------------------------- | ----------------------------- | ------------------------- |
| Qwen3-8B | 1   | 2k1k   | OK / SKIPPED / FAILED | `serve-...-qwen3-8b-tp1.log` | `benchmark-...-2048-1024.txt` | (error details if failed) |
| Qwen3-8B | 1   | 8k2k   | OK / SKIPPED / FAILED | `serve-...-qwen3-8b-tp1.log` | `benchmark-...-8192-2048.txt` |                           |
| ...      |     |        |                       |                              |                               |                           |

Key points to report:

- How many test combos completed successfully vs skipped/failed
- Any skipped or failed combos — include the error reason
- Whether all log files were produced and non-empty
- Any GPU cleanup issues (residual memory after stopping services)
- Log file name for every test combo — include both the serve log and bench log paths so the user can quickly locate specific results (e.g., which file is the DeepSeek service log, which file is the 2k1k bench output)

## Parallel Benchmark Mode

When GPU resources are sufficient to run multiple model instances simultaneously, **parallel benchmark mode** can significantly reduce total testing time by running services and benchmarks concurrently on non-overlapping GPU sets.

### When to Enable Parallel Mode

- Total available GPUs can accommodate multiple model instances without overlap
- Models that fit on independent GPU subsets (e.g., tp1 models on single GPUs, tp2 models on GPU pairs)
- **DeepSeek-V3/R1 (tp8) cannot run in parallel with anything** — it requires all 8 GPUs on an 8-GPU machine. Schedule it after all parallel tests complete.

### Parallel Planning Rules

1. **GPU allocation must not overlap** — each GPU can only be assigned to one service at a time
2. **Each service must use a unique SERVE_PORT** — explicitly set ports to avoid conflicts; never rely on defaults in parallel mode
3. **Set `CUDA_VISIBLE_DEVICES`** for each service to restrict it to its assigned GPUs
4. **Track all PIDs** — you will have multiple services running; record each PID separately
5. **Kill services individually by PID** — never use `pkill` in parallel mode, as it will kill all running services
6. **Log files must be distinguishable** — the standard naming convention already includes model+tp, but also include the port to disambiguate parallel runs

### Example: 8-GPU Machine with Qwen3 Models

| GPUs | Model                                | TP  | Port | Config |
| ---- | ------------------------------------ | --- | ---- | ------ |
| 0    | Qwen3-8B                             | 1   | 8055 | 2k1k   |
| 1    | Qwen3-8B                             | 1   | 8056 | 8k2k   |
| 2-3  | Qwen3-32B                            | 2   | 8057 | 2k1k   |
| 4-5  | Qwen3-32B                            | 2   | 8058 | 8k2k   |
| 6-7  | (idle — reserved for DeepSeek later) |     |      |        |

After all Qwen3 parallel tests complete, free all GPUs, then run DeepSeek-V3/R1 tp=8 sequentially (2k1k then 8k2k).

### Parallel Launch Commands

Each service launch must include `CUDA_VISIBLE_DEVICES` and an explicit `--port`:

```bash
# GPU 0: Qwen3-8B tp=1, port 8055
ssh <host> "nohup bash -c 'CUDA_VISIBLE_DEVICES=0 python3 -m sglang.launch_server --model-path <MODEL_PATH>/Qwen3-8B --tp 1 --host 0.0.0.0 --port 8055' > <LOG_DIR>/serve-$(date +%Y%m%d-%H%M%S)-qwen3-8b-tp1-port8055.log 2>&1 & echo \$!"

# GPU 2,3: Qwen3-32B tp=2, port 8057
ssh <host> "nohup bash -c 'CUDA_VISIBLE_DEVICES=2,3 python3 -m sglang.launch_server --model-path <MODEL_PATH>/Qwen3-32B --tp 2 --host 0.0.0.0 --port 8057' > <LOG_DIR>/serve-$(date +%Y%m%d-%H%M%S)-qwen3-32b-tp2-port8057.log 2>&1 & echo \$!"
```

**Note the `nohup bash -c '...'` pattern** — this is required so that `CUDA_VISIBLE_DEVICES` is set inside the nohup session. Without `bash -c`, the environment variable would be lost.

### Parallel Workflow

In parallel mode, the workflow changes from sequential to concurrent:

1. **Plan GPU + port allocation** — create a table mapping GPUs, models, ports, and configs
2. **Launch all services** — start each service with its `CUDA_VISIBLE_DEVICES` and port
3. **Wait for all health checks** — poll each port independently; do not proceed until all are healthy
4. **Run benchmarks** — each benchmark targets its assigned port; benchmarks can run in parallel if desired, or sequentially per-service
5. **Stop services individually** — kill by PID only; verify each GPU subset is freed

### Parallel Mode Safety Rules (in addition to general Safety Rules)

- **Never use `pkill` in parallel mode** — always kill by specific PID to avoid killing other running services
- **Never share a GPU between services** — verify `CUDA_VISIBLE_DEVICES` assignments are non-overlapping before launching
- **Always explicitly set SERVE_PORT** — never use the default port when running multiple services
- **Verify GPU isolation after launch** — after all services are healthy, run `nvidia-smi` to confirm each GPU is only used by its assigned service process
- **If one service fails** — investigate and fix that service only; do not restart or kill other running services
- **Before launching DeepSeek (tp8)** — ensure ALL other services are stopped and ALL GPUs are free; DeepSeek needs all 8 GPUs

## Full Test Sequence Example

### Sequential Mode (e.g., 2x A100 80GB)

For a machine with 2x A100 80GB (160 GB total VRAM), user provides:

- BENCH_SH=`/data/benchmark/bench.sh`, BENCH_SERVING_PY=`/data/benchmark/bench_serving.py`
- DATASET_PATH=`/data/datasets/ShareGPT_V3_unfiltered_cleaned_split.json`
- Model paths: Qwen3-8B at `/data/models/Qwen3-8B`, Qwen3-32B at `/data/models/Qwen3-32B`

Test sequence (each step is a full start→bench→stop cycle):

1. **Qwen3-8B tp=1 2k1k** → start service → bench → stop service
2. **Qwen3-8B tp=1 8k2k** → start service → bench → stop service
3. **Qwen3-32B tp=2 2k1k** → start service → bench → stop service
4. **Qwen3-32B tp=2 8k2k** → start service → bench → stop service

For each model+tp+config:

```
GPU check → start service → wait healthy → get KV cache → run bench → stop service → GPU check
```

### Parallel Mode (e.g., 8x A100 80GB)

For a machine with 8x A100 80GB, user provides:

- BENCH_SH=`/data/benchmark/bench.sh`, BENCH_SERVING_PY=`/data/benchmark/bench_serving.py`
- DATASET_PATH=`/data/datasets/ShareGPT_V3_unfiltered_cleaned_split.json`
- Model paths: Qwen3-8B at `/data/models/Qwen3-8B`, Qwen3-32B at `/data/models/Qwen3-32B`, DeepSeek-V3 at `/data/models/DeepSeek-V3`

**Phase 1: Parallel Qwen3 tests** (4 services running simultaneously)

| GPUs | Model     | TP  | Port | Config |
| ---- | --------- | --- | ---- | ------ |
| 0    | Qwen3-8B  | 1   | 8055 | 2k1k   |
| 1    | Qwen3-8B  | 1   | 8056 | 8k2k   |
| 2-3  | Qwen3-32B | 2   | 8057 | 2k1k   |
| 4-5  | Qwen3-32B | 2   | 8058 | 8k2k   |

Parallel workflow:

```
Launch all 4 services → wait all healthy → get KV cache for each → run all benchmarks → stop all by PID → GPU check
```

**Phase 2: Sequential DeepSeek tests** (after all Qwen3 services are stopped and GPUs 0-7 are fully free)

1. **DeepSeek-V3 tp=8 2k1k** → start service on all GPUs → bench → stop service
2. **DeepSeek-V3 tp=8 8k2k** → start service on all GPUs → bench → stop service

## Safety Rules

- **Never kill unknown GPU processes** — report to user instead
- **Never proceed if a required file is missing** — stop and report
- **Always verify GPU cleanup after stopping a service** — residual GPU usage indicates a problem
- **Always log everything** — service stdout/stderr and bench output must be captured to files
- **Always calculate max concurrency from KV cache** — never guess or use hardcoded values
- **Respect the 128 concurrency cap** — even if KV cache allows more
- **If service fails to start after simple fix + 1 retry**, skip the combo and report to user — do not spend time on repeated retries
- **Never assume file paths** — all paths must come from the user; use placeholders in commands
- **Always restart the service before each bench.sh run** — even same model+TP, switching configs (2k1k→8k2k) requires a restart to clear cache
- **In parallel mode: never use `pkill`** — always kill by specific PID to avoid killing other running services
- **In parallel mode: always explicitly set SERVE_PORT** — never rely on defaults when multiple services run concurrently
- **In parallel mode: always set `CUDA_VISIBLE_DEVICES`** — prevent GPU overlap between services
- **In parallel mode: verify GPU isolation after launch** — confirm each GPU is used only by its assigned service

## Notes

- Each Bash tool call is a new shell session — SSH connections are stateless per call
- `bench.sh` runs benchmarks sequentially for each concurrency level; a full run may take 30+ minutes
- SGLang and vLLM have different launch commands and log formats — always detect which framework is installed first
- Use the `ssh-tasks` skill for SSH connectivity, user discovery, and file transfer when working with remote machines
- If the user specifies a custom SERVE_PORT, adapt both the service launch and bench.sh commands
