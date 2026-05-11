#!/usr/bin/env bash
# tests/promotion-candidate-stale-fire-reaper-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/promotion-candidate-stale-fire-reaper.sh
# (filled-in by bead flywheel-5ke66.16 — wave-2-general-16).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/promotion-candidate-stale-fire-reaper.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi
"$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version and .command == "info"' >/dev/null && pass "--info emits canonical envelope" || fail "--info envelope"
"$SCRIPT" --schema 2>/dev/null | jq -e '.schema_version and .command == "schema"' >/dev/null && pass "--schema emits canonical envelope" || fail "--schema envelope"
"$SCRIPT" --examples --json 2>/dev/null | jq -e '.command == "examples"' >/dev/null && pass "--examples emits canonical envelope" || fail "--examples envelope"
"$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor"' >/dev/null && pass "doctor emits canonical envelope" || fail "doctor envelope"
"$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null && pass "health emits canonical envelope" || fail "health envelope"
"$SCRIPT" repair --scope none --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run"' >/dev/null && pass "repair --dry-run emits canonical envelope" || fail "repair --dry-run envelope"
"$SCRIPT" repair --scope none --apply --json >/dev/null 2>&1; rc=$?
if [[ "$rc" -eq 3 ]]; then pass "repair --apply without --idempotency-key returns rc=3"; else fail "repair --apply rc=$rc (expected 3)"; fi
"$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate"' >/dev/null && pass "validate emits canonical envelope" || fail "validate envelope"
"$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit"' >/dev/null && pass "audit emits canonical envelope" || fail "audit envelope"
"$SCRIPT" why some-id 2>/dev/null | jq -e '.command == "why"' >/dev/null && pass "why <id> emits canonical envelope" || fail "why envelope"
"$SCRIPT" help repair 2>/dev/null | grep -q 'topic:' && pass "help repair returns topic header" || fail "help topic"
"$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null && pass "quickstart emits canonical envelope" || fail "quickstart envelope"

# ===== fillin-specific (flywheel-5ke66.16) =====

if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version | test("^promotion-candidate-stale-fire-reaper/v[0-9]+$")' >/dev/null; then
  pass "--info schema_version matches promotion-candidate-stale-fire-reaper/v1 pattern"
else fail "--info schema_version pattern"; fi

if "$SCRIPT" --schema repair 2>/dev/null \
  | jq -e '.scopes | index("audit-log-rotate") and index("canonical-incidents-prime")' >/dev/null; then
  pass "--schema repair lists audit-log-rotate + canonical-incidents-prime"
else fail "--schema repair scopes"; fi

if "$SCRIPT" doctor --json 2>/dev/null \
  | jq -e '.checks | length >= 5 and (any(.name == "jq_on_path")) and (any(.name == "br_bin_executable")) and (any(.name == "canonical_incidents_present"))' >/dev/null; then
  pass "doctor: 5+ probes incl. jq + br + canonical_incidents"
else fail "doctor substrate probes"; fi

if "$SCRIPT" repair --scope canonical-incidents-prime --dry-run --json 2>/dev/null \
  | jq -e '.command == "repair" and .scope == "canonical-incidents-prime" and (.status != "todo") and has("canonical_incidents") and has("present") and has("line_count")' >/dev/null; then
  pass "repair --scope canonical-incidents-prime emits non-stub envelope"
else fail "repair scope-specific"; fi

if "$SCRIPT" validate --row-json='{"schema_version":"promotion-candidate-stale-fire-reaper.v1","ts":"2026-05-11T00:00:00Z","mode":"dry-run","candidates_count":3,"stale_closed_count":1,"real_kept_count":2}' 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "row" and .status == "pass" and (.valid == true)' >/dev/null; then
  pass "validate --row-json enforces reaper-row schema (6 required fields)"
else fail "validate row schema"; fi

if "$SCRIPT" validate --canonical-incidents 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "canonical-incidents" and has("canonical_incidents") and has("present") and has("line_count")' >/dev/null; then
  pass "validate --canonical-incidents probes INCIDENTS.md (surface-specific)"
else fail "validate canonical-incidents subject"; fi

if "$SCRIPT" validate --candidates 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "candidates" and has("br_status") and has("open_promotion_candidates")' >/dev/null; then
  pass "validate --candidates queries br for open candidates (surface-specific)"
else fail "validate candidates subject"; fi


if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
