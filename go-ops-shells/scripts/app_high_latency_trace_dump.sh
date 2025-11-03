#!/usr/bin/env bash
# app high latency trace dump
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


ENDPOINT="${ENDPOINT:-http://localhost:8080/metrics}"
P95=$(curl -fsS "$ENDPOINT" | awk -F[ {}]+ "/http_request_duration_seconds_bucket.*le=\"0.500\"/{sum+=\$NF} END{print sum+0}" 2>/dev/null || echo 0)
if [[ "${P95:-0}" -eq 0 ]]; then log INFO "metric not found"; exit 0; fi
if [[ "$P95" -gt 0 ]]; then
  log WARN "p95>500ms? capture pprof if running"
  curl -fsS http://localhost:6060/debug/pprof/goroutine?debug=2 -o "/tmp/pprof.$(date +%s).txt" 2>/dev/null || true
fi

