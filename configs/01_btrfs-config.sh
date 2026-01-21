#!/usr/bin/env bash
set -euo pipefail

# Pos-config: instala paru (AUR), pacotes Btrfs/Snapper, configura Snapper e GRUB-Btrfs,
# e adiciona o hook grub-btrfs-overlayfs no mkinitcpio.conf (somente se existir).
#
# Rode como usuario normal:
#   chmod +x pos-config.sh
#   ./pos-config.sh
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
  inotify-tools

echo
echo "---------------------"
echo "Instalando btrfs-assistant (AUR)..."
paru -S --needed --noconfirm btrfs-assistant

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
sudo snapper -c home set-config "TIMELINE_CREATE=no"

# -----------------------------
# updatedb.conf (plocate/mlocate)
# -----------------------------
echo
echo "---------------------"
echo "Ajustando /etc/updatedb.conf..."
sudo sed -i 's|^PRUNENAMES[[:space:]]*=[[:space:]]*".*"|PRUNENAMES = ".git .hg .svn .snapshots"|' /etc/updatedb.conf

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
