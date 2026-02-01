#!/usr/bin/env bash
# shader-booster-amd.sh
# Shader Booster para AMD (RADV + Mesa shader cache 12G)
# Cenário: Arch Linux + KDE (Wayland ou X11)
# Método limpo: systemd environment.d

set -euo pipefail

CONF_DIR="${HOME}/.config/environment.d"
CONF_FILE="${CONF_DIR}/99-shader-booster.conf"

echo "Criando diretório: ${CONF_DIR}"
mkdir -p "${CONF_DIR}"

echo "Gravando configuração: ${CONF_FILE}"
cat > "${CONF_FILE}" <<'EOF'
# LinuxToys Shader Booster (AMD)
# Força RADV (Mesa) e aumenta o shader cache para reduzir stutter em jogos
AMD_VULKAN_ICD=RADV
MESA_SHADER_CACHE_MAX_SIZE=12G
EOF

echo
echo "OK. Configuração aplicada."
echo "Faça logout/login (ou reboot) para a sessão gráfica herdar as variáveis."

# --------------------------------------------------------------------
# VALIDAR
# --------------------------------------------------------------------
# echo $AMD_VULKAN_ICD
# echo $MESA_SHADER_CACHE_MAX_SIZE
#
# SAIDA
#
# RADV
# 12G
# -------------------------------------------------------------------
# DESINSTALAÇÃO (manual)
# -------------------------------------------------------------------
# Para remover o Shader Booster:
#   rm -f ~/.config/environment.d/99-shader-booster.conf
#
# Depois:
#   logout/login (ou reboot)
#
# Para validar que foi removido:
#   echo $AMD_VULKAN_ICD
#   echo $MESA_SHADER_CACHE_MAX_SIZE
# (as variáveis não devem mais retornar valor)
