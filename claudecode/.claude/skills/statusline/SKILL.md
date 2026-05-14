---
name: webup-statusline
description: Generate and install a custom Claude Code status line with selectable columns (model, context, effort level, git, dir, worktree, vim) and a color theme. Context and effort elements color-change based on level. Triggers on "status line", "statusline", "customize status", "status bar", "effort level display", "状态栏", "ステータスライン", or similar.
---

# Status Line Generator

Generate a custom Claude Code status line script with your choice of columns and a color theme. Installs directly to `~/.claude/settings.json`.

## How It Works

Claude Code supports custom status lines via a shell script configured in `~/.claude/settings.json`. The script receives session JSON on stdin (model, context window, workspace, vim, worktree, etc.) and prints formatted text to stdout.

This skill generates a bash script tailored to your preferences and installs it automatically.

## Script Directory

**Important**: All scripts are located in the `scripts/` subdirectory of this skill.

**Agent Execution Instructions**:

1. Determine this SKILL.md file's directory path as `SKILL_DIR`
2. Script path = `${SKILL_DIR}/scripts/<script-name>.mjs`
3. Replace all `${SKILL_DIR}` in this document with the actual path

**Script Reference**:
| Script | Purpose |
|--------|---------|
| `scripts/generate.mjs` | Generate and install status line script from chosen options |

## Prerequisites

- **jq** — required by the generated status line script to parse JSON input from Claude Code. On Windows, the script auto-detects jq installed via WinGet or scoop; if jq is still not found, add its directory to your PATH manually.
- **Bun** — required to run the generator. Use `npx -y bun` if not installed globally.

## Usage

```bash
# Preview generated script
npx -y bun ${SKILL_DIR}/scripts/generate.mjs --elements model,context,effort,git,dir --theme gruvbox

# Generate and install
npx -y bun ${SKILL_DIR}/scripts/generate.mjs --elements model,context,effort,git,dir --theme dracula --install
```

### Options

| Flag                     | Default                                         | Description                                                                                                                    |
| ------------------------ | ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `--elements <list>`      | `model,context,cost,effort,style,git,dir`       | Comma-separated columns to display                                                                                             |
| `--theme <name>`         | `gruvbox`                                       | Color theme — see table below                                                                                                  |
| `--effort-icon <preset>` | `arrow` (`↯`) for iconic themes, none otherwise | Override the effort prefix icon. Presets: `arrow`, `bolt`, `flash`, `reason`, `dot`, `none`. A raw character is also accepted. |
| `--install`              | off                                             | Write script to `~/.claude/scripts/statusline.sh` and update `settings.json`                                                   |

### Columns

| Column     | Description                                                                    | Data source                                                                  |
| ---------- | ------------------------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| `model`    | Active model name (e.g. "Opus 4.7")                                            | `model.display_name`                                                         |
| `context`  | Progress bar + percentage — **color changes with remaining capacity**          | `context_window.remaining_percentage`                                        |
| `cost`     | Session API spend formatted as `$X.XX` in gold — hidden when rounds to `$0.00` | `cost.total_cost_usd` from input JSON                                        |
| `effort`   | Reasoning effort level — **color changes with level**                          | `effortLevel` in `~/.claude/settings.local.json` → `~/.claude/settings.json` |
| `style`    | Output style name (e.g. Explanatory, Learning) — hidden when "default"         | `output_style.name` from input JSON                                          |
| `git`      | Git branch name (yellow when dirty)                                            | `worktree.branch` → git CLI                                                  |
| `dir`      | Repo basename (original repo when in a worktree)                               | `worktree.original_repo_dir` → `workspace.current_dir`                       |
| `worktree` | Bold `worktree:<id>` label (hidden outside a worktree)                         | `worktree.name` → parent-dir basename via git CLI                            |
| `vim`      | Vim mode indicator (hidden when inactive)                                      | `vim.mode`                                                                   |

### Color-changing elements

**`context`** — bar fill + percentage color scale with remaining capacity:

| Remaining | Color  | Meaning                    |
| --------- | ------ | -------------------------- |
| > 50%     | green  | plenty of context          |
| 20–50%    | yellow | watch out                  |
| < 20%     | red    | nearly full — compact soon |

**`effort`** — value + optional prefix icon color by level:

| Level                    | Color                                 |
| ------------------------ | ------------------------------------- |
| `max`, `xhigh`, `high`   | **bold red**                          |
| `medium`                 | yellow                                |
| `low`, `xlow`, `minimal` | green                                 |
| other / unset            | dim (or hidden when completely unset) |

### Themes

| Theme          | Vibe                         | Icons rendered in bar                                                            |
| -------------- | ---------------------------- | -------------------------------------------------------------------------------- |
| `gruvbox`      | Warm retro, muted            | `✦` model · `↯` effort · `❋` style · `⌂` dir · `⊕` worktree · `⎇` git · `⌨` vim |
| `dracula`      | Modern dark, high saturation | `◈` model · `↯` effort · `❋` style · `⌂` dir · `⊕` worktree · `⎇` git · `⌨` vim |
| `robbyrussell` | Classic oh-my-zsh            | no prefix icons — colors + labels only                                           |
| `minimal`      | Default terminal colors      | no prefix icons — plain text                                                     |

The `context` column intentionally skips a prefix icon — the colored progress bar is already visually rich. The `effort` prefix (`↯`) is baked into iconic themes and can be overridden with `--effort-icon`.

### Effort icons

Pass `--effort-icon <preset>` to swap the glyph in front of the effort value. Presets:

