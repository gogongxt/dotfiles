# code-review (user skill)

A migration of the `/code-review` skill bundled inside the Claude Code binary,
with one deliberate feature added: **reviewer model selection**.

## Why this exists

The built-in skill spawns generic subagents through the Agent tool. The Agent
tool's `model` parameter only accepts `sonnet`, `opus`, `haiku`, `fable`, so
there is no way to point a review at a gateway model such as `glm-5.3` or
`dsv4.1-local`.

This skill fixes that by spawning a *named agent type* instead. The
`subagent_type` passed to the Agent tool resolves to a file in
`~/.claude/agents/`, and that file's `model:` frontmatter is what actually
selects the model.

## Usage

```
/code-review                                  # medium, default reviewer (model `dsv4.1-ts`)
/code-review high                             # more recall
/code-review max --model dsv41-local          # deepest, on a specific model
/code-review high --finder-model glm53-flash --verify-model glm53
/code-review --fix 1234                       # review PR #1234 and apply fixes
/code-review high --max-findings all          # no cap
```

### Changing the default reviewer model

Edit one line in `SKILL.md`:

```
**Default reviewer agent: `dsv41-ts`**
```

Replace `dsv41-ts` with any `name:` from `~/.claude/agents/*.md`. The actual model
comes from that agent file's `model:` field, so to review on a model that has
no agent file yet, create one:

```markdown
---
name: reviewer-opus
description: Code review reviewer agent
model: <model-id>
---
You are a careful code reviewer.
```

## What is faithful to the built-in, and what differs

Kept: the five correctness angles (A line-by-line, B removed-behavior, C
cross-file, D language-pitfall, E wrapper/proxy), the five cleanup angles
(reuse, simplification, efficiency, altitude, conventions), the effort ladder,
the 1-vote CONFIRMED/PLAUSIBLE/REFUTED verify pass, the recall-biased verify
rules, the xhigh/max gap sweep, the `ReportFindings` output contract, `--fix`
with `outcome` re-reporting, `--comment` for GitHub, and the inline fallback
when the Agent tool is unavailable.

Changed:

- **Reviewer model is selectable** (`--model`, `--finder-model`,
  `--verify-model`, and a configurable default). This is the reason the skill
  exists.
- **Angle text is factored out** instead of duplicated per effort level, so the
  whole recipe fits one SKILL.md. The built-in only injects the chosen level's
  text at runtime, which let it afford duplication.
- **Fleet size scales with diff size** (`min(angle_count, ceil(lines/150))`,
  2–8) instead of the built-in's model-family matrix. The matrix routed
  different model families to different prompt cells (`o48-high-v1`, `o5-bmin`,
  `low-sonnet5`, …); this skill keeps one recipe per level, which is what the
  default cell used.
- **Dropped**: `ultra` (cloud review, needs claude.ai account access), the
  GitLab `glab` posting path, the per-model-family prompt matrix, and the
  bundled-skill plumbing (`--post` is accepted and ignored with a note).
- **Last-used level and `--max-findings` are remembered in `~/.claude/state/`**
  (`code-review-last-effort`, `code-review-last-max-findings`) instead of in
  Claude Code's internal state store, which a user skill cannot reach.

## Shadowing note

A user skill named `code-review` shadows the bundled one, so `/code-review`
now runs this file. To keep both, rename `name:` in the frontmatter (e.g.
`code-review-x`) — the bundled one reappears under `/code-review` and the alias
`/review` follows the bundled command.

Upgrades of Claude Code may improve the bundled skill; those improvements will
not reach this copy automatically. Re-migrate by extracting the new skill text
from the binary if that matters.
