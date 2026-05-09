#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/.flywheel/scripts/verify-callback-delivery.sh"
TMP="$(mktemp -d)"
trap 'find "$TMP" -mindepth 1 -delete; rmdir "$TMP"' EXIT

FAKE_NTM="$TMP/ntm"
STATE="$TMP/state"
CALLS="$TMP/calls"
MODE="${MODE:-success}"
printf '0' >"$STATE"
: >"$CALLS"

cat >"$FAKE_NTM" <<'NTM'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >>"${CALLS:?}"
cmd="${1:-}"; shift || true
case "$cmd" in
  send)
    count="$(cat "${STATE:?}")"
    printf '%s' "$((count + 1))" >"$STATE"
    [[ "${MODE:-success}" == fts5 ]] && exit 1
    if [[ "${MODE:-success}" == copy_mode ]]; then
      printf 'ntm: pane %%1 is not in a mode that accepts input\n' >&2
      exit 1
    fi
    exit 0
    ;;
  history)
    [[ "${MODE:-success}" == pane ]] && exit 1
    count="$(cat "${STATE:?}")"
    case "${MODE:-success}" in
      success)
        cat <<JSON
[{"session":"flywheel","pane":1,"text":"DONE task-success evidence=/tmp/task-success.md"}]
JSON
        ;;
      queued)
        cat <<JSON
[{"session":"flywheel","pane":1,"text":"prompt queued only count=$count"}]
JSON
        ;;
      *)
        printf '[]\n'
        ;;
    esac
    ;;
  logs|copy)
    echo "legacy scrollback command must not be used" >&2
    exit 42
    ;;
  *)
    echo "unexpected ntm command: $cmd" >&2
    exit 64
    ;;
esac
NTM
chmod +x "$FAKE_NTM"

SPOOL_DIR="$TMP/spool"

run_json() {
  MODE="$1" CALLS="$CALLS" STATE="$STATE" \
    "$SCRIPT" --ntm "$FAKE_NTM" --task-id "$2" --message "$3" \
      --retries 2 --wait-seconds 0 --spool-dir "$SPOOL_DIR" --json
}

assert_jq() {
  local json="$1" expr="$2"
  jq -e "$expr" <<<"$json" >/dev/null
}

out="$(run_json success task-success 'DONE task-success evidence=/tmp/task-success.md')"
assert_jq "$out" '.status == "ok" and .callback_delivery_verified == true and .verify_method == "ntm_history"'
grep -q '^history ' "$CALLS"
! grep -Eq '^(logs|copy) ' "$CALLS"

: >"$CALLS"
out="$(run_json queued task-queued 'DONE task-queued evidence=/tmp/task-queued.md')" || true
assert_jq "$out" '.status == "fail" and .callback_delivery_verified == false and .failure_class == "callback_not_observed"'
grep -q '^history ' "$CALLS"
! grep -Eq '^(logs|copy) ' "$CALLS"

: >"$CALLS"
out="$(run_json fts5 task-fts 'DONE task-fts evidence=/tmp/task-fts.md')" || true
assert_jq "$out" '.status == "fail" and .failure_class == "ntm_send_failed"'

: >"$CALLS"
out="$(run_json pane task-pane 'DONE task-pane evidence=/tmp/task-pane.md')" || true
assert_jq "$out" '.status == "fail" and .failure_class == "pane_disappeared"'

: >"$CALLS"
out="$(run_json copy_mode task-copymode 'DONE task-copymode evidence=/tmp/task-copymode.md')" || true
assert_jq "$out" '.status == "fail" and .failure_class == "pane_not_in_input_mode" and (.spool_path | length > 0)'
SPOOLED="$SPOOL_DIR/flywheel/task-copymode.json"
test -s "$SPOOLED" || { echo "expected spool file at $SPOOLED" >&2; exit 1; }
jq -e '.schema_version == "callback-spool/v1" and .task_id == "task-copymode" and .failure_class == "pane_not_in_input_mode" and .status == "pending" and .attempts == 0 and (.message | contains("DONE task-copymode"))' "$SPOOLED" >/dev/null \
  || { echo "spool file missing required fields" >&2; jq . "$SPOOLED" >&2; exit 1; }

FAILED="$TMP/custom-failure.md"
MODE=queued CALLS="$CALLS" STATE="$STATE" \
  "$SCRIPT" --ntm "$FAKE_NTM" --task-id task-failed-path --message 'DONE task-failed-path evidence=/tmp/task-failed.md' \
  --retries 1 --wait-seconds 0 --failed-path "$FAILED" --json >/dev/null || true
test -s "$FAILED"
grep -q 'verify_method: ntm_history' "$FAILED"

echo "verify-callback-delivery tests passed"
