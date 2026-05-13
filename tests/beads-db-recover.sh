#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/beads-db-recover.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/beads-db-recover-test.XXXXXX")"
BR_BIN="${BEADS_DB_RECOVER_BR_BIN:-$(command -v br || printf '$HOME/.cargo/bin/br')}"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || cat "$file" >&2
  fi
}

hash_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

make_repo() {
  local repo="$1"
  mkdir -p "$repo"
  git -C "$repo" init -q
  (cd "$repo" && "$BR_BIN" init --prefix jnc --json >/dev/null)
  (cd "$repo" && "$BR_BIN" create "alpha" -t task -p 2 --json >/dev/null)
  (cd "$repo" && "$BR_BIN" create "beta" -t task -p 2 --json >/dev/null)
  (cd "$repo" && "$BR_BIN" sync --flush-only --json >/dev/null)
}

corrupt_db() {
  local db="$1"
  printf 'X' | dd of="$db" bs=1 seek=100 conv=notrunc >/dev/null 2>&1
  if [[ "$(sqlite3 "$db" 'PRAGMA integrity_check;' 2>&1 || true)" == "ok" ]]; then
    printf 'Y' | dd of="$db" bs=1 seek=4096 conv=notrunc >/dev/null 2>&1
  fi
  [[ "$(sqlite3 "$db" 'PRAGMA integrity_check;' 2>&1 || true)" != "ok" ]]
}

run_script() {
  env \
    BEADS_DB_RECOVER_LEDGER="$TMP/beads-recovery.jsonl" \
    BEADS_DB_RECOVER_CONTRACT_LEDGER="$TMP/substrate-loop-contract.jsonl" \
    BEADS_DB_RECOVER_NOW="2026-05-05T04:10:00Z" \
    BEADS_DB_RECOVER_BR_BIN="$BR_BIN" \
    "$SCRIPT" "$@"
}

bash -n "$SCRIPT" && pass "script_syntax"

"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "beads-db-recover.sh" and (.canonical_cli_surfaces | index("doctor")) and .mutation_requires == "--apply"' "info_canonical_cli_surface"

repo_dry="$TMP/repo-dry"
make_repo "$repo_dry"
corrupt_db "$repo_dry/.beads/beads.db"
before_hash="$(hash_file "$repo_dry/.beads/beads.db")"
run_script --repo "$repo_dry" --dry-run --json >"$TMP/dry-run.json"
after_hash="$(hash_file "$repo_dry/.beads/beads.db")"
if [[ "$before_hash" == "$after_hash" ]]; then pass "dry_run_does_not_mutate_db"; else fail "dry_run_does_not_mutate_db"; fi
assert_jq "$TMP/dry-run.json" '.dry_run == true and (.planned_actions | length) == 9 and (.would_delete | length) == 0' "dry_run_plan_shape"

repo_apply="$TMP/repo-apply"
make_repo "$repo_apply"
repo_apply_abs="$(cd "$repo_apply" && pwd -P)"
corrupt_db "$repo_apply/.beads/beads.db"
run_script --repo "$repo_apply" --apply --force --json >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.status == "pass" and .success == true and .step_completed == 9 and .integrity_check_post == "ok" and (.backup_path | test("beads.db.bak."))' "apply_recovery_succeeds"
test -f "$(jq -r '.backup_path' "$TMP/apply.json")" && pass "backup_preserved" || fail "backup_preserved"
sqlite3 "$repo_apply/.beads/beads.db" 'PRAGMA integrity_check;' | grep -qx ok && pass "post_integrity_ok" || fail "post_integrity_ok"
(cd "$repo_apply" && "$BR_BIN" ready --json >/dev/null && "$BR_BIN" dep cycles --json >/dev/null) && pass "br_smoke_operations_pass" || fail "br_smoke_operations_pass"

assert_jq "$TMP/beads-recovery.jsonl" 'select(.repo == "'"$repo_apply_abs"'" and .success == true and .step_completed == 9)' "ledger_success_row_written"
run_script --repo "$repo_apply" --doctor --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.schema_version | startswith("beads-db-recover")' "doctor_schema_version"
assert_jq "$TMP/doctor.json" '.beads_db_recovery_last_24h_count >= 1 and .beads_db_integrity_check_status == "ok" and has("beads_db_recovery_last_ts")' "doctor_fields_present"

repo_missing="$TMP/repo-missing-jsonl"
mkdir -p "$repo_missing/.beads"
sqlite3 "$repo_missing/.beads/beads.db" 'create table fixture(id integer);'
set +e
run_script --repo "$repo_missing" --apply --force --json >"$TMP/missing-jsonl.json"
missing_rc=$?
set -e
if [[ "$missing_rc" -ne 0 ]]; then pass "missing_jsonl_edge_fails"; else fail "missing_jsonl_edge_fails"; fi
assert_jq "$TMP/missing-jsonl.json" '.reason == "no_jsonl_to_sync_from"' "missing_jsonl_reason"

repo_locked="$TMP/repo-locked"
make_repo "$repo_locked"
corrupt_db "$repo_locked/.beads/beads.db"
touch "$repo_locked/.beads/.lock"
set +e
run_script --repo "$repo_locked" --apply --json >"$TMP/locked.json"
locked_rc=$?
set -e
if [[ "$locked_rc" -ne 0 ]]; then pass "locked_db_edge_halts"; else fail "locked_db_edge_halts"; fi
assert_jq "$TMP/locked.json" '.reason == "active_lock" and .status == "blocked"' "locked_db_reason"

run_script repair --scope substrate-contract --apply --json >"$TMP/contract-repair.json"
assert_jq "$TMP/contract-repair.json" '.status == "pass" and .row.primitive_name == "beads-db-recover"' "contract_repair_appends_self_row"

if [[ "$fail_count" -eq 0 ]]; then
  printf 'PASS tests=%s failures=0\n' "$pass_count"
else
  printf 'FAIL tests=%s failures=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
