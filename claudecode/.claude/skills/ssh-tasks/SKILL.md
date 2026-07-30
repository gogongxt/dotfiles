---
name: ssh-tasks
description: Execute code on remote GPU machines via SSH - connectivity check, GPU status, env validation, script/command execution
user-invocable: true
---

# SSH Remote Task Execution

Execute code on remote GPU machines when the local dev machine lacks GPUs or has different GPU types. Handles SSH connectivity, GPU selection, environment validation, and remote execution.

## When to Use

- Local machine has no GPU or incompatible GPU for the task
- Need to run training, inference, or benchmarking on a remote GPU server
- Running sglang/vllm serving, PyTorch training scripts, or CUDA-dependent code remotely

## Workflow

Always follow these steps **in order**. Do not skip steps or assume previous checks passed.

### Step 1: Gather Target Info

Use the SSH connection command the user provides — whether it's SSH key auth, an SSH alias, or `sshpass` with a password. If the user hasn't given the connection details, ask for them. Also confirm:

- **Task type**: script file path, or inline command
- **GPU requirements**: how many GPUs, minimum VRAM, specific GPU model if needed (e.g. "need 2x A100 80GB")
- **Environment**: required packages to verify (e.g. sglang, vllm, torch). Remote machines are typically Docker containers with pre-installed environments — just verify, don't manage

### Step 2: SSH Connectivity Check

Test the connection with the SSH command the user gave:

```bash
ssh -o ConnectTimeout=3 <user-provided-ssh-target> "echo 'SSH OK'"
```

If it fails, report it and ask the user how to proceed.

### Step 3: GPU Status Check

Check remote GPU availability and pick idle GPUs:

```bash
ssh -p <port> <user>@<host> "nvidia-smi --query-gpu=index,name,memory.total,memory.used,memory.free,utilization.gpu --format=csv,noheader,nounits"
```

**GPU Selection Rules:**

1. Prefer GPUs with **low utilization** (< 10%) and **high free memory** (> 80% of total)
2. If multiple GPUs qualify, pick the ones with the most free memory
3. If no GPU meets the requirements, **report the status to the user and ask how to proceed** — do NOT silently use occupied GPUs
4. Set `CUDA_VISIBLE_DEVICES` based on selected GPUs for the execution command

Also check if any processes are holding GPU memory:

```bash
ssh -p <port> <user>@<host> "nvidia-smi --query-compute-apps=pid,gpu_uuid,used_memory --format=csv,noheader"
```

### Step 4: Environment Validation

Remote machines are typically **Docker containers** with pre-installed environments (sglang, vllm, torch, etc.). The goal is to **verify** the environment matches requirements, not manage it. Run all checks via SSH:

```bash
# Check Python version
ssh -p <port> <user>@<host> "python --version"

# Check installed packages relevant to the task
ssh -p <port> <user>@<host> "pip list | grep -iE 'torch|sglang|vllm|transformers|ray'"

# Check CUDA version and torch compatibility
ssh -p <port> <user>@<host> "python -c 'import torch; print(f\"torch={torch.__version__}, cuda={torch.version.cuda}, gpu_available={torch.cuda.is_available()}')'"

# Check available GPU count visible to PyTorch
ssh -p <port> <user>@<host> "python -c 'import torch; print(f\"gpu_count={torch.cuda.device_count()}\")'"

# Check system CUDA/driver info
ssh -p <port> <user>@<host> "nvcc --version 2>/dev/null || cat /usr/local/cuda/version.txt 2>/dev/null"
```

If the remote uses conda (rare, user will specify), adapt to `conda run -n <env_name>` prefix. Otherwise assume the default Python environment is the target. If a required package is missing, report to the user — **do not `pip install` without explicit approval**.

### Step 5: Transfer Files (if needed)

**NFS Shared Paths:** If the user mentions NFS or the script path starts with `/nfs/`, the files are already accessible on the remote machine at the **same absolute path**. No transfer needed:

- Local path: `/nfs/gogongxt/project/train.py`
- Remote path: `/nfs/gogongxt/project/train.py` (identical)

Just verify the file exists on remote:

```bash
ssh -p <port> <user>@<host> "ls -la /nfs/gogongxt/project/train.py"
```

**Non-NFS Paths:** If files are not on shared storage, transfer is needed. Use the same SSH connection the user provided (prepend `sshpass` only if their command did):

```bash
# Copy a script
scp -P <port> <local_script_path> <user>@<host>:<remote_dir>/

# Or copy an entire project directory
rsync -avz -e "ssh -p <port>" <local_dir>/ <user>@<host>:<remote_dir>/
```

SCP destination dir best is `~/gogongxt`. mkdir it before transfer.

Verify the file arrived:

```bash
ssh -p <port> <user>@<host> "ls -la <remote_dir>/<script_name>"
```

### Step 6: Execute

**CRITICAL: Always use absolute paths.** Never use relative paths in any SSH execution command. This means:

