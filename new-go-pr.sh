#!/usr/bin/env bash
set -euo pipefail

# --- 고정 값 (변수 문제 방지용)
OWNER="daeun-ops"
REPO="go-study"

AREA="${1:?usage: ./new-go-pr.sh <area> <name> ; areas=basic|advanced|k8s-agent|monitoring-demo|ops-scripts}"
NAME="${2:?name}"
BR="feat/${AREA}-${NAME}"

lookup_milestone() {
  local title="$1"
  gh api "repos/${OWNER}/${REPO}/milestones" | jq -r --arg t "$title" '.[] | select(.title==$t) | .number' | head -n1
}

case "$AREA" in
  basic)           DIR="go-basic/${NAME}";           MILE=$(lookup_milestone '2024-06~12 Basics/Advanced'); LABEL='area/basic' ;;
  advanced)        DIR="go-advanced/${NAME}";        MILE=$(lookup_milestone '2024-06~12 Basics/Advanced'); LABEL='area/advanced' ;;
  k8s-agent)       DIR="go-k8s-agent/${NAME}";       MILE=$(lookup_milestone '2025-01~02 K8s Agent & Monitoring'); LABEL='area/k8s-agent' ;;
  monitoring-demo) DIR="go-monitoring-demo/${NAME}"; MILE=$(lookup_milestone '2025-03~09 Observability Demo'); LABEL='area/monitoring-demo' ;;
  ops-scripts)     DIR="go-ops-shells/${NAME}";      MILE=$(lookup_milestone '2025-10~11 Ops Scripts'); LABEL='area/ops-scripts' ;;
  *) echo "unknown area"; exit 1 ;;
esac

echo "🚀 Creating branch: $BR"
git checkout -b "$BR"

mkdir -p "$DIR"
cat > "$DIR/README.md" <<EOF
# ${NAME^}
Part of ${AREA} module. Created automatically by new-go-pr.sh.
EOF

git add "$DIR"
git commit -m "feat(${AREA}): add ${NAME} module"
git push origin "$BR"

echo "📦 Creating Pull Request..."
gh pr create --fill --base main --head "$BR" \
  --label "$LABEL" \
  --milestone "$MILE" \
  --title "feat(${AREA}): add ${NAME} module" \
  --body "Auto-generated PR for ${AREA}/${NAME} via new-go-pr.sh"

echo "✅ Done. Branch '$BR' and PR created successfully."

