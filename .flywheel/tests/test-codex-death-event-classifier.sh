#!/usr/bin/env bash
# test-codex-death-event-classifier.sh (AG3 for flywheel-b2zpg)
#
# Asserts:
#   1. H1 fixture (exit_code=0, stderr_byte_count=0) classifies as H1, no bead filed.
#   2. H2 fixture (exit_code=2, stderr_byte_count=137) classifies as H2.
#   3. H3 fixture (exit_code=1, stderr_byte_count=0) classifies as H3.
#   4. H4 fixture (exit_code=0, stderr_byte_count=42) classifies as H4 informational.
#   5. Idempotency: a second `run` finds 0 new rows (sha-keyed ledger).
#   6. validate / why / audit / doctor / health all return zero.
#   7. Malformed receipt is surfaced as `unclassifiable` and counted in errors.
#   8. introspection trio (info / examples / schema) all exit 0 and emit valid JSON.
#
# Bead-filing path is exercised with --no-bead-filing so the test does NOT
# mutate the real beads DB. The bead-filing branch logic is tested via
# json shape only (ledger row contains hypothesis but bead_filed=false).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
CLASSIFIER="$ROOT/.flywheel/scripts/codex-death-event-classifier.sh"
[[ -x "$CLASSIFIER" ]] || { echo "FAIL: classifier not executable: $CLASSIFIER" >&2; exit 1; }

TMP="$(mktemp -d -t test-codex-death-classifier.XXXXXX)"
trap 'find "$TMP" -mindepth 1 -delete 2>/dev/null; rmdir "$TMP" 2>/dev/null || true' EXIT

EV="$TMP/evidence"
LEDGER="$TMP/ledger.jsonl"
mkdir -p "$EV"

# --- fixtures ---
write_receipt() {
  local pid="$1" ts="$2" exit_code="$3" stderr_bytes="$4" label="$5"
  local path="$EV/exit_evidence-${pid}-${ts}.json"
  jq -nc \
    --arg sv "codex-deathtrap-launcher.v1" \
    --arg ts "$ts" \
    --arg label "$label" \
    --arg host "test-host" \
    --arg stderr_log "$EV/stderr-${pid}-${ts}.log" \
    --arg exit_receipt "$path" \
    --arg args_log "$EV/args-${pid}-${ts}.txt" \
    --argjson pid "$pid" \
    --argjson exit_code "$exit_code" \
    --argjson stderr_bytes "$stderr_bytes" \
    '{schema_version:$sv, ts:$ts, label:$label, host:$host,
      pid:$pid, codex_exit_code:$exit_code,
      stderr_byte_count:$stderr_bytes,
      last_stderr_lines:[],
      last_zsh_history_cmd:null,
      parent_pane_id:null,
      evidence_paths:{stderr_log:$stderr_log, exit_receipt:$exit_receipt, args_log:$args_log}}' > "$path"
  printf '%s\n' "$path"
}

P_H1="$(write_receipt 1001 20260510T010000Z 0 0 fleet-death-experiment)"
P_H2="$(write_receipt 1002 20260510T010100Z 2 137 fleet-death-experiment)"
P_H3="$(write_receipt 1003 20260510T010200Z 1 0 fleet-death-experiment)"
P_H4="$(write_receipt 1004 20260510T010300Z 0 42 fleet-death-experiment)"

fail=0
report_fail() { echo "FAIL[$1]: $2" >&2; fail=$((fail+1)); }

# --- (1) validate H1 ---
out_h1="$("$CLASSIFIER" validate "$P_H1" --json)"
hyp_h1="$(jq -r .hypothesis <<<"$out_h1")"
[[ "$hyp_h1" == "H1_silent_clean_exit" ]] || report_fail 1 "expected H1_silent_clean_exit got $hyp_h1"

# --- (2) validate H2 ---
out_h2="$("$CLASSIFIER" validate "$P_H2" --json)"
hyp_h2="$(jq -r .hypothesis <<<"$out_h2")"
[[ "$hyp_h2" == "H2_real_error_with_stderr" ]] || report_fail 2 "expected H2_real_error_with_stderr got $hyp_h2"

# --- (3) validate H3 ---
out_h3="$("$CLASSIFIER" validate "$P_H3" --json)"
hyp_h3="$(jq -r .hypothesis <<<"$out_h3")"
[[ "$hyp_h3" == "H3_tmux_misreport" ]] || report_fail 3 "expected H3_tmux_misreport got $hyp_h3"

# --- (4) validate H4 ---
out_h4="$("$CLASSIFIER" validate "$P_H4" --json)"
hyp_h4="$(jq -r .hypothesis <<<"$out_h4")"
[[ "$hyp_h4" == "H4_warn_but_successful" ]] || report_fail 4 "expected H4_warn_but_successful got $hyp_h4"

