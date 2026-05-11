#!/usr/bin/env bash
# Canonical-CLI surface tests for gap-hunt-probe.sh
# (bead flywheel-1hshd.34 — wave-4-general-34 partial → passing).
# IN-PLACE AUGMENTATION + SURGICAL VERB SCAFFOLD: native already had
# --info/--schema/--examples/--doctor flags; in-place augmented to
# add .name/.capabilities/.input_schema/.output_schema/.examples-json
# branch. NEW positional verbs (doctor/health/repair/validate/audit/
# why/quickstart/help) added via scaffold dispatch in main(). Four
# pre-existing regression suites preserved (28/0 total).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/gap-hunt-probe.sh"
TMP="$(mktemp -d -t ghp-cli.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
LOG="$TMP/runs.jsonl"

pass=0; fail=0
ok()  { printf 'PASS %s\n' "$1"; pass=$((pass+1)); }
bad() { printf 'FAIL %s\n' "$1" >&2; fail=$((fail+1)); }
expect_rc() { [[ "$1" == "$2" ]] && ok "$3 rc=$1" || bad "$3 expected_rc=$2 got=$1"; }
expect_jq() { jq -e "$2" "$1" >/dev/null && ok "$3" || { bad "$3"; jq . "$1" >&2 || true; }; }

# --- AG3 strict gates ---

# Test 1: AG3.1 .name + .version + .capabilities (NATIVE info_payload augmented in-place)
"$SCRIPT" --info --json >"$TMP/info.json"
expect_jq "$TMP/info.json" '.name == "gap-hunt-probe.sh" and .version and (.capabilities|type=="array") and (.capabilities|length>=3)' "AG3.1 --info name+version+capabilities"

# Test 2: regression-style — native fields preserved on --info
expect_jq "$TMP/info.json" '.success == true and .repo_root and .ledger and .gap_classes and (.gap_classes|length == 9)' "native --info fields preserved (regression contract)"

# Test 3: AG3.2 .input_schema + .output_schema (NATIVE schema_payload augmented)
"$SCRIPT" --schema --json >"$TMP/schema.json"
expect_jq "$TMP/schema.json" '.input_schema and .output_schema' "AG3.2 --schema input/output"
expect_jq "$TMP/schema.json" '.schema == "flywheel.gap_hunt_probe.v1" and .gap_classes and .mutation_contract' "native --schema fields preserved"

# Test 4: AG3.3 .examples >= 3 (NEW JSON envelope branch)
"$SCRIPT" --examples --json >"$TMP/examples.json"
expect_jq "$TMP/examples.json" '.examples | length >= 3' "AG3.3 --examples >= 3"

# Test 5: --examples (no --json) preserves text mode for back-compat
"$SCRIPT" --examples 2>&1 | grep -q 'Examples:' && ok "examples text-mode back-compat" || bad "examples text-mode"

# Test 6: AG3.4 doctor --json emits .checks (NEW positional verb routes through scaffold)
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" doctor --json >"$TMP/doctor.json"
expect_jq "$TMP/doctor.json" '.checks | length >= 5' "AG3.4 doctor .checks >= 5"
expect_jq "$TMP/doctor.json" '[.checks[].name] | (index("python3_available") and index("br_executable") and index("ledger_dir_writable"))' "doctor includes load-bearing python3+br+ledger probes"

# --- health ---

# Test 7: health binds audit log
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" health --json >"$TMP/health.json"
expect_jq "$TMP/health.json" '.audit_log == "'"$LOG"'" and .stale_threshold_seconds and (.status=="pass" or .status=="warn")' "health binds audit_log"

# --- repair (apply-contract gate) ---

# Test 8: repair --dry-run audit_log_dir
"$SCRIPT" repair --scope audit_log_dir --dry-run --json >"$TMP/r-dry.json"
expect_jq "$TMP/r-dry.json" '.status == "ok" and .scope == "audit_log_dir"' "repair --dry-run audit_log_dir"

# Test 9: repair --apply without --idempotency-key returns rc=3
set +e; "$SCRIPT" repair --scope audit_log_dir --apply --json >"$TMP/r-refused.json"; rc=$?; set -e
expect_rc "$rc" 3 "repair --apply no-key refused"

