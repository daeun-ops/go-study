#!/usr/bin/env bash
# app log parser anomaly
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


require jq
FILE="${FILE:-/var/log/app.json.log}"
[ -r "$FILE" ] || { log ERROR "no log file: $FILE"; exit 1; }
CNT=$(jq -c "select(.level==\"error\")" "$FILE" | wc -l | awk "{print \$1}")
log INFO "error lines: $CNT"
[[ "$CNT" -gt ${THRESHOLD:-50} ]] && log WARN "anomaly detected" || log INFO "within threshold"

