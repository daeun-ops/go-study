#!/usr/bin/env bash
# app service healthcheck restart
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


URL="${URL:-http://localhost:8080/healthz}"
if curl -fsS "$URL" >/dev/null; then log INFO "healthy"; exit 0; fi
UNIT="${UNIT:-app.service}"
log WARN "restart systemd: $UNIT"
sudo systemctl restart "$UNIT" || true
sleep 2
sudo systemctl is-active --quiet "$UNIT" && log INFO "recovered" || { log ERROR "still unhealthy"; exit 2; }

