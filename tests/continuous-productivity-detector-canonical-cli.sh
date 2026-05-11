#!/usr/bin/env bash
# Canonical-CLI surface tests for continuous-productivity-detector.sh
# (bead flywheel-1hshd.19 — wave-4-general-19 partial → passing).
# SURGICAL DASH-FLAG SCAFFOLD: bash scaffold owns --schema + new verbs
# (doctor/health/repair/validate/audit/why/quickstart); python heredoc
# owns default classifier + --info (augmented in-place) + --examples.
# Pre-existing regression: .flywheel/tests/test_continuous_productivity_detector.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/continuous-productivity-detector.sh"
TMP="$(mktemp -d -t cpd-cli.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
LOG="$TMP/runs.jsonl"

pass=0; fail=0
ok()  { printf 'PASS %s\n' "$1"; pass=$((pass+1)); }
bad() { printf 'FAIL %s\n' "$1" >&2; fail=$((fail+1)); }
expect_rc() { [[ "$1" == "$2" ]] && ok "$3 rc=$1" || bad "$3 expected_rc=$2 got=$1"; }
expect_jq() { jq -e "$2" "$1" >/dev/null && ok "$3" || { bad "$3"; jq . "$1" >&2 || true; }; }

# --- AG3 strict gates ---

# Test 1: AG3.1 .name + .version + .capabilities (NATIVE python info()
# augmented in-place + regression contract preserved)
"$SCRIPT" --info --json >"$TMP/info.json"
expect_jq "$TMP/info.json" '.name == "continuous-productivity-detector.sh" and .version and (.capabilities|type=="array") and (.capabilities|length>=3)' "AG3.1 --info name+version+capabilities"

# Test 2: regression contract preserved on --info
expect_jq "$TMP/info.json" '.read_only == true and .peer_repo_writes == false and (.canonical_cli|index("--quiet")) and (.joshua_notify_allowlist|index("substrate-corrupt"))' "regression --info contract preserved"

# Test 3: AG3.2 .input_schema + .output_schema (SCAFFOLD intercepts --schema)
"$SCRIPT" --schema --json >"$TMP/schema.json"
expect_jq "$TMP/schema.json" '.input_schema and .output_schema and (.surfaces|index("doctor"))' "AG3.2 --schema input/output"

# Test 4: AG3.3 .examples >= 3 (NATIVE python examples() unchanged)
"$SCRIPT" --examples --json >"$TMP/examples.json"
expect_jq "$TMP/examples.json" '.examples | length >= 3' "AG3.3 --examples >= 3"

# Test 5: AG3.4 doctor --json emits .checks (SCAFFOLD owns doctor)
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" doctor --json >"$TMP/doctor.json"
expect_jq "$TMP/doctor.json" '.checks | length >= 5' "AG3.4 doctor .checks >= 5"
expect_jq "$TMP/doctor.json" '[.checks[].name] | (index("python3_available") and index("ntm_executable") and index("topology_readable"))' "doctor includes load-bearing python3+ntm+topology probes"

# --- per-surface schemas ---

# Test 6: per-surface schemas
"$SCRIPT" --schema doctor >"$TMP/sch-d.json"
expect_jq "$TMP/sch-d.json" '.surface == "doctor"' "--schema doctor"
"$SCRIPT" --schema repair >"$TMP/sch-r.json"
expect_jq "$TMP/sch-r.json" '.surface == "repair" and .contract.requires_idempotency_key_when_apply == true' "--schema repair contract"

# --- health (NEW scaffold verb) ---

# Test 7: health binds audit log
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" health --json >"$TMP/health.json"
expect_jq "$TMP/health.json" '.audit_log == "'"$LOG"'" and .stale_threshold_seconds and (.status=="pass" or .status=="warn")' "health binds audit_log"

# --- repair (NEW scaffold verb with apply-contract gate) ---

# Test 8: repair --dry-run audit_log_dir
"$SCRIPT" repair --scope audit_log_dir --dry-run --json >"$TMP/r-dry.json"
expect_jq "$TMP/r-dry.json" '.status == "ok" and .scope == "audit_log_dir" and .mode == "dry_run"' "repair --dry-run audit_log_dir"

# Test 9: repair --apply without --idempotency-key returns rc=3
set +e; "$SCRIPT" repair --scope audit_log_dir --apply --json >"$TMP/r-refused.json"; rc=$?; set -e
expect_rc "$rc" 3 "repair --apply no-key refused"
expect_jq "$TMP/r-refused.json" '.status == "refused"' "repair refused status"

