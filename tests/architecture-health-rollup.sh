#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/architecture-health-rollup.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/architecture-health-rollup.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

mkdir -p "$TMP/repo/.flywheel/validation-receipts" "$TMP/repo/.flywheel/reports" "$TMP/repo/.beads"
mkdir -p "$TMP/identity" "$TMP/agent-mail/sessions" "$TMP/state" "$TMP/tokens"

cat >"$TMP/repo/.flywheel/dispatch-log.jsonl" <<'JSONL'
{"ts":"2026-05-04T19:00:00Z","session":"flywheel","pane":2,"task_id":"t1","task_summary":"doctrine L98 probe skill"}
{"ts":"2026-05-04T19:04:00Z","event":"callback_received","session":"flywheel","pane":2,"task_id":"t1","callback_status":"done","skills_consulted":"observability-platform"}
{"ts":"2026-05-04T19:10:00Z","session":"flywheel","pane":3,"task_id":"t2","task_summary":"threshold fixture test"}
{"ts":"2026-05-04T19:20:00Z","session":"{capability-control-plane}","pane":2,"task_id":"t3","task_summary":"coord cross-orch probe"}
JSONL

cat >"$TMP/repo/.flywheel/validation-receipts/t1.json" <<'JSON'
{"schema_version":"validation-receipt/v1","validated_at":"2026-05-04T19:05:00Z","task_id":"t1","verdict":"pass"}
JSON

cat >"$TMP/repo/.flywheel/validation-receipts/t2.json" <<'JSON'
{"schema_version":"validation-receipt/v1","validated_at":"2026-05-04T19:15:00Z","task_id":"t2","verdict":"fail"}
JSON

cat >"$TMP/repo/.beads/issues.jsonl" <<'JSONL'
{"id":"flywheel-a","status":"closed","closed_at":"2026-05-04T19:30:00Z","title":"probe addition"}
JSONL

cat >"$TMP/fuckups.jsonl" <<'JSONL'
{"ts":"2026-05-04T19:40:00Z","session":"flywheel","pane":2,"trauma_class":"fixture","severity":"medium"}
JSONL

cat >"$TMP/agent-mail/sessions/flywheel:2.json" <<JSON
{"session":"flywheel","pane":2,"identity_name":"CloudyMill","status":"active","fleet_mail_project_key":"$TMP/repo","token_path":"$TMP/tokens/CloudyMill.token"}
JSON
cat >"$TMP/agent-mail/sessions/flywheel:3.json" <<JSON
{"session":"flywheel","pane":3,"identity_name":"GoldenNorth","status":"active","fleet_mail_project_key":"$TMP/repo","token_path":"$TMP/tokens/GoldenNorth.token"}
JSON

cat >"$TMP/identity/flywheel.json" <<JSON
{"schema_version":"orch-worker-identity/v1","session":"flywheel","generated_at":"2026-05-04T19:00:00Z","orchestrator":{"pane":1},"workers":[
  {"pane":2,"fleet_mail_identity":"CloudyMill","registration_status":"active","registry_source":"$TMP/agent-mail/sessions/flywheel:2.json"},
  {"pane":3,"fleet_mail_identity":"GoldenNorth","registration_status":"active","registry_source":"$TMP/agent-mail/sessions/flywheel:3.json"}
],"validation":{"all_workers_registered":true,"unregistered_count":0}}
JSON

if bash -n "$SCRIPT"; then
  pass "script syntax"
else
  fail "script syntax"
fi
if "$SCRIPT" --info --json | jq -e '.name == "architecture-health-rollup" and .write_requires == "--write"' >/dev/null; then
  pass "info surface"
else
  fail "info surface"
fi
if "$SCRIPT" --schema --json | jq -e '.schema_version == "architecture-health-rollup/v1"' >/dev/null; then
  pass "schema surface"
else
  fail "schema surface"
fi
if "$SCRIPT" --examples --json | jq -e '.examples | length >= 3' >/dev/null; then
  pass "examples surface"
else
  fail "examples surface"
fi

"$SCRIPT" \
  --repo "$TMP/repo" \
  --period 24h \
  --now 2026-05-04T20:00:00Z \
  --identity-dir "$TMP/identity" \
  --fuckup-log "$TMP/fuckups.jsonl" \
  --json >"$TMP/out.json"

assert_jq "$TMP/out.json" '.schema_version == "architecture-health-rollup/v1" and .period == "24h"' "period output schema"
assert_jq "$TMP/out.json" '.source_counts.dispatches == 3 and .source_counts.callbacks == 1' "dispatch callback counts"
assert_jq "$TMP/out.json" '.architecture_health_metric_unpaired_count == 0 and .agent_shaming_report_detected == false' "anti-shaming metric contracts"
assert_jq "$TMP/out.json" '.identity_vectors | length == 2 and all(.[]; .agent_id | contains(":"))' "identity vectors use tuple ids"
assert_jq "$TMP/out.json" '.report_policy.individual_rankings_emitted == false' "no leaderboard emitted"
assert_jq "$TMP/out.json" '.fleet_metrics.rework_ratio > 0' "rework ratio computed"
assert_jq "$TMP/out.json" '.fleet_metrics.architecture_debt_observation_ratio > 0 and .source_counts.architecture_debt_observation_rows == 1' "architecture debt observation ratio computed"
assert_jq "$TMP/out.json" '.source_counts.rework_event_count == (.source_counts.validation_fail + .source_counts.redispatch_rows)' "rework excludes debt observations"

"$SCRIPT" \
  --repo "$TMP/repo" \
  --period all \
  --now 2026-05-04T20:00:00Z \
  --identity-dir "$TMP/identity" \
  --fuckup-log "$TMP/fuckups.jsonl" \
  --state-dir "$TMP/state" \
  --write \
  --json >"$TMP/all.json"

for period in 24h 7d 30d 90d; do
  if test -s "$TMP/state/$period.json"; then
    pass "wrote $period rollup"
  else
    fail "wrote $period rollup"
  fi
done

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
