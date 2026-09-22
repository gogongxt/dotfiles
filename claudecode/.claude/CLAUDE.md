## Network Environment Guidelines

The current runtime environment is located in China, where access to some overseas services (such as GitHub, YouTube, and other global platforms) may be unstable or slow.

Follow these guidelines when accessing external resources:

- For services that may be affected by regional network restrictions, use the `/proxy` skill when necessary.
- This includes platforms such as GitHub, YouTube, and other non-mainland services where direct access may be unreliable.
- Do not use the proxy by default. Use it only when direct access is unavailable, unstable, or significantly degraded.

## GitHub Access Guidelines

When working with GitHub-related resources:

- Prefer using the GitHub CLI (`gh`) when it provides a more reliable or efficient way to access GitHub repositories, issues, pull requests, releases, or other GitHub resources.
- Before using `gh` commands, read and follow the `/github` skill instructions.
- For simple public information retrieval, other available methods may be used when appropriate.

## General Principles

- Prefer reliable access methods instead of repeatedly retrying failed network requests.
- Use available skills when they provide environment-specific workflows or better reliability.
- Keep normal workflows unchanged unless additional handling is required due to network constraints.

<!-- CODEGRAPH_START -->
## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
<!-- CODEGRAPH_END -->

@RTK.md
