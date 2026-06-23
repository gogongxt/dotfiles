#!/usr/bin/env python3
"""pystow - A Python reimplementation of GNU Stow."""

import argparse
import os
import shutil
import sys
from pathlib import Path


def create_symlink(src: Path, dst: Path, simulate: bool, verbose: int) -> bool:
    """Create a relative symlink from dst -> src. Returns True on success."""
    rel_src = os.path.relpath(src, dst.parent)
    if verbose >= 1:
        print(f"LINK: {dst} -> {rel_src}")
    if simulate:
        return True
    try:
        dst.symlink_to(rel_src)
        return True
    except OSError as e:
        print(f"ERROR: cannot create symlink {dst}: {e}", file=sys.stderr)
        return False


def stow_package(
    package_dir: Path, target_dir: Path, simulate: bool, verbose: int, force: bool
) -> list[str]:
    """Stow a single package into the target directory.

    Walks the package tree. For each entry:
      - If the corresponding target path doesn't exist -> create a symlink.
      - If the target is already a symlink pointing into this package -> skip (idempotent).
      - If the target is a symlink pointing elsewhere -> CONFLICT, unless --force is
        given, in which case replace it with a symlink into this package.
      - If the target is a directory and the package entry is a directory -> recurse.
      - Otherwise (regular file or type mismatch) -> CONFLICT; --force never touches
        regular files, only replaces stray symlinks.
    """
    errors = []
    _stow_recursive(
        package_dir, package_dir, target_dir, simulate, verbose, force, errors
    )
    return errors


def _stow_recursive(
    pkg_root: Path,
    pkg_current: Path,
    target_current: Path,
    simulate: bool,
    verbose: int,
    force: bool,
    errors: list[str],
) -> None:
    for entry in sorted(pkg_current.iterdir()):
        target_entry = target_current / entry.name

        rel_from_pkg_root = entry.relative_to(pkg_root)
        target_in_pkg = pkg_root / rel_from_pkg_root

        if not target_entry.exists() and not target_entry.is_symlink():
            # Nothing at target — symlink the whole entry
            if not create_symlink(entry, target_entry, simulate, verbose):
                errors.append(str(target_entry))
        elif target_entry.is_symlink():
            # Target is already a symlink — check if it points into our package
            resolved = target_entry.resolve()
            try:
                pkg_resolved = target_in_pkg.resolve()
                if resolved == pkg_resolved:
                    if verbose >= 2:
                        print(f"SKIP: {target_entry} already points to {target_in_pkg}")
                elif force:
                    if verbose >= 1:
                        old_target = os.readlink(target_entry)
                        print(
                            f"REPLACE (force): {target_entry} -> {old_target} (will relink to {target_in_pkg})"
                        )
                    if not simulate:
                        target_entry.unlink()
                    if not create_symlink(entry, target_entry, simulate, verbose):
                        errors.append(str(target_entry))
                else:
                    msg = f"CONFLICT: {target_entry} already exists as symlink to {os.readlink(target_entry)}"
                    print(f"WARNING: {msg}", file=sys.stderr)
                    errors.append(msg)
            except OSError:
                errors.append(f"CONFLICT: {target_entry} is a broken symlink")
        elif target_entry.is_dir() and entry.is_dir():
            # Both are directories — recurse (directory folding)
            _stow_recursive(
                pkg_root, entry, target_entry, simulate, verbose, force, errors
            )
        else:
            # Regular file or type mismatch — never touched by --force
            msg = f"CONFLICT: {target_entry} already exists (regular file or type mismatch; --force does not touch regular files)"
            print(f"WARNING: {msg}", file=sys.stderr)
            errors.append(msg)


def delete_package(
    package_dir: Path, target_dir: Path, simulate: bool, verbose: int
) -> list[str]:
    """Unstow a package: remove symlinks that point into this package."""
    errors = []
    _delete_recursive(
        package_dir, package_dir, target_dir, target_dir, simulate, verbose, errors
    )
    return errors


