#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/state-store-authority-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/state-store-authority.XXXXXX")"
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
    printf 'expr=%s file=%s\n' "$expr" "$file" >&2
    jq . "$file" >&2 || cat "$file" >&2
  fi
}

write_registry() {
  local path="$1" mode="$2" root="$3"
  mkdir -p "$root/.flywheel/receipts" "$root/.beads"
  printf 'source\n' >"$root/source.jsonl"
  printf 'mirror\n' >"$root/mirror.db"
  touch -t 202605080100 "$root/source.jsonl" "$root/mirror.db"
  case "$mode" in
    stale)
      touch -t 202605080200 "$root/source.jsonl"
      touch -t 202605080100 "$root/mirror.db"
      ;;
  esac
  jq -n --arg mode "$mode" '{
    schema_version:"flywheel-state-store-authority/v1",
    stores:[
      {
        id:"healthy",
        kind:"jsonl_append_only_ledger",
        authority:"jsonl_source",
        source_path:"source.jsonl",
        derived_mirrors:[{path:"mirror.db",freshness_source:"source.jsonl"}],
        backup_path:"receipts/backup.json",
        migration_command:"migrate --dry-run --json",
        integrity_probe_command:"probe --json",
        repair_command:"repair --dry-run --json",
        repair_contract:{
          dry_run_command:"repair --dry-run --json",
          apply_command:"repair --apply --json",
          receipt_path:"receipts/repair.jsonl",
          append_only_ledgers_never_truncated:["source.jsonl","receipts/repair.jsonl"]
        }
      }
    ]
  }
  | if $mode == "missing_backup" then del(.stores[0].backup_path)
    elif $mode == "missing_migration" then del(.stores[0].migration_command)
    elif $mode == "failed_integrity" then .stores[0].integrity_probe_status="fail" | .stores[0].integrity_probe_detail="fixture failure"
    else . end' >"$path"
}

chmod +x "$SCRIPT"
bash -n "$SCRIPT" && pass "01_script_syntax" || fail "01_script_syntax"

"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "state-store-authority-probe.sh" and (.canonical_cli_surfaces | index("repair")) and .mutation_requires == "repair --apply"' "02_info_canonical_cli_surface"

healthy_root="$TMP/healthy-root"; mkdir -p "$healthy_root"
write_registry "$TMP/healthy.json" healthy "$healthy_root"
"$SCRIPT" validate --root "$healthy_root" --registry "$TMP/healthy.json" --json >"$TMP/healthy.out"
assert_jq "$TMP/healthy.out" '.status == "pass" and .store_count == 1 and (.summary.fail == 0) and (.stores[0].repair_contract.append_only_ledgers_never_truncated | length) == 2' "03_healthy_authority_row_passes"

write_registry "$TMP/missing-backup.json" missing_backup "$healthy_root"
"$SCRIPT" validate --root "$healthy_root" --registry "$TMP/missing-backup.json" --json >"$TMP/missing-backup.out" || true
assert_jq "$TMP/missing-backup.out" '.status == "warn" and any(.checks[]; .check == "backup_path_declared" and .status == "warn")' "04_missing_backup_warns"

write_registry "$TMP/missing-migration.json" missing_migration "$healthy_root"
"$SCRIPT" validate --root "$healthy_root" --registry "$TMP/missing-migration.json" --json >"$TMP/missing-migration.out" || true
assert_jq "$TMP/missing-migration.out" '.status == "warn" and any(.checks[]; .check == "migration_command_declared" and .status == "warn")' "05_missing_migration_warns"

stale_root="$TMP/stale-root"; mkdir -p "$stale_root"
write_registry "$TMP/stale.json" stale "$stale_root"
"$SCRIPT" validate --root "$stale_root" --registry "$TMP/stale.json" --json >"$TMP/stale.out" || true
assert_jq "$TMP/stale.out" '.status == "warn" and any(.checks[]; .check == "derived_mirror_freshness" and .status == "warn" and (.detail.stale_mirrors | index("mirror.db")))' "06_stale_mirror_warns"

write_registry "$TMP/failed-integrity.json" failed_integrity "$healthy_root"
"$SCRIPT" validate --root "$healthy_root" --registry "$TMP/failed-integrity.json" --json >"$TMP/failed-integrity.out" || true
assert_jq "$TMP/failed-integrity.out" '.status == "fail" and any(.checks[]; .check == "integrity_probe_status" and .status == "fail")' "07_failed_integrity_probe_fails"

ledger="$TMP/authority-repair.jsonl"
"$SCRIPT" repair --root "$healthy_root" --registry "$TMP/healthy.json" --ledger "$ledger" --dry-run --json >"$TMP/repair-dry.out"
assert_jq "$TMP/repair-dry.out" '.status == "planned" and .dry_run == true and .append_only_ledgers_never_truncated == true and (.planned_actions | length) == 1 and (.actual_actions | length) == 0' "08_repair_dry_run_receipt_shape"
[[ ! -e "$ledger" ]] && pass "09_repair_dry_run_does_not_write_ledger" || fail "09_repair_dry_run_does_not_write_ledger"

before_sha="$(shasum -a 256 "$healthy_root/source.jsonl" | awk '{print $1}')"
"$SCRIPT" repair --root "$healthy_root" --registry "$TMP/healthy.json" --ledger "$ledger" --apply --json >"$TMP/repair-apply.out"
after_sha="$(shasum -a 256 "$healthy_root/source.jsonl" | awk '{print $1}')"
assert_jq "$TMP/repair-apply.out" '.status == "applied" and .dry_run == false and (.actual_actions | index("append_state_store_authority_repair_receipt"))' "10_repair_apply_receipt_shape"
[[ "$before_sha" == "$after_sha" ]] && pass "11_apply_never_truncates_append_only_source" || fail "11_apply_never_truncates_append_only_source"
assert_jq "$ledger" '.schema_version == "state-store-authority.repair.v1" and .append_only_ledgers_never_truncated == true' "12_apply_appends_repair_ledger"

"$SCRIPT" why healthy --root "$healthy_root" --registry "$TMP/healthy.json" --json >"$TMP/why.out"
assert_jq "$TMP/why.out" '.command == "why" and .match.id == "healthy"' "13_why_explains_store"

"$SCRIPT" schema result --json >"$TMP/schema.out"
assert_jq "$TMP/schema.out" '.schema_version == "state-store-authority.result.schema.v1"' "14_schema_result"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$pass_count" -eq 14 && "$fail_count" -eq 0 ]]
