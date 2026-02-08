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

ensure_timer_enabled_active() {
  local timer="$1"

  if is_enabled "$timer" && is_active "$timer"; then
    ok "Timer já estava habilitado e ativo (ignorado): $timer"
    return 0
  fi

  info "Habilitando/iniciando timer: $timer"
  if sudo systemctl enable --now "$timer" >/dev/null 2>&1; then
    if is_enabled "$timer" && is_active "$timer"; then
      ok "Timer foi habilitado e ficou ativo: $timer"
    else
      if ! is_enabled "$timer"; then
        warn "Timer não ficou habilitado: $timer"
      fi
      if ! is_active "$timer"; then
        warn "Timer não ficou ativo: $timer"
      fi
    fi
  else
    warn "Falha ao habilitar/iniciar timer: $timer"
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

# systemd-timesyncd (NTP) - valida /etc/systemd/timesyncd.conf e habilita o serviço
TIMESYNCD_CONF="/etc/systemd/timesyncd.conf"
NTP_LINE="NTP=a.st1.ntp.br b.st1.ntp.br c.st1.ntp.br d.st1.ntp.br"
FALLBACK_LINE="FallbackNTP=a.ntp.br b.ntp.br c.ntp.br"

if [[ ! -f "$TIMESYNCD_CONF" ]]; then
  info "Arquivo $TIMESYNCD_CONF nao existe. Criando..."
  sudo install -Dm644 /dev/null "$TIMESYNCD_CONF" >/dev/null 2>&1 || true
fi

# Se faltar [Time] ou as linhas NTP/FallbackNTP corretas, aplica o conteudo padrao
if ! grep -qxF "[Time]" "$TIMESYNCD_CONF" \
  || ! grep -qxF "$NTP_LINE" "$TIMESYNCD_CONF" \
  || ! grep -qxF "$FALLBACK_LINE" "$TIMESYNCD_CONF"; then

  info "Aplicando configuracao padrao do systemd-timesyncd..."
  sudo bash -c "printf '%s\n' \
'[Time]' \
'$NTP_LINE' \
'$FALLBACK_LINE' \
> '$TIMESYNCD_CONF'" >/dev/null 2>&1 || true
  ok "timesyncd.conf configurado: $TIMESYNCD_CONF"
else
  ok "timesyncd.conf ja estava configurado corretamente (ignorado): $TIMESYNCD_CONF"
fi

ensure_service_enabled_active "systemd-timesyncd"

# power-profiles-daemon (pacote + serviço)
ensure_pkg "power-profiles-daemon"
ensure_service_enabled_active "power-profiles-daemon"

# gamemoded (user service) - depende do pacote gamemode
ensure_pkg "gamemode"
ensure_user_service_enabled_active "gamemoded"

# paccache.timer (pacman cache) - depende do pacote pacman-contrib
ensure_pkg "pacman-contrib"

if systemctl list-unit-files --no-pager --no-legend 2>/dev/null | awk '{print $1}' | grep -qx "paccache.timer"; then
  ensure_timer_enabled_active "paccache.timer"
else
  warn "paccache.timer nao encontrado (pacman-contrib pode estar incompleto ou sua distro nao fornece esse timer)"
fi

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
