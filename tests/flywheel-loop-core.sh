#!/usr/bin/env bash
set -u -o pipefail

PASS_COUNT=0
FAIL_COUNT=0
CHECK_COUNT=0

FLYWHEEL_LOOP_BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
FLYWHEEL_REFRESH_SOURCE="${FLYWHEEL_REFRESH_SOURCE:-$HOME/.claude/skills/.flywheel/bin/flywheel-refresh-source}"

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

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "dependency: $1"
    note "missing command: $1"
    return 1
  fi
  return 0
}

tmpdir() {
  mktemp -d "${TMPDIR:-/tmp}/flywheel-loop-core.XXXXXX"
}

json_value() {
  printf '%s' "$1" | jq -r "$2" 2>/dev/null
}

write_temp_repo_seed() {
  local repo="$1"
  cat >"$repo/README.md" <<'EOF'
# Loop fixture

## Mission

Validate portable flywheel loop behavior in a temporary repository.
EOF
  cat >"$repo/Makefile" <<'EOF'
test:
	@true
EOF
  mkdir -p "$repo/.flywheel/scripts"
  cat >"$repo/.flywheel/scripts/publishability-bar.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
jq -nc '{schema_version:"publishability-bar/v1",status:"pass",publishability_bar_score:5,errors:[],warnings:[]}'
EOF
  chmod +x "$repo/.flywheel/scripts/publishability-bar.sh"
}

check_doctor_strict_lock_drift() {
  local label="T3.1 doctor reports ready docs then drift_detected on bad lock_hash"
  local repo out rc state tmp storage_fixture topology_fixture josh_requests_fixture
  repo=$(tmpdir) || { fail "$label"; note "mktemp failed"; return; }

  git -C "$repo" init -q >/dev/null 2>&1 || {
    rm -rf "$repo"
    fail "$label"
    note "git init failed"
    return
  }
  write_temp_repo_seed "$repo"
  printf '# Fixture AGENTS\n' >"$repo/AGENTS.md"
  mkdir -p "$repo/.flywheel/reports"
  printf '# daily\n' >"$repo/.flywheel/reports/daily-$(date -u +%F).md"
  storage_fixture="$repo/.flywheel/storage-healthy.json"
  jq -nc '{disk_total_gb:926,disk_free_gb:400,disk_free_pct:43,developer_dir_gb:0,local_state_gb:0,stale_baks_count:0,stale_baks_size_mb:0,qdrant_volumes_size_mb:0,tmp_dispatch_artifacts_count:0}' >"$storage_fixture"
  topology_fixture="$repo/.flywheel/session-topology.jsonl"
  josh_requests_fixture="$repo/.flywheel/josh-requests.jsonl"
  : >"$topology_fixture"
  : >"$josh_requests_fixture"

  if ! "$FLYWHEEL_LOOP_BIN" init --repo "$repo" --mission-source "$repo/README.md" --goal-source "$repo/README.md" --state-source "$repo/README.md" --json >/dev/null 2>&1; then
    rm -rf "$repo"
    fail "$label"
    note "flywheel-loop init failed"
    return
  fi

  out=$(FLYWHEEL_STORAGE_PROBE_FIXTURE="$storage_fixture" FLYWHEEL_SESSION_TOPOLOGY="$topology_fixture" FLYWHEEL_JOSH_REQUESTS_LOG="$josh_requests_fixture" FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 FLYWHEEL_CANONICAL_DOCTRINE_PATH="$repo/AGENTS.md" "$FLYWHEEL_LOOP_BIN" doctor --strict --repo "$repo" --json 2>/dev/null)
  rc=$?
  if [[ -z "$out" ]]; then
    rm -rf "$repo"
    fail "$label"
    note "strict doctor returned no JSON before corruption rc=$rc"
    return
  fi
  if [[ "$(json_value "$out" '.repo_docs_state')" != "ready" ]]; then
    rm -rf "$repo"
    fail "$label"
    note "expected repo_docs_state=ready before corruption"
    note "$out"
    return
  fi

  state="$repo/.flywheel/STATE.md"
  tmp="$repo/.flywheel/STATE.md.tmp"
  awk '
    !done && /^lock_hash:[[:space:]]*/ { print "lock_hash: bad-lock-hash"; done=1; next }
    { print }
  ' "$state" >"$tmp" && mv "$tmp" "$state"

  out=$(FLYWHEEL_STORAGE_PROBE_FIXTURE="$storage_fixture" FLYWHEEL_SESSION_TOPOLOGY="$topology_fixture" FLYWHEEL_JOSH_REQUESTS_LOG="$josh_requests_fixture" FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 FLYWHEEL_CANONICAL_DOCTRINE_PATH="$repo/AGENTS.md" "$FLYWHEEL_LOOP_BIN" doctor --strict --repo "$repo" --json 2>/dev/null)
  rc=$?
  if [[ "$rc" -eq 0 ]]; then
    rm -rf "$repo"
    fail "$label"
    note "strict doctor succeeded after corrupt lock_hash"
    note "$out"
    return
  fi
  if [[ "$(json_value "$out" '.repo_docs_state')" != "drift_detected" ]]; then
    rm -rf "$repo"
    fail "$label"
    note "expected repo_docs_state=drift_detected after corrupt lock_hash"
    note "$out"
    return
  fi

  rm -rf "$repo"
  pass "$label"
}

