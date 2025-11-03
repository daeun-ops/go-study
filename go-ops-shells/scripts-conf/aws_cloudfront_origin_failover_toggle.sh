#!/usr/bin/env bash
# aws cloudfront origin failover toggle
# Auto-generated: 2025-11-04 (conf incidents pack)
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


require aws
DIST_ID="${DIST_ID:?cloudfront dist}"; ORIGIN_ID="${ORIGIN_ID:?origin id}"
log WARN "toggle origin failover routing weight"
log INFO "document: use origin group failover or weighted behaviors; CLI update omitted for safety"

