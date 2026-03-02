#!/usr/bin/env bash
set -u

ok()   { printf '[OK]   %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
fail() { printf '[FAIL] %s\n' "$*"; }
info() { printf '       %s\n' "$*"; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { fail "Comando não encontrado: $1"; return 1; }
  ok "Comando presente: $1"
}

# --- 1) Kernel params / LSM ---
CMDLINE="$(cat /proc/cmdline 2>/dev/null || true)"
LSM_CUR="$(cat /sys/kernel/security/lsm 2>/dev/null || true)"

if [[ "$CMDLINE" == *"audit=1"* ]]; then ok "Kernel cmdline contém audit=1"; else fail "Kernel cmdline NÃO contém audit=1"; fi
if [[ "$CMDLINE" == *"lsm="* ]]; then ok "Kernel cmdline contém lsm=..."; else fail "Kernel cmdline NÃO contém lsm=..."; fi

if [[ "$LSM_CUR" == *"apparmor"* ]]; then
  ok "LSM ativo inclui AppArmor: $LSM_CUR"
else
  fail "AppArmor não aparece em /sys/kernel/security/lsm (atual: $LSM_CUR)"
fi

# --- 2) Pacotes / ferramentas ---
need_cmd aa-status
need_cmd aa-notify || warn "aa-notify não encontrado (no Arch normalmente vem no pacote apparmor)"

# auditctl é útil pra checar audit; nem sempre está no PATH dependendo do pacote
command -v auditctl >/dev/null 2>&1 && ok "Comando presente: auditctl" || warn "auditctl não encontrado (pode ser ok, depende do pacote audit)"

# --- 3) Serviços ---
svc_check() {
  local s="$1"
  if systemctl is-enabled "$s" >/dev/null 2>&1; then
    ok "Service $s: enabled"
  else
    fail "Service $s: NOT enabled"
  fi

  if systemctl is-active "$s" >/dev/null 2>&1; then
    ok "Service $s: active"
  else
    fail "Service $s: NOT active"
  fi
}

svc_check apparmor.service
svc_check auditd.service

# --- 4) auditd.conf log_group ---
AUDIT_CONF="/etc/audit/auditd.conf"
if [[ -f "$AUDIT_CONF" ]]; then
  ok "Arquivo existe: $AUDIT_CONF"
  if grep -Eq '^\s*log_group\s*=\s*audit\s*$' "$AUDIT_CONF"; then
    ok "auditd.conf: log_group = audit"
  else
    fail "auditd.conf: log_group NÃO está como audit (procure e ajuste)"
    info "Linha atual (se existir):"
    grep -En '^\s*log_group\s*=' "$AUDIT_CONF" 2>/dev/null | sed 's/^/       /' || true
  fi
else
  fail "Arquivo não existe: $AUDIT_CONF"
fi

# --- 5) Grupo audit / acesso ao log ---
USER_NAME="${SUDO_USER:-$USER}"

if getent group audit >/dev/null 2>&1; then
  ok "Grupo existe: audit"
else
  fail "Grupo NÃO existe: audit"
fi

if id -nG "$USER_NAME" | tr ' ' '\n' | grep -qx audit; then
  ok "Usuário '$USER_NAME' está no grupo audit"
else
  fail "Usuário '$USER_NAME' NÃO está no grupo audit (precisa relogar após gpasswd)"
fi

AUDIT_LOG="/var/log/audit/audit.log"
if [[ -f "$AUDIT_LOG" ]]; then
  ok "Log existe: $AUDIT_LOG"
else
  fail "Log NÃO existe: $AUDIT_LOG (auditd pode não ter gerado ainda)"
fi

# tenta ler como o usuário atual (não-root)
if sudo -u "$USER_NAME" bash -lc "test -r '$AUDIT_LOG'" >/dev/null 2>&1; then
  ok "Usuário '$USER_NAME' consegue ler $AUDIT_LOG"
else
  fail "Usuário '$USER_NAME' NÃO consegue ler $AUDIT_LOG (log_group/permissões/grupo)"
fi

# --- 6) Autostart aa-notify ---
DESKTOP_FILE="$HOME/.config/autostart/apparmor-notify.desktop"
if [[ -f "$DESKTOP_FILE" ]]; then
  ok "Autostart existe: $DESKTOP_FILE"
  if grep -Eq '^Exec=.*aa-notify' "$DESKTOP_FILE"; then
    ok "Autostart contém Exec com aa-notify"
  else
    fail "Autostart NÃO contém Exec com aa-notify"
  fi
else
  warn "Autostart NÃO encontrado: $DESKTOP_FILE (sem notificação automática)"
fi

# --- 7) bwrap profile (opcional) ---
BWRAP_PROFILE="/etc/apparmor.d/bwrap"
if [[ -f "$BWRAP_PROFILE" ]]; then
  ok "Profile bwrap existe: $BWRAP_PROFILE"
  if grep -Eq 'flags=\(unconfined\)' "$BWRAP_PROFILE"; then
    ok "bwrap está flags=(unconfined)"
  else
    warn "bwrap existe mas não parece unconfined (verifique conteúdo)"
  fi
else
  warn "Profile bwrap não existe (OK se você não aplicou o fix Flatpak/Proton)"
fi

# --- 8) Resumo do aa-status ---
echo
echo "== Resumo aa-status =="
if sudo aa-status >/dev/null 2>&1; then
  # Só extrai linhas-chave pra não poluir
  sudo aa-status 2>/dev/null | sed -n '1,25p'
else
  fail "aa-status falhou ao executar"
fi

echo
echo "Validação concluída."
echo "Se algo deu FAIL, corrija e depois rode novamente."
