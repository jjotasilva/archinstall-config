#!/usr/bin/env bash

set -u

ok()   { echo "[OK] $1"; }
warn() { echo "[ATENÇÃO] $1"; }

check_cmd() {
  local desc="$1"
  shift
  if eval "$@" >/dev/null 2>&1; then
    ok "$desc"
  else
    warn "$desc"
  fi
}

echo "==============================================="
echo "CHECKLIST PÓS-INSTALAÇÃO (Archinstall Custom)"
echo "==============================================="
echo

############################################################
# 1) GRUB / EFI
############################################################
check_cmd "GRUB em /boot e EFI loader OK (/efi/EFI/arch/grubx64.efi)" \
  'test -d /boot/grub && test -f /boot/grub/grub.cfg && test -f /efi/EFI/arch/grubx64.efi'

############################################################
# 2) NoCOW em @images
############################################################
check_cmd "NoCOW (+C) aplicado em /var/lib/libvirt/images" \
  'lsattr -d /var/lib/libvirt/images | grep -q "C"'

############################################################
# 3) alias ll no bash global
############################################################
check_cmd "alias ll aplicado em /etc/bash.bashrc" \
  'grep -qxF '\''alias ll="ls -lh --color=auto"'\'' /etc/bash.bashrc'

############################################################
# 4) nano syntax highlight
############################################################
check_cmd "include nano syntax aplicado em /etc/nanorc" \
  'grep -qxF '\''include "/usr/share/nano/*.nanorc"'\'' /etc/nanorc'

############################################################
# 5) pacman.conf (Color / ILoveCandy / ParallelDownloads)
############################################################
check_cmd "pacman.conf com Color, ILoveCandy e ParallelDownloads=20" \
  'grep -qxF "Color" /etc/pacman.conf && grep -qxF "ILoveCandy" /etc/pacman.conf && grep -qxF "ParallelDownloads = 20" /etc/pacman.conf'

############################################################
# 6) timesyncd.conf (NTP.br) + serviço ativo
############################################################
check_cmd "timesyncd.conf configurado com NTP.br e serviço ativo (systemd-timesyncd)" \
  'grep -qxF "NTP=a.st1.ntp.br b.st1.ntp.br c.st1.ntp.br d.st1.ntp.br" /etc/systemd/timesyncd.conf && grep -qxF "FallbackNTP=a.ntp.br b.ntp.br c.ntp.br" /etc/systemd/timesyncd.conf && systemctl is-enabled --quiet systemd-timesyncd && systemctl is-active --quiet systemd-timesyncd'

############################################################
# 7) Serviços (sem duplicar validação)
############################################################
check_cmd "Serviço habilitado (fstrim.timer)" \
  'systemctl is-enabled --quiet fstrim.timer'

check_cmd "Serviço habilitado e ativo (power-profiles-daemon)" \
  'systemctl is-enabled --quiet power-profiles-daemon && systemctl is-active --quiet power-profiles-daemon'

############################################################
# 8) Pacotes instalados
############################################################
check_cmd "Pacotes do custom JSON instalados" \
  'pacman -Q man man-db man-pages plocate amd-ucode git curl nano-syntax-highlighting bash-completion base-devel firefox firefox-i18n-pt-br power-profiles-daemon python-pyqt6 alsa-utils dmidecode cloud-guest-utils'

echo
echo "==============================================="
echo "CHECK FINALIZADO"
echo "==============================================="
