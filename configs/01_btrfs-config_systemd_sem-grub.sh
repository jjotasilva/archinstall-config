#!/usr/bin/env bash
set -euo pipefail

# Pos-config Btrfs/Snapper para instalacao com systemd-boot (sem GRUB).
#
# Objetivo:
# - instalar apenas os pacotes oficiais necessarios para Btrfs/Snapper;
# - usar o Btrfs Assistant como interface grafica para administrar snapshots;
# - configurar Snapper para / e /home;
# - habilitar os timers de criacao/limpeza de snapshots;
# - nao instalar grub-btrfs;
# - nao habilitar grub-btrfsd;
# - nao adicionar grub-btrfs-overlayfs ao mkinitcpio.
#
# Rode como usuario normal:
#   sudo chmod +x 01_btrfs-config_systemd_sem-grub.sh
#   ./01_btrfs-config_systemd_sem-grub.sh
#
# O script usa sudo quando precisa.

if [[ $EUID -eq 0 ]]; then
  echo "Nao execute como root. Rode como usuario normal (o script usa sudo)."
  exit 1
fi

echo
echo "---------------------"
echo "Atualizando sistema..."
sudo pacman -Syu --noconfirm

# -----------------------------
# Pacotes oficiais Btrfs / Snapper
# -----------------------------
echo
echo "---------------------"
echo "Instalando pacotes oficiais Btrfs/Snapper..."
sudo pacman -S --needed --noconfirm \
  snapper \
  snap-pac \
  btrfsmaintenance \
  compsize \
  btrfs-assistant \
  plocate

# -----------------------------
# Configurar Snapper (idempotente)
# -----------------------------
echo
echo "---------------------"
echo "Configurando Snapper..."

if ! sudo snapper list-configs | awk '{print $1}' | grep -qx "root"; then
  sudo snapper -c root create-config /
fi

if ! sudo snapper list-configs | awk '{print $1}' | grep -qx "home"; then
  sudo snapper -c home create-config /home
fi

sudo snapper -c root set-config "ALLOW_USERS=$USER" "SYNC_ACL=yes"
sudo snapper -c home set-config "ALLOW_USERS=$USER" "SYNC_ACL=yes"

# Desativar timeline no /home, caso prefira snapshots automaticos somente da raiz.
# sudo snapper -c home set-config "TIMELINE_CREATE=no"

# -----------------------------
# updatedb.conf (plocate)
# -----------------------------
echo
echo "---------------------"
echo "Ajustando /etc/updatedb.conf..."

if [[ ! -f /etc/updatedb.conf ]]; then
  echo 'PRUNENAMES = ".git .hg .svn .snapshots"' | sudo tee /etc/updatedb.conf >/dev/null
else
  if grep -qE '^PRUNENAMES[[:space:]]*=' /etc/updatedb.conf; then
    for name in ".git" ".hg" ".svn" ".snapshots"; do
      if ! grep '^PRUNENAMES[[:space:]]*=' /etc/updatedb.conf | grep -Fqw "$name"; then
        sudo sed -i -E "s|^(PRUNENAMES[[:space:]]*=[[:space:]]*\")([^\"]*)\"|\1\2 ${name}\"|" /etc/updatedb.conf
      fi
    done
  else
    echo 'PRUNENAMES = ".git .hg .svn .snapshots"' | sudo tee -a /etc/updatedb.conf >/dev/null
  fi
fi

# -----------------------------
# Ativar timers do Snapper
# -----------------------------
echo
echo "---------------------"
echo "Ativando timers do Snapper..."
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer

echo
echo "---------------------"
echo "Configuracao concluida."
echo "Btrfs Assistant pode ser usado para visualizar, criar e restaurar snapshots do Snapper."
