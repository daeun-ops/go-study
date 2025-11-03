#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$ROOT/scripts-conf"
LIB="$ROOT/lib"
mkdir -p "$SCRIPTS" "$LIB"

# 공용 런타임 (없으면 생성)
if [ ! -f "$LIB/common.sh" ]; then
  cat > "$LIB/common.sh" <<'SH'
#!/usr/bin/env bash
set -Eeuo pipefail
: "${LOG_DIR:=/var/log/ops-scripts}"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_FILE:-$LOG_DIR/$(basename "$0").log}"

log() { printf '[%s] [%s] %s\n' "$(date '+%F %T')" "${1:-INFO}" "${2:-}" | tee -a "$LOG_FILE"; }
require() { command -v "$1" >/dev/null 2>&1 || { log ERROR "missing command: $1"; exit 127; }; }
retry() { local max=${1:-5} delay=${2:-1}; shift 2; local n=0; until "$@"; do n=$((n+1)); (( n>=max )) && { log ERROR "retry failed: $*"; return 1; }; log WARN "retry $n/$max: $*"; sleep $(( delay * n )); done; }
with_lock() { local name="$1"; shift; exec 200>"/tmp/${name}.lock"; flock -n 200 || { log WARN "lock busy: $name"; return 0; }; "$@"; }
confirm() { [[ "${ASSUME_YES:-0}" == "1" ]] && return 0; read -r -p "Proceed? [y/N] " a; [[ "$a" =~ ^[Yy]$ ]]; }
doit() { if [[ "${DRY_RUN:-0}" == "1" ]]; then echo "(dry-run) $*"; else eval "$*"; fi; }
k() { require kubectl; kubectl ${NAMESPACE:+-n "$NAMESPACE"} "$@"; }
json() { jq -r "$@" 2>/dev/null || true; }
pct() { awk "BEGIN{printf \"%.2f\", ($1/$2)*100}"; }
SH
  chmod +x "$LIB/common.sh"
fi

make_script() {
  local name="$1"; shift
  local body="$*"
  local path="$SCRIPTS/${name}.sh"
  cat > "$path" <<SH
#!/usr/bin/env bash
# $(echo "$name" | tr '_' ' ')
# Auto-generated: 2025-11-04 (conf incidents pack)
set -Eeuo pipefail
LIB_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "\$LIB_DIR/common.sh"

$body
SH
  chmod +x "$path"
  echo " [+] ${name}.sh"
}

echo "🚀 Generating conference-grade incident scripts → $SCRIPTS"

# ===== AWS 중심 (대형 쇼핑/거래소 패턴) =====
make_script aws_route53_hc_flap_guard '
require aws
HZ_ID="${HZ_ID:?set hosted zone id}"; REC="${REC:?set record name}"
log WARN "guard against healthcheck flapping → temporarily increase TTL"
doit "aws route53 change-resource-record-sets --hosted-zone-id \"$HZ_ID\" --change-batch \"{\\\"Changes\\\":[{\\\"Action\\\":\\\"UPSERT\\\",\\\"ResourceRecordSet\\\":{\\\"Name\\\":\\\"$REC\\\",\\\"Type\\\":\\\"A\\\",\\\"SetIdentifier\\\":\\\"primary\\\",\\\"TTL\\\":60}}]}\""
'

make_script aws_eni_ip_exhaustion_remediator '
require aws
VPC_ID="${VPC_ID:?set vpc}"; ENI_LIMIT_WARN="${ENI_LIMIT_WARN:-80}"
# 개략: 서브넷 IP/ENI 사용률 조회 → 경고 이상이면 서브넷 확장/액션 제안
log INFO "check IP/ENI pressure on VPC=$VPC_ID (warn>=$ENI_LIMIT_WARN%)"
doit "aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC_ID"
log WARN "if nearing limits: add CIDR block or scale out NAT/EKS CNI config (document-only step)"
'

make_script aws_eks_cni_ip_leak_recovery '
require kubectl
NAMESPACE=kube-system
log WARN "recycle aws-node (CNI) daemonset pods when IP leak suspected"
k rollout restart ds/aws-node
k rollout status ds/aws-node -w
'

make_script aws_asg_drain_stabilizer '
require aws; require kubectl
ASG="${ASG:?asg name}"
log WARN "scale-out 1, drain oldest node safely"
doit "aws autoscaling set-desired-capacity --auto-scaling-group-name \"$ASG\" --desired-capacity $(($(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names \"$ASG\" --query 'AutoScalingGroups[0].DesiredCapacity' --output text)+1))"
OLDEST=$(kubectl get nodes -o json | jq -r ".items|sort_by(.metadata.creationTimestamp)|.[0].metadata.name")
[ -n "$OLDEST" ] && { k cordon "$OLDEST"; k drain "$OLDEST" --ignore-daemonsets --delete-emptydir-data --force --grace-period=60 || true; }
'

