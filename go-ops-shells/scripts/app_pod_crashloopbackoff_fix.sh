#!/usr/bin/env bash
# app pod crashloopbackoff fix
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


require kubectl
NAMESPACE="${NAMESPACE:-default}"
PODS=$(k get po -o json | jq -r ".items[] | select(.status.containerStatuses[]?.state.waiting.reason==\"CrashLoopBackOff\") | .metadata.name" 2>/dev/null || true)
[ -z "$PODS" ] && { log INFO "no CrashLoopBackOff"; exit 0; }
for p in $PODS; do
  log WARN "dump logs: $p"; k logs "$p" --all-containers --tail=500 >"/tmp/${p}.log" 2>&1 || true
  log WARN "delete pod: $p"; k delete pod "$p" --force --grace-period=0 || true
done

