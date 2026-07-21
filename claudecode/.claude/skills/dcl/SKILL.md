---
name: dcl
description: Didi internal code review (CR) tool on the kunpeng platform — the Didi equivalent of `gh` for PRs. Use `dcl` to create, update, list, inspect, land, and revert code reviews (CRs). Trigger on "dcl", "提交 cr", "创建 cr", "更新 cr", "kunpeng", "code review", "提交代码", or any CR/revision workflow on kunpeng.xiaojukeji.com.
user-invocable: true
---

# DCL — Didi Kunpeng Code Review Tool

`dcl` is Didi's EE client for the **kunpeng** code review platform. It is the internal
equivalent of `gh` for pull requests: you use it to create and update **CRs**
(revisions) instead of PRs. Revisions live at `https://kunpeng.xiaojukeji.com`.

- Create a CR → `dcl -c` (equivalent to `gh pr create`)
- Update a CR → `dcl -u <revisionID>` (push new commits onto an existing review)
- A CR is identified by a **revision ID** (a number, e.g. `643821`), shown in the
  returned URL: `https://kunpeng.xiaojukeji.com/view/revision/<revisionID>`.

## CRITICAL: No proxy needed

Kunpeng (`xiaojukeji.com` / `didichuxing.com`) is an **internal service**. Do **NOT**
load the proxy for `dcl` commands — it is an intranet host and may be unreachable or
slower through the proxy. Run `dcl` directly. (This differs from `gh`, which needs
`proxy on`.)

## CRITICAL: Confirm before creating/updating a CR

Creating or updating a CR is an outward-facing action (it notifies reviewers and
publishes your diff to the team). **Never run `dcl -c` or `dcl -u` without explicit
user approval.** Before submitting, present to the user:

- The **target branch** (default `master`) — confirm this is intended
- A summary of the **commits / diff** that will be included: run
  `git log <target>..HEAD --oneline` and `git diff <target>...HEAD --stat`
- Whether to create new (`-c`) or update an existing revision (`-u <ID>`)
- Interactive vs non-interactive mode (see below)

Wait for the user's explicit go-ahead, then run the command.

## Interactive vs non-interactive mode

`dcl diff` defaults to **interactive mode**, which opens a TUI to edit the CR title,
summary, and reviewers. A TUI does not work well in this agent environment.

- **Prefer non-interactive mode** with `-n`. You then modify the CR title, summary,
  and reviewers on the web page after creation:
  ```
  Tips: non-interactive mode is enabled, you can modify CR title, summary or reviewer on the web page
  ```
- Only use interactive mode (omit `-n`) if the user explicitly asks for it.

## Core workflows

### 1. See what `dcl diff` will select (always do this first)

Before creating or updating, check which repo you're in and which commits will be
sent for review:

```bash
dcl which
```

Use `dcl which --show-base` to print only the base commit, and `-t <branch>` to check
a non-default target branch. The default target branch is `master`.

### 2. Create a new CR

```bash
dcl diff master -c -n
```

Typical successful output:

```
-----start lint-----
[INFO] Dcl lint use local config:  ./.arclint
[INFO] To use specified config, please use --config-path=PATH_TO_CONFIG
[INFO] Lint config not found, ignore lint step
-----finish lint-----
Tips: non-interactive mode is enabled, you can modify CR title, summary or reviewer on the web page
Waiting for git push to complete
Dcl call kunpeng API to create or update your revision
Your revision link: https://kunpeng.xiaojukeji.com/view/revision/643821
```

- The last line's number is the **revision ID** — record it and tell the user.
- `master` is the target branch; change it (e.g. `dcl diff dev -c -n`) if the PR
  targets another branch.
- Add `-d` to create a **draft** revision (`dcl diff master -c -n -d`).
- Add `--nolint` to skip the lint step if it's blocking and the user accepts the risk.
- Add `-i` / `--ignore-untracked` to ignore untracked files.

### 3. Update an existing CR (new commits)

