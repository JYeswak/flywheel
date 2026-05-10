#!/usr/bin/env bash
# tests/b3h2p-daily-report-doctor-signal-resolved.sh
# Bead flywheel-b3h2p: regression for the doctor `daily_report` signal.
#
# At packet build time the doctor reported daily_report_age_hours=76.44
# (above the 36h fail threshold). At dispatch execution time the
# doctor returned daily_report_age_hours=12.15, status=pass — daily
# report had been regenerated externally between packet build and
# worker dispatch.
#
# This regression asserts the resolved-state invariant: doctor
# daily_report.status is pass AND daily_report_age_hours is below
# the 36h threshold. Fires when the daily-narrative cadence
# regresses again.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
FLYWHEEL_LOOP_BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
DAILY_REPORT_THRESHOLD_HOURS="${DAILY_REPORT_THRESHOLD_HOURS:-36}"
REPORTS_DIR="${REPORTS_DIR:-$ROOT/.flywheel/reports}"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: flywheel-loop binary available
if [[ -x "$FLYWHEEL_LOOP_BIN" ]]; then
  pass "flywheel-loop binary available at $FLYWHEEL_LOOP_BIN"
else
  fail "flywheel-loop missing at $FLYWHEEL_LOOP_BIN"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

# Capture doctor packet once (slow source — typically 60-90s)
DOCTOR_JSON="$(timeout 150 "$FLYWHEEL_LOOP_BIN" doctor --repo "$ROOT" --json 2>/dev/null || true)"
if [[ -z "$DOCTOR_JSON" ]]; then
  fail "doctor returned empty output"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

# Test 2: daily_report.status is pass (downgraded from packet-build fail)
if jq -e '.daily_report.status == "pass"' >/dev/null 2>&1 <<<"$DOCTOR_JSON"; then
  pass "doctor daily_report.status=pass (signal resolved; was fail at packet build)"
else
  fail "doctor daily_report.status not pass; got: $(jq -r '.daily_report.status // "null"' <<<"$DOCTOR_JSON")"
fi

# Test 3: daily_report_age_hours is below 36h fail threshold
AGE_HOURS="$(jq -r '.daily_report.daily_report_age_hours // 0' <<<"$DOCTOR_JSON")"
if awk -v age="$AGE_HOURS" -v threshold="$DAILY_REPORT_THRESHOLD_HOURS" \
  'BEGIN { exit !(age < threshold) }'; then
  pass "daily_report_age_hours=$AGE_HOURS < $DAILY_REPORT_THRESHOLD_HOURS h fail threshold"
else
  fail "daily_report_age_hours=$AGE_HOURS exceeds $DAILY_REPORT_THRESHOLD_HOURS h fail threshold"
fi

# Test 4: latest_report path exists on disk
LATEST_REPORT="$(jq -r '.daily_report.latest_report // ""' <<<"$DOCTOR_JSON")"
if [[ -n "$LATEST_REPORT" && -f "$LATEST_REPORT" ]]; then
  pass "doctor latest_report path exists on disk: $LATEST_REPORT"
else
  fail "latest_report path missing or unset; got: $LATEST_REPORT"
fi

# Test 5: latest report carries the canonical generated_at + repo + doctor_status preamble
if [[ -n "$LATEST_REPORT" && -f "$LATEST_REPORT" ]]; then
  if grep -qE '^# Flywheel Daily Report - 2026' "$LATEST_REPORT" \
    && grep -qE '^- generated_at: 2026' "$LATEST_REPORT" \
    && grep -q '^- repo:' "$LATEST_REPORT"; then
    pass "latest daily report has canonical preamble (header + generated_at + repo)"
  else
    fail "latest daily report missing canonical preamble"
  fi
else
  fail "skipping preamble check; latest_report absent"
fi

# Test 6: reports directory has at least 3 daily reports (cadence intact)
REPORT_COUNT="$(ls -1 "$REPORTS_DIR"/daily-*.md 2>/dev/null | wc -l | tr -d '[:space:]')"
if [[ "${REPORT_COUNT:-0}" -ge 3 ]]; then
  pass "reports directory has $REPORT_COUNT daily reports (cadence has run multiple times)"
else
  fail "reports directory has only ${REPORT_COUNT:-0} reports; cadence may be broken"
fi

# Test 7: doctor exposes a config_path field (regen mechanism is
# config-aware). The file itself is optional — the mechanism has
# internal defaults — but the doctor's config_path field shape is
# the canonical surface for future config landing.
CONFIG_PATH="$(jq -r '.daily_report.config_path // ""' <<<"$DOCTOR_JSON")"
if [[ -n "$CONFIG_PATH" ]] && [[ "$CONFIG_PATH" == */daily-report-config.json ]]; then
  pass "doctor exposes daily_report.config_path field (canonical config surface; file is optional override)"
else
  fail "daily_report.config_path field shape regressed; got: $CONFIG_PATH"
fi

# Test 8: daily-report.sh script is executable (regen surface intact)
DAILY_REPORT_SCRIPT="$ROOT/.flywheel/scripts/daily-report.sh"
if [[ -x "$DAILY_REPORT_SCRIPT" ]]; then
  pass "daily-report.sh regen surface intact at $DAILY_REPORT_SCRIPT"
else
  fail "daily-report.sh missing or non-executable"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
