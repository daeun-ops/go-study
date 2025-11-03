#!/usr/bin/env bash
# infra disk pressure resolver
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


log INFO "inode usage check"
LOW=$(disk_inodes_low || true)
[ -n "$LOW" ] && log WARN "high inode usage: $LOW"
log INFO "journal vacuum"
sudo journalctl --vacuum-size=200M --vacuum-time=7d || true
log INFO "cleanup tmp"
sudo find /var/tmp -type f -mtime +7 -delete 2>/dev/null || true

