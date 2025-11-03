#!/usr/bin/env bash
# aws asg drain stabilizer
# Auto-generated: 2025-11-04 (conf incidents pack)
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


require aws; require kubectl
ASG="${ASG:?asg name}"
log WARN "scale-out 1, drain oldest node safely"
doit "aws autoscaling set-desired-capacity --auto-scaling-group-name \"$ASG\" --desired-capacity $(($(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names \"$ASG\" --query AutoScalingGroups[0].DesiredCapacity --output text)+1))"
OLDEST=$(kubectl get nodes -o json | jq -r ".items|sort_by(.metadata.creationTimestamp)|.[0].metadata.name")
[ -n "$OLDEST" ] && { k cordon "$OLDEST"; k drain "$OLDEST" --ignore-daemonsets --delete-emptydir-data --force --grace-period=60 || true; }

