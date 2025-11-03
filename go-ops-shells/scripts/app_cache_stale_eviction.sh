#!/usr/bin/env bash
# app cache stale eviction
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


require redis-cli
PATTERN="${PATTERN:-app:*}"
TTL_LIST=$(redis-cli --raw scan 0 match "$PATTERN" count 1000 | xargs -r -n1 -I{} redis-cli ttl "{}" 2>/dev/null || true)
[ -z "$TTL_LIST" ] && { log INFO "no keys"; exit 0; }
log INFO "evicting keys with TTL<0 (stale)"
redis-cli --raw scan 0 match "$PATTERN" count 1000 | while read -r k; do
  t=$(redis-cli ttl "$k"); [[ "$t" -lt 0 ]] && { redis-cli del "$k" >/dev/null; echo "del $k"; }
done

