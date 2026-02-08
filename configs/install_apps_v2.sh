#!/usr/bin/env bash
set -u

ok()   { echo "[OK] $1"; }
warn() { echo "[ATENÇÃO] $1"; }
info() { echo "[INFO] $1"; }

# --------------------------
# Listas de pacotes (ativos)
# --------------------------
PACMAN_PKGS=(
  fastfetch
  zip
  unzip
  ffmpeg
  ffmpegthumbs
  ntfs-3g
  discord
  rclone
  obs-studio
  libreoffice-fresh
  libreoffice-fresh-pt-br
  dolphin-plugins
  okular
  gwenview
  elisa
  kcalc
  unrar
  p7zip
  noto-fonts-cjk
  rsync
  cpu-x
  net-tools
  dnsutils
  dnsmasq
  mission-center
  pavucontrol
  vlc
  vlc-plugins-all
  qbittorrent
  lact
  steam
  mangohud
  gamemode
)

# Comentados (mantidos pra referência)
# reflector
# goverlay

AUR_PKGS=(
  brave-bin
  vscodium-bin
  ttf-ms-fonts
  heroic-games-launcher-bin
  protonplus
  termius
  mangojuice
)

# Comentados (mantidos pra referência)
# sshpilot

# --------------------------
# Helpers
# --------------------------
is_installed() {
  pacman -Q "$1" >/dev/null 2>&1
}

validate_list() {
  local title="$1"; shift
  local -a pkgs=( "$@" )
  local missing=0

  echo
  echo "---------------------"
  echo "Validando: $title"

  for p in "${pkgs[@]}"; do
    if is_installed "$p"; then
      ok "$p instalado"
    else
      warn "$p NÃO está instalado"
      missing=$((missing + 1))
    fi
  done

  if [ "$missing" -eq 0 ]; then
    ok "Validado OK: $title (todos instalados)"
  else
    warn "Atenção: $title (faltando: $missing)"
  fi

  return "$missing"
}

# --------------------------
# Execução
# --------------------------
echo
echo "---------------------"
echo "Atualizando sistema..."
sudo pacman -Syu

echo
echo "---------------------"
echo "Instalando os apps (pacman)..."
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

# -------------------------------------------------------------------
# Instalação de apps via AUR
# -------------------------------------------------------------------
echo
echo "---------------------"
echo "Instalando aplicativos via AUR..."

if command -v paru >/dev/null 2>&1; then
  AUR_HELPER="paru"
elif command -v yay >/dev/null 2>&1; then
  AUR_HELPER="yay"
else
  warn "Nenhum helper AUR encontrado (paru ou yay). Pulando AUR."
  AUR_HELPER=""
fi

if [ -n "${AUR_HELPER}" ]; then
  info "Usando helper AUR: $AUR_HELPER"
  # --needed evita reinstalar; --noconfirm para rodar liso em script
  "$AUR_HELPER" -S --needed --noconfirm "${AUR_PKGS[@]}"
fi

# --------------------------
# Validação final
# --------------------------
missing_total=0

validate_list "Pacotes instalados via pacman" "${PACMAN_PKGS[@]}" || missing_total=$((missing_total + $?))

if [ -n "${AUR_HELPER}" ]; then
  validate_list "Pacotes instalados via AUR" "${AUR_PKGS[@]}" || missing_total=$((missing_total + $?))
else
  warn "Validação AUR pulada (sem helper AUR)."
fi

echo
echo "---------------------"
if [ "$missing_total" -eq 0 ]; then
  ok "Resultado final: todos os pacotes ATIVOS (descomentados) estão instalados."
else
  warn "Resultado final: faltam $missing_total pacote(s). Revise a saída acima."
fi
