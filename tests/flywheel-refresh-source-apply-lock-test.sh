#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="${FLYWHEEL_REFRESH_SOURCE_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-refresh-source}"
REAL_FLYWHEEL_HOME="${FLYWHEEL_HOME:-$HOME/.claude/skills/.flywheel}"
JSONL_APPEND_LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"
LIVE_DB="$HOME/.claude/skills/.flywheel/state.db"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-refresh-source-lock.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

PASS_COUNT=0
FAIL_COUNT=0

pass() {
  printf 'PASS %s\n' "$1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  printf 'FAIL %s\n' "$1" >&2
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

assert_no_sqlite_lock_error() {
  local label="$1"
  shift
  if rg -i 'database is locked|database locked' "$@" >/dev/null 2>&1; then
    fail "$label"
    rg -n -i 'database is locked|database locked' "$@" >&2 || true
  else
    pass "$label"
  fi
}

write_fixture_tools() {
  mkdir -p "$TMP/bin"
  cat >"$TMP/bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
out=""
url=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) out="${2:?}"; shift 2 ;;
    -w) shift 2 ;;
    --max-time|-A) shift 2 ;;
    -*) shift ;;
    *) url="$1"; shift ;;
  esac
done
[[ -n "$out" ]] || exit 2
sleep "${FAKE_CURL_SLEEP:-0.2}"
case "$url" in
  file://*)
    cp "${url#file://}" "$out"
    printf '000'
    ;;
  *)
    printf 'fixture payload\n' >"$out"
    printf '200'
    ;;
esac
EOF
  chmod +x "$TMP/bin/curl"
}

