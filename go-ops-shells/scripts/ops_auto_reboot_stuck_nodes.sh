#!/usr/bin/env bash
# ops auto reboot stuck nodes
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


THRESH="${THRESH:-15.0}"
L=$(loadavg1)
log INFO "loadavg1=$L"
awk -v l="$L" -v t="$THRESH" "BEGIN{exit (l>t)?0:1}" && { log WARN "auto reboot"; sudo shutdown -r +1 "auto reboot due to high load"; } || log INFO "within limit"

