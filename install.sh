#!/usr/bin/env bash

# Exit immediately if any command fails
set -e

# Color codes for consistent output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Enhanced error handler with line number and context
trap 'error_exit "Installation failed at line $LINENO"' ERR

error_exit() {
    gum style --foreground 196 "❌ Error: $1"
    exit 1
}

success_msg() {
    gum style --foreground 46 "✔️ $1"
}

info_msg() {
    gum style --foreground 220 "➔ $1"
}

warning_msg() {
    gum style --foreground 214 "⚠️ $1"
}

################################################################################
# 0. ROOT AND ENVIRONMENT CHECKS
################################################################################

# Check for root (must run as normal user)
if [ "$EUID" -eq 0 ]; then
    error_exit "Please run this script as your normal user, NOT as root."
fi

# Check if running on Arch Linux
if ! command -v pacman &> /dev/null; then
    error_exit "This script requires Arch Linux (pacman not found)."
fi

info_msg "Checking system requirements..."

# Refresh sudo session to avoid timeout during installation
sudo -v || error_exit "Failed to acquire sudo privileges. Check your sudoers configuration."
success_msg "Sudo privileges confirmed"

################################################################################
# 0.5. PREREQUISITES (with validation)
################################################################################

info_msg "Installing prerequisites silently (gum, git, unzip, etc.)..."

PREREQ_PKGS=(gum git unzip ttf-iosevka-nerd wget base-devel)

# Install quietly
if sudo pacman -Sy --needed --noconfirm "${PREREQ_PKGS[@]}" > /dev/null 2>&1; then
    success_msg "Prerequisites installed"
else
    error_exit "Failed to install prerequisites. Check your internet and pacman configuration."
fi

clear

# Verify gum was actually installed
if ! command -v gum &> /dev/null; then
    error_exit "gum installation verification failed. Cannot continue without gum."
fi

success_msg "gum is available"

################################################################################
# 0.6. BACKUP SECTION
################################################################################

if gum confirm "Do you want to take backups of your config and local folders?"; then
    info_msg "Creating backups..."
    
    if [ -d ~/.config ]; then
        if cp -r ~/.config ~/config_old 2>/dev/null; then
            success_msg "Backed up ~/.config to ~/config_old"
        else
            warning_msg "Failed to backup ~/.config (proceeding anyway)"
        fi
    fi
    
    if [ -d ~/.local ]; then
        if cp -r ~/.local ~/local_old 2>/dev/null; then
            success_msg "Backed up ~/.local to ~/local_old"
        else
            warning_msg "Failed to backup ~/.local (proceeding anyway)"
        fi
    fi
else
    info_msg "Skipping backups"
fi

################################################################################
# 1. CLONE THE REPOSITORY
################################################################################

info_msg "Cloning Aradhy dotfiles repository..."

# Remove old directory
rm -rf ~/aradhy-dotfiles 2>/dev/null || true

# Clone repository
if ! gum spin --spinner dot --title "Cloning repository..." -- \
    git clone --depth=1 https://github.com/Aradhy-arch/aradhy-dotfiles ~/aradhy-dotfiles; then
    error_exit "Failed to clone repository. Check your internet connection and GitHub URL."
fi

# Verify clone succeeded
if [ ! -d ~/aradhy-dotfiles ]; then
    error_exit "Repository clone verification failed. Directory does not exist."
fi

cd ~/aradhy-dotfiles || error_exit "Failed to enter repository directory"
success_msg "Repository cloned successfully"

clear

################################################################################
# 2. DEFINE PACKAGE LISTS
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

gum style \
    --foreground 220 --border-foreground 220 --border double \
    --align center --width 60 --margin "1 2" --padding "2 4" \
    "✨ Aradhy's Arch Setup ✨"

if ! gum confirm "Ready to install packages and apply dotfiles?"; then
    gum style --foreground 196 "Installation aborted by user."
    exit 0
fi

clear

################################################################################
# 4. INTERACTIVE MODE SETUP
################################################################################

info_msg "Interactive or silent mode?"
INTERACTIVE=$(gum choose "Yes (confirm each step)" "No (run silently)")

# Safer command execution without eval
run_cmd() {
    local description="$1"
    shift
    local cmd=("$@")
    
    if [ "$INTERACTIVE" = "Yes (confirm each step)" ]; then
        # Show the command
        gum style --foreground 220 "Command: ${cmd[*]}"
        
        if gum confirm "Execute this command?"; then
            "${cmd[@]}" || {
                warning_msg "Command failed: ${cmd[*]}"
                return 1
            }
            success_msg "$description completed"
        else
            gum style --foreground 214 "Command skipped by user"
            return 0
        fi
    else
        # Silent mode - run without user confirmation
        gum spin --spinner dot --title "$description..." -- "${cmd[@]}" || {
            error_exit "Failed: $description"
        }
    fi
}

