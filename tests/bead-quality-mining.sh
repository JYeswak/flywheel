#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/bead-quality-mining.sh"
VALIDATOR="$ROOT/.flywheel/scripts/bead-ag-format.py"
WRAPPER="$ROOT/.flywheel/scripts/br-create-validated.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/bead-quality-mining-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

json_get() {
  jq -r "$1" "$2"
}

create_closed_bead() {
  local repo="$1" title="$2" desc="$3" id
  id="$(br create "$title" --type task --priority 1 --description "$desc" --json | jq -r '.id // .issue.id')"
  [[ -n "$id" && "$id" != "null" ]] || fail "failed to create bead $title"
  br close "$id" --reason "fixture closure" --json >/dev/null
  printf '%s\n' "$id"
}

repo="$TMP/repo"
mkdir -p "$repo/.flywheel" "$repo/tests"
cd "$repo"
git init -q
br init --prefix bq --json >/dev/null

printf 'ok\n' >"$repo/.flywheel/full.txt"
printf '# Incidents\n' >"$repo/INCIDENTS.md"
printf '#!/usr/bin/env bash\nexit 0\n' >"$repo/tests/pass.sh"
chmod +x "$repo/tests/pass.sh"
doctor_fixture="$TMP/doctor.json"
printf '{"present_signal_count":0,"nested":{"another_signal_count":1}}\n' >"$doctor_fixture"
export BEAD_QUALITY_DOCTOR_JSON_FILE="$doctor_fixture"

valid_body="$TMP/valid-body.md"
nested_body="$TMP/nested-body.md"
noverb_body="$TMP/noverb-body.md"
printf 'Acceptance gates\nAG1: `.flywheel/full.txt` exists.\nAG2: `tests/pass.sh` passes.\n' >"$valid_body"
printf 'Acceptance gates\nAG1: `.flywheel/full.txt` exists.\n  - nested subgate should be rejected\n' >"$nested_body"
printf 'Acceptance gates\nAG1: green path\n' >"$noverb_body"

valid_once="$TMP/valid-once.json"
valid_twice="$TMP/valid-twice.json"
"$VALIDATOR" --description-file "$valid_body" --json >"$valid_once"
"$VALIDATOR" --description-file "$valid_body" --json >"$valid_twice"
[[ "$(json_get '.status' "$valid_once")" == "pass" ]] || fail "well-formed AG list did not pass"
[[ "$(json_get '.gate_count' "$valid_once")" -eq "$(json_get '.gate_count' "$valid_twice")" ]] || fail "AG parser count was not deterministic"

"$VALIDATOR" --description-file "$nested_body" --json >"$TMP/nested.json" && nested_rc=0 || nested_rc=$?
[[ "$nested_rc" -eq 1 ]] || fail "nested AG list was not rejected"
[[ "$(jq -r '.errors[0].code' "$TMP/nested.json")" == "nested_ag_content" ]] || fail "nested AG rejection code mismatch"

"$VALIDATOR" --description-file "$noverb_body" --json >"$TMP/noverb.json"
[[ "$(json_get '.status' "$TMP/noverb.json")" == "warn" ]] || fail "AG without testable verb was not warned"
jq -e '.warnings[] | select(.code=="ag_without_testable_verb")' "$TMP/noverb.json" >/dev/null || fail "missing ag_without_testable_verb warning"

wrapper_id="$("$WRAPPER" --title "validated wrapper fixture" --type task --priority 1 --description-file "$valid_body" --json | jq -r '.id // .issue.id')"
[[ -n "$wrapper_id" && "$wrapper_id" != "null" ]] || fail "validated wrapper did not create bead"
"$WRAPPER" --title "blocked nested wrapper fixture" --type task --priority 1 --description-file "$nested_body" --json >"$TMP/wrapper-blocked.json" 2>/dev/null && wrapper_block_rc=0 || wrapper_block_rc=$?
[[ "$wrapper_block_rc" -eq 1 ]] || fail "validated wrapper did not block nested AG body"

