#!/bin/sh

hyprctl hyprpaper unload all > /dev/null 2>&1
hyprctl hyprpaper preload "/home/aradhy/Pictures/Wallpapers/storm.jpg" > /dev/null 2>&1

for MON in $(hyprctl monitors | awk '/Monitor/ {print $2}'); do
    hyprctl hyprpaper wallpaper "$MON,/home/aradhy/Pictures/Wallpapers/storm.jpg" >/dev/null 2>&1
done

cat << EOF > "$HOME/.config/hypr/hyprpaper.conf"
wallpaper {
    monitor =
    path = /home/aradhy/Pictures/Wallpapers/storm.jpg
    fit_mode = cover
}

splash = false

EOF
