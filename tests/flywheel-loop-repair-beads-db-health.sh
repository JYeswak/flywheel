#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-loop-repair-beads-db-health.XXXXXX")"
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
    jq . "$file" >&2 || cat "$file" >&2
  fi
}

make_repo() {
  local repo="$1"
  mkdir -p "$repo/.beads"
  git init -q "$repo"
  git -C "$repo" config user.email fixture@example.invalid
  git -C "$repo" config user.name "Fixture"
  printf '{"id":"flywheel-fixture","title":"fixture","status":"open","created_at":"2026-05-19T00:00:00Z","updated_at":"2026-05-19T00:00:00Z"}\n' >"$repo/.beads/issues.jsonl"
  printf 'stale-db\n' >"$repo/.beads/beads.db"
  git -C "$repo" add .beads/issues.jsonl
  git -C "$repo" commit -q -m init
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
      printf '{"workspace_health":"unsafe","errors":[{"code":"sqlite_database_corrupt"}]}\n'
      exit 1
    fi
    printf '{"workspace_health":"ok","errors":[]}\n'
    ;;
  *) printf '{}\n' ;;
esac
SH
chmod +x "$fake_br"

"$BIN" repair --list-scopes --json >"$TMP/scopes.json"
assert_jq "$TMP/scopes.json" '.scopes == ["beads-db-health"]' "list_scopes_includes_beads_db_health"

repo_dry="$TMP/repo-dry"
make_repo "$repo_dry"
set +e
FAKE_BR_COUNT="$TMP/count-dry" BEADS_AUTO_REBUILD_BR_BIN="$fake_br" \
  "$BIN" repair --scope=beads-db-health --repo="$repo_dry" --dry-run --json >"$TMP/dry.json" 2>"$TMP/dry.err"
rc=$?
set -e
[[ "$rc" -eq 0 ]] && pass "dry_run_exit_zero" || fail "dry_run_exit_zero"
[[ ! -s "$TMP/dry.err" ]] && pass "dry_run_json_stdout_only" || fail "dry_run_json_stdout_only"
assert_jq "$TMP/dry.json" '.command == "repair" and .scope == "beads-db-health" and .mode == "dry_run"' "dry_run_shape"
assert_jq "$TMP/dry.json" '.planned_actions[0].status != "SKIPPED" and (.planned_actions[0].reason? // "" | contains("no bounded repair registered") | not)' "dry_run_bounded_action"
assert_jq "$TMP/dry.json" '.helper.action == "would_rebuild_from_jsonl"' "dry_run_routes_to_rebuild_helper"

set +e
"$BIN" repair --scope INVALID_SCOPE --dry-run --json >"$TMP/invalid.out" 2>"$TMP/invalid.err"
rc=$?
set -e
[[ "$rc" -ne 0 ]] && pass "invalid_scope_nonzero" || fail "invalid_scope_nonzero"
[[ ! -s "$TMP/invalid.out" ]] && pass "invalid_scope_stdout_empty" || fail "invalid_scope_stdout_empty"
grep -q "unknown repair scope" "$TMP/invalid.err" && pass "invalid_scope_stderr_message" || fail "invalid_scope_stderr_message"

set +e
"$BIN" repair --scope beads-db-health --repo "$repo_dry" --apply --json >"$TMP/no-key.out" 2>"$TMP/no-key.err"
rc=$?
set -e
[[ "$rc" -eq 3 ]] && pass "apply_requires_idempotency_key" || fail "apply_requires_idempotency_key"

repo_apply="$TMP/repo-apply"
make_repo "$repo_apply"
FAKE_BR_COUNT="$TMP/count-apply" BEADS_AUTO_REBUILD_BR_BIN="$fake_br" BEADS_AUTO_REBUILD_LEDGER="$TMP/rebuild-ledger.jsonl" \
  "$BIN" repair --scope beads-db-health --repo "$repo_apply" --apply --idempotency-key test-key --json >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.mode == "apply" and .actual_actions[0].status == "APPLIED" and .helper.recovered == true' "apply_shape"
assert_jq "$TMP/rebuild-ledger.jsonl" 'select(.action == "rebuild_from_jsonl" and .recovered == true)' "apply_helper_ledger"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
