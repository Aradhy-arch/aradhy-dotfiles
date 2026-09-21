#!/usr/bin/env bash

################################################################################
# Aradhy's Arch Dotfiles Installer
# Must be run as a normal user (NOT root) with sudo access.
################################################################################

# -e: exit on error, -E: let the ERR trap fire inside functions too
set -eE

# Warnings are collected here and printed again at the very end
# (otherwise a later 'clear' would wipe them before you could read them)
WARNINGS=()
LOG_FILE="/tmp/aradhy-dotfiles-install.log"

################################################################################
# MESSAGE HELPERS (work even before gum is installed)
################################################################################

say() {
    # say <gum-color> <text>
    if command -v gum > /dev/null 2>&1; then
        gum style --foreground "$1" "$2" || echo "$2"
    else
        echo "$2"
    fi
}

error_exit() {
    say 196 "❌ Error: $1"
    exit 1
}

success_msg() { say 46 "✔️ $1"; }
info_msg()    { say 220 "➔ $1"; }
warning_msg() { say 214 "⚠️ $1"; WARNINGS+=("$1"); }

trap 'error_exit "Installation failed at line $LINENO"' ERR

################################################################################
# 0. ENVIRONMENT CHECKS
################################################################################

if [ "$EUID" -eq 0 ]; then
    error_exit "Please run this script as your normal user, NOT as root."
fi

if ! command -v pacman > /dev/null 2>&1; then
    error_exit "This script requires Arch Linux (pacman not found)."
fi

info_msg "Checking system requirements..."

sudo -v || error_exit "Failed to acquire sudo privileges. Check your sudoers configuration."

# Keep the sudo timestamp fresh in the background. Long installs can outlast
# sudo's timeout, and a password prompt hidden inside 'gum spin' would hang forever.
while kill -0 "$$" 2> /dev/null; do
    sudo -n true 2> /dev/null || true
    sleep 60
done &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2> /dev/null || true' EXIT

success_msg "Sudo privileges confirmed"

################################################################################
# 0.5. PREREQUISITES
################################################################################

info_msg "Installing prerequisites (gum, git, unzip, fonts, ...)..."

PREREQ_PKGS=(gum git unzip ttf-iosevka-nerd wget base-devel)

if sudo pacman -S --needed --noconfirm "${PREREQ_PKGS[@]}" > "$LOG_FILE" 2>&1; then
    success_msg "Prerequisites installed"
else
    tail -n 15 "$LOG_FILE" || true
    error_exit "Failed to install prerequisites (full log: $LOG_FILE)"
fi

command -v gum > /dev/null 2>&1 || error_exit "gum is still missing after install. Cannot continue."

clear

################################################################################
# 0.6. BACKUP
################################################################################

if gum confirm "Do you want to take backups of your config and local folders?"; then
    info_msg "Creating backups..."

    for dir in .config .local; do
        if [ -d "$HOME/$dir" ]; then
            dest="$HOME/${dir#.}_old"
            # Never nest into (or overwrite) an existing backup
            [ -e "$dest" ] && dest="${dest}_$(date +%s)"
            if cp -r "$HOME/$dir" "$dest"; then
                success_msg "Backed up ~/$dir to $dest"
            else
                warning_msg "Failed to back up ~/$dir (continuing anyway)"
            fi
        fi
    done
else
    info_msg "Skipping backups"
fi

################################################################################
# 1. CLONE THE REPOSITORY
################################################################################

info_msg "Cloning Aradhy dotfiles repository..."

rm -rf "$HOME/aradhy-dotfiles"

gum spin --spinner dot --show-error --title "Cloning repository..." -- \
    git clone --depth=1 https://github.com/Aradhy-arch/aradhy-dotfiles "$HOME/aradhy-dotfiles" \
    || error_exit "Failed to clone repository. Check your internet connection."

cd "$HOME/aradhy-dotfiles" || error_exit "Failed to enter repository directory"
success_msg "Repository cloned"

################################################################################
# 2. PACKAGE LISTS
################################################################################

PACMAN_PKGS=(
    fish btop zoxide fzf fastfetch starship eza bat micro neovim qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg
    hyprland hyprpaper hyprlock swaync cliphist grim slurp waybar rofi hyprpolkitagent hypridle hyprsunset
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk qt5-wayland qt6-wayland noto-fonts-cjk noto-fonts-emoji
    pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber
    bluez bluez-utils blueman wf-recorder brightnessctl
    alacritty discord spotify-launcher mousepad thunar xarchiver thunar-archive-plugin sddm wl-clip-persist imv mpv cmatrix
)

AUR_PKGS=(
    cbonsai pipes.sh helium-browser-bin wallust lavat volumectl
)

################################################################################
# 3. WELCOME SCREEN
################################################################################

clear

gum style \
    --foreground 220 --border-foreground 220 --border double \
    --align center --width 60 --margin "1 2" --padding "2 4" \
    "✨ Aradhy's Arch Setup ✨"

