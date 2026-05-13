---
name: transfer
description: Transfer files between machines via SSH - supports direct transfer, jump host relay, and progress monitoring
user-invocable: true
---

# File Transfer via SSH

Transfer files/directories between machines through SSH. Supports direct transfer and jump host (bastion) relay scenarios. Handles large file monitoring, parallel transfers, and verification.

## When to Use

- Transfer model weights, docker images, datasets, or scripts to a remote machine
- Need to go through a jump host / bastion to reach the target machine
- Transfer large files (10G+) that need progress monitoring
- User explicitly invokes `/transfer`

## Required User Inputs

Before starting, confirm with the user:

| Parameter    | Description                                              | Example                   |
| ------------ | -------------------------------------------------------- | ------------------------- |
| Source files | File/directory paths to transfer (on local or jump host) | `/path/to/<DIR_NAME>`     |
| Target host  | Destination machine address                              | `<USER>@<HOST>`           |
| Target port  | SSH port (default: 22)                                   | `22`                      |
| Target path  | Destination directory on target machine                  | `/<TARGET_DIR>`           |
| Jump host    | (Optional) Bastion host for relay transfers              | `<JUMP_USER>@<JUMP_HOST>` |
| Jump port    | (Optional) Jump host SSH port (default: 22)              | `22`                      |

If the user does not specify a target path, ask — do not guess.

## Transfer Scenarios

### Scenario A: Direct Transfer (no jump host)

Local machine can reach target directly.

### Scenario B: Jump Host Relay

Local machine → jump host → target machine. The jump host has access to both the source files (via NFS or local storage) and the target machine.

**Key question: Does the jump host share the same NFS as the local machine?**

- If YES: No need to transfer files from local to jump host. Just SCP from jump host to target directly.
- If NO: Need to first SCP from local to jump host, then SCP from jump host to target.

Common pattern: `/nfs/ofs-llm-ssd/` paths are shared between local and jump host machines. Verify this before starting.

## Workflow

### Step 1: Connectivity Check

Test SSH connectivity to each machine in the chain:

```bash
# Direct: test target
ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -p <port> <user>@<host> "echo OK"

# Jump host: test both hops
ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -p <jump_port> <jump_user>@<jump_host> "echo 'Jump host OK'"
ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -p <jump_port> <jump_user>@<jump_host> "ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -p <target_port> <target_user>@<target_host> 'echo Target OK'"
```

If connection fails, report to user — do not proceed.

### Step 2: Verify Source Files

Check that all source files/directories exist and get their sizes:

```bash
# If files are on local machine
ls -lh <source_path>
du -sh <source_path>

# If files are on NFS shared with jump host
ssh -p <jump_port> <jump_user>@<jump_host> "ls -lh <source_path> && du -sh <source_path>"
```

Report total transfer size to the user.

### Step 3: Check Target Disk Space

Verify the target machine has enough disk space:

```bash
# Direct
ssh -p <port> <user>@<host> "df -h <target_path>"

# Via jump host
ssh -p <jump_port> <jump_user>@<jump_host> "ssh -p <target_port> <target_user>@<target_host> 'df -h <target_path>'"
```

If not enough space, report to user and stop.

### Step 4: Create Target Directory

```bash
# Direct
ssh -p <port> <user>@<host> "mkdir -p <target_path>"

# Via jump host
ssh -p <jump_port> <jump_user>@<jump_host> "ssh -p <target_port> <target_user>@<target_host> 'mkdir -p <target_path>'"
```

### Step 5: Launch Transfers

Launch SCP for each file/directory. For multiple files, run them **in parallel** as background processes on the source machine.

**Direct transfer:**

```bash
# Single file
scp -o StrictHostKeyChecking=no -P <port> <source_file> <user>@<host>:<target_path>/

# Directory
scp -o StrictHostKeyChecking=no -r -P <port> <source_dir> <user>@<host>:<target_path>/
```

