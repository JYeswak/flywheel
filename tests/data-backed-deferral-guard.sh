#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
FLYWHEEL_LOOP_BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
FLYWHEEL_LOOP_TICK="${FLYWHEEL_LOOP_TICK:-$ROOT/.flywheel/flywheel-loop-tick}"
FIXTURES="$ROOT/tests/fixtures/data-backed-deferral"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/data-backed-deferral-guard.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
check_count=0

pass() {
  check_count=$((check_count + 1))
  pass_count=$((pass_count + 1))
  printf 'PASS %s\n' "$1"
}

fail() {
  check_count=$((check_count + 1))
  printf 'FAIL %s\n' "$1" >&2
  printf '  - %s\n' "$2" >&2
  exit 1
}

line_count() {
  [[ -f "$1" ]] || { printf '0'; return 0; }
  wc -l <"$1" | tr -d ' '
}

assert_jq_file() {
  local label="$1" file="$2" filter="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label" "jq filter failed: $filter; file=$file; content=$(cat "$file" 2>/dev/null || true)"
  fi
}

json_get_file() {
  jq -r "$2" "$1"
}

run_check() {
  local fixture="$1" out="$2" rcvar="$3" command_rc=0
  "$FLYWHEEL_LOOP_BIN" data-backed-deferral-check --signals "$fixture" --json >"$out" 2>"$out.err" || command_rc=$?
  printf -v "$rcvar" '%s' "$command_rc"
}