if ! gum confirm "Ready to install packages and apply dotfiles?"; then
    say 196 "Installation aborted by user."
    exit 0
fi

################################################################################
# 4. INTERACTIVE MODE
################################################################################

info_msg "Interactive or silent mode?"
INTERACTIVE=$(gum choose "Yes (confirm each step)" "No (run silently)")

# Returns 0 if the step should run, 1 if the user skipped it
confirm_step() {
    if [ "$INTERACTIVE" = "Yes (confirm each step)" ]; then
        gum confirm "$1" || { warning_msg "Skipped by user: $1"; return 1; }
    fi
    return 0
}

# Interactive mode: run with full visible output.
# Silent mode: run behind a spinner, but still show the output if it fails.
run_step() {
    local title="$1"
    shift
    if [ "$INTERACTIVE" = "Yes (confirm each step)" ]; then
        info_msg "$title"
        "$@"
    else
        gum spin --spinner dot --show-error --title "$title" -- "$@"
    fi
}

################################################################################
# 5. AUR HELPER
################################################################################

info_msg "Which AUR helper do you prefer?"
AUR_HELPER=$(gum choose "yay" "paru")

info_msg "Checking for $AUR_HELPER..."

if command -v "$AUR_HELPER" > /dev/null 2>&1; then
    success_msg "$AUR_HELPER is already installed"
else
    warning_msg "$AUR_HELPER not found, installing the prebuilt ${AUR_HELPER}-bin package"

    confirm_step "Clone and build ${AUR_HELPER}-bin from the AUR?" \
        || error_exit "Cannot continue without an AUR helper"

    # The -bin packages avoid compiling Go/Rust (much faster and lighter)
    tmp_dir=$(mktemp -d)

    run_step "Cloning ${AUR_HELPER}-bin..." \
        git clone "https://aur.archlinux.org/${AUR_HELPER}-bin.git" "$tmp_dir/$AUR_HELPER" \
        || error_exit "Failed to clone ${AUR_HELPER}-bin from the AUR"

    run_step "Building ${AUR_HELPER}-bin..." \
        bash -c 'cd "$1" && makepkg -si --noconfirm' _ "$tmp_dir/$AUR_HELPER" \
        || error_exit "Failed to build ${AUR_HELPER}-bin"

    rm -rf "$tmp_dir"

    command -v "$AUR_HELPER" > /dev/null 2>&1 || error_exit "$AUR_HELPER not found after install"
    success_msg "$AUR_HELPER installed"
fi

################################################################################
# 6. OFFICIAL PACKAGES
################################################################################

info_msg "Official pacman packages (${#PACMAN_PKGS[@]})..."

if confirm_step "Install official packages with pacman?"; then
    run_step "Installing pacman packages..." \
        sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" \
        || error_exit "Pacman installation failed"
    success_msg "Official packages installed"
fi

################################################################################
# 7. AUR PACKAGES
################################################################################

info_msg "AUR packages (${#AUR_PKGS[@]})..."

if confirm_step "Install AUR packages with $AUR_HELPER?"; then
    run_step "Installing AUR packages..." \
        "$AUR_HELPER" -S --needed --noconfirm "${AUR_PKGS[@]}" \
        || error_exit "AUR installation failed"
    success_msg "AUR packages installed"
fi

################################################################################
# 8. COPY CONFIGURATIONS
################################################################################

info_msg "Verifying repository contents..."

for config_dir in swaync alacritty fastfetch fish hypr random_conf_shit systemd wallust waybar rofi gtk-3.0 sddm-astronaut-theme; do
    [ -d "$config_dir" ] || error_exit "Directory not found in repo: $config_dir"
done

for config_file in daily-wall logind.conf starship.catppuccin.toml; do
    [ -f "$config_file" ] || error_exit "File not found in repo: $config_file"
done

success_msg "Repository contents verified"

info_msg "Applying configurations..."

mkdir -p ~/.config ~/.local/share || error_exit "Failed to create config directories"

cp -r swaync alacritty fastfetch fish hypr random_conf_shit systemd wallust waybar rofi gtk-3.0 ~/.config/ \
    || error_exit "Failed to copy configuration files"
success_msg "Configuration files copied to ~/.config"

cp daily-wall ~/.local/ || error_exit "Failed to copy daily-wall"
success_msg "daily-wall copied"

sudo cp logind.conf /etc/systemd/logind.conf || error_exit "Failed to install logind.conf"
success_msg "logind.conf installed"

# Move the rofi data into ~/.local/share (copy + remove so re-running never fails)
mkdir -p ~/.local/share/rofi
cp -r ~/.config/random_conf_shit/rofi/. ~/.local/share/rofi/ || error_exit "Failed to install rofi data"
rm -rf ~/.config/random_conf_shit/rofi
success_msg "Rofi data installed"

cp starship.catppuccin.toml ~/.config/starship.toml || error_exit "Failed to apply starship config"
success_msg "Starship config applied"

