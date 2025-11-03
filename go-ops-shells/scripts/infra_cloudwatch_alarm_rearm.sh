#!/usr/bin/env bash
# infra cloudwatch alarm rearm
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


require aws
ARN="${ARN:?alarm arn}"
log INFO "enable actions: $ARN"
aws cloudwatch enable-alarm-actions --alarm-names "$ARN"

