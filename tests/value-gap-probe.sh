#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/value-gap-probe.sh"
TICK="$ROOT/.flywheel/flywheel-loop-tick"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/tick-receipt.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/value-gap-probe.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

repo="$TMP/repo"
mkdir -p "$repo"
git -C "$repo" init -q
(cd "$repo" && br init >/dev/null)
parent="$(cd "$repo" && br create "parent value gap fixture" --priority P3 --type task --description fixture --json | jq -r '.id')"
state="$TMP/state"
mkdir -p "$state"

bash -n "$PROBE" && pass "script syntax" || fail "script syntax"
bash -n "$TICK" && pass "tick syntax" || fail "tick syntax"
jq -e '.properties.value_gap and .properties.value_gap_dimension_scanned and .properties.value_gap_finding and .properties.bead_filed_id' "$SCHEMA" >/dev/null \
  && pass "tick schema has value_gap fields" || fail "tick schema has value_gap fields"
jq -e '.properties.agent_mail_fd_status and .properties.mobile_eats_receipt_status and .properties.daily_jeff_ingest_status and .properties.fleet_onboard_status and .properties.jeff_status_stale_open_count' "$SCHEMA" >/dev/null \
  && pass "tick schema has scheduled probe fields" || fail "tick schema has scheduled probe fields"

"$PROBE" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.mode == "info" and .dimension_count == 10' "info reports 10 dimensions"

"$PROBE" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '(.receipt_fields | index("value_gap_dimension_scanned")) and (.mutation_requires | index("--apply"))' "schema documents receipt and mutation"

"$PROBE" --doctor --repo "$repo" --state-dir "$state" --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.mode == "doctor" and .success == true' "doctor passes in fixture"

for dim in 0 1 2; do
  "$PROBE" --repo "$repo" --state-dir "$state" --dry-run --dimension "$dim" --json >"$TMP/dim-$dim.json"
done
jq -sr '[.[].value_gap_dimension_scanned] | unique | length == 3' "$TMP"/dim-*.json >/dev/null \
  && pass "three dry-run ticks scan three dimensions" || fail "three dry-run ticks scan three dimensions"
jq -e '.bead_filed_id == null and .bead_action == "dry_run"' "$TMP/dim-0.json" >/dev/null \
  && pass "dry-run does not file bead" || fail "dry-run does not file bead"

"$PROBE" --repo "$repo" --state-dir "$state" --apply --dimension 0 --parent "$parent" --idempotency-key test-1 --json >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.bead_action == "created" and (.bead_filed_id | startswith("flywheel-") or startswith("repo-") or type == "string")' "apply files value-gap bead"

"$PROBE" --repo "$repo" --state-dir "$state" --apply --dimension 0 --parent "$parent" --idempotency-key test-1 --json >"$TMP/apply-again.json"
assert_jq "$TMP/apply-again.json" '.bead_action == "existing" and .bead_filed_id != null' "apply is idempotent by title"

for n in $(seq 1 55); do
  (cd "$repo" && br create "higher priority filler $n" --priority P0 --type task --description fixture --json >/dev/null)
done
"$PROBE" --repo "$repo" --state-dir "$state" --apply --dimension 0 --parent "$parent" --idempotency-key test-1 --json >"$TMP/apply-after-limit.json"
assert_jq "$TMP/apply-after-limit.json" '.bead_action == "existing" and .bead_filed_id != null' "apply finds existing beyond default list limit"

"$PROBE" audit --repo "$repo" --state-dir "$state" --json >"$TMP/audit.json"
assert_jq "$TMP/audit.json" '.rows >= 2' "audit reads ledger"

"$PROBE" metrics --repo "$repo" --state-dir "$state" --json >"$TMP/metrics.json"
assert_jq "$TMP/metrics.json" '.ledger_rows >= 2 and .beads_filed >= 2' "metrics reads filed beads"

rg -q 'value_gap_probe' "$TICK" && pass "tick runs value gap probe" || fail "tick runs value gap probe"
rg -q 'Value gap pre-tick' "$TICK" && pass "tick prompt includes value gap section" || fail "tick prompt includes value gap section"
rg -q 'value_gap_dimension_scanned' "$TICK" && pass "tick receipt writes value gap fields" || fail "tick receipt writes value gap fields"

echo
printf 'Summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
