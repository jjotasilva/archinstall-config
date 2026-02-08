#!/usr/bin/env bash
set -euo pipefail

OK_COUNT=0
WARN_COUNT=0

ok()   { echo "[OK] $1"; OK_COUNT=$((OK_COUNT + 1)); }
warn() { echo "[ATENÇÃO] $1"; WARN_COUNT=$((WARN_COUNT + 1)); }
info() { echo "[INFO] $1"; }

pkg_installed() {
  pacman -Q "$1" >/dev/null 2>&1
}

ensure_pkg() {
  local pkg="$1"

  if pkg_installed "$pkg"; then
    ok "Pacote já estava instalado (ignorado): $pkg"
    return 0
  fi

  info "Instalando pacote: $pkg"
  if sudo pacman -S --needed --noconfirm "$pkg" >/dev/null 2>&1; then
    if pkg_installed "$pkg"; then
      ok "Pacote instalado com sucesso: $pkg"
      return 0
    fi
  fi

  warn "Falha ao instalar pacote: $pkg"
  return 1
}

is_enabled() {
  systemctl is-enabled --quiet "$1" 2>/dev/null
}

is_active() {
  systemctl is-active --quiet "$1" 2>/dev/null
}

is_enabled_user() {
  systemctl --user is-enabled --quiet "$1" 2>/dev/null
}

is_active_user() {
  systemctl --user is-active --quiet "$1" 2>/dev/null
}

ensure_timer_enabled() {
  local timer="$1"

  if is_enabled "$timer"; then
    ok "Timer já estava habilitado (ignorado): $timer"
    return 0
  fi

  info "Habilitando timer: $timer"
  if sudo systemctl enable --now "$timer" >/dev/null 2>&1; then
    is_enabled "$timer" && ok "Timer habilitado: $timer" || warn "Timer não ficou habilitado: $timer"
  else
    warn "Falha ao habilitar timer: $timer"
  fi
}

ensure_service_enabled_active() {
  local svc="$1"
  local was_enabled="no"
  local was_active="no"

  is_enabled "$svc" && was_enabled="yes"
  is_active  "$svc" && was_active="yes"

  if [ "$was_enabled" = "yes" ] && [ "$was_active" = "yes" ]; then
    ok "Serviço já estava habilitado e ativo (ignorado): $svc"
    return 0
  fi

  info "Habilitando/iniciando serviço: $svc"
  sudo systemctl enable --now "$svc" >/dev/null 2>&1 || true

  if is_enabled "$svc" && is_active "$svc"; then
    ok "Serviço foi habilitado e iniciado: $svc"
  else
    # mensagens mais específicas
    if ! is_enabled "$svc"; then
      warn "Serviço não ficou habilitado: $svc"
    fi
    if ! is_active "$svc"; then
      warn "Serviço não ficou ativo: $svc"
    fi
  fi
}

ensure_user_service_enabled_active() {
  local svc="$1"
  local was_enabled="no"
  local was_active="no"

  is_enabled_user "$svc" && was_enabled="yes"
  is_active_user  "$svc" && was_active="yes"

  if [ "$was_enabled" = "yes" ] && [ "$was_active" = "yes" ]; then
    ok "Serviço (user) já estava habilitado e ativo (ignorado): $svc"
    return 0
  fi

  info "Habilitando/iniciando serviço (user): $svc"
  systemctl --user enable --now "$svc" >/dev/null 2>&1 || true

  if is_enabled_user "$svc" && is_active_user "$svc"; then
    ok "Serviço (user) foi habilitado e iniciado: $svc"
  else
    if ! is_enabled_user "$svc"; then
      warn "Serviço (user) não ficou habilitado: $svc"
    fi
    if ! is_active_user "$svc"; then
      warn "Serviço (user) não ficou ativo: $svc"
    fi
  fi
}

echo
echo "---------------------"
echo "Pos-config: configuracoes e servicos"
echo "---------------------"
echo

# Requer sudo (mas nao precisa rodar como root)
if ! sudo -n true 2>/dev/null; then
  echo "Vai pedir sua senha do sudo..."
fi

############################################################
# 1) Bash prompt customizado (PS1)
############################################################
echo
echo "---------------------"
echo "Configurando PS1 no ~/.bashrc..."

USER_BASHRC="$HOME/.bashrc"
touch "$USER_BASHRC"

# Comenta PS1 padrao (somente se a linha comecar exatamente com PS1=)
sed -i 's|^PS1=|#PS1=|' "$USER_BASHRC" || true

if grep -q 'Custom bash prompt via kirsle.net/wizards/ps1.html' "$USER_BASHRC"; then
  ok "PS1 custom já existia em ~/.bashrc (ignorado)"
else
  cat << 'EOF' >> "$USER_BASHRC"

# Custom bash prompt via kirsle.net/wizards/ps1.html
export PS1="\[$(tput bold)\]\[$(tput setaf 2)\][\u@\h \W]\\$ \[$(tput sgr0)\]"
EOF
  ok "PS1 custom adicionado em ~/.bashrc"
fi

############################################################
# 2) Serviços (com validação + instalação de pacotes)
############################################################
echo
echo "---------------------"
echo "Validando pacotes e habilitando servicos..."

# fstrim.timer (timer)
ensure_timer_enabled "fstrim.timer"

# power-profiles-daemon (pacote + serviço)
ensure_pkg "power-profiles-daemon"
ensure_service_enabled_active "power-profiles-daemon"

# gamemoded (user service) - depende do pacote gamemode
ensure_pkg "gamemode"
ensure_user_service_enabled_active "gamemoded"

############################################################
# Resumo final
############################################################
echo
echo "---------------------"
echo "RESUMO FINAL"
echo "---------------------"
echo "OK:       $OK_COUNT"
echo "ATENÇÃO:  $WARN_COUNT"

if [ "$WARN_COUNT" -eq 0 ]; then
  echo "Status: Tudo validado com sucesso."
else
  echo "Status: Existem pendencias. Revise as mensagens de ATENÇÃO acima."
fi

echo
echo "Concluido. Abra um novo terminal (ou faça logout/login) para aplicar o PS1."
