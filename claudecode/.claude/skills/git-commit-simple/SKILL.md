---
name: git-commit-simple
description: Commit changes with a simple, concise conventional-commit message — just a type prefix and a short one-line subject in English. Use when the user says "commit", "提交", "git commit", or wants to save changes with a brief message. Keeps messages short: no long body, no co-author trailers, no boilerplate.
user-invocable: true
---

# Simple Git Commit

Commit staged (or all) changes with a **short** conventional-commit message.

## Message format

```
<type>: <short subject in english>
```

- **One line only.** No body paragraph, no bullet lists, no co-author trailers.
- Subject is a **few keywords**, lowercase after the type, no trailing period.
- Keep it to ~50–60 chars; a second line is acceptable only if one line can't fit.

### Allowed types

| Type       | Use for                              |
| ---------- | ------------------------------------ |
| `feat`     | new feature / new capability         |
| `add`      | add a file, config, or small thing   |
| `fix`      | bug fix                              |
| `refactor` | code restructure, no behavior change |
| `docs`     | documentation only                   |
| `chore`    | build, deps, tooling, misc           |
| `test`     | tests only                           |

If unsure, `feat` for new behavior, `fix` for corrections, `chore` for the rest.

## Examples

```
feat: add dcl skill for kunpeng cr
fix: handle empty revision id in update
add: proxy config to settings
refactor: split diff logic into helper
docs: update readme install steps
chore: bump deps
```

## Workflow

1. See what changed:
   ```bash
   git status -s
   git diff --stat
   ```
2. Stage. Stage only what the user asked for; if they said "commit everything",
   `git add -A`. Otherwise stage explicitly (`git add <paths>`).
3. Commit with the short message:
   ```bash
   git commit -m "feat: add dcl skill for kunpeng cr"
   ```

## CRITICAL: Pre-commit hook failures — stop, do not self-fix

Repos often run `pre-commit` hooks on `git commit` (lint, format, type-check, tests).
These hooks may **fail** the commit, and some hooks (e.g. formatters) may also
**auto-modify files**. When the commit fails:

1. **Stop immediately.** Do NOT retry the commit, do NOT run the hook's fix command,
   and do NOT edit the code to "fix" whatever the hook complained about.
2. **Report the raw error to the user** — show the full stdout/stderr that `git commit`
   returned, especially the pre-commit section. Quote it verbatim.
3. Note whether any files were auto-modified by a hook (check `git status -s` / the
   hook output) and tell the user, but do not stage or re-commit on your own.
4. Wait for the user to decide what to do (fix manually, adjust the hook, skip with
   `--no-verify` only if they ask, etc.).

Never silently patch code, run `git add -A` + re-commit, or pass `--no-verify` to
bypass a failing hook without explicit user approval.

## Rules

- **English only**, lowercase subject, imperative mood ("add" not "added").
- **No co-author trailer**, no `Co-Authored-By`, no `🤖 Generated with` line.
- **No long body.** If the change is complex enough to need explanation, still keep
  the message to one line; the diff explains the rest.
- Don't amend or rewrite history unless asked.
- If there's nothing staged and the user didn't say to stage all, ask before
  `git add -A`.