# --- (5) run (apply, --no-bead-filing) processes all 4 ---
run1="$("$CLASSIFIER" run --evidence-dir "$EV" --ledger "$LEDGER" --json --no-bead-filing 2>/dev/null)"
new1="$(jq -r .new_classified <<<"$run1")"
[[ "$new1" == "4" ]] || report_fail 5 "first run expected new=4 got $new1"
ledger_count="$(wc -l <"$LEDGER" | tr -d ' ')"
[[ "$ledger_count" -eq 4 ]] || report_fail 5 "ledger expected 4 rows got $ledger_count"

# Idempotency: second run finds 0 new
run2="$("$CLASSIFIER" run --evidence-dir "$EV" --ledger "$LEDGER" --json --no-bead-filing 2>/dev/null)"
new2="$(jq -r .new_classified <<<"$run2")"
[[ "$new2" == "0" ]] || report_fail 5 "second run expected new=0 (idempotent) got $new2"
ledger_count_after="$(wc -l <"$LEDGER" | tr -d ' ')"
[[ "$ledger_count_after" -eq 4 ]] || report_fail 5 "ledger after second run expected 4 rows got $ledger_count_after"

# --- (6) audit + doctor + health + why ---
audit_out="$("$CLASSIFIER" audit --ledger "$LEDGER" --json)"
[[ "$(jq -r .total <<<"$audit_out")" == "4" ]] || report_fail 6 "audit total expected 4"
[[ "$(jq -r '.by_hypothesis.H1_silent_clean_exit' <<<"$audit_out")" == "1" ]] || report_fail 6 "audit H1 count expected 1"
[[ "$(jq -r '.by_hypothesis.H2_real_error_with_stderr' <<<"$audit_out")" == "1" ]] || report_fail 6 "audit H2 count expected 1"
[[ "$(jq -r '.by_hypothesis.H3_tmux_misreport' <<<"$audit_out")" == "1" ]] || report_fail 6 "audit H3 count expected 1"

doctor_out="$("$CLASSIFIER" doctor --evidence-dir "$EV" --ledger "$LEDGER" --json)"
[[ "$(jq -r .pending <<<"$doctor_out")" == "0" ]] || report_fail 6 "doctor pending expected 0"
[[ "$(jq -r .total_receipts <<<"$doctor_out")" == "4" ]] || report_fail 6 "doctor total_receipts expected 4"

health_out="$("$CLASSIFIER" health --evidence-dir "$EV" --ledger "$LEDGER" --json)"
[[ "$(jq -r .status <<<"$health_out")" == "ok" ]] || report_fail 6 "health status expected ok"

why_out="$("$CLASSIFIER" why "$P_H2" --json)"
[[ "$(jq -r .hypothesis <<<"$why_out")" == "H2_real_error_with_stderr" ]] || report_fail 6 "why hypothesis expected H2"
[[ "$(jq -r .reason <<<"$why_out")" == *"H2 real error"* ]] || report_fail 6 "why reason should mention H2 real error"

# --- (7) malformed receipt ---
EV2="$TMP/evidence-malformed"
LEDGER2="$TMP/ledger-malformed.jsonl"
mkdir -p "$EV2"
echo "this is not json" > "$EV2/exit_evidence-9999-20260510T020000Z.json"
set +e
malformed_out="$("$CLASSIFIER" run --evidence-dir "$EV2" --ledger "$LEDGER2" --json --no-bead-filing 2>/dev/null)"
malformed_rc=$?
set -e
[[ "$malformed_rc" -eq 4 ]] || report_fail 7 "malformed receipt expected rc=4 got rc=$malformed_rc"
[[ "$(jq -r .errors <<<"$malformed_out")" == "1" ]] || report_fail 7 "malformed errors expected 1"
[[ "$(jq -r '.rows[0].hypothesis' <<<"$malformed_out")" == "unclassifiable" ]] || report_fail 7 "malformed row should be unclassifiable"

# --- (8) introspection ---
"$CLASSIFIER" info | jq -e .version >/dev/null || report_fail 8 "info command should emit valid JSON with .version"
"$CLASSIFIER" examples | grep -q "EXAMPLES:" || report_fail 8 "examples command failed"
"$CLASSIFIER" schema | jq -e .title >/dev/null || report_fail 8 "schema command should emit valid JSON with .title"
"$CLASSIFIER" help | head -1 | grep -q "codex-death-event-classifier" || report_fail 8 "help should mention command name"

if [[ "$fail" -gt 0 ]]; then
  echo "FAIL: $fail assertion(s) failed" >&2
  exit 1
fi
echo "PASS test-codex-death-event-classifier (8 assertion groups, 4 hypotheses + idempotency + introspection)"
exit 0
