#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/low-bead-threshold-detector.sh"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/low-bead-threshold-decision.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/low-bead-threshold-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail() { printf 'FAIL %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then pass "$label"; else jq . "$file" >&2 || true; fail "$label"; fi
}

repo() { local d="$TMP/$1"; mkdir -p "$d/.beads"; : >"$d/.beads/issues.jsonl"; printf '%s\n' "$d"; }
issue() {
  local repo="$1" id="$2" status="$3" title="${4:-work}" assignee="${5:-}"
  jq -nc --arg id "$id" --arg status "$status" --arg title "$title" --arg assignee "$assignee" \
    '{id:$id,status:$status,title:$title,priority:1,issue_type:"task",assignee:(if $assignee == "" then null else $assignee end),created_at:"2026-05-06T00:00:00Z",updated_at:"2026-05-06T00:00:00Z"}' >>"$repo/.beads/issues.jsonl"
}

run() {
  local label="$1" repo="$2"; shift 2
  LOW_BEAD_THRESHOLD_LEDGER="$TMP/$label-ledger.jsonl" "$SCRIPT" check --repo "$repo" --json "$@" >"$TMP/$label.json"
}

validate_payload() {
  python3 - "$SCHEMA" "$1" <<'PY'
import json, sys
from jsonschema import Draft202012Validator
schema = json.load(open(sys.argv[1], encoding="utf-8"))
payload = json.load(open(sys.argv[2], encoding="utf-8"))
Draft202012Validator.check_schema(schema)
Draft202012Validator(schema).validate(payload)
PY
}

bash -n "$SCRIPT" && pass "script_syntax"
"$SCRIPT" --help >/dev/null && pass "help_passes"
"$SCRIPT" --examples >/dev/null && pass "examples_passes"
jq empty "$SCHEMA" && pass "schema_json_parses"

r="$(repo green)"; for n in $(seq 1 20); do issue "$r" "g$n" open; done
run green "$r"
assert_jq "$TMP/green.json" '.signal == "GREEN" and .ready_count == 20 and .in_progress_count == 0' "twenty_ready_green"
validate_payload "$TMP/green.json" && pass "green_schema_valid"

r="$(repo yellow)"; for n in $(seq 1 7); do issue "$r" "y$n" open; done
run yellow "$r"
assert_jq "$TMP/yellow.json" '.signal == "YELLOW" and .ready_count == 7 and .yellow_floor == 5' "seven_ready_yellow"

r="$(repo red)"; for n in $(seq 1 3); do issue "$r" "r$n" open; done; issue "$r" p1 in_progress work WorkerOne
run red "$r" --auto-bead
assert_jq "$TMP/red.json" '.signal == "RED" and .ready_count == 3 and .in_progress_count == 1 and .auto_bead_filed == true and .hunt_bead_id != null' "three_ready_red_files"
grep -q '"title":"hunt-work-MISSION-env-skills"' "$r/.beads/issues.jsonl" && pass "hunt_bead_written"

run red2 "$r" --auto-bead
assert_jq "$TMP/red2.json" '.auto_bead_filed == false and .auto_bead_action == "reused"' "open_hunt_idempotent"
[[ "$(grep -c '"title":"hunt-work-MISSION-env-skills"' "$r/.beads/issues.jsonl")" == "1" ]] || fail "open_hunt_duplicate"
pass "open_hunt_no_duplicate"

r="$(repo closed)"; issue "$r" h closed hunt-work-MISSION-env-skills; for n in $(seq 1 2); do issue "$r" "c$n" open; done
run closed "$r" --auto-bead
assert_jq "$TMP/closed.json" '.signal == "RED" and .auto_bead_filed == true' "closed_hunt_allows_new"

r="$(repo noauto)"; for n in $(seq 1 3); do issue "$r" "n$n" open; done
run noauto "$r"
assert_jq "$TMP/noauto.json" '.signal == "RED" and .auto_bead_filed == false and .hunt_bead_id == null' "auto_flag_respected"

r="$(repo threshold)"; for n in $(seq 1 8); do issue "$r" "t$n" open; done
run threshold "$r" --threshold 20
assert_jq "$TMP/threshold.json" '.threshold == 20 and .yellow_floor == 10 and .signal == "RED"' "threshold_configurable"

[[ "$(wc -l <"$TMP/threshold-ledger.jsonl" | tr -d ' ')" == "1" ]] && pass "ledger_each_invocation" || fail "ledger_each_invocation"

missing="$TMP/missing-repo"; mkdir -p "$missing"
set +e
LOW_BEAD_THRESHOLD_LEDGER="$TMP/missing-ledger.jsonl" "$SCRIPT" check --repo "$missing" --json >"$TMP/missing.json"
rc=$?
set -e
[[ "$rc" == "2" ]] && pass "missing_jsonl_rc2" || fail "missing_jsonl_rc2"
assert_jq "$TMP/missing.json" '.signal == "GRAY" and .exit_code == 2 and (.warnings | index("issues_jsonl_missing"))' "missing_jsonl_gray"
[[ "$(wc -l <"$TMP/missing-ledger.jsonl" | tr -d ' ')" == "1" ]] && pass "missing_ledger_written" || fail "missing_ledger_written"

printf 'PASS cases=10 assertions=%s failures=0\n' "$pass_count"
