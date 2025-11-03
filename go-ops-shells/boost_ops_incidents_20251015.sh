#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$ROOT/scripts"
LIB="$ROOT/lib"
mkdir -p "$SCRIPTS" "$LIB"

# ========== 공용 런타임 ==========
cat > "$LIB/common.sh" <<'SH'
#!/usr/bin/env bash
set -Eeuo pipefail

: "${LOG_DIR:=/var/log/ops-scripts}"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_FILE:-$LOG_DIR/$(basename "$0").log}"

log() { printf '[%s] [%s] %s\n' "$(date '+%F %T')" "${1:-INFO}" "${2:-}" | tee -a "$LOG_FILE"; }
require() { command -v "$1" >/dev/null 2>&1 || { log ERROR "missing command: $1"; exit 127; }; }
retry() {
  local max=${1:-5} delay=${2:-1}; shift 2
  local n=0
  until "$@"; do
    n=$((n+1)); (( n>=max )) && { log ERROR "retry failed: $*"; return 1; }
    log WARN "retry $n/$max: $*"; sleep $(( delay * n ))
  done
}
with_lock() {
  local name="$1"; shift
  exec 200>"/tmp/${name}.lock"
  flock -n 200 || { log WARN "lock busy: $name"; return 0; }
  "$@"
}

k() { require kubectl; kubectl ${NAMESPACE:+-n "$NAMESPACE"} "$@"; }
json() { jq -r "$@" 2>/dev/null || true; }

pct() { awk "BEGIN{printf \"%.2f\", ($1/$2)*100}"; }
mem_swap_pct() { awk '/^SwapTotal:/{t=$2}/^SwapFree:/{f=$2}END{if(t>0) printf "%.0f", 100-((f/t)*100); else print 0}' /proc/meminfo; }
loadavg1() { awk '{print $1}' /proc/loadavg; }
disk_inodes_low() { df -iP | awk 'NR>1 && $5+0>90{print $6":"$5}'; }
SH
chmod +x "$LIB/common.sh"

# ========== 유틸: 스크립트 작성기 ==========
make_script() {
  local name="$1"; shift
  local body="$*"
  local path="$SCRIPTS/${name}.sh"
  cat > "$path" <<SH
#!/usr/bin/env bash
# $(echo "$name" | tr '_' ' ')
# Auto-generated: 2025-10-15
set -Eeuo pipefail
LIB_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/../lib" && pwd)"
# shellcheck source=/dev/null
source "\$LIB_DIR/common.sh"

$body
SH
  chmod +x "$path"
  echo " [+] ${name}.sh"
}

echo "🚀 Generating professional SRE scripts into $SCRIPTS ..."

# ===== 퍼블릭 클라우드/인프라(10) =====
make_script infra_aws_api_throttle_recovery '
require aws
API="${API:-ec2 describe-instances}"
log INFO "call: aws $API"
retry 6 1 bash -c "aws $API >/dev/null 2>&1 || { rc=$?; grep -qi throttling <<<\"$(aws $API 2>&1 || true)\" && exit 1 || exit $rc; }"
log INFO "OK (no throttle or recovered)"
'

make_script infra_gcp_vm_restart '
require gcloud
PROJECT="${PROJECT:?set PROJECT}"; ZONE="${ZONE:?set ZONE}"; INST="${INST:?set INST}"
log WARN "reset gcp vm: $INST"
retry 4 2 gcloud compute instances reset "$INST" --project "$PROJECT" --zone "$ZONE"
'

make_script infra_k8s_node_not_ready '
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
'

make_script infra_dns_resolution_failure '
require sed; require grep
TARGET="${TARGET:-github.com}"
if getent hosts "$TARGET" >/dev/null 2>&1; then log INFO "DNS OK"; exit 0; fi
log WARN "DNS fail → fallback resolvers"
sudo cp /etc/resolv.conf /etc/resolv.conf.bak.$(date +%s) || true
printf "nameserver 1.1.1.1\nnameserver 8.8.8.8\n" | sudo tee /etc/resolv.conf >/dev/null
getent hosts "$TARGET" && log INFO "resolved via fallback" || { log ERROR "still failing"; exit 2; }
'

