#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/.flywheel/scripts/polish-preflight-quality-gate.sh"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/polish-preflight-receipt.schema.json"
PLAN="mission-lock-paradigm-extension-2026-05-06"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/polish-preflight-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0
CASES=0

ok() { PASS=$((PASS + 1)); CASES=$((CASES + 1)); }
not_ok() { echo "FAIL: $1" >&2; FAIL=$((FAIL + 1)); CASES=$((CASES + 1)); }
assert() { if "$@"; then ok; else not_ok "$*"; fi; }

assert test -x "$SCRIPT"
assert bash -n "$SCRIPT"
assert test -f "$SCHEMA"

bash "$SCRIPT" --info > "$TMP/info.txt"
assert grep -q "polish-preflight-quality-gate" "$TMP/info.txt"
bash "$SCRIPT" --info --json > "$TMP/info.json"
assert jq -e '.gate_version=="v1" and .gates==8' "$TMP/info.json" >/dev/null

start="$(python3 - <<'PY'
import time
print(time.time())
PY
)"
bash "$SCRIPT" --check --plan-slug "$PLAN" --json > "$TMP/pass.json"
end="$(python3 - <<'PY'
import time
print(time.time())
PY
)"
assert jq -e '.gate_status=="PASS" and (.gates_run|length)==8 and .composite_health_score>=7 and .all_audit_findings_closed==true' "$TMP/pass.json" >/dev/null
assert python3 - "$SCHEMA" "$TMP/pass.json" <<'PY'
import json, sys
from jsonschema import Draft202012Validator
schema = json.load(open(sys.argv[1]))
data = json.load(open(sys.argv[2]))
Draft202012Validator(schema).validate(data)
PY
assert python3 - "$start" "$end" <<'PY'
import sys
sys.exit(0 if float(sys.argv[2]) - float(sys.argv[1]) < 60 else 1)
PY

set +e
bash "$SCRIPT" --check --plan-slug "$PLAN" --json >/dev/null
rc_pass=$?
bash "$SCRIPT" --check --plan-slug missing-plan --json >/dev/null
rc_pending=$?
set -e
[[ "$rc_pass" -eq 0 ]] && ok || not_ok "pass exit code"
[[ "$rc_pending" -eq 2 ]] && ok || not_ok "pending exit code"

for gate in \
  mission_lock_output_schema \
  dispatch_author_contract \
  close_validator_contract \
  mission_lock_scaffold \
  mission_lock_readiness \
  dispatch_self_test_identity \
  golden_fixture_replay_all \
  golden_fixture_verify_invariants; do
  set +e
  POLISH_PREFLIGHT_FORCE_FAIL="$gate" bash "$SCRIPT" --check --plan-slug "$PLAN" --json > "$TMP/$gate.fail.json"
  rc=$?
  set -e
  if [[ "$rc" -eq 1 ]] && jq -e --arg gate "$gate" '.gate_status=="FAIL" and (.first_fire_reason|contains($gate))' "$TMP/$gate.fail.json" >/dev/null; then
    ok
  else
    not_ok "forced negative $gate"
  fi
done

LEDGER="$TMP/gate-ledger.jsonl"
IDEMP="$TMP/idempotency.jsonl"
LOCKS="$TMP/locks"
POLISH_PREFLIGHT_LEDGER="$LEDGER" POLISH_PREFLIGHT_IDEMPOTENCY_LEDGER="$IDEMP" POLISH_PREFLIGHT_LOCK_DIR="$LOCKS" \
  bash "$SCRIPT" --check --plan-slug "$PLAN" --apply --json > "$TMP/apply1.json"
POLISH_PREFLIGHT_LEDGER="$LEDGER" POLISH_PREFLIGHT_IDEMPOTENCY_LEDGER="$IDEMP" POLISH_PREFLIGHT_LOCK_DIR="$LOCKS" \
  bash "$SCRIPT" --check --plan-slug "$PLAN" --apply --json > "$TMP/apply2.json"
assert test "$(wc -l < "$LEDGER" | tr -d ' ')" = "1"
assert jq -e '.applied==true' "$TMP/apply1.json" >/dev/null
assert jq -e '.applied==false and .idempotency_status=="already_completed"' "$TMP/apply2.json" >/dev/null

if [[ "$FAIL" -ne 0 ]]; then
  echo "RESULT pass=$PASS fail=$FAIL test_cases=$CASES" >&2
  exit 1
fi
echo "RESULT pass=$PASS fail=0 test_cases=$CASES"