validate_fixture_contract() {
  local fixture="$1" label
  label="$(json_get_file "$fixture" '.fixture')"
  assert_jq_file "fixture $label has expected assertion contract" "$fixture" '
    (.fixture | type == "string" and length > 0)
    and (.source_ref | type == "string" and length > 0)
    and (.case_id | type == "string" and length > 0)
    and (.draft_question | type == "string" and length > 0)
    and (.signals | type == "object")
    and (.expected | type == "object")
    and (.expected.violation | type == "boolean")
    and (
      if .expected.violation then
        .expected.code == "orch_question_when_data_clear"
      else
        ((.expected.override_reason // .expected.no_violation_reason) | type == "string" and length > 0)
      end
    )
  '
}

assert_check_matches_fixture() {
  local fixture="$1" label out rc expected_violation expected_status expected_code expected_allowed expected_gate
  label="$(json_get_file "$fixture" '.fixture')"
  out="$TMP/$label.check.json"
  run_check "$fixture" "$out" rc

  expected_violation="$(json_get_file "$fixture" '.expected.violation')"
  expected_status="$(json_get_file "$fixture" '.expected.status // empty')"
  expected_code="$(json_get_file "$fixture" '.expected.code // empty')"
  expected_allowed="$(json_get_file "$fixture" '.expected.allowed_reason // empty')"
  expected_gate="$(json_get_file "$fixture" '.expected.gate_passes // empty')"

  if [[ "$expected_violation" == "true" && "$rc" -ne 1 ]]; then
    fail "fixture $label rc matches violation expectation" "expected rc=1 got $rc output=$(cat "$out") stderr=$(cat "$out.err")"
  fi
  if [[ "$expected_violation" == "false" && "$rc" -ne 0 ]]; then
    fail "fixture $label rc matches allow expectation" "expected rc=0 got $rc output=$(cat "$out") stderr=$(cat "$out.err")"
  fi
  pass "fixture $label rc matches expected outcome"

  jq -e --argjson expected "$expected_violation" '.violation == $expected' "$out" >/dev/null \
    && pass "fixture $label violation flag matches" \
    || fail "fixture $label violation flag matches" "output=$(cat "$out")"

  if [[ -n "$expected_status" ]]; then
    jq -e --arg expected "$expected_status" '.status == $expected' "$out" >/dev/null \
      && pass "fixture $label status matches" \
      || fail "fixture $label status matches" "output=$(cat "$out")"
  fi
  if [[ -n "$expected_code" ]]; then
    jq -e --arg expected "$expected_code" '.code == $expected' "$out" >/dev/null \
      && pass "fixture $label code matches" \
      || fail "fixture $label code matches" "output=$(cat "$out")"
  fi
  if [[ -n "$expected_allowed" ]]; then
    jq -e --arg expected "$expected_allowed" '.allowed_reason == $expected' "$out" >/dev/null \
      && pass "fixture $label allowed_reason matches" \
      || fail "fixture $label allowed_reason matches" "output=$(cat "$out")"
  fi
  if [[ -n "$expected_gate" ]]; then
    jq -e --argjson expected "$expected_gate" '.gate.passes == $expected' "$out" >/dev/null \
      && pass "fixture $label gate expectation matches" \
      || fail "fixture $label gate expectation matches" "output=$(cat "$out")"
  fi
}

assert_receipt_roundtrip() {
  local fixture="$1" label receipt_kind now save_log override_log out rc=0
  label="$(json_get_file "$fixture" '.fixture')"
  receipt_kind="$(json_get_file "$fixture" '.expected.receipt // empty')"
  now="2026-05-07T01:00:00Z"

  case "$receipt_kind" in
    save)
      save_log="$TMP/$label.save.jsonl"
      out="$TMP/$label.save.out"
      set +e
      FLYWHEEL_DATA_BACKED_DEFERRAL_NOW="$now" "$FLYWHEEL_LOOP_BIN" data-backed-deferral-check \
        --signals "$fixture" \
        --json \
        --record-save \
        --save-log "$save_log" >"$out" 2>"$out.err"
      rc=$?
      set -e
      [[ "$rc" -eq 1 ]] || fail "fixture $label save receipt exits with violation" "rc=$rc output=$(cat "$out")"
      [[ "$(line_count "$save_log")" == "1" ]] || fail "fixture $label save receipt writes one row" "rows=$(line_count "$save_log")"
      assert_jq_file "fixture $label save receipt row schema" "$save_log" \
        'select(.event=="data_backed_deferral_prevented") | .ts and .session and .draft_question and .suggested_action and (.signals_aligned | length >= 3)'
      jq -e '.save_row_written == true and .save_duplicate_suppressed == false' "$out" >/dev/null \
        && pass "fixture $label save command receipt reports write" \
        || fail "fixture $label save command receipt reports write" "output=$(cat "$out")"
      ;;
    override)
      override_log="$TMP/$label.override.jsonl"
      out="$TMP/$label.override.out"
      FLYWHEEL_DATA_BACKED_DEFERRAL_NOW="$now" "$FLYWHEEL_LOOP_BIN" data-backed-deferral-check \
        --signals "$fixture" \
        --json \
        --record-override \
        --override-log "$override_log" >"$out" 2>"$out.err"
      [[ "$(line_count "$override_log")" == "1" ]] || fail "fixture $label override receipt writes one row" "rows=$(line_count "$override_log") output=$(cat "$out")"
      assert_jq_file "fixture $label override receipt row schema" "$override_log" \
        'select(.event=="data_backed_deferral_override" and (.reason | IN("evidence_missing","cost","source_scope","reject_revert","require_confirm","live_prod","tie_between"))) | .ts and .session and .details and .signals'
      jq -e '.status == "ok" and .override_row_written == true' "$out" >/dev/null \
        && pass "fixture $label override command receipt reports write" \
        || fail "fixture $label override command receipt reports write" "output=$(cat "$out")"
      ;;
    "")
      pass "fixture $label has no receipt roundtrip requirement"
      ;;
    *)
      fail "fixture $label receipt kind is known" "unexpected receipt=$receipt_kind"
      ;;
  esac
}

run_tick_fixture() {
  local fixture="$1" out="$2" save_log="$3" override_log="$4"
  FLYWHEEL_LOOP_TICK_TEST_DATA_BACKED_DEFERRAL=1 \
  FLYWHEEL_DATA_BACKED_DEFERRAL_TICK_FIXTURE="$fixture" \
  FLYWHEEL_DATA_BACKED_DEFERRAL_NOW="2026-05-07T02:00:00Z" \
  FLYWHEEL_DEFERRAL_SAVE_LOG="$save_log" \
  FLYWHEEL_DEFERRAL_OVERRIDE_LOG="$override_log" \
    "$FLYWHEEL_LOOP_TICK" >"$out" 2>"$out.err"
}

