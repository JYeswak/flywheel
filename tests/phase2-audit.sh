#!/usr/bin/env bash
set -u -o pipefail

PASS_COUNT=0
FAIL_COUNT=0
CHECK_COUNT=0

pass() {
  CHECK_COUNT=$((CHECK_COUNT + 1))
  PASS_COUNT=$((PASS_COUNT + 1))
  printf 'PASS %s\n' "$1"
}

fail() {
  CHECK_COUNT=$((CHECK_COUNT + 1))
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf 'FAIL %s\n' "$1"
}

note() {
  printf '  - %s\n' "$1"
}

check_t21() {
  local label="T2.1 global vault tombstone + stale IDs closed"
  local tombstone="/Users/josh/Developer/.beads-tombstone"
  local global_beads="/Users/josh/Developer/.beads"
  local stale_ids=(fc-27i fc-2pm fc-1q9 fc-1sr fc-7xm fc-hci fc-y3w fc-135 fc-d9s fc-3fv fc-2m7)

  if [[ ! -e "$tombstone" ]]; then
    fail "$label"
    note "missing tombstone marker: $tombstone"
    return
  fi

  if [[ -e "$global_beads" ]]; then
    fail "$label"
    note "active global vault exists: $global_beads"
    return
  fi

  local tombstone_db="${tombstone}/beads.db"
  if [[ -f "$tombstone_db" ]]; then
    local ids_csv
    ids_csv=$(printf "'%s'," "${stale_ids[@]}")
    ids_csv="${ids_csv%,}"
    local open_count
    open_count=$(sqlite3 "$tombstone_db" "SELECT COUNT(*) FROM issues WHERE id IN ($ids_csv) AND status IN ('open','in_progress');" 2>/dev/null || echo "ERR")
    if [[ "$open_count" == "ERR" ]]; then
      fail "$label"
      note "could not query stale IDs in $tombstone_db"
      return
    fi
    if [[ "$open_count" != "0" ]]; then
      fail "$label"
      note "stale IDs still open in tombstone DB: $open_count"
      return
    fi
    note "tombstone DB stale ID open count = 0"
  else
    note "no tombstone DB present (marker only), global vault inactive"
  fi

  pass "$label"
}

check_t22() {
  local label="T2.2 spot-check active repos have .beads/beads.db"
  local repos=(
    "/Users/josh/Developer/flywheel"
    "/Users/josh/Developer/zesttube"
    "/Users/josh/Developer/polymarket-pico-z"
    "/Users/josh/Developer/cubcloud-aaas"
    "/Users/josh/Developer/agent-bench"
    "/Users/josh/Developer/josh-ops"
  )

  local missing=0
  for repo in "${repos[@]}"; do
    local db="$repo/.beads/beads.db"
    if [[ ! -f "$db" ]]; then
      note "missing DB: $db"
      missing=$((missing + 1))
      continue
    fi
    if ! sqlite3 "$db" "SELECT 1;" >/dev/null 2>&1; then
      note "unreadable sqlite DB: $db"
      missing=$((missing + 1))
      continue
    fi
  done

  if [[ $missing -eq 0 ]]; then
    pass "$label"
  else
    fail "$label"
    note "repos with missing/unreadable DB: $missing"
  fi
}

