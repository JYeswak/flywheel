#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
VALIDATOR="$ROOT/.flywheel/scripts/callback-envelope-validator.sh"
VERIFY="$ROOT/.flywheel/scripts/worker-tick-contract-postcallback-verify.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/extended-callback-envelope.XXXXXX")"
ASSERTIONS=0

cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

fail() {
  printf 'ASSERTION FAILED: %s\n' "$1" >&2
  exit 1
}

pass() {
  ASSERTIONS=$((ASSERTIONS + 1))
}

assert_jq() {
  local json="$1" expr="$2" label="$3"
  jq -e "$expr" <<<"$json" >/dev/null || fail "$label"
  pass
}

assert_rc() {
  local expected="$1" got="$2" label="$3"
  [[ "$got" == "$expected" ]] || fail "$label expected=$expected got=$got"
  pass
}

v2_row="$(jq -nc '{schema_version:2,event:"worker_callback",task_id:"legacy-v2",commit:"abc1234",tests:"PASS"}')"
out="$("$VALIDATOR" --row-json "$v2_row" --json)"
assert_jq "$out" '.valid == true and .mode == "legacy_v2_backcompat"' "v2 row passes back-compat"

substrate_row="$(jq -nc '{
  schema_version:3,
  event:"worker_callback",
  task_id:"substrate-v3",
  close_class:"substrate_class",
  commit_sha:"abcdef12345",
  tests:"PASS",
  post_callback_worktree_removed:true,
  post_callback_branch_local_deleted:true,
  post_callback_stash_dropped:null,
  post_callback_main_ff_status:"ok",
  post_callback_auto_push_status:"ok",
  runtime_receipt_path:null,
  runtime_artifacts:{}
}')"
out="$("$VALIDATOR" --row-json "$substrate_row" --json)"
assert_jq "$out" '.valid == true and .close_class == "substrate_class"' "v3 substrate row passes"

runtime_missing="$(jq -nc '{
  schema_version:3,
  event:"worker_callback",
  task_id:"runtime-missing",
  close_class:"runtime_class",
  post_callback_main_ff_status:"ok",
  post_callback_auto_push_status:"ok",
  runtime_artifacts:{device:"iPhone"}
}')"
set +e
out="$("$VALIDATOR" --row-json "$runtime_missing" --json)"
rc=$?
set -e
assert_rc 1 "$rc" "runtime missing receipt fails"
assert_jq "$out" '.valid == false and (.reasons | index("runtime_receipt_path_required"))' "runtime missing receipt reason"

receipt="$TMP/runtime-receipt.json"
jq -nc '{build:"42",device:"iPhone 15",ios:"18.5",ts:"2026-05-20T06:00:00Z"}' >"$receipt"
runtime_ok="$(jq -nc --arg receipt "$receipt" '{
  schema_version:3,
  event:"worker_callback",
  task_id:"runtime-ok",
  close_class:"runtime_class",
  post_callback_worktree_removed:true,
  post_callback_branch_local_deleted:true,
  post_callback_stash_dropped:true,
  post_callback_main_ff_status:"ok",
  post_callback_auto_push_status:"swept",
  runtime_receipt_path:$receipt,
  runtime_artifacts:{build:"42",device:"iPhone 15",ios:"18.5",ts:"2026-05-20T06:00:00Z"}
}')"
out="$("$VALIDATOR" --row-json "$runtime_ok" --json)"
assert_jq "$out" '.valid == true and .close_class == "runtime_class"' "runtime row with populated receipt passes validator"

missing_close_class="$(jq -nc '{
  schema_version:3,
  event:"worker_callback",
  task_id:"missing-close-class",
  post_callback_main_ff_status:"ok",
  post_callback_auto_push_status:"ok"
}')"
set +e
out="$("$VALIDATOR" --row-json "$missing_close_class" --json)"
rc=$?
set -e
assert_rc 1 "$rc" "missing close_class fails validator"
assert_jq "$out" '.reasons | index("missing_or_invalid_close_class")' "missing close_class reason"

unfinished="$(jq -nc '{
  schema_version:3,
  event:"worker_callback",
  task_id:"unfinished-cleanup",
  close_class:"substrate_class",
  post_callback_worktree_removed:false,
  post_callback_branch_local_deleted:true,
  post_callback_stash_dropped:null,
  post_callback_main_ff_status:"ok",
  post_callback_auto_push_status:"blocked"
}')"
set +e
out="$("$VERIFY" --row-json "$unfinished" --repo "$TMP" --json)"
rc=$?
set -e
assert_rc 1 "$rc" "postcallback verifier blocks unfinished cleanup"
assert_jq "$out" '(.reasons | index("post_callback_worktree_removed_unfinished")) and (.reasons | index("auto_push_blocked"))' "unfinished cleanup reasons"

mixed="$TMP/mixed.jsonl"
{
  printf '%s\n' "$v2_row"
  printf '%s\n' "$substrate_row"
  printf '%s\n' "$runtime_ok"
} >"$mixed"
while IFS= read -r row; do
  "$VALIDATOR" --row-json "$row" --json >/dev/null
done <"$mixed"
pass

out1="$("$VALIDATOR" --row-json "$runtime_ok" --json)"
out2="$("$VALIDATOR" --row-json "$runtime_ok" --json)"
[[ "$out1" == "$out2" ]] || fail "re-validation envelope changed"
pass

out="$("$VERIFY" --row-json "$runtime_ok" --repo "$TMP" --json)"
assert_jq "$out" '.ok == true and .exit_code == 0' "postcallback verifier passes runtime receipt"

undeclared="$(jq -nc '{schema_version:3,event:"worker_callback",task_id:"undeclared"}')"
set +e
"$VERIFY" --row-json "$undeclared" --repo "$TMP" --json >"$TMP/undeclared.json"
rc=$?
set -e
assert_rc 2 "$rc" "postcallback verifier close_class undeclared exits 2"

printf 'PASS extended-callback-envelope-smoke assertions=%s\n' "$ASSERTIONS"
