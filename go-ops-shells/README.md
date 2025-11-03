### Coverage Map

**A) Core pack 30 (go-ops-shells/scripts/)**

- Kubernetes: `CrashLoopBackOff` auto-recovery, pod drain/uncordon, `readinessProbe`/`livenessProbe` 기반 재시작 가드
- Linux/FS: log rotation 압력 완화, disk space 급증 감지, inode 고갈 대응
- Networking: `conntrack` 과포화 스냅샷, `iptables` quick fix 가이드
- App/Runtime: `systemd` 서비스 health-check 및 auto-restart, `pprof`/heap dump 스냅샷
- Datastore: MySQL/PostgreSQL connection saturation triage, Redis eviction/latency guard .
- Queue/Stream: Kafka consumer lag drain, DLQ rate-limit drain
- Security/Access: 급한 `WAF`/IP blocklist 갱신 절차의 문서형 가드
- FinOps/Observability: 기본 `textfile exporter` 연동 전제 스텁 제공

**B) Conference-grade pack 30 (go-ops-shells/scripts-conf/)**

- **AWS/EKS/Network**: Route53 health-check flap guard, ENI/IP exhaustion 점검, EKS CNI recycle, ASG drain stabilizer, WAF blocklist hotfix, RDS failover status detector, EBS gp2→gp3 전환 검토, Kinesis hot-shard 힌트, Lambda reserved concurrency shedding 포함
- **Multi-Cloud Patterns**: GCP Cloud SQL promote flow sanity-check, GKE control-plane/API backoff 습관화, Azure VMSS unhealthy repair, DNS Resolver failover, Cloudflare/Akamai edge traffic shift 문서형 가이드
- **Release & App Stability**: Canary auto-rollback guard, feature-flag freeze, circuit breaker trip/clear, config rollout rollback guard, cache warm-up, index rebuild throttle, `pprof` hot-path snapshot 포함
- **Ops / Security / FinOps**: AWS Cost Explorer 기반 cost anomaly guardrail, GuardDuty findings snapshot, OpenSearch cluster red 힌트, ClickHouse replication lag 대응, Kafka controller re-election 주의 플로우, etcd quorum 체크, S3 regional latency probe, Redis slot migration guard, Postgres bloat 후보 점검, kernel TCP tuning snapshot

---

### Safety & Ops Hygiene

- `DRY_RUN=1` 로 변경 없이 end-to-end 절차 검증 가능
- `ASSUME_YES=1` 로 비대화형 실행 지원
- 파괴적 변경은 **document-first** 또는 `confirm`/`doit` 가드로 이중 안전장치 제공

---

### How to Try

```bash
# 공용 런타임 존재 확인함
test -f go-ops-shells/lib/common.sh && echo "runtime OK"

# 개수 확인함
find go-ops-shells/scripts      -maxdepth 1 -type f -name '*.sh' | wc -l
find go-ops-shells/scripts-conf -maxdepth 1 -type f -name '*.sh' | wc -l

# DRY_RUN 모드로 안전 실행 예시함
DRY_RUN=1 bash go-ops-shells/scripts/k8s_crashloop_auto_recover.sh
ASSUME_YES=1 DRY_RUN=1 bash go-ops-shells/scripts-conf/aws_lambda_concurrency_shedder.sh
```

---

### Rollback

신규 파일 추가 중심 변경이므로 디렉터리 단위 revert 로 clean rollback 가능함.

---

### Notes

- 일부 스크립트는 `aws`, `gcloud`, `az`, `kubectl`, `jq`, `redis-cli`, `psql` 등 공급사 CLI 및 권한 전제를 가짐. 환경에 따라 **noop** 또는 **문서형 가이드**로 동작함.
- 실제 변경 단계는 주석 및 `confirm` 으로 명확히 표기하여 on-call 중 fat-finger 리스크를 낮춤.

---

### Next

- 각 runbook 실행 결과를 `textfile exporter` 로 노출하여 success/failure/latency 를 Prometheus/Grafana 에서 시각화하도록 확장 예정임.
- Alertmanager/Grafana OnCall 연계로 one-click runbook 버튼화를 고려함.
- 고위험 액션에 대해 `break-glass` 모드와 `change window` 태깅을 추가하여 감사 추적성을 강화할 예정임.
