<div align="center">

# ❄️ Aradhy's Dotfiles

*My personal Arch Linux configuration files, optimized for speed, aesthetics, and productivity.*

[![OS](https://img.shields.io/badge/OS-Arch%20Linux-1793D1?logo=arch-linux&logoColor=white&style=for-the-badge)](#)
[![Shell](https://img.shields.io/badge/Shell-Fish-blue?logo=gnubash&logoColor=white&style=for-the-badge)](#)
[![Terminal](https://img.shields.io/badge/Terminal-Alacritty-FF6B6B?logo=alacritty&logoColor=white&style=for-the-badge)](#)
[![Theme](https://img.shields.io/badge/Theme-Catppuccin-b4befe?logo=catppuccin&logoColor=white&style=for-the-badge)](#)

</div>

---

### 🖥️ Overview

A minimal, keyboard-driven desktop workspace built on top of **Arch Linux**. Styled primarily around the **Catppuccin** palette with a focus on responsiveness and a clutter-free environment.

### 📸 Screenshots

![Desktop Preview](./Screenshots/desktop.png)
![Fastfetch Specs](./Screenshots/fastfetch.png)

### Features xD

The main attraction of these dotfiles is alacritty and wallust tho my fish config is awesome! I have set it up so that after running `wallust run /path/to/your/image`, it dynamically updates your wallpaper, your fastfetch, starship prompt, and alacritty config. But what if you didin't loke it? so for that reason I spent hours creating a custom flag for wallust which is `wallust --restore` It basically restores everything back to normal :D

### ⚙️ System Details

| Component | Choice |
| :--- | :--- |
| **OS** | [Arch Linux](https://archlinux.org/) |
| **Terminal** | [Alacritty](https://github.com/alacritty/alacritty) |
| **Shell** | [Fish Shell](https://fishshell.com/) |
| **Prompt** | [Starship](https://starship.rs/) |
| **Colorscheme** | [Catppuccin](https://github.com/catppuccin/catppuccin) |

---

## 📂 Repository Structure

```text
aradhy-dotfiles/
├── .config/
│   ├── alacritty/       # Alacritty terminal configuration & colors
│   ├── fish/            # Fish shell functions, aliases, & config
│   ├── starship.toml    # Custom cross-shell prompt configuration
│   └── ...              # Other application configs
├── scripts/             # Useful maintenance & helper scripts
└── README.md
```

---

## 🚀 Installation

> [!WARNING]
> Before cloning or linking any configurations, ensure you back up your existing files (`~/.config/`).

### Automatic Install:-

```bash
git clone --depth=1 https://github.com/Aradhy-arch/aradhy-dotfiles
cd ~/aradhy-dotfiles
./install.sh
```
### Manual Install:-
1. Clone the repo:
```bash
git clone --depth=1 https://github.com/Aradhy-arch/aradhy-dotfiles
```
2. Move the folders into `~/.config`:-
```bash
cp -r alacritty ~/.config
cp -r fastfetch ~/.config
cp -r fish ~/.config
cp -r hypr ~/.config
cp -r random_conf_shit ~/.config
cp -r systemd ~/.config
cp -r wallust ~/.config
cp -r waybar ~/.config
```
3. Move the rest of the files:-
```bash
cp daily-wall ~/.local
cp starship.catppuccin.toml ~/.config
cp starship.toml ~/.config
```
4. Apply the SDDM theme:-
```bash
sudo cp -r sddm-astronaut-theme /usr/share/sddm/themes/
sudo mkdir -p /etc/sddm.conf.d
echo -e "[Theme]\nCurrent=sddm-astronaut-theme" | sudo tee /etc/sddm.conf.d/theme.conf > /dev/null
```
5. Make stuff executable:-
```bash
chmod +x ~/.config/random_conf_shit/sddmtheme.sh
chmod +x ~/.config/random_conf_shit/usb_formatter.sh
chmod +x ~/.local/daily-wall
chmod +x ~/.config/wallust/templates/set_bg.sh
```
---

## 🎨 Credits & Acknowledgments

I did not create the wallpapers, assets, or third-party artwork included in this repository. If you are the original artist or creator of any work featured here, please reach out by opening an issue or contacting me—I will gladly add proper credits and links to your work!

---

<div align="center">

*Configured and maintained by **[Aradhy Jain](https://github.com/Aradhy-arch)**.*

</div>
