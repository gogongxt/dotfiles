# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal dotfiles repository managed with GNU Stow. Each top-level directory is a "package" that gets symlinked to the home directory via `stow -t ~ <package>`.

## Key Packages

- **nvim** - AstroNvim v6 configuration (Lazy.nvim plugin manager, Lua-based)
- **zsh** - Zsh config with oh-my-zsh, powerlevel10k theme, zsh-vi-mode
- **tmux** - Tmux config with TPM plugin manager
- **yazi** - Yazi file manager with custom plugins
- **macos/sketchybar** - macOS status bar (SketchyBar + yabai integration)
- **kitty** - Kitty terminal config
- **scripts** - Utility scripts organized by category (macos, linux, ssh, etc.)

## Stow Commands

```bash
stow -t ~ */           # Stow all packages
stow -t ~ nvim zsh     # Stow specific packages
stow -D -t ~ nvim      # Unstow a package
```

If a config file already exists, backup and remove it before stowing.

## Neovim Configuration

Located at `nvim/.config/nvim/`. Uses AstroNvim v6 with Lazy.nvim.

- **init.lua** - Entry point
- **lua/lazy_setup.lua** - Lazy.nvim setup, imports plugins
- **lua/mappings.lua** - Helper for registering keymaps with which-key support
- **lua/plugins/** - Plugin specs (each `_*_.lua` file is a plugin configuration)
- **lua/polish.lua** - Final setup, autocmds, and polish

Leader key is `,`. Plugins are in `~/.local/share/nvim/lazy/` after installation.

### Adding a Plugin

Create `lua/plugins/_pluginname_.lua`:

```lua
return {
  "author/plugin-name",
  event = "VeryLazy",
  opts = {},
}
```

## Zsh Configuration

- **.zshrc** - Main config, sources oh-my-zsh and shell helpers
- **.sh_help/** - Modular shell config library (aliases, functions, completions)
- **.p10k.zsh** - Powerlevel10k theme config

Load order: `.zshrc` → oh-my-zsh → `.p10k.zsh` → `.sh_help/init.sh`

### Shell Helper Architecture

```
.sh_help/init.sh     → Entry point, sources all modules
.sh_help/config.sh   → Core aliases, env vars, tool configs
.sh_help/functions/  → Utility functions (proxy, trash, log, extract, copy)
.sh_help/completion/ → Shell completion (tmux wrapper, nsys)
```

Key functions:
- `proxy on|off|toggle|status` - Manage proxy env vars
- `mylog <cmd>` - Run command with timestamped logging to `~/logs/`
- `extract <archive>` - Universal archive extraction
- `trash-delete` - Batch trash operations

## Tmux Configuration

Located at `tmux/.config/tmux/`. Uses TPM for plugins.

After config changes, restart tmux: `tmux kill-server && tmux`

### TPM Commands

- `prefix + I` - Install plugins
- `prefix + U` - Update plugins
- `prefix + Alt + u` - Remove unused plugins

## Yazi Configuration

Located at `yazi/.config/yazi/`.

- **init.lua** - Loads plugins, modifies status bar/header
- **yazi.toml** - Core settings, openers, previewers
- **keymap.toml** - Keybindings
- **package.toml** - Plugin dependencies with pinned revisions
- **plugins/** - Custom local plugins

## macOS SketchyBar Configuration

Located at `macos/sketchybar/.config/sketchybar/`.

- **sketchybarrc** - Main entry point
- **plugins/** - Dynamic content plugins (lyrics, space poller, etc.)

Commands:
- `sketchybar --reload` - Reload config
- `sketchybar --update` - Update all items

## Configuration Patterns

### Block Delimiters

Configs use `#🔽🔽🔽` and `#🔼🔼🔼` markers to delimit custom sections for readability.

### Feature Detection

Shell configs use `command -v <tool> &>/dev/null` before enabling features.

### Conditional Platform Support

- `archlinux/` - Arch Linux specific (i3, polybar)
- `macos/` - macOS specific (yabai, sketchybar)

Platform-specific code checks `uname` or uses separate directories.
