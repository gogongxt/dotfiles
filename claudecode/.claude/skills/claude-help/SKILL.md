---
name: claude-help
description: Search and read Claude Code official docs, changelog, and GitHub issues. Use when the user asks how Claude Code works, what a setting/env var/flag does, wants release notes, or wants to find/triage a known issue. Handles proxy + GitHub fallback automatically for network problems.
user-invocable: true
---

# Claude Help

Search and read authoritative Claude Code information: official documentation, the changelog, and GitHub issues in `anthropics/claude-code`. Answers "how do I…", "what does X do", "is this a known issue", and "what changed in version Y" questions.

## When to Use

- User asks how Claude Code works (features, hooks, slash commands, settings, env vars, flags, MCP, IDE integrations).
- User asks what a specific setting / env var / CLI flag means.
- User wants release notes or what changed in a version.
- User hit an error / odd behavior and wants to find a known issue.
- User asks to search Claude Code GitHub issues (bugs, feature requests, questions).

## CRITICAL: Network, Proxy & Fetcher Rules

There are **three independent fetchers** — they fail differently. Know which one you're using.

| Fetcher | Tool | Needs proxy? | Notes |
|---------|------|--------------|-------|
| Shell network | `Bash` (`gh`, `curl`, `git`) | **Yes** for github.com / pypi / npm | Env vars do NOT persist between Bash calls. **Do NOT hardcode proxy commands here** — read the `/proxy` skill for the correct incantation. |
| Built-in fetch | `WebFetch` / `WebSearch` | No | Has its own network path; proxy env vars do nothing for it. Geo-blocked on some `platform.claude.com` URLs. |
| Exa MCP | `mcp__exa__web_search_exa` / `mcp__exa__web_search_advanced_exa` / `mcp__exa__crawling_exa` / `mcp__exa__get_code_context_exa` | No | Fetches via Exa's own infra. **Bypasses the `platform.claude.com` geo-block** (verified) and gives cleaner search with highlights/summaries. Preferred over WebSearch when available. |

So:
- **Reading docs via WebFetch or Exa crawl** → just call it. No proxy.
- **Searching issues / changelog via `gh` or `curl`** → proxy is required. **Read the `/proxy` skill** for the correct command form (when proxy is needed, how to enable it, and the reminder that each Bash call is a fresh shell). Do not inline `proxy on` here — the `/proxy` skill is the source of truth.
- If a Bash network command fails, the most common cause is proxy not enabled or a flaky proxy. Consult the `/proxy` skill and retry once with proxy explicitly enabled before assuming the endpoint is down.

### Known geo-block + the Exa bypass (important)

`code.claude.com/docs/en/*` is reachable via WebFetch. But `platform.claude.com/docs/*` (where the model-overview / max-output-tokens table lives) **307-redirects to "app unavailable in region"** under WebFetch in some networks.

**Exa's crawler bypasses this** — `mcp__exa__crawling_exa` fetches `platform.claude.com` pages in full (verified). So when WebFetch reports that 307 redirect, **do not chase it** — re-fetch the same URL with `mcp__exa__crawling_exa` instead, then fall back to `gh`/Exa search only if Exa also fails.

### Which Exa tool to use

| Tool | Use for |
|------|---------|
| `mcp__exa__crawling_exa` | Reading a **known URL** in full (especially a geo-blocked one). Batch up to several URLs per call. |
| `mcp__exa__web_search_exa` | Natural-language search — describe the ideal page, not keywords. Best default search. |
| `mcp__exa__web_search_advanced_exa` | Search with filters: domains, date range, labels. Use `includeDomains: ["anthropic.com","code.claude.com","github.com"]` to restrict to official sources. ⚠️ Can return huge payloads — pass `numResults` ≤ 5 and `textMaxCharacters` to stay manageable. |
| `mcp__exa__get_code_context_exa` | API/library usage examples & docs — use when the question is about the Claude API/SDK specifically. |

> Exa tools are only present if the Exa MCP server is connected. If the tools aren't available, silently fall back to WebSearch/WebFetch.

## Sources, in order of preference

Try the cheapest reliable source first; escalate only if it's empty.

1. **Local changelog cache** — `~/.claude/cache/changelog.md` (~418k, offline, always works). Best for "what changed in version X" / "when was feature Y added". No proxy needed.
2. **Official docs** via WebFetch — `https://code.claude.com/docs/en/<page>.md` (note the `.md` suffix for clean markdown). Best for how-to / settings / env vars / flags. No proxy needed. If WebFetch geo-blocks (307 on `platform.claude.com`), re-fetch with `mcp__exa__crawling_exa`.
3. **GitHub issues** via `gh` — `anthropics/claude-code`. Best for known bugs / behavior questions / confirming whether something is a reported issue. **Needs proxy (see `/proxy`).**
4. **Web search** via Exa (`mcp__exa__web_search_exa`, preferred) or WebSearch (fallback) — for recent info, when docs/gh are blocked, or to find a known URL before crawling it. No proxy needed.

## Workflows

### A. "What does X do?" (setting / env var / flag / feature)

1. Check the local changelog first if it sounds version-recent:
   ```bash
   grep -n -i "<term>" ~/.claude/cache/changelog.md | head -20
   ```
