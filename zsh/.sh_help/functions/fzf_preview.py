#! /usr/bin/python3

import os
import shutil
import subprocess
import sys


def fzf_preview(rg_name):
    rg_list = rg_name.split(":")
    if len(rg_list) == 1:
        bat_range = 0
    else:
        bat_range = rg_list[1].replace("\n", "")
    file_path_list = rg_list[0].replace("\n", "").split("/")
    for i, filep in zip(range(len(file_path_list)), file_path_list):
        path_space = filep.find(" ")
        if not path_space == -1:
            file_path_list[i] = "'{}'".format(filep)
        file_path = "/".join(file_path_list)
    preview_nameandline = [file_path, bat_range]
    return preview_nameandline


if __name__ == "__main__":
    rg_name = sys.stdin.readlines()[0]
    preview_nameandline = fzf_preview(rg_name)
    if os.path.isdir(preview_nameandline[0]):
        os.system("ls -la {}".format(preview_nameandline[0]))
    elif preview_nameandline[0].replace("'", "").endswith((".zip", ".ZIP")):
        os.system("unzip -l {}".format(preview_nameandline[0]))
    elif preview_nameandline[0].replace("'", "").endswith((".rar", ".RAR")):
        os.system("unrar l {}".format(preview_nameandline[0]))
    elif preview_nameandline[0].replace("'", "").endswith(".torrent"):
        os.system("transmission-show {}".format(preview_nameandline[0]))
    elif (
        preview_nameandline[0]
        .replace("'", "")
        .endswith(
            (
                ".jpg",
                ".jpeg",
                ".png",
                ".gif",
                ".svg",
                ".bmp",
                ".webp",
                ".ico",
                ".tiff",
                ".tif",
            )
        )
    ):
        # Get preview dimensions
        cols = os.environ.get("FZF_PREVIEW_COLUMNS", "")
        lines = os.environ.get("FZF_PREVIEW_LINES", "")

        dim = ""
        if cols and lines:
            dim = f"{cols}x{lines}"
            # Avoid scrolling issue when Sixel image touches bottom of screen
            kitty_window_id = os.environ.get("KITTY_WINDOW_ID", "")
            try:
                result = subprocess.run(
                    ["stty", "size"],
                    stdin=open("/dev/tty"),
                    capture_output=True,
                    text=True,
                )
                if result.returncode == 0 and not kitty_window_id:
                    term_lines = int(result.stdout.strip().split()[0])
                    preview_top = int(os.environ.get("FZF_PREVIEW_TOP", "0"))
                    if preview_top + int(lines) == term_lines:
                        dim = f"{cols}x{int(lines) - 1}"
            except:
                pass
        else:
            # Fallback: get terminal size from stty
            try:
                result = subprocess.run(
                    ["stty", "size"],
                    stdin=open("/dev/tty"),
                    capture_output=True,
                    text=True,
                )
                if result.returncode == 0:
                    parts = result.stdout.strip().split()
                    if len(parts) == 2:
                        dim = f"{parts[1]}x{parts[0]}"
            except:
                pass

        file_path = preview_nameandline[0]

        # 1. Use kitten icat (Kitty/Ghostty)
        kitty_window_id = os.environ.get("KITTY_WINDOW_ID", "")
        ghostty_resources = os.environ.get("GHOSTTY_RESOURCES_DIR", "")
        if (kitty_window_id or ghostty_resources) and shutil.which("kitten"):
            if dim:
                subprocess.run(
                    f"kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no --place={dim}@0x0 {file_path}",
                    shell=True,
                )

        # 2. Use chafa
        elif shutil.which("chafa"):
            if dim:
                os.system(f"chafa -s {dim} {file_path}")
            else:
                os.system(f"chafa {file_path}")
            print()

        # 3. Use catimg
        elif shutil.which("catimg"):
            os.system(f"catimg {file_path}")

        # 4. Use imgcat (iTerm2)
        elif shutil.which("imgcat"):
            if dim:
                w, h = dim.split("x")
                os.system(f"imgcat -W {w} -H {h} {file_path}")
            else:
                os.system(f"imgcat {file_path}")

        # 5. Cannot find any suitable method
        else:
            os.system(f"file {file_path}")
    elif preview_nameandline[0].replace("'", "").endswith((".html", ".htm", ".xhtml")):
        os.system("w3m -dump {}".format(preview_nameandline[0]))
    elif preview_nameandline[0].replace("'", "").endswith((".md")):
        os.system("glow -s dark -- {}".format(preview_nameandline[0]))
    else:
        if shutil.which("bat"):  # if has bat to preview file
            os.system(
                "bat --style=numbers --color=always -r {}: {}".format(
                    preview_nameandline[1], preview_nameandline[0]
                )
            )
        else:
            os.system("cat {}".format(preview_nameandline[0]))
