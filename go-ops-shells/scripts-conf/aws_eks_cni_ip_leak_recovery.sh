#!/usr/bin/env bash
# aws eks cni ip leak recovery
# Auto-generated: 2025-11-04 (conf incidents pack)
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


require kubectl
NAMESPACE=kube-system
log WARN "recycle aws-node (CNI) daemonset pods when IP leak suspected"
k rollout restart ds/aws-node
k rollout status ds/aws-node -w

