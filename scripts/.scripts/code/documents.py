#!/usr/bin/env python3
import argparse
import fnmatch
import mimetypes
import os
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Callable, List, Optional, Tuple

# Try to import rich for progress bar, fall back to a dummy implementation
try:
    from rich.progress import (
        BarColumn,
        Progress,
        SpinnerColumn,
        TextColumn,
        TimeElapsedColumn,
    )
except ImportError:
    # Dummy Progress class if rich is not installed
    class Progress:
        def __init__(self, *args, **kwargs):
            pass

        def __enter__(self):
            return self

        def __exit__(self, *args, **kwargs):
            pass

        def add_task(self, *args, **kwargs):
            return 0

        def update(self, *args, **kwargs):
            pass


# Try to import pyperclip for clipboard functionality
try:
    import pyperclip
except ImportError:
    pyperclip = None

# --- Constants ---
# Files and directories to always ignore
DEFAULT_IGNORE_PATTERNS = [
    ".git",
    ".gitignore",
    ".idea",
    ".vscode",
    "__pycache__",
    "*.pyc",
    "*.pyo",
    "*.pyd",
    "*egg-info",
    ".DS_Store",
    "node_modules",
    "dist",
    "build",
    "venv",
    ".env",
]
# Common text file extensions to prioritize for content inclusion
TEXT_MIMETYPES = [
    "application/json",
    "application/javascript",
    "application/xml",
    "application/sql",
    "application/x-sh",
    "text/",
]


def _format_size(size_bytes: int) -> str:
    """Format file size in human readable format."""
    if size_bytes == 0:
        return "0 B"
    units = ["B", "KB", "MB", "GB", "TB"]
    unit_index = 0
    size = float(size_bytes)
    while size >= 1024 and unit_index < len(units) - 1:
        size /= 1024
        unit_index += 1
    if unit_index == 0:
        return f"{int(size)} {units[unit_index]}"
    else:
        return f"{size:.1f} {units[unit_index]}"


class FileProcessor:
    """
    Handles processing a single file, including reading its content and checking if it's binary.
    """

    def __init__(self, root_path: Path):
        self.root_path = root_path

    def is_binary(self, file_path: Path) -> bool:
        """
        Heuristically determines if a file is binary.
        """
        mime_type, _ = mimetypes.guess_type(file_path)
        if mime_type:
            # Check if mime_type starts with any of the text mimetypes
            if any(mime_type.startswith(text_mime) for text_mime in TEXT_MIMETYPES):
                return False
            if "application" in mime_type and "octet-stream" not in mime_type:
                return False  # Often text-based like application/json

        # Fallback: Read a chunk and check for null bytes
        try:
            with open(file_path, "rb") as f:
                chunk = f.read(1024)
                return b"\0" in chunk
        except IOError:
            return True  # If we can't read it, treat it as binary/inaccessible

    def process(self, file_path: Path) -> Optional[Tuple[str, str]]:
        """
        Reads a file and returns its relative path and content.
        Returns None if the file is binary or cannot be read.
        """
        if self.is_binary(file_path):
            relative_path = file_path.relative_to(self.root_path)
            # You could choose to return a placeholder for binary files
            # return (str(relative_path), "[Binary file, content omitted]")
            return None

        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
            relative_path = file_path.relative_to(self.root_path)
            return (str(relative_path), content)
        except (IOError, UnicodeDecodeError) as e:
            # Failed to read as text, likely binary or permission error
            print(f"\n[Warning] Could not read {file_path}: {e}")
            return None


class IgnoreHandler:
    """
    Manages ignore rules from various sources (.gitignore, command-line patterns).
    """

    def __init__(self, root_path: Path, custom_ignore_file: str = ".pycombinerignore"):
        self.root = root_path
        self.ignore_patterns = set(DEFAULT_IGNORE_PATTERNS)
        self.load_ignore_file(root_path / ".gitignore")
        self.load_ignore_file(root_path / custom_ignore_file)

    def load_ignore_file(self, file_path: Path):
        """Loads ignore patterns from a .gitignore-style file."""
        if file_path.is_file():
            with open(file_path, "r", encoding="utf-8") as f:
                for line in f:
                    stripped_line = line.strip()
                    if stripped_line and not stripped_line.startswith("#"):
                        self.ignore_patterns.add(stripped_line)

    def is_ignored(
        self, path: Path, include_patterns: List[str], exclude_patterns: List[str]
    ) -> bool:
        """
        Checks if a path should be ignored based on all rules.
        Exclusion has higher priority than inclusion.
        """
        relative_path = str(path.relative_to(self.root))

        # 1. Check custom exclusion patterns first
        for pattern in exclude_patterns:
            if fnmatch.fnmatch(relative_path, pattern) or fnmatch.fnmatch(
                path.name, pattern
            ):
                return True

        # 2. Check general ignore patterns
        # Check against path components
        parts = relative_path.split(os.sep)
        for part in parts:
            if any(fnmatch.fnmatch(part, pattern) for pattern in self.ignore_patterns):
                return True
        # Check against full path
        if any(
            fnmatch.fnmatch(relative_path, pattern) for pattern in self.ignore_patterns
        ):
            return True

        # 3. If include patterns are specified, a file MUST match one of them
        if include_patterns:
            if not any(
                fnmatch.fnmatch(relative_path, p) or fnmatch.fnmatch(path.name, p)
                for p in include_patterns
            ):
                return True

        return False