After adding new commits to the branch, push them onto an existing review with its
revision ID:

```bash
dcl diff -u 643821 -n
```

(`dcl diff` with no `-c`/`-u` auto-decides create-vs-update, but pass `-u <ID>`
explicitly when you know the revision to avoid ambiguity.)

### 4. List your CRs

```bash
dcl list            # your need_review + draft revisions
dcl ls              # alias
dcl list -r 643821  # patchsets of a revision
dcl list -r 643821 -p 3   # commits of patchset 3 of the revision
```

### 5. Inspect a CR on the web

Open the revision in a browser (or just give the user the link):

```
https://kunpeng.xiaojukeji.com/view/revision/<revisionID>
```

### 6. Pull a CR's code locally

Check out a CR's code into a new branch `kp-<revisionID>-<timestamp>`:

```bash
dcl pull <revisionID>
```

### 7. Land (merge) a CR

```bash
dcl land                     # land the CR for the current branch
dcl land --revision 643821   # land a specific revision
```

### 8. Revert a closed CR

Revert all commits of a closed revision from the current branch:

```bash
dcl revert 643821
```

### 9. Abandon a CR

Abandon a `need_review` or `draft` revision:

```bash
dcl diff --abandon 643821
```

## Command reference

| Task                        | Command                          |
| --------------------------- | -------------------------------- |
| What will be reviewed       | `dcl which`                      |
| Create a CR (non-interact)  | `dcl diff master -c -n`          |
| Create a draft CR           | `dcl diff master -c -n -d`       |
| Update a CR with new commit | `dcl diff -u <ID> -n`            |
| List my CRs                 | `dcl list`                       |
| Patchsets of a CR           | `dcl list -r <ID>`               |
| Commits of a patchset       | `dcl list -r <ID> -p <n>`        |
| Pull a CR locally           | `dcl pull <ID>`                  |
| Land (merge) a CR           | `dcl land --revision <ID>`       |
| Revert a closed CR          | `dcl revert <ID>`                |
| Abandon a CR                | `dcl diff --abandon <ID>`        |
| Skip lint on create/update  | `dcl diff master -c -n --nolint` |
| Ignore untracked files      | `dcl diff master -c -n -i`       |

Full flags for `dcl diff` (create/update):

- `-c, --create` — create a new revision
- `-u, --update <revisionID>` — update an existing revision
- `-n, --non-interactive` — non-interactive mode (preferred here)
- `-d, --draft` — create/update as a draft
- `-i, --ignore-untracked` — ignore untracked files
- `--nolint` — skip lint step
- `-p, --parent <int>` — parent CR ID to base the new revision on
- `-t, --task <taskID>` — attach a task ID
- `--abandon <revisionID>` — abandon a revision
- `--resolved` — submit all resolved draft comments (default true)
- `--trace` — show trace info

## Common errors

- **Lint blocks creation**: the `-----start lint-----` block runs automatically.
  If lint fails and the user wants to proceed anyway, retry with `--nolint` (accept
  the lint risk explicitly).
- **No CR found to update**: `dcl list` shows only your `need_review`/`draft`
  revisions. Confirm the revision ID is correct and belongs to you.
- **Wrong target branch**: `dcl diff` defaults to `master`. Always pass the intended
  target branch explicitly (`dcl diff <branch> -c -n`).
- **TUI hangs in interactive mode**: if a command seems to hang, it likely opened the
  interactive editor. Kill it and rerun with `-n`.

## Notes

- **No proxy** for any `dcl` command — kunpeng is internal.
- Each Bash tool call is a new shell; local git ops (`git log`, `git diff`) need no
  special setup and no proxy.
- Always read the full output of `dcl diff -c`/`-u`: the revision link/ID is on the
  last line and must be surfaced to the user.
- **Never create or update a CR without explicit user approval** — show the target
  branch, commit list, and diff stat first.
- **Prefer `-n` (non-interactive)** in this environment.