check_fleet_scan_flywheel_ready() {
  local label="T3.2 fleet scan reports flywheel docs ready"
  local out status docs_state
  out=$("$FLYWHEEL_LOOP_BIN" fleet --root /Users/josh/Developer --json 2>/dev/null)
  if [[ $? -ne 0 || -z "$out" ]]; then
    fail "$label"
    note "flywheel-loop fleet failed"
    return
  fi

  status=$(printf '%s' "$out" | jq -r '.repos[]? | select(.repo=="/Users/josh/Developer/flywheel") | .status' 2>/dev/null)
  docs_state=$(printf '%s' "$out" | jq -r '.repos[]? | select(.repo=="/Users/josh/Developer/flywheel") | .repo_docs_state' 2>/dev/null)
  if [[ "$docs_state" == "ready" ]]; then
    pass "$label"
  else
    fail "$label"
    note "expected /Users/josh/Developer/flywheel repo_docs_state=ready"
    note "status=${status:-missing} repo_docs_state=${docs_state:-missing}"
  fi
}

check_lock_hash_known_body() {
  local label="T3.3 frontmatter body hash matches known body"
  local dir helper file got expected
  dir=$(tmpdir) || { fail "$label"; note "mktemp failed"; return; }
  helper="$dir/frontmatter_body_sha256.sh"
  awk '/^frontmatter_body_sha256\(\)/,/^}/' "$HOME/.claude/skills/.flywheel/lib/canonical.sh" >"$helper"
  # shellcheck source=/dev/null
  . "$helper"

  file="$dir/locked.md"
  cat >"$file" <<'EOF'
---
status: locked
lock_hash: placeholder
---
alpha
beta
EOF

  expected="e49c81e2d2f84e259d40e2fb8192f3bcd198b355184845d76d8f58807d0d78ee"
  got=$(frontmatter_body_sha256 "$file")
  rm -rf "$dir"

  if [[ "$got" == "$expected" ]]; then
    pass "$label"
  else
    fail "$label"
    note "expected $expected"
    note "got $got"
  fi
}

check_snapshot_cap() {
  local label="T3.4 snapshot cap truncates files above 512000 bytes"
  local dir helper file size
  dir=$(tmpdir) || { fail "$label"; note "mktemp failed"; return; }
  helper="$dir/snapshot_cap.sh"
  awk '
    /^SNAPSHOT_MAX_BYTES=/ { capture=1 }
    /^fw_cap_snapshot_dir\(\)/ { exit }
    capture { print }
  ' "$FLYWHEEL_REFRESH_SOURCE" >"$helper"

  unset FLYWHEEL_SNAPSHOT_MAX_BYTES
  # shellcheck source=/dev/null
  . "$helper"

  if [[ "${SNAPSHOT_MAX_BYTES:-}" != "512000" ]]; then
    rm -rf "$dir"
    fail "$label"
    note "expected default SNAPSHOT_MAX_BYTES=512000, got ${SNAPSHOT_MAX_BYTES:-unset}"
    return
  fi

  file="$dir/oversize.cur"
  dd if=/dev/zero of="$file" bs=1024 count=513 >/dev/null 2>&1
  fw_cap_snapshot_file "$file"
  size=$(wc -c <"$file" | tr -d ' ')
  rm -rf "$dir"

  if [[ "$size" == "512000" ]]; then
    pass "$label"
  else
    fail "$label"
    note "expected capped size 512000 bytes, got $size"
  fi
}

