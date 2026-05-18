"""Tests for pystow — covers stow, delete, restow, directory folding, conflicts, simulate."""

import os
import subprocess
import sys
from pathlib import Path

import pytest

from main import create_symlink, delete_package, restow_package, stow_package

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


@pytest.fixture()
def workspace(tmp_path):
    """Provide a clean workspace with stow_dir and target_dir."""
    stow_dir = tmp_path / "stow"
    target_dir = tmp_path / "target"
    stow_dir.mkdir()
    target_dir.mkdir()
    return stow_dir, target_dir


def _make_package(stow_dir, name, files: dict[str, str]):
    """Create a package directory with given files.

    files: {"relative/path": "content", ...}
    """
    pkg = stow_dir / name
    pkg.mkdir(exist_ok=True)
    for rel, content in files.items():
        p = pkg / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content)
    return pkg


def _symlinks_in(target_dir):
    """Return a dict of {relative_path: link_target} for all symlinks under target_dir."""
    result = {}
    for root, dirs, files in os.walk(target_dir):
        for name in dirs + files:
            full = Path(root) / name
            if full.is_symlink():
                result[str(full.relative_to(target_dir))] = os.readlink(full)
    return result


# ---------------------------------------------------------------------------
# create_symlink unit tests
# ---------------------------------------------------------------------------


class TestCreateSymlink:
    def test_creates_relative_symlink(self, workspace):
        stow_dir, target_dir = workspace
        src = stow_dir / "myfile"
        src.write_text("hello")
        dst = target_dir / "myfile"

        assert create_symlink(src, dst, simulate=False, verbose=0)
        assert dst.is_symlink()
        assert os.readlink(dst) == os.path.relpath(src, dst.parent)
        assert dst.read_text() == "hello"

    def test_simulate_does_not_create(self, workspace):
        stow_dir, target_dir = workspace
        src = stow_dir / "myfile"
        src.write_text("hello")
        dst = target_dir / "myfile"

        assert create_symlink(src, dst, simulate=True, verbose=0)
        assert not dst.exists()
        assert not dst.is_symlink()


# ---------------------------------------------------------------------------
# stow_package — basic scenarios
# ---------------------------------------------------------------------------


class TestStowBasic:
    def test_stow_creates_top_level_symlinks(self, workspace):
        """Clean target: each top-level entry in package becomes a symlink."""
        stow_dir, target_dir = workspace
        pkg = _make_package(
            stow_dir,
            "mypkg",
            {
                ".bashrc": "alias ll='ls -la'",
                "bin/tool": "#!/bin/bash\necho hi",
            },
        )

        errors = stow_package(pkg, target_dir, simulate=False, verbose=0)
        assert errors == []

        links = _symlinks_in(target_dir)
        # .bashrc and bin/ are top-level entries → both become symlinks
        assert ".bashrc" in links
        assert "bin" in links
        # bin itself is the symlink, not bin/tool
        assert (target_dir / "bin" / "tool").read_text() == "#!/bin/bash\necho hi"

    def test_stow_deep_nested_structure(self, workspace):
        stow_dir, target_dir = workspace
        pkg = _make_package(
            stow_dir,
            "vim",
            {
                ".vim/autoload/plug.vim": "plug content",
                ".vim/colors/solarized.vim": "colors content",
            },
        )

        errors = stow_package(pkg, target_dir, simulate=False, verbose=0)
        assert errors == []

        links = _symlinks_in(target_dir)
        # .vim is the only top-level entry → one symlink
        assert list(links.keys()) == [".vim"]
        assert (
            target_dir / ".vim" / "autoload" / "plug.vim"
        ).read_text() == "plug content"

    def test_stow_multiple_packages(self, workspace):
        """Stowing two independent packages creates symlinks for both."""
        stow_dir, target_dir = workspace
        _make_package(stow_dir, "bash", {".bashrc": "bashrc"})
        _make_package(stow_dir, "vim", {".vim/README": "vim"})

        errors1 = stow_package(stow_dir / "bash", target_dir, simulate=False, verbose=0)
        errors2 = stow_package(stow_dir / "vim", target_dir, simulate=False, verbose=0)
        assert errors1 == [] and errors2 == []

        links = _symlinks_in(target_dir)
        assert ".bashrc" in links
        assert ".vim" in links

    def test_stow_idempotent(self, workspace):
        """Stowing the same package twice should produce no errors."""
        stow_dir, target_dir = workspace
        pkg = _make_package(stow_dir, "mypkg", {".bashrc": "content"})

        stow_package(pkg, target_dir, simulate=False, verbose=0)
        errors = stow_package(pkg, target_dir, simulate=False, verbose=0)
        assert errors == []


