#!/usr/bin/env bash

# ==============================================================================
# SDDM ASTRONAUT THEME SWITCHER & PREVIEWER
# ==============================================================================

set -euo pipefail

readonly THEME_NAME="sddm-astronaut-theme"
readonly THEMES_DIR="/usr/share/sddm/themes"
readonly METADATA="$THEMES_DIR/$THEME_NAME/metadata.desktop"

readonly -a THEMES=(
    "black_hole" 
    "cyberpunk" 
    "astronaut" 
    "hyprland_kath" 
    "jake_the_dog"
    "japanese_aesthetic" 
    "pixel_sakura" 
    "toyota-chaser" 
    "purple_leaves"
)

# ------------------------------------------------------------------------------
# UI & LOGGING HELPER FUNCTIONS
# ------------------------------------------------------------------------------
info() {
    if command -v gum &>/dev/null; then
        gum style --foreground 10 "✅ $*"
    else
        echo -e "\e[32m✅ $*\e[0m"
    fi
}

error() {
    if command -v gum &>/dev/null; then
        gum style --foreground 9 "❌ $*" >&2
    else
        echo -e "\e[31m❌ $*\e[0m" >&2
    fi
}

choose() {
    if command -v gum &>/dev/null; then
        gum choose --cursor.foreground 12 --header="" --header.foreground 12 "$@"
    else
        select opt in "$@"; do [[ -n "$opt" ]] && { echo "$opt"; break; }; done
    fi
}

# ------------------------------------------------------------------------------
# CORE OPERATIONS
# ------------------------------------------------------------------------------
select_theme() {
    if [[ ! -f "$METADATA" ]]; then
        error "Theme metadata not found at $METADATA"
        return 1
    fi

    local theme
    theme=$(choose "${THEMES[@]}" || echo "black_hole")
    
    sudo sed -i "s|^ConfigFile=.*|ConfigFile=Themes/${theme}.conf|" "$METADATA"
    info "Selected theme variant: $theme"
}

preview_theme() {
    local date_stamp
    date_stamp=$(date +%s)
    local log_file="/tmp/${THEME_NAME}_${date_stamp}.txt"

    info "Launching SDDM greeter preview window..."
    sddm-greeter-qt6 --test-mode --theme "$THEMES_DIR/$THEME_NAME/" > "$log_file" 2>&1 &
    local greeter_pid=$!

    # Keep preview active for up to 10 seconds or until closed
    for _ in {1..10}; do
        if ! kill -0 "$greeter_pid" 2>/dev/null; then
            break
        fi
        sleep 1
    done

    if kill -0 "$greeter_pid" 2>/dev/null; then
        kill "$greeter_pid" 2>/dev/null || true
    fi

    local current_theme
    current_theme="$(sed -n 's|^ConfigFile=Themes/\(.*\)\.conf|\1|p' "$METADATA")"
    info "Preview closed ($current_theme theme active)."
}

# ------------------------------------------------------------------------------
# MAIN LOOP
# ------------------------------------------------------------------------------
main() {
    [[ $EUID -eq 0 ]] && { error "Do not run as root directly."; exit 1; }

    clear
    while true; do
        if command -v gum &>/dev/null; then
            gum style --bold --padding "0 2" --border double --border-foreground 12 "🎨 SDDM Astronaut Theme Switcher"
        else
            echo -e "\e[36m🎨 SDDM Astronaut Theme Switcher\e[0m"
        fi

        local choice
        choice=$(choose \
            "🎨 Select Theme Variant" \
            "✨ Preview Active Theme" \
            "❌ Exit")

        case "$choice" in
            "🎨 Select Theme Variant") select_theme && preview_theme ;;
            "✨ Preview Active Theme") preview_theme ;;
            "❌ Exit") info "Goodbye!"; exit 0 ;;
        esac

        echo
        if command -v gum &>/dev/null; then
            gum input --placeholder="Press Enter to continue..."
        else
            echo -n "Press Enter to continue..."; read -r
        fi
    done
}

main "$@"