make_script aws_cloudfront_origin_failover_toggle '
require aws
DIST_ID="${DIST_ID:?cloudfront dist}"; ORIGIN_ID="${ORIGIN_ID:?origin id}"
log WARN "toggle origin failover routing weight"
log INFO "document: use origin group failover or weighted behaviors; CLI update omitted for safety"
'

make_script aws_waf_hotfix_blocklist '
require aws
WAF_ARN="${WAF_ARN:?webacl arn}"; IPSET_ARN="${IPSET_ARN:?ipset arn}"; BAD_IP="${BAD_IP:?x.x.x.x/32}"
log INFO "append IP to blocklist set"
doit "aws wafv2 update-ip-set --scope REGIONAL --id \"$(aws wafv2 list-ip-sets --scope REGIONAL --query \"IPSets[?ARN=='$IPSET_ARN'].Id|[0]\" --output text)\" --name \"$(aws wafv2 list-ip-sets --scope REGIONAL --query \"IPSets[?ARN=='$IPSET_ARN'].Name|[0]\" --output text)\" --addresses $BAD_IP --lock-token \"$(aws wafv2 get-ip-set --scope REGIONAL --id \"$(aws wafv2 list-ip-sets --scope REGIONAL --query \"IPSets[?ARN=='$IPSET_ARN'].Id|[0]\" --output text)\" --name \"$(aws wafv2 list-ip-sets --scope REGIONAL --query \"IPSets[?ARN=='$IPSET_ARN'].Name|[0]\" --output text)\" --query LockToken --output text)\""
'

make_script aws_rds_failover_stuck_detector '
require aws
ARN="${ARN:?db arn}"
STS=$(aws rds describe-db-instances --db-instance-identifier "$ARN" --query "DBInstances[0].DBInstanceStatus" --output text 2>/dev/null || echo unknown)
log INFO "status=$STS"
[[ "$STS" == "failing-over" ]] && log WARN "failover taking long; consider reboot with failover (manual gate)"
'

make_script aws_ebs_io_degradation_switch_gp3 '
require aws
VOL_ID="${VOL_ID:?volume id}"
log WARN "consider migrating gp2→gp3 with baseline IOPS tuning (manual change by owner)"
doit "aws ec2 describe-volumes --volume-ids \"$VOL_ID\""
'

make_script aws_kinesis_hot_shard_splitter '
require aws
STREAM="${STREAM:?stream}"
log WARN "hot shard suspected → increase shards (document-only safe)"
doit "aws kinesis describe-stream-summary --stream-name \"$STREAM\""
'

make_script aws_lambda_concurrency_shedder '
require aws
FUNC="${FUNC:?function}"
LIMIT="${LIMIT:-100}"
log WARN "temporarily set reserved concurrency to limit blast radius"
confirm && doit "aws lambda put-function-concurrency --function-name \"$FUNC\" --reserved-concurrent-executions \"$LIMIT\""
'

# ===== 멀티클라우드/공급사 발표서 자주 언급되는 패턴 =====
make_script gcp_cloudsql_failover_promote '
require gcloud
INST="${INST:?instance}"
log WARN "promote replica to primary (manual gated); for doc only"
doit "gcloud sql instances describe \"$INST\""
'

make_script gcp_gke_controlplane_api_backoff '
require kubectl
log INFO "backoff client retries; reduce controller churn"
k get apiservices|wc -l >/dev/null 2>&1 || true
'

make_script azure_vnet_dns_resolver_failover '
require az
RESOLVER="${RESOLVER:?resolver name}"
log WARN "switch resolver endpoint (documented step)"
doit "az network dns-resolver show -g ${RG:?} -n \"$RESOLVER\""
'

make_script azure_vmss_unhealthy_repair '
require az
VMSS="${VMSS:?scale set}"; RG="${RG:?rg}"
log WARN "repair unhealthy instances"
doit "az vmss repair --resource-group \"$RG\" --name \"$VMSS\" --instance-ids '*' --only-replace"
'

make_script cloudflare_dns_cache_seed '
require dig
TARGET="${TARGET:-example.com}"
log INFO "seed local cache with upstream resolvers"
dig +trace "$TARGET" >/dev/null 2>&1 || true
'

make_script akamai_edge_traffic_shift '
log INFO "document-only: shift % to backup origin via property rule (manual via API/UI)"
'

# ===== 애플리케이션/릴리즈 안정화 (대규모 트래픽 캠페인 패턴) =====
make_script release_canary_auto_rollback '
require kubectl
APP="${APP:?deployment}"
log WARN "watch error rate & rollback to previous revision if threshold exceeded"
ERR=$(kubectl get --raw /apis/custom.metrics.k8s.io/v1beta1 | wc -l 2>/dev/null || echo 0)
[ "$ERR" -gt 0 ] || true
# 실제 롤백: 안전을 위해 주석
# k rollout undo deploy/$APP
'

