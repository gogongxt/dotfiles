# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a shell helper configuration library (`~/.sh_help`) providing aliases, functions, and shell integrations for both zsh and bash. It's sourced by `.zshrc` or `.bashrc` during shell initialization.

## Architecture

```
init.sh          → Entry point, sources all modules
config.sh        → Core aliases, env vars, tool configs
functions/       → Utility functions (copy, extract, log, proxy, trash)
completion/      → Shell completion (nsys, tmux)
zsh/             → Zsh-specific configs (vi-mode)
```

Load order: `init.sh` → `config.sh` → `functions/*` → `completion/*` → `zsh/*` or `bash/*`

## Key Function Modules

- **proxy.sh**: `proxy on|off|toggle|status` - manage environment proxy variables
- **trash.sh**: trash-cli wrapper, `rm` aliased to `trash-put`, `trash-delete` for batch operations
- **log.sh**: `mylog <command>` - run command with timestamped logging to `~/logs/`
- **extract.sh**: `extract <archive>` - universal archive extraction supporting .tar.*, .zip, .7z, etc.
- **copy.sh**: clipboard utilities

## Tmux Wrapper

`completion/tmux.sh` provides a tmux wrapper with custom subcommands:
- `tmux <session>` - attach or create session
- `tmux ls` - list sessions
- `tmux rm <session>` - kill session
- `tmux sw` - switch window (fzf)
- `tmux cd <path>` - set `TMUX_WORKING_DIR`
- `tmux save [file]` - capture pane content

## Configuration Conventions

- Blocks marked with `#🔽🔽🔽` and `#🔼🔼🔼` delimiters for readability
- Feature detection via `command -v <tool> &>/dev/null` before enabling features
- Supports both zsh and bash via `$ZSH_VERSION`/`$BASH_VERSION` checks
- Lazy loading for conda to improve shell startup time
