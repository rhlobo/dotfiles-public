#!/usr/bin/env bash

## TERMINAL DAEMON
[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources || {
    [[ -f ~/.Xdefaults  ]] && xrdb -merge ~/.Xdefaults
}

## BACKGROUND
feh --bg-center --bg-fill "/home/rhlobo/dropbox/files/personal/Imagens/WallPapers/Bugs_wallpapers_298.jpg"

## COMPOSITE MANAGER
xcompmgr -c -f -D=600 -t=-5 -l=-5 -r=5 -o=.5 &
#compton -cCfb -D 1 -r 12 -l -18 -t -12 -o 0.4 -e 0.4 &

## GUAKE TERMINAL
guake &

## Allowing cron to notify-send
xhost +local:

## Loading shell_extension
source /home/rhlobo/.shell_extension

## Default brightness
x_brightness 60

## 2 finger scroll
synclient VertEdgeScroll=1
synclient VertTwoFingerScroll=1
