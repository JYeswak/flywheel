#!/usr/bin/env bash
# test_peer_orch_drift_alert_emitted.sh — synthetic drift triggers alert-log entry
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/peer-orch-drift-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/peer-orch-drift-alert.XXXXXX")"
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

# ---- Build drifted session fixture ----
mkdir -p "$TMP/bad-session/.flywheel"
cat >"$TMP/bad-session/.flywheel/MISSION.md" <<'MD'
# bad-session Mission
status: locked
Build client-facing analytics pipeline and maintain SLA.
MD
# All task_summaries are garbage words — no mission keywords
cat >"$TMP/bad-session/.flywheel/dispatch-log.jsonl" <<'JSONL'
{"ts":"2026-05-06T07:00:00Z","task_id":"b1","task_summary":"xyzzy plugh frobnicate"}
{"ts":"2026-05-06T07:10:00Z","task_id":"b2","task_summary":"corge grault garply waldo"}
{"ts":"2026-05-06T07:20:00Z","task_id":"b3","task_summary":"thud fred barney qux"}
{"ts":"2026-05-06T07:30:00Z","task_id":"b4","task_summary":"quux florp zorp nozzle"}
{"ts":"2026-05-06T07:40:00Z","task_id":"b5","task_summary":"blorb plonk crinkle wibble"}
JSONL

ALERT_LOG="$TMP/alerts.jsonl"

# Run WITHOUT --dry-run so alert is written to disk
EXIT_CODE=0
"$SCRIPT" \
  --fixture-dir "$TMP" \
  --session bad-session \
  --alert-log "$ALERT_LOG" \
  --json >"$TMP/out.json" || EXIT_CODE=$?

# Should exit 2 (>=40% drift)
if [[ "$EXIT_CODE" -eq 2 ]]; then
  pass "exit_code=2 for fully-drifted session"
else
  fail "expected exit_code=2, got $EXIT_CODE"
fi

# Alert JSONL must exist and have at least one row
if [[ -f "$ALERT_LOG" ]]; then
  pass "alert log created"
else
  fail "alert log not created at $ALERT_LOG"
fi

ALERT_COUNT=$(wc -l <"$ALERT_LOG" | tr -d ' ')
if [[ "$ALERT_COUNT" -ge 1 ]]; then
  pass "alert log has >=1 entry"
else
  fail "alert log empty (count=$ALERT_COUNT)"
fi

# Parse first alert row
FIRST_ROW=$(head -1 "$ALERT_LOG")
echo "$FIRST_ROW" | jq -e '.session == "bad-session"' >/dev/null \
  && pass "alert row has correct session" || fail "alert row missing session"
echo "$FIRST_ROW" | jq -e '.drift_pct > 0' >/dev/null \
  && pass "alert row has drift_pct>0" || fail "alert row drift_pct missing"
echo "$FIRST_ROW" | jq -e '.message | test("ALIGNMENT WARNING")' >/dev/null \
  && pass "alert row message contains ALIGNMENT WARNING" || fail "alert row message wrong"
echo "$FIRST_ROW" | jq -e '.schema_version == "peer-orch-drift-probe/v1"' >/dev/null \
  && pass "alert row schema_version" || fail "alert row schema_version wrong"
echo "$FIRST_ROW" | jq -e '.dry_run == false' >/dev/null \
  && pass "alert row dry_run=false" || fail "alert row dry_run wrong"

# Probe output: alerts_emitted should be non-empty
jq -e '.alerts_emitted | length >= 1' "$TMP/out.json" >/dev/null \
  && pass "output alerts_emitted non-empty" || fail "output alerts_emitted empty"

# agent_mail_gap documented in output
jq -e '.agent_mail_gap | type == "string"' "$TMP/out.json" >/dev/null \
  && pass "agent_mail_gap documented in output" || fail "agent_mail_gap missing from output"

echo
echo "Summary: $pass_count pass, $fail_count fail"
[[ $fail_count -eq 0 ]] || exit 1
