---
name: benchmark-allinone
description: Run online LLM benchmark evaluations on the internal LLM Benchmark Platform
user-invocable: true
disable-model-invocation: true
---

documents please read @/nfs/gogongxt/Projects/llm-benchmark-online/API.md

platform: https://ifx-llm-benchmark.intra.xiaojukeji.com/

## TPM ladder for the avg-TTFT SLO knee

For "find the highest TPM tier whose avg TTFT still meets SLO", use
`scripts/run_tpm_ladder.sh` (see API.md §7). It creates one
`timestamp_replay` task per tier, polls to terminal, and prints a summary
table with an ok/OVER/ABORT verdict.

```bash
TARGET_HOST=<host> TARGET_PORT=<port> MODEL_PATH=<platform-reachable model dir> \
WINDOW=7200 DATASET=dsv4_flash_mixed_length OUT_LEN=1 \
  bash scripts/run_tpm_ladder.sh 1200 1000 800 600
```

Run full windows (7200s): the replay datasets ramp up in their second half,
so short windows materially understate load.