# ---------------------------------------------------------------------------
# directory folding — target dir already exists
# ---------------------------------------------------------------------------


class TestDirectoryFolding:
    def test_folding_when_target_dir_exists(self, workspace):
        """If target/.config already exists, stow creates symlink inside it."""
        stow_dir, target_dir = workspace
        pkg = _make_package(
            stow_dir,
            "app",
            {
                ".config/app/config.yml": "setting: true",
            },
        )
        # Pre-create .config in target (with other content)
        (target_dir / ".config" / "other").mkdir(parents=True)

        errors = stow_package(pkg, target_dir, simulate=False, verbose=0)
        assert errors == []

        links = _symlinks_in(target_dir)
        # .config is NOT a symlink (it's a real dir), but .config/app is
        assert ".config" not in links
        assert ".config/app" in links
        assert (
            target_dir / ".config" / "app" / "config.yml"
        ).read_text() == "setting: true"
        # other dir still exists
        assert (target_dir / ".config" / "other").is_dir()

    def test_deep_folding(self, workspace):
        """Multiple levels of existing directories should each be folded."""
        stow_dir, target_dir = workspace
        pkg = _make_package(
            stow_dir,
            "deep",
            {
                "a/b/c/file.txt": "deep",
            },
        )
        # Pre-create a/b in target
        (target_dir / "a" / "b" / "existing").mkdir(parents=True)

        errors = stow_package(pkg, target_dir, simulate=False, verbose=0)
        assert errors == []

        links = _symlinks_in(target_dir)
        # a and a/b are real dirs, a/b/c is the symlink
        assert "a" not in links
        assert "a/b" not in links
        assert "a/b/c" in links


# ---------------------------------------------------------------------------
# conflict detection
# ---------------------------------------------------------------------------


class TestConflicts:
    def test_conflict_existing_file(self, workspace):
        """Target has a real file where package wants to place a symlink."""
        stow_dir, target_dir = workspace
        pkg = _make_package(stow_dir, "app", {".bashrc": "new content"})
        # Pre-create a real file at target
        (target_dir / ".bashrc").write_text("old content")

        errors = stow_package(pkg, target_dir, simulate=False, verbose=0)
        assert len(errors) == 1
        assert "CONFLICT" in errors[0]
        # Original file should be untouched
        assert (target_dir / ".bashrc").read_text() == "old content"

    def test_conflict_symlink_to_other_package(self, workspace):
        """Target already has a symlink pointing to a different package."""
        stow_dir, target_dir = workspace
        pkg1 = _make_package(stow_dir, "pkg1", {".bashrc": "from pkg1"})
        pkg2 = _make_package(stow_dir, "pkg2", {".bashrc": "from pkg2"})

        stow_package(pkg1, target_dir, simulate=False, verbose=0)
        errors = stow_package(pkg2, target_dir, simulate=False, verbose=0)
        assert len(errors) == 1
        assert "CONFLICT" in errors[0]
        # Should still point to pkg1
        assert (target_dir / ".bashrc").read_text() == "from pkg1"


# ---------------------------------------------------------------------------
# delete_package
# ---------------------------------------------------------------------------


