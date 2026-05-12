#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/ntm-checkpoint-rollback-guard.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-checkpoint-rollback.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

run_case() {
  local name="$1"
  shift
  local out="$TMP/$name.json"
  local rc=0
  set +e
  "$SCRIPT" "$@" --json >"$out"
  rc=$?
  set -e
  printf '%s\n' "$rc" >"$TMP/$name.rc"
  printf '%s\n' "$out"
}

make_repo() {
  local repo="$1"
  mkdir -p "$repo"
  git -C "$repo" init -q
  printf 'base\n' >"$repo/base.txt"
  git -C "$repo" add base.txt
  git -C "$repo" -c user.name=fixture -c user.email=fixture@example.invalid commit -qm initial
}

repo="$TMP/repo"
checkpoint_dir="$TMP/checkpoints"
ledger="$TMP/rollback-receipts.jsonl"
make_repo "$repo"

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"
bash -n "$0" && pass "test_syntax" || fail "test_syntax"

info_out="$(run_case info info)"
assert_jq "$info_out" '.status == "ok" and .name == "ntm-checkpoint-rollback-guard" and .l112_observed == "OK_ntm_migrate_W3bR"' "info_json_contract"
assert_jq "$info_out" '.canonical_cli.doctor == true and .canonical_cli.repair == true and .canonical_cli.audit == true and .canonical_cli.apply_requires_idempotency_key == true' "canonical_cli_surface"

schema_out="$(run_case schema schema)"
assert_jq "$schema_out" '.checkpoint_save_dry_run_claim == "forbidden" and .default_mode == "dry-run" and (.preview_surfaces | index("verify"))' "schema_documents_preview_only_checkpoint"

doctor_out="$(run_case doctor doctor --repo "$repo" --checkpoint-dir "$checkpoint_dir" --ledger "$ledger")"
assert_jq "$doctor_out" '.status == "pass" and .checks.rollback_execution_refused == true' "doctor_reports_refusal_guard"

dry_checkpoint="$(run_case dry-checkpoint checkpoint --repo "$repo" --checkpoint-dir "$checkpoint_dir" --checkpoint-id fixture --dry-run)"
assert_jq "$dry_checkpoint" '.status == "pass" and .checkpoint_written == false and .checkpoint_save_dry_run_claim == false' "checkpoint_dry_run_no_save_claim"
test ! -e "$checkpoint_dir/fixture.json" && pass "checkpoint_dry_run_writes_no_file" || fail "checkpoint_dry_run_writes_no_file"

apply_no_key="$(run_case apply-no-key checkpoint --repo "$repo" --checkpoint-dir "$checkpoint_dir" --checkpoint-id fixture --apply)"
[[ "$(cat "$TMP/apply-no-key.rc")" == "2" ]] && pass "checkpoint_apply_requires_key_exit_2" || fail "checkpoint_apply_requires_key_exit_2"
assert_jq "$apply_no_key" '.status == "fail" and .reason_code == "missing_idempotency_key"' "checkpoint_apply_requires_key_json"

checkpoint_out="$(run_case checkpoint checkpoint --repo "$repo" --checkpoint-dir "$checkpoint_dir" --checkpoint-id fixture --apply --idempotency-key fixture-key)"
assert_jq "$checkpoint_out" '.status == "pass" and .checkpoint_written == true and .checkpoint.metadata_sha256 and .checkpoint.rollback_execution_authorized == false' "checkpoint_apply_writes_metadata"
test -s "$checkpoint_dir/fixture.json" && pass "checkpoint_file_exists" || fail "checkpoint_file_exists"

verify_out="$(run_case verify verify --repo "$repo" --checkpoint-file "$checkpoint_dir/fixture.json")"
assert_jq "$verify_out" '.status == "pass" and .reason_code == "checkpoint_hash_verified" and .preview_only == true' "verify_hash_passes"

list_out="$(run_case list list --checkpoint-dir "$checkpoint_dir")"
assert_jq "$list_out" '.status == "pass" and (.checkpoints | length) == 1 and .checkpoints[0].valid == true' "list_previews_checkpoint"

printf 'dirty\n' >"$repo/unrelated.tmp"
dirty_out="$(run_case dirty-rollback rollback --repo "$repo" --checkpoint-file "$checkpoint_dir/fixture.json" --ledger "$ledger" --idempotency-key dirty-key --dry-run)"
[[ "$(cat "$TMP/dirty-rollback.rc")" == "1" ]] && pass "dirty_unscoped_exit_1" || fail "dirty_unscoped_exit_1"
assert_jq "$dirty_out" '.status == "refused" and .reason_code == "dirty_worktree_unscoped" and .dirty_scope.all_dirty_paths_preserved == false and .rollback_executed == false' "dirty_untracked_unrelated_blocks_rollback"
test ! -e "$ledger" && pass "rollback_dry_run_writes_no_receipt" || fail "rollback_dry_run_writes_no_receipt"

