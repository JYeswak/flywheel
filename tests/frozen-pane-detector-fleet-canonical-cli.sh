#!/usr/bin/env bash
# Canonical-CLI surface tests for frozen-pane-detector-fleet.sh
# (bead flywheel-1hshd.31 — wave-4-general-31 partial → passing).
# IN-PLACE AUGMENTATION pattern (no scaffold layer needed): native
# already had every canonical verb (doctor/health/install/uninstall/
# cycle/repair/validate/audit/why/schema/quickstart/completion). Four
# augmentations in-place: info_json (.name+.capabilities), schema_json
# (.input_schema+.output_schema), examples (--json envelope branch),
# augmented_doctor_json (.checks wrap). Two pre-existing regression
# suites preserved.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/frozen-pane-detector-fleet.sh"
TMP="$(mktemp -d -t fpd-cli.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

# Isolate state so we don't pollute the operator's plist + state dir.
export FROZEN_FLEET_STATE_DIR="$TMP/state"
export FROZEN_FLEET_PLIST="$TMP/ai.zeststream.frozen-pane-detector-fleet.plist"
export FROZEN_FLEET_STDOUT="$TMP/logs/out.log"
export FROZEN_FLEET_STDERR="$TMP/logs/err.log"
mkdir -p "$TMP/state" "$TMP/logs"

pass=0; fail=0
ok()  { printf 'PASS %s\n' "$1"; pass=$((pass+1)); }
bad() { printf 'FAIL %s\n' "$1" >&2; fail=$((fail+1)); }
expect_jq() { jq -e "$2" "$1" >/dev/null && ok "$3" || { bad "$3"; jq . "$1" >&2 || true; }; }

# --- AG3 strict gates ---

# Test 1: AG3.1 .name + .version + .capabilities + back-compat .commands
"$SCRIPT" --info --json >"$TMP/info.json"
expect_jq "$TMP/info.json" '.name == "frozen-pane-detector-fleet.sh" and .version and (.capabilities|type=="array") and (.capabilities|length>=3)' "AG3.1 --info name+version+capabilities"
expect_jq "$TMP/info.json" '.commands | (index("doctor") and index("repair") and index("validate") and index("audit") and index("why"))' "regression .commands preserved"

# Test 2: AG3.2 .input_schema + .output_schema + back-compat .title/.required
"$SCRIPT" --schema --json >"$TMP/schema.json"
expect_jq "$TMP/schema.json" '.input_schema and .output_schema' "AG3.2 --schema input/output"
expect_jq "$TMP/schema.json" '.title and .required' "regression .title/.required preserved"

# Test 3: AG3.3 .examples >= 3 (NEW JSON envelope branch)
"$SCRIPT" --examples --json >"$TMP/examples.json"
expect_jq "$TMP/examples.json" '.examples | length >= 3' "AG3.3 --examples >= 3"

# Test 4: --examples (no --json) preserves text mode for back-compat
"$SCRIPT" --examples 2>&1 | grep -q 'frozen-pane-detector-fleet.sh' && ok "examples text-mode back-compat" || bad "examples text-mode"

# Test 5: AG3.4 doctor --json emits .checks (positional verb routes through augmented_doctor_json)
"$SCRIPT" doctor --json >"$TMP/doctor.json" 2>/dev/null || true
expect_jq "$TMP/doctor.json" '.checks | length >= 5' "AG3.4 doctor .checks >= 5"
expect_jq "$TMP/doctor.json" '[.checks[].name] | (index("launchctl_available") and index("plutil_available") and index("detector_executable"))' "doctor includes load-bearing launchctl+plutil+detector probes"

# Test 6: --doctor --json (dash flag) ALSO routes through augmentation (regression contract)
"$SCRIPT" --doctor --json >"$TMP/dash-doc.json" 2>/dev/null || true
expect_jq "$TMP/dash-doc.json" '.status and .daemon_installed != null and (.checks | length >= 5)' "--doctor flag preserves regression contract + adds .checks"

# Test 7: doctor preserves all native fields (regression contract)
expect_jq "$TMP/doctor.json" '.status and .daemon_installed != null and .cadence_seconds and .recovery_budget' "doctor native fields preserved"

# --- canonical surface back-compat (already-existing native verbs) ---

# Test 8: native `audit` verb
"$SCRIPT" audit --json >"$TMP/audit.json" 2>/dev/null || true
expect_jq "$TMP/audit.json" '.schema_version == "frozen-pane-detector-fleet.v1" and .mode == "audit"' "native audit verb back-compat"

# Test 9: native `why <topic>` verb
"$SCRIPT" why gate >"$TMP/why-gate.txt"
grep -q 'L60/L67' "$TMP/why-gate.txt" && ok "native why gate topic" || bad "native why gate"

# Test 10: native quickstart verb
"$SCRIPT" quickstart >"$TMP/qs.txt"
grep -q 'Install' "$TMP/qs.txt" && ok "native quickstart verb" || bad "native quickstart"

# Test 11: native completion verb
"$SCRIPT" completion >"$TMP/comp.txt"
grep -q '#compdef' "$TMP/comp.txt" && ok "native completion verb" || bad "native completion"

# Test 12: native validate budgets
"$SCRIPT" validate budgets --json >"$TMP/vb.json" 2>/dev/null || true
expect_jq "$TMP/vb.json" '.schema_version == "frozen-pane-detector-fleet.v1" and .mode == "validate" and .thing == "budgets"' "native validate budgets back-compat"

# Test 13: install --dry-run (no plist mutation; isolated state)
"$SCRIPT" install --dry-run --json >"$TMP/install-dry.json" 2>/dev/null || true
expect_jq "$TMP/install-dry.json" '.schema_version == "frozen-pane-detector-fleet.v1" and .mode == "install"' "install --dry-run back-compat"

# Test 14: --info text mode (no --json) ALSO returns JSON per native default
"$SCRIPT" --info | jq -e '.commands' >/dev/null && ok "--info default-mode emits JSON (native behavior preserved)" || bad "--info default-mode"

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