check_fuckup_unprocessed_honors_sidecar() {
  local label="T3.5 fuckup list --unprocessed honors processed sidecar"
  local dir log processed out count kept ignore_count missing_count
  dir=$(tmpdir) || { fail "$label"; note "mktemp failed"; return; }
  log="$dir/fuckup-log.jsonl"
  processed="$dir/fuckup-processed.jsonl"

  cat >"$log" <<'EOF'
{"ts":"2026-05-03T00:00:00Z","trauma_class":"line-only","severity":"medium"}
{"ts":"2026-05-03T00:01:00Z","id":"row-2","trauma_class":"id-row","severity":"medium"}
{"ts":"2026-05-03T00:02:00Z","event_id":"event-3","trauma_class":"event-row","severity":"medium"}
{"ts":"2026-05-03T00:03:00Z","trauma_class":"ts-row","severity":"medium"}
{"ts":"2026-05-03T00:04:00Z","id":"keep","trauma_class":"keep-row","severity":"medium"}
{"ts":"2026-05-03T00:05:00Z","id":"raw-processed-at","processed_at":"2026-05-03T00:06:00Z","trauma_class":"raw-processed","severity":"medium"}
{"ts":"2026-05-03T00:06:00Z","id":"raw-processed-bool","processed":true,"trauma_class":"raw-processed","severity":"medium"}
{"ts":"2026-05-03T00:07:00Z","id":"raw-processed-into","processed_into":"/tmp/out.md","trauma_class":"raw-processed","severity":"medium"}
EOF
  cat >"$processed" <<'EOF'
{"fuckup_log_lines":[1]}
{"fuckup_log_ids":["row-2","event-3"]}
{"fuckup_ts":"2026-05-03T00:03:00Z"}
EOF

  out=$(FLYWHEEL_FUCKUP_LOG="$log" FUCKUP_PROCESSED="$processed" "$FLYWHEEL_LOOP_BIN" fuckup list --since=all --unprocessed --json 2>/dev/null)
  count=$(printf '%s\n' "$out" | jq -s 'length' 2>/dev/null)
  kept=$(printf '%s\n' "$out" | jq -r -s '.[0].id // empty' 2>/dev/null)
  ignore_count=$(FLYWHEEL_FUCKUP_LOG="$log" FUCKUP_PROCESSED="$processed" "$FLYWHEEL_LOOP_BIN" fuckup list --since=all --unprocessed --ignore-sidecar --json 2>/dev/null | jq -s 'length' 2>/dev/null)
  missing_count=$(FLYWHEEL_FUCKUP_LOG="$log" FUCKUP_PROCESSED="$dir/missing.jsonl" "$FLYWHEEL_LOOP_BIN" fuckup list --since=all --unprocessed --json 2>/dev/null | jq -s 'length' 2>/dev/null)
  rm -rf "$dir"

  if [[ "$count" == "1" && "$kept" == "keep" && "$ignore_count" == "5" && "$missing_count" == "5" ]]; then
    pass "$label"
  else
    fail "$label"
    note "expected sidecar-aware count=1 kept=keep ignore-sidecar=5 missing-sidecar=5"
    note "got count=${count:-missing} kept=${kept:-missing} ignore=${ignore_count:-missing} missing=${missing_count:-missing}"
  fi
}

check_repo_local_cli_floor_doctor_signal() {
  local label="T3.6 repo-local bin CLI floor doctor signal"
  local repo out rc storage_fixture topology_fixture josh_requests_fixture
  repo=$(tmpdir) || { fail "$label"; note "mktemp failed"; return; }
  git -C "$repo" init -q >/dev/null 2>&1 || {
    rm -rf "$repo"
    fail "$label"
    note "git init failed"
    return
  }
  write_temp_repo_seed "$repo"
  printf '# Fixture AGENTS\n' >"$repo/AGENTS.md"
  mkdir -p "$repo/.flywheel/reports"
  printf '# daily\n' >"$repo/.flywheel/reports/daily-$(date -u +%F).md"
  storage_fixture="$repo/.flywheel/storage-healthy.json"
  jq -nc '{disk_total_gb:926,disk_free_gb:400,disk_free_pct:43,developer_dir_gb:0,local_state_gb:0,stale_baks_count:0,stale_baks_size_mb:0,qdrant_volumes_size_mb:0,tmp_dispatch_artifacts_count:0}' >"$storage_fixture"
  topology_fixture="$repo/.flywheel/session-topology.jsonl"
  josh_requests_fixture="$repo/.flywheel/josh-requests.jsonl"
  : >"$topology_fixture"
  : >"$josh_requests_fixture"
  if ! "$FLYWHEEL_LOOP_BIN" init --repo "$repo" --mission-source "$repo/README.md" --goal-source "$repo/README.md" --state-source "$repo/README.md" --json >/dev/null 2>&1; then
    rm -rf "$repo"
    fail "$label"
    note "flywheel-loop init failed"
    return
  fi
  mkdir -p "$repo/bin"
  cat >"$repo/bin/bad-cli" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "--help" ]]; then
  printf 'usage: bad-cli\n'
  exit 0
