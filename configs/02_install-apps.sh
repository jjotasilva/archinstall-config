#!/usr/bin/env bash

echo " "
echo "---------------------"
echo "Atualizando sistema..."

sudo pacman -Suy

echo " "
echo "---------------------"
echo "Instalando os apps..."
sudo pacman -S --needed \
  fastfetch \
  zip \
  unzip \
  ffmpeg \
  ntfs-3g \
  discord \
  rclone \
  obs-studio \
  libreoffice-fresh \
  libreoffice-fresh-br \
  dolphin-plugins \
  okular \
  transmission-qt \
  intel-ucode \
  gwenview \
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
  steam \
  mangohud \
  goverlay \
  gamemode