**Jump host relay (SCP from jump host to target):**

```bash
ssh -p <jump_port> <jump_user>@<jump_host> "nohup scp -o StrictHostKeyChecking=no -r <source_path> <target_user>@<target_host>:<target_path>/ > /tmp/transfer_<name>.log 2>&1 & echo PID=\$!"
```

**Parallel launch pattern** — launch multiple SCPs at once from the jump host:

```bash
ssh -p <jump_port> <jump_user>@<jump_host> "
  nohup scp -o StrictHostKeyChecking=no -r <source1> <target_user>@<target_host>:<target_path>/ > /tmp/transfer_1.log 2>&1 &
  nohup scp -o StrictHostKeyChecking=no -r <source2> <target_user>@<target_host>:<target_path>/ > /tmp/transfer_2.log 2>&1 &
  nohup scp -o StrictHostKeyChecking=no -r <source3> <target_user>@<target_host>:<target_path>/ > /tmp/transfer_3.log 2>&1 &
  echo 'All SCPs launched'
"
```

### Step 6: Monitor Progress

For large transfers, periodically check progress by querying file sizes on the target:

```bash
# Direct
ssh -p <port> <user>@<host> "du -sh <target_path>/* 2>/dev/null"

# Via jump host
ssh -p <jump_port> <jump_user>@<jump_host> "ssh -p <target_port> <target_user>@<target_host> 'du -sh <target_path>/* 2>/dev/null'"
```

Also check if SCP processes are still running:

```bash
# On jump host
ssh -p <jump_port> <jump_user>@<jump_host> "ps aux | grep scp | grep -v grep | wc -l"
```

**Monitoring cadence:**

- For small files (<1G): no monitoring needed, just verify completion
- For medium files (1G-10G): check every 5 minutes
- For large files (10G+): check every 10 minutes
- For very large files (50G+): check every 10-20 minutes

Use background Bash tasks (`run_in_background: true`) with `sleep` for periodic monitoring to avoid blocking the conversation.

**Present progress as a table** each time:

| File            | Total Size | Transferred | %    | Status       |
| --------------- | ---------- | ----------- | ---- | ------------ |
| <FILE_NAME>.tar | 28G        | 14G         | 50%  | Transferring |
| <DIR_NAME>/     | 16G        | 16G         | 100% | Complete     |

### Step 7: Verify Completion

After all SCP processes have exited, compare source and target sizes to confirm transfer completeness.

**Compare source and target sizes with `du -sh`:**

```bash
# Source side (local or jump host)
du -sh <source_path>/*

# Target side — Direct
ssh -p <port> <user>@<host> "du -sh <target_path>/* 2>/dev/null"

# Target side — Via jump host
ssh -p <jump_port> <jump_user>@<jump_host> "ssh -p <target_port> <target_user>@<target_host> 'du -sh <target_path>/* 2>/dev/null'"
```

**Present comparison as a table:**

| File             | Source Size | Target Size | Match | Status   |
| ---------------- | ----------- | ----------- | ----- | -------- |
| <FILE_NAME>.tar  | 28G         | 28G         | Yes   | Complete |
| <DIR_NAME>/      | 16G         | 16G         | Yes   | Complete |
| <FILE_NAME>.json | 642M        | 640M        | ~Yes  | Complete |

_Note: Small differences (<1%) are normal due to filesystem block size differences. Large discrepancies indicate incomplete or failed transfer — report to user._

**Also verify SCP processes have exited:**

```bash
# On jump host
ssh -p <jump_port> <jump_user>@<jump_host> "ps aux | grep scp | grep -v grep | wc -l"
# Expected: 0
```

**For directories, also check file count matches:**

```bash
# Source
find <source_dir> -type f | wc -l

# Target — Direct
ssh -p <port> <user>@<host> "find <target_path>/<dir> -type f | wc -l"

# Target — Via jump host
ssh -p <jump_port> <jump_user>@<jump_host> "ssh -p <target_port> <target_user>@<target_host> 'find <target_path>/<dir> -type f | wc -l'"
```