fi
exit 2
EOF
  chmod +x "$repo/bin/bad-cli"

  out=$(FLYWHEEL_STORAGE_PROBE_FIXTURE="$storage_fixture" FLYWHEEL_SESSION_TOPOLOGY="$topology_fixture" FLYWHEEL_JOSH_REQUESTS_LOG="$josh_requests_fixture" FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 FLYWHEEL_CANONICAL_DOCTRINE_PATH="$repo/AGENTS.md" "$FLYWHEEL_LOOP_BIN" doctor --strict --repo "$repo" --json 2>/dev/null)
  rc=$?
  rm -rf "$repo"

  if [[ "$rc" -ne 0 ]] \
    && [[ "$(json_value "$out" '.repo_local_clis_below_canonical_floor')" == "1" ]] \
    && [[ "$(json_value "$out" '.repo_local_cli_floor.rows[0].name')" == "bad-cli" ]]; then
    pass "$label"
  else
    fail "$label"
    note "expected strict doctor failure with repo_local_clis_below_canonical_floor=1 for bad-cli"
    note "$out"
  fi
}

check_init_distributes_selected_incidents() {
  local label="T3.8 init distributes selected canonical INCIDENTS"
  local repo out incidents
  repo=$(tmpdir) || { fail "$label"; note "mktemp failed"; return; }
  git -C "$repo" init -q >/dev/null 2>&1 || {
    rm -rf "$repo"
    fail "$label"
    note "git init failed"
    return
  }
  write_temp_repo_seed "$repo"
  printf '# Fixture AGENTS\n' >"$repo/AGENTS.md"

  out=$("$FLYWHEEL_LOOP_BIN" init --repo "$repo" --mission-source "$repo/README.md" --goal-source "$repo/README.md" --state-source "$repo/README.md" --json 2>/dev/null)
  if [[ $? -ne 0 || -z "$out" ]]; then
    rm -rf "$repo"
    fail "$label"
    note "flywheel-loop init failed"
    note "$out"
    return
  fi
  incidents="$repo/.flywheel/INCIDENTS.md"
  if [[ ! -s "$incidents" ]]; then
    rm -rf "$repo"
    fail "$label"
    note "missing generated .flywheel/INCIDENTS.md"
    return
  fi
  if ! grep -q 'mission-anchor-drift-sub-mission-promotion' "$incidents"; then
    rm -rf "$repo"
    fail "$label"
    note "selected mission-anchor-drift incident was not distributed"
    return
  fi
  if grep -q 'agent-mail-token-continuity-after-compaction' "$incidents"; then
    rm -rf "$repo"
    fail "$label"
    note "unselected canonical incident was copied"
    return
  fi
  if ! printf '%s' "$out" | jq -e '.planned_writes[] | select(endswith("/.flywheel/INCIDENTS.md"))' >/dev/null; then
    rm -rf "$repo"
    fail "$label"
    note "init packet did not declare .flywheel/INCIDENTS.md in planned_writes"
    return
  fi
  rm -rf "$repo"
  pass "$label"
}

check_doctor_empty_errors_regression() {
  local label="T3.7 doctor fail carries concrete errors"
  local root script out rc
  root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || {
    fail "$label"
    note "could not resolve repo root"
    return
  }
  script="$root/.flywheel/scripts/test-doctor-empty-errors.sh"
  if [[ ! -r "$script" ]]; then
    fail "$label"
    note "missing regression script: $script"
    return
  fi

  out=$(FLYWHEEL_LOOP_BIN="$FLYWHEEL_LOOP_BIN" bash "$script" 2>&1)
  rc=$?
  if [[ "$rc" -eq 0 ]]; then
    pass "$label"
  else
    fail "$label"
    note "standalone regression failed"
    note "$out"
  fi
}

main() {
  need git || exit 1
  need jq || exit 1
  need shasum || exit 1
  need awk || exit 1
  need dd || exit 1

  if [[ ! -x "$FLYWHEEL_LOOP_BIN" ]]; then
    fail "dependency: flywheel-loop"
    note "not executable: $FLYWHEEL_LOOP_BIN"
    exit 1
  fi
  if [[ ! -r "$FLYWHEEL_REFRESH_SOURCE" ]]; then
    fail "dependency: flywheel-refresh-source"
    note "not readable: $FLYWHEEL_REFRESH_SOURCE"
    exit 1
  fi

  check_doctor_strict_lock_drift
  check_fleet_scan_flywheel_ready
  check_lock_hash_known_body
  check_snapshot_cap
  check_fuckup_unprocessed_honors_sidecar
  check_repo_local_cli_floor_doctor_signal
  check_doctor_empty_errors_regression
  check_init_distributes_selected_incidents

  echo
  echo "Summary: $PASS_COUNT/$CHECK_COUNT passed, $FAIL_COUNT failed"
  if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
