#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 🚨 Grafana FinOps Alert Rule Setup
# Author: daeun-ops (Sophie Kim)
# Description:
#   Automatically creates Grafana alerting rule to notify
#   when FinOps cost ($/hr) exceeds threshold.
# ============================================================

ROOT="$HOME/java-ecommerce-msa/go-study/go-monitoring-demo"
ALERT_DIR="$ROOT/grafana/provisioning/alerting"
mkdir -p "$ALERT_DIR"

cat > "$ALERT_DIR/finops_alert.yaml" <<'EOF'
apiVersion: 1

groups:
  - orgId: 1
    name: FinOps_Alerts
    folder: FinOps
    interval: 30s
    rules:
      - uid: finops_cost_threshold
        title: "⚠️ FinOps Cost Exceeded Threshold"
        condition: C
        data:
          - refId: A
            datasourceUid: prometheus
            model:
              expr: rate(process_cpu_seconds_total[1m]) * 0.05
              interval: ""
              legendFormat: "FinOps Cost ($/hr)"
              refId: A
          - refId: B
            datasourceUid: "__expr__"
            model:
              conditions:
                - evaluator:
                    params: [0.05]
                    type: gt
                  operator:
                    type: and
                  query:
                    params: ["A"]
                  reducer:
                    type: avg
                  type: query
        no_data_state: OK
        exec_err_state: Alerting
        for: 2m
        annotations:
          summary: "FinOps cost exceeded $0.05/hr threshold!"
          description: "Current cost has gone above the defined limit."
        labels:
          severity: "critical"
EOF

echo "✅ Alert rule written to $ALERT_DIR/finops_alert.yaml"
echo ""
echo "📡 Next Steps:"
echo "  1️⃣ Restart Grafana → docker restart grafana"
echo "  2️⃣ In Grafana UI → Alerting → Alert rules → Verify 'FinOps Cost Exceeded Threshold'"
echo ""
echo "💬 Slack/Telegram integration:"
echo "   - In Grafana → Alerting → Contact points → Add new"
echo "   - Choose Slack (Webhook URL) or Telegram (Bot Token + Chat ID)"
echo "   - Assign it to the 'FinOps_Alerts' rule."
echo ""
echo "🎯 Tip: You can adjust threshold in finops_alert.yaml → params: [0.05]"