Report final status to the user with a summary table showing all files transferred, source vs target sizes, and whether they match.

## Speed Estimation

Typical transfer speeds to help estimate completion time:

| Network Type     | Speed per stream | Time for 100G |
| ---------------- | ---------------- | ------------- |
| Same datacenter  | 50-100 MB/s      | 15-30 min     |
| Cross datacenter | 10-30 MB/s       | 1-3 hours     |
| WAN / VPN        | 2-10 MB/s        | 3-15 hours    |

Multiple parallel streams share bandwidth. When one stream finishes, remaining streams may speed up.

## Safety Rules

- **Always verify disk space before transfer** — do not fill up the target disk
- **Always create target directory before SCP** — SCP will fail if the directory doesn't exist
- **Use `nohup` for all large transfers** — ensures transfer survives SSH disconnects
- **Redirect output to log files** — capture stdout/stderr for debugging
- **Never delete existing files on target** — if a file already exists, report to user
- **Verify completion** — check file sizes match and SCP processes have exited before reporting success
- **Report transfer speed estimate** — help the user understand how long to wait

## Error Handling — STOP and Report

When any of the following situations occur, **immediately stop all operations and report to the user**. Do NOT attempt to fix, retry, or work around the issue on your own:

- **SSH connection fails** — do not try alternative ports, users, or hosts without asking the user
- **Source file not found** — do not guess or search for similar paths; ask the user for the correct path
- **Target disk space insufficient** — do not delete files on target to make room; ask the user how to proceed
- **Target file/directory already exists** — do not overwrite; report the conflict and ask the user
- **SCP transfer fails or gets stuck** — do not retry automatically; check the log and report the error
- **File size mismatch after transfer** — do not re-transfer; report the discrepancy to the user
- **Unexpected SCP process behavior** (e.g., process disappeared, wrong file count) — stop and report
- **Permission denied on target** — do not use `sudo` or change permissions; report to the user

**Rule of thumb: When in doubt, stop and ask.** Never take destructive or speculative actions. The user can always provide guidance, but cannot undo an unauthorized operation.

## Common Patterns

### Transfer model files through a jump host

```
User: "Transfer /path/to/<DIR_NAME> to <TARGET_HOST>:<TARGET_DIR> via <JUMP_USER>@<JUMP_HOST>"

Steps:
1. SSH to jump host, verify file exists on NFS
2. SSH from jump host to target, verify connectivity and disk space
3. mkdir -p <TARGET_DIR> on target
4. nohup scp -r from jump host to target in background
5. Monitor every 10 min with du -sh on target
6. Verify completion
```

### Transfer multiple small files directly

```
User: "Copy <FILE_1> and <FILE_2> to <USER>@<HOST>:<TARGET_DIR>/"

Steps:
1. Verify files exist locally
2. ssh <USER>@<HOST> "mkdir -p <TARGET_DIR>"
3. scp <FILE_1> <FILE_2> <USER>@<HOST>:<TARGET_DIR>/
4. Verify: ssh <USER>@<HOST> "ls -la <TARGET_DIR>/<FILE_1> <TARGET_DIR>/<FILE_2>"
```

## Notes

- For SSH authentication issues, use `/ssh-tasks` skill to get the full SSH access methods and guidance
- NFS shared paths (`/nfs/`) are typically identical between local and jump host — verify, then skip the local→jump transfer
- Each Bash tool call is a new shell session — SSH connections are stateless per call
- For jump host scenarios, all SCP commands run ON the jump host (it has access to both source and target)
- Use `-o StrictHostKeyChecking=no` to avoid interactive host key prompts
- For `scp`, note the capital `-P` for port (unlike ssh's lowercase `-p`)
