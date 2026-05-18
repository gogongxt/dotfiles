# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

pystow is a Python reimplementation of GNU Stow for managing dotfiles via symlinks. It has zero runtime dependencies (pure standard library) and is not packaged for pip — it runs directly from the checkout directory.

## Commands

```bash
# Run all tests
./test.sh
# or
python -m pytest test_main.py -v

# Run a single test
python -m pytest test_main.py::TestStowBasic::test_stow_creates_top_level_symlinks -v

# Run tests by keyword
python -m pytest test_main.py -k "test_stow_idempotent" -v

# Run the CLI
./pystow -t ~/dotfiles -d ~ -S vim bash
```

No linter, formatter, or type checker is configured.

## Architecture

Single-file design: all logic lives in `main.py` (~270 lines).

- **Entry point**: `./pystow` is a bash wrapper that execs `main.py`
- **Core functions**: `stow_package()`, `delete_package()`, `restow_package()` — each accepts `simulate` flag for dry-run
- **Recursive tree walking**: Both stow and delete use `_stow_recursive()` / `_delete_recursive()` to walk the package directory, mapping entries to corresponding target paths
- **Directory folding**: When the target already has a real directory matching a package directory, the algorithm recurses into both instead of replacing with a symlink
- **Relative symlinks**: All symlinks use `os.path.relpath()` for portability
- **Error accumulation**: Operations collect errors into a list rather than raising; processing continues on conflict (best-effort, matches GNU Stow behavior)
- **Empty directory pruning**: `_prune_empty_parents()` walks upward after deletion, removing empty dirs up to the target root

## Test Structure

- Tests import directly from `main` (`from main import ...`)
- All tests use pytest `tmp_path` via a `workspace` fixture that creates `stow_dir` and `target_dir` subdirectories
- `TestCLI` runs `main.py` as a subprocess rather than calling functions directly
- Test classes: TestStowBasic, TestStowWithDirs, TestStowIdempotent, TestConflicts, TestDelete, TestDeleteWithDirs, TestRestow, TestCLI

## Not Implemented (vs GNU Stow)

--ignore, --defer, --override, --adopt, --dotfiles

## Documentation Language

README and design docs (`docs/design.md`) are written in Chinese.
