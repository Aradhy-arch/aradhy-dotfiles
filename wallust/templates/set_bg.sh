#!/bin/sh

hyprctl hyprpaper preload "{{wallpaper}}"
hyprctl hyprpaper wallpaper ",{{wallpaper}}"
hyprctl hyprpaper unload all

cat << EOF > "$HOME/.config/hypr/hyprpaper.conf"
wallpaper {
    monitor =
    path = {{wallpaper}}
    fit_mode = cover
}
splash = false
EOF