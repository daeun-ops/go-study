#!/usr/bin/env bash
# ops log rotation cleanup
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


DIR="${DIR:-/var/log}"
MAX_MB="${MAX_MB:-200}"
find "$DIR" -type f -name "*.log" -size +"${MAX_MB}"M -print0 | while IFS= read -r -d "" f; do
  log WARN "rotate $f"
  mv "$f" "${f}.$(date +%F).1" && gzip -9 "${f}."*".1" 2>/dev/null || true
done

