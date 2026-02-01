#!/usr/bin/env bash

echo " "
echo "---------------------"
echo "Atualizando sistema..."

sudo pacman -Syu

echo " "
echo "---------------------"
echo "Instalando os apps..."
sudo pacman -S --needed \
  fastfetch \
  zip \
  unzip \
  ffmpeg \
  ffmpegthumbs \
  ntfs-3g \
  discord \
  rclone \
  obs-studio \
  libreoffice-fresh \
  libreoffice-fresh-pt-br \
  dolphin-plugins \
  okular \
  gwenview \
  elisa \
  kcalc \
  unrar \
  p7zip \
  noto-fonts-cjk \
  rsync \
  net-tools \
  dnsutils \
  dnsmasq \
  reflector \
  mission-center \
  pavucontrol \
  vlc \
  vlc-plugins-all \
  qbittorrent \
  lact \
  steam \
  mangohud \
  gamemode

# -------------------------------------------------------------------
# 9) Instalação de apps via AUR
# -------------------------------------------------------------------
echo
echo "---------------------"
echo "Instalando aplicativos via AUR..."

# Detecta helper AUR (paru ou yay)
if command -v paru >/dev/null 2>&1; then
  AUR_HELPER="paru"
elif command -v yay >/dev/null 2>&1; then
  AUR_HELPER="yay"
else
  echo "Erro: nenhum helper AUR encontrado (paru ou yay)."
  exit 1
fi

echo "Usando helper AUR: $AUR_HELPER"

$AUR_HELPER -S --needed --noconfirm \
  brave-bin \
  vscodium-bin \
  heroic-games-launcher-bin \
  protonplus \
  sshpilot \
  mangojuice