# Test 10: repair topology_path REPORT-ONLY scope
"$SCRIPT" repair --scope topology_path --dry-run --json >"$TMP/r-report.json"
expect_jq "$TMP/r-report.json" '.status == "report" and .scope == "topology_path" and (.readable|type=="boolean")' "repair topology_path REPORT-ONLY"

# Test 11: repair unknown scope rc=64
set +e; "$SCRIPT" repair --scope bogus --json >"$TMP/r-unk.json"; rc=$?; set -e
expect_rc "$rc" 64 "repair unknown rc=64"

# --- validate (NEW canonical 3-subject contract) ---

# Test 12: validate session-name OK
"$SCRIPT" validate session-name skillos >"$TMP/v-sn.json"
expect_jq "$TMP/v-sn.json" '.status == "ok"' "validate session-name OK"

# Test 13: validate threshold-seconds in range
"$SCRIPT" validate threshold-seconds 600 >"$TMP/v-th-ok.json"
expect_jq "$TMP/v-th-ok.json" '.status == "ok" and .value == 600' "validate threshold-seconds in-range"

# Test 14: validate threshold-seconds out of range rc=1
set +e; "$SCRIPT" validate threshold-seconds 99999999 >"$TMP/v-th-bad.json"; rc=$?; set -e
expect_rc "$rc" 1 "validate threshold-seconds out-of-range rc=1"

# Test 15: validate allowlist-class enum members
for c in substrate-corrupt security phi paradigm destructive; do
  "$SCRIPT" validate allowlist-class "$c" >"$TMP/v-c-$c.json"
  expect_jq "$TMP/v-c-$c.json" '.status == "ok"' "validate allowlist-class $c"
done

# Test 16: validate allowlist-class unknown rc=1
set +e; "$SCRIPT" validate allowlist-class bogus >"$TMP/v-c-bad.json"; rc=$?; set -e
expect_rc "$rc" 1 "validate allowlist-class unknown rc=1"

# Test 17: validate unknown subject rc=64
set +e; "$SCRIPT" validate fictitious >"$TMP/v-uns.json"; rc=$?; set -e
expect_rc "$rc" 64 "validate unknown_subject rc=64"

# --- audit + why (NEW scaffold verbs) ---

# Test 18: audit empty
SCAFFOLD_AUDIT_LOG="$TMP/missing.jsonl" "$SCRIPT" audit --json >"$TMP/a-empty.json"
expect_jq "$TMP/a-empty.json" '.status == "missing" or .status == "empty"' "audit empty/missing"

# Test 19: audit with rows
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '{"ts":"%s","session":"skillos","productivity_state":"productive"}\n' "$TS" > "$LOG"
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" audit --json >"$TMP/a-row.json"
expect_jq "$TMP/a-row.json" '(.status == "pass" or .status == "ok") and (.row_count == 1 or (.rows|length) == 1)' "audit with row"

# Test 20: why found
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" why "$TS" --json >"$TMP/w-found.json"
expect_jq "$TMP/w-found.json" '.status == "found"' "why found"

# Test 21: why not_found
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" why no-such-id --json >"$TMP/w-nf.json"
expect_jq "$TMP/w-nf.json" '.status == "not_found"' "why not_found"

# Test 22: why unavailable
SCAFFOLD_AUDIT_LOG="$TMP/missing.jsonl" "$SCRIPT" why anything --json >"$TMP/w-un.json"
expect_jq "$TMP/w-un.json" '.status == "unavailable"' "why unavailable"

# --- quickstart + help <topic> ---

# Test 23: quickstart
"$SCRIPT" quickstart --json >"$TMP/qs.json"
expect_jq "$TMP/qs.json" '.command == "quickstart" and (.steps|length>=3)' "quickstart steps"

# Test 24: help <topic>
"$SCRIPT" help doctor >"$TMP/help-d.txt"
grep -q 'topic: doctor' "$TMP/help-d.txt" && ok "help doctor topic" || bad "help doctor topic"

# --- back-compat: native default classifier untouched ---

# Test 25: bare invocation falls through to python (default classifier)
# Use empty fixtures dirs so no real probes fire.
mkdir -p "$TMP/topo-empty" "$TMP/loops-empty" "$TMP/act-empty" "$TMP/ready-empty" "$TMP/doc-empty"
: > "$TMP/topology.jsonl"
"$SCRIPT" --topology "$TMP/topology.jsonl" --loops-dir "$TMP/loops-empty" \
  --activity-dir "$TMP/act-empty" --ready-dir "$TMP/ready-empty" --doctor-dir "$TMP/doc-empty" --json \
  >"$TMP/native-cls.json"
expect_jq "$TMP/native-cls.json" '.schema_version == "continuous-productivity-detector/v1" and .sessions_checked == 0 and .action_required_count == 0' "native default classifier back-compat"

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
