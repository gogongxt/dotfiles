---
name: code-review
description: Review the current diff, or a PR number/branch/path target, for correctness bugs (plus reuse/simplification/efficiency cleanups where the recipe covers them) at the effort level given first, before any target (low|medium|high|xhigh|max: from few high-confidence findings to many, some uncertain); with no level given, it uses medium. Pass --comment to post findings as inline PR comments, or --fix to apply them to the working tree after the review. Pass --max-findings <n> to report up to n findings, or --max-findings all for every finding.
argument-hint: [low|medium|high|xhigh|max] [--fix] [--comment] [--max-findings <n>|all|default] [--model <agent>] [<pr#>|<branch>|<path>]
user-invocable: true
context: fork
effort: medium
---

# Code review

A migration of the built-in `/code-review`. `context: fork` runs the whole review in one subagent, so the caller sees a single reviewer. Low through extra-high work the angles inline, in this context; only `max` fans out.

## Run settings

- **Level** — the first token when it starts with `low`, `med`, `hig`, `xhi` or `max` (case-insensitive). Absent means `medium`; an unrecognized level-like token means `medium` with one line saying so.
- **Flags** — `--fix`, `--comment`, `--max-findings <n>|all|default` (also written `--max-findings=5`; anything else after it is ignored with one line saying so). `--post`/`--no-post` belong to the cloud review this skill does not have: ignore them, and say so in one line.
- **Model flags** — `--model <agent>` (alias `--reviewer`), `--finder-model`, `--verify-model`: agent types for the `max` finders and verifiers only. They cannot change this review's own model.
- **Target** — what remains after flags: a PR number (leading `#` dropped), a branch, or a path. Empty means the working diff.

## Reviewer model

The fork's model is the frontmatter `model:` if set (a full model ID works), else the agent type in frontmatter `agent:`, else the session's model. Nothing is pinned today. To pin one, add `model: <full-id>` or `agent: <name>` to the frontmatter — a runtime flag cannot change the fork's own model.

`max` spawns with `subagent_type: "<agent name>"` when a name was given, and with no `subagent_type` otherwise. Never pass the Agent tool's `model:` parameter: it accepts only standard Claude models and would override the agent type's model. If the Agent tool is unavailable, run the fan-out inline and say the review ran single-pass without fan-out.

## Phase 0 — the diff

`git diff @{upstream}...HEAD` (or `main...HEAD`, `HEAD~1` if there is no upstream), plus `git diff HEAD` when there are uncommitted changes or the range is empty; a target argument replaces this. That diff is the review scope.

**Evidence budget.** One call for the diff, then combined Bash calls for the changed files, the callers of changed symbols, and the CLAUDE.md files in scope. About three calls for a small diff; never one Read per file, and do not open files the diff does not touch unless a call site demands it. A `medium` or `high` review normally ends in four or five model turns: diff, evidence, report.

**No builds, tests, linters or formatters while reviewing** — decide from the code; CI runs those. The one exception is after `--fix` has edited files, where checking the touched files is fine.

## Angles

Each angle is one reviewer's whole job: inline levels work through them in sequence, `max` gives each its own finder.

**A — line-by-line diff scan.** Every hunk, line by line, then Read the enclosing function for each hunk — bugs in unchanged lines of a touched function are in scope. Ask what input, state, timing or platform makes each line wrong: inverted condition, off-by-one, null/undefined deref, missing `await`, falsy-zero check, wrong-variable copy-paste, error swallowed in a catch, unescaped regex metachar.

**B — removed behavior.** For every line the diff deletes or replaces, name the invariant it enforced and find where the new code re-establishes it. If nowhere: a removed guard, a dropped error path, a narrowed validation, a deleted test that covered a real case.

**C — cross-file.** For each changed function, Grep its callers and check the change breaks no call site — new precondition, changed return shape, new exception, ordering dependency — and that parallel changes in the same diff do not make a call unsafe.

**D — language pitfalls.** The diff's language/framework traps: JS falsy-zero, `==` coercion, closure-captured loop var; Python mutable defaults, late binding; Go nil-map write, range capture; SQL injection; DST drift; float equality.

**E — wrapper/proxy.** For a new or changed wrapper (cache, proxy, decorator, adapter): every method routes to the wrapped instance, not back through a registry or global — a `delegate` field resolving IDs via `session.get(...)` re-enters the cache — and the wrapper forwards every method its callers use.

**Cleanup angles.** *Reuse* — new code re-implementing something the codebase has (Grep shared modules and adjacent files; name the helper to call). *Simplification* — redundant or derivable state, copy-paste variants, deep nesting, dead code; name the simpler form. *Efficiency* — repeated I/O or computation, independent work run sequentially, blocking work on startup or hot paths, long-lived closures keeping a large scope alive; name the cheaper alternative. *Altitude* — the root cause at the right depth, not a symptom patch; special cases piled onto shared infrastructure mean the fix is too shallow. *Conventions* — the CLAUDE.md files governing the changed code (`~/.claude/CLAUDE.md`, the repo root, and any in an ancestor directory of a changed file); quote the exact rule and the exact line, no style preferences, nothing when none applies.

Cleanup findings state the concrete cost in `failure_scenario`, not a crash. Correctness outranks cleanup, altitude and conventions when the cap forces a cut.

## Effort ladder

| Level | Shape | Angles | Cap |
|---|---|---|---|
| `low` | one hunk-only pass, no verify | hunk scan | 4 |
| `medium` | 8 inline angles, dedup only | A, B, C + the five cleanups | 8 |
| `high` | same 8 inline angles, dedup only | A, B, C + the five cleanups | 10 |
| `xhigh` | 10 inline angles, dedup, then a gap sweep | all ten | 15 |
| `max` | finders → 1-vote verify → gap sweep | all ten | 15 |

Medium and high share one recipe; only `max` fans out. Use `max` only when the user or CLAUDE.md explicitly asks — never on your own judgment.

No angle may suppress another: two angles flagging one line for different reasons are two findings. Pass every candidate with a nameable failure scenario — silently dropping half-believed candidates is the dominant cause of misses. Each candidate carries `file`, `line`, a one-line `summary` and a concrete `failure_scenario`.

`--max-findings <n>` replaces the cap (32 is the tool's ceiling); `all` lifts the cap to that ceiling; `default` restores the table.

### low

One tool call for the diff, skipping test/fixture hunks (`test/`, `spec/`, `__tests__/`, `*_test.*`, `*.test.*`, `fixtures/`, `testdata/`). No subagents, no full-file reads.

Flag only hunk-visible runtime bugs — Angle A's list — plus a duplicated helper visible in the diff context and dead code left behind. Do not flag style, naming, perf, missing tests, or anything outside the hunk.

Report at most 4, or the `--max-findings` limit instead when one was typed, at `level: "low"`. An empty array is a valid result: this level is one pass, not a search.

### medium and high

Correctness first: surface every plausible bug — catching a real one matters more than a false positive.

Work through the 8 angles yourself in this context, no subagents, up to 6 candidates each. Dedup only (same defect, same location, same reason → one); no verifiers, no re-judging; sort by severity.

Five findings is a normal result, not a quota: report what the angles found, and do not invent or widen the search to reach a number.

The two levels differ only in the report cap — 8 at `medium`, 10 at `high`.

### xhigh

Recall: a missed bug ships.

Work through all 10 angles yourself, no subagents, up to 8 candidates each, and do not drop on uncertainty. Dedup only; no verifiers.

Then one fresh pass over the deduplicated list hunting only gaps: code moved or extracted without its guard, second-tier footguns (dataclass default evaluated once, `hash()` non-determinism, lock-scope shrink, side-effecting predicates), test setup/teardown asymmetry, flipped config defaults. Add nothing when nothing new.

Seven findings is a normal result, not a quota.

### max

Recall at maximum effort. This is the only level that spawns subagents.

**Finders.** One finder per angle, each given its angle text verbatim, the target and diff commands, the 8-candidate cap and the candidate contract. Scale the fleet to the diff: `git diff --numstat`, then about `min(8, max(2, ceil(lines/150)))` finders spread over the angles that fit. Dedup same-line/mechanism candidates, keeping the most concrete scenario.

**Verify.** One verifier per remaining candidate, same spawning rules, given the diff, the relevant files and the candidate; it returns one verdict from "Verify verdicts" below. CONFIRMED or PLAUSIBLE keeps the finding — do not drop on uncertainty.

**Sweep.** One more finder holding the verified list, hunting only gaps of the kind listed under `xhigh`; up to 8 new candidates, nothing when there are none.

### Verify verdicts (max only)

- **CONFIRMED** — names the inputs/state that trigger it and the wrong output or crash; quotes the line.
- **PLAUSIBLE** — real mechanism, uncertain trigger (timing, env, config); states what would confirm it.
- **REFUTED** — factually wrong, provably impossible, already guarded in this diff, or pure style with no observable effect. Quote the line that proves it.

**PLAUSIBLE by default.** Do not refute a candidate for being speculative when the state is realistic: races, nil/undefined on a rare-but-reachable path, falsy-zero read as missing, off-by-one on a boundary the code does not exclude, retry storms, an anchor lost from a regex or allowlist.

Keep CONFIRMED and PLAUSIBLE; drop REFUTED.

## Output

Call `ReportFindings` once with `{level, findings}`, most severe first. Fields: `file`, `summary` and `failure_scenario` are required — a rejected call costs a full extra turn. `line` (integer), `short_summary` (≤60 chars, the claim alone), `category` (kebab-case slug for the angle that produced it) and `verdict` (when a verify pass ran) are optional but fill them; an omitted field just drops out of the UI. The tool takes at most 32 findings.

Keep the most severe when over the cap; an empty array when nothing survives. Do not also print the findings, do not publish an artifact — the tool call is the report. Then stop: no further tool calls, at most one closing line.

**Without `--fix` this review is read-only** — no edits, no `git add`/`commit`/`stash`, not even to demonstrate a fix; put the fix in `failure_scenario` instead. If `ReportFindings` is unavailable, emit a JSON array of `{file, line, summary, failure_scenario}` instead and stop.

**After the report**, if a `/verify` skill is installed, has not run this session, and the diff has a runtime surface (not test- or docs-only), run it: this review checks the diff *reads* right, `/verify` that it *runs* right.

## Posting to GitHub (--comment)

With `--comment` and a GitHub PR target, post each finding as an inline comment via `mcp__github_inline_comment__create_inline_comment` (a suggestion block only when it fully fixes the issue), falling back to `gh api repos/{owner}/{repo}/pulls/{pr}/comments`, or print the findings when neither exists. A non-PR target prints and notes that `--comment` was ignored.

## Applying fixes (--fix)

With `--fix`, apply the findings to the working tree after reporting: fix each one, reuse/simplification/efficiency cleanups included. Skip any whose fix changes intended behavior, reaches well outside the reviewed diff, or is a false positive — note the skip rather than arguing. Then call `ReportFindings` again with the same findings plus an `outcome` (`fixed`, `no_change_needed`, `skipped`) and one line per skip.

If findings are fixed later in this session, make that same `outcome` call immediately after the fixes land, before any prose summary.