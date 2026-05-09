#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/.flywheel/scripts/callback-spool-reap.sh"
TMP="$(mktemp -d)"
trap 'find "$TMP" -mindepth 1 -delete 2>/dev/null; rmdir "$TMP" 2>/dev/null || true' EXIT

FAKE_NTM="$TMP/ntm"
SPOOL="$TMP/spool"
ARCHIVE="$TMP/spool/archive"
DLOG="$TMP/dispatch-log.jsonl"

cat >"$FAKE_NTM" <<'NTM'
#!/usr/bin/env bash
set -euo pipefail
cmd="${1:-}"; shift || true
case "$cmd" in
  send)
    if [[ -f "${MOCK_SEND_FAIL_FILE:-}" ]]; then
      printf 'ntm: pane is not in a mode that accepts input\n' >&2
      exit 1
    fi
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
NTM
chmod +x "$FAKE_NTM"

assert_jq(){
  local label="$1" json="$2" expr="$3"
  if jq -e "$expr" <<<"$json" >/dev/null; then
    printf 'PASS %s\n' "$label"
  else
    printf 'FAIL %s\n' "$label" >&2
    printf '%s\n' "$json" >&2
    exit 1
  fi
}

write_spool_entry(){
  local session="$1" task_id="$2" message="$3" attempts="${4:-0}"
  mkdir -p "$SPOOL/$session"
  jq -n --arg ts "2026-05-09T15:00:00Z" \
        --arg session "$session" --arg pane "1" \
        --arg task_id "$task_id" --arg message "$message" \
        --argjson attempts "$attempts" \
        '{schema_version:"callback-spool/v1",ts:$ts,session:$session,pane:$pane,task_id:$task_id,message:$message,failure_class:"pane_not_in_input_mode",status:"pending",attempts:$attempts}' \
        >"$SPOOL/$session/$task_id.json"
}

# 1. Doctor on empty spool
out="$("$SCRIPT" doctor --spool-dir "$SPOOL" --archive-dir "$ARCHIVE" --json)"
assert_jq "doctor reports empty spool" "$out" '.pending == 0 and .archived == 0'

# 2. Dry-run with one pending entry: would_retry, no mutation
write_spool_entry flywheel task-dry 'DONE task-dry evidence=/tmp/x.md'
out="$("$SCRIPT" --dry-run --json --spool-dir "$SPOOL" --archive-dir "$ARCHIVE" --ntm "$FAKE_NTM")"
assert_jq "dry-run reports would_retry" "$out" '.mode == "dry-run" and .reaped == 0 and (.results | length == 1) and (.results[0].outcome == "would_retry")'
test -f "$SPOOL/flywheel/task-dry.json" || { echo "dry-run must not delete spool" >&2; exit 1; }
printf 'PASS dry-run leaves spool intact\n'

# 3. Apply with successful retry: archived
out="$("$SCRIPT" --apply --json --spool-dir "$SPOOL" --archive-dir "$ARCHIVE" --ntm "$FAKE_NTM")"
assert_jq "apply reaps successfully" "$out" '.reaped == 1 and .retry_pending == 0 and .persisted_failure == 0'
test ! -f "$SPOOL/flywheel/task-dry.json" || { echo "expected spool entry removed" >&2; exit 1; }
test -f "$ARCHIVE/flywheel/task-dry.json" || { echo "expected archive entry" >&2; exit 1; }
jq -e '.status == "reaped" and .attempts == 1' "$ARCHIVE/flywheel/task-dry.json" >/dev/null
printf 'PASS apply archives reaped entry with attempts=1\n'

# 4. Apply with failing send: retry_pending; attempts increment
write_spool_entry flywheel task-fail 'DONE task-fail evidence=/tmp/y.md'
touch "$TMP/send-fail"
export MOCK_SEND_FAIL_FILE="$TMP/send-fail"
out="$("$SCRIPT" --apply --json --spool-dir "$SPOOL" --archive-dir "$ARCHIVE" --ntm "$FAKE_NTM")"
assert_jq "send fail leaves retry_pending" "$out" '.reaped == 0 and .retry_pending == 1'
jq -e '.attempts == 1 and (.last_send_stderr | length > 0)' "$SPOOL/flywheel/task-fail.json" >/dev/null
printf 'PASS retry increments attempts and records stderr\n'

# 5. Persisted failure: max_attempts reached → row appended to dispatch-log + archive failure artifact
write_spool_entry flywheel task-persist 'DONE task-persist evidence=/tmp/z.md' 4
out="$("$SCRIPT" --apply --json --spool-dir "$SPOOL" --archive-dir "$ARCHIVE" --dispatch-log "$DLOG" --max-attempts 5 --ntm "$FAKE_NTM")"
assert_jq "persisted failure surfaces" "$out" '(.results[] | select(.task_id == "task-persist") | .outcome == "persisted_failure") and (.persisted_failure >= 1)'
test ! -f "$SPOOL/flywheel/task-persist.json" || { echo "spool should be moved to failure artifact" >&2; exit 1; }
ls "$ARCHIVE/flywheel/task-persist.json.persisted-failure.json" >/dev/null
test -f "$DLOG" && tail -1 "$DLOG" | jq -e '.event == "callback_spool_persisted_failure" and .task_id == "task-persist" and .fuckup_class == "send_persisted_failure"' >/dev/null
printf 'PASS persisted failure writes archive artifact and dispatch-log row\n'

unset MOCK_SEND_FAIL_FILE

# 6. Validate detects malformed entry
write_spool_entry flywheel task-good 'DONE task-good evidence=/tmp/g.md'
echo '{"not_a_callback":true}' > "$SPOOL/flywheel/task-bad.json"
set +e
out="$("$SCRIPT" validate --spool-dir "$SPOOL" --json)"
rc=$?
set -e
test "$rc" -ne 0 || { echo "validate must exit non-zero on malformed" >&2; exit 1; }
assert_jq "validate detects malformed" "$out" '.malformed >= 1'
printf 'PASS validate detects malformed entries\n'

# 7. Audit lists archived entries
out="$("$SCRIPT" audit --spool-dir "$SPOOL" --archive-dir "$ARCHIVE" --json)"
echo "$out" | jq -e 'length >= 1' >/dev/null
printf 'PASS audit lists archived entries\n'

# 8. Schema endpoint
out="$("$SCRIPT" schema)"
echo "$out" | jq -e '.schema_version == "callback-spool/v1" and (.required_fields | index("task_id"))' >/dev/null
printf 'PASS schema endpoint\n'

# 9. Info endpoint
out="$("$SCRIPT" --info)"
echo "$out" | jq -e '.name == "callback-spool-reap.sh" and (.version | startswith("callback-spool-reap"))' >/dev/null
printf 'PASS info endpoint\n'

printf 'callback-spool-reap tests passed\n'
