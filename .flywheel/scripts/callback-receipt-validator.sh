#!/usr/bin/env bash
set -uo pipefail

VERSION="callback-receipt-validator.v1.0.0"
SCHEMA_VERSION="callback-receipt-decision/v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO="$REPO_DEFAULT"
LEDGER="${CALLBACK_RECEIPT_VALIDATOR_LEDGER:-$HOME/.local/state/flywheel/callback-receipt-validator-ledger.jsonl}"
FIX_BEAD_OPENER="${CALLBACK_RECEIPT_FIX_BEAD_OPENER:-$SCRIPT_DIR/callback-fix-bead-opener.sh}"

MODE=""
CALLBACK_TEXT=""
CALLBACK_STDIN=0
DISPATCH_FILE=""
JSON_OUT=0

usage() {
  cat <<'EOF'
usage:
  callback-receipt-validator.sh check --callback-text TEXT --dispatch-file PATH [--repo PATH] [--json]
  callback-receipt-validator.sh check --callback-stdin --dispatch-file PATH [--repo PATH] [--json]
  callback-receipt-validator.sh --info|--help|--examples
EOF
}

info() {
  jq -nc \
    --arg name "callback-receipt-validator.sh" \
    --arg version "$VERSION" \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg repo "$REPO_DEFAULT" \
    --arg ledger "$LEDGER" \
    '{name:$name,version:$version,schema_version:$schema_version,repo:$repo,ledger:$ledger,purpose:"validate worker DONE callbacks by rerunning dispatch L112 verify before summary",exit_codes:{"0":"PASS verified","1":"REFUSE hard block","2":"UNVERIFIABLE malformed callback fail-open"}}'
}

examples() {
  cat <<'EOF'
callback-receipt-validator.sh check --callback-text 'DONE task-a bead=flywheel-a evidence=/tmp/a.md l112_observed=OK' --dispatch-file /tmp/dispatch_task-a.md --json
printf '%s\n' 'DONE task-a bead=flywheel-a evidence=/tmp/a.md l112_observed=OK' | callback-receipt-validator.sh check --callback-stdin --dispatch-file /tmp/dispatch_task-a.md --repo /Users/josh/Developer/flywheel --json
EOF
}

