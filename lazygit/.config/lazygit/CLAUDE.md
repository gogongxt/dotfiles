# Lazygit Configuration

Location: `lazygit/.config/lazygit/config.yml`

## Viewing All Config Options

```bash
lazygit --config
```

This outputs the full default config with all supported keys, including `gui`, `git`, `keybinding`, `update`, `refresher`, `customCommands`, etc.

## Config Structure

- **gui** - UI appearance (theme colors, scroll behavior, icons, panel layout)
- **git** - Git behavior (merging, branching, pagers, log format, auto-fetch)
- **keybinding** - Custom keybindings for all views
- **customCommands** - User-defined commands
- **services** - External service integrations (e.g. GitHub)

## Current Customizations

```yaml
keybinding:
  universal:
    gotoTop: g
    gotoBottom: G
```

Overrides default `<`/`>` with vim-style `g`/`G`.

## Keybinding Sections

Each `keybinding` subsection maps to a lazygit view:

| Section          | View                   |
| ---------------- | ---------------------- |
| `universal`      | All views              |
| `status`         | Status panel           |
| `files`          | Files panel            |
| `branches`       | Branches panel         |
| `worktrees`      | Worktrees panel        |
| `commits`        | Commits panel          |
| `amendAttribute` | Amend attribute menu   |
| `stash`          | Stash panel            |
| `commitFiles`    | Commit files panel     |
| `main`           | Main (diff/patch) view |
| `submodules`     | Submodules panel       |
| `commitMessage`  | Commit message editor  |