# Test 10: repair ledger_path REPORT-ONLY scope
"$SCRIPT" repair --scope ledger_path --dry-run --json >"$TMP/r-report.json"
expect_jq "$TMP/r-report.json" '.status == "report" and .scope == "ledger_path" and (.readable|type=="boolean")' "repair ledger_path REPORT-ONLY"

# Test 11: repair unknown scope rc=64
set +e; "$SCRIPT" repair --scope bogus --json >"$TMP/r-unk.json"; rc=$?; set -e
expect_rc "$rc" 64 "repair unknown rc=64"

# --- validate (3 subjects) ---

# Test 12: validate gap-class enum
for c in wired-but-cold doctrine-without-measurement probe-without-receiver loop-integrity; do
  "$SCRIPT" validate gap-class "$c" >"$TMP/v-c-$c.json"
  expect_jq "$TMP/v-c-$c.json" '.status == "ok"' "validate gap-class $c"
done

# Test 13: validate gap-class unknown rc=1
set +e; "$SCRIPT" validate gap-class bogus-class >"$TMP/v-c-bad.json"; rc=$?; set -e
expect_rc "$rc" 1 "validate gap-class unknown rc=1"

# Test 14: validate bead-id pattern
"$SCRIPT" validate bead-id flywheel-1hshd.34 >"$TMP/v-b-ok.json"
expect_jq "$TMP/v-b-ok.json" '.status == "ok"' "validate bead-id pattern OK"

# Test 15: validate bead-id pattern reject
set +e; "$SCRIPT" validate bead-id "not a bead" >"$TMP/v-b-bad.json"; rc=$?; set -e
expect_rc "$rc" 1 "validate bead-id pattern rc=1"

# Test 16: validate auto-bead-cap in range
"$SCRIPT" validate auto-bead-cap 5 >"$TMP/v-cap-ok.json"
expect_jq "$TMP/v-cap-ok.json" '.status == "ok" and .value == 5' "validate auto-bead-cap in-range"

# Test 17: validate auto-bead-cap out of range rc=1
set +e; "$SCRIPT" validate auto-bead-cap 999 >"$TMP/v-cap-bad.json"; rc=$?; set -e
expect_rc "$rc" 1 "validate auto-bead-cap out-of-range rc=1"

# Test 18: validate unknown subject rc=64
set +e; "$SCRIPT" validate fictitious >"$TMP/v-uns.json"; rc=$?; set -e
expect_rc "$rc" 64 "validate unknown_subject rc=64"

# --- audit + why ---

# Test 19: audit empty
SCAFFOLD_AUDIT_LOG="$TMP/missing.jsonl" "$SCRIPT" audit --json >"$TMP/a-empty.json"
expect_jq "$TMP/a-empty.json" '.status == "empty" or .status == "missing"' "audit empty/missing"

# Test 20: audit with rows
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '{"ts":"%s","gap_ids":["g1","g2"],"version":"gap-hunt-probe.v1"}\n' "$TS" > "$LOG"
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" audit --json >"$TMP/a-row.json"
expect_jq "$TMP/a-row.json" '.status == "ok" and (.rows|length) == 1' "audit with row"

# Test 21: why found by gap_id
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" why g1 --json >"$TMP/w-found.json"
expect_jq "$TMP/w-found.json" '.status == "found"' "why found by gap_id"

# Test 22: why not_found
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" why no-such-id --json >"$TMP/w-nf.json"
expect_jq "$TMP/w-nf.json" '.status == "not_found"' "why not_found"

# Test 23: why unavailable
SCAFFOLD_AUDIT_LOG="$TMP/missing.jsonl" "$SCRIPT" why anything --json >"$TMP/w-un.json"
expect_jq "$TMP/w-un.json" '.status == "unavailable"' "why unavailable"

# --- quickstart + help <topic> ---

# Test 24: quickstart
"$SCRIPT" quickstart >"$TMP/qs.json"
expect_jq "$TMP/qs.json" '.command == "quickstart" and (.steps|length>=3)' "quickstart"

# Test 25: help <topic>
"$SCRIPT" help doctor >"$TMP/help-d.txt"
grep -q 'topic: doctor' "$TMP/help-d.txt" && ok "help doctor topic" || bad "help doctor topic"

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
