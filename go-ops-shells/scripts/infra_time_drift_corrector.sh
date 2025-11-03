#!/usr/bin/env bash
# infra time drift corrector
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


if command -v chronyc >/dev/null; then
  log INFO "chrony sources"; chronyc -n sources || true
  log INFO "chrony tracking"; chronyc tracking || true
elif command -v timedatectl >/dev/null; then
  log INFO "timedatectl status"; timedatectl status || true
fi

