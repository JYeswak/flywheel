#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/bead-evidence-indexer.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/bead-evidence-indexer-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }
assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

repo="$TMP/repo"
home="$TMP/home"
state="$home/.local/state/flywheel"
tmp_evidence="$TMP/tmp"
mkdir -p "$repo/.flywheel" "$state" "$tmp_evidence"

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"

HOME="$home" "$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.schema_version == "bead-evidence-index/v1" and .default_mode == "dry-run" and (.commands | index("--doctor"))' "info_exposes_cli_contract"
HOME="$home" "$SCRIPT" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '(.statuses | index("indexed")) and .exit_codes."1" == "doctor found missing evidence"' "schema_exposes_statuses"

printf 'explicit evidence\n' >"$TMP/explicit.md"
cat >"$repo/.flywheel/dispatch-log.jsonl" <<JSONL
{"event":"closed","ts":"2026-05-07T01:00:00Z","bead_id":"flywheel-explicit","task_id":"task-explicit","evidence_path":"$TMP/explicit.md"}
{"event":"closed","ts":"2026-05-07T01:01:00Z","bead_id":"flywheel-scanme","task_id":"task-scanme"}
{"event":"closed","ts":"2026-05-07T01:02:00Z","bead_id":"flywheel-callback","task_id":"task-callback"}
JSONL
printf 'scanned evidence\n' >"$tmp_evidence/ntm-wire-in-W1-scanme-2026-05-07-evidence.md"
printf 'callback evidence\n' >"$tmp_evidence/callback-target.md"
printf 'DONE flywheel-callback task_id=task-callback evidence=%s tests=PASS\n' "$tmp_evidence/callback-target.md" >"$tmp_evidence/ntm-wire-in-W1-callback-2026-05-07-done-callback.txt"

HOME="$home" "$SCRIPT" --repo "$repo" --dispatch-log "$repo/.flywheel/dispatch-log.jsonl" --tmp-dir "$tmp_evidence" --json >"$TMP/dry.json"
assert_jq "$TMP/dry.json" '.mode == "dry-run" and .status_counts.would_index == 3' "dry_run_finds_three_candidates"
test ! -e "$state/bead-evidence-index.jsonl" && pass "dry_run_writes_nothing" || fail "dry_run_writes_nothing"

HOME="$home" "$SCRIPT" --repo "$repo" --dispatch-log "$repo/.flywheel/dispatch-log.jsonl" --tmp-dir "$tmp_evidence" --apply --json >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.mode == "apply" and .status_counts.indexed == 3' "apply_indexes_three"
test -f "$state/bead-evidence/flywheel-explicit.md" && pass "explicit_evidence_copied" || fail "explicit_evidence_copied"
test -f "$state/bead-evidence/flywheel-scanme.md" && pass "tmp_scan_evidence_copied" || fail "tmp_scan_evidence_copied"
test -f "$state/bead-evidence/flywheel-callback.md" && pass "callback_evidence_copied" || fail "callback_evidence_copied"
test "$(wc -l <"$state/bead-evidence-index.jsonl" | tr -d ' ')" = "3" && pass "index_has_three_rows" || fail "index_has_three_rows"

HOME="$home" "$SCRIPT" --repo "$repo" --dispatch-log "$repo/.flywheel/dispatch-log.jsonl" --tmp-dir "$tmp_evidence" --apply --json >"$TMP/reapply.json"
assert_jq "$TMP/reapply.json" '.status_counts.already_indexed == 3' "apply_is_idempotent"
test "$(wc -l <"$state/bead-evidence-index.jsonl" | tr -d ' ')" = "3" && pass "idempotent_index_unchanged" || fail "idempotent_index_unchanged"

callback_line="DONE flywheel-close task_id=task-close evidence=$TMP/explicit.md tests=PASS"
HOME="$home" "$SCRIPT" --repo "$repo" --callback "$callback_line" --apply --json >"$TMP/callback.json"
assert_jq "$TMP/callback.json" '.record_count == 1 and .status_counts.indexed == 1 and .rows[0].record_source == "callback"' "close_time_callback_indexes_directly"

set +e
HOME="$home" "$SCRIPT" --repo "$repo" --dispatch-log "$repo/.flywheel/dispatch-log.jsonl" --tmp-dir "$tmp_evidence" --doctor --json >"$TMP/doctor.json"
doctor_rc=$?
set -e
test "$doctor_rc" = "0" && pass "doctor_clean_exit_zero" || fail "doctor_clean_exit_zero"
assert_jq "$TMP/doctor.json" '.status == "ok" and .closed_records_observed == 3 and .indexed_count == 4' "doctor_reports_clean_index"

HOME="$home" "$SCRIPT" --repo "$repo" --dispatch-log "$repo/.flywheel/dispatch-log.jsonl" --tmp-dir "$tmp_evidence" --watch --max-cycles 1 --json >"$TMP/watch.json"
assert_jq "$TMP/watch.json" '.schema_version == "bead-evidence-index/v1" and .record_count == 3' "watch_one_cycle_scans"

if [ "$fail_count" -gt 0 ]; then
  printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'RESULT pass=%d fail=0\n' "$pass_count"