make_script infra_network_latency_detector '
TARGET="${TARGET:-8.8.8.8}"; LIMIT_MS="${LIMIT_MS:-300}"
AVG=$(ping -c3 -w5 "$TARGET" | awk -F/ "/^rtt/ {print \$5+0}")
[ -z "$AVG" ] && { log ERROR "ping failed"; exit 2; }
log INFO "rtt=$AVG ms (limit=$LIMIT_MS)"
awk -v a="$AVG" -v l="$LIMIT_MS" "BEGIN{exit (a>l)?0:1}" && log WARN "High latency" || log INFO "OK"
'

make_script infra_loadbalancer_drain_recover '
require aws
TG_ARN="${TG_ARN:?target group arn}"; TARGET="${TARGET:?ip:port}"
log WARN "deregister $TARGET"
aws elbv2 deregister-targets --target-group-arn "$TG_ARN" --targets Id="$TARGET"
sleep 10
log INFO "register $TARGET"
aws elbv2 register-targets --target-group-arn "$TG_ARN" --targets Id="$TARGET"
'

make_script infra_efs_mount_recovery '
require mount; require umount
MP="${MP:?mountpoint}"
mountpoint -q "$MP" || { log WARN "not mounted → remount"; sudo mount -a; exit 0; }
log WARN "lazy unmount & remount: $MP"
sudo umount -l "$MP" || true
sleep 2
sudo mount -a
mountpoint -q "$MP" && log INFO "remounted" || { log ERROR "remount fail"; exit 2; }
'

make_script infra_cloudwatch_alarm_rearm '
require aws
ARN="${ARN:?alarm arn}"
log INFO "enable actions: $ARN"
aws cloudwatch enable-alarm-actions --alarm-names "$ARN"
'

make_script infra_disk_pressure_resolver '
log INFO "inode usage check"
LOW=$(disk_inodes_low || true)
[ -n "$LOW" ] && log WARN "high inode usage: $LOW"
log INFO "journal vacuum"
sudo journalctl --vacuum-size=200M --vacuum-time=7d || true
log INFO "cleanup tmp"
sudo find /var/tmp -type f -mtime +7 -delete 2>/dev/null || true
'

make_script infra_time_drift_corrector '
if command -v chronyc >/dev/null; then
  log INFO "chrony sources"; chronyc -n sources || true
  log INFO "chrony tracking"; chronyc tracking || true
elif command -v timedatectl >/dev/null; then
  log INFO "timedatectl status"; timedatectl status || true
fi
'

# ===== 애플리케이션(10) =====
make_script app_pod_crashloopbackoff_fix '
require kubectl
NAMESPACE="${NAMESPACE:-default}"
PODS=$(k get po -o json | jq -r ".items[] | select(.status.containerStatuses[]?.state.waiting.reason==\"CrashLoopBackOff\") | .metadata.name" 2>/dev/null || true)
[ -z "$PODS" ] && { log INFO "no CrashLoopBackOff"; exit 0; }
for p in $PODS; do
  log WARN "dump logs: $p"; k logs "$p" --all-containers --tail=500 >"/tmp/${p}.log" 2>&1 || true
  log WARN "delete pod: $p"; k delete pod "$p" --force --grace-period=0 || true
done
'

make_script app_db_connection_recovery '
require bash
CHECK="${CHECK:-bash -lc '\''true'\' '}"
log INFO "recycle DB connection pool via app hook (if available)"
${APP_HOOK:-true} || true
log INFO "run connectivity check"; eval "$CHECK" && log INFO "OK" || log WARN "check failed"
'

make_script app_high_latency_trace_dump '
ENDPOINT="${ENDPOINT:-http://localhost:8080/metrics}"
P95=$(curl -fsS "$ENDPOINT" | awk -F'[ {}]+' "/http_request_duration_seconds_bucket.*le=\"0.500\"/{sum+=\$NF} END{print sum+0}" 2>/dev/null || echo 0)
if [[ "${P95:-0}" -eq 0 ]]; then log INFO "metric not found"; exit 0; fi
if [[ "$P95" -gt 0 ]]; then
  log WARN "p95>500ms? capture pprof if running"
  curl -fsS http://localhost:6060/debug/pprof/goroutine?debug=2 -o "/tmp/pprof.$(date +%s).txt" 2>/dev/null || true
