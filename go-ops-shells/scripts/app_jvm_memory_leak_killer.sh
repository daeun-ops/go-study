#!/usr/bin/env bash
# app jvm memory leak killer
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


PID=$(ps -eo pid,comm,%mem --sort=-%mem | awk "$2==\"java\" && $3+0>90 {print $1; exit}")
[ -z "$PID" ] && { log INFO "no heavy java"; exit 0; }
log WARN "kill -TERM $PID (RSS>90%)"; kill -TERM "$PID" || true
sleep 5
kill -0 "$PID" 2>/dev/null && { log WARN "force kill $PID"; kill -KILL "$PID" || true; } || log INFO "terminated"

