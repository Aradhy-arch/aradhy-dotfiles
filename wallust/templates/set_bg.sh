#!/bin/sh

hyprctl hyprpaper preload "{{wallpaper}}"
hyprctl hyprpaper wallpaper "LVDS-1,{{wallpaper}}"
hyprctl hyprpaper unload all

cat << EOF > "$HOME/.config/hypr/hyprpaper.conf"
wallpaper {
    monitor = LVDS-1
    path = {{wallpaper}}
    fit_mode = cover
}
splash = false
EOF