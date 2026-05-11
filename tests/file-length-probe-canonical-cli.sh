#!/usr/bin/env bash
# Canonical-CLI surface tests for file-length-probe.sh
# (bead flywheel-1hshd.26 — wave-4-general-26 partial → passing).
# SURGICAL DASH-FLAG SCAFFOLD: bash scaffold owns --info/--schema/
# --examples + new positional verbs; native --repo/--json/--doctor/
# --no-color/--no-emoji + default scanner fall through unchanged.
# Pre-existing regression: tests/file-length-probe.sh (9/9 PASS).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/file-length-probe.sh"
TMP="$(mktemp -d -t flp-cli.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
LOG="$TMP/runs.jsonl"
REPO="$TMP/repo"; mkdir -p "$REPO"

pass=0; fail=0
ok()  { printf 'PASS %s\n' "$1"; pass=$((pass+1)); }
bad() { printf 'FAIL %s\n' "$1" >&2; fail=$((fail+1)); }
expect_rc() { [[ "$1" == "$2" ]] && ok "$3 rc=$1" || bad "$3 expected_rc=$2 got=$1"; }
expect_jq() { jq -e "$2" "$1" >/dev/null && ok "$3" || { bad "$3"; jq . "$1" >&2 || true; }; }

# --- AG3 strict gates ---

# Test 1: AG3.1 .name + .version + .capabilities
"$SCRIPT" --info --json >"$TMP/info.json"
expect_jq "$TMP/info.json" '.name == "file-length-probe.sh" and .version and (.capabilities|type=="array") and (.capabilities|length>=3)' "AG3.1 --info name+version+capabilities"

# Test 2: AG3.2 .input_schema + .output_schema
"$SCRIPT" --schema --json >"$TMP/schema.json"
expect_jq "$TMP/schema.json" '.input_schema and .output_schema and (.surfaces|index("doctor"))' "AG3.2 --schema input/output"

# Test 3: AG3.3 .examples >= 3
"$SCRIPT" --examples --json >"$TMP/examples.json"
expect_jq "$TMP/examples.json" '.examples | length >= 3' "AG3.3 --examples >= 3"

# Test 4: AG3.4 doctor --json emits .checks
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" doctor --json >"$TMP/doctor.json"
expect_jq "$TMP/doctor.json" '.checks | length >= 5' "AG3.4 doctor .checks >= 5"
expect_jq "$TMP/doctor.json" '[.checks[].name] | (index("find_available") and index("repo_resolvable"))' "doctor includes load-bearing find+repo probes"

# Test 5: per-surface schemas
"$SCRIPT" --schema doctor >"$TMP/sch-d.json"
expect_jq "$TMP/sch-d.json" '.surface == "doctor"' "--schema doctor"
"$SCRIPT" --schema repair >"$TMP/sch-r.json"
expect_jq "$TMP/sch-r.json" '.surface == "repair" and .contract.requires_idempotency_key_when_apply == true' "--schema repair contract"

# Test 6: quickstart
"$SCRIPT" quickstart --json >"$TMP/qs.json"
expect_jq "$TMP/qs.json" '.command == "quickstart" and (.steps|length>=3)' "quickstart"

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

# Test 10: repair repo_path REPORT-ONLY scope
"$SCRIPT" repair --scope repo_path --dry-run --json >"$TMP/r-report.json"
expect_jq "$TMP/r-report.json" '.status == "report" and .scope == "repo_path" and (.readable|type=="boolean")' "repair repo_path REPORT-ONLY"

# Test 11: repair unknown scope rc=64
set +e; "$SCRIPT" repair --scope bogus --json >"$TMP/r-unk.json"; rc=$?; set -e
expect_rc "$rc" 64 "repair unknown rc=64"

# --- validate (3 subjects) ---

# Test 12: validate repo-path OK
"$SCRIPT" validate repo-path "$REPO" >"$TMP/v-r-ok.json"
expect_jq "$TMP/v-r-ok.json" '.status == "ok" and .subject == "repo-path"' "validate repo-path OK"

# Test 13: validate repo-path missing rc=1
set +e; "$SCRIPT" validate repo-path /no/such/dir/abc >"$TMP/v-r-bad.json"; rc=$?; set -e
expect_rc "$rc" 1 "validate repo-path missing rc=1"

