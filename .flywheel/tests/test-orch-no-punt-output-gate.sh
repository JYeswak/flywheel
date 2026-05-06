#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/orch-no-punt-output-gate.sh"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/orch-no-punt-decision.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/orch-no-punt-output-gate.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0

pass() {
  printf 'PASS %s\n' "$1"
  pass_count=$((pass_count + 1))
}

fail() {
  printf 'FAIL %s\n' "$1" >&2
  exit 1
}

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    jq . "$file" >&2 || cat "$file" >&2
    fail "$label"
  fi
}

schema_validate() {
  local file="$1"
  python3 -c 'import json, sys
from jsonschema import Draft202012Validator
schema = json.load(open(sys.argv[1], encoding="utf-8"))
payload = json.load(open(sys.argv[2], encoding="utf-8"))
Draft202012Validator(schema, format_checker=Draft202012Validator.FORMAT_CHECKER).validate(payload)' "$SCHEMA" "$file"
}

write_ready() {
  local file="$1" count="${2:-1}"
  if [[ "$count" -eq 0 ]]; then
    printf '{"issues":[]}\n' >"$file"
  else
    jq -nc --argjson count "$count" '{issues:[range(0; $count) | {id:("fixture-" + tostring), status:"open", priority:0}]}' >"$file"
  fi
}

write_activity() {
  local file="$1" state="$2"
  case "$state" in
    waiting)
      jq -nc '{agents:[{pane_idx:2,agent_type:"codex",state:"WAITING",detected_patterns:["codex_chevron_prompt"]}]}' >"$file"
      ;;
    waiting_pattern)
      jq -nc '{agents:[{pane_idx:2,agent_type:"codex",state:"THINKING",detected_patterns:["codex_waiting_background","codex_chevron_prompt"]}]}' >"$file"
      ;;
    busy)
      jq -nc '{agents:[{pane_idx:2,agent_type:"codex",state:"THINKING",detected_patterns:["codex_working"]}]}' >"$file"
      ;;
    *)
      fail "unknown activity fixture: $state"
      ;;
  esac
}

run_gate() {
  local name="$1" expected_rc="$2" text="$3" activity_state="$4" ready_count="$5"
  local activity="$TMP/$name.activity.json" ready="$TMP/$name.ready.json" out="$TMP/$name.out"
  write_activity "$activity" "$activity_state"
  write_ready "$ready" "$ready_count"
  set +e
  ORCH_NO_PUNT_LEDGER="$TMP/ledger.jsonl" \
    ORCH_NO_PUNT_ACTIVITY_FILE="$activity" \
    ORCH_NO_PUNT_READY_FILE="$ready" \
    "$SCRIPT" check --text-stdin --session fixture --json <<<"$text" >"$out"
  rc=$?
  set -e
  [[ "$rc" -eq "$expected_rc" ]] || { cat "$out" >&2 || true; fail "$name expected rc=$expected_rc got rc=$rc"; }
  jq empty "$out" >/dev/null || fail "$name JSON parse"
  schema_validate "$out" || fail "$name schema validation"
  pass "${name}_schema"
}

command -v jq >/dev/null 2>&1 || fail "missing jq"
bash -n "$SCRIPT" && pass "script_syntax"
jq empty "$SCHEMA" >/dev/null && pass "schema_json_parses"
"$SCRIPT" --help >/dev/null && pass "help"
"$SCRIPT" --info | jq -e '.name == "orch-no-punt-output-gate.sh"' >/dev/null && pass "info_json"
"$SCRIPT" --examples | grep -q -- '--text-stdin' && pass "examples"

run_gate refuse 1 "options: A or B" waiting 2
assert_jq "$TMP/refuse.out" '.decision == "refuse" and .punt_pattern_matched == "Options:" and .panes_waiting == [2] and .ready_beads == 2' "refuse_idle_ready"

run_gate busy_allow 0 "should I dispatch this?" busy 1
assert_jq "$TMP/busy_allow.out" '.decision == "allow" and .reason == "no_idle_worker_capacity"' "allow_busy"

run_gate blocker_allow 0 "should I rotate the Vercel API key now?" waiting 1
assert_jq "$TMP/blocker_allow.out" '.decision == "allow" and .blocker_class_matched == "credential_or_secret_rotation"' "allow_blocker_class"

run_gate no_punt_allow 0 "Dispatching flywheel-abc to pane 4." waiting 1
assert_jq "$TMP/no_punt_allow.out" '.decision == "allow" and .reason == "no_punt_pattern"' "allow_no_punt"

run_gate no_ready_allow 0 "want me to fire this?" waiting_pattern 0
assert_jq "$TMP/no_ready_allow.out" '.decision == "allow" and .reason == "no_ready_beads" and .panes_waiting == [2]' "allow_no_ready"

missing_out="$TMP/missing-file.out"
ORCH_NO_PUNT_LEDGER="$TMP/ledger.jsonl" "$SCRIPT" check --text-file "$TMP/does-not-exist" --session fixture --json >"$missing_out"
schema_validate "$missing_out" || fail "missing text-file schema validation"
assert_jq "$missing_out" '.decision == "allow" and .reason == "text_file_unreadable_fail_open" and (.warnings[0] | test("text_file_unreadable_fail_open"))' "allow_missing_text_file"

cat >"$TMP/fail-ntm" <<'SH'
#!/usr/bin/env bash
exit 7
SH
chmod +x "$TMP/fail-ntm"
ready="$TMP/fail-open.ready.json"
write_ready "$ready" 1
set +e
ORCH_NO_PUNT_LEDGER="$TMP/ledger.jsonl" \
  ORCH_NO_PUNT_NTM_BIN="$TMP/fail-ntm" \
  ORCH_NO_PUNT_READY_FILE="$ready" \
  "$SCRIPT" check --text-stdin --session fixture --json <<<"want me to dispatch?" >"$TMP/fail-open.out"
fail_open_rc=$?
set -e
[[ "$fail_open_rc" -eq 0 ]] || fail "probe failure should fail open"
schema_validate "$TMP/fail-open.out" || fail "fail-open schema validation"
assert_jq "$TMP/fail-open.out" '.decision == "allow" and .reason == "probe_error_fail_open" and (.warnings | index("ntm_activity_probe_failed"))' "allow_probe_failure"

ledger_count="$(wc -l <"$TMP/ledger.jsonl" | tr -d ' ')"
[[ "$ledger_count" -eq 7 ]] || fail "expected 7 ledger rows, got $ledger_count"
while IFS= read -r row; do
  jq empty <<<"$row" >/dev/null || fail "ledger row is not JSON"
done <"$TMP/ledger.jsonl"
pass "ledger_row_appended_on_every_decision"

printf 'Summary: %s passed\n' "$pass_count"
