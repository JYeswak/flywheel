#!/usr/bin/env bash
# Canonical-CLI surface tests for codex-death-event-classifier.sh
# (bead flywheel-1hshd.15 — wave-4-general-15 partial → passing).
# Verifies SURGICAL DASH-FLAG SCAFFOLD: scaffold owns --info/--schema/
# --examples/quickstart canonical envelopes; native positional subcommands
# (info/schema/examples + run/doctor/health/repair/validate/audit/why)
# remain unchanged for back-compat (covered by
# .flywheel/tests/test-codex-death-event-classifier.sh).
#
# In-place augmentations verified here:
#   - doctor --json now emits .checks array (AG3.4)
#   - --idempotency-key flag + apply-contract gate (rc=3 if --apply alone)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/codex-death-event-classifier.sh"
TMP="$(mktemp -d -t cdec-cli.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
EV="$TMP/evidence"; mkdir -p "$EV"
LEDGER="$TMP/ledger.jsonl"

pass=0; fail=0
ok()  { printf 'PASS %s\n' "$1"; pass=$((pass+1)); }
bad() { printf 'FAIL %s\n' "$1" >&2; fail=$((fail+1)); }
expect_rc() { [[ "$1" == "$2" ]] && ok "$3 rc=$1" || bad "$3 expected_rc=$2 got=$1"; }
expect_jq() { jq -e "$2" "$1" >/dev/null && ok "$3" || { bad "$3"; jq . "$1" >&2 || true; }; }

# ---------- Scaffold-owned canonical envelopes (--info/--schema/--examples) ----------

# Test 1: AG3.1 .name + .version + .capabilities
"$SCRIPT" --info --json >"$TMP/info.json"
expect_jq "$TMP/info.json" '.name == "codex-death-event-classifier.sh" and .version and (.capabilities|type=="array") and (.capabilities|length>=3)' "AG3.1 --info has name+version+capabilities"

# Test 2: AG3.2 .input_schema + .output_schema
"$SCRIPT" --schema --json >"$TMP/schema.json"
expect_jq "$TMP/schema.json" '.input_schema and .output_schema and (.surfaces|index("doctor"))' "AG3.2 --schema has input/output schemas"

# Test 3: AG3.3 .examples > 0
"$SCRIPT" --examples --json >"$TMP/examples.json"
expect_jq "$TMP/examples.json" '.examples | length >= 3' "AG3.3 --examples has >=3 entries"

# Test 4: --schema <surface> per-surface schema
"$SCRIPT" --schema doctor >"$TMP/schema-doctor.json"
expect_jq "$TMP/schema-doctor.json" '.surface == "doctor" and (.fields|type=="object")' "--schema doctor surface schema"
"$SCRIPT" --schema repair >"$TMP/schema-repair.json"
expect_jq "$TMP/schema-repair.json" '.surface == "repair" and .contract.requires_idempotency_key_when_apply == true' "--schema repair contract"

# Test 5: quickstart
"$SCRIPT" quickstart --json >"$TMP/qs.json"
expect_jq "$TMP/qs.json" '.command == "quickstart" and (.steps|length>=3)' "quickstart steps"

# Test 6: help <topic>
"$SCRIPT" help doctor >"$TMP/help-doctor.txt"
grep -q 'topic: doctor' "$TMP/help-doctor.txt" && ok "help doctor topic" || bad "help doctor topic"

# ---------- doctor --json .checks (AG3.4 in-place augmentation) ----------

# Test 7: doctor --json emits .checks array (AG3.4)
"$SCRIPT" doctor --json --evidence-dir "$EV" --ledger "$LEDGER" >"$TMP/doctor.json"
expect_jq "$TMP/doctor.json" '.checks | length >= 5' "AG3.4 doctor has >=5 checks"
expect_jq "$TMP/doctor.json" '[.checks[].name] | (index("br_bin_available") and index("evidence_dir_readable"))' "doctor includes load-bearing br_bin probe"

# Test 8: doctor --json preserves back-compat fields (regression test asserts these)
expect_jq "$TMP/doctor.json" '.pending == 0 and .total_receipts == 0' "doctor preserves pending+total_receipts"

# ---------- Apply-contract gate (rc=3 if --apply without --idempotency-key) ----------

# Test 9: run --apply without --idempotency-key returns rc=3
set +e; "$SCRIPT" run --apply --evidence-dir "$EV" --ledger "$LEDGER" --json >"$TMP/run-refused.json"; rc=$?; set -e
expect_rc "$rc" 3 "run --apply without --idempotency-key refused"
expect_jq "$TMP/run-refused.json" '.status == "refused" and .exit_code == 3' "run refused has status=refused"

# Test 10: run --apply WITH --idempotency-key proceeds
set +e; "$SCRIPT" run --apply --idempotency-key cdec-test-key --evidence-dir "$EV" --ledger "$LEDGER" --json --no-bead-filing >"$TMP/run-ok.json"; rc=$?; set -e
expect_rc "$rc" 0 "run --apply --idempotency-key proceeds"
expect_jq "$TMP/run-ok.json" '.mode == "apply"' "run apply mode"

# Test 11: run --dry-run does NOT require --idempotency-key
set +e; "$SCRIPT" run --dry-run --evidence-dir "$EV" --ledger "$LEDGER" --json >"$TMP/run-dry.json"; rc=$?; set -e
expect_rc "$rc" 0 "run --dry-run no key required"
expect_jq "$TMP/run-dry.json" '.mode == "dry-run"' "run dry-run mode"

# Test 12: implicit `run` (back-compat default → apply mode without explicit --apply) does NOT require --idempotency-key
set +e; "$SCRIPT" run --evidence-dir "$EV" --ledger "$LEDGER" --json --no-bead-filing >"$TMP/run-default.json"; rc=$?; set -e
expect_rc "$rc" 0 "implicit run (default apply) no key required (back-compat)"
expect_jq "$TMP/run-default.json" '.mode == "apply"' "implicit run still applies"

# Test 13: repair --apply without --idempotency-key returns rc=3
set +e; "$SCRIPT" repair --apply --evidence-dir "$EV" --ledger "$LEDGER" --json >"$TMP/repair-refused.json"; rc=$?; set -e
expect_rc "$rc" 3 "repair --apply without --idempotency-key refused"

# ---------- Native back-compat (introspection trio still works) ----------

# Test 14: native `info` positional still emits valid JSON with .version
"$SCRIPT" info >"$TMP/native-info.json"
expect_jq "$TMP/native-info.json" '.version' "native `info` back-compat (.version)"

# Test 15: native `schema` positional still emits valid JSON with .title
"$SCRIPT" schema >"$TMP/native-schema.json"
expect_jq "$TMP/native-schema.json" '.title == "codex-death-classifier ledger row"' "native `schema` back-compat (.title)"

# Test 16: native `examples` positional still prints text "EXAMPLES:"
"$SCRIPT" examples >"$TMP/native-examples.txt"
grep -q '^EXAMPLES:' "$TMP/native-examples.txt" && ok "native \`examples\` back-compat (text)" || bad "native examples"

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