def get_file_paths(root_path: Path) -> List[Path]:
    """Recursively finds all file paths in a directory."""
    return [p for p in root_path.rglob("*") if p.is_file()]


def combine_files(
    root_path: Path,
    output_file: Optional[Path],
    to_clipboard: bool,
    max_workers: int,
    include: List[str],
    exclude: List[str],
    dry_run: bool,
):
    """
    Main function to orchestrate the file combination process.
    """
    start_time = time.time()

    # Initialization
    ignore_handler = IgnoreHandler(root_path)
    file_processor = FileProcessor(root_path)
    all_files = get_file_paths(root_path)

    # Filter out ignored files upfront
    files_to_process = [
        f
        for f in all_files
        if not ignore_handler.is_ignored(f, include, exclude) and f != output_file
    ]

    if dry_run:
        print("--- Dry Run: Files that would be included ---")
        for path in sorted(files_to_process):
            print(path.relative_to(root_path))
        print(f"\nFound {len(files_to_process)} files to include.")
        return

    processed_files = []

    # Set up progress bar
    progress = Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
        TimeElapsedColumn(),
    )

    with progress:
        task = progress.add_task(
            "[cyan]Processing files...", total=len(files_to_process)
        )
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            # Submit files for processing
            futures = {
                executor.submit(file_processor.process, path): path
                for path in files_to_process
            }

            for future in as_completed(futures):
                result = future.result()
                if result:
                    processed_files.append(result)
                progress.update(task, advance=1)

    # Sort files by path for consistent output
    processed_files.sort(key=lambda x: x[0])

    # Generate the output content
    output_content = [
        f"# File Combination Report\n",
        f"# Source Directory: {root_path.resolve()}\n",
        f"# Generated on: {time.strftime('%Y-%m-%d %H:%M:%S')}\n",
        f"# Total Files Included: {len(processed_files)}\n\n",
        f"--- TABLE OF CONTENTS ---\n",
    ]
    for rel_path, _ in processed_files:
        output_content.append(
            f"- [{rel_path}](#file-{rel_path.replace(os.sep, '-')})\n"
        )

    output_content.append("\n" + "=" * 80 + "\n\n")

    for rel_path, content in processed_files:
        # Create a language hint for markdown code blocks
        lang_hint = mimetypes.guess_type(rel_path)[0] or ""
        lang_hint = (
            lang_hint.split("/")[-1] if "/" in lang_hint else rel_path.split(".")[-1]
        )

        header = f"--- File: {rel_path} ---\n"
        anchor = f"<a id='file-{rel_path.replace(os.sep, '-')}'></a>\n"  # HTML anchor for TOC
        output_content.append(
            f"{anchor}## {rel_path}\n\n```{lang_hint}\n{content}\n```\n\n"
        )

    final_output = "".join(output_content)

    # Output to file or clipboard
    if to_clipboard:
        if pyperclip:
            pyperclip.copy(final_output)
            content_size = len(final_output)
            print(f"\n✅ Copied content of {len(processed_files)} files to clipboard.")
            print(
                f"📊 Output size: {_format_size(content_size)} ({len(final_output.splitlines()):,} lines)"
            )
        else:
            print(
                "\n❌ Pyperclip not found. Please install it (`pip install pyperclip`) to use this feature."
            )
    elif output_file:
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(final_output)
        file_size = output_file.stat().st_size
        line_count = len(final_output.splitlines())
        print(
            f"\n✅ Successfully combined {len(processed_files)} files into: {output_file}"
        )
        print(f"📊 File size: {_format_size(file_size)} ({line_count:,} lines)")

    end_time = time.time()
    print(f"⏱️  Processed in {end_time - start_time:.2f} seconds.")


def main():
    parser = argparse.ArgumentParser(
        description="Combines multiple text files from a directory into a single file with metadata.",
        formatter_class=argparse.RawTextHelpFormatter,
    )
    parser.add_argument(
        "dir",
        nargs="?",
        default=".",
        help="Directory to scan (default: current directory).",
    )
    parser.add_argument(
        "-o",
        "--output",
        default="combined_output.md",
        help="Output file path (default: combined_output.md).",
    )
    parser.add_argument(
        "-w",
        "--workers",
        type=int,
        default=os.cpu_count() or 4,
        help="Number of worker threads to use.",
    )
    parser.add_argument(
        "--include",
        nargs="+",
        default=[],
        help="Glob patterns for files to explicitly include (e.g., '*.py' '*.js').",
    )
    parser.add_argument(
        "--exclude",
        nargs="+",
        default=[],
        help="Glob patterns for files/directories to explicitly exclude (e.g., '*.log' 'docs/*').",
    )
    parser.add_argument(
        "--clipboard",
        action="store_true",
        help="Copy the output to the clipboard instead of a file.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="List files that would be included without creating an output file.",
    )

    args = parser.parse_args()

    root_dir = Path(args.dir).resolve()
    if not root_dir.is_dir():
        print(f"Error: Directory not found at '{args.dir}'")
        return

    output_path = Path(args.output) if not args.clipboard else None

    combine_files(
        root_path=root_dir,
        output_file=output_path,
        to_clipboard=args.clipboard,
        max_workers=args.workers,
        include=args.include,
        exclude=args.exclude,
        dry_run=args.dry_run,
    )


if __name__ == "__main__":
    main()