write_state_db() {
  sqlite3 "$DB" <<'SQL'
PRAGMA journal_mode=WAL;
CREATE TABLE sources (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    skill           TEXT    NOT NULL,
    url             TEXT    NOT NULL,
    kind            TEXT    NOT NULL CHECK (kind IN ('url','x_user','x_search')),
    added_at        TEXT    NOT NULL DEFAULT (datetime('now')),
    last_attempt_at TEXT,
    last_ok_at      TEXT,
    fail_streak     INTEGER NOT NULL DEFAULT 0,
    quality_score   REAL    NOT NULL DEFAULT 0.5,
    quality_alpha   REAL    NOT NULL DEFAULT 1.0,
    quality_beta    REAL    NOT NULL DEFAULT 1.0,
    UNIQUE(skill, url)
);
CREATE INDEX idx_sources_skill ON sources(skill);
CREATE TABLE snapshots (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    source_id     INTEGER NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
    fetched_at    TEXT    NOT NULL DEFAULT (datetime('now')),
    bytes         INTEGER NOT NULL,
    sha256        TEXT    NOT NULL,
    summary       TEXT,
    novelty_score REAL    NOT NULL DEFAULT 0.0,
    fetch_status  TEXT    NOT NULL CHECK (fetch_status IN ('ok','fail','rate_limited','dns','timeout'))
);
CREATE INDEX idx_snapshots_source ON snapshots(source_id, fetched_at DESC);
CREATE TABLE deltas (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    snapshot_id     INTEGER NOT NULL REFERENCES snapshots(id) ON DELETE CASCADE,
    skill           TEXT    NOT NULL,
    bullets         TEXT    NOT NULL,
    severity        TEXT    NOT NULL DEFAULT 'info' CHECK (severity IN ('info','minor','major','breaking')),
    created_at      TEXT    NOT NULL DEFAULT (datetime('now')),
    surfaced_at     TEXT,
    surfaced_count  INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_deltas_skill ON deltas(skill, created_at DESC);
CREATE TABLE events (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    ts          TEXT    NOT NULL DEFAULT (datetime('now')),
    kind        TEXT    NOT NULL,
    skill       TEXT,
    duration_ms INTEGER,
    detail      TEXT
);
CREATE INDEX idx_events_kind ON events(kind, ts DESC);
SQL
}

write_skill_fixture() {
  mkdir -p "$SKILL_DIR/data"
  printf 'payload %s\n' "$(date -u +%s)" >"$PAYLOAD"
  printf 'file://%s\n' "$PAYLOAD" >"$SKILL_DIR/data/sources.txt"
}

run_apply() {
  local timeout_sec="$1" out="$2" err="$3"
  HOME="$SCRATCH_HOME" \
  PATH="$TMP/bin:$PATH" \
  FLYWHEEL_HOME="$REAL_FLYWHEEL_HOME" \
  FLYWHEEL_DB="$DB" \
  FLYWHEEL_LOG="$LOG" \
  FLYWHEEL_STATE_DIR="$STATE_DIR" \
  FLYWHEEL_REFRESH_SOURCE_LOCK="$LOCK" \
  FLYWHEEL_REFRESH_SOURCE_APPLY_LEDGER="$LEDGER" \
  FLYWHEEL_REFRESH_SOURCE_LOCK_TIMEOUT_SEC="$timeout_sec" \
  FLYWHEEL_JSONL_APPEND_LIB="$JSONL_APPEND_LIB" \
  FAKE_CURL_SLEEP="${FAKE_CURL_SLEEP:-0.2}" \
  "$BIN" "$SKILL_DIR" --json >"$out" 2>"$err"
}

run_apply_lock_doctor() {
  local out="$1"
  HOME="$SCRATCH_HOME" \
  FLYWHEEL_HOME="$REAL_FLYWHEEL_HOME" \
  FLYWHEEL_DB="$DB" \
  FLYWHEEL_LOG="$LOG" \
  FLYWHEEL_STATE_DIR="$STATE_DIR" \
  FLYWHEEL_REFRESH_SOURCE_LOCK="$LOCK" \
  FLYWHEEL_REFRESH_SOURCE_APPLY_LEDGER="$LEDGER" \
  FLYWHEEL_JSONL_APPEND_LIB="$JSONL_APPEND_LIB" \
  "$BIN" doctor --scope apply-lock --json >"$out"
}

hold_apply_lock() {
  python3 - "$1" "$2" <<'PY'
import fcntl
import os
import sys
import time

path, duration = sys.argv[1], float(sys.argv[2])
os.makedirs(os.path.dirname(path), exist_ok=True)
fd = os.open(path, os.O_RDWR | os.O_CREAT, 0o600)
try:
    fcntl.flock(fd, fcntl.LOCK_EX)
    time.sleep(duration)
finally:
    fcntl.flock(fd, fcntl.LOCK_UN)
    os.close(fd)
PY
}

if bash -n "$BIN"; then
  pass "target shell syntax"
else
  fail "target shell syntax"
fi

DB="$TMP/state.db"
LOCK="$TMP/apply.lock"
LEDGER="$TMP/apply-ledger.jsonl"
LOG="$TMP/flywheel.log"
STATE_DIR="$TMP/state-dir"
SCRATCH_HOME="$TMP/home"
SKILL_DIR="$TMP/fixture-skill"
PAYLOAD="$TMP/payload.txt"
mkdir -p "$SCRATCH_HOME" "$STATE_DIR"

live_before=""
if [[ -f "$LIVE_DB" ]]; then
  live_before="$(shasum -a 256 "$LIVE_DB" | awk '{print $1}')"
fi

write_fixture_tools
write_state_db >/dev/null
write_skill_fixture

FAKE_CURL_SLEEP=0.5 run_apply 5 "$TMP/parallel-a.out" "$TMP/parallel-a.err" &
pid_a=$!
FAKE_CURL_SLEEP=0.5 run_apply 5 "$TMP/parallel-b.out" "$TMP/parallel-b.err" &
pid_b=$!
set +e
wait "$pid_a"
rc_a=$?
wait "$pid_b"
rc_b=$?
set -e
if [[ "$rc_a" -eq 0 && "$rc_b" -eq 0 ]]; then
  pass "parallel applies both exit zero"
else
  fail "parallel applies both exit zero rc_a=$rc_a rc_b=$rc_b"
fi
assert_jq "$TMP/parallel-a.out" '.status == "ok"' "parallel apply a json ok"
assert_jq "$TMP/parallel-b.out" '.status == "ok"' "parallel apply b json ok"
assert_no_sqlite_lock_error "parallel applies avoid sqlite lock errors" "$TMP/parallel-a.out" "$TMP/parallel-a.err" "$TMP/parallel-b.out" "$TMP/parallel-b.err"
if jq -s -e '[.[] | select(.action == "apply_lock_acquired")] | length == 2' "$LEDGER" >/dev/null &&
   jq -s -e '[.[] | select(.action == "apply_lock_released")] | length == 2' "$LEDGER" >/dev/null; then
  pass "parallel ledger has two acquire release pairs"
else
  fail "parallel ledger has two acquire release pairs"
  jq -s . "$LEDGER" >&2 || true
fi

run_apply_lock_doctor "$TMP/doctor-ok.json"
assert_jq "$TMP/doctor-ok.json" '.status == "OK" and .subsystems[0].acquire_count_24h == 2 and .subsystems[0].release_count_24h == 2 and .subsystems[0].timeout_count_24h == 0' "doctor apply-lock counts clean parallel run"

hold_apply_lock "$LOCK" 3 &
holder_pid=$!
sleep 0.2
set +e
run_apply 1 "$TMP/timeout.out" "$TMP/timeout.err"
timeout_rc=$?
set -e
wait "$holder_pid"
if [[ "$timeout_rc" -eq 3 ]]; then
  pass "held lock exits transient code 3"
else
  fail "held lock exits transient code 3 got=$timeout_rc"
fi
assert_jq "$TMP/timeout.err" '.action == "apply_aborted" and .reason == "flock_timeout" and .timeout_sec == 1' "timeout stderr emits ledger row"
if jq -s -e '[.[] | select(.action == "apply_aborted" and .reason == "flock_timeout")] | length == 1' "$LEDGER" >/dev/null; then
  pass "timeout ledger row appended"
else
  fail "timeout ledger row appended"
  jq -s . "$LEDGER" >&2 || true
fi

set +e
run_apply_lock_doctor "$TMP/doctor-fail.json"
doctor_fail_rc=$?
set -e
if [[ "$doctor_fail_rc" -eq 1 ]]; then
  pass "doctor apply-lock exits nonzero after timeout"
else
  fail "doctor apply-lock exits nonzero after timeout got=$doctor_fail_rc"
fi
assert_jq "$TMP/doctor-fail.json" '.status == "FAIL" and .subsystems[0].timeout_count_24h == 1 and .subsystems[0].contention_count_24h == 1' "doctor apply-lock reports timeout contention"

if FLYWHEEL_REFRESH_SOURCE_BIN="$BIN" bash "$ROOT/tests/flywheel-refresh-source-canonical-cli.sh" >"$TMP/canonical.out" 2>"$TMP/canonical.err"; then
  pass "existing canonical cli test passes"
else
  fail "existing canonical cli test passes"
  cat "$TMP/canonical.out" >&2
  cat "$TMP/canonical.err" >&2
fi

if [[ -n "$live_before" ]]; then
  live_after="$(shasum -a 256 "$LIVE_DB" | awk '{print $1}')"
  if [[ "$live_before" == "$live_after" ]]; then
    pass "live state db hash unchanged"
  else
    fail "live state db hash unchanged"
  fi
fi

echo
printf 'Summary: %s passed, %s failed\n' "$PASS_COUNT" "$FAIL_COUNT"
if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi
