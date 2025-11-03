#!/usr/bin/env bash
# infra efs mount recovery
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


require mount; require umount
MP="${MP:?mountpoint}"
mountpoint -q "$MP" || { log WARN "not mounted → remount"; sudo mount -a; exit 0; }
log WARN "lazy unmount & remount: $MP"
sudo umount -l "$MP" || true
sleep 2
sudo mount -a
mountpoint -q "$MP" && log INFO "remounted" || { log ERROR "remount fail"; exit 2; }