full_id="$(create_closed_bead "$repo" "full evidence fixture" $'Acceptance gates\nAG1: file `.flywheel/full.txt` exists and doctor signal `present_signal_count` wired.\nAG2: test `tests/pass.sh` exists.')"
missing_id="$(create_closed_bead "$repo" "missing artifact fixture" $'Acceptance gates\nAG1: file `.flywheel/missing.txt` exists.')"
doctor_id="$(create_closed_bead "$repo" "doctor not wired fixture" $'Acceptance gates\nAG1: doctor signal `missing_signal_count` is exposed.')"
skipped_id="$(create_closed_bead "$repo" "tests skipped fixture" $'Acceptance gates\nAG1: tests=SKIPPED for `tests/not-run.sh` must not validate as full.')"
pending_id="$(create_closed_bead "$repo" "pending fixture" $'Acceptance gates\nAG1: ship the operator workflow without naming a mechanical artifact.')"
incidents_id="$(create_closed_bead "$repo" "incidents shorthand fixture" $'Acceptance gates\nAG1: Aggregate sources include INCIDENTS additions.')"
learn_id="$(create_closed_bead "$repo" "slash command fixture" $'Acceptance gates\nAG1: B09 routes newly discovered unwired-surface failures into `/flywheel:learn` exactly once.')"
open_bad_id="$(br create "open nested AG fixture" --type task --priority 1 --description "$(cat "$nested_body")" --json | jq -r '.id // .issue.id')"

first="$TMP/first.json"
"$SCRIPT" --repo "$repo" --json --scan-open-ag-format --now 2026-05-04T00:00:00Z >"$first"

[[ "$(json_get '.closed_beads_checked' "$first")" -eq 7 ]] || fail "expected 7 closed beads checked"
[[ "$(json_get '.closed_bead_audit_gap_count' "$first")" -eq 3 ]] || fail "expected 3 gap beads on first run"
[[ "$(json_get '.closed_bead_audit_pending_count' "$first")" -eq 1 ]] || fail "expected 1 pending gate"
[[ "$(json_get '.ag_format_gap_count' "$first")" -eq 1 ]] || fail "expected 1 open AG format gap"
[[ "$(jq -r --arg id "$open_bad_id" '.open_ag_format_rows[] | select(.bead_id==$id) | .audit_status' "$first")" == "gap_pending" ]] || fail "open noncanonical AG bead was not flagged"
[[ "$(jq -r --arg id "$full_id" '.rows[] | select(.bead_id==$id) | .audit_status' "$first")" == "full" ]] || fail "full fixture did not audit full"
[[ "$(jq -r --arg id "$missing_id" '.rows[] | select(.bead_id==$id) | .audit_status' "$first")" == "gap_pending" ]] || fail "missing fixture did not create gap"
[[ "$(jq -r --arg id "$doctor_id" '.rows[] | select(.bead_id==$id) | .audit_status' "$first")" == "gap_pending" ]] || fail "doctor fixture did not create gap"
[[ "$(jq -r --arg id "$skipped_id" '.rows[] | select(.bead_id==$id) | .audit_status' "$first")" == "gap_pending" ]] || fail "skipped fixture did not create gap"
[[ "$(jq -r --arg id "$pending_id" '.rows[] | select(.bead_id==$id) | .audit_status' "$first")" == "partial" ]] || fail "pending fixture did not audit partial"
[[ "$(jq -r --arg id "$incidents_id" '.rows[] | select(.bead_id==$id) | .audit_status' "$first")" == "full" ]] || fail "INCIDENTS shorthand did not resolve to INCIDENTS.md"
[[ "$(jq -r --arg id "$learn_id" '.rows[] | select(.bead_id==$id) | .audit_status' "$first")" == "full" ]] || fail "/flywheel:learn slash command did not resolve to command file"

first_gap_total="$(br list --all --json --limit 0 | jq '[.issues[] | select((.labels // []) | index("audit-gap"))] | length')"
[[ "$first_gap_total" -eq 4 ]] || fail "expected exactly 4 audit-gap beads after first run, got $first_gap_total"

second="$TMP/second.json"
"$SCRIPT" --repo "$repo" --json --scan-open-ag-format --now 2026-05-04T00:15:00Z >"$second"
second_gap_total="$(br list --all --json --limit 0 | jq '[.issues[] | select((.labels // []) | index("audit-gap"))] | length')"
[[ "$second_gap_total" -eq "$first_gap_total" ]] || fail "idempotent rerun created duplicate gap beads"

doctor="$TMP/doctor-mode.json"
"$SCRIPT" --repo "$repo" --doctor --json --now 2026-05-04T00:30:00Z >"$doctor"
[[ "$(json_get '.closed_bead_audit_gap_count' "$doctor")" -ge 3 ]] || fail "doctor mode did not expose gap count"
[[ "$(json_get '.signals | length' "$doctor")" -eq 3 ]] || fail "doctor mode did not expose 3 signal contracts"

echo "PASS bead-quality-mining fixtures full-evidence missing-AG doctor-not-wired tests-skipped canonical-AG-format idempotent-rerun"
