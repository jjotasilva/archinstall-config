#!/usr/bin/env bash
set -euo pipefail

echo
echo "---------------------"
echo "Pos-config: reflector, PS1 e servicos"

# Requer sudo (mas nao precisa rodar como root)
if ! sudo -n true 2>/dev/null; then
  echo "Vai pedir sua senha do sudo..."
fi

# -------------------------------------------------------------------
# 5) Reflector: espelhos de repositório
# -------------------------------------------------------------------
#echo
#echo "---------------------"
#echo "Configurando mirrorlist (reflector)..."
#
#if ! command -v reflector >/dev/null 2>&1; then
#  sudo pacman -S --needed reflector
#fi
#
#if [ ! -f /etc/pacman.d/mirrorlist.bkp ]; then
#  sudo cp -p /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bkp
#fi
#
#sudo reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

# -------------------------------------------------------------------
# 6) Bash prompt customizado (PS1)
# -------------------------------------------------------------------
echo
echo "---------------------"
echo "Configurando PS1 no ~/.bashrc..."

USER_BASHRC="$HOME/.bashrc"
touch "$USER_BASHRC"

# Comenta PS1 padrao (somente se a linha comecar exatamente com PS1=)
sed -i 's|^PS1=|#PS1=|' "$USER_BASHRC" || true

# Adiciona PS1 customizado se ainda nao existir
if ! grep -q 'Custom bash prompt via kirsle.net/wizards/ps1.html' "$USER_BASHRC"; then
  cat << 'EOF' >> "$USER_BASHRC"

# Custom bash prompt via kirsle.net/wizards/ps1.html
export PS1="\[$(tput bold)\]\[$(tput setaf 2)\][\u@\h \W]\\$ \[$(tput sgr0)\]"
EOF
fi

# -------------------------------------------------------------------
# 7) Serviços
# -------------------------------------------------------------------
echo
echo "---------------------"
echo "Validando pacotes e habilitando servicos..."

# Instala firewalld e power-profiles-daemon se nao estiverem instalados
need_pkgs=()

# pacman -Q firewalld >/dev/null 2>&1 || need_pkgs+=("firewalld")
pacman -Q power-profiles-daemon >/dev/null 2>&1 || need_pkgs+=("power-profiles-daemon")
pacman -Q gamemode >/dev/null 2>&1 || need_pkgs+=("gamemode")

if [ "${#need_pkgs[@]}" -gt 0 ]; then
  sudo pacman -S --needed "${need_pkgs[@]}"
fi

# Habilitar timers/servicos (enable --now e idempotente)
sudo systemctl enable --now fstrim.timer
# sudo systemctl enable --now firewalld.service
sudo systemctl enable --now power-profiles-daemon.service
# sudo systemctl enable --now systemd-resolved
sudo systemctl enable --now systemd-timesyncd
systemctl --user enable --now gamemoded

echo
echo "Concluido. Abra um novo terminal (ou faca logout/login) para aplicar o PS1."

