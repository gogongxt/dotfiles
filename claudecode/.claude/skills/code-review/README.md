# code-review (user skill)

A migration of the `/code-review` skill bundled inside the Claude Code binary,
with one deliberate addition: **the reviewer can be pinned to a model**.

## How it runs

The skill declares `context: fork`, so the whole review executes inside one
subagent — the caller sees a single reviewer, not a fleet. That matches the
built-in, which also registers `getContext → "fork"`.

Inside that fork, the effort ladder mirrors the built-in's *default* model-family
cell (`o48-high-v1` / `o48-xhigh-v1` / `max`):

| Level | Shape |
|---|---|
| `low` | one diff pass, hunk-only, no verify |
| `medium` / `high` | 8 angles worked inline, dedup only, no verify |
| `xhigh` | 10 angles inline, dedup, then a self gap-sweep |
| `max` | 10 parallel finders → 1-vote verify → gap sweep |

Only `max` spawns subagents. Medium and high deliberately run **inline** —
that is what the built-in does for a model it does not recognise, and it is
why the built-in shows you one subagent on a gateway model like `glm-5.3`.

## Usage

```
/code-review                                  # medium
/code-review high                             # same recipe, different framing
/code-review max --model dsv41-local          # 10 finders on a pinned model
/code-review max --finder-model glm53-flash --verify-model glm53
/code-review --fix 1234                       # review PR #1234 and apply fixes
/code-review high --max-findings all          # no cap
```

### Pinning the reviewer model

By default nothing is pinned: the fork runs on the session's model, so `/model`
and `CLAUDE_CODE_SUBAGENT_MODEL` govern it exactly as they govern any subagent.

To pin it permanently, add one line to the frontmatter:

```yaml
model: <full-model-id>      # e.g. claude-fable-5-dd-st-1.4vsd
```

or name an agent type:

```yaml
agent: dsv41-ts             # resolves ~/.claude/agents/dsv41-ts.md, whose model: applies
```

A full model ID is the only way to reach a gateway model the Agent tool's own
`model:` parameter cannot name. Runtime arguments do **not** change the fork's
model — `--model <agent>` only reaches the finders that `max` spawns.

To review on a model that has no agent file yet, create one:

```markdown
---
name: reviewer-opus
description: Code review reviewer agent
model: <model-id>
---
You are a careful code reviewer.
```

## What is faithful to the built-in, and what differs

Kept: `context: fork` (one reviewer subagent), the five correctness angles
(A line-by-line, B removed-behavior, C cross-file, D language-pitfall,
E wrapper/proxy), the five cleanup angles (reuse, simplification, efficiency,
altitude, conventions), the effort ladder including the inline medium/high and
xhigh gap-sweep, the 1-vote CONFIRMED/PLAUSIBLE/REFUTED verify pass, the
recall-biased verify rules, the `ReportFindings` output contract, `--fix` with
`outcome` re-reporting, and `--comment` for GitHub.

Added:

- **The reviewer model is pinnable** via frontmatter `model:` / `agent:`.
  This is the reason the skill exists. Runtime `--model` reaches the `max`
  finders, which is what the built-in cannot do at all.

Changed or dropped:

- **No model-family matrix.** The built-in routes Sonnet 5, Opus 4.8 and Opus 5
  to different prompt cells and moves their medium/high off the fan-out
  recipes. This skill keeps the default cell for every model, so behaviour does
  not depend on which model answers.
- **Angle text is written once** and referenced by each level, instead of the
  built-in's per-level duplication, so the whole recipe fits one SKILL.md.
- **Dropped**: `ultra` (cloud review, needs claude.ai account access), the
  GitLab `glab` posting path, and the bundled-skill plumbing (`--post` /
  `--no-post` are accepted and ignored with a note).
- **Last-used level and `--max-findings` live in `~/.claude/state/`**
  (`code-review-last-effort`, `code-review-last-max-findings`) instead of
  Claude Code's internal state store, which a user skill cannot reach.

## Shadowing note

A user skill named `code-review` shadows the bundled one, so `/code-review`
now runs this file. To keep both, rename `name:` in the frontmatter (e.g.
`code-review-x`) — the bundled one reappears under `/code-review` and the alias
`/review` follows the bundled command.

Upgrades of Claude Code may improve the bundled skill; those improvements will
not reach this copy automatically. Re-migrate by extracting the new skill text
from the binary if that matters.