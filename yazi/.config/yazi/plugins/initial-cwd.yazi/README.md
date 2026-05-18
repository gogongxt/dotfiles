# initial-cwd.yazi

Yazi plugin to cd back to the initial working directory.

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