fi
'

make_script app_api_rate_limit_protection '
CONF="/etc/nginx/conf.d/ratelimit.conf"
if [[ -w "$CONF" || $(id -u) -eq 0 ]]; then
  log WARN "apply nginx rate limit (burst=20, rate=100r/s)"
  sudo tee "$CONF" >/dev/null <<EOF
limit_req_zone \$binary_remote_addr zone=api:10m rate=100r/s;
server { location /api/ { limit_req zone=api burst=20 nodelay; proxy_pass http://api_upstream; } }
EOF
  sudo nginx -t && sudo systemctl reload nginx
else
  log ERROR "need sudo to write $CONF"
fi
'

make_script app_service_healthcheck_restart '
URL="${URL:-http://localhost:8080/healthz}"
if curl -fsS "$URL" >/dev/null; then log INFO "healthy"; exit 0; fi
UNIT="${UNIT:-app.service}"
log WARN "restart systemd: $UNIT"
sudo systemctl restart "$UNIT" || true
sleep 2
sudo systemctl is-active --quiet "$UNIT" && log INFO "recovered" || { log ERROR "still unhealthy"; exit 2; }
'

make_script app_cache_stale_eviction '
require redis-cli
PATTERN="${PATTERN:-app:*}"
TTL_LIST=$(redis-cli --raw scan 0 match "$PATTERN" count 1000 | xargs -r -n1 -I{} redis-cli ttl "{}" 2>/dev/null || true)
[ -z "$TTL_LIST" ] && { log INFO "no keys"; exit 0; }
log INFO "evicting keys with TTL<0 (stale)"
redis-cli --raw scan 0 match "$PATTERN" count 1000 | while read -r k; do
  t=$(redis-cli ttl "$k"); [[ "$t" -lt 0 ]] && { redis-cli del "$k" >/dev/null; echo "del $k"; }
done
'

make_script app_jvm_memory_leak_killer '
PID=$(ps -eo pid,comm,%mem --sort=-%mem | awk "$2==\"java\" && $3+0>90 {print $1; exit}")
[ -z "$PID" ] && { log INFO "no heavy java"; exit 0; }
log WARN "kill -TERM $PID (RSS>90%)"; kill -TERM "$PID" || true
sleep 5
kill -0 "$PID" 2>/dev/null && { log WARN "force kill $PID"; kill -KILL "$PID" || true; } || log INFO "terminated"
'

make_script app_deadlock_detector '
if curl -fsS http://localhost:6060/debug/pprof/goroutine?debug=2 -o "/tmp/goroutine.$(date +%s).txt"; then
  log WARN "goroutine dump captured (inspect for deadlocks)"
else
  log INFO "pprof not enabled"
fi
'

make_script app_log_parser_anomaly '
require jq
FILE="${FILE:-/var/log/app.json.log}"
[ -r "$FILE" ] || { log ERROR "no log file: $FILE"; exit 1; }
CNT=$(jq -c "select(.level==\"error\")" "$FILE" | wc -l | awk "{print \$1}")
log INFO "error lines: $CNT"
[[ "$CNT" -gt ${THRESHOLD:-50} ]] && log WARN "anomaly detected" || log INFO "within threshold"
'

make_script app_message_queue_backpressure '
if command -v kafka-consumer-groups.sh >/dev/null; then
  KAFKA="${KAFKA:-localhost:9092}"; GROUP="${GROUP:?set GROUP}"
  log INFO "lag for $GROUP"
  kafka-consumer-groups.sh --bootstrap-server "$KAFKA" --describe --group "$GROUP" || true
else
  log INFO "kafka tooling not present; noop"
fi
'

# ===== 운영/FinOps/유지보수(10) =====
make_script ops_log_rotation_cleanup '
DIR="${DIR:-/var/log}"
MAX_MB="${MAX_MB:-200}"
find "$DIR" -type f -name "*.log" -size +"${MAX_MB}"M -print0 | while IFS= read -r -d "" f; do
  log WARN "rotate $f"
  mv "$f" "${f}.$(date +%F).1" && gzip -9 "${f}."*".1" 2>/dev/null || true
done
'

make_script ops_tmp_file_cleaner '
DIRS="${DIRS:-/tmp /var/tmp}"
for d in $DIRS; do
  log INFO "clean $d (>7d)"
  find "$d" -type f -mtime +7 -delete 2>/dev/null || true
done
'

make_script ops_memory_swap_alert '
P=$(mem_swap_pct)
log INFO "swap used=${P}%"
[[ "$P" -ge ${THRESHOLD:-70} ]] && { log WARN "swap high"; exit 2; } || exit 0
'

make_script ops_auto_reboot_stuck_nodes '
THRESH="${THRESH:-15.0}"
L=$(loadavg1)
log INFO "loadavg1=$L"
awk -v l="$L" -v t="$THRESH" "BEGIN{exit (l>t)?0:1}" && { log WARN "auto reboot"; sudo shutdown -r +1 "auto reboot due to high load"; } || log INFO "within limit"
'

make_script ops_alertmanager_silence_expiry '
AM="${AM:-http://localhost:9093}"
if curl -fsS "$AM/api/v2/silences" | jq -e ".[] | select(.status.state==\"expired\")" >/dev/null; then
  IDS=$(curl -fsS "$AM/api/v2/silences" | jq -r ".[] | select(.status.state==\"expired\") | .id")
  for id in $IDS; do
    log INFO "delete silence $id"; curl -fsS -X DELETE "$AM/api/v2/silence/$id" >/dev/null || true
  done
else
  log INFO "no expired silences"
fi
'

make_script ops_finops_cost_spike_guard '
BASE_FILE="${BASE_FILE:-/var/lib/ops/cost_baseline.json}"
CUR=${CUR_COST:-0}
mkdir -p "$(dirname "$BASE_FILE")"
BASE=$(jq -r ".yesterday // 0" "$BASE_FILE" 2>/dev/null || echo 0)
LIMIT=$(awk -v b="$BASE" "BEGIN{printf \"%.2f\", b*1.3}")
log INFO "base=$BASE cur=$CUR limit=$LIMIT"
awk -v c="$CUR" -v l="$LIMIT" "BEGIN{exit (c>l)?0:1}" && log WARN "spike detected" || log INFO "ok"
jq -n --argjson yesterday "$CUR" '{yesterday:$yesterday}' > "$BASE_FILE".new && mv "$BASE_FILE".new "$BASE_FILE"
'

make_script ops_backup_integrity_check '
FILE="${FILE:?set FILE}"
log INFO "verify tar: $FILE"
tar -tf "$FILE" >/dev/null && log INFO "ok" || { log ERROR "corrupt tar"; exit 2; }
'

make_script ops_slow_query_exporter '
SRC="${SRC:-/var/log/mysql/slow.log}"; OUT="${OUT:-/var/lib/node_exporter/textfile_collector/slow_queries.prom}"
mkdir -p "$(dirname "$OUT")"
CNT=$(grep -c "Query_time: " "$SRC" 2>/dev/null || echo 0)
{
  echo "# HELP slow_queries_total Slow SQLs"
  echo "# TYPE slow_queries_total counter"
  echo "slow_queries_total $CNT"
} > "$OUT"
log INFO "exported $CNT → $OUT"
'

make_script ops_systemd_restart_failed '
FAILED=$(systemctl --failed --no-legend | awk "{print \$1}")
[ -z "$FAILED" ] && { log INFO "no failed units"; exit 0; }
for u in $FAILED; do
  log WARN "restart $u"; sudo systemctl restart "$u" || true
done
'

make_script ops_zombie_process_cleaner '
Z=$(ps -eo pid,ppid,stat,comm | awk "$3 ~ /Z/{print \$1}")
[ -z "$Z" ] && { log INFO "no zombie"; exit 0; }
log WARN "zombies: $Z (kill parents)"
for p in $Z; do
  PP=$(ps -o ppid= -p "$p" | tr -d " ")
  [ -n "$PP" ] && { kill -TERM "$PP" 2>/dev/null || true; }
done
'

echo "✅ Done. Generated 30 scripts + lib/common.sh"