- Script path: `/full/path/to/script.py`, NOT `./script.py` or `script.py`
- Working directory: specify full path like `/nfs/gogongxt/project`, NOT `~/project` or `./project`
- Log file path: `/full/path/to/output.log`, NOT `output.log`
- Model path, data path, and any file references in arguments: always absolute

Relative paths are unreliable over SSH because each SSH call starts in the remote's default `$HOME`, and `cd` + relative path combinations are fragile.

**CRITICAL: Verify file exists before execution.** Never assume the script path is correct — always check first:

```bash
# Check if script exists on remote (use absolute path)
ssh -p <port> <user>@<host> "test -f /full/path/to/script.py && echo 'EXISTS' || echo 'NOT_FOUND'"

# If not found, report to user and ask for correct path
# Do NOT proceed with execution if file check fails
```

After file verification, build and run the command. Always use `nohup` for long-running tasks so they survive SSH disconnects.

```bash
# For a script (short-running, wait for output) — use absolute paths
ssh -p <port> <user>@<host> "cd /full/path/to/project && CUDA_VISIBLE_DEVICES=<selected_gpus> python /full/path/to/project/script.py <args>"

# For a long-running task (background, no hang) — use absolute paths for everything
ssh -p <port> <user>@<host> "cd /full/path/to/project && nohup bash -c 'CUDA_VISIBLE_DEVICES=<selected_gpus> python /full/path/to/project/script.py <args>' > /full/path/to/project/output.log 2>&1 & echo \$!"
```

For background tasks, capture the PID and check status:

```bash
# Check if process is still running
ssh -p <port> <user>@<host> "ps -p <pid> -o pid,stat,etime,cmd"

# Tail the log
ssh -p <port> <user>@<host> "tail -n 50 <log_file>"

# Check GPU usage while running
ssh -p <port> <user>@<host> "nvidia-smi"
```

## Important Constraints

### Safety

- **Never use `sudo` on remote machines** — if elevated privileges are needed, ask the user
- **Never kill remote processes you didn't start** — if GPU memory is occupied, report and ask the user
- **Never modify remote `.bashrc` or shell configs** — use inline env setup only
- **Always confirm before installing packages** — `pip install` changes the remote environment

### Reliability

- **ALWAYS verify file exists before execution** — check with `test -f <path>` or `ls -la <path>` on remote. If file not found, ask user for correct path. Never execute with a guessed path.
- **Always set `CUDA_VISIBLE_DEVICES`** explicitly — never let the script grab all GPUs blindly
- **ALWAYS use absolute paths** — for scripts, working directories, log files, model paths, data paths, and any file references. Never use relative paths (`./script.py`, `output.log`) over SSH. Each SSH call has an independent shell with unpredictable `$PWD`, making relative paths unreliable. Example: use `/nfs/gogongxt/project/train.py` not `train.py` or `~/project/train.py`
- **Use `nohup` + background for anything that takes more than a few minutes** — SSH timeouts will kill foreground processes
- **Log output to a file** — always redirect stdout and stderr so you can check results later
- **Verify file transfer** — after `scp`/`rsync`, confirm the file exists and has the expected size on the remote

### Execution Strategy

- **Default: use `python` directly** — remote Docker containers have pre-installed environments, no need for `conda run` or `venv` activation
- If the remote does use conda (user will specify), adapt to `conda run -n <env_name>` prefix
- **For multi-GPU tasks** (e.g. tensor parallel), verify NCCL/Ray setup if needed before launching
- **For serving tasks** (sglang/vllm), check that the target port is not already in use:

```bash
ssh -p <port> <user>@<host> "ss -tlnp | grep <serve_port>"
```

## SSH Alias Support

If the user provides an SSH alias (from `~/.ssh/config`), use it directly — no need to specify user/host/port separately:

```bash
ssh my-gpu-server "nvidia-smi"
```

## Notes

- Each Bash tool call is a new shell session — SSH connections are stateless per call
- Always use `-o ConnectTimeout=10` for quick failure detection
- For `scp`, note the capital `-P` for port (unlike ssh's lowercase `-p`)
- If SSH connection drops during a background task, the process survives (nohup) — just reconnect to check logs
- Report remote GPU status in a human-readable table before executing, so the user can verify the selection
- **Connection method:** Use whatever SSH command the user gives you. Don't guess usernames, passwords, or default to `sshpass`/`didi` — if connection details aren't provided, ask.
- **NFS shared paths:** Paths starting with `/nfs/` are shared between local and remote — use the same absolute path on both sides, no transfer needed.
- **CRITICAL:** Always verify file exists on remote before execution. Use `test -f <path>` check. Never execute with an unverified path.
- **CRITICAL:** Always use absolute paths for everything over SSH — scripts, working directories, log files, model paths, data paths. Relative paths break because each SSH call is an independent shell session with unpredictable `$PWD`.
