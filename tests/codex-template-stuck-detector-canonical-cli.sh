#!/usr/bin/env bash
# Canonical-CLI surface tests for codex-template-stuck-detector.sh
# (bead flywheel-1hshd.17 — wave-4-general-17 partial → passing).
# SURGICAL DASH-FLAG SCAFFOLD: scaffold owns --info/--schema/--examples/
# quickstart + NEW verbs (health/repair/audit/why/validate); native
# doctor/info/schema/detect remain unchanged for back-compat (covered by
# tests/codex-template-stuck-detector.sh + .flywheel/tests/test_codex_template_stuck_detector.sh).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/codex-template-stuck-detector.sh"
TMP="$(mktemp -d -t cdec-stuck-cli.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
LOG="$TMP/runs.jsonl"

pass=0; fail=0
ok()  { printf 'PASS %s\n' "$1"; pass=$((pass+1)); }
bad() { printf 'FAIL %s\n' "$1" >&2; fail=$((fail+1)); }
expect_rc() { [[ "$1" == "$2" ]] && ok "$3 rc=$1" || bad "$3 expected_rc=$2 got=$1"; }
expect_jq() { jq -e "$2" "$1" >/dev/null && ok "$3" || { bad "$3"; jq . "$1" >&2 || true; }; }

# --- Scaffold-owned canonical envelopes ---

# Test 1: AG3.1 .name + .version + .capabilities
"$SCRIPT" --info --json >"$TMP/info.json"
expect_jq "$TMP/info.json" '.name == "codex-template-stuck-detector.sh" and .version and (.capabilities|type=="array") and (.capabilities|length>=3)' "AG3.1 --info name+version+capabilities"

# Test 2: AG3.2 .input_schema + .output_schema
"$SCRIPT" --schema --json >"$TMP/schema.json"
expect_jq "$TMP/schema.json" '.input_schema and .output_schema and (.surfaces|index("doctor"))' "AG3.2 --schema input/output"

# Test 3: AG3.3 .examples >= 3
"$SCRIPT" --examples --json >"$TMP/examples.json"
expect_jq "$TMP/examples.json" '.examples | length >= 3' "AG3.3 --examples >= 3"

# Test 4: per-surface schemas
"$SCRIPT" --schema doctor >"$TMP/sch-doctor.json"
expect_jq "$TMP/sch-doctor.json" '.surface == "doctor"' "--schema doctor"
"$SCRIPT" --schema repair >"$TMP/sch-repair.json"
expect_jq "$TMP/sch-repair.json" '.surface == "repair" and .contract.requires_idempotency_key_when_apply == true' "--schema repair contract"

# Test 5: quickstart
"$SCRIPT" quickstart --json >"$TMP/qs.json"
expect_jq "$TMP/qs.json" '.command == "quickstart" and (.steps|length>=3)' "quickstart"

# --- doctor --json .checks (AG3.4 in-place augmentation) ---

# Test 6: AG3.4 doctor --json emits .checks array
SCAFFOLD_AUDIT_LOG="$LOG" CODEX_STUCK_DETECTOR_LEDGER="$LOG" "$SCRIPT" --doctor --json >"$TMP/doctor.json"
expect_jq "$TMP/doctor.json" '.checks | length >= 5' "AG3.4 doctor .checks >= 5"
expect_jq "$TMP/doctor.json" '[.checks[].name] | (index("ntm_executable") and index("caam_bin_executable"))' "doctor includes load-bearing probes (ntm + caam)"

# Test 7: doctor preserves back-compat fields (regression-test contract)
expect_jq "$TMP/doctor.json" '.schema_version == "codex-stuck-detector.doctor.v1" and (.codex_template_stuck_count_24h != null) and (.substrate_loop_contract_self_row_action != null)' "doctor back-compat fields preserved"

# --- health (NEW scaffold verb) ---

# Test 8: health binds audit log
SCAFFOLD_AUDIT_LOG="$LOG" "$SCRIPT" health --json >"$TMP/health.json"
expect_jq "$TMP/health.json" '.audit_log == "'"$LOG"'" and .stale_threshold_seconds and (.status=="pass" or .status=="warn")' "health binds audit_log"

# --- repair (NEW scaffold verb) ---

# Test 9: repair --dry-run audit_log_dir
"$SCRIPT" repair --scope audit_log_dir --dry-run --json >"$TMP/r-dry.json"
expect_jq "$TMP/r-dry.json" '.status == "ok" and .scope == "audit_log_dir" and .mode == "dry_run"' "repair --dry-run audit_log_dir"

