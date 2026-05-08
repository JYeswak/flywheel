#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/storage-pause-auto-resume.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/storage-pause-auto-resume.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || fail "missing command: $1"
}

need jq
bash -n "$SCRIPT"

state="$TMP/storage-pause-active.json"
reclaim_dir="$TMP/reclaim"
mkdir -p "$reclaim_dir" "$TMP/bin"

jq -nc '{
  schema_version:"storage-pause-active/v1",
  generated_at:"2026-05-08T04:00:00Z",
  storage_pause_active:true,
  paused_workers:[
    {name:"cass-autoindex",pids:[111,222]},
    {name:"alps-headless-chrome",pids:[333]}
  ]
}' >"$state"

"$SCRIPT" --state "$state" --reclaim-dir "$reclaim_dir" --json \
  | jq -e '.status == "waiting_for_reclaim_receipt" and .resumed_count == 0' >/dev/null \
  || fail "missing reclaim receipt should wait"

jq -nc '{schema_version:"reclaim-receipt/v1",issued_at:"2026-05-08T04:10:00Z"}' >"$reclaim_dir/reclaim.json"
"$SCRIPT" --state "$state" --reclaim-dir "$reclaim_dir" --dry-run --json \
  | jq -e '.status == "would_resume" and .apply == false and (.pids | sort) == ["111","222","333"]' >/dev/null \
  || fail "dry-run should list pids"

cat >"$TMP/bin/kill" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$KILL_LOG"
exit 0
SH
chmod +x "$TMP/bin/kill"
export KILL_LOG="$TMP/kill.log"

KILL_BIN="$TMP/bin/kill" "$SCRIPT" --state "$state" --reclaim-dir "$reclaim_dir" --apply --json \
  | jq -e '.status == "resumed" and .apply == true and .resumed_count == 3 and .failed_count == 0' >/dev/null \
  || fail "apply should resume all fixture pids"

grep -q -- '-CONT 111' "$KILL_LOG" || fail "pid 111 not resumed"
grep -q -- '-CONT 222' "$KILL_LOG" || fail "pid 222 not resumed"
grep -q -- '-CONT 333' "$KILL_LOG" || fail "pid 333 not resumed"

printf 'PASS storage-pause-auto-resume\n'