fail_usage() {
  printf 'ERR: %s\n' "$1" >&2
  usage >&2
  exit 2
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

read_callback_text() {
  if [[ "$CALLBACK_STDIN" -eq 1 ]]; then
    cat
  else
    printf '%s\n' "$CALLBACK_TEXT"
  fi
}

parse_callback_json() {
  local path="$1"
  python3 - "$path" <<'PY'
import json
import shlex
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
compact = " ".join(text.splitlines()).strip()
try:
    tokens = shlex.split(compact)
except ValueError as exc:
    print(json.dumps({"ok": False, "error": "callback_malformed", "detail": str(exc), "task_id": "", "bead": "", "evidence": "", "l112_observed": "", "raw": text}))
    raise SystemExit(0)

if not tokens or tokens[0] != "DONE":
    print(json.dumps({"ok": False, "error": "callback_malformed", "detail": "callback must start with DONE", "task_id": "", "bead": "", "evidence": "", "l112_observed": "", "raw": text}))
    raise SystemExit(0)

fields = {}
positionals = []
for token in tokens[1:]:
    if "=" in token:
        key, value = token.split("=", 1)
        fields[key] = value
    else:
        positionals.append(token)

task_id = fields.get("task_id") or (positionals[0] if positionals else "")
bead = fields.get("bead") or (positionals[0] if fields.get("task_id") and positionals else "")
evidence = fields.get("evidence", "")
l112_observed = fields.get("l112_observed", "")

ok = bool(task_id and l112_observed)
payload = {
    "ok": ok,
    "error": "" if ok else "callback_malformed",
    "detail": "" if ok else "missing task_id or l112_observed",
    "task_id": task_id,
    "bead": bead,
    "evidence": evidence,
    "l112_observed": l112_observed,
    "raw": text,
}
print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
PY
}

extract_dispatch_json() {
  local path="$1"
  python3 - "$path" <<'PY'
import json
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8", errors="replace")
match = re.search(r"(?ims)^##\s*L112\s+verify\s*\n(?P<section>.*?)(?=^##\s|\Z)", text)
if not match:
    print(json.dumps({"ok": False, "error": "l112_verify_missing", "command": "", "timeout": 30}))
    raise SystemExit(0)

section = match.group("section")
fence = re.search(r"```(?:bash|sh)?\s*\n(?P<cmd>.*?)\n```", section, re.S)
if fence:
    command = fence.group("cmd").strip()
else:
    lines = []
    for raw in section.splitlines():
        line = raw.strip()
        if not line or line.lower().startswith(("expected:", "timeout:")):
            continue
        lines.append(raw)
    command = "\n".join(lines).strip()

timeout_match = re.search(r"(?im)^Timeout:\s*([0-9]+)\b", section)
timeout = int(timeout_match.group(1)) if timeout_match else int(__import__("os").environ.get("CALLBACK_RECEIPT_TIMEOUT_SEC", "30"))
print(json.dumps({"ok": bool(command), "error": "" if command else "l112_verify_missing", "command": command, "timeout": timeout}, sort_keys=True, separators=(",", ":")))
PY
}

append_ledger() {
  local row="$1"
  mkdir -p "$(dirname "$LEDGER")" 2>/dev/null || return 1
  jq -c . <<<"$row" >>"$LEDGER" 2>/dev/null
}

last_nonempty_line() {
  awk 'NF { line=$0 } END { print line }' "$1"
}

run_l112_verify() {
  local command_text="$1" timeout_sec="$2" stdout_file="$3" stderr_file="$4" timeout_bin rc
  timeout_bin="$(command -v gtimeout || command -v timeout || true)"
  if [[ -n "$timeout_bin" ]]; then
    set +e
    (cd "$REPO" && "$timeout_bin" "$timeout_sec" bash -lc "$command_text") >"$stdout_file" 2>"$stderr_file"
    rc=$?
    set +e
  else
    set +e
    (cd "$REPO" && bash -lc "$command_text") >"$stdout_file" 2>"$stderr_file"
    rc=$?
    set +e
  fi
  return "$rc"
}

open_fix_bead() {
  local task_id="$1" bead="$2" reason="$3" expected="$4" actual="$5" output
  [[ -x "$FIX_BEAD_OPENER" ]] || { printf 'null\n'; return 0; }
  set +e
  output="$("$FIX_BEAD_OPENER" --repo "$REPO" --task-id "$task_id" --bead "$bead" --reason "$reason" --expected "$expected" --actual "$actual" --json 2>/dev/null)"
  set +e
  jq -r '.fix_bead_id // "created_unparsed"' <<<"$output" 2>/dev/null || printf 'created_unparsed\n'
}

decision_row() {
  local decision="$1" reason="$2" exit_code="$3" callback_json="$4" dispatch_cmd="$5" verify_rc="$6" expected="$7" actual="$8" stdout_text="$9" stderr_text="${10}" fix_bead_id="${11}"
  jq -nc \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg ts "$(now_iso)" \
    --arg repo_path "$REPO" \
    --arg dispatch_file "$DISPATCH_FILE" \
    --arg decision "$decision" \
    --arg reason "$reason" \
    --arg command "$dispatch_cmd" \
    --arg expected "$expected" \
    --arg actual "$actual" \
    --arg stdout "$stdout_text" \
    --arg stderr "$stderr_text" \
    --arg ledger_path "$LEDGER" \
    --arg fix_bead_id "$fix_bead_id" \
    --argjson exit_code "$exit_code" \
    --argjson verify_exit_code "$verify_rc" \
    --argjson callback "$callback_json" \
    '{schema_version:$schema_version,version:$version,ts:$ts,repo_path:$repo_path,callback:$callback,dispatch_file:$dispatch_file,l112_verify_command:(if $command == "" then null else $command end),expected_l112:(if $expected == "" then null else $expected end),actual_l112:(if $actual == "" then null else $actual end),verify_result:{exit_code:$verify_exit_code,stdout:$stdout,stderr:$stderr},decision:$decision,reason:$reason,exit_code:$exit_code,fix_bead_id:(if $fix_bead_id == "" or $fix_bead_id == "null" then null else $fix_bead_id end),ledger_path:$ledger_path}'
}

emit_row() {
  local row="$1" rc="$2"
  append_ledger "$row" || true
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$row"
  else
    printf 'decision=%s reason=%s task_id=%s\n' "$(jq -r '.decision' <<<"$row")" "$(jq -r '.reason' <<<"$row")" "$(jq -r '.callback.task_id // "unknown"' <<<"$row")"
  fi
  exit "$rc"
}

run_check() {
  local callback_file callback_json task_id bead observed dispatch_json command timeout stdout_file stderr_file verify_rc actual reason row fix stdout_text stderr_text
  callback_file="$(mktemp "${TMPDIR:-/tmp}/callback-receipt.XXXXXX")"
  read_callback_text >"$callback_file"
  callback_json="$(parse_callback_json "$callback_file")"
  if ! jq -e '.ok == true' >/dev/null 2>&1 <<<"$callback_json"; then
    row="$(decision_row "UNVERIFIABLE" "callback_malformed" 2 "$callback_json" "" null "" "" "" "" "")"
    emit_row "$row" 2
  fi

  task_id="$(jq -r '.task_id' <<<"$callback_json")"
  bead="$(jq -r '.bead // ""' <<<"$callback_json")"
  observed="$(jq -r '.l112_observed' <<<"$callback_json")"

  if [[ ! -f "$DISPATCH_FILE" ]]; then
    fix="$(open_fix_bead "$task_id" "$bead" "dispatch_file_missing" "$observed" "")"
    row="$(decision_row "REFUSE" "dispatch_file_missing" 1 "$callback_json" "" null "$observed" "" "" "" "$fix")"
    emit_row "$row" 1
  fi

  dispatch_json="$(extract_dispatch_json "$DISPATCH_FILE")"
  if ! jq -e '.ok == true' >/dev/null 2>&1 <<<"$dispatch_json"; then
    reason="$(jq -r '.error // "l112_verify_missing"' <<<"$dispatch_json")"
    fix="$(open_fix_bead "$task_id" "$bead" "$reason" "$observed" "")"
    row="$(decision_row "REFUSE" "$reason" 1 "$callback_json" "" null "$observed" "" "" "" "$fix")"
    emit_row "$row" 1
  fi

  command="$(jq -r '.command' <<<"$dispatch_json")"
  timeout="$(jq -r '.timeout' <<<"$dispatch_json")"
  stdout_file="$(mktemp "${TMPDIR:-/tmp}/callback-l112-stdout.XXXXXX")"
  stderr_file="$(mktemp "${TMPDIR:-/tmp}/callback-l112-stderr.XXXXXX")"
  run_l112_verify "$command" "$timeout" "$stdout_file" "$stderr_file"
  verify_rc=$?
  actual="$(last_nonempty_line "$stdout_file")"
  stdout_text="$(cat "$stdout_file")"
  stderr_text="$(cat "$stderr_file")"

  if [[ "$verify_rc" -ne 0 ]]; then
    fix="$(open_fix_bead "$task_id" "$bead" "l112_verify_failed" "$observed" "$actual")"
    row="$(decision_row "REFUSE" "l112_verify_failed" 1 "$callback_json" "$command" "$verify_rc" "$observed" "$actual" "$stdout_text" "$stderr_text" "$fix")"
    emit_row "$row" 1
  fi

  if [[ "$actual" != "$observed" ]]; then
    fix="$(open_fix_bead "$task_id" "$bead" "l112_output_mismatch" "$observed" "$actual")"
    row="$(decision_row "REFUSE" "l112_output_mismatch" 1 "$callback_json" "$command" "$verify_rc" "$observed" "$actual" "$stdout_text" "$stderr_text" "$fix")"
    emit_row "$row" 1
  fi

  row="$(decision_row "PASS" "pass" 0 "$callback_json" "$command" "$verify_rc" "$observed" "$actual" "$stdout_text" "$stderr_text" "")"
  emit_row "$row" 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    check) MODE="check"; shift ;;
    --callback-text) CALLBACK_TEXT="${2:-}"; shift 2 ;;
    --callback-stdin) CALLBACK_STDIN=1; shift ;;
    --dispatch-file) DISPATCH_FILE="${2:-}"; shift 2 ;;
    --repo) REPO="${2:-}"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) fail_usage "unknown argument: $1" ;;
  esac
done

[[ "$MODE" == "check" ]] || fail_usage "missing command: check"
[[ "$CALLBACK_STDIN" -eq 1 || -n "$CALLBACK_TEXT" ]] || fail_usage "missing callback source"
[[ -n "$DISPATCH_FILE" ]] || fail_usage "missing --dispatch-file"
REPO="$(cd "$REPO" 2>/dev/null && pwd -P)" || fail_usage "repo not found: $REPO"
run_check