# Test 10: repair --apply without --idempotency-key returns rc=3
set +e; "$SCRIPT" repair --scope audit_log_dir --apply --json >"$TMP/r-refused.json"; rc=$?; set -e
expect_rc "$rc" 3 "repair --apply no-key refused"
expect_jq "$TMP/r-refused.json" '.status == "refused"' "repair refused status"

# Test 11: repair caam_rotate_path REPORT-ONLY scope
"$SCRIPT" repair --scope caam_rotate_path --dry-run --json >"$TMP/r-report.json"
expect_jq "$TMP/r-report.json" '.status == "report" and .scope == "caam_rotate_path" and (.executable|type=="boolean")' "repair caam_rotate_path REPORT-ONLY"

# Test 12: repair unknown scope rc=64
set +e; "$SCRIPT" repair --scope bogus --json >"$TMP/r-unk.json"; rc=$?; set -e
expect_rc "$rc" 64 "repair unknown scope rc=64"

# --- validate (NEW canonical 3-subject contract via scaffold) ---

# Test 13: validate fixture-path with non-JSON file rc=1
set +e; "$SCRIPT" validate fixture-path /etc/hosts >"$TMP/v-fp-bad.json"; rc=$?; set -e
expect_rc "$rc" 1 "validate fixture-path non-JSON rc=1"

# Test 14: validate fixture-path OK (real JSON)
echo '{"session":"test","pane":1,"t0":"x","t1":"x"}' > "$TMP/fixture.json"
"$SCRIPT" validate fixture-path "$TMP/fixture.json" >"$TMP/v-fp-ok.json"
expect_jq "$TMP/v-fp-ok.json" '.status == "ok" and .subject == "fixture-path"' "validate fixture-path OK"

# Test 15: validate subclass enum members
for s in alive background_terminal_stuck model_at_capacity_halt post_completion input_deaf buffer_stuck; do
  "$SCRIPT" validate subclass "$s" >"$TMP/v-s-$s.json"
  expect_jq "$TMP/v-s-$s.json" '.status == "ok"' "validate subclass $s"
done

# Test 16: validate subclass unknown rc=1
set +e; "$SCRIPT" validate subclass bogus >"$TMP/v-s-bad.json"; rc=$?; set -e
expect_rc "$rc" 1 "validate subclass unknown rc=1"

# Test 17: validate session-name OK
"$SCRIPT" validate session-name flywheel >"$TMP/v-sn.json"
expect_jq "$TMP/v-sn.json" '.status == "ok"' "validate session-name"

# Test 18: scaffold intercepts validate ONLY for known canonical subjects
# (fixture-path|subclass|session-name); unknown subjects fall through to
# native validate by design. This preserves back-compat with the existing
# tests/codex-template-stuck-detector.sh which calls
# `$SCRIPT validate fixture --fixture ...` and expects native shape.
# Verify native validate is still reachable for non-canonical subjects:
set +e; "$SCRIPT" validate fixture --fixture "$TMP/fixture.json" --json >"$TMP/v-native.json"; rc=$?; set -e
expect_jq "$TMP/v-native.json" '.schema_version == "codex-stuck-detector.validate.v1"' "validate non-canonical falls through to native"

# --- audit + why (NEW scaffold verbs) ---

# Test 19: audit empty
SCAFFOLD_AUDIT_LOG="$TMP/missing.jsonl" "$SCRIPT" audit --json >"$TMP/a-empty.json"
expect_jq "$TMP/a-empty.json" '.status == "missing" or .status == "empty"' "audit empty/missing"

# Test 20: audit with rows
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '{"ts":"%s","session":"flywheel","subclass":"alive","hash_t1":"abc"}\n' "$TS" > "$LOG"
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

# --- back-compat (native introspection trio + detect mode) ---

# Test 24: native `info` positional still emits valid JSON
"$SCRIPT" info >"$TMP/n-info.json"
expect_jq "$TMP/n-info.json" '.name == "codex-template-stuck-detector.sh" and .version' "native \`info\` back-compat"

# Test 25: native `--info` flag form still works (NB: routes to scaffold now,
# but envelope still has name+version per AG3.1 — verified by Test 1 above).
# This is intentional: --info is canonical; positional `info` retains native shape.

# Test 26: native detect mode (default) with fixture works unchanged
echo '{"session":"test","pane":1,"t0":"alive","t1":"alive"}' > "$TMP/alive.json"
"$SCRIPT" --fixture "$TMP/alive.json" --json >"$TMP/det-alive.json"
expect_jq "$TMP/det-alive.json" '.subclass == "alive" and .schema_version == "codex-stuck-detector.detect.v1"' "native detect (alive fixture) back-compat"

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
