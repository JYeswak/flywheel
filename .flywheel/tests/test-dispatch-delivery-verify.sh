#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/dispatch-delivery-verify.sh"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/dispatch-delivery-verify.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dispatch-delivery-verify.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
outputs=()

pass() {
  printf 'PASS %s\n' "$1"
  pass_count=$((pass_count + 1))
}

fail() {
  printf 'FAIL %s\n' "$1" >&2
  fail_count=$((fail_count + 1))
}

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || cat "$file" >&2
  fi
}

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
state="${FAKE_NTM_STATE:?}"
mode="${FAKE_NTM_MODE:-present}"
mkdir -p "$state"
case "${1:-}" in
  send)
    shift
    session="${1:-}"
    shift || true
    pane=""
    prompt=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --pane=*) pane="${1#*=}"; shift ;;
        --pane) pane="${2:-}"; shift 2 ;;
        --file) prompt="$(cat "${2:?}")"; shift 2 ;;
        --file=*) prompt="$(cat "${1#*=}")"; shift ;;
        --no-cass-check) shift ;;
        *) prompt="${prompt:+$prompt }$1"; shift ;;
      esac
    done
    printf '%s\n' "$prompt" >"$state/last_prompt"
    jq -nc --arg session "$session" --arg pane "$pane" '{success:true,session:$session,pane:($pane|tonumber? // null)}'
    ;;
  --robot-tail=*)
    pane="2"
    for arg in "$@"; do
      case "$arg" in
        --panes=*) pane="${arg#*=}" ;;
      esac
    done
    case "$mode" in
      live) text="$(cat "$state/last_prompt" 2>/dev/null || true)" ;;
      present) text="worker buffer line with task-synthetic-present visible" ;;
      missing) text="worker buffer without target id" ;;
      object) jq -nc --arg pane "$pane" '{success:true,panes:{($pane):{state:"idle",lines:["object fixture task-object-present"]}},source_health:{status:"fixture"}}'; exit 0 ;;
      error) jq -nc --arg pane "$pane" '{success:true,panes:{($pane):{state:"ERROR",lines:["pane has an ERROR state"]}},source_health:{status:"fixture"}}'; exit 0 ;;
      capture_fail) printf 'robot tail failed\n' >&2; exit 42 ;;
      *) text="unknown mode" ;;
    esac
    jq -nc --argjson pane "$pane" --arg text "$text" '{success:true,panes:[{pane:$pane,text:$text}],source_health:{status:"fixture"}}'
    ;;
  *)
    printf 'unsupported fake ntm args: %s\n' "$*" >&2
    exit 2
    ;;
esac
SH
chmod +x "$TMP/ntm"

run_verify() {
  local label="$1" mode="$2" task_id="$3" expected_rc="$4" jq_filter="$5" out rc
  out="$TMP/${label// /_}.json"
  set +e
  env \
    "FAKE_NTM_STATE=$TMP/ntm-state" \
    "FAKE_NTM_MODE=$mode" \
    "DISPATCH_DELIVERY_VERIFY_NTM=$TMP/ntm" \
    "DISPATCH_DELIVERY_VERIFY_LEDGER=$TMP/ledger.jsonl" \
    "DISPATCH_DELIVERY_VERIFY_FUCKUP_LOG=$TMP/fuckup-log.jsonl" \
    "$SCRIPT" --session flywheel --pane 2 --task-id "$task_id" --timeout-sec 0 --json >"$out" 2>"$out.err"
  rc=$?
  set -e
  outputs+=("$out")
  if [[ "$rc" == "$expected_rc" ]] && jq -e "$jq_filter" "$out" >/dev/null; then
    return 0
  fi
  fail "$label"
  printf 'rc=%s expected=%s stderr=%s\n' "$rc" "$expected_rc" "$(cat "$out.err")" >&2
  jq . "$out" >&2 || cat "$out" >&2
  return 1
}

bash -n "$SCRIPT"

env FAKE_NTM_STATE="$TMP/ntm-state" FAKE_NTM_MODE=live "$TMP/ntm" send flywheel --pane=2 "Read /tmp/dispatch_task-live.md and execute task-live" >/dev/null
run_verify "live ntm send and immediate verify true" live task-live 0 '.verified == true and .matched_at_line != null and .reason == null' \
  && pass "live ntm send and immediate verify true"

run_verify "synthetic fixture with task_id true" present task-synthetic-present 0 '.verified == true and .matched_at_line == 1' \
  && pass "synthetic fixture with task_id true"

run_verify "synthetic object fixture true" object task-object-present 0 '.verified == true and .matched_at_line == 1' >/dev/null || true

run_verify "synthetic without task_id false" missing task-absent 1 '.verified == false and .reason == "task_id_not_observed" and .matched_at_line == null' \
  && pass "synthetic without task_id false"

run_verify "pane ERROR state false" error task-error 1 '.verified == false and .reason == "pane_unhealthy"' \
  && pass "pane ERROR state false"

run_verify "buffer capture failure fail closed" capture_fail task-capture-fail 1 '.verified == false and .reason == "capture_failed" and .ntm_rc == 42' \
  && [[ -s "$TMP/fuckup-log.jsonl" ]] \
  && jq -e 'select(.trauma_class == "dispatch-delivery-verify-capture-failed" and .task_id == "task-capture-fail")' "$TMP/fuckup-log.jsonl" >/dev/null \
  && pass "buffer capture failure fail closed and fuckup row"

ledger_rows="$(wc -l <"$TMP/ledger.jsonl" | tr -d ' ')"
if [[ "$ledger_rows" == "6" ]] \
  && jq -e 'select(.task_id == "task-live")' "$TMP/ledger.jsonl" >/dev/null \
  && jq -e 'select(.task_id == "task-capture-fail")' "$TMP/ledger.jsonl" >/dev/null; then
  pass "ledger row appended on every invocation"
else
  fail "ledger row appended on every invocation"
  printf 'ledger_rows=%s\n' "$ledger_rows" >&2
  cat "$TMP/ledger.jsonl" >&2 || true
fi

python3 - "$SCHEMA" "${outputs[@]}" <<'PY'
import json
import sys
from pathlib import Path

schema = json.loads(Path(sys.argv[1]).read_text())
required = set(schema["required"])
try:
    import jsonschema
except Exception:
    jsonschema = None

for path in sys.argv[2:]:
    data = json.loads(Path(path).read_text())
    missing = required.difference(data)
    if missing:
        raise SystemExit(f"{path}: missing required fields {sorted(missing)}")
    if jsonschema is not None:
        jsonschema.Draft202012Validator(schema).validate(data)
PY
pass "JSON shape valid"

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$pass_count" == "7" && "$fail_count" == "0" ]]
