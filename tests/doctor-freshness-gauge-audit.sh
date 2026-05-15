#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/doctor-freshness-gauge-audit.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/doctor-freshness-audit.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    jq . "$file" >&2 || true
    fail "$label"
  fi
}

repo="$TMP/repo"
mkdir -p "$repo/.flywheel/reports" "$repo/.flywheel/scripts"
git -C "$TMP" init -q repo
git -C "$repo" config user.email "test@example.invalid"
git -C "$repo" config user.name "Test User"
printf '# test\n' >"$repo/README.md"
git -C "$repo" add README.md
git -C "$repo" commit -qm init
printf '# Daily\n' >"$repo/.flywheel/reports/daily-2026-05-15.md"

cat >"$TMP/josh.json" <<'JSON'
{"action":"surfaced","queued_count":4,"unread":1,"consumed_with_evidence_count":3,"truncated_consumed_requests":false}
JSON

cat >"$TMP/mission.json" <<'JSON'
{"status":"degraded","mission_lock_status":"stale-warn","mission_lock_age_hours":200.0,"lock_hash_matches_body":false,"lock_hash_matches_lock_log":true,"warnings":["lock_hash_body_mismatch"]}
JSON

cat >"$TMP/canonical.json" <<'JSON'
{"status":"pass","canonical_root_drift_count":0,"root_target_count":2,"timed_out":false,"classification":null}
JSON

cat >"$TMP/daily.json" <<'JSON'
{"status":"warn","daily_report_age_hours":28.0,"latest_report":"/tmp/daily.md","work_since_latest_report_count":7}
JSON

FLYWHEEL_AUDIT_JOSH_REQUESTS_FIXTURE="$TMP/josh.json" \
  FLYWHEEL_AUDIT_MISSION_LOCK_FIXTURE="$TMP/mission.json" \
  FLYWHEEL_AUDIT_CANONICAL_ROOT_DRIFT_FIXTURE="$TMP/canonical.json" \
  FLYWHEEL_AUDIT_DAILY_REPORT_FIXTURE="$TMP/daily.json" \
  "$SCRIPT" --repo "$repo" --json >"$TMP/out.json"

assert_jq "$TMP/out.json" '.schema_version == "flywheel.doctor_freshness_gauge_audit.v1"' "schema"
assert_jq "$TMP/out.json" '.status == "pass"' "audit passes when all consumption models present"
assert_jq "$TMP/out.json" '.required_gauge_count == 4 and .audited_gauge_count == 4' "all gauges audited"
assert_jq "$TMP/out.json" '.gauges[] | select(.name == "josh_requests" and .model == "consumed_vs_queued" and .payload.consumed_with_evidence_count == 3)' "josh requests consumed-vs-queued"
assert_jq "$TMP/out.json" '.gauges[] | select(.name == "mission_lock_status" and .model == "age_plus_content_stability" and .payload.lock_hash_matches_body == false and .payload.lock_hash_matches_lock_log == true)' "mission lock content stability"
assert_jq "$TMP/out.json" '.gauges[] | select(.name == "daily_report_age_hours" and .model == "age_plus_work_since_report" and .payload.work_since_latest_report_count == 7)' "daily report work since latest report"
assert_jq "$TMP/out.json" '.gauges[] | select(.name == "canonical_doctrine_propagation" and .model == "propagation_plus_root_drift" and .payload.canonical_root_drift_count == 0)' "canonical root drift truth"
assert_jq "$TMP/out.json" '.truth_status_counts.warn == 3 and .truth_status_counts.pass == 1' "truth counts preserve real red/yellow state"

cat >"$TMP/josh-missing.json" <<'JSON'
{"action":"surfaced","unread":4}
JSON

if FLYWHEEL_AUDIT_JOSH_REQUESTS_FIXTURE="$TMP/josh-missing.json" \
  FLYWHEEL_AUDIT_MISSION_LOCK_FIXTURE="$TMP/mission.json" \
  FLYWHEEL_AUDIT_CANONICAL_ROOT_DRIFT_FIXTURE="$TMP/canonical.json" \
  FLYWHEEL_AUDIT_DAILY_REPORT_FIXTURE="$TMP/daily.json" \
  "$SCRIPT" --repo "$repo" --json >"$TMP/fail.json"; then
  fail "missing consumed field fails audit"
else
  assert_jq "$TMP/fail.json" '.status == "fail" and (.audit_failure_codes | index("CONSUMED_WITH_EVIDENCE_MISSING"))' "missing consumed field fails audit"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
