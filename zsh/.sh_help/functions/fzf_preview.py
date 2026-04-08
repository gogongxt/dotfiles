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
    file_path_list = rg_list[0].replace("\n", "").strip().split("/")
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
        file_path = preview_nameandline[0]

        # 1. Use kitten icat
        if shutil.which("kitten"):
            # 获取 fzf 预览窗格的行列数，如果没有则给定默认值
            cols = os.environ.get("FZF_PREVIEW_COLUMNS", "80")
            lines = os.environ.get("FZF_PREVIEW_LINES", "40")

            # --place 的格式是: 宽度x高度@左边距x顶边距
            # 使用 @0x0 强制对齐到左上角 (0,0)
            # 建议高度减去 1-2 行，给底部的状态栏留出空间，防止图片溢出导致闪烁
            place_arg = f"--place={cols}x{int(lines)-1}@0x0"

            # 执行命令，同时加上 --clear 确保切换文件时清理上一张图
            os.system(
                f"kitten icat --clear --stdin=no {place_arg} {file_path} 2> /dev/null"
            )

        # 2. Use chafa
        elif shutil.which("chafa"):
            os.system(f"chafa {file_path}")
            print()

        # 3. Use catimg
        elif shutil.which("catimg"):
            os.system(f"catimg {file_path}")

        # 4. Use imgcat (iTerm2)
        elif shutil.which("imgcat"):
            os.system(f"imgcat {file_path}")

        # 5. Cannot find any suitable method
        else:
            os.system(f"file {file_path}")
    elif preview_nameandline[0].replace("'", "").endswith((".html", ".htm", ".xhtml")):
        os.system("w3m -dump {}".format(preview_nameandline[0]))
    elif preview_nameandline[0].replace("'", "").endswith((".md")):
        if shutil.which("glow"):
            os.system(f"script -q -c 'glow -s dark {preview_nameandline[0]}' /dev/null")
        else:
            os.system("bat --color=always {}".format(preview_nameandline[0]))
    else:
        if shutil.which("bat"):  # if has bat to preview file
            os.system(
                "bat --style=numbers --color=always -r {}: {}".format(
                    preview_nameandline[1], preview_nameandline[0]
                )
            )
        else:
            os.system("cat {}".format(preview_nameandline[0]))
