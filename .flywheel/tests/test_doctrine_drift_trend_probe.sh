#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/doctrine-drift-trend-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/doctrine-drift-trend.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail() { printf 'FAIL %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    jq . "$file" >&2 || true
    fail "$label"
  fi
}

write_row() {
  local ledger="$1" ts="$2" count="$3"
  shift 3
  python3 - "$ledger" "$ts" "$count" "$@" <<'PY'
import json
import sys

ledger, ts, count, *repos = sys.argv[1:]
details = []
for repo in repos:
    details.append({
        "repo": f"/Users/josh/Developer/{repo}",
        "target": f"/Users/josh/Developer/{repo}/AGENTS.md",
        "status": "drifted",
        "missing_rules": ["L100", "L101"],
    })
with open(ledger, "a", encoding="utf-8") as handle:
    handle.write(json.dumps({"ts": ts, "mode": "check", "status": "drift_detected" if int(count) else "ok", "drifted_count": int(count), "root_details": details}, separators=(",", ":")) + "\n")
PY
}

run_probe() {
  local ledger="$1" out="$2"
  "$SCRIPT" --ledger "$ledger" --now "2026-05-06T13:00:00Z" --json >"$out"
}

bash -n "$SCRIPT" && pass "probe_syntax"
"$SCRIPT" --info >/dev/null && pass "info_passes"
"$SCRIPT" --help >/dev/null && pass "help_passes"
"$SCRIPT" --examples >/dev/null && pass "examples_passes"

ledger="$TMP/zero.jsonl"
write_row "$ledger" "2026-05-06T13:00:00Z" 0
run_probe "$ledger" "$TMP/zero.json"
assert_jq "$TMP/zero.json" '.status == "pass" and .current_drift_count == 0 and .alert == false' "zero_drift_passes"

ledger="$TMP/five.jsonl"
write_row "$ledger" "2026-05-06T13:00:00Z" 5 alpsinsurance cfs-expo comfyui cubcloud-aaas mobile-eats
run_probe "$ledger" "$TMP/five.json"
assert_jq "$TMP/five.json" '.status == "warn" and .current_drift_count == 5 and (.top_drifted_repos | length) == 5' "five_drifted_top_n"

ledger="$TMP/nineteen.jsonl"
write_row "$ledger" "2026-05-05T12:00:00Z" 19 alpsinsurance cfs-expo comfyui cubcloud-aaas mobile-eats
write_row "$ledger" "2026-05-06T13:00:00Z" 19 alpsinsurance alpsinsurance-seed-org-43451a8e-3256a440 cfs-expo comfyui cubcloud-aaas fleet-commander gpu-optimization josh-ops mobile-eats polymarket-pico-z skillos soundsoftheforest terratitle vrtx zeststream-infra zeststream-procurement zeststream-v2-fresh zesttube
run_probe "$ledger" "$TMP/nineteen.json"
assert_jq "$TMP/nineteen.json" '.current_drift_count == 19 and (.top_drifted_repos[0:5] | map(.repo) | index("/Users/josh/Developer/alpsinsurance")) != null' "nineteen_fixture_has_alps_top5"

ledger="$TMP/improve.jsonl"
write_row "$ledger" "2026-05-05T13:00:00Z" 19 alpsinsurance cfs-expo
write_row "$ledger" "2026-05-06T13:00:00Z" 14 alpsinsurance cfs-expo
run_probe "$ledger" "$TMP/improve.json"
assert_jq "$TMP/improve.json" '.previous_24h_drift_count == 19 and .current_drift_count == 14 and .drift_count_delta_24h == -5 and .alert == false' "improvement_delta_negative"

ledger="$TMP/worse.jsonl"
write_row "$ledger" "2026-05-05T13:00:00Z" 14 alpsinsurance cfs-expo
write_row "$ledger" "2026-05-06T13:00:00Z" 19 alpsinsurance cfs-expo comfyui cubcloud-aaas mobile-eats
run_probe "$ledger" "$TMP/worse.json"
assert_jq "$TMP/worse.json" '.previous_24h_drift_count == 14 and .current_drift_count == 19 and .drift_count_delta_24h == 5 and .alert == true' "worsening_delta_alerts"

ledger="$TMP/malformed.jsonl"
printf '{"ts":"2026-05-06T13:00:00Z","drifted_count":1}\nnot-json\n' >"$ledger"
set +e
"$SCRIPT" --ledger "$ledger" --json >"$TMP/malformed.json"
rc=$?
set -e
[[ "$rc" -eq 2 ]] || fail "malformed exits 2"
assert_jq "$TMP/malformed.json" '.classification == "malformed_ledger" and .status == "error"' "malformed_classification"

quiet_out="$("$SCRIPT" --ledger "$TMP/five.jsonl" --quiet)"
[[ -z "$quiet_out" ]] && pass "quiet_suppresses_output" || fail "quiet_suppresses_output"

printf 'PASS cases=6 assertions=%s failures=0\n' "$pass_count"
