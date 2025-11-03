#!/usr/bin/env bash
# app api rate limit protection
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


CONF="/etc/nginx/conf.d/ratelimit.conf"
if [[ -w "$CONF" || $(id -u) -eq 0 ]]; then
  log WARN "apply nginx rate limit (burst=20, rate=100r/s)"
  sudo tee "$CONF" >/dev/null <<EOF
limit_req_zone \$binary_remote_addr zone=api:10m rate=100r/s;
server { location /api/ { limit_req zone=api burst=20 nodelay; proxy_pass http://api_upstream; } }
EOF
  sudo nginx -t && sudo systemctl reload nginx
else
  log ERROR "need sudo to write $CONF"
fi

