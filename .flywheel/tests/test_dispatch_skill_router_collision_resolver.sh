#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/.flywheel/scripts/dispatch-skill-router-collision-resolver.sh"
pass=0

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

case_ok() {
  local name="$1"; shift
  "$@" >/tmp/dispatch-skill-router-test.out 2>/tmp/dispatch-skill-router-test.err || {
    cat /tmp/dispatch-skill-router-test.err >&2
    fail "$name"
  }
  pass=$((pass + 1))
}

json_case() {
  local name="$1"; shift
  local expr="$1"; shift
  "$SCRIPT" --json "$@" | jq -e "$expr" >/dev/null || fail "$name"
  pass=$((pass + 1))
}

case_ok "help verb" "$SCRIPT" --help
case_ok "info verb" "$SCRIPT" --info
case_ok "examples verb" "$SCRIPT" --examples
case_ok "quiet verb" "$SCRIPT" --quiet backend-endpoint

json_case "backend plus database collision" \
  '.route_status=="pass" and (.collisions|index("backend_plus_database")) and (.skills|index("api-design-patterns")) and (.skills|index("database-modeling")) and (.skills|index("authentication-authorization"))' \
  backend-endpoint database-migration

json_case "substrate security cli collision forbids secret evidence" \
  '.no_raw_secret_evidence==true and (.collisions|index("substrate_security_cli")) and (.skills|index("mcp-secret-scanner")) and (.skills|index("canonical-cli-scoping"))' \
  substrate-fix security cli

json_case "docs implementation collision requests skip receipts" \
  '(.collisions|index("docs_contract_plus_implementation")) and (.notes|index("explicit_skip_receipts_required")) and (.skills|index("readme-writing")) and (.skills|index("testing-golden-artifacts"))' \
  docs operator-contract implementation

json_case "missing exact fallback is degraded with follow-up" \
  '.route_status=="degraded" and .missing_skill_followup==true and (.collisions|index("missing_exact_skill_fallback")) and (.overlays|index("search-tool-routing-doctrine"))' \
  missing-skill schema-complete-drift-guard

json_case "cross cutting overlays are included" \
  '(.overlays|index("agent-mail")) and (.overlays|index("agent-monitoring")) and (.overlays|index("cost-attribution")) and (.overlays|index("search-tool-routing-doctrine")) and (.overlays|index("mcp-secret-scanner"))' \
  agent-mail observability cost secret-rotation search

json_case "negative fixture fails route health" \
  '.route_status=="fail" and .self_test_gate=="fail"' \
  irrelevant no-source blocked

printf 'OK dispatch_skill_router_collision_resolver cases=%s\n' "$pass"
