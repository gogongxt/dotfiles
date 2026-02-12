# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About This Configuration

This is a Yazi file manager configuration located at `~/.config/yazi/`. It extends Yazi's default functionality with numerous custom plugins and enhancements, following Yazi's modular plugin architecture.

## Configuration File Structure

### Core Configuration Files

- **init.lua** - Main initialization script. Loads plugins and modifies UI components (status bar, header).
- **yazi.toml** - Core Yazi settings (preview dimensions, opener rules, previewers).
- **keymap.toml** - Keyboard shortcuts and keybinding definitions.
- **theme.toml** - UI theme and styling configuration.
- **package.toml** - Plugin dependency management with pinned revisions.

### Plugin System

Yazi uses a TOML-based dependency manager. Plugins are defined in `package.toml` with:
- `use` - Plugin identifier (format: `user/repo:plugin-name`)
- `rev` - Git commit hash for version pinning
- `hash` - Content hash for verification

Plugins are loaded in `init.lua` via `require("plugin-name"):setup()`.

### Custom Plugins

The `plugins/` directory contains locally developed plugins (mainly from `gogongxt/*`):

- **copy-path.yazi** - Advanced path copying (full path, filename, basename, extension, relative path)
- **smart-tab.yazi** - Intelligent tab management (switch to existing tabs or create new ones, numeric keys 1-0)
- **lines-linemode.yazi** - Display line counts in file listings with background caching

Each plugin is a self-contained directory with `main.lua` as the entry point.

### Flavors (Themes)

Theme definitions are stored in `flavors/` directory. This config uses **Catppuccin Macchiato** dark flavor. Flavors define color schemes for UI elements.

## Architecture Patterns

### Status Bar Extensions

Status bar components are added using `Status:children_add()`:

```lua
Status:children_add(function()
    -- Return ui.Line or ui.Span
end, priority, Position)  -- Position: Status.LEFT or Status.RIGHT
```

Priority determines display order (lower number = higher priority).

### Plugin Fetchers and Previewers

In `yazi.toml`, plugins can add fetchers (for getting file metadata) and previewers (for displaying file content):

```toml
[[plugin.prepend_fetchers]]
id = "plugin-id"
name = "pattern"
run = "command"

[[plugin.prepend_previewers]]
name = "pattern"
run = "shell command"
```

### Keymap Structure

Keymaps in `keymap.toml` follow a nested structure:

```toml
[manager]
keymap = [
    { on = "<key>", run = "<command>" },
    { on = "<key>", run = "<command>", exec = "<condition>" }
]
```

The `exec` field conditionally executes keybindings based on shell-like conditions (e.g., `has_selected`, "!has_selected`).

## Common Development Tasks

### Adding a New Plugin

1. Add to `package.toml`:
```toml
[[plugin.deps]]
use = "user/repo:plugin-name"
rev = "commit-hash"
hash = "content-hash"
```

2. Load in `init.lua`:
```lua
require("plugin-name"):setup()
```

3. If needed, add fetchers/previewers to `yazi.toml`

### Modifying the Status Bar

Edit `init.lua` to add UI components:

```lua
Status:children_add(function(self)
    -- Access current file via self._current.hovered
    -- Return ui.Line or string
end, 500, Status.LEFT)
```

### Adding Keybindings

Edit `keymap.toml`. Keybindings can be in:
- `[manager.keymap]` - Main file browser
- `[tasks.keymap]` - Task manager
- `[select.keymap]` - File selection mode
- `[input.keymap]` - Command input
- `[help.keymap]` - Help menu
- `[completion.keymap]` - Command completion

### Custom Openers

Add to `yazi.toml` under `[open]`:

```toml
[open]
prepend_rules = [
    { name = "*.ext", use = "opener-name" }
]
```

## Custom Plugin Development

### Plugin Structure

```
plugins/your-plugin.yazi/
├── main.lua           # Required entry point
├── README.md          # Documentation
└── (other files)
```

### Main.lua Template

```lua
local function setup()
    -- Plugin initialization
end

return { setup = setup }
```

### Common Yazi APIs

- `ya` - Core Yazi functions (user_name, target_family, etc.)
- `cx.active` - Active context (current tab, hovered file, etc.)
- `ui.Line` / `ui.Span` - UI rendering components
- `Status` / `Header` - UI container registration

## Testing Configuration

After making changes:
1. Reload Yazi or restart the application
2. Check for Lua syntax errors: `luac -p init.lua`
3. Verify TOML syntax: Use a TOML linter or parser
4. Test keybindings and plugins interactively

## Notes

- Git integration is configured via the git.yazi plugin with fetchers prepended for all files
- The `piper` plugin enables shell command-based previews (e.g., markdown rendering with glow)
- Starship integration provides dynamic prompt information
- Tab switching uses numeric keys 1-0 via the smart-tab plugin