################################################################################
# 9. SDDM THEME
################################################################################

info_msg "Setting up SDDM theme..."

sudo cp -r sddm-astronaut-theme /usr/share/sddm/themes/ || error_exit "Failed to install SDDM theme"
sudo mkdir -p /etc/sddm.conf.d || error_exit "Failed to create /etc/sddm.conf.d"
printf '[Theme]\nCurrent=sddm-astronaut-theme\n' | sudo tee /etc/sddm.conf.d/theme.conf > /dev/null \
    || error_exit "Failed to write SDDM theme config"
success_msg "SDDM theme configured"

################################################################################
# 10. EXECUTABLE PERMISSIONS
################################################################################

info_msg "Setting executable permissions..."

SCRIPTS=(
    ~/.config/random_conf_shit/sddmtheme.sh
    ~/.config/random_conf_shit/usb_formatter.sh
    ~/.local/daily-wall
    ~/.config/hypr/scripts/wifi-menu.sh
    ~/.config/hypr/scripts/power_menu.sh
    ~/.config/hypr/scripts/reboot_menu.sh
    ~/.config/wallust/templates/set_bg.sh
    ~/.config/hypr/scripts/rofi-bluetooth.sh
    ~/.config/hypr/scripts/screen-record.sh
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        chmod +x "$script" || warning_msg "Failed to chmod $script"
    else
        warning_msg "Script not found (skipped chmod): $script"
    fi
done

success_msg "Script permissions set"

################################################################################
# 11. WALLPAPERS
################################################################################

info_msg "Downloading wallpapers..."

mkdir -p ~/Pictures || error_exit "Failed to create ~/Pictures"

WALLPAPER_URL="https://github.com/Aradhy-arch/aradhy-dotfiles/releases/download/Wallp/Wallpapers.zip"
WALLPAPER_FILE="$HOME/Pictures/Wallpapers.zip"

if run_step "Downloading wallpapers..." wget -q -O "$WALLPAPER_FILE" "$WALLPAPER_URL"; then
    if unzip -oq "$WALLPAPER_FILE" -d ~/Pictures/; then
        rm -f "$WALLPAPER_FILE"
        success_msg "Wallpapers downloaded and extracted"
    else
        rm -f "$WALLPAPER_FILE"
        warning_msg "Wallpapers downloaded but could not be extracted"
    fi
else
    rm -f "$WALLPAPER_FILE"
    warning_msg "Failed to download wallpapers (continuing without them)"
fi

################################################################################
# 12. IMAGE VIEWER (imv) DESKTOP ENTRY
################################################################################

info_msg "Configuring imv..."

mkdir -p ~/.local/share/applications || error_exit "Failed to create applications directory"

if cp /usr/share/applications/imv.desktop ~/.local/share/applications/; then
    # Make imv open the clicked image together with the rest of its folder
    if sed -i 's/^Exec=.*/Exec=sh -c '"'"'imv -n "$1" "$(dirname "$1")"'"'"' sh %f/' \
        ~/.local/share/applications/imv.desktop; then
        success_msg "imv configured"
    else
        warning_msg "Failed to edit imv.desktop"
    fi
else
    warning_msg "Failed to copy imv.desktop"
fi

################################################################################
# 13. SERVICES
################################################################################

info_msg "Enabling services..."

enable_service() {
    local service="$1"
    local service_type="$2"   # "system" or "user"

    if [ "$service_type" = "user" ]; then
        if systemctl --user enable "$service" 2> /dev/null; then
            success_msg "User service $service enabled"
        else
            # Happens when there is no user session (e.g. when run from a chroot during install)
            warning_msg "Could not enable $service now. After your first login run: systemctl --user enable --now $service"
        fi
    else
        if sudo systemctl enable "$service"; then
            success_msg "System service $service enabled"
        else
            warning_msg "Failed to enable $service"
        fi
    fi
}

enable_service "sddm.service" "system"
enable_service "bluetooth.service" "system"
enable_service "daily-wall.timer" "user"

################################################################################
# 14. FINAL SUMMARY (no 'clear' after this point)
################################################################################

echo ""

gum style \
    --foreground 46 --border-foreground 46 --border double \
    --align center --width 70 --margin "1 2" --padding "2 4" \
    "🎉 System Setup Complete! 🎉" \
    "" \
    "Reboot your system to enter your new workspace."

if [ "${#WARNINGS[@]}" -gt 0 ]; then
    echo ""
    info_msg "Things that need your attention:"
    for w in "${WARNINGS[@]}"; do
        echo "  - $w"
    done
fi

echo ""
info_msg "Next steps:"
echo "  1. Review ~/.config/hypr/hyprland.conf for keyboard bindings"
echo "  2. Reboot your system"
echo "  3. Login and enjoy your new setup!"
echo ""
say 46 "✨ Thank you for using Aradhy's dotfiles! ✨"

exit 0
