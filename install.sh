#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

if [ "$EUID" -eq 0 ]; then
  echo "Please run this script as your normal user, NOT as root."
  exit 1
fi

# 0. Prerequisites (Silently install so gum works immediately)
sudo pacman -Sy --needed --noconfirm gum git unzip ttf-iosevka-nerd wget git base-devel > /dev/null 2>&1

# 1. Clone The Repo
rm -rf ~/aradhy-dotfiles && clear
gum spin --spinner dot --title "Cloning Repo..." -- git clone --depth=1 https://github.com/Aradhy-arch/aradhy-dotfiles
cd aradhy-dotfiles

PACMAN_PKGS=(
    fish btop zoxide fzf fastfetch starship eza bat micro neovim ark qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg
    hyprland hyprpaper hyprlock swaync cliphist grim slurp waybar rofi hyprpolkitagent hypridle hyprsunset
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk qt5-wayland qt6-wayland noto-fonts-cjk noto-fonts-emoji
    pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber
    bluez bluez-utils blueman wf-recorder brightnessctl
    alacritty discord spotify-launcher mousepad thunar sddm wl-clip-persist
)

AUR_PKGS=(
    cbonsai pipes.sh cmatrix wallust lavat volumectl
)

clear

# 2. Premium Welcome Screen
gum style \
	--foreground 220 --border-foreground 220 --border double \
	--align center --width 60 --margin "1 2" --padding "2 4" \
	"✨ Aradhy's Arch Setup ✨"

if ! gum confirm "Ready to install packages and apply dotfiles?"; then
    gum style --foreground 196 "Installation aborted."
    exit 0
fi

# 3. Interactive Mode Setup
gum style --foreground 220 "➔ See all command outputs and confirm before executing?"
INTERACTIVE=$(gum choose "Yes" "No")

run_cmd() {
    local cmd="$*"
    if [ "$INTERACTIVE" = "Yes" ]; then
        gum confirm "Execute: $cmd?" || return 0
        eval "$cmd"
    else
        eval "$cmd" > /dev/null 2>&1
    fi
}

# 4. Choose and Install AUR Helper
gum style --foreground 220 "➔ Choose your AUR helper:"
AUR_HELPER=$(gum choose "yay" "paru")

gum style --foreground 220 "➔ Checking for $AUR_HELPER..."
if command -v "$AUR_HELPER" &> /dev/null; then
    gum style --foreground 46 "  ✔️ $AUR_HELPER is already installed! Skipping..."
else
    gum style --foreground 214 "  📦 $AUR_HELPER not found. Installing now..."
    if [ "$INTERACTIVE" = "Yes" ]; then
        gum confirm "Clone and build $AUR_HELPER?" || exit 1
        git clone "https://aur.archlinux.org/$AUR_HELPER.git" "/tmp/$AUR_HELPER"
        cd "/tmp/$AUR_HELPER"
        makepkg -si --noconfirm
        cd - > /dev/null
        rm -rf "/tmp/$AUR_HELPER"
    else
        gum spin --spinner dot --title "Cloning $AUR_HELPER repository..." -- git clone "https://aur.archlinux.org/$AUR_HELPER.git" "/tmp/$AUR_HELPER"
        cd "/tmp/$AUR_HELPER"
        echo "Building $AUR_HELPER..."
        makepkg -si --noconfirm
        cd - > /dev/null
        rm -rf "/tmp/$AUR_HELPER"
    fi
fi

# 5. Install Packages
gum style --foreground 220 "➔ Installing Official Pacman Packages..."
if [ "$INTERACTIVE" = "Yes" ]; then
    gum confirm "Run pacman installation?" && sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
else
    echo "Downloading and installing pacman packages..."
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
fi

gum style --foreground 220 "➔ Installing AUR Packages..."
if [ "$INTERACTIVE" = "Yes" ]; then
    gum confirm "Run $AUR_HELPER installation?" && "$AUR_HELPER" -S --needed --noconfirm "${AUR_PKGS[@]}"
else
    echo "Building from AUR..."
    "$AUR_HELPER" -S --needed --noconfirm "${AUR_PKGS[@]}"
fi

# 6. Copying Configurations
gum style --foreground 220 "➔ Applying configurations..."
COPY_CMD="mkdir -p ~/.config ~/.local ~/.local/share && \
cp -r swaync alacritty fastfetch fish hypr random_conf_shit systemd wallust waybar rofi gtk-3.0 ~/.config && \
cp daily-wall ~/.local && \
mv ~/.config/random_conf_shit/rofi ~/.local/share && \
cp starship.catppuccin.toml starship.toml ~/.config"

run_cmd "$COPY_CMD"

# 7. SDDM Theme Application
gum style --foreground 220 "➔ Setting up SDDM Theme..."
SDDM_CMD="sudo cp -r sddm-astronaut-theme /usr/share/sddm/themes/ && \
sudo mkdir -p /etc/sddm.conf.d && \
echo -e '[Theme]\nCurrent=sddm-astronaut-theme' | sudo tee /etc/sddm.conf.d/theme.conf"

run_cmd "$SDDM_CMD"

# 8. Setting Executable Permissions & Downloading Wallpapers
gum style --foreground 220 "➔ Setting script permissions..."
PERM_CMD="chmod +x ~/.config/random_conf_shit/sddmtheme.sh \
~/.config/random_conf_shit/usb_formatter.sh \
~/.local/daily-wall \
~/.config/hypr/scripts/wifi-menu.sh \
~/.config/hypr/scripts/power_menu.sh \
~/.config/hypr/scripts/reboot_menu.sh \
~/.config/wallust/templates/set_bg.sh \
~/.config/hypr/scripts/rofi-bluetooth.sh \
~/.config/hypr/scripts/screen-record.sh"

run_cmd "$PERM_CMD"

gum style --foreground 220 "➔ Downloading Wallpapers..."
WALL_CMD="wget -P ~/Pictures/ https://github.com/Aradhy-arch/aradhy-dotfiles/releases/download/Wallp/Wallpapers.zip && \
unzip -o ~/Pictures/Wallpapers.zip -d ~/Pictures/ && \
rm ~/Pictures/Wallpapers.zip"

run_cmd "$WALL_CMD"

# 9. Enabling Services
gum style --foreground 220 "➔ Enabling Services (SDDM, Bluetooth, & Daily Wallpaper)..."
SVC_CMD="sudo systemctl enable sddm.service || true; \
sudo systemctl enable bluetooth.service || true; \
systemctl --user enable --now daily-wall.timer || true"

run_cmd "$SVC_CMD"

gum style \
	--foreground 220 --border-foreground 220 --border rounded \
	--align center --width 60 --margin "1 2" --padding "1 2" \
	"🎉 System setup complete! 🎉" \
    "" \
    "Reboot your system to enter your new workspace."
