#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/dispatch-and-log.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dispatch-and-log-expected-by.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  preflight)
    printf '{"error_count":0,"warning_count":0,"findings":[]}\n'
    ;;
  send)
    printf 'sent\n'
    ;;
  wait)
    printf '{"status":"generating"}\n'
    ;;
  *)
    printf 'unsupported fake ntm args: %s\n' "$*" >&2
    exit 2
    ;;
esac
SH
chmod +x "$TMP/ntm"

task_file="$TMP/task.md"
printf 'fixture task\n' >"$task_file"
log="$TMP/dispatch-log.jsonl"

run_dispatch() {
  local task_id="$1" callback_by="$2"
  FLYWHEEL_DISPATCH_LOG="$log" \
  FLYWHEEL_DISPATCH_AND_LOG_NOW_EPOCH=1777850000 \
  NTM="$TMP/ntm" \
    "$SCRIPT" --session=fixture --pane=2 --task-file="$task_file" --task-id="$task_id" --callback-by="$callback_by" >/dev/null
}

run_dispatch duration "+45min"
if jq -e '
  .task_id == "duration"
  and .ts == "2026-05-03T23:13:20Z"
  and .callback_expected_by == "2026-05-03T23:58:20Z"
  and .callback_expected_by_input == "+45min"
  and .callback_expected_by_legacy_duration == "+45min"
  and .callback_expected_by_parse_status == "duration"
' "$log" >/dev/null; then
  pass "duration_callback_by_becomes_absolute_iso"
else
  fail "duration_callback_by_becomes_absolute_iso"
fi

run_dispatch absolute "2026-05-05T17:30:35Z"
if sed -n '2p' "$log" | jq -e '
  .task_id == "absolute"
  and .callback_expected_by == "2026-05-05T17:30:35Z"
  and .callback_expected_by_input == "2026-05-05T17:30:35Z"
  and .callback_expected_by_legacy_duration == null
  and .callback_expected_by_parse_status == "absolute"
' >/dev/null; then
  pass "absolute_callback_by_preserved"
else
  fail "absolute_callback_by_preserved"
fi

run_dispatch malformed "soon"
if sed -n '3p' "$log" | jq -e '
  .task_id == "malformed"
  and .callback_expected_by == null
  and .callback_expected_by_input == "soon"
  and .callback_expected_by_legacy_duration == null
  and .callback_expected_by_parse_status == "unknown"
' >/dev/null; then
  pass "malformed_callback_by_records_unknown_without_failing"
else
  fail "malformed_callback_by_records_unknown_without_failing"
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$pass_count" == "3" && "$fail_count" == "0" ]]
