#!/usr/bin/env bash
# app deadlock detector
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


if curl -fsS http://localhost:6060/debug/pprof/goroutine?debug=2 -o "/tmp/goroutine.$(date +%s).txt"; then
  log WARN "goroutine dump captured (inspect for deadlocks)"
else
  log INFO "pprof not enabled"
fi