# Test 14: validate language-name enum members
for lang in bash python rust markdown; do
  "$SCRIPT" validate language-name "$lang" >"$TMP/v-l-$lang.json"
  expect_jq "$TMP/v-l-$lang.json" '.status == "ok"' "validate language-name $lang"
done

# Test 15: validate language-name unknown rc=1
set +e; "$SCRIPT" validate language-name go >"$TMP/v-l-bad.json"; rc=$?; set -e
expect_rc "$rc" 1 "validate language-name unknown rc=1"

# Test 16: validate threshold in range
"$SCRIPT" validate threshold 750 >"$TMP/v-th-ok.json"
expect_jq "$TMP/v-th-ok.json" '.status == "ok" and .value == 750' "validate threshold in-range"

# Test 17: validate threshold out of range rc=1
set +e; "$SCRIPT" validate threshold 999999999 >"$TMP/v-th-bad.json"; rc=$?; set -e
expect_rc "$rc" 1 "validate threshold out-of-range rc=1"

# Test 18: validate unknown subject rc=64
set +e; "$SCRIPT" validate fictitious >"$TMP/v-uns.json"; rc=$?; set -e
expect_rc "$rc" 64 "validate unknown_subject rc=64"

# --- audit + why ---

# Test 19: audit empty
SCAFFOLD_AUDIT_LOG="$TMP/missing.jsonl" "$SCRIPT" audit --json >"$TMP/a-empty.json"
expect_jq "$TMP/a-empty.json" '.status == "missing" or .status == "empty"' "audit empty/missing"

# Test 20: audit with rows
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '{"ts":"%s","repo":"%s","oversized_files_count":2}\n' "$TS" "$REPO" > "$LOG"
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" audit --json >"$TMP/a-row.json"
expect_jq "$TMP/a-row.json" '(.status == "pass" or .status == "ok") and (.row_count == 1 or (.rows|length) == 1)' "audit with row"

# Test 21: why found
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" why "$TS" --json >"$TMP/w-found.json"
expect_jq "$TMP/w-found.json" '.status == "found"' "why found"

# Test 22: why not_found
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" why no-such-id --json >"$TMP/w-nf.json"
expect_jq "$TMP/w-nf.json" '.status == "not_found"' "why not_found"

# Test 23: why unavailable
SCAFFOLD_AUDIT_LOG="$TMP/missing.jsonl" "$SCRIPT" why anything --json >"$TMP/w-un.json"
expect_jq "$TMP/w-un.json" '.status == "unavailable"' "why unavailable"

# --- help <topic> ---

# Test 24: help <topic>
"$SCRIPT" help doctor >"$TMP/help-d.txt"
grep -q 'topic: doctor' "$TMP/help-d.txt" && ok "help doctor topic" || bad "help doctor topic"

# --- back-compat: native scanner unchanged ---

# Test 25: native --repo PATH --json default scanner produces canonical findings
mkdir -p "$REPO/scripts"
echo "echo hi" > "$REPO/scripts/tiny.sh"
"$SCRIPT" --repo "$REPO" --json >"$TMP/native-scan.json"
expect_jq "$TMP/native-scan.json" '.schema_version == "file-length-probe/v1" and .oversized_files_count == 0 and .scanned_files_count >= 1' "native --repo --json scanner back-compat"

# Test 26: native --doctor flag (alias for --json) still works
"$SCRIPT" --repo "$REPO" --doctor >"$TMP/native-doc.json"
expect_jq "$TMP/native-doc.json" '.schema_version == "file-length-probe/v1" and .status' "native --doctor flag back-compat"

# Test 27: self-exclusion — probe doesn't surface itself in oversized count
# Copy probe into test repo (mirrors the regression-suite pattern)
cp "$SCRIPT" "$REPO/.flywheel/scripts/file-length-probe.sh" 2>/dev/null || mkdir -p "$REPO/.flywheel/scripts" && cp "$SCRIPT" "$REPO/.flywheel/scripts/file-length-probe.sh"
"$SCRIPT" --repo "$REPO" --json >"$TMP/native-self.json"
expect_jq "$TMP/native-self.json" '.oversized_files_count == 0' "self-exclusion: probe does not self-surface as oversized"

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