class TestDelete:
    def test_delete_removes_symlinks(self, workspace):
        stow_dir, target_dir = workspace
        pkg = _make_package(
            stow_dir,
            "mypkg",
            {
                ".bashrc": "content",
                "bin/tool": "#!/bin/bash",
            },
        )

        stow_package(pkg, target_dir, simulate=False, verbose=0)
        assert ".bashrc" in _symlinks_in(target_dir)

        errors = delete_package(pkg, target_dir, simulate=False, verbose=0)
        assert errors == []
        assert _symlinks_in(target_dir) == {}

    def test_delete_prunes_empty_dirs(self, workspace):
        """After delete, directories that become empty should be removed."""
        stow_dir, target_dir = workspace
        pkg = _make_package(
            stow_dir,
            "mypkg",
            {
                "bin/tool": "#!/bin/bash",
            },
        )

        stow_package(pkg, target_dir, simulate=False, verbose=0)
        assert (target_dir / "bin").is_symlink()

        delete_package(pkg, target_dir, simulate=False, verbose=0)
        # bin was a symlink, after removal the empty dir should be pruned
        assert not (target_dir / "bin").exists()

    def test_delete_preserves_dirs_with_other_content(self, workspace):
        """Directory folding: delete should only remove our symlink, not the shared dir."""
        stow_dir, target_dir = workspace
        pkg = _make_package(
            stow_dir,
            "app",
            {
                ".config/app/config.yml": "setting: true",
            },
        )
        (target_dir / ".config" / "other").mkdir(parents=True)

        stow_package(pkg, target_dir, simulate=False, verbose=0)
        assert ".config/app" in _symlinks_in(target_dir)

        errors = delete_package(pkg, target_dir, simulate=False, verbose=0)
        assert errors == []
        # .config/other should still exist
        assert (target_dir / ".config" / "other").is_dir()
        # .config/app should be gone
        assert not (target_dir / ".config" / "app").exists()

    def test_delete_simulate(self, workspace):
        """Simulate delete should not actually remove anything."""
        stow_dir, target_dir = workspace
        pkg = _make_package(stow_dir, "mypkg", {".bashrc": "content"})

        stow_package(pkg, target_dir, simulate=False, verbose=0)
        errors = delete_package(pkg, target_dir, simulate=True, verbose=0)
        assert errors == []
        # Symlink should still exist
        assert ".bashrc" in _symlinks_in(target_dir)

    def test_delete_non_stowed_package(self, workspace):
        """Deleting a package that was never stowed should produce no errors."""
        stow_dir, target_dir = workspace
        pkg = _make_package(stow_dir, "ghost", {".bashrc": "content"})

        errors = delete_package(pkg, target_dir, simulate=False, verbose=0)
        assert errors == []


# ---------------------------------------------------------------------------
# restow_package
# ---------------------------------------------------------------------------


class TestRestow:
    def test_restow_refreshes_symlinks(self, workspace):
        """Restow should delete old links and create new ones."""
        stow_dir, target_dir = workspace
        pkg = _make_package(stow_dir, "mypkg", {".bashrc": "content"})

        stow_package(pkg, target_dir, simulate=False, verbose=0)
        links_before = _symlinks_in(target_dir)

        errors = restow_package(pkg, target_dir, simulate=False, verbose=0)
        assert errors == []

        links_after = _symlinks_in(target_dir)
        assert links_before == links_after
        assert (target_dir / ".bashrc").read_text() == "content"

    def test_restow_picks_up_new_files(self, workspace):
        """After adding a file to the package, restow should link it."""
        stow_dir, target_dir = workspace
        pkg = _make_package(stow_dir, "mypkg", {".bashrc": "content"})

        stow_package(pkg, target_dir, simulate=False, verbose=0)
        assert ".profile" not in _symlinks_in(target_dir)

        # Add a new file to the package
        (pkg / ".profile").write_text("profile content")

        errors = restow_package(pkg, target_dir, simulate=False, verbose=0)
        assert errors == []
        assert ".profile" in _symlinks_in(target_dir)


