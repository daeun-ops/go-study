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

## 대시보드 내용 요약

| 패널 | 설명 | 의미 |
| --- | --- | --- |
| 💸 **Cost Breakdown** | 서비스별 CPU 기반 비용 비율 | 어떤 모듈이 돈을 제일 많이 쓰는지 |
| 📈 **Monthly Cost Trend** | 30분 단위 CPU 누적 → 월간 환산 | 클라우드 요금 추세 예측 |
| ⚙️ **CPU vs Cost Correlation** | 실시간 CPU 사용률 vs 비용 | 효율/낭비 구간 시각화 |




## 지금 상태 정리

| 구성요소 | 상태 | 설명 |
| --- | --- | --- |
| **Go Exporter** | 🟢 정상 작동 | FinOps 로그 시뮬레이션 중 |
| **Prometheus** | 🟢 정상 작동 | Exporter(8080)를 스크랩 중 |
| **Grafana** | 🟢 정상 작동 | Admin UI `http://localhost:3000` 실행 중 |
| **메트릭 엔드포인트** | http://localhost:8080/metrics | Prometheus 포맷 데이터 확인 가능 |
