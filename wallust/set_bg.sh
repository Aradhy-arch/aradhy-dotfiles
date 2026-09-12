#!/bin/sh

hyprctl hyprpaper preload "/home/aradhy/Pictures/Wallpapers/storm.jpg"
hyprctl hyprpaper wallpaper ",/home/aradhy/Pictures/Wallpapers/storm.jpg"
hyprctl hyprpaper unload all

cat << EOF > "$HOME/.config/hypr/hyprpaper.conf"
wallpaper {
    monitor = 
    path = /home/aradhy/Pictures/Wallpapers/storm.jpg
    fit_mode = cover
}
splash = false
EOF