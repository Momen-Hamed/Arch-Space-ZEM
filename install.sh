#!/usr/bin/env bash

# mesa lib32-mesa -media-driver vulkan-intel lib32-vulkan-intel
set -e

# -----------------------------
# Helpers
# -----------------------------
pacman_install() {
  sudo pacman -S --needed --noconfirm "$@"
}

yay_install() {
  yay -S --needed --noconfirm "$@"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -----------------------------
# Enable multilib
# -----------------------------
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
  echo "==> Enabling multilib..."
  sudo sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
  sudo pacman -Sy --noconfirm
fi

# -----------------------------
# System update
# -----------------------------
echo "==> Updating system..."
sudo pacman -Syu --noconfirm

# -----------------------------
# Diagnose
# -----------------------------
if [ -f "$SCRIPT_DIR/diagnose.sh" ]; then
  bash "$SCRIPT_DIR/diagnose.sh"
fi

# -----------------------------
# Base packages
# -----------------------------
pacman_install \
  kitty \
  bluez bluez-utils \
  base-devel git cpio cmake pkg-config gcc \
  hyprland sudo wget curl \
  wayland wayland-protocols \
  xorg-xwayland xorg-xhost \
  pipewire wireplumber \
  greetd \
  pipewire-audio pipewire-alsa pipewire-pulse pipewire-jack \
  lib32-pipewire lib32-pipewire-jack lib32-libpulse \
  xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  polkit-gnome \
  efibootmgr \
  zsh zsh-autosuggestions zsh-syntax-highlighting \
  nautilus gparted \
  rofi waybar slurp grim cliphist hyprlock hypridle \
  qalculate-gtk btop cava cowsay \
  gnome-clocks gnome-text-editor \
  inter-font noto-fonts-emoji nerd-fonts noto-fonts-cjk \
  adw-gtk-theme ntfs-3g \
  wine-mono wine-gecko winetricks zenity \
  ffmpeg gamescope telegram-desktop \
  gst-plugins-{base,good,bad,ugly} \
  samba gnutls sdl2-compat \
  swaync \
  font-manager \
  mangohud lib32-mangohud gamemode lib32-gamemode goverlay vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools steam \
  discord \
  blueman \
  scrcpy wayvnc \
  thermald \
  flatpak \
  xdg-utils \
  linux-headers \
  ufw \
  swww \
  eog \
  matugen \
  jq \
  brightnessctl \
  fastfetch \
  rofi-emoji \
  pacman-contrib \
  rsync \
  vulkan-headers \
  power-profiles-daemon \
  gobject-introspection python-gobject \
  satty \
  qt5-base qt6-base qt5-tools qt6-tools qt5-wayland qt6-wayland \
  evince \
  totem \
  unrar \
  rofimoji \
  file-roller \
  gnome-calendar \
  gnome-weather \
  vkd3d \
  sound-theme-freedesktop libcanberra libcanberra-pulse socat \
  gnome-system-monitor \
  timeshift \
  wtype \
  bc \
  hyprpicker \
  qt6-5compat qt5-graphicaleffects

# -----------------------------
# VirtualBox
# -----------------------------
read -rp "Install VirtualBox? [y/N]: " VBOX_CONFIRM
if [[ "$VBOX_CONFIRM" =~ ^[Yy]$ ]]; then
  sudo pacman -S --needed --noconfirm virtualbox virtualbox-host-modules-arch
  sudo modprobe vboxdrv
  sudo modprobe vboxnetflt
  sudo modprobe vboxnetadp
fi

# -----------------------------
# Remove bad portal
# -----------------------------
sudo pacman -Rns --noconfirm xdg-desktop-portal-wlr 2>/dev/null || true

# -----------------------------
# Enable PipeWire
# -----------------------------
sudo systemctl enable greetd.service
sudo systemctl enable --now bluetooth
systemctl --user enable --now pipewire.service
systemctl --user enable --now wireplumber.service
systemctl --user enable --now pipewire-pulse.socket
systemctl --user enable --now pipewire-pulse.service
sudo systemctl enable --now thermald.service
sudo systemctl enable --now ufw.service
sudo systemctl enable --now power-profiles-daemon

# -----------------------------
# Configure greetd
# -----------------------------
GREETD_CONFIG="/etc/greetd/config.toml"
USERNAME=$(whoami)

echo "==> Configuring greetd..."

sudo grep -q '^\[default_session\]' "$GREETD_CONFIG" || \
  sudo tee -a "$GREETD_CONFIG" >/dev/null <<EOF
[default_session]
command = "start-hyprland"
user = "$USERNAME"
EOF

sudo sed -i "
/^\[default_session\]/,/^\[/ {
  s/^command *=.*/command = \"start-hyprland\"/
  s/^user *=.*/user = \"$USERNAME\"/
}
" "$GREETD_CONFIG"

sudo grep -q '^command *= *"start-hyprland"' "$GREETD_CONFIG" || \
  sudo sed -i '/^\[default_session\]/a command = "start-hyprland"' "$GREETD_CONFIG"

sudo grep -q "^user *= *\"$USERNAME\"" "$GREETD_CONFIG" || \
  sudo sed -i "/^\[default_session\]/a user = \"$USERNAME\"" "$GREETD_CONFIG"

# -----------------------------
# Editor setup
# -----------------------------
echo "Select editor to install:"
echo "1) NvChad (neovim)"
echo "2) nano"
echo "3) Skip"
read -rp "Choice [1/2/3]: " EDITOR_CHOICE

if [[ "$EDITOR_CHOICE" == "1" ]]; then
  sudo pacman -S --needed --noconfirm neovim
  NVIM_DIR="$HOME/.config/nvim"
  NVCHAD_MARKER="$NVIM_DIR/lua/core/init.lua"
  if [ ! -f "$NVCHAD_MARKER" ]; then
    echo "==> Installing NvChad..."
    git clone https://github.com/NvChad/starter "$NVIM_DIR" || true
  else
    echo "==> NvChad already installed, skipping clone"
  fi
  cp -f nvim_plugins/* "$NVIM_DIR/lua/plugins/"
  nvim
  INIT_LUA="$NVIM_DIR/init.lua"
  if ! grep -q "Load matugen colors" "$INIT_LUA" 2>/dev/null; then
    cat >> "$INIT_LUA" <<'EOF'
-- Load matugen colors after startup
vim.schedule(function()
  require "mappings"
  local colors = vim.fn.stdpath("config") .. "/colors.lua"
  if vim.fn.filereadable(colors) == 1 then
    dofile(colors)
  end
end)
EOF
  fi
  COLORS_LUA="$NVIM_DIR/colors.lua"
  [ -f "$COLORS_LUA" ] || touch "$COLORS_LUA"
elif [[ "$EDITOR_CHOICE" == "2" ]]; then
  echo "==> Installing nano..."
  sudo pacman -S --needed --noconfirm nano
else
  echo "==> Skipping editor install."
fi

# -----------------------------
# AUR packages
# -----------------------------
yay_install \
  pavucontrol \
  bibata-cursor-theme-bin \
  heroic-games-launcher-bin \
  elecwhat-bin \
  ttf-symbola \
  freedownloadmanager \
  visual-studio-code-bin \
  proton-ge-custom-bin \
  protonup-qt-bin \
  spotify \
  cmatrix-git \
  overskride-bin \
  nmgui-bin \
  network-manager-applet \
  ocean-sound-theme \
  adwsteamgtk \
  dxvk-bin \
  darkly-qt6-git \
  darkly-qt5-git \
  swayosd-git

# -----------------------------
# Browser
# -----------------------------
echo "Select browser to install:"
echo "1) Brave"
echo "2) Zen Browser"
echo "3) Firefox"
echo "4) Google Chrome"
echo "5) Skip"
read -rp "Choice [1/2/3/4/5]: " BROWSER_CHOICE

case "$BROWSER_CHOICE" in
  1) yay -S --needed --noconfirm brave-bin ;;
  2) yay -S --needed --noconfirm zen-browser-bin ;;
  3) sudo pacman -S --needed --noconfirm firefox ;;
  4) yay -S --needed --noconfirm google-chrome ;;
  *) echo "==> Skipping browser install." ;;
esac

cd /usr/share/icons/
sudo rm -rf Bibata-Modern-Amber Bibata-Modern-Amber-Right Bibata-Modern-Classic-Right Bibata-Modern-Ice Bibata-Modern-Ice-Right Bibata-Original-Amber Bibata-Original-Amber Bibata-Original-Amber-Right Bibata-Original-Classic Bibata-Original-Classic-Right Bibata-Original-Ice Bibata-Original-Ice-Right
cd ~/

# -----------------------------
# Flatpak
# -----------------------------
read -rp "Install Roblox (Sober)? [y/N]: " ROBLOX_CONFIRM
if [[ "$ROBLOX_CONFIRM" =~ ^[Yy]$ ]]; then
  flatpak install flathub org.vinegarhq.Sober || true
fi

# -----------------------------
# Nautilus default
# -----------------------------
xdg-mime query default inode/directory | grep -q Nautilus || \
xdg-mime default org.gnome.Nautilus.desktop inode/directory

# -----------------------------
# Deploy dotfiles (force overwrite)
# -----------------------------
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
curl -sS https://starship.rs/install.sh | sh
if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

echo "==> Copying dotfiles to home (overwrite enabled)..."

# Copy .config (merge, overwrite same files)
if [ -d "$SCRIPT_DIR/.config" ]; then
  rsync -a --checksum "$SCRIPT_DIR/.config/" "$HOME/.config/"
fi
# Copy .local (merge, overwrite same files)
if [ -d "$SCRIPT_DIR/.local" ]; then
  rsync -a --checksum "$SCRIPT_DIR/.local/"  "$HOME/.local/"
fi
# Copy .zshrc (replace file)
if [ -f "$SCRIPT_DIR/.zshrc" ]; then
  rsync -a --checksum "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
fi

# -----------------------------
# Hyprlock username
# -----------------------------
HYPRLOCK_CONF="$HOME/.config/hypr/hyprlock.conf"
if [ -f "$HYPRLOCK_CONF" ]; then
  echo "Hyprlock display name:"
  echo "1) Keep default (\$USER)"
  echo "2) Set custom name"
  read -rp "Choice [1/2]: " HYPRLOCK_CHOICE
  if [[ "$HYPRLOCK_CHOICE" == "2" ]]; then
    read -rp "Enter display name: " HYPRLOCK_NAME
    sed -i "s/text = \$USER/text = $HYPRLOCK_NAME/" "$HYPRLOCK_CONF"
  fi
fi

# -----------------------------
# Root GTK theming
# -----------------------------
sudo mkdir -p /root/.config
sudo ln -sf ~/.config/gtk-3.0 /root/.config/
sudo ln -sf ~/.config/gtk-4.0 /root/.config/
sudo ln -sf ~/.config/nvim /root/.config/

# -----------------------------
# X access for root apps
# -----------------------------
xhost +SI:localuser:root || true

# -----------------------------
# Time & NTP
# -----------------------------
TIMEZONE=$(curl -s https://ipapi.co/timezone)
sudo timedatectl set-timezone "$TIMEZONE"
sudo timedatectl set-local-rtc 1 --adjust-system-clock
sudo timedatectl set-ntp true

timedatectl status | grep -E "Time zone|System clock synchronized|NTP service"

cd ~/
git clone https://github.com/vinceliuice/Colloid-icon-theme.git; cd Colloid-icon-theme/
./install.sh -s default
cd ~/
rm -rf Colloid-icon-theme/

mkdir -p ~/Videos ~/Documents ~/Pictures ~/Downloads ~/Desktop
echo
echo "✅ Setup complete."

# -----------------------------
# Reboot confirmation
# -----------------------------
read -rp "🔄 Reboot now? [y/N]: " REBOOT_CONFIRM
if [[ "$REBOOT_CONFIRM" =~ ^[Yy]$ ]]; then
  sudo reboot
else
  echo "Reboot skipped."
fi
