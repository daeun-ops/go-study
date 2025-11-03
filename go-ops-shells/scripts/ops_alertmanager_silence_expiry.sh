#!/usr/bin/env bash
# ops alertmanager silence expiry
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


AM="${AM:-http://localhost:9093}"
if curl -fsS "$AM/api/v2/silences" | jq -e ".[] | select(.status.state==\"expired\")" >/dev/null; then
  IDS=$(curl -fsS "$AM/api/v2/silences" | jq -r ".[] | select(.status.state==\"expired\") | .id")
  for id in $IDS; do
    log INFO "delete silence $id"; curl -fsS -X DELETE "$AM/api/v2/silence/$id" >/dev/null || true
  done
else
  log INFO "no expired silences"
fi

