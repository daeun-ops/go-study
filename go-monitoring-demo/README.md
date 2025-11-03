## Title  
>  Observability stack v1 — Prometheus/OTel/Grafana/Helm (+ FinOps guardrails)
> Go 기반 **Observability demo**를 구성하여 **Prometheus Metrics**, **OpenTelemetry
> Traces**, **Grafana Dashboards**, **Helm/Kubernetes** 배포 연습까지 일련의 Pipeline을 구축하고
> 운영 관점에서 **/metrics**, **/healthz**, **OTLP trace export**, **FinOps cost estimator** 등을 확인하기 위해 해당 작업들을 진행했습니다. 

---

### Scope  
- **Exporter**: `prometheus/client_golang` 기반 `/metrics` 노출 구현 
- **Health**: `/healthz` Readiness/Startup 확인 End-point 제공
- **Tracing**: `OpenTelemetry SDK` + `OTLP/HTTP Exporter` 연동
- **Dashboards**: `Grafana` JSON dashboards 및 `provisioning` Dir 제공.  
- **Alerting**: FinOps 초과 비용 감지 rule 샘플과 `Alertmanager` 연계를 위해 Template 포함.  
- **Deploy**: `docker-compose` 로 로컬 실행, `Helm Chart` 골격 및 `Kubernetes manifest` 샘플 포함.

---

### What’s inside  
- `cmd/` + `pkg/` 분리 구조로 모듈성 확보.  
- `pkg/exporter.go`, `pkg/healthz.go`, `pkg/trace.go`, `pkg/cost_estimator.go` 등 핵심 컴포넌트 포함함.  
- `grafana/provisioning/` 에 Datasource/Dashboard 자동 로딩 구조 포함.  
- `prometheus/` 스크랩 설정과 `textfile exporter` 확장 여지 포함.

---

### How to run (local)
```bash
# deps
go mod tidy

# run
go run ./cmd/main.go

# check
curl -sf localhost:8080/healthz | xargs echo "healthz="; curl -sf localhost:8080/metrics | head

# compose (optional)
docker compose up -d --build
```

---

### Validation  
- Latency/Throughput 지표가 `/metrics` 로 노출되는지 확인.  
- Trace가 OTLP로 Collector에 전송되는지 확인.  
- Dashboard가 자동 provisioning 되는지 확인.  
- `DRY_RUN` 모드의 FinOps guardrail 로직이 정상 동작하는지 확인.

---

### Risk & Mitigation  
- OTel/Prometheus 라이브러리 버전 상이로 인한 build 이슈 가능함 → `go.mod` 에 version pinning 
- Docker/Helm 환경 차이로 startup 순서 이슈 발생 가능함 → `readinessProbe/startupProbe` 조정 가이드 

---

### Next  
- `textfile exporter` 로 run 결과(success/failure/latency) 노출해 Runbook SLO 시각화 진행 예정임.  
- `Grafana OnCall / Alertmanager` 연계해 one-click triage 버튼화 고려함.




--------
<img width="979" height="170" alt="image" src="https://github.com/user-attachments/assets/6407f362-96b6-4389-9e37-539fe4cb628c" />



<img width="792" height="199" alt="image" src="https://github.com/user-attachments/assets/07f945fb-6f60-42f7-84bc-4690b0a1c854" />


<img width="1027" height="508" alt="image" src="https://github.com/user-attachments/assets/be40bc63-1425-4366-aa5f-e96cf5500ca0" />


<img width="1029" height="494" alt="image" src="https://github.com/user-attachments/assets/40801f6d-8e88-478c-80fe-bb8a98abd34f" />


<img width="1046" height="367" alt="image" src="https://github.com/user-attachments/assets/a06423aa-4064-4b91-a712-f92610ab313d" />


<img width="1024" height="840" alt="image" src="https://github.com/user-attachments/assets/d1b88d66-ef94-447d-8c6d-a664ca719ae7" />


<img width="938" height="189" alt="image" src="https://github.com/user-attachments/assets/3d4df648-b8bf-4b2e-8b88-108e06fc731a" />



<img width="970" height="131" alt="image" src="https://github.com/user-attachments/assets/1c990672-d2f0-4e76-b87e-1adbac459ae4" />


<img width="1019" height="571" alt="image" src="https://github.com/user-attachments/assets/8636981f-7752-4364-b1b8-9d9a0436d02b" />


<img width="539" height="436" alt="image" src="https://github.com/user-attachments/assets/12c6e0c9-6457-4b3a-aa90-e3f8b0f9b9c4" />


<img width="324" height="466" alt="image" src="https://github.com/user-attachments/assets/2f858f56-ec5f-4e13-8369-dc0b798637ad" />


<img width="948" height="265" alt="image" src="https://github.com/user-attachments/assets/fe3f695f-e603-4f3f-8899-5a8b0613442c" />





