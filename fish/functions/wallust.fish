function wallust --wraps wallust --description "Wallust wrapper with a custom restore flag"
    if test "$argv[1]" = "--restore"
        echo "[!] Restoring original Catppuccin theme and starting daily cycle..."
        
        # 1. Restore Alacritty colors
        cp ~/.config/alacritty/colors.catppuccin.toml ~/.config/alacritty/colors.toml

        # 2. Restore Starship prompt
        cp ~/.config/starship.catppuccin.toml ~/.config/starship.toml
        
        # 3. Enable the systemd daily timer
        systemctl --user start daily-wall.timer
        
        # 4. Cycle the wallpaper instantly (without running wallust)
        ~/.local/daily-wall
        
        echo "[✔] Done! Alacritty and Starship are back to normal, daily cycling is ON."
        return 0
    end

    # If you manually run wallust, stop the daily cycle
    if test "$argv[1]" = "run"
        echo "[!] Manual wallpaper set. Pausing daily rotation..."
        systemctl --user stop daily-wall.timer
    end

    # If --restore wasn't typed, pass all arguments to the real wallust binary
    command wallust $argv
end