# ---------------------------------------------------------------------------
# simulate mode
# ---------------------------------------------------------------------------


class TestSimulate:
    def test_simulate_stow_creates_nothing(self, workspace):
        stow_dir, target_dir = workspace
        pkg = _make_package(stow_dir, "mypkg", {".bashrc": "content"})

        errors = stow_package(pkg, target_dir, simulate=True, verbose=0)
        assert errors == []
        assert _symlinks_in(target_dir) == {}

    def test_simulate_delete_removes_nothing(self, workspace):
        stow_dir, target_dir = workspace
        pkg = _make_package(stow_dir, "mypkg", {".bashrc": "content"})

        stow_package(pkg, target_dir, simulate=False, verbose=0)
        delete_package(pkg, target_dir, simulate=True, verbose=0)
        assert ".bashrc" in _symlinks_in(target_dir)


# ---------------------------------------------------------------------------
# CLI integration (pystow bash script)
# ---------------------------------------------------------------------------


class TestCLI:
    def test_cli_stow_and_delete(self, workspace):
        stow_dir, target_dir = workspace
        _make_package(stow_dir, "mypkg", {".bashrc": "cli content"})

        result = subprocess.run(
            [
                sys.executable,
                str(Path(__file__).parent / "main.py"),
                "-d",
                str(stow_dir),
                "-t",
                str(target_dir),
                "mypkg",
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0
        assert (target_dir / ".bashrc").read_text() == "cli content"

        # Delete
        result = subprocess.run(
            [
                sys.executable,
                str(Path(__file__).parent / "main.py"),
                "-d",
                str(stow_dir),
                "-t",
                str(target_dir),
                "-D",
                "mypkg",
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0
        assert not (target_dir / ".bashrc").exists()

    def test_cli_simulate(self, workspace):
        stow_dir, target_dir = workspace
        _make_package(stow_dir, "mypkg", {".bashrc": "cli content"})

        result = subprocess.run(
            [
                sys.executable,
                str(Path(__file__).parent / "main.py"),
                "-d",
                str(stow_dir),
                "-t",
                str(target_dir),
                "-n",
                "mypkg",
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0
        assert not (target_dir / ".bashrc").exists()

    def test_cli_restow(self, workspace):
        stow_dir, target_dir = workspace
        _make_package(stow_dir, "mypkg", {".bashrc": "cli content"})

        # Stow first
        subprocess.run(
            [
                sys.executable,
                str(Path(__file__).parent / "main.py"),
                "-d",
                str(stow_dir),
                "-t",
                str(target_dir),
                "mypkg",
            ],
            capture_output=True,
            text=True,
        )

        # Restow
        result = subprocess.run(
            [
                sys.executable,
                str(Path(__file__).parent / "main.py"),
                "-d",
                str(stow_dir),
                "-t",
                str(target_dir),
                "-R",
                "mypkg",
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0
        assert (target_dir / ".bashrc").read_text() == "cli content"

    def test_cli_missing_package_exits_1(self, workspace):
        stow_dir, target_dir = workspace
        result = subprocess.run(
            [
                sys.executable,
                str(Path(__file__).parent / "main.py"),
                "-d",
                str(stow_dir),
                "-t",
                str(target_dir),
                "nonexistent",
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 1

    def test_cli_multiple_packages(self, workspace):
        stow_dir, target_dir = workspace
        _make_package(stow_dir, "pkg1", {".bashrc": "bash"})
        _make_package(stow_dir, "pkg2", {".vimrc": "vim"})

        result = subprocess.run(
            [
                sys.executable,
                str(Path(__file__).parent / "main.py"),
                "-d",
                str(stow_dir),
                "-t",
                str(target_dir),
                "pkg1",
                "pkg2",
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0
        assert (target_dir / ".bashrc").read_text() == "bash"
        assert (target_dir / ".vimrc").read_text() == "vim"
