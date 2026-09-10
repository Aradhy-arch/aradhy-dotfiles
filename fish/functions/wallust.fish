function wallust --wraps wallust --description "Wallust wrapper with a custom restore flag"
    if test "$argv[1]" = "--restore"
        echo "[!] Restoring original Catppuccin theme..."
        
        # 1. Restore Alacritty colors
        cp ~/.config/alacritty/colors.catppuccin.toml ~/.config/alacritty/colors.toml

        # 2. Restore Starship prompt
        cp ~/.config/starship.catppuccin.toml ~/.config/starship.toml
        
        # 3. Restore default wallpaper 
        hyprctl hyprpaper wallpaper "LVDS-1,/home/aradhy/Pictures/Wallpapers/storm.jpg"
        
        echo "[✔] Done! Alacritty and Starship are back to normal."
        return 0
    end

    # If --restore wasn't typed, pass all arguments to the real wallust binary
    command wallust $argv
end