def _delete_recursive(
    pkg_root: Path,
    pkg_current: Path,
    target_current: Path,
    target_root: Path,
    simulate: bool,
    verbose: int,
    errors: list[str],
) -> None:
    for entry in sorted(pkg_current.iterdir()):
        target_entry = target_current / entry.name

        rel_from_pkg_root = entry.relative_to(pkg_root)
        target_in_pkg = pkg_root / rel_from_pkg_root

        if target_entry.is_symlink():
            resolved = target_entry.resolve()
            try:
                pkg_resolved = target_in_pkg.resolve()
                if resolved == pkg_resolved:
                    if verbose >= 1:
                        print(f"UNLINK: {target_entry}")
                    if not simulate:
                        target_entry.unlink()
                    _prune_empty_parents(
                        target_entry.parent, target_root, simulate, verbose
                    )
                else:
                    if verbose >= 2:
                        print(f"SKIP: {target_entry} points elsewhere, not removing")
            except OSError as e:
                errors.append(f"ERROR checking symlink {target_entry}: {e}")
        elif target_entry.is_dir() and entry.is_dir():
            _delete_recursive(
                pkg_root, entry, target_entry, target_root, simulate, verbose, errors
            )
            _prune_empty_parents(target_entry, target_root, simulate, verbose)


def _prune_empty_parents(
    path: Path, stop_at: Path, simulate: bool, verbose: int
) -> None:
    """Remove empty directories from path up to (but not including) stop_at."""
    current = path
    while current != stop_at and current != current.parent:
        try:
            if current.is_dir() and not any(current.iterdir()):
                if verbose >= 2:
                    print(f"RMDIR: {current} (empty)")
                if not simulate:
                    current.rmdir()
                current = current.parent
            else:
                break
        except OSError:
            break


def restow_package(
    package_dir: Path, target_dir: Path, simulate: bool, verbose: int, force: bool
) -> list[str]:
    """Restow: delete then stow."""
    errors = delete_package(package_dir, target_dir, simulate, verbose)
    errors.extend(stow_package(package_dir, target_dir, simulate, verbose, force))
    return errors


def main():
    parser = argparse.ArgumentParser(
        prog="pystow",
        description="pystow - A Python reimplementation of GNU Stow",
    )
    parser.add_argument(
        "-t",
        "--target",
        default=None,
        help="Set target directory (default: parent of stow dir)",
    )
    parser.add_argument(
        "-d",
        "--dir",
        default=None,
        help="Set stow directory containing packages (default: current directory)",
    )
    parser.add_argument(
        "-S",
        "--stow",
        action="store_true",
        default=True,
        help="Stow the packages (default action)",
    )
    parser.add_argument(
        "-D",
        "--delete",
        action="store_true",
        help="Unstow the packages",
    )
    parser.add_argument(
        "-R",
        "--restow",
        action="store_true",
        help="Restow (delete then stow)",
    )
    parser.add_argument(
        "-n",
        "--no",
        "--simulate",
        action="store_true",
        dest="simulate",
        help="Simulate; don't make any filesystem changes",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Replace existing symlinks that point elsewhere; regular files are still NOT touched",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="Increase verbosity (can be repeated)",
    )
    parser.add_argument(
        "packages",
        nargs="+",
        metavar="package",
        help="Package directories to stow/unstow",
    )

    args = parser.parse_args()

    stow_dir = Path(args.dir).resolve() if args.dir else Path.cwd()
    target_dir = Path(args.target).resolve() if args.target else stow_dir.parent

    if not stow_dir.is_dir():
        print(f"ERROR: stow dir {stow_dir} does not exist", file=sys.stderr)
        sys.exit(1)

    if not target_dir.is_dir():
        print(f"ERROR: target dir {target_dir} does not exist", file=sys.stderr)
        sys.exit(1)

    all_errors = []

    # Determine the operation: -R takes precedence, then -D, default is -S
    if args.restow:
        op = "restow"
    elif args.delete:
        op = "delete"
    else:
        op = "stow"

    for pkg_name in args.packages:
        package_dir = stow_dir / pkg_name
        if not package_dir.is_dir():
            print(
                f"WARNING: package {pkg_name} not found in {stow_dir}", file=sys.stderr
            )
            all_errors.append(f"package {pkg_name} not found")
            continue

        if op == "stow":
            errors = stow_package(
                package_dir, target_dir, args.simulate, args.verbose, args.force
            )
        elif op == "delete":
            errors = delete_package(
                package_dir, target_dir, args.simulate, args.verbose
            )
        elif op == "restow":
            errors = restow_package(
                package_dir, target_dir, args.simulate, args.verbose, args.force
            )

        all_errors.extend(errors)

    if all_errors:
        sys.exit(1)


if __name__ == "__main__":
    main()