assert_tick_rewrite_fixture() {
  local fixture="$FIXTURES/l94-wave10-question-violation.json" out="$TMP/tick-rewrite.json" save_log="$TMP/tick-rewrite.save.jsonl" override_log="$TMP/tick-rewrite.override.jsonl"
  run_tick_fixture "$fixture" "$out" "$save_log" "$override_log"
  jq -e '
    .event == "orch_question_when_data_clear"
    and .status == "violation"
    and .code == "orch_question_when_data_clear"
    and .soft_violation == true
    and .rewrite_path == true
    and .tick_action == "rewrite_to_data_implied_action"
    and .selected_action_source == "pagerank_pick"
    and (.rewrite_action | type == "string" and length > 0)
  ' "$out" >/dev/null \
    && pass "tick fixture rewrites question into data-backed action" \
    || fail "tick fixture rewrites question into data-backed action" "output=$(cat "$out") stderr=$(cat "$out.err")"
  [[ "$(line_count "$save_log")" == "1" ]] && pass "tick rewrite writes save receipt" || fail "tick rewrite writes save receipt" "rows=$(line_count "$save_log") output=$(cat "$out")"
}

assert_tick_allow_fixture() {
  local fixture="$FIXTURES/ambiguous-tie-allow.json" out="$TMP/tick-allow.json" save_log="$TMP/tick-allow.save.jsonl" override_log="$TMP/tick-allow.override.jsonl"
  run_tick_fixture "$fixture" "$out" "$save_log" "$override_log"
  jq -e '
    .event == "orch_question_allowed_with_evidence"
    and .status == "ok"
    and .allowed_reason == "tie_between"
    and .soft_violation == false
    and .rewrite_path == false
    and .tick_action == "allow_question_with_evidence"
  ' "$out" >/dev/null \
    && pass "tick allow fixture preserves evidence-backed question" \
    || fail "tick allow fixture preserves evidence-backed question" "output=$(cat "$out") stderr=$(cat "$out.err")"
  [[ "$(line_count "$override_log")" == "1" ]] && pass "tick allow writes override receipt" || fail "tick allow writes override receipt" "rows=$(line_count "$override_log") output=$(cat "$out")"
}

assert_tick_score_threshold_fixture() {
  local fixture="$TMP/tick-score-threshold.json" out="$TMP/tick-score-threshold.out.json" save_log="$TMP/tick-score-threshold.save.jsonl" override_log="$TMP/tick-score-threshold.override.jsonl"
  jq -nc '{
    fixture:"tick-score-threshold",
    source_ref:"flywheel-4hch-acceptance-gate-3",
    case_id:"tick-data-alignment-score",
    class:"tick-data-backed-deferral",
    session:"flywheel",
    pane:1,
    idle_worker_count:1,
    ready_bead_count:1,
    data_alignment_score:3,
    action_in_doctrine:true,
    pagerank_pick:"flywheel-next-pagerank",
    suggested_action:"dispatch flywheel-next-pagerank via canonical dispatch enforcement",
    draft_question:"Should I ask {operator} whether to dispatch flywheel-next-pagerank?",
    draft_text:"Should I ask {operator} whether to dispatch flywheel-next-pagerank?",
    signals:{
      idle_worker_count:1,
      ready_bead_count:1,
      data_alignment_score:3,
      action_in_doctrine:true,
      pagerank_pick:"flywheel-next-pagerank"
    }
  }' >"$fixture"
  run_tick_fixture "$fixture" "$out" "$save_log" "$override_log"
  jq -e '
    .event == "orch_question_when_data_clear"
    and .soft_violation == true
    and .rewrite_path == true
    and .data_alignment_score == 3
    and .selected_action_source == "pagerank_pick"
    and .suggested_action == "dispatch flywheel-next-pagerank via canonical dispatch enforcement"
  ' "$out" >/dev/null \
    && pass "tick score-threshold fixture proves data_alignment_score rewrite" \
    || fail "tick score-threshold fixture proves data_alignment_score rewrite" "output=$(cat "$out") stderr=$(cat "$out.err")"
}

