#! /usr/bin/python3

import os
import sys


def fzf_preview(rg_name):
    rg_list = rg_name.split(':')
    if len(rg_list) == 1:
        bat_range = 0
    else:
        bat_range = rg_list[1].replace('\n', '')
    file_path_list = rg_list[0].replace('\n', '').split('/')
    for i,filep in zip(range(len(file_path_list)), file_path_list):
        path_space = filep.find(' ')
        if not path_space == -1:
            file_path_list[i] = "'{}'".format(filep)
        file_path = '/'.join(file_path_list)
    preview_nameandline = [file_path, bat_range]
    return preview_nameandline


if __name__ == "__main__":
    rg_name = sys.stdin.readlines()[0]
    preview_nameandline = fzf_preview(rg_name)
    if os.path.isdir(preview_nameandline[0]):
        os.system('ls -la {}'.format(preview_nameandline[0]))
    elif preview_nameandline[0].replace("'", '').endswith(('.zip', '.ZIP')):
        os.system('unzip -l {}'.format(preview_nameandline[0]))
    elif preview_nameandline[0].replace("'", '').endswith(('.rar', '.RAR')):
        os.system('unrar l {}'.format(preview_nameandline[0]))
    elif preview_nameandline[0].replace("'", '').endswith('.torrent'):
        os.system('transmission-show {}'.format(preview_nameandline[0]))
    elif preview_nameandline[0].replace("'", '').endswith(('.html', '.htm', '.xhtml')):
        os.system('w3m -dump {}'.format(preview_nameandline[0]))
    elif preview_nameandline[0].replace("'", '').endswith(('.md')):
        os.system('glow -s dark -- {}'.format(preview_nameandline[0]))
    else:
        if os.system("command -v bat >/dev/null") == 0 : # if has bat to preview file
            os.system('bat --style=numbers --color=always -r {}: {}'.format(
                preview_nameandline[1], preview_nameandline[0]))
        else :
            os.system('cat {}'.format(preview_nameandline[0]))
