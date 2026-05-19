#!/usr/bin/env bash
set -euo pipefail

# Pos-config: instala paru (AUR), pacotes Btrfs/Snapper, configura Snapper e GRUB-Btrfs,
# e adiciona o hook grub-btrfs-overlayfs no mkinitcpio.conf (somente se existir).
#
# Rode como usuario normal:
#   sudo chmod +x 01_btrfs-config_v2.sh
#   ./01_btrfs-config_v2.sh
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

echo
echo "---------------------"
echo "Dependencias base..."
sudo pacman -S --needed --noconfirm base-devel git

# -----------------------------
# Instalar PARU (AUR)
# -----------------------------
if ! command -v paru >/dev/null 2>&1; then
  echo
  echo "---------------------"
  echo "Instalando PARU..."
  tmpdir="$(mktemp -d)"
  git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
  (cd "$tmpdir/paru" && makepkg -si --noconfirm)
  rm -rf "$tmpdir"
else
  echo
  echo "---------------------"
  echo "PARU ja instalado."
fi

# -----------------------------
# Pacotes BTRFS / Snapper
# -----------------------------
echo
echo "---------------------"
echo "Instalando pacotes BTRFS/Snapper..."
sudo pacman -S --needed --noconfirm \
  snapper \
  snap-pac \
  grub-btrfs \
  compsize \
  inotify-tools

echo
echo "---------------------"
echo "Instalando btrfs-assistant (AUR)..."
paru -S --needed --noconfirm btrfs-assistant btrfsmaintenance

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

# Desativar timeline no /home (se esse for seu padrao)
#sudo snapper -c home set-config "TIMELINE_CREATE=no"

# -----------------------------
# updatedb.conf (plocate/mlocate)
# -----------------------------
echo
echo "---------------------"
echo "Ajustando /etc/updatedb.conf..."

if ! pacman -Qq plocate >/dev/null 2>&1; then
  echo "plocate nao encontrado. Instalando..."
  sudo pacman -S --needed --noconfirm plocate
fi

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
# Ativar timers / serviços
# -----------------------------
echo
echo "---------------------"
echo "Ativando timers do Snapper..."
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer

echo
echo "---------------------"
echo "Ativando grub-btrfsd..."
sudo systemctl enable --now grub-btrfsd.service

# -----------------------------
# mkinitcpio: adicionar hook grub-btrfs-overlayfs (somente se existir)
# -----------------------------
echo
echo "---------------------"
echo "Ajustando /etc/mkinitcpio.conf (hook grub-btrfs-overlayfs)..."

HOOK_NAME="grub-btrfs-overlayfs"

if [[ -f "/usr/lib/initcpio/hooks/${HOOK_NAME}" || -f "/usr/lib/initcpio/install/${HOOK_NAME}" ]]; then
  if grep -qE '^HOOKS=\(.*\bgrub-btrfs-overlayfs\b.*\)' /etc/mkinitcpio.conf; then
    echo "mkinitcpio: hook ${HOOK_NAME} ja esta presente."
  else
    # Adiciona antes do ")" final do HOOKS=(...)
    sudo sed -i -E "s/^(HOOKS=\([^)]*)\)/\1 ${HOOK_NAME})/" /etc/mkinitcpio.conf
    echo "mkinitcpio: hook ${HOOK_NAME} adicionado."
  fi

  echo "Regerando initramfs..."
  sudo mkinitcpio -P
else
  echo "mkinitcpio: hook ${HOOK_NAME} nao encontrado em /usr/lib/initcpio."
  echo "Nao alterei /etc/mkinitcpio.conf e nao rodei mkinitcpio -P."
  echo "Se voce espera esse hook, descreva qual pacote/hook voce quer usar e eu ajusto."
fi

echo
echo "---------------------"
echo "Concluido."
