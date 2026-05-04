#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/verify-callback-delivery.sh"
FIXTURES="$ROOT/tests/fixtures/verify-callback-delivery"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/verify-callback-delivery.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

make_fake_ntm() {
  local mode="$1" ntm counter
  ntm="$TMP/ntm-$mode"
  counter="$TMP/send-count-$mode"
  printf '0\n' >"$counter"
  {
    printf '%s\n' '#!/usr/bin/env bash'
    printf '%s\n' 'set -euo pipefail'
    printf 'MODE=%q\n' "$mode"
    printf 'COUNTER=%q\n' "$counter"
    printf '%s\n' 'if [[ "${1:-}" == "send" ]]; then'
    printf '%s\n' '  n="$(cat "$COUNTER")"; n=$((n + 1)); printf "%s\n" "$n" >"$COUNTER"'
    printf '%s\n' '  if [[ "$MODE" == "fts5" ]]; then printf "fts5: syntax error near quote\n" >&2; exit 1; fi'
    printf '%s\n' '  printf "{\"success\":true}\n"; exit 0'
    printf '%s\n' 'fi'
    printf '%s\n' 'if [[ "${1:-}" == "logs" ]]; then'
    printf '%s\n' '  if [[ "$MODE" == "success" ]]; then printf "orchestrator pane saw DONE task-success evidence=/tmp/task-success.md\n"; else printf "stale orchestrator text\n"; fi'
    printf '%s\n' '  exit 0'
    printf '%s\n' 'fi'
    printf '%s\n' 'if [[ "${1:-}" == "copy" ]]; then'
    printf '%s\n' '  out=""'
    printf '%s\n' '  while [[ $# -gt 0 ]]; do if [[ "$1" == "--output" ]]; then out="$2"; shift 2; else shift; fi; done'
    printf '%s\n' '  if [[ "$MODE" == "pane" ]]; then exit 1; fi'
    printf '%s\n' '  if [[ "$MODE" == "success-copy" ]]; then printf "DONE task-success\n" >"$out"; else printf "old pane text\n" >"$out"; fi'
    printf '%s\n' '  exit 0'
    printf '%s\n' 'fi'
    printf '%s\n' 'printf "{}\n"'
  } >"$ntm"
  chmod +x "$ntm"
  printf '%s\n' "$ntm"
}

run_case() {
  local label="$1" mode="$2" task_id="$3" fixture="$4" expected_rc="$5" jq_filter="$6"
  local ntm out rc=0 failed_path
  ntm="$(make_fake_ntm "$mode")"
  out="$TMP/$task_id.json"
  failed_path="$TMP/$task_id-callback-failed.md"
  "$SCRIPT" \
    --session flywheel \
    --pane 1 \
    --task-id "$task_id" \
    --message-file "$FIXTURES/$fixture" \
    --ntm "$ntm" \
    --retries 2 \
    --wait-seconds 0 \
    --failed-path "$failed_path" \
    --json >"$out" || rc=$?
  if [[ "$rc" == "$expected_rc" ]] && jq -e "$jq_filter" "$out" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    printf 'rc=%s expected=%s\n' "$rc" "$expected_rc"
    jq . "$out" || true
  fi
}

run_case "success via logs" "success" "task-success" "success.txt" 0 '.callback_delivery_verified == true and .verify_method == "ntm_logs"'
run_case "queued-not-submitted retries and fails" "queued" "task-queued" "queued-not-submitted.txt" 1 '.callback_delivery_verified == false and .failure_class == "callback_not_observed"'
run_case "FTS5 escape send failure" "fts5" "task-fts5" "fts5-escape.txt" 1 '.callback_delivery_verified == false and .failure_class == "ntm_send_failed"'
run_case "pane disappeared" "pane" "task-pane" "pane-disappeared.txt" 1 '.callback_delivery_verified == false and .failure_class == "pane_disappeared"'

default_task_id="task-default-$$"
default_failed_path="/tmp/${default_task_id}-callback-failed.md"
rm -f "$default_failed_path"
default_ntm="$(make_fake_ntm queued)"
default_out="$TMP/default-failed-path.json"
default_rc=0
"$SCRIPT" \
  --session flywheel \
  --pane 1 \
  --task-id "$default_task_id" \
  --message-file "$FIXTURES/queued-not-submitted.txt" \
  --ntm "$default_ntm" \
  --retries 1 \
  --wait-seconds 0 \
  --json >"$default_out" || default_rc=$?
if [[ "$default_rc" == "1" ]] \
  && jq -e --arg path "$default_failed_path" '.callback_delivery_verified == false and .failed_path == $path' "$default_out" >/dev/null \
  && [[ -f "$default_failed_path" ]] \
  && rg -q 'callback_delivery_verified: false' "$default_failed_path"; then
  pass "default failure artifact path"
else
  fail "default failure artifact path"
  printf 'rc=%s path=%s\n' "$default_rc" "$default_failed_path"
  jq . "$default_out" || true
fi
rm -f "$default_failed_path"

echo
printf 'Summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
