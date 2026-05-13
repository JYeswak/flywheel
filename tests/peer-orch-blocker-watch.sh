#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/peer-orch-blocker-watch.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/peer-orch-blocker-watch-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

chmod +x "$SCRIPT"
bash -n "$SCRIPT" && pass "script syntax" || fail "script syntax"

stale="$TMP/stale.jsonl"
cat >"$stale" <<'JSONL'
{"ts":"2026-05-04T00:00:00Z","event":"peer_blocker_reported","sender":"{proof-product}:1","blocker_type":"flywheel_class","blocker_class":"canonical_doctrine_drift_local","requested_owner":"flywheel:1","proposed_action":"sync canonical doctrine"}
JSONL
"$SCRIPT" --ledger "$stale" --now 2026-05-04T00:06:00Z --json >"$TMP/stale.out"
assert_jq "$TMP/stale.out" '.status == "fail" and .stale_blockers_count == 1 and .peer_orch_blocker_age_seconds == 360' "stale flywheel blocker trips"
assert_jq "$TMP/stale.out" '.stale_blockers[0].blocker_type == "flywheel_class"' "blocker type surfaced"

acked="$TMP/acked.jsonl"
cat >"$acked" <<'JSONL'
{"ts":"2026-05-04T00:00:00Z","event":"peer_blocker_reported","sender":"{capability-control-plane}:1","blocker_type":"flywheel_class","blocker_class":"missing doctor signal","requested_owner":"flywheel:1"}
{"ts":"2026-05-04T00:01:00Z","event":"xpane_response","from":"flywheel:1","to":"{capability-control-plane}:1","reason":"ack and working"}
JSONL
"$SCRIPT" --ledger "$acked" --now 2026-05-04T00:06:00Z --json >"$TMP/acked.out"
assert_jq "$TMP/acked.out" '.status == "pass" and .stale_blockers_count == 0 and .blockers[0].acked == true' "flywheel ack clears stale blocker"

inferred="$TMP/inferred.jsonl"
cat >"$inferred" <<'JSONL'
{"ts":"2026-05-04T00:00:00Z","event":"mobile_eats_blocker_received","sender":"{proof-product}:1","doctor_error":"canonical_doctrine_drift_local","proposed_action":"restore canonical doctrine snapshot"}
JSONL
"$SCRIPT" --ledger "$inferred" --now 2026-05-04T00:06:00Z --json >"$TMP/inferred.out"
assert_jq "$TMP/inferred.out" '.status == "fail" and .blockers[0].blocker_type == "flywheel_class"' "legacy row infers flywheel_class"

malformed="$TMP/malformed.jsonl"
cat >"$malformed" <<'JSONL'
not json
{"ts":"2026-05-04T00:00:00Z","event":"peer_blocker_reported","sender":"{proof-product}:1","blocker_type":"peer_class"}
JSONL
"$SCRIPT" --ledger "$malformed" --now 2026-05-04T00:01:00Z --json >"$TMP/malformed.out"
assert_jq "$TMP/malformed.out" '.status == "warn" and .malformed_rows_count == 1' "malformed rows warn not crash"

schema="$TMP/schema.out"
"$SCRIPT" --schema >"$schema"
grep -q 'peer_orch_blocker_age_seconds' "$schema" && pass "schema exposes doctor field" || fail "schema exposes doctor field"

doctor_json="$TMP/doctor.json"
FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 \
FLYWHEEL_CROSS_ORCH_COORDINATION_LEDGER="$stale" \
FLYWHEEL_PEER_ORCH_BLOCKER_THRESHOLD_SECONDS=300 \
FLYWHEEL_PEER_ORCH_BLOCKER_NOW=2026-05-04T00:06:00Z \
FLYWHEEL_STORAGE_PROBE_FIXTURE=/dev/null \
"$HOME/.claude/skills/.flywheel/bin/flywheel-loop" doctor --repo "$ROOT" --json >"$doctor_json" 2>"$TMP/doctor.err" || true
assert_jq "$doctor_json" '.peer_orch_blocker_age_seconds == 360 and .peer_orch_idle_on_blocker_count == 1 and .peer_orch_blocker_watch.status == "fail"' "flywheel-loop doctor exposes L75 fields"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
