#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$HOME/.claude/skills/.flywheel/scripts/beads-auto-rebuild-from-jsonl.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/substrate-discipline-primitives.XXXXXX")"
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

make_repo() {
  local repo="$1"
  mkdir -p "$repo/.beads"
  git -C "$repo" init -q
  printf '{"id":"flywheel-fixture","title":"fixture","status":"open","created_at":"2026-05-07T00:00:00Z","updated_at":"2026-05-07T00:00:00Z"}\n' >"$repo/.beads/issues.jsonl"
  printf 'stale-db\n' >"$repo/.beads/beads.db"
  git -C "$repo" add .beads/issues.jsonl
  git -C "$repo" -c user.email=fixture@example.invalid -c user.name=fixture commit -m init >/dev/null
}

fake_br="$TMP/br"
cat >"$fake_br" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-} ${2:-}" in
  "doctor --json")
    count_file="${FAKE_BR_COUNT:?}"
    count=0
    [ -f "$count_file" ] && count="$(cat "$count_file")"
    count=$((count + 1))
    printf '%s\n' "$count" >"$count_file"
    if [ "$count" -eq 1 ]; then
      printf '{"workspace_health":"unsafe","errors":[{"code":"sqlite_database_missing"}]}\n'
      exit 1
    fi
    printf '{"workspace_health":"ok","errors":[]}\n'
    ;;
  *) printf '{}\n' ;;
esac
SH
chmod +x "$fake_br"

bash -n "$SCRIPT" && pass "auto_rebuild_syntax" || fail "auto_rebuild_syntax"
"$SCRIPT" --info >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "beads-auto-rebuild-from-jsonl.sh" and .mutation_requires == "--apply" and .class_1_6 == "none"' "auto_rebuild_info_contract"

repo_dry="$TMP/repo-dry"
make_repo "$repo_dry"
before_hash="$(shasum -a 256 "$repo_dry/.beads/beads.db" | awk '{print $1}')"
FAKE_BR_COUNT="$TMP/count-dry" BEADS_AUTO_REBUILD_BR_BIN="$fake_br" \
  "$SCRIPT" --repo "$repo_dry" --dry-run --json >"$TMP/dry.json"
after_hash="$(shasum -a 256 "$repo_dry/.beads/beads.db" | awk '{print $1}')"
assert_jq "$TMP/dry.json" '.action == "would_rebuild_from_jsonl" and .recovered == false and .jsonl_lines == 1 and .class_1_6 == "none"' "auto_rebuild_dry_run_shape"
if [ "$before_hash" = "$after_hash" ]; then pass "auto_rebuild_dry_run_no_mutation"; else fail "auto_rebuild_dry_run_no_mutation"; fi

repo_apply="$TMP/repo-apply"
make_repo "$repo_apply"
FAKE_BR_COUNT="$TMP/count-apply" BEADS_AUTO_REBUILD_BR_BIN="$fake_br" BEADS_AUTO_REBUILD_LEDGER="$TMP/ledger.jsonl" \
  "$SCRIPT" --repo "$repo_apply" --apply --json >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.action == "rebuild_from_jsonl" and .recovered == true and .doctor_health == "ok" and .jsonl_lines == 1' "auto_rebuild_apply_shape"
backup_path="$(jq -r '.backup_path' "$TMP/apply.json")"
test -d "$backup_path" && test -f "$backup_path/issues.jsonl" && pass "auto_rebuild_backup_preserved" || fail "auto_rebuild_backup_preserved"
test ! -e "$repo_apply/.beads/beads.db" && pass "auto_rebuild_db_removed" || fail "auto_rebuild_db_removed"
assert_jq "$TMP/ledger.jsonl" 'select(.action == "rebuild_from_jsonl" and .recovered == true)' "auto_rebuild_ledger_row"

printf 'OK_substrate_discipline_doctrine\n'
printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