################################################################################
# 5. AUR HELPER SELECTION AND INSTALLATION
################################################################################

info_msg "Which AUR helper do you prefer?"
AUR_HELPER=$(gum choose "yay" "paru")

info_msg "Checking for $AUR_HELPER..."

if command -v "$AUR_HELPER" &> /dev/null; then
    success_msg "$AUR_HELPER is already installed"
else
    warning_msg "$AUR_HELPER not found. Installing now..."
    
    if [ "$INTERACTIVE" = "Yes (confirm each step)" ]; then
        if ! gum confirm "Clone and build $AUR_HELPER from AUR?"; then
            error_exit "Cannot continue without AUR helper"
        fi
    fi
    
    # Create temp directory safely
    tmp_dir=$(mktemp -d) || error_exit "Failed to create temporary directory"
    rm -rf "$tmp_dir"
    
    gum spin --spinner dot --title "Cloning $AUR_HELPER..." -- \
        git clone "https://aur.archlinux.org/$AUR_HELPER.git" "$tmp_dir/$AUR_HELPER" || \
        error_exit "Failed to clone $AUR_HELPER from AUR"
    
    gum spin --spinner dot --title "Building $AUR_HELPER..." -- bash -c \
        "cd '$tmp_dir/$AUR_HELPER' && makepkg -si --noconfirm" || \
        error_exit "Failed to build $AUR_HELPER"
    
    success_msg "$AUR_HELPER installed successfully"
fi

clear

################################################################################
# 6. INSTALL OFFICIAL PACKAGES
################################################################################

info_msg "Installing official Pacman packages (${#PACMAN_PKGS[@]} packages)..."

if [ "$INTERACTIVE" = "Yes (confirm each step)" ]; then
    gum confirm "Proceed with pacman installation?" || {
        warning_msg "Pacman installation skipped"
    } && \
    gum spin --spinner dot --title "Installing packages..." -- \
        sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
else
    gum spin --spinner dot --title "Installing Pacman packages..." -- \
        sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" || \
        error_exit "Pacman installation failed"
fi

success_msg "Official packages installed"
clear

################################################################################
# 7. INSTALL AUR PACKAGES
################################################################################

info_msg "Installing AUR packages (${#AUR_PKGS[@]} packages)..."

if [ "$INTERACTIVE" = "Yes (confirm each step)" ]; then
    gum confirm "Proceed with $AUR_HELPER installation?" || {
        warning_msg "$AUR_HELPER installation skipped"
    } && \
    gum spin --spinner dot --title "Installing from AUR..." -- \
        "$AUR_HELPER" -S --needed --noconfirm "${AUR_PKGS[@]}"
else
    gum spin --spinner dot --title "Installing from AUR..." -- \
        "$AUR_HELPER" -S --needed --noconfirm "${AUR_PKGS[@]}" || \
        error_exit "AUR installation failed"
fi

success_msg "AUR packages installed"
clear

################################################################################
# 8. COPY CONFIGURATIONS
################################################################################

info_msg "Verifying configuration files exist..."

# Function to check if directory exists in current repo
check_config_dir() {
    if [ ! -d "$1" ]; then
        error_exit "Configuration directory not found: $1 (current dir: $(pwd))"
    fi
}

# Verify all required directories exist
for config_dir in swaync alacritty fastfetch fish hypr random_conf_shit systemd wallust waybar rofi gtk-3.0; do
    check_config_dir "$config_dir"
done

[ -f daily-wall ] || error_exit "Script not found: daily-wall"
[ -f logind.conf ] || error_exit "File not found: logind.conf"
[ -f starship.catppuccin.toml ] || error_exit "File not found: starship.catppuccin.toml"
[ -d sddm-astronaut-theme ] || error_exit "Directory not found: sddm-astronaut-theme"

success_msg "All configuration files verified"

info_msg "Applying configurations..."

# Create necessary directories
mkdir -p ~/.config ~/.local ~/.local/share || error_exit "Failed to create config directories"

# Copy configurations with error checking
if cp -r swaync alacritty fastfetch fish hypr random_conf_shit systemd wallust waybar rofi gtk-3.0 ~/.config/; then
    success_msg "Configuration files copied to ~/.config"
else
    error_exit "Failed to copy configuration files"
fi

if cp daily-wall ~/.local/; then
    success_msg "Daily wallpaper script copied"
else
    error_exit "Failed to copy daily-wall script"
fi

if sudo cp logind.conf /etc/systemd/logind.conf; then
    success_msg "systemd logind.conf installed"
else
    error_exit "Failed to install logind.conf"
fi

