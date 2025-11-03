#!/usr/bin/env bash
# infra k8s node not ready
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


require kubectl
NODES=$(k get nodes --no-headers | awk "$2!~/Ready/{print \$1}")
[ -z "$NODES" ] && { log INFO "all nodes Ready"; exit 0; }
for n in $NODES; do
  with_lock "nodefix-$n" bash -c "
    log WARN \"cordon+drain $n\"
    k cordon "$n"
    k drain "$n" --ignore-daemonsets --delete-emptydir-data --force --grace-period=60 || true
    log WARN \"delete node $n (let autoscaler recreate)\"
    k delete node "$n" || true
  "
done

