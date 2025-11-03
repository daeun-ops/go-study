#!/usr/bin/env bash
# app db connection recovery
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


require bash
CHECK="${CHECK:-bash -lc 'true' }"
log INFO "recycle DB connection pool via app hook (if available)"
${APP_HOOK:-true} || true
log INFO "run connectivity check"; eval "$CHECK" && log INFO "OK" || log WARN "check failed"

