#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

if [ "$EUID" -eq 0 ]; then
  echo "Please run this script as your normal user, NOT as root."
  exit 1
fi

# 1. Prerequisites (Silently install so gum works immediately)
sudo pacman -Sy --needed --noconfirm gum unzip ttf-iosevka-nerd wget git base-devel > /dev/null 2>&1

PACMAN_PKGS=(
    fish btop zoxide fzf fastfetch starship eza bat micro neovim ark
    hyprland hyprpaper hyprlock swaync cliphist grim slurp waybar rofi hyprpolkitagent
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk qt5-wayland qt6-wayland
    pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber
    bluez bluez-utils blueman
    alacritty discord spotify-launcher mousepad thunar sddm
)

YAY_PKGS=(
    cbonsai pipes.sh cmatrix wallust
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

# 3. Check and Install yay
gum style --foreground 220 "➔ Checking for yay..."
if command -v yay &> /dev/null; then
    gum style --foreground 46 "  ✔️ yay is already installed! Skipping..."
else
    gum style --foreground 214 "  📦 yay not found. Installing now..."
    gum spin --spinner dot --title "Cloning yay repository..." -- git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    gum spin --spinner dot --title "Building yay..." -- makepkg -si --noconfirm
    cd - > /dev/null
    rm -rf /tmp/yay
fi

# 4. Install Packages
gum style --foreground 220 "➔ Installing Official Pacman Packages..."
gum spin --spinner line --title "Downloading and installing..." -- sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

gum style --foreground 220 "➔ Installing AUR Packages..."
gum spin --spinner line --title "Building from AUR..." -- yay -S --needed --noconfirm "${YAY_PKGS[@]}"

# 5. Copying Configurations
gum style --foreground 220 "➔ Applying configurations..."
mkdir -p ~/.config
mkdir -p ~/.local

cp -r alacritty ~/.config
cp -r fastfetch ~/.config
cp -r fish ~/.config
cp -r hypr ~/.config
cp -r random_conf_shit ~/.config
cp -r systemd ~/.config
cp -r wallust ~/.config
cp -r waybar ~/.config
cp daily-wall ~/.local
cp -r rofi ~/.config
mv -r ~/.config/random_conf_shit/rofi ~/.local/share

# Standard files
cp starship.catppuccin.toml ~/.config
cp starship.toml ~/.config

# 6. SDDM Theme Application
gum style --foreground 220 "➔ Setting up SDDM Theme..."
sudo cp -r sddm-astronaut-theme /usr/share/sddm/themes/
sudo mkdir -p /etc/sddm.conf.d
echo -e "[Theme]\nCurrent=sddm-astronaut-theme" | sudo tee /etc/sddm.conf.d/theme.conf > /dev/null

# 7. Setting Executable Permissions
gum style --foreground 220 "➔ Setting script permissions..."
chmod +x ~/.config/random_conf_shit/sddmtheme.sh
chmod +x ~/.config/random_conf_shit/usb_formatter.sh
chmod +x ~/.local/daily-wall
chmod +x ~/.config/hypr/scripts/wifi-menu.sh
chmod +x ~/.config/hypr/scripts/power_menu.sh
chmod +x ~/.config/wallust/templates/set_bg.sh
wget -P ~/Pictures/ https://github.com/Aradhy-arch/aradhy-dotfiles/releases/download/Wallp/Wallpapers.zip && unzip ~/Pictures/Wallpapers.zip -d ~/Pictures/ && rm ~/Pictures/Wallpapers.zip

# 8. Enabling Services
gum style --foreground 220 "➔ Enabling Services (SDDM, Bluetooth, & Daily Wallpaper)..."
sudo systemctl enable sddm.service > /dev/null 2>&1 || true
sudo systemctl enable bluetooth.service > /dev/null 2>&1 || true
systemctl --user enable --now daily-wall.timer > /dev/null 2>&1 || true

gum style \
	--foreground 220 --border-foreground 220 --border rounded \
	--align center --width 60 --margin "1 2" --padding "1 2" \
	"🎉 System setup complete! 🎉" \
    "" \
    "Reboot your system to enter your new workspace."