if mv ~/.config/random_conf_shit/rofi ~/.local/share/; then
    success_msg "Rofi configuration moved"
else
    error_exit "Failed to move rofi configuration"
fi

if cp starship.catppuccin.toml ~/.config/starship.toml; then
    success_msg "Starship configuration applied"
else
    error_exit "Failed to apply starship configuration"
fi

clear

################################################################################
# 9. SDDM THEME APPLICATION
################################################################################

info_msg "Setting up SDDM theme..."

if ! sudo cp -r sddm-astronaut-theme /usr/share/sddm/themes/; then
    error_exit "Failed to install SDDM theme"
fi

if ! sudo mkdir -p /etc/sddm.conf.d; then
    error_exit "Failed to create SDDM config directory"
fi

if echo -e '[Theme]\nCurrent=sddm-astronaut-theme' | sudo tee /etc/sddm.conf.d/theme.conf > /dev/null; then
    success_msg "SDDM theme configured"
else
    error_exit "Failed to configure SDDM theme"
fi

clear

################################################################################
# 10. SET EXECUTABLE PERMISSIONS
################################################################################

info_msg "Setting executable permissions on scripts..."

# Array of scripts to make executable
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
        warning_msg "Script not found: $script"
    fi
done

success_msg "Script permissions set"
clear

################################################################################
# 11. DOWNLOAD WALLPAPERS
################################################################################

info_msg "Downloading wallpapers..."

mkdir -p ~/Pictures || error_exit "Failed to create Pictures directory"

# Download wallpapers with retry logic
WALLPAPER_URL="https://github.com/Aradhy-arch/aradhy-dotfiles/releases/download/Wallp/Wallpapers.zip"
WALLPAPER_FILE=~/Pictures/Wallpapers.zip

if gum spin --spinner dot --title "Downloading wallpapers..." -- \
    wget -P ~/Pictures/ "$WALLPAPER_URL" -O "$WALLPAPER_FILE"; then
    
    if unzip -o "$WALLPAPER_FILE" -d ~/Pictures/; then
        rm "$WALLPAPER_FILE" || warning_msg "Failed to clean up wallpaper zip"
        success_msg "Wallpapers downloaded and extracted"
    else
        error_exit "Failed to extract wallpapers"
    fi
else
    warning_msg "Failed to download wallpapers (proceeding without them)"
fi

clear

################################################################################
# 12. CONFIGURE IMAGE VIEWER
################################################################################

info_msg "Configuring image viewer (imv)..."

mkdir -p ~/.local/share/applications || error_exit "Failed to create applications directory"

if ! cp /usr/share/applications/imv.desktop ~/.local/share/applications/; then
    warning_msg "Failed to copy imv.desktop"
else
    # More readable sed command with explanation
    # This configures imv to open images in their directory context
    if sed -i 's/^Exec=.*/Exec=sh -c '"'"'imv -n "$1" "$(dirname "$1")"'"'"' sh %f/' \
        ~/.local/share/applications/imv.desktop; then
        success_msg "Image viewer configured"
    else
        warning_msg "Failed to configure imv desktop entry"
    fi
fi

clear

################################################################################
# 13. ENABLE SERVICES
################################################################################

info_msg "Enabling and starting services..."

# Function to safely enable systemd services
enable_service() {
    local service="$1"
    local service_type="$2"  # "system" or "user"
    
    if [ "$service_type" = "user" ]; then
        if systemctl --user enable "$service"; then
            success_msg "User service $service enabled"
        else
            warning_msg "Failed to enable user service $service"
        fi
    else
        if sudo systemctl enable "$service"; then
            success_msg "System service $service enabled"
        else
            warning_msg "Failed to enable system service $service (non-critical)"
        fi
    fi
}

# Enable system services
enable_service "sddm.service" "system"
enable_service "bluetooth.service" "system"

# Enable user timer
enable_service "daily-wall.timer" "user"

clear

################################################################################
# 14. FINAL SUMMARY
################################################################################

gum style \
    --foreground 46 --border-foreground 46 --border double \
    --align center --width 70 --margin "1 2" --padding "2 4" \
    "🎉 System Setup Complete! 🎉" \
    "" \
    "✓ All packages installed" \
    "✓ Configurations applied" \
    "✓ SDDM theme configured" \
    "✓ Services enabled" \
    "✓ Scripts and permissions set" \
    "" \
    "Your system is ready for rebooting."

echo ""
info_msg "Recommended next steps:"
echo "  1. Review ~/.config/hypr/hyprland.conf for keyboard bindings"
echo "  2. Reboot your system: reboot"
echo "  3. Login and enjoy your new setup!"
echo ""
gum style --foreground 46 "✨ Thank you for using Aradhy's dotfiles! ✨"

exit 0
