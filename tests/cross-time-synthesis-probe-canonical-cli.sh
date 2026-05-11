#!/usr/bin/env bash
# Canonical-CLI surface tests for cross-time-synthesis-probe.sh
# (bead flywheel-1hshd.23 — wave-4-general-23 partial → passing).
# SURGICAL DASH-FLAG SCAFFOLD: bash scaffold owns --examples + new
# positional verbs; native --info/--schema/--doctor + default classifier
# fall through to native (with in-place .name/.capabilities/.input_schema/
# .output_schema augmentations). No pre-existing regression suite for
# this surface — coverage delivered solely by this canonical-cli suite.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/cross-time-synthesis-probe.sh"
TMP="$(mktemp -d -t cts-cli.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
LOG="$TMP/runs.jsonl"
HOFFS="$TMP/handoffs"; mkdir -p "$HOFFS"

pass=0; fail=0
ok()  { printf 'PASS %s\n' "$1"; pass=$((pass+1)); }
bad() { printf 'FAIL %s\n' "$1" >&2; fail=$((fail+1)); }
expect_rc() { [[ "$1" == "$2" ]] && ok "$3 rc=$1" || bad "$3 expected_rc=$2 got=$1"; }
expect_jq() { jq -e "$2" "$1" >/dev/null && ok "$3" || { bad "$3"; jq . "$1" >&2 || true; }; }

# --- AG3 strict gates ---

# Test 1: AG3.1 .name + .version + .capabilities (NATIVE info_payload augmented in-place)
"$SCRIPT" --info --json >"$TMP/info.json"
expect_jq "$TMP/info.json" '.name == "cross-time-synthesis-probe.sh" and .version and (.capabilities|type=="array") and (.capabilities|length>=3)' "AG3.1 --info name+version+capabilities"

# Test 2: regression-style — native fields preserved on --info
expect_jq "$TMP/info.json" '.repo and .handoff_dir and .ledger and .modes and .value_gap_dimension == "cross-time-synthesis"' "native --info contract preserved"

# Test 3: AG3.2 .input_schema + .output_schema (NATIVE schema_payload augmented)
"$SCRIPT" --schema --json >"$TMP/schema.json"
expect_jq "$TMP/schema.json" '.input_schema and .output_schema and .ledger_row_required_fields' "AG3.2 --schema input/output + back-compat"

# Test 4: AG3.3 .examples >= 3 (NEW scaffold-owned envelope)
"$SCRIPT" --examples --json >"$TMP/examples.json"
expect_jq "$TMP/examples.json" '.examples | length >= 3' "AG3.3 --examples >= 3"

# Test 5: AG3.4 doctor --json emits .checks (NEW scaffold-owned)
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" doctor --json >"$TMP/doctor.json"
expect_jq "$TMP/doctor.json" '.checks | length >= 5' "AG3.4 doctor .checks >= 5"
expect_jq "$TMP/doctor.json" '[.checks[].name] | (index("python3_available") and index("handoff_dir_readable"))' "doctor includes load-bearing python3+handoff_dir probes"

# --- health (NEW scaffold verb) ---

# Test 6: health binds audit log
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" health --json >"$TMP/health.json"
expect_jq "$TMP/health.json" '.audit_log == "'"$LOG"'" and .stale_threshold_seconds and (.status=="pass" or .status=="warn")' "health binds audit_log"

# --- repair (NEW scaffold verb with apply-contract gate) ---

# Test 7: repair --dry-run audit_log_dir
"$SCRIPT" repair --scope audit_log_dir --dry-run --json >"$TMP/r-dry.json"
expect_jq "$TMP/r-dry.json" '.status == "ok" and .scope == "audit_log_dir" and .mode == "dry_run"' "repair --dry-run"

# Test 8: repair --apply without --idempotency-key returns rc=3
set +e; "$SCRIPT" repair --scope audit_log_dir --apply --json >"$TMP/r-refused.json"; rc=$?; set -e
expect_rc "$rc" 3 "repair --apply no-key refused"

# Test 9: repair handoff_dir_path REPORT-ONLY scope
"$SCRIPT" repair --scope handoff_dir_path --dry-run --json >"$TMP/r-report.json"
expect_jq "$TMP/r-report.json" '.status == "report" and .scope == "handoff_dir_path" and (.readable|type=="boolean")' "repair handoff_dir_path REPORT-ONLY"

# Test 10: repair unknown scope rc=64
set +e; "$SCRIPT" repair --scope bogus --json >"$TMP/r-unk.json"; rc=$?; set -e
expect_rc "$rc" 64 "repair unknown rc=64"

# --- validate (NEW canonical 3-subject contract) ---

