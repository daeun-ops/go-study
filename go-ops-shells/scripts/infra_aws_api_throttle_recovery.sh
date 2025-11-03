#!/usr/bin/env bash
# infra aws api throttle recovery
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


require aws
API="${API:-ec2 describe-instances}"
log INFO "call: aws $API"
retry 6 1 bash -c "aws $API >/dev/null 2>&1 || { rc=$?; grep -qi throttling <<<\"$(aws $API 2>&1 || true)\" && exit 1 || exit $rc; }"
log INFO "OK (no throttle or recovered)"

