#!/usr/bin/env bash

PROMPT="Logout?"

# 1. Check if the Rofi menu is already running
if pgrep -f "rofi.*$PROMPT" > /dev/null; then
    # 2. Second press detected! Kill Rofi and shut down.
    pkill -f "rofi.*$PROMPT"
    command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'
    exit 0
fi

# 3. First press: Show the Rofi menu. 
CHOICE=$(echo -e "Yes\nNo" | rofi -dmenu -p "$PROMPT" -lines 2)

# 4. Handle the user's manual selection (arrow keys + enter, or mouse click)
if [ "$CHOICE" == "Yes" ]; then
    command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'
fi