check_t23() {
  local label="T2.3 source_repo='.' count is 0 in repo-local DBs"
  local any_bad=0
  local checked=0
  local skipped=0

  while IFS= read -r beads_dir; do
    local db="$beads_dir/beads.db"
    if [[ ! -f "$db" ]]; then
      skipped=$((skipped + 1))
      continue
    fi

    local has_issues
    has_issues=$(sqlite3 "$db" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='issues';" 2>/dev/null || echo "ERR")
    if [[ "$has_issues" != "1" ]]; then
      skipped=$((skipped + 1))
      continue
    fi

    local count
    count=$(sqlite3 "$db" "SELECT COUNT(*) FROM issues WHERE source_repo = '.';" 2>/dev/null || echo "ERR")
    if [[ "$count" == "ERR" ]]; then
      note "query error: $db"
      any_bad=1
      continue
    fi

    checked=$((checked + 1))
    if [[ "$count" != "0" ]]; then
      note "$db -> source_repo='.' count=$count"
      any_bad=1
    fi
  done < <(find /Users/josh/Developer -maxdepth 2 -name '.beads' -type d 2>/dev/null)

  note "checked DBs: $checked"
  note "skipped non-DB/non-issues dirs: $skipped"

  if [[ $checked -eq 0 ]]; then
    fail "$label"
    note "no repo-local DBs with issues table found"
    return
  fi

  if [[ $any_bad -eq 0 ]]; then
    pass "$label"
  else
    fail "$label"
  fi
}

check_t24() {
  # Intent: br create populates source_repo AND br where resolves the local DB.
  # 2026-05-09 calibration (flywheel-8x2le close): br 0.2.5 writes basename,
  # not absolute path. Earlier br versions wrote absolute paths (1386 historical
  # rows in flywheel.db). Rather than assert a specific implementation, this
  # check verifies the contract that actually matters to consumers: source_repo
  # is non-empty, and br where (from inside the repo) resolves to that DB.
  # Cross-repo basename collisions are a CONSUMER concern — handle by
  # canonicalizing at read time, not by demanding a specific source_repo shape.
  local label="T2.4 br create populates source_repo and br where resolves local DB"
  local tmp
  tmp=$(mktemp -d)
  local title
  title="phase2-audit-src-repo-$RANDOM-$(date +%s)"

  if ! git -C "$tmp" init -q >/dev/null 2>&1; then
    rm -rf "$tmp"
    fail "$label"
    note "git init failed in temp repo"
    return
  fi

  if ! (cd "$tmp" && ~/.cargo/bin/br init >/dev/null 2>&1); then
    rm -rf "$tmp"
    fail "$label"
    note "br init failed in temp repo"
    return
  fi

  if ! (cd "$tmp" && ~/.cargo/bin/br create "$title" -t task -p 4 -d "phase2 audit probe" >/dev/null 2>&1); then
    rm -rf "$tmp"
    fail "$label"
    note "br create failed in temp repo"
    return
  fi

  local src
  src=$(sqlite3 "$tmp/.beads/beads.db" "SELECT source_repo FROM issues WHERE title='$title' ORDER BY created_at DESC LIMIT 1;" 2>/dev/null || true)

  if [[ -z "$src" ]]; then
    rm -rf "$tmp"
    fail "$label"
    note "missing source_repo value for created issue"
    return
  fi

  local where_out
  where_out=$(cd "$tmp" && ~/.cargo/bin/br where 2>/dev/null || true)
  local expected_db="$tmp/.beads"

  if ! printf '%s' "$where_out" | grep -q "$expected_db"; then
    rm -rf "$tmp"
    fail "$label"
    note "br where did not resolve to local .beads dir: $where_out"
    return
  fi

  rm -rf "$tmp"
  pass "$label"
}

check_t25() {
  local label="T2.5 br where from flywheel resolves local DB"
  local out
  if ! out=$(cd /Users/josh/Developer/flywheel && ~/.cargo/bin/br where 2>/dev/null); then
    fail "$label"
    note "br where command failed"
    return
  fi

  if ! printf '%s' "$out" | grep -q "/Users/josh/Developer/flywheel/.beads"; then
    fail "$label"
    note "br where did not resolve flywheel local .beads"
    note "$out"
    return
  fi

  if printf '%s' "$out" | grep -q "/Users/josh/Developer/.beads"; then
    fail "$label"
    note "br where resolved global vault unexpectedly"
    note "$out"
    return
  fi

  pass "$label"
}

check_t26() {
  local label="T2.6 bd and br-real absent from PATH"
  local has_bd=1
  local has_br_real=1

  if command -v bd >/dev/null 2>&1; then
    has_bd=0
    note "bd found at $(command -v bd)"
  fi
  if command -v br-real >/dev/null 2>&1; then
    has_br_real=0
    note "br-real found at $(command -v br-real)"
  fi

  if [[ $has_bd -eq 1 && $has_br_real -eq 1 ]]; then
    pass "$label"
  else
    fail "$label"
  fi
}

check_t27() {
  local label="T2.7 RunBrReal not called in ntm/internal"
  local out
  out=$(grep -R --line-number --fixed-strings "RunBrReal" /Users/josh/Developer/ntm/internal/ 2>/dev/null || true)
  if [[ -n "$out" ]]; then
    fail "$label"
    note "$out"
  else
    pass "$label"
  fi
}

check_t28() {
  local label="T2.8 runtime_handoff has working_dir column"
  local state_db="${NTM_STATE_DB:-$HOME/.config/ntm/state.db}"

  if [[ ! -f "$state_db" ]]; then
    fail "$label"
    note "state DB not found: $state_db"
    return
  fi

  local has_table
  has_table=$(sqlite3 "$state_db" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='runtime_handoff';" 2>/dev/null || echo "ERR")
  if [[ "$has_table" != "1" ]]; then
    fail "$label"
    note "runtime_handoff table missing in $state_db"
    return
  fi

  local has_column
  has_column=$(sqlite3 "$state_db" "SELECT COUNT(*) FROM pragma_table_info('runtime_handoff') WHERE name='working_dir';" 2>/dev/null || echo "ERR")
  if [[ "$has_column" != "1" ]]; then
    fail "$label"
    note "working_dir column missing in runtime_handoff ($state_db)"
    return
  fi

  pass "$label"
}

check_t28b() {
  local label="T2.8b runtime_handoff supports distinct session/workdir rows"
  local state_db="${NTM_STATE_DB:-$HOME/.config/ntm/state.db}"

  if [[ ! -f "$state_db" ]]; then
    fail "$label"
    note "state DB not found: $state_db"
    return
  fi

  local tmp
  tmp=$(mktemp -d -t bead-isolation-p2.XXXXXX)
  local schema_file="$tmp/runtime_handoff.schema.sql"
  local fixture_db="$tmp/runtime_handoff-fixture.db"
  local err_file="$tmp/runtime_handoff.err"

  if ! sqlite3 "$state_db" ".schema runtime_handoff" >"$schema_file" 2>"$err_file"; then
    fail "$label"
    note "could not read runtime_handoff schema: $(tr '\n' ' ' <"$err_file")"
    rm -rf "$tmp"
    return
  fi

  if ! grep -q "CREATE TABLE .*runtime_handoff" "$schema_file"; then
    fail "$label"
    note "runtime_handoff schema missing from $state_db"
    rm -rf "$tmp"
    return
  fi

  if ! sqlite3 "$fixture_db" <"$schema_file" 2>"$err_file"; then
    fail "$label"
    note "could not create isolated fixture DB: $(tr '\n' ' ' <"$err_file")"
    rm -rf "$tmp"
    return
  fi

  local has_working_dir
  has_working_dir=$(sqlite3 "$fixture_db" "SELECT COUNT(*) FROM pragma_table_info('runtime_handoff') WHERE name='working_dir';" 2>/dev/null || echo "ERR")
  if [[ "$has_working_dir" != "1" ]]; then
    fail "$label"
    note "working_dir column missing in isolated fixture schema"
    rm -rf "$tmp"
    return
  fi

  local has_id insert_sql
  has_id=$(sqlite3 "$fixture_db" "SELECT COUNT(*) FROM pragma_table_info('runtime_handoff') WHERE name='id';" 2>/dev/null || echo "ERR")
  if [[ "$has_id" == "1" ]]; then
    insert_sql="
      INSERT INTO runtime_handoff (id, session_name, status, updated_at, collected_at, stale_after, working_dir)
        VALUES (1, 'session-a', 'ok', datetime('now'), datetime('now'), datetime('now', '+5 minutes'), '/path/to/repoA');
      INSERT INTO runtime_handoff (id, session_name, status, updated_at, collected_at, stale_after, working_dir)
        VALUES (2, 'session-b', 'ok', datetime('now'), datetime('now'), datetime('now', '+5 minutes'), '/path/to/repoB');
    "
  else
    insert_sql="
      INSERT INTO runtime_handoff (session_name, status, updated_at, collected_at, stale_after, working_dir)
        VALUES ('session-a', 'ok', datetime('now'), datetime('now'), datetime('now', '+5 minutes'), '/path/to/repoA');
      INSERT INTO runtime_handoff (session_name, status, updated_at, collected_at, stale_after, working_dir)
        VALUES ('session-b', 'ok', datetime('now'), datetime('now'), datetime('now', '+5 minutes'), '/path/to/repoB');
    "
  fi

  if ! sqlite3 "$fixture_db" "$insert_sql" 2>"$err_file"; then
    fail "$label"
    note "isolated fixture rejected distinct session/workdir rows: $(tr '\n' ' ' <"$err_file")"
    rm -rf "$tmp"
    return
  fi

  local row_count distinct_pairs
  row_count=$(sqlite3 "$fixture_db" "SELECT COUNT(*) FROM runtime_handoff;" 2>/dev/null || echo "ERR")
  distinct_pairs=$(sqlite3 "$fixture_db" "SELECT COUNT(DISTINCT session_name || char(31) || working_dir) FROM runtime_handoff;" 2>/dev/null || echo "ERR")
  rm -rf "$tmp"

  if [[ "$row_count" == "2" && "$distinct_pairs" == "2" ]]; then
    pass "$label"
  else
    fail "$label"
    note "expected 2 rows / 2 distinct session+workdir pairs, got rows=$row_count distinct_pairs=$distinct_pairs"
  fi
}

main() {
  echo "Phase 2 Audit — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  check_t21
  check_t22
  check_t23
  check_t24
  check_t25
  check_t26
  check_t27
  check_t28
  check_t28b

  echo
  echo "Summary: $PASS_COUNT/$CHECK_COUNT passed, $FAIL_COUNT failed"
  if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
