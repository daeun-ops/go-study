#!/usr/bin/env bash
# aws eni ip exhaustion remediator
# Auto-generated: 2025-11-04 (conf incidents pack)
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


require aws
VPC_ID="${VPC_ID:?set vpc}"; ENI_LIMIT_WARN="${ENI_LIMIT_WARN:-80}"
# 개략: 서브넷 IP/ENI 사용률 조회 → 경고 이상이면 서브넷 확장/액션 제안
log INFO "check IP/ENI pressure on VPC=$VPC_ID (warn>=$ENI_LIMIT_WARN%)"
doit "aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC_ID"
log WARN "if nearing limits: add CIDR block or scale out NAT/EKS CNI config (document-only step)"

