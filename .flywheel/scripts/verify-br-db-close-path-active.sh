#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DB="$ROOT/.beads/beads.db"
JSONL="$ROOT/.beads/issues.jsonl"
probe_id=""

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

jsonl_hash() {
  shasum -a 256 "$JSONL" | awk '{print $1}'
}

db_issue_count() {
  sqlite3 "$DB" "SELECT count(*) FROM issues WHERE COALESCE(ephemeral, 0) = 0;"
}

jsonl_issue_count() {
  jq -r '.id' "$JSONL" | sort -u | wc -l | tr -d ' '
}

cleanup_probe() {
  [[ -n "${probe_id:-}" ]] || return 0
  case "$probe_id" in
    *[!A-Za-z0-9._-]*) return 1 ;;
  esac
  sqlite3 "$DB" "PRAGMA foreign_keys=OFF;
BEGIN;
DELETE FROM blocked_issues_cache WHERE issue_id = '$probe_id';
DELETE FROM export_hashes WHERE issue_id = '$probe_id';
DELETE FROM dirty_issues WHERE issue_id = '$probe_id';
DELETE FROM comments WHERE issue_id = '$probe_id';
DELETE FROM events WHERE issue_id = '$probe_id';
DELETE FROM labels WHERE issue_id = '$probe_id';
DELETE FROM dependencies WHERE issue_id = '$probe_id' OR depends_on_id = '$probe_id';
DELETE FROM child_counters WHERE parent_id = '$probe_id';
DELETE FROM issues WHERE id = '$probe_id';
COMMIT;"
}

trap cleanup_probe EXIT

cd "$ROOT"

[[ -f "$DB" ]] || fail "missing .beads/beads.db"
[[ -f "$JSONL" ]] || fail "missing .beads/issues.jsonl"

sqlite3 "$DB" "PRAGMA integrity_check;" | grep -qx "ok" || fail "integrity_check_not_ok"
sqlite3 "$DB" "PRAGMA quick_check;" | grep -qx "ok" || fail "quick_check_not_ok"
br --version >/dev/null 2>&1 || fail "br_version_failed"

before_hash="$(jsonl_hash)"
before_jsonl_count="$(jsonl_issue_count)"
before_db_count="$(db_issue_count)"
[[ "$before_jsonl_count" == "$before_db_count" ]] || fail "count_drift_before db=$before_db_count jsonl=$before_jsonl_count"

create_out="$(mktemp "${TMPDIR:-/tmp}/br-db-close-path-create.XXXXXX")"
close_out="$(mktemp "${TMPDIR:-/tmp}/br-db-close-path-close.XXXXXX")"
show_out="$(mktemp "${TMPDIR:-/tmp}/br-db-close-path-show.XXXXXX")"

br create "test-br-db-verify-probe" \
  --priority p3 \
  --status open \
  --description "verify probe" \
  --no-auto-flush \
  --no-auto-import \
  --json >"$create_out"

probe_id="$(jq -r '.id // .issue.id // empty' "$create_out")"
[[ -n "$probe_id" ]] || fail "probe_create_missing_id"

br close "$probe_id" \
  --force \
  --reason "verify probe close-path round trip" \
  --session "br-db-close-path-probe" \
  --no-auto-flush \
  --no-auto-import \
  --json >"$close_out"

br show "$probe_id" \
  --no-auto-flush \
  --no-auto-import \
  --json >"$show_out"

status="$(jq -r 'if type == "array" then .[0].status else .status end' "$show_out")"
[[ "$status" == "closed" ]] || fail "probe_status_not_closed status=$status"

cleanup_probe || fail "probe_cleanup_failed"
probe_id=""

sqlite3 "$DB" "PRAGMA integrity_check;" | grep -qx "ok" || fail "integrity_check_after_not_ok"
after_hash="$(jsonl_hash)"
after_jsonl_count="$(jsonl_issue_count)"
after_db_count="$(db_issue_count)"

[[ "$after_hash" == "$before_hash" ]] || fail "jsonl_hash_changed"
[[ "$after_jsonl_count" == "$before_jsonl_count" ]] || fail "jsonl_count_changed"
[[ "$after_db_count" == "$before_db_count" ]] || fail "db_count_changed_after_cleanup"
[[ "$after_db_count" == "$after_jsonl_count" ]] || fail "count_drift_after db=$after_db_count jsonl=$after_jsonl_count"

printf 'OK_br_db_close_path_active\n'

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-04-receipt-callback-envelope.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-88-content-addressed-evidence-pack.md`
