---
name: code-review
description: Review the current diff, or a PR number/branch/path target, for correctness bugs (plus reuse/simplification/efficiency cleanups where the recipe covers them) at the effort level given first, before any target (low|medium|high|xhigh|max: from few high-confidence findings to many, some uncertain); with no level given, it uses medium. Pass --comment to post findings as inline PR comments, or --fix to apply them to the working tree after the review. Pass --max-findings <n> to report up to n findings, or --max-findings all for every finding.
argument-hint: [low|medium|high|xhigh|max] [--fix] [--comment] [--max-findings <n>|all|default] [--model <agent>] [<pr#>|<branch>|<path>]
user-invocable: true
context: fork
effort: medium
---

# Code review

A migration of Claude Code's built-in `/code-review`. It runs the same way: `context: fork` puts the whole review in one subagent, so the caller sees a single reviewer. Low through extra-high work the angles inline, in this context; only `max` fans out.

## Resolve the run settings

Parse the arguments before doing anything else.

- **Effort level** — the first token, if it is one of `low`, `medium`, `high`, `xhigh`, `max`. Case-insensitive. Absent means `medium`.
- **Flags** — `--fix`, `--comment`, `--max-findings <n>|all|default`. `--post` and `--no-post` belong to the cloud review this skill does not have: ignore them, and say so in one line if one was typed.
- **Model flag** — `--model <agent>` (alias `--reviewer`) and `--finder-model` / `--verify-model` select agent types for the `max` finders and verifiers only. They cannot change this review's own model — see "Reviewer model".
- **Target** — everything left after flags: a PR number, a branch, or a path. Empty means the current working diff.

If an unrecognized effort-like token was typed, say so in one line and use `medium`. Valid levels: `low, medium, high, xhigh, max`.

## Reviewer model

This skill runs as a forked subagent (frontmatter `context: fork`), and that fork is the reviewer. Its model is:

1. the frontmatter `model:` below, if set — a full model ID works;
2. otherwise the agent type in frontmatter `agent:`, if set;
3. otherwise the session's model, exactly like the built-in.

Nothing is pinned today, so the review runs on the session's own model. To pin it permanently, add one line to the frontmatter — `model: <full-model-id>`, or `agent: <name>` naming a file under `~/.claude/agents/` whose `model:` is what you want. A runtime argument cannot change the fork's model; `--model <agent>` only reaches the finders that `max` spawns.

**How to spawn** (only `max` does): call the Agent tool with `subagent_type: "<resolved agent name>"` when a name was given, and with no `subagent_type` otherwise. Never pass the Agent tool's own `model:` parameter — it accepts only the standard Claude models and would override the agent type's model. The agent type carries the model; the prompt carries the instructions.

If the Agent tool is not available in this context, run the fan-out part inline too, and say in the summary that it was a single-pass review without fan-out, so the reader is not misled about what ran.

## Phase 0 — Gather the diff

Run `git diff @{upstream}...HEAD` (or `git diff main...HEAD` / `git diff HEAD~1` if there's no upstream) to get the unified diff under review. If there are uncommitted changes, or the range diff is empty, also run `git diff HEAD` and include the working-tree changes in scope — the review often runs before the commit. If a PR number, branch name, or file path was passed as an argument, review that target instead. Treat this diff as the review scope.

**Evidence budget.** Gather in as few calls as the diff allows: one for the diff, then combined Bash calls that print the changed files, grep for callers of the changed symbols, and list the CLAUDE.md files in scope. A small diff needs about three calls in all; a large one needs more, but still combined — do not Read files one at a time, and do not open files the diff does not touch unless a call site demands it. A `medium` or `high` review is normally finished in four or five model turns: diff, evidence, report.

**Do not run builds, tests, linters or formatters to review.** Decide from the diff and the code it touches; CI runs those, and a build can cost minutes per call. This holds even when a finding is uncertain — read the code instead. The one exception is after `--fix` has edited files: running the project's check on the touched files is fine then.

## Angles

Each angle below is one reviewer's whole job. Inline levels work through them in sequence; `max` gives each to its own finder.

### Correctness angles

**Angle A — line-by-line diff scan.** Read every hunk in the diff, line by line. Then Read the enclosing function for each hunk — bugs in unchanged lines of a touched function are in scope (the PR re-exposes or fails to fix them). For every line ask: what input, state, timing, or platform makes this line wrong? Look for inverted/wrong conditions, off-by-one, null/undefined deref, missing `await`, falsy-zero checks, wrong-variable copy-paste, error swallowed in catch, unescaped regex metachars.

**Angle B — removed-behavior auditor.** For every line the diff DELETES or replaces, name the invariant or behavior it enforced, then search the new code for where that invariant is re-established. If you can't find it, that's a candidate: a removed guard, a dropped error path, a narrowed validation, a deleted test that was covering a real case.

**Angle C — cross-file tracer.** For each function the diff changes, find its callers (Grep for the symbol) and check whether the change breaks any call site: a new precondition, a changed return shape, a new exception, a timing/ordering dependency. Also check callees: does a parallel change in the same PR make a call unsafe?

**Angle D — language-pitfall specialist.** Scan for the classic pitfalls of the diff's language/framework — for example: JS falsy-zero, `==` coercion, closure-captured loop var; Python mutable default args, late-binding closures; Go nil-map write, range-var capture; SQL injection; timezone/DST drift; float equality. Flag any instance the diff introduces.

**Angle E — wrapper/proxy correctness.** When the PR adds or modifies a type that wraps another (cache, proxy, decorator, adapter): check that every method routes to the wrapped instance and not back through a registry/session/global — e.g. a caching provider holding a `delegate` field that resolves IDs via `session.get(...)` instead of `delegate.get(...)` will re-enter the cache or recurse. Also check that the wrapper forwards all the methods the callers actually use.

### Cleanup angles

**Reuse.** Flag new code that re-implements something the codebase already has — Grep shared/utility modules and files adjacent to the change, and name the existing helper to call instead.

**Simplification.** Flag unnecessary complexity the diff adds: redundant or derivable state, copy-paste with slight variation, deep nesting, dead code left behind. Name the simpler form that does the same job.

**Efficiency.** Flag wasted work the diff introduces: redundant computation or repeated I/O, independent operations run sequentially, blocking work added to startup or hot paths. Also flag long-lived objects built from closures or captured environments — they keep the entire enclosing scope alive for the object's lifetime (a memory leak when that scope holds large values); prefer a class/struct that copies only the fields it needs. Name the cheaper alternative.

**Altitude.** Check that each change fixes the root cause at the right depth rather than patching a symptom with a fragile bandaid. Special cases layered on shared infrastructure are a sign the fix isn't deep enough — prefer the simpler, more general change to the underlying mechanism over adding special cases, and name that change.

**Conventions (CLAUDE.md).** Find the CLAUDE.md files that govern the changed code: the user-level `~/.claude/CLAUDE.md`, the repo-root `CLAUDE.md`, plus any `CLAUDE.md` or `CLAUDE.local.md` in a directory that is an ancestor of a changed file (a directory's CLAUDE.md only applies to files at or below it). Read each one that exists, then check the diff for clear violations of the rules they state.

Only flag a violation when you can quote the exact rule and the exact line that breaks it — no style preferences, no vague "spirit of the doc" inferences. In the finding, name the CLAUDE.md path and quote the rule so the report can cite it. If no CLAUDE.md applies, return nothing for this angle.

Cleanup, altitude, and conventions candidates use the same `file`/`line`/`summary` shape; in `failure_scenario`, state the concrete cost (what is duplicated, wasted, harder to maintain, or which CLAUDE.md rule is broken) instead of a crash. Correctness bugs always outrank cleanup, altitude, and conventions findings when the output cap forces a cut.

## Effort ladder

| Level | Shape | Angles | Candidates per angle | Report cap |
|-------|-------|--------|---------------------|-----------|
| `low` | 1 diff pass → no verify | none (hunk-only scan) | — | 4 |
| `medium` | 8 inline angles → dedup, no verify | A, B, C + Reuse, Simplification, Efficiency, Altitude, Conventions | 6 | 10 |
| `high` | 8 inline angles → dedup, no verify | same as medium | 6 | 10 |
| `xhigh` | 10 inline angles → dedup → gap sweep | A, B, C, D, E + Reuse, Simplification, Efficiency, Altitude, Conventions | 8 | 15 |
| `max` | 10 fan-out finders → 1-vote verify → gap sweep | A, B, C, D, E + the five cleanup angles | 8 | 15 |

This mirrors the built-in's default model-family cell: medium and high share one recipe, and only `max` fans out.

Do not let one angle's conclusions suppress another's — if two angles flag the same line for different reasons, record both. Pass every candidate with a nameable failure scenario through.

Each candidate carries `file`, `line`, a one-line `summary`, and a concrete `failure_scenario` (the inputs/state → wrong output/crash; for cleanups, the concrete cost).

`--max-findings <n>` replaces the cap for this review; `--max-findings all` removes it; `--max-findings default` restores the table.

### low

Skip test/fixture hunks (`test/`, `spec/`, `__tests__/`, `*_test.*`, `*.test.*`, `fixtures/`, `testdata/`) — test-file changes are not reviewed at this level. No subagents, no full-file reads.

Read the unified diff in one tool call, then flag runtime-correctness bugs visible from the hunk alone: inverted/wrong condition, off-by-one, null/undefined deref where adjacent lines show the value can be absent, removed guard, falsy-zero check, missing `await`, wrong-variable copy-paste, error swallowed in a catch that should propagate. Also flag — still from the hunk alone — new code that duplicates an existing helper visible in the diff context, and dead code the diff leaves behind.

Do **not** flag style, naming, perf, missing tests, or anything outside the hunk.

Report at most 4 findings, most-severe first, in one `ReportFindings` call with `{level, findings}`. Target at least `min(files_changed, 4)` — if you see fewer, widen to other hunks in the same diff before stopping. If fewer than 4 genuine findings exist, report what you have.

### medium and high

You are reviewing for **recall**: catch every real bug a careful reviewer would catch in one sitting. At this level, catching real bugs matters more than avoiding false positives. Err on the side of surfacing.

Work through **8 angles** yourself, in sequence, in this same context — do **not** spawn subagents: A, B, C, then Reuse, Simplification, Efficiency, Altitude, Conventions. Each surfaces **up to 6 candidate findings**.

Then **dedup only** — near-duplicates (same defect, same location, same reason → keep one). Do **not** run verifiers, do **not** re-judge. Sort by severity.

Five findings is a normal result here, not a quota: report what the angles found within the evidence budget. If fewer genuine findings exist, emit what you have — do not invent to reach a number, and do not widen the search to reach one.

### xhigh

You are reviewing for **recall** at extra-high effort: catch every real bug. A missed bug ships, so err on the side of surfacing.

Work through **10 angles** yourself, in sequence, in this same context — do **not** spawn subagents: A, B, C, D, E, then the five cleanup angles. Each surfaces **up to 8 candidate findings**. Do NOT let one angle's conclusions suppress another's.

Then dedup near-duplicates (same defect, same location, same reason → keep one). Do **not** run verifiers.

Then take **one more pass yourself** as a fresh reviewer who has the deduplicated list. Re-read the diff and enclosing functions looking ONLY for defects not already listed: moved/extracted code that dropped a guard or anchor; second-tier footguns (dataclass default evaluated once, `hash()` non-determinism, lock-scope shrink, predicate methods with side effects); setup/teardown asymmetry in tests; config defaults flipped. If nothing new, add nothing — do not pad.

Seven findings is a normal result here, not a quota: report what the angles and the sweep found within the evidence budget. If fewer genuine findings exist, emit what you have — do not invent to reach a number, and do not widen the search to reach one.

### max

You are reviewing for **recall** at maximum effort: catch every real bug. A missed bug ships, so err on the side of surfacing.

**Phase 1 — finders.** Spawn **10 finders**, one per angle (A, B, C, D, E, Reuse, Simplification, Efficiency, Altitude, Conventions), in parallel, with the `subagent_type` rules above. Each finder's prompt carries its angle text verbatim, the review target and the diff commands, the cap of 8 candidates, and the candidate output contract. Do NOT let one angle's conclusions suppress another's — if two angles flag the same line for different reasons, record both. Pass every candidate with a nameable failure scenario through; finders that silently drop half-believed candidates bypass the verify step and are the dominant cause of misses.

**Phase 2 — verify.** Dedup candidates that point at the same line/mechanism, keeping the one with the most concrete failure scenario. For each remaining candidate, run **one verifier** (same spawning rules) with the diff, the relevant file(s), and the candidate; it returns exactly one of CONFIRMED / PLAUSIBLE / REFUTED below. This is recall mode — a single non-REFUTED vote carries the finding. Do NOT drop on uncertainty.

**Phase 3 — sweep.** Spawn **one more finder** as a fresh reviewer who has the verified list. Re-read the diff and enclosing functions looking ONLY for defects not already listed — the job is gaps. Surface **up to 8 additional candidates**; if nothing new, return an empty sweep, do not pad.

## Verify verdicts (max only)

- **CONFIRMED** — can name the inputs/state that trigger it and the wrong output or crash. Quote the line.
- **PLAUSIBLE** — mechanism is real, trigger is uncertain (timing, env, config). State what would confirm it.
- **REFUTED** — factually wrong (code doesn't say that) or guarded elsewhere. Quote the line that proves it.

Keep CONFIRMED and PLAUSIBLE; drop REFUTED.

**PLAUSIBLE by default** — do not refute a candidate for being "speculative" or "depends on runtime state" when the state is realistic: concurrency races, nil/undefined on a rare-but-reachable path (error handler, cold cache, missing optional field), falsy-zero treated as missing, off-by-one on a boundary the code does not exclude, retry storms / partial failures, regex/allowlist that lost an anchor. These are PLAUSIBLE.

**REFUTED** only when constructible from the code: factually wrong (quote the actual line); provably impossible (type/constant/invariant — show it); already handled in this diff (cite the guard); or pure style with no observable effect.

## Output

Call `ReportFindings` once with `{level, findings}`, ranked most-severe first. Each finding:

- `file` — repo-relative path
- `line` — 1-indexed start line
- `summary` — one sentence stating the defect and its consequence
- `short_summary` — the claim compressed to ≤60 characters, no rationale or consequence clause
- `failure_scenario` — concrete inputs/state → wrong output/crash (for cleanups: the concrete cost)
- `category` — short kebab-case slug for the angle that produced it (`correctness`, `reuse`, `simplification`, `efficiency`, `altitude`, `conventions`, or a more specific slug like `test-coverage`)
- `verdict` — `CONFIRMED` or `PLAUSIBLE` when a verify pass produced one

Every finding must carry `file`, `line`, `summary`, `short_summary`, `failure_scenario` and `category`: the tool rejects a call that omits any of them, and a rejected call costs a full extra turn.

If nothing survives, call it with an empty array. Do not also print the findings as text, and do not create or publish an artifact of the review — the tool call is the report. Then stop: no further tool calls, at most one closing line.

If `ReportFindings` is not available in this context, emit a JSON array of `{file, line, summary, failure_scenario}` instead, ranked most-severe first, and stop there.

## Posting to GitHub (--comment)

The `--comment` flag was passed. After producing the findings list, if the review target is a GitHub PR, post each finding as an inline PR comment via `mcp__github_inline_comment__create_inline_comment` (one call per finding; include a suggestion block only when it fully fixes the issue). If that tool is not available, fall back to `gh api` (`repos/{owner}/{repo}/pulls/{pr}/comments`) or print the findings instead. If the target is not a PR, print the findings to the terminal and note that `--comment` was ignored.

## Applying fixes (--fix)

The `--fix` flag was passed. After producing the findings list, apply the findings to the working tree instead of stopping at the report: fix each one directly — correctness bugs and reuse/simplification/efficiency cleanups alike. Skip any finding whose fix would change intended behavior, require changes well outside the reviewed diff, or that you judge to be a false positive — note the skip rather than arguing with it.

If findings were reported with `ReportFindings`, call it again with the same findings, each carrying an `outcome`: `fixed`, `no_change_needed` (the finding was wrong or already handled), or `skipped` (real but not applied). Do not repeat the findings as text. Then give one line per skipped finding saying why.

If findings are fixed later in this session — the user asks you to fix them, or later work fixes them incidentally — make that same `outcome` call immediately after the fixes land, before any prose summary.