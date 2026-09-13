#!/bin/sh

hyprctl hyprpaper preload "/home/aradhy/Pictures/Wallpapers/arch-black-4k.png"
hyprctl hyprpaper wallpaper "LVDS-1,/home/aradhy/Pictures/Wallpapers/arch-black-4k.png"
hyprctl hyprpaper unload all

cat << EOF > "$HOME/.config/hypr/hyprpaper.conf"
wallpaper {
    monitor = LVDS-1
    path = /home/aradhy/Pictures/Wallpapers/arch-black-4k.png
    fit_mode = cover
}
splash = false
EOF