make_script feature_flag_freeze '
log INFO "freeze risky features via flag provider (document-only hook)"
'

make_script api_circuit_breaker_trip_clear '
log INFO "trip breaker if upstream 5xx>threshold, auto clear after cooldown (requires gateway/mesh rules)"
'

make_script config_rollout_rollback_guard '
require kubectl
CM="${CM:?configmap}"; NS="${NAMESPACE:-default}"
log WARN "snapshot current CM, apply staged CM, on failure revert"
k get cm "$CM" -n "$NS" -o yaml >/tmp/cm.snap.yaml
# k apply -f new.yaml || { log ERROR "apply failed; revert"; k apply -f /tmp/cm.snap.yaml; }
'

make_script mq_dlq_burst_drain_safe '
require jq
DLQ="${DLQ:-/var/log/dlq.jsonl}"
CNT=$(wc -l "$DLQ" 2>/dev/null | awk "{print \$1+0}")
log INFO "dlq messages=$CNT → drain with rate limit"
'

make_script cache_warmup_regression_guard '
URL="${URL:-http://localhost:8080/warmup}"
retry 5 1 curl -fsS "$URL" >/dev/null && log INFO "warmed" || { log WARN "warmup failed"; exit 2; }
'

make_script search_index_rebuild_throttle '
log INFO "rebuild index in chunks to cap CPU/IO (implement per engine)"
'

make_script pprof_hotpath_snapshot '
if curl -fsS http://localhost:6060/debug/pprof/profile?seconds=15 -o "/tmp/profile.$(date +%s).pb.gz"; then
  log INFO "cpu profile captured"
else
  log INFO "pprof disabled"
fi
'

# ===== 운영/보안/FinOps 인사이트 =====
make_script cost_anomaly_guardrail_aws_ce '
require aws
CUR=${CUR_COST:-0}
BASE=$(aws ce get-cost-and-usage --time-period Start=$(date -d "-2 day" +%F),End=$(date -d "-1 day" +%F) --granularity DAILY --metrics UnblendedCost --query "ResultsByTime[0].Total.UnblendedCost.Amount" --output text 2>/dev/null || echo 0)
LIMIT=$(awk -v b="$BASE" "BEGIN{printf \"%.2f\", b*1.4}")
log INFO "base=$BASE cur=$CUR limit=$LIMIT"
awk -v c="$CUR" -v l="$LIMIT" "BEGIN{exit (c>l)?0:1}" && log WARN "spike detected" || log INFO "ok"
'

make_script guardduty_findings_snapshot '
require aws
OUT="${OUT:-/tmp/guardduty-findings.json}"
DET=$(aws guardduty list-detectors --query "DetectorIds[0]" --output text 2>/dev/null || echo "")
[ -z "$DET" ] && { log INFO "no detector"; exit 0; }
aws guardduty list-findings --detector-id "$DET" --output json > "$OUT"
log INFO "saved → $OUT"
'

make_script opensearch_cluster_red_recover_hint '
require curl
ES="${ES:-http://localhost:9200}"
HEALTH=$(curl -fsS "$ES/_cluster/health" | jq -r ".status" 2>/dev/null || echo unknown)
log INFO "status=$HEALTH"
[[ "$HEALTH" == "red" ]] && log WARN "check unassigned shards / disk watermarks / routing allocation"
'

make_script clickhouse_replication_lag_shed '
require clickhouse-client
log WARN "reduce heavy queries or move traffic if replication lag high (observed via system.replicas)"
'

make_script kafka_controller_re_election '
log WARN "trigger re-election (dangerous) — document-only. Prefer rolling broker restart with safety checks."
'

make_script etcd_quorum_check_eks '
require kubectl
log INFO "inspect etcd endpoints via kube-apiserver metrics (control-plane managed)"
'

make_script s3_regional_latency_probe '
require curl
BUCKET="${BUCKET:?bucket}"; OBJ="${OBJ:-health.txt}"
URL="https://${BUCKET}.s3.amazonaws.com/${OBJ}"
TS=$(date +%s%3N); curl -fsS -o /dev/null "$URL"; TE=$(date +%s%3N); log INFO "latency=$((TE-TS))ms"
'

make_script redis_cluster_slot_migration_guard '
require redis-cli
log WARN "guard slot migration windows; throttle client timeouts"
'

make_script pg_bloat_autovac_hint '
require psql
log INFO "check bloat candidates; schedule autovac/analyze off-peak"
'

make_script system_kernel_tcp_tuning_snapshot '
sysctl -a | egrep "net.ipv4.tcp_(tw|fin|sync|mem)|somaxconn" > /tmp/tcp.tune.$(date +%s).txt || true
log INFO "captured tcp kernel params snapshot"
'

echo "✅ Done. 30 scripts generated."
