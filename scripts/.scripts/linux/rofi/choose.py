#!/usr/bin/env python

import subprocess

import time

def ChooseYesOrNo(title:str=" ",delay=0.0)->str:
    time.sleep(delay)
    #      key:display information   value:function
    choose = {
        "√ YES": "yes",
        "X NO": "no",
    }
    cmd = "echo $(echo -e '"
    for choose_string in choose.keys():
        cmd += choose_string + "\\n"
    cmd = cmd[:-2]
    cmd += "' | rofi -dmenu -window-title "+title+")"
    # print(cmd)
    result = subprocess.run(
        cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE
    )
    choose_ret = result.stdout.decode("utf-8").replace("\n", "")
    # print(choose_ret)
    return choose[choose_ret]


if __name__ == "__main__":
    pass
