#!/bin/bash

PROMPT="Power off?"

# 1. Check if the Rofi menu is already running
if pgrep -f "rofi.*$PROMPT" > /dev/null; then
    # 2. Second press detected! Kill Rofi and shut down.
    pkill -f "rofi.*$PROMPT"
    systemctl poweroff
    exit 0
fi

# 3. First press: Show the Rofi menu. 
CHOICE=$(echo -e "Yes\nNo" | rofi -dmenu -p "$PROMPT" -lines 2)

# 4. Handle the user's manual selection (arrow keys + enter, or mouse click)
if [ "$CHOICE" == "Yes" ]; then
    systemctl poweroff
fi
