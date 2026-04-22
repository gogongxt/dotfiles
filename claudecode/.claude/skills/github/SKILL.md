---
name: github
description: One-stop GitHub operations - connectivity check, fork repos, manage proxy, and common gh workflows
user-invocable: true
---

# GitHub Operations

A one-stop skill for GitHub operations: connectivity checks, forking repos, proxy management, and common gh workflows.

## CRITICAL: Proxy Must Be Loaded Per Command

Each Bash tool call runs in a **new shell session** — environment variables do NOT persist between calls. Every command that needs network access MUST load proxy inline:

```bash
source ~/.zshrc && proxy on && <your-command>
```

Do NOT assume proxy is active from a previous call. Always chain `source ~/.zshrc && proxy on &&` before every network-dependent command.

## Step 1: Proxy Setup

Check proxy status and enable if needed:

```bash
source ~/.zshrc && proxy status
```

If proxy is off and you need it, toggle it on:

```bash
source ~/.zshrc && proxy on
```

Quick reference:

- `source ~/.zshrc && proxy on` — turn proxy on
- `source ~/.zshrc && proxy off` — turn proxy off
- `source ~/.zshrc && proxy toggle` — toggle proxy
- `source ~/.zshrc && proxy status` — check current status

## Step 2: Connectivity Check

Run these checks in order (each includes proxy loading):

1. **Is `gh` installed?** `source ~/.zshrc && proxy on && command -v gh && gh --version`
2. **Is `gh` authenticated?** `source ~/.zshrc && proxy on && gh auth status`
3. **Can connect to GitHub API?** `source ~/.zshrc && proxy on && gh api user --jq '.login'`

## Step 3: Common Operations

### Fork a Repo and Make Changes

```bash
# 1. Check and enable proxy
source ~/.zshrc && proxy on

# 2. Fork the repo (creates fork under your account and clones it)
source ~/.zshrc && proxy on && cd ~/Projects && gh repo fork <owner/repo> --clone=true

# 3. Navigate into the cloned repo
cd ~/Projects/<repo-name>

# 4. Create a feature branch
git checkout -b <branch-name>

# 5. Make changes, commit, and push
git add -A && git commit -m "your message"
source ~/.zshrc && proxy on && git push -u origin <branch-name>

# 6. Create a pull request (DO NOT submit directly!)
# Before creating the PR, present the following to the user for confirmation:
#   - PR title
#   - PR body/description
#   - Explain diff of changes (git diff <upstream-branch>...HEAD)
# Wait for the user's explicit approval before running gh pr create.
source ~/.zshrc && proxy on && gh pr create --title "PR title" --body "PR description"
```

### Other Useful Commands

Each command below requires `source ~/.zshrc && proxy on &&` prefix when network access is needed:

| Task            | Command                          |
| --------------- | -------------------------------- |
| List my repos   | `gh repo list --limit 20`        |
| View repo info  | `gh repo view <owner/repo>`      |
| Check PR status | `gh pr status`                   |
| List open PRs   | `gh pr list --repo <owner/repo>` |
| Checkout a PR   | `gh pr checkout <number>`        |
| Merge a PR      | `gh pr merge <number>`           |
| Create a gist   | `gh gist create <file>`          |
| View issue      | `gh issue view <number>`         |

## Notes

- **Every Bash call is a new shell** — always chain `source ~/.zshrc && proxy on &&` before network commands
- Local git operations (checkout, commit, add, diff) do NOT need proxy
- Remote operations (push, pull, fetch, gh api, gh pr create, gh repo fork) DO need proxy
- Use `proxy on` explicitly rather than `pt` (toggle) to avoid accidentally turning proxy off
- When forking, `--clone=true` will clone the fork; use `--clone=false` if you only want the remote fork
- Always clone repos to `~/Projects/` directory
- **IMPORTANT:** Never submit a PR directly. Before running `gh pr create`, always present the PR title, body, and full diff to the user and wait for explicit confirmation
