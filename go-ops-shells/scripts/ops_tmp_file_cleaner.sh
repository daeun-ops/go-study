#!/usr/bin/env bash
# ops tmp file cleaner
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


DIRS="${DIRS:-/tmp /var/tmp}"
for d in $DIRS; do
  log INFO "clean $d (>7d)"
  find "$d" -type f -mtime +7 -delete 2>/dev/null || true
done

