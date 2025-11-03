#!/usr/bin/env bash
# infra network latency detector
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


TARGET="${TARGET:-8.8.8.8}"; LIMIT_MS="${LIMIT_MS:-300}"
AVG=$(ping -c3 -w5 "$TARGET" | awk -F/ "/^rtt/ {print \$5+0}")
[ -z "$AVG" ] && { log ERROR "ping failed"; exit 2; }
log INFO "rtt=$AVG ms (limit=$LIMIT_MS)"
awk -v a="$AVG" -v l="$LIMIT_MS" "BEGIN{exit (a>l)?0:1}" && log WARN "High latency" || log INFO "OK"

