# handoff

Type `/handoff` to hand the work off to a fresh context.

The mod asks Claude to write its goal, state, decisions and next action to a
markdown file, then compacts the conversation with that file's path kept, then
starts the next turn by reading the file and continuing. Nothing fires on a
token count: you decide when the context has gone muddy, and the model decides
nothing about timing.

## Use

Type `/handoff` at the prompt. Optionally add a focus, as in
`/handoff keep the parser refactor and the failing test`.

1. Claude writes `/tmp/claude-handoff-<session-id>.md`.
2. When the file appears, the mod compacts the conversation.
3. When compaction finishes, the next turn reads the note and picks the work up.

Every step reports itself with a toast, so you can see where it got to.

## What it does not do

- It does not run in `claude -p` or an SDK host: `$.session.compact()` is a stub
  there and always rejects. A terminal session is required.
- It does not touch the conversation until the note is written. If the write
  never happens (the turn is interrupted, or a subagent wrote it instead), the
  mod gives up after a few turns and says so.
- It respects a veto: if a `PreCompact` hook blocks compaction, the note stays
  saved and nothing resumes.

## Install

From a folder, for one session:

```
claude --plugin-dir <this folder>
```

Or add the folder as a marketplace and install it by name.
