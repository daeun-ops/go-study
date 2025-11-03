#!/usr/bin/env bash
# aws route53 hc flap guard
# Auto-generated: 2025-11-04 (conf incidents pack)
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


require aws
HZ_ID="${HZ_ID:?set hosted zone id}"; REC="${REC:?set record name}"
log WARN "guard against healthcheck flapping → temporarily increase TTL"
doit "aws route53 change-resource-record-sets --hosted-zone-id \"$HZ_ID\" --change-batch \"{\\\"Changes\\\":[{\\\"Action\\\":\\\"UPSERT\\\",\\\"ResourceRecordSet\\\":{\\\"Name\\\":\\\"$REC\\\",\\\"Type\\\":\\\"A\\\",\\\"SetIdentifier\\\":\\\"primary\\\",\\\"TTL\\\":60}}]}\""