# Test 11: validate handoff-dir-path OK (real dir)
"$SCRIPT" validate handoff-dir-path "$HOFFS" >"$TMP/v-h-ok.json"
expect_jq "$TMP/v-h-ok.json" '.status == "ok" and .subject == "handoff-dir-path"' "validate handoff-dir-path OK"

# Test 12: validate handoff-dir-path missing rc=1
set +e; "$SCRIPT" validate handoff-dir-path /no/such/dir/abc >"$TMP/v-h-bad.json"; rc=$?; set -e
expect_rc "$rc" 1 "validate handoff-dir-path missing rc=1"

# Test 13: validate sample-n in range
"$SCRIPT" validate sample-n 25 >"$TMP/v-sn-ok.json"
expect_jq "$TMP/v-sn-ok.json" '.status == "ok" and .value == 25' "validate sample-n in-range"

# Test 14: validate sample-n out of range rc=1
set +e; "$SCRIPT" validate sample-n 99999 >"$TMP/v-sn-bad.json"; rc=$?; set -e
expect_rc "$rc" 1 "validate sample-n out-of-range rc=1"

# Test 15: validate tomorrow-header-regex OK
"$SCRIPT" validate tomorrow-header-regex '^## (Tomorrow|Open question)' >"$TMP/v-rx-ok.json"
expect_jq "$TMP/v-rx-ok.json" '.status == "ok"' "validate tomorrow-header-regex OK"

# Test 16: validate unknown subject rc=64
set +e; "$SCRIPT" validate fictitious >"$TMP/v-uns.json"; rc=$?; set -e
expect_rc "$rc" 64 "validate unknown_subject rc=64"

# --- audit + why (NEW scaffold verbs) ---

# Test 17: audit empty
SCAFFOLD_AUDIT_LOG="$TMP/missing.jsonl" "$SCRIPT" audit --json >"$TMP/a-empty.json"
expect_jq "$TMP/a-empty.json" '.status == "missing" or .status == "empty"' "audit empty/missing"

# Test 18: audit with rows
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '{"ts":"%s","handoff_dir":"%s","tomorrow_you_artifact_today":"present"}\n' "$TS" "$HOFFS" > "$LOG"
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" audit --json >"$TMP/a-row.json"
expect_jq "$TMP/a-row.json" '(.status == "pass" or .status == "ok") and (.row_count == 1 or (.rows|length) == 1)' "audit with row"

# Test 19: why found
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" why "$TS" --json >"$TMP/w-found.json"
expect_jq "$TMP/w-found.json" '.status == "found"' "why found"

# Test 20: why not_found
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" why no-such-id --json >"$TMP/w-nf.json"
expect_jq "$TMP/w-nf.json" '.status == "not_found"' "why not_found"

# Test 21: why unavailable
SCAFFOLD_AUDIT_LOG="$TMP/missing.jsonl" "$SCRIPT" why anything --json >"$TMP/w-un.json"
expect_jq "$TMP/w-un.json" '.status == "unavailable"' "why unavailable"

# --- quickstart + help <topic> ---

# Test 22: quickstart
"$SCRIPT" quickstart --json >"$TMP/qs.json"
expect_jq "$TMP/qs.json" '.command == "quickstart" and (.steps|length>=3)' "quickstart"

# Test 23: help <topic>
"$SCRIPT" help doctor >"$TMP/help-d.txt"
grep -q 'topic: doctor' "$TMP/help-d.txt" && ok "help doctor topic" || bad "help doctor topic"

# --- back-compat: native --info / --schema / --doctor / default still work ---

# Test 24: native --doctor (dash flag) still emits .status + .issues
"$SCRIPT" --doctor --json --ledger "$LOG" --handoff-dir "$HOFFS" >"$TMP/n-doc.json"
expect_jq "$TMP/n-doc.json" '.status and (.issues|type == "array") and .mode == "doctor"' "native --doctor back-compat"

# Test 25: native default classifier (no flag) emits ledger row shape
"$SCRIPT" --json --handoff-dir "$HOFFS" --ledger "$LOG" >"$TMP/n-cls.json"
expect_jq "$TMP/n-cls.json" '.schema_version == "cross-time-synthesis/v1" and .handoffs_observed == 0 and .tomorrow_you_artifact_today' "native default classifier back-compat"

# Test 26: --idempotency-key flag accepted on default classifier (lint L7)
"$SCRIPT" --apply --idempotency-key cts-test-key --handoff-dir "$HOFFS" --ledger "$TMP/idem-test.jsonl" --json >"$TMP/n-idem.json"
expect_jq "$TMP/n-idem.json" '.mode == "apply" and .ledger == "'"$TMP/idem-test.jsonl"'"' "--idempotency-key flag accepted on --apply"

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