command -v jq >/dev/null 2>&1 || { echo "missing jq" >&2; exit 69; }
[[ -x "$FLYWHEEL_LOOP_BIN" ]] || { echo "not executable: $FLYWHEEL_LOOP_BIN" >&2; exit 69; }
[[ -x "$FLYWHEEL_LOOP_TICK" ]] || { echo "not executable: $FLYWHEEL_LOOP_TICK" >&2; exit 69; }
test -d "$FIXTURES" && pass "fixture directory exists" || fail "fixture directory exists" "missing $FIXTURES"

fixture_files=()
while IFS= read -r fixture_path; do
  fixture_files+=("$fixture_path")
done < <(find "$FIXTURES" -maxdepth 1 -type f -name '*.json' | sort)
fixture_count="${#fixture_files[@]}"
[[ "$fixture_count" -ge 6 ]] && pass "fixture corpus has at least six json files" || fail "fixture corpus has at least six json files" "count=$fixture_count"
jq -e '.draft_question and .signals' "$FIXTURES"/*.json >/dev/null && pass "all fixtures expose draft_question and signals" || fail "all fixtures expose draft_question and signals" "jq acceptance failed"

for fixture in "${fixture_files[@]}"; do
  validate_fixture_contract "$fixture"
  assert_check_matches_fixture "$fixture"
  assert_receipt_roundtrip "$fixture"
done

dupe_log="$TMP/duplicate-save.jsonl"
dupe_fixture="$FIXTURES/row185-catch.json"
set +e
FLYWHEEL_DATA_BACKED_DEFERRAL_NOW="2026-05-07T00:10:00Z" "$FLYWHEEL_LOOP_BIN" data-backed-deferral-check \
  --signals "$dupe_fixture" \
  --json \
  --record-save \
  --save-log "$dupe_log" >"$TMP/dupe.first.out" 2>&1
first_rc=$?
FLYWHEEL_DATA_BACKED_DEFERRAL_NOW="2026-05-07T00:15:00Z" "$FLYWHEEL_LOOP_BIN" data-backed-deferral-check \
  --signals "$dupe_fixture" \
  --json \
  --record-save \
  --save-log "$dupe_log" >"$TMP/dupe.second.out" 2>&1
second_rc=$?
set -e
[[ "$first_rc" -eq 1 && "$second_rc" -eq 1 ]] || fail "duplicate save still reports violation" "first=$first_rc second=$second_rc"
[[ "$(line_count "$dupe_log")" == "1" ]] && pass "duplicate save rows suppressed inside ten minutes" || fail "duplicate save rows suppressed inside ten minutes" "rows=$(line_count "$dupe_log")"
jq -e '.save_duplicate_suppressed == true and .save_row_written == false' "$TMP/dupe.second.out" >/dev/null \
  && pass "duplicate save command receipt reports suppression" \
  || fail "duplicate save command receipt reports suppression" "output=$(cat "$TMP/dupe.second.out")"

malformed_save_log="$TMP/malformed-save.jsonl"
printf '{malformed-json\n' >"$malformed_save_log"
set +e
FLYWHEEL_DATA_BACKED_DEFERRAL_NOW="2026-05-07T00:30:00Z" "$FLYWHEEL_LOOP_BIN" data-backed-deferral-check \
  --signals "$FIXTURES/ntm116-catch.json" \
  --json \
  --record-save \
  --save-log "$malformed_save_log" >"$TMP/malformed-save.out" 2>&1
malformed_save_rc=$?
set -e
[[ "$malformed_save_rc" -eq 1 ]] || fail "malformed save log is tolerated" "rc=$malformed_save_rc output=$(cat "$TMP/malformed-save.out")"
malformed_save_valid_line="$(tail -n 1 "$malformed_save_log")"
jq -e 'select(.event=="data_backed_deferral_prevented")' <<<"$malformed_save_valid_line" >/dev/null \
  && pass "malformed save log keeps appended valid row parseable" \
  || fail "malformed save log keeps appended valid row parseable" "content=$(cat "$malformed_save_log")"

assert_tick_rewrite_fixture
assert_tick_allow_fixture
assert_tick_score_threshold_fixture

printf '\nSummary: %s/%s passed; fixtures=%s\n' "$pass_count" "$check_count" "$fixture_count"