| Preset   | Glyph    | Notes                                                |
| -------- | -------- | ---------------------------------------------------- |
| `arrow`  | `↯`      | Electric arrow — **default**, narrow                 |
| `bolt`   | `ϟ`      | Greek koppa — narrow lightning                       |
| `flash`  | `⚡`     | Classic lightning — wide in emoji-presentation fonts |
| `reason` | `∴`      | Therefore                                            |
| `dot`    | `◉`      | Filled circle                                        |
| `none`   | (hidden) | Drop the icon entirely                               |

You can also pass any raw character as `--effort-icon <char>`.

**Worktree behavior**: When inside a git worktree (detected via the input JSON's `worktree.*` fields or via `git rev-parse --git-common-dir` fallback), the `worktree` column shows a bold `worktree:<id>` label using the parent dir name (e.g. `~/.codex/worktrees/46a6/clawmaster` → `worktree:46a6`). The `git` column prefers `worktree.branch` from the input JSON; the `dir` column prefers `worktree.original_repo_dir` so the repo identity stays stable across worktrees.

## Invocation

This skill can be invoked with or without arguments:

- **No args** (`/webup-statusline`): Interactive prompt via `AskUserQuestion` to pick columns and theme.
- **With args** (`/webup-statusline dracula`): NLP parse for theme and column preferences.

### Arg parsing (natural language)

The args string is free-form text. Use NLP to extract:

1. **theme** — match against: gruvbox, robbyrussell, minimal, dracula. Recognize aliases (暗黑=dracula, 极简=minimal, 复古=gruvbox, レトロ=gruvbox).
2. **elements** — look for mentions of: model, context/进度/コンテキスト, effort/推理强度/努力度, git/分支/ブランチ, dir/目录/ディレクトリ, worktree/工作树/ワークツリー, vim.

Unspecified fields use defaults: `model,context,effort,git,dir` columns, `gruvbox` theme.

## Workflow

1. **If no args provided**: Use `AskUserQuestion` to ask 2 questions in a single prompt. `AskUserQuestion` caps each question at 4 options, so **offer curated presets for columns** rather than an exhaustive toggle list. If the user picks "Other", interpret their free text as a comma-separated column list (or a natural-language description that maps to one).

   **Q1 — Column preset** (single): Which columns to display? Offer these 3 curated presets — `AskUserQuestion` will auto-append an "Other" option that lets the user type a free-text column list or description.

   - "Everything (Recommended)" — `model,context,cost,effort,style,git,dir,worktree` (all columns that have a useful signal today; `vim` is excluded because most users don't use vim keybindings)
   - "Default" — `model,context,effort,style,git,dir` (balanced — drops cost and worktree; matches the skill's default flag value)
   - "Essentials" — `model,context,git,dir` (lean; no effort, no style, no cost)

   If the user picks the auto-added "Other", treat their free text as a comma-separated column list, or as a natural-language description to map to columns. Fall back to `Default` if parsing is ambiguous.

   **Q2 — Theme** (single): Color theme?

   - "Dracula" — modern dark, purple/pink/cyan (Recommended)
   - "Gruvbox Dark" — warm retro palette, 24-bit true color
   - "Robbyrussell" — classic oh-my-zsh style, no icons
   - "Minimal" — no decoration, dim separators only

   **If args provided**: Parse theme and columns from args. Skip the prompt.

2. Map user selections to script flags:

   - Column preset → expand to the preset's canonical `--elements` list:
     - `Everything` → `model,context,cost,effort,style,git,dir,worktree`
     - `Default` → `model,context,effort,style,git,dir`
     - `Essentials` → `model,context,git,dir`
     - `Other` (auto-added by `AskUserQuestion`) → parse the user's free text; keep only recognized column names (`model,context,cost,effort,style,dir,worktree,git,vim`). If parsing is ambiguous, fall back to `Default`.
   - Theme → `--theme` value (one of `gruvbox`, `dracula`, `robbyrussell`, `minimal`)

3. Run the generator with `--install`:

   ```bash
   npx -y bun ${SKILL_DIR}/scripts/generate.mjs --elements <list> --theme <theme> --install
   ```

4. Tell user to restart Claude Code to see the new status line.

## Output Examples

**Dracula** (all columns), remaining=49%, cost=$0.42, effort=high, output style=Explanatory, inside a worktree:

```
◈ Opus 4.7 | [■■■■■■■■■■□□□□□□□□□□] 51% | $0.42 | ↯ high | ❋ Explanatory | ⌂ clawmaster | ⊕ worktree:46a6 | ⎇ feat/xyz
```

(bar yellow — 49% remaining; `$0.42` gold session spend next to the bar; effort "high" bold red; purple `❋ Explanatory` sits between effort and dir; context carries no prefix icon — the bar is already visual enough)

**Gruvbox Dark** (model + context + effort + dir + git), remaining=88%, effort=medium:

```
✦ Opus 4.7 | [■■□□□□□□□□□□□□□□□□□□] 12% | ↯ medium | ⌂ skills-cc | ⎇ main
```

(bar green — 88% remaining; effort "medium" yellow)

**Minimal** (model + effort + dir + git), effort=low:

```
Claude Opus 4.7 · low · skills-cc · main
```

(no prefix icons in minimal; effort "low" green)

## Notes

- Generated script is saved to `~/.claude/scripts/statusline.sh`
- Running the skill again overwrites the existing script — just re-run to change theme or columns
- The script uses `jq` to parse JSON input — make sure it's installed. On Windows, the script auto-detects WinGet and scoop jq paths; if jq is still not found, add it to PATH manually.
- Git dirty detection uses `--no-optional-locks` to avoid interfering with other git operations