2. Fetch the relevant docs page (no proxy):
   ```
   WebFetch url="https://code.claude.com/docs/en/settings.md" prompt="What does <X> do?"
   ```
   Common pages: `settings`, `env-vars`, `cli-reference`, `hooks`, `slash-commands`, `mcp`, `model-config`, `costs`, `statusline`, `ide-integrations`.
3. **If WebFetch geo-blocks the URL** (307 redirect on `platform.claude.com`), re-fetch the exact same URL with `mcp__exa__crawling_exa` — it bypasses the block (verified).
4. **Delegate for hard "how do I / does Claude" questions**: spawn the `claude-code-guide` agent (purpose-built for Claude Code / SDK / API Q&A). It can search docs + release notes for you.
5. If docs are geo-blocked or empty after the Exa retry, fall back to Exa/WebSearch, then to grepping the changelog.

### B. "What changed in version X?" / release notes

1. Grep the local changelog (offline, fast):
   ```bash
   grep -n -i "^## 2.1.<X>\|<feature-term>" ~/.claude/cache/changelog.md | head -30
   ```
2. Present the matching `## <version>` entry. Quote it; don't paraphrase behavior.

### C. "Is this a known issue?" / search GitHub issues

This is the workflow that needs **proxy + gh together** — the network problem the user mentioned.

**Do NOT hand-roll the `gh` commands or proxy incantation here.** Read the **`/github` skill** — it is the source of truth for:
- proxy setup + the connectivity check sequence (it composes `/proxy` internally),
- the exact `gh issue list` / `gh issue view` / `gh api search/issues` commands and their qualifiers,
- the present-findings and create-issue (approval-gated) steps.

Workflow using those skills:

1. **Read `/github`** to load the issue-search workflow (and let it handle proxy via `/proxy`).
2. **Target repo**: `anthropics/claude-code` (unless the user names another).
3. **Extract keywords** from the user's description: error text, flag/function names, concepts. Drop stop words.
4. **Search open + closed issues** using the commands from `/github` (closed issues often carry the fix). Use `--repo anthropics/claude-code`.
5. **Read a specific issue + comments** using the read-issue step from **`/github`**, scoped to `--repo anthropics/claude-code` and `--comments` for the full discussion.
6. **Present findings**: exact matches (link + state), related issues, any known workaround from closed issues, and a verdict (known? open/closed? fix merged?).
7. If nothing matches: try broader keywords, then say it may be unreported and offer to draft a new issue — **never create/comment on an issue without explicit user approval** (per `/github`).

### D. Network failure recovery

If a `gh` command fails:
1. Was proxy enabled for that Bash call? Each Bash call is a fresh shell — consult **`/proxy`** for the correct enable command and re-run with proxy on.
2. Still failing? Use **`/proxy`**'s status check to diagnose, and enable explicitly — avoid the toggle alias (it can flip proxy off by accident). See `/proxy` for the exact commands.
3. If proxy is up but GitHub still fails, **search via Exa** (`mcp__exa__web_search_exa`) for the issue with the error text + "claude code issue" (no proxy needed); fall back to WebSearch if Exa is unavailable.
4. For geo-blocked doc URLs, re-fetch with `mcp__exa__crawling_exa` (verified bypass) before giving up.
5. As a last resort, suggest the user open the docs/issue URL directly in a browser.

## Answering

- Cite the source (docs URL, changelog version line, or issue number + link) for every non-obvious claim.
- If a source was unreachable (geo-block / network), say so explicitly and note which source you used instead — don't silently substitute.
- Quote docs/changelog verbatim for exact behavior; paraphrase only for summary.
- If the answer is model-dependent or version-dependent and you couldn't pin down the exact number, say that plainly rather than guessing.

## Notes

- **This skill orchestrates; it does not duplicate commands.** For proxy enablement and the exact `gh`/issue workflows, **read the `/proxy` and `/github` skills** — they are the source of truth and stay current. Inlining their commands here would drift.
- **Three fetchers, three rules**: WebFetch/WebSearch and Exa MCP = no proxy; `gh`/`curl`/`git` in Bash = proxy required (see `/proxy`), every call.
- **Exa MCP bypasses the `platform.claude.com` geo-block** that WebFetch hits — use `mcp__exa__crawling_exa` to re-fetch any URL WebFetch 307-redirects. If Exa tools aren't connected, silently fall back to WebSearch.
- Local changelog at `~/.claude/cache/changelog.md` is the fastest, most reliable source for version-specific questions — use it first.
- `code.claude.com/docs/en/*` works via WebFetch; `platform.claude.com/docs/*` is geo-blocked under WebFetch but reachable via Exa.
- Exa `web_search_advanced_exa` can return very large payloads — always pass `numResults` ≤ 5 and `textMaxCharacters`, and prefer `includeDomains` to official sources.
- Delegate deep Claude Code / SDK / API Q&A to the `claude-code-guide` agent when a single docs page won't suffice.
- Never create or comment on `anthropics/claude-code` issues without explicit user approval.
- Composes: `/proxy` (proxy enablement) and `/github` (gh + issue workflows) for the underlying commands.
