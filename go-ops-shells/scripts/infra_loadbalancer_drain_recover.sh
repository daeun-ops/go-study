#!/usr/bin/env bash
# infra loadbalancer drain recover
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


require aws
TG_ARN="${TG_ARN:?target group arn}"; TARGET="${TARGET:?ip:port}"
log WARN "deregister $TARGET"
aws elbv2 deregister-targets --target-group-arn "$TG_ARN" --targets Id="$TARGET"
sleep 10
log INFO "register $TARGET"
aws elbv2 register-targets --target-group-arn "$TG_ARN" --targets Id="$TARGET"

