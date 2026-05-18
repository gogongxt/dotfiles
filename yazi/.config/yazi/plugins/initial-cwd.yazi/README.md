# initial-cwd.yazi

Yazi plugin to cd back to the initial working directory (the directory where Yazi was launched).

## Install

```bash
ya pkg add gogongxt/initial-cwd
```

## Usage

Add keybinding in your `keymap.toml`:

```toml
[mgr.prepend_keymap]
{ on = [ "g", " " ], run = "plugin initial-cwd", desc = "Go to initial directory" },
```

Add setup in your `init.lua`:

```lua
require("initial-cwd"):setup()
```

This must be called to capture the initial working directory at startup.
