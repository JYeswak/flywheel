#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/recovery-slo-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/recovery-slo-probe.XXXXXX")"
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
    sed -n '1,160p' "$file" >&2 || true
  fi
}

bash -n "$SCRIPT" && pass "script syntax" || fail "script syntax"

now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
old="$(date -u -v-48H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '48 hours ago' +%Y-%m-%dT%H:%M:%SZ)"
ledger="$TMP/recovery-ledger.jsonl"
jq -nc --arg ts "$now" '{ts:$ts,event:"recovery",session:"flywheel",pane:2,total_recovery_latency_seconds:42}' >>"$ledger"
jq -nc --arg ts "$now" '{ts:$ts,event:"recovery",session:"flywheel",pane:3,detection_latency_seconds:60,recovery_latency_seconds:60}' >>"$ledger"
jq -nc --arg ts "$now" '{ts:$ts,event:"recovery",session:"flywheel",pane:4,total_recovery_latency_seconds:220}' >>"$ledger"
jq -nc --arg ts "$now" '{ts:$ts,event:"queued_submit_recovery",session:"flywheel",pane:4,total_recovery_latency_seconds:999}' >>"$ledger"
jq -nc --arg ts "$now" '{ts:$ts,event:"recovery",session:"flywheel",pane:5}' >>"$ledger"
jq -nc --arg ts "$old" '{ts:$ts,event:"recovery",session:"flywheel",pane:6,total_recovery_latency_seconds:999}' >>"$ledger"

"$SCRIPT" --ledger "$ledger" --json >"$TMP/probe.json"
assert_jq "$TMP/probe.json" '.recovery_latency_p50_seconds_24h == 120 and .recovery_latency_p95_seconds_24h == 220' "probe computes p50 and p95 from measured recoveries"
assert_jq "$TMP/probe.json" '.recovery_slo_breach_count_24h == 1 and .recovery_slo_status == "red"' "probe marks SLO breach red"
assert_jq "$TMP/probe.json" '.eligible_recovery_count_24h == 4 and .measured_recovery_count_24h == 3 and .unmeasured_recovery_count_24h == 1' "probe reports eligible/measured/unmeasured counts"

"$SCRIPT" --ledger "$TMP/missing.jsonl" --json >"$TMP/empty.json"
assert_jq "$TMP/empty.json" '.recovery_slo_status == "green" and .recovery_latency_p95_seconds_24h == 0 and .recovery_slo_breach_count_24h == 0' "missing ledger is empty green"

"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '(.doctor_fields | index("recovery_latency_p95_seconds_24h")) and (.canonical_flags | index("--schema"))' "info exposes doctor fields and canonical flags"
"$SCRIPT" --schema >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.required | index("recovery_slo_status") and index("recovery_slo_breach_count_24h")' "schema exposes SLO fields"
"$SCRIPT" --examples >/dev/null && pass "examples surface" || fail "examples surface"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
