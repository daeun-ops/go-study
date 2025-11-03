#!/usr/bin/env bash
# infra gcp vm restart
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"


require gcloud
PROJECT="${PROJECT:?set PROJECT}"; ZONE="${ZONE:?set ZONE}"; INST="${INST:?set INST}"
log WARN "reset gcp vm: $INST"
retry 4 2 gcloud compute instances reset "$INST" --project "$PROJECT" --zone "$ZONE"

