# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                         ARADHY'S ARCH RICE                                  ║
# ║                   Custom Fish Configuration                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝


# ==============================================================================
# GENERAL SETTINGS
# ==============================================================================
if status is-interactive
    # Disable default fish welcome message
    set -g fish_greeting ""

    # ==========================================================================
    # SOURCES & INITIALIZATIONS
    # ==========================================================================
    zoxide init fish | source
    starship init fish | source
    fzf --fish | source
    fastfetch
    
    # ==========================================================================
    # ABBREVIATIONS & ALIASES
    # ==========================================================================
    # Navigation & General
    abbr -a c "clear"
    abbr -a e "exit"
    abbr -a shut "systemctl poweroff"

    # Quick Config & Management
    alias sourcefish "source ~/.config/fish/config.fish"
    alias openfish "nano ~/.config/fish/config.fish"
    abbr -a pa "sudo pacman -S"
    abbr -a ya "yay -S"
    abbr -a aria2 "aria2c -x 16 -s 16"
    alias ff "fastfetch"

    # Modern CLI Replacements 
    abbr -a gc "git clone --depth=1"
    alias ls "eza --icons=always --group-directories-first"
    alias ll "eza -lah --icons=always --group-directories-first"
    alias tree "eza --tree --icons=always"
    alias cat "bat"
    alias nano "micro"

    # Random Config Shit
    alias sddmtheme "~/.config/random_conf_shit/sddmtheme.sh"
    alias formatduh "~/.config/random_conf_shit/usb_formatter.sh"
    alias next "~/.local/daily-wall"

    # Fun Stuff
    alias tre "cbonsai"
    alias l "lavat"
    alias pi "pipes.sh"
    alias cm "cmatrix"
    
    # ==========================================================================
    # FUNCTIONS
    # ==========================================================================
    # You can add your custom functions here :D

end

fish_add_path /home/aradhy/.spicetify
