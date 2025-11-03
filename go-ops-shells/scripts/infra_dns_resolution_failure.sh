#!/usr/bin/env bash
# infra dns resolution failure
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


require sed; require grep
TARGET="${TARGET:-github.com}"
if getent hosts "$TARGET" >/dev/null 2>&1; then log INFO "DNS OK"; exit 0; fi
log WARN "DNS fail → fallback resolvers"
sudo cp /etc/resolv.conf /etc/resolv.conf.bak.$(date +%s) || true
printf "nameserver 1.1.1.1\nnameserver 8.8.8.8\n" | sudo tee /etc/resolv.conf >/dev/null
getent hosts "$TARGET" && log INFO "resolved via fallback" || { log ERROR "still failing"; exit 2; }

