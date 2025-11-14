#!/usr/bin/env python

import os
import subprocess
import time

import choose

SLEEP_TIME = 0.1


def shutdown():
    ret = choose.ChooseYesOrNo("shutdown",SLEEP_TIME)
    if ret == "yes":
        os.system("shutdown -h now")


def reboot():
    ret = choose.ChooseYesOrNo("reboot",SLEEP_TIME)
    if ret == "yes":
        os.system("reboot")


def logout():
    ret = choose.ChooseYesOrNo("log out",SLEEP_TIME)
    if ret == "yes":
        os.system("i3-msg exit")


def suspend():
    ret = choose.ChooseYesOrNo("suspend to ram",SLEEP_TIME)
    if ret == "yes":
        os.system("systemctl suspend ")


def hibernate():
    ret = choose.ChooseYesOrNo("hibernate to disk",SLEEP_TIME)
    if ret == "yes":
        os.system("systemctl hibernate ")


def lock():
    os.system("bash ~/.scripts/i3lock/lock.sh")


def MenuRofi():
    #      key:display information   value:function
    choose = {
        "⏻ shutdown": "shutdown",
        " reboot": "reboot",
        "󰍃 log out": "logout",
        "⏾ suspend to ram": "suspend",
        "󰒲 hibernate to disk": "hibernate",
        "󰷛 lock": "lock",
    }
    cmd = "echo $(echo -e '"
    for choose_string in choose.keys():
        cmd += choose_string + "\\n"
    cmd = cmd[:-2]
    cmd += "' | rofi -dmenu -window-title '󰹯 POWER')"
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
