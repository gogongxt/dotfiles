---
name: code-review
description: Review the current diff, or a PR number/branch/path target, for correctness bugs (plus reuse/simplification/efficiency cleanups where the recipe covers them) at the effort level given first, before any target (low|medium|high|xhigh|max: from few high-confidence findings to many, some uncertain); with no level given, it reuses the level you typed last. Pass --comment to post findings as inline PR comments, or --fix to apply them to the working tree after the review. Pass --max-findings <n> to report up to n findings, or --max-findings all for every finding. Reviewers run on the session's model unless --model <agent> names a reviewer agent type.
argument-hint: [low|medium|high|xhigh|max] [--fix] [--comment] [--model <agent>] [<pr#>|<branch>|<path>] [--max-findings <n>|all|default]
user-invocable: true
---

# Code review

A migration of Claude Code's built-in `/code-review`, with one addition: **the reviewer subagents' model is selectable**. By default the review runs on the session's own model, exactly like the built-in. When you want a different one, name an agent type from `~/.claude/agents/` — that file's `model:` frontmatter carries the model, which is the only lever that reaches models the Agent tool's own `model:` parameter cannot name.

## Resolve the run settings

Parse the arguments before doing anything else.

- **Effort level** — the first token, if it is one of `low`, `medium`, `high`, `xhigh`, `max`. Case-insensitive. If absent, read the last-used level from `~/.claude/state/code-review-last-effort`; if that file is missing, use `medium`. When a level was typed explicitly, remember it: at the very end of the turn, write just that word to `~/.claude/state/code-review-last-effort`.
- **Flags** — `--fix`, `--comment`, `--post`, `--no-post` (post is unsupported here; ignore it and say so in one line), and `--max-findings <n>|all|default`.
- **Model flags** — `--model <agent>` (alias `--reviewer <agent>`) sets the agent type for both finders and verifiers. `--finder-model <agent>` and `--verify-model <agent>` override one side each.
- **Target** — everything left after flags: a PR number, a branch, or a path. Empty means the current working diff.

If an unrecognized effort-like token was typed, say so in one line and use the remembered level. Valid levels: `low, medium, high, xhigh, max`.

## Reviewer model

**By default, pin nothing.** Spawn every finder and verifier with no `subagent_type`, so the review runs on the session's own model — whatever `/model` (or `CLAUDE_CODE_SUBAGENT_MODEL`) governs the session also governs the review. Do not hard-code a reviewer here.

Only when the arguments name one:

1. `--finder-model <agent>` / `--verify-model <agent>` — one side each, and they may differ;
2. `--model <agent>` (alias `--reviewer <agent>`) — both sides.

A named reviewer is any `name:` from `~/.claude/agents/*.md`; that file's `model:` frontmatter is what selects the model, which is how a caller pins a model the Agent tool itself cannot name. Run `ls ~/.claude/agents/` to list them. If a requested name is not listed, say so in one line, list the available names, and fall back to the default (no `subagent_type`).

**How to spawn:** without a named reviewer, call the Agent tool without `subagent_type`. With one, pass `subagent_type: "<name>"`. Never pass the Agent tool's own `model:` parameter — it only accepts the standard Claude models and would override the agent type's model. The agent type carries the model; the prompt carries the instructions.

If the Agent tool is not available in this context, run the whole review inline, in this conversation, working through each angle yourself in sequence. State clearly in the summary that it was a single-pass review without fan-out, so the reader is not misled about what ran.

## Phase 0 — Gather the diff

Run `git diff @{upstream}...HEAD` (or `git diff main...HEAD` / `git diff HEAD~1` if there's no upstream) to get the unified diff under review. If there are uncommitted changes, or the range diff is empty, also run `git diff HEAD` and include the working-tree changes in scope — the review often runs before the commit. If a PR number, branch name, or file path was passed as an argument, review that target instead. Treat this diff as the review scope.

Size the fleet from the diff: `min(angle_count, clamp(ceil(lines / 150), 2, 8))`. The angle count below is a ceiling, not a target — a 20-line diff should not start 8 agents. When the fleet is smaller than the angle list, give each finder consecutive angles rather than dropping the tail.

## Angles

Every finder gets exactly one angle. Include the angle text verbatim in its prompt, along with the review target and the instruction to obtain the diff itself.

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

## Phase 1 — Find candidates

Spawn one finder per angle, in parallel — with `subagent_type` set only when a finder agent was named in the arguments. Each finder's prompt must carry:

- the angle text above, verbatim
- the review target and the git commands that produce the diff
- the candidate cap for this level
- this output contract: a JSON array of `{file, line, summary, failure_scenario}`, one candidate per finding, `summary` a single sentence, `failure_scenario` the concrete inputs/state → wrong output/crash

Angle subsets by level:

| Level | Correctness angles | + Cleanup angles | Candidates per angle |
|-------|--------------------|------------------|----------------------|
| medium | A, B, C | Reuse, Simplification, Efficiency, Altitude, Conventions | 6 |
| high | A, B, C | Reuse, Simplification, Efficiency, Altitude, Conventions | 6 |
| xhigh | A, B, C, D, E | Reuse, Simplification, Efficiency, Altitude, Conventions | 8 |
| max | A, B, C, D, E | Reuse, Simplification, Efficiency, Altitude, Conventions | 8 |

Do not let one angle's conclusions suppress another's — if two angles flag the same line for different reasons, record both.

Pass every candidate with a nameable failure scenario through — finders that silently drop half-believed candidates bypass the verify step and are the dominant cause of misses.

## Phase 2 — Verify

`low` skips this phase entirely.

Dedup candidates that point at the same line/mechanism, keeping the one with the most concrete failure scenario. For each remaining candidate, run **one verifier** (same model rules as the finders): give it the diff, the relevant file(s), and the candidate, and have it return exactly one of:

- **CONFIRMED** — can name the inputs/state that trigger it and the wrong output or crash. Quote the line.
- **PLAUSIBLE** — mechanism is real, trigger is uncertain (timing, env, config). State what would confirm it.
- **REFUTED** — factually wrong (code doesn't say that) or guarded elsewhere. Quote the line that proves it.

Keep CONFIRMED and PLAUSIBLE; drop REFUTED.

From `high` up, verify recall-biased:

**PLAUSIBLE by default** — do not refute a candidate for being "speculative" or "depends on runtime state" when the state is realistic: concurrency races, nil/undefined on a rare-but-reachable path (error handler, cold cache, missing optional field), falsy-zero treated as missing, off-by-one on a boundary the code does not exclude, retry storms / partial failures, regex/allowlist that lost an anchor. These are PLAUSIBLE.

**REFUTED** only when constructible from the code: factually wrong (quote the actual line); provably impossible (type/constant/invariant — show it); already handled in this diff (cite the guard); or pure style with no observable effect.

## Phase 3 — Sweep for gaps

`xhigh` and `max` only. Spawn **one more finder** as a fresh reviewer who has the verified list. Re-read the diff and enclosing functions looking ONLY for defects not already listed. Do not re-derive or re-confirm anything already there — the job is gaps. Focus on what the first pass tends to miss: moved/extracted code that dropped a guard or anchor; second-tier footguns (dataclass default evaluated once, `hash()` non-determinism, lock-scope shrink, predicate methods with side effects); setup/teardown asymmetry in tests; config defaults flipped.

Surface **up to 8 additional candidates**, each naming a defect not already on the list. If nothing new, return an empty sweep — do not pad.

## Effort recipes

| Level | Shape | Framing passed to finders | Cap |
|-------|-------|---------------------------|-----|
| `low` | 1 diff pass → no verify | see below | 4 |
| `medium` | 3+5 angles × 6 → 1-vote verify | precision: every finding should be one a maintainer would act on | 8 |
| `high` | 3+5 angles × 6 → verify (recall-biased) | recall: catch every real bug a careful reviewer would catch in one sitting | 10 |
| `xhigh` | 5+5 angles × 8 → verify → sweep | recall at extra-high effort: a missed bug ships, so err on the side of surfacing | 15 |
| `max` | 5+5 angles × 8 → verify → sweep | recall at maximum effort: a missed bug ships, so err on the side of surfacing | 15 |

For `xhigh` and `max`, a single non-REFUTED verifier vote carries the finding — do NOT drop on uncertainty.

`--max-findings <n>` replaces the cap; `--max-findings all` removes it; `--max-findings default` restores the table above. A typed limit persists until `--max-findings default` is passed: remember it in `~/.claude/state/code-review-last-max-findings` the same way as the effort level.

### low

Skip test/fixture hunks (`test/`, `spec/`, `__tests__/`, `*_test.*`, `*.test.*`, `fixtures/`, `testdata/`) — test-file changes are not reviewed at this level. No subagents, no full-file reads.

Read the unified diff in one tool call, then flag runtime-correctness bugs visible from the hunk alone: inverted/wrong condition, off-by-one, null/undefined deref where adjacent lines show the value can be absent, removed guard, falsy-zero check, missing `await`, wrong-variable copy-paste, error swallowed in a catch that should propagate. Also flag — still from the hunk alone — new code that duplicates an existing helper visible in the diff context, and dead code the diff leaves behind.

Do **not** flag style, naming, perf, missing tests, or anything outside the hunk.

Report at most 4 findings, most-severe first, in one `ReportFindings` call with `{level, findings}`. Target at least `min(files_changed, 4)` — if you see fewer, widen to other hunks in the same diff before stopping. If fewer than 4 genuine findings exist, report what you have.

### medium / high / xhigh / max

Run Phase 0, then Phase 1 (angle table above), then Phase 2 (recall-biased from `high` up), then Phase 3 for `xhigh` and `max`.

## Output

Call `ReportFindings` once with `{level, findings}`, ranked most-severe first. Each finding:

- `file` — repo-relative path
- `line` — 1-indexed start line
- `summary` — one sentence stating the defect and its consequence
- `short_summary` — the claim compressed to ≤60 characters, no rationale or consequence clause
- `failure_scenario` — concrete inputs/state → wrong output/crash (for cleanups: the concrete cost)
- `category` — short kebab-case slug for the angle that produced it (`correctness`, `reuse`, `simplification`, `efficiency`, `altitude`, `conventions`, or a more specific slug like `test-coverage`)
- `verdict` — `CONFIRMED` or `PLAUSIBLE` when a verify pass produced one

If nothing survives, call it with an empty array. Do not also print the findings as text, and do not create or publish an artifact of the review — the tool call is the report.

If `ReportFindings` is not available in this context, emit a JSON array of `{file, line, summary, failure_scenario}` instead, ranked most-severe first.

## Posting to GitHub (--comment)

The `--comment` flag was passed. After producing the findings list, if the review target is a GitHub PR, post each finding as an inline PR comment via `mcp__github_inline_comment__create_inline_comment` (one call per finding; include a suggestion block only when it fully fixes the issue). If that tool is not available in this session, fall back to `gh api` (`repos/{owner}/{repo}/pulls/{pr}/comments`) or print the findings instead. If the target is not a PR, print the findings to the terminal and note that `--comment` was ignored.

## Applying fixes (--fix)

The `--fix` flag was passed. After producing the findings list, apply the findings to the working tree instead of stopping at the report: fix each one directly — correctness bugs and reuse/simplification/efficiency cleanups alike. Skip any finding whose fix would change intended behavior, require changes well outside the reviewed diff, or that you judge to be a false positive — note the skip rather than arguing with it.

If findings were reported with `ReportFindings`, call it again with the same findings, each carrying an `outcome`: `fixed`, `no_change_needed` (the finding was wrong or already handled), or `skipped` (real but not applied). Do not repeat the findings as text. Then give one line per skipped finding saying why.

If findings are fixed later in this session — the user asks you to fix them, or later work fixes them incidentally — make that same `outcome` call immediately after the fixes land, before any prose summary.
