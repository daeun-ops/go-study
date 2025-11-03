#!/usr/bin/env bash
# ops memory swap alert
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


P=$(mem_swap_pct)
log INFO "swap used=${P}%"
[[ "$P" -ge ${THRESHOLD:-70} ]] && { log WARN "swap high"; exit 2; } || exit 0

