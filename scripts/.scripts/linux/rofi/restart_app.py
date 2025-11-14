#!/usr/bin/env python

import os
import subprocess
import time

import choose

SLEEP_TIME = 0.1


def polybar():
    os.system("sh ~/.config/polybar/launch.sh")


def picom():
    os.system("killall picom;sleep 0.1; nohup picom&>/dev/null")

def MenuRofi():
    #      key:display information   value:function
    choose = {
        "󱒊 polybar": "polybar",
        " picom": "picom",
    }
    cmd = "echo $(echo -e '"
    for choose_string in choose.keys():
        cmd += choose_string + "\\n"
    cmd = cmd[:-2]
    cmd += "' | rofi -dmenu -window-title '󰹯 RESTART APP')"
    # print(cmd)
    result = subprocess.run(
        cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE
    )
    choose_ret = result.stdout.decode("utf-8").replace("\n", "")
    # print(choose_ret)
    match_function = choose[choose_ret]
    try:
        exec(str(match_function) + "()")
    except Exception:
        pass


if __name__ == "__main__":
    MenuRofi()