scoped_out="$(run_case scoped-rollback rollback --repo "$repo" --checkpoint-file "$checkpoint_dir/fixture.json" --ledger "$ledger" --idempotency-key scoped-key --preserve-path unrelated.tmp --apply)"
[[ "$(cat "$TMP/scoped-rollback.rc")" == "1" ]] && pass "scoped_rollback_refuses_execution_exit_1" || fail "scoped_rollback_refuses_execution_exit_1"
assert_jq "$scoped_out" '.status == "refused" and .reason_code == "rollback_execution_refused" and .dirty_scope.all_dirty_paths_preserved == true and .receipt_written == true and .receipt.rollback_executed == false and .receipt.git_mutation_performed == false' "scoped_dirty_still_refuses_execution_but_receipts"
[[ "$(wc -l <"$ledger" | tr -d ' ')" == "1" ]] && pass "receipt_appended_once" || fail "receipt_appended_once"

duplicate_out="$(run_case duplicate rollback --repo "$repo" --checkpoint-file "$checkpoint_dir/fixture.json" --ledger "$ledger" --idempotency-key scoped-key --preserve-path unrelated.tmp --apply)"
[[ "$(cat "$TMP/duplicate.rc")" == "0" ]] && pass "duplicate_token_exit_zero" || fail "duplicate_token_exit_zero"
assert_jq "$duplicate_out" '.status == "stopped" and .reason_code == "duplicate_idempotency_key" and .duplicate_suppressed == true and .receipt_written == false' "duplicate_token_suppressed"
[[ "$(wc -l <"$ledger" | tr -d ' ')" == "1" ]] && pass "duplicate_writes_no_second_receipt" || fail "duplicate_writes_no_second_receipt"

missing_out="$(run_case missing rollback --repo "$repo" --checkpoint-file "$TMP/no-such-checkpoint.json" --ledger "$ledger" --idempotency-key missing-key --preserve-path unrelated.tmp --dry-run)"
[[ "$(cat "$TMP/missing.rc")" == "3" ]] && pass "missing_checkpoint_exit_3" || fail "missing_checkpoint_exit_3"
assert_jq "$missing_out" '.reason_code == "checkpoint_missing" and .checkpoint_valid == false' "missing_checkpoint_fails_closed"

tampered="$TMP/tampered-checkpoint.json"
cp "$checkpoint_dir/fixture.json" "$tampered"
jq '.git_head = "tampered"' "$tampered" >"$tampered.tmp" && mv "$tampered.tmp" "$tampered"
tampered_out="$(run_case tampered-case verify --checkpoint-file "$tampered")"
[[ "$(cat "$TMP/tampered-case.rc")" == "3" ]] && pass "tampered_checkpoint_exit_3" || fail "tampered_checkpoint_exit_3"
assert_jq "$tampered_out" '.reason_code == "checkpoint_hash_mismatch"' "tampered_checkpoint_hash_fails"

reservation_out="$(run_case reservation rollback --repo "$repo" --checkpoint-file "$checkpoint_dir/fixture.json" --ledger "$TMP/reservation.jsonl" --idempotency-key reservation-key --preserve-path unrelated.tmp --reservation-state expired --dry-run)"
[[ "$(cat "$TMP/reservation.rc")" == "1" ]] && pass "expired_reservation_exit_1" || fail "expired_reservation_exit_1"
assert_jq "$reservation_out" '.reason_code == "reservations_missing_or_expired" and .rollback_executed == false' "expired_reservation_blocks"

audit_out="$(run_case audit audit --checkpoint-dir "$checkpoint_dir" --ledger "$ledger")"
assert_jq "$audit_out" '.status == "pass" and .rollback_execution_rows == 0 and .rollback_execution_refused == true' "audit_passes_no_execution_rows"

repair_out="$(run_case repair repair --dry-run)"
assert_jq "$repair_out" '.status == "pass" and .source_mutated == false and (.cannot_repair | index("git reset"))' "repair_refuses_irreversible_actions"

why_out="$(run_case why why dirty-worktree)"
assert_jq "$why_out" '.status == "ok" and (.selected | test("git status --porcelain"))' "why_explains_dirty_worktree"

completion_out="$TMP/completion.bash"
"$SCRIPT" completion bash >"$completion_out"
rg -q 'complete -W' "$completion_out" && pass "completion_bash" || fail "completion_bash"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
