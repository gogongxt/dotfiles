---
name: github
description: One-stop GitHub operations - connectivity check, fork repos, manage proxy, common gh workflows, and issue search/management
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

## Issue Search and Management

Use this section when the user describes a bug, feature request, question, or any problem and wants to find related GitHub issues.

### Step 1: Identify the repo

If the user doesn't specify a repo, ask. The target repo is required for all issue commands. Format: `owner/repo` (e.g. `sgl-project/sglang`).

### Step 2: Extract search keywords

From the user's description, extract the most specific keywords: error messages, function names, flag names, concepts. Avoid stop words. Example: "SGLang crashes with CUDA OOM when batch size > 32" → keywords: `CUDA OOM batch size`.

### Step 3: Search issues

Always search with proxy. Use multiple targeted queries if the first returns no useful results.

```bash
# Full-text search across open issues
source ~/.zshrc && proxy on && gh issue list --repo <owner/repo> --search "<keywords>" --limit 20 --state open

# Also search closed issues (may have resolutions)
source ~/.zshrc && proxy on && gh issue list --repo <owner/repo> --search "<keywords>" --limit 10 --state closed

# Filter by label (common labels: bug, enhancement, question, help wanted)
source ~/.zshrc && proxy on && gh issue list --repo <owner/repo> --search "<keywords>" --label bug --limit 10

# Search via GitHub API for richer results (returns title, number, state, url)
source ~/.zshrc && proxy on && gh api "search/issues?q=<keywords>+repo:<owner/repo>&per_page=10" --jq '.items[] | {number: .number, title: .title, state: .state, url: .html_url, comments: .comments}'
```

`gh issue list --search` uses GitHub's search syntax. Useful qualifiers:

| Qualifier               | Example               | Meaning             |
| ----------------------- | --------------------- | ------------------- |
| `is:open` / `is:closed` | `is:open`             | Filter by state     |
| `label:<name>`          | `label:bug`           | Filter by label     |
| `author:<user>`         | `author:octocat`      | Issues by a user    |
| `assignee:<user>`       | `assignee:octocat`    | Assigned to a user  |
| `comments:>5`           | `comments:>5`         | At least 5 comments |
| `created:>2024-01-01`   | `created:>2024-01-01` | Created after date  |

### Step 4: Read a specific issue

```bash
# View issue body and metadata
source ~/.zshrc && proxy on && gh issue view <number> --repo <owner/repo>

# View with comments (full discussion)
source ~/.zshrc && proxy on && gh issue view <number> --repo <owner/repo> --comments
```

### Step 5: Present findings

After searching, summarize for the user:

1. **Exact matches** — issues that describe the same problem (link + title + state)
2. **Related issues** — adjacent problems or partial overlaps
3. **Workarounds** — if any closed issue has a known fix, surface it
4. **Verdict** — is this a known issue? Open/closed? Has a fix been merged?

If no issues found: try broader keywords, then suggest the user may have hit an unreported bug and offer to help draft a new issue.

### Step 6: Create a new issue (only when asked)

**Never create an issue without explicit user approval.** Before running `gh issue create`, show the user:

- Proposed title
- Proposed body (steps to reproduce, expected vs actual behavior, environment info)

Wait for confirmation, then:

```bash
source ~/.zshrc && proxy on && gh issue create \
  --repo <owner/repo> \
  --title "<title>" \
  --body "<body>" \
  --label bug
```

For a feature request, use `--label enhancement` instead of `bug`.

## Notes

- **Every Bash call is a new shell** — always chain `source ~/.zshrc && proxy on &&` before network commands
- Local git operations (checkout, commit, add, diff) do NOT need proxy
- Remote operations (push, pull, fetch, gh api, gh pr create, gh repo fork) DO need proxy
- Use `proxy on` explicitly rather than `pt` (toggle) to avoid accidentally turning proxy off
- When forking, `--clone=true` will clone the fork; use `--clone=false` if you only want the remote fork
- Always clone repos to `~/Projects/` directory
- **IMPORTANT:** Never submit a PR directly. Before running `gh pr create`, always present the PR title, body, and full diff to the user and wait for explicit confirmation
- **IMPORTANT:** Never create or comment on issues without explicit user approval
