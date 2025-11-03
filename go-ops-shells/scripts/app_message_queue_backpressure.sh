#!/usr/bin/env bash
# app message queue backpressure
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


if command -v kafka-consumer-groups.sh >/dev/null; then
  KAFKA="${KAFKA:-localhost:9092}"; GROUP="${GROUP:?set GROUP}"
  log INFO "lag for $GROUP"
  kafka-consumer-groups.sh --bootstrap-server "$KAFKA" --describe --group "$GROUP" || true
else
  log INFO "kafka tooling not present; noop"
fi

