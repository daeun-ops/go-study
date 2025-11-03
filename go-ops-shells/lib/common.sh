#!/usr/bin/env bash
set -Eeuo pipefail

: "${LOG_DIR:=/var/log/ops-scripts}"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_FILE:-$LOG_DIR/$(basename "$0").log}"

log() { printf '[%s] [%s] %s\n' "$(date '+%F %T')" "${1:-INFO}" "${2:-}" | tee -a "$LOG_FILE"; }
require() { command -v "$1" >/dev/null 2>&1 || { log ERROR "missing command: $1"; exit 127; }; }
retry() {
  local max=${1:-5} delay=${2:-1}; shift 2
  local n=0
  until "$@"; do
    n=$((n+1)); (( n>=max )) && { log ERROR "retry failed: $*"; return 1; }
    log WARN "retry $n/$max: $*"; sleep $(( delay * n ))
  done
}
with_lock() {
  local name="$1"; shift
  exec 200>"/tmp/${name}.lock"
  flock -n 200 || { log WARN "lock busy: $name"; return 0; }
  "$@"
}

k() { require kubectl; kubectl ${NAMESPACE:+-n "$NAMESPACE"} "$@"; }
json() { jq -r "$@" 2>/dev/null || true; }

pct() { awk "BEGIN{printf \"%.2f\", ($1/$2)*100}"; }
mem_swap_pct() { awk '/^SwapTotal:/{t=$2}/^SwapFree:/{f=$2}END{if(t>0) printf "%.0f", 100-((f/t)*100); else print 0}' /proc/meminfo; }
loadavg1() { awk '{print $1}' /proc/loadavg; }
disk_inodes_low() { df -iP | awk 'NR>1 && $5+0>90{print $6":"$5}'; }
