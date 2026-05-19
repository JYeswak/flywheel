#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (filled per bead flywheel-1hshd.9)
# L5 lint requires `set -euo pipefail`. Strict mode here is safe — the
# validator uses explicit `set +e` inside the verify-rerun block to
# preserve rc capture for the pass/block/unverifiable tri-state.
set -euo pipefail

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

# ====== BEGIN canonical-cli scaffold (bead flywheel-1hshd.9) ======
# Wave-4 partial→passing for a 288-line single-command validator (the
# script that 1hshd.8's wrapper delegates to). Adds canonical CLI family
# (doctor / health / repair / validate / audit / why / --schema /
# --examples + quickstart / help / completion). Original `check` command
# and tri-state PASS/REFUSE/UNVERIFIABLE behavior preserved unchanged.

SCAFFOLD_SCHEMA_VERSION="callback-receipt-validator/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$LEDGER}"
IDEMPOTENCY_KEY=""

scaffold_emit_schema() {
  local surface="${1:-default}"
  [[ "$surface" == "--json" ]] && surface="default"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
    '{schema_version:$sv,command:"schema",surface:$surface,
      decision_row:{required:["schema_version","version","ts","repo_path","callback","dispatch_file","l112_verify_command","expected_l112","actual_l112","verify_result","decision","reason","exit_code","fix_bead_id","ledger_path"]},
      decisions:["PASS","REFUSE","UNVERIFIABLE"],
      exit_codes:{"0":"PASS verified","1":"REFUSE hard block","2":"UNVERIFIABLE malformed callback fail-open","3":"--apply without --idempotency-key (canonical apply contract)"}}'
}

scaffold_emit_quickstart() {
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    '{schema_version:$sv,command:"quickstart",steps:[
      {step:1,action:"probe doctor",command:"callback-receipt-validator.sh doctor --json"},
      {step:2,action:"check a callback",command:"echo \"DONE ...\" | callback-receipt-validator.sh check --callback-stdin --dispatch-file /tmp/dispatch.md --json"}
    ]}'
}

scaffold_emit_topic_help() {
  case "${1:-}" in
    check)    printf 'topic: check — validate a worker DONE callback by rerunning the dispatch L112 probe. Inputs: --callback-text TEXT or --callback-stdin + --dispatch-file PATH. Tri-state exit: 0=PASS, 1=REFUSE, 2=UNVERIFIABLE.\n' ;;
    doctor)   printf 'topic: doctor — substrate probe: jq, fix-bead opener, ledger writable, repo dir, flywheel root.\n' ;;
    health)   printf 'topic: health — tails ledger; warn stale >7d. Counts PASS/REFUSE/UNVERIFIABLE decisions.\n' ;;
    repair)   printf 'topic: repair — scopes: ledger-rotate (5MB), fix-bead-opener-prime.\n' ;;
    validate) printf 'topic: validate — subjects: row, schema, config, ledger.\n' ;;
    *)        printf 'topics: check | doctor | health | repair | validate\n' ;;
  esac
}

scaffold_cmd_doctor() {
  local checks="" overall="pass"
  if command -v jq >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v jq)" '{name:"jq_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"jq_on_path",status:"fail"}')"$'\n'; overall="fail"
  fi
  local fb_present=false
  [[ -x "$FIX_BEAD_OPENER" ]] && fb_present=true
  local fb_status="pass"; [[ "$fb_present" != true ]] && fb_status="warn"
  checks+="$(jq -nc --arg p "$FIX_BEAD_OPENER" --arg s "$fb_status" --argjson present "$fb_present" \
    '{name:"fix_bead_opener_executable",status:$s,value:$p,present:$present}')"$'\n'
  local ledger_dir; ledger_dir="$(dirname "$LEDGER")"
  if [[ -d "$ledger_dir" && -w "$ledger_dir" ]] || mkdir -p "$ledger_dir" 2>/dev/null; then
    local row_count=0
    [[ -r "$LEDGER" ]] && row_count="$(wc -l < "$LEDGER" 2>/dev/null | tr -d ' ' || echo 0)"
    checks+="$(jq -nc --arg p "$LEDGER" --argjson rc "${row_count:-0}" '{name:"ledger_writable",status:"pass",value:$p,row_count:$rc}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$LEDGER" '{name:"ledger_writable",status:"fail",value:$p}')"$'\n'; overall="fail"
  fi
  if [[ -d "$REPO" ]]; then
    checks+="$(jq -nc --arg p "$REPO" '{name:"repo_dir_present",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$REPO" '{name:"repo_dir_present",status:"fail",value:$p}')"$'\n'; overall="fail"
  fi
  if [[ -d "$REPO_DEFAULT" ]]; then
    checks+="$(jq -nc --arg p "$REPO_DEFAULT" '{name:"flywheel_root_resolvable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$REPO_DEFAULT" '{name:"flywheel_root_resolvable",status:"fail",value:$p}')"$'\n'; overall="fail"
  fi
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s' "$checks" | jq -sc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$overall" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$status,checks:.}'
}

scaffold_cmd_health() {
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local log="$LEDGER"
  local last_row="null" stale_seconds=-1 status="warn" pass_count=0 refuse_count=0 unverifiable_count=0
  if [[ -r "$log" ]]; then
    local row_raw; row_raw="$(tail -n 1 "$log" 2>/dev/null || true)"
    if [[ -n "$row_raw" ]] && printf '%s' "$row_raw" | jq -e '.' >/dev/null 2>&1; then
      last_row="$row_raw"
      local last_ts; last_ts="$(printf '%s' "$row_raw" | jq -r '.ts // empty' 2>/dev/null || true)"
      if [[ -n "$last_ts" ]]; then
        local last_epoch now_epoch
        last_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_ts" +%s 2>/dev/null || echo 0)"
        now_epoch="$(date -u +%s)"
        if [[ "$last_epoch" -gt 0 ]]; then
          stale_seconds=$((now_epoch - last_epoch))
          [[ "$stale_seconds" -le 604800 ]] && status="pass"
        fi
      fi
    fi
    pass_count="$(grep -c '"decision":"PASS"' "$log" 2>/dev/null; true)"
    refuse_count="$(grep -c '"decision":"REFUSE"' "$log" 2>/dev/null; true)"
    unverifiable_count="$(grep -c '"decision":"UNVERIFIABLE"' "$log" 2>/dev/null; true)"
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log" \
    --arg status "$status" --argjson stale "$stale_seconds" --argjson row "$last_row" \
    --argjson pc "${pass_count:-0}" --argjson rc "${refuse_count:-0}" --argjson uc "${unverifiable_count:-0}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,stale_seconds:$stale,last_row:$row,pass_count:$pc,refuse_count:$rc,unverifiable_count:$uc}'
}

scaffold_cmd_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --scope) scope="${2:-}"; shift 2 ;;
      --dry-run) mode="dry_run"; shift ;;
      --apply) mode="apply"; shift ;;
      --idempotency-key) idem_key="${2:-}"; shift 2 ;;
      --idempotency-key=*) idem_key="${1#--idempotency-key=}"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown repair arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
      '{schema_version:$sv,command:"repair",status:"refused",mode:"apply",scope:$scope,reason:"--apply requires --idempotency-key"}'
    exit 3
  fi
  case "$scope" in
    ledger-rotate)
      local log="$LEDGER" size_bytes=0 rotated=false
      [[ -r "$log" ]] && size_bytes="$(stat -f '%z' "$log" 2>/dev/null || echo 0)"
      if [[ "$mode" == "apply" && "$size_bytes" -gt 5242880 ]]; then
        local rotated_path="${log}.$(date -u +%Y%m%dT%H%M%SZ)"
        mv "$log" "$rotated_path" 2>/dev/null && { : > "$log" 2>/dev/null || true; rotated=true; }
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg log "$log" --argjson sz "$size_bytes" --argjson r "$rotated" \
        '{schema_version:$sv,command:"repair",status:"pass",mode:$mode,scope:$scope,audit_log:$log,size_bytes:$sz,rotation_threshold:5242880,rotated:$r}'
      ;;
    fix-bead-opener-prime)
      local present=false
      [[ -x "$FIX_BEAD_OPENER" ]] && present=true
      local status="pass"; [[ "$present" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg fbo "$FIX_BEAD_OPENER" --arg s "$status" --argjson present "$present" \
        '{schema_version:$sv,command:"repair",status:$s,mode:$mode,scope:$scope,fix_bead_opener:$fbo,present:$present,note:"read-only probe"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        '{schema_version:$sv,command:"repair",status:"unknown_scope",mode:$mode,scope:$scope,known_scopes:["ledger-rotate","fix-bead-opener-prime"]}'
      ;;
  esac
}

scaffold_cmd_validate() {
  local subject="" row_json=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --row-json) subject="row"; row_json="${2:-}"; shift 2 ;;
      --row-json=*) subject="row"; row_json="${1#--row-json=}"; shift ;;
      --schema) subject="schema"; shift ;;
      --config) subject="config"; shift ;;
      --ledger) subject="ledger"; shift ;;
      --json) shift ;;
      *) shift ;;
    esac
  done
  case "$subject" in
    row)
      local valid=true missing=""
      if [[ -z "$row_json" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",subject:"row",status:"fail",valid:false,reason:"--row-json required"}'
        return 0
      fi
      if ! printf '%s' "$row_json" | jq -e '.' >/dev/null 2>&1; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",subject:"row",status:"fail",valid:false,reason:"invalid_json"}'
        return 0
      fi
      for f in schema_version version ts decision; do
        printf '%s' "$row_json" | jq -e --arg k "$f" 'has($k)' >/dev/null 2>&1 || { valid=false; missing="${missing}${f},"; }
      done
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson v "$valid" --arg m "${missing%,}" \
        '{schema_version:$sv,command:"validate",subject:"row",status:(if $v then "pass" else "fail" end),valid:$v,missing:$m}'
      ;;
    schema)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",subject:"schema",status:"pass",surfaces:["doctor","health","repair","validate","audit","why"]}'
      ;;
    config)
      local jq_ok=false fb_ok=false ledger_ok=false repo_ok=false
      command -v jq >/dev/null 2>&1 && jq_ok=true
      [[ -x "$FIX_BEAD_OPENER" ]] && fb_ok=true
      [[ -d "$(dirname "$LEDGER")" ]] && ledger_ok=true
      [[ -d "$REPO" ]] && repo_ok=true
      local overall=pass; [[ "$jq_ok" != true || "$repo_ok" != true ]] && overall=fail
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$overall" \
        --argjson jqq "$jq_ok" --argjson fb "$fb_ok" --argjson ld "$ledger_ok" --argjson r "$repo_ok" \
        --arg ledger "$LEDGER" --arg repo "$REPO" --arg fbo "$FIX_BEAD_OPENER" \
        '{schema_version:$sv,command:"validate",subject:"config",status:$s,jq_present:$jqq,fix_bead_opener_executable:$fb,ledger_dir_present:$ld,repo_dir_present:$r,ledger:$ledger,repo:$repo,fix_bead_opener:$fbo}'
      ;;
    ledger)
      local present=false rows=0 pass_c=0 refuse_c=0 unverifiable_c=0
      if [[ -r "$LEDGER" ]]; then
        present=true
        rows="$(wc -l < "$LEDGER" 2>/dev/null | tr -d ' ' || echo 0)"
        pass_c="$(grep -c '"decision":"PASS"' "$LEDGER" 2>/dev/null; true)"
        refuse_c="$(grep -c '"decision":"REFUSE"' "$LEDGER" 2>/dev/null; true)"
        unverifiable_c="$(grep -c '"decision":"UNVERIFIABLE"' "$LEDGER" 2>/dev/null; true)"
      fi
      local status="pass"; [[ "$present" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg ledger "$LEDGER" \
        --argjson present "$present" --argjson rows "${rows:-0}" \
        --argjson pc "${pass_c:-0}" --argjson rc "${refuse_c:-0}" --argjson uc "${unverifiable_c:-0}" \
        '{schema_version:$sv,command:"validate",subject:"ledger",status:$s,ledger:$ledger,present:$present,row_count:$rows,pass_count:$pc,refuse_count:$rc,unverifiable_count:$uc}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"pass",subjects:["row","schema","config","ledger"]}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",subject:$s,status:"unknown_subject",known:["row","schema","config","ledger"]}'
      ;;
  esac
}

scaffold_cmd_audit() {
  local limit=50
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --limit) limit="${2:-50}"; shift 2 ;;
      --limit=*) limit="${1#--limit=}"; shift ;;
      --json) shift ;;
      *) shift ;;
    esac
  done
  local rows="[]" count=0
  if [[ -r "$LEDGER" ]]; then
    rows="$(tail -n "$limit" "$LEDGER" | jq -sc '. // []' 2>/dev/null || echo '[]')"
    count="$(printf '%s' "$rows" | jq 'length' 2>/dev/null || echo 0)"
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$LEDGER" --argjson rows "$rows" --argjson count "$count" \
    '{schema_version:$sv,command:"audit",audit_log:$log,row_count:$count,rows:$rows}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then printf 'ERR: why requires <id>\n' >&2; return 64; fi
  local matches="[]" status="not_found" any_source_present=false
  if [[ -r "$LEDGER" ]]; then
    any_source_present=true
    local raw; raw="$(grep -F "$id" "$LEDGER" 2>/dev/null || true)"
    [[ -n "$raw" ]] && matches="$(printf '%s' "$raw" | jq -sc '.' 2>/dev/null || echo '[]')"
  fi
  if [[ "$any_source_present" != true ]]; then status="unavailable"
  else
    local n; n="$(printf '%s' "$matches" | jq 'length' 2>/dev/null || echo 0)"
    n="${n//[^0-9]/}"; [[ -z "$n" ]] && n=0
    [[ "$n" -gt 0 ]] && status="found"
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg s "$status" \
    --arg log "$LEDGER" --argjson m "$matches" \
    '{schema_version:$sv,command:"why",id:$id,status:$s,audit_log:$log,matches:$m,total_matches:($m|length)}'
}

_scaffold_is_canonical_arg() {
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart) return 0 ;;
    --schema|--examples) return 0 ;;
    help)
      case "${2:-}" in check|doctor|health|repair|validate|audit|why|-h|--help) return 0 ;; esac
      return 1 ;;
    *) return 1 ;;
  esac
}

if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  case "$1" in
    doctor)       shift; scaffold_cmd_doctor "$@"; exit $? ;;
    health)       shift; scaffold_cmd_health "$@"; exit $? ;;
    repair)       shift; scaffold_cmd_repair "$@"; exit $? ;;
    validate)     shift; scaffold_cmd_validate "$@"; exit $? ;;
    audit)        shift; scaffold_cmd_audit "$@"; exit $? ;;
    why)          shift; scaffold_cmd_why "$@"; exit $? ;;
    quickstart)   shift; scaffold_emit_quickstart "$@"; exit 0 ;;
    --schema)
      shift
      _surface="${1:-default}"
      [[ "$_surface" == "--json" ]] && _surface="default"
      scaffold_emit_schema "$_surface"; exit 0 ;;
    --examples)   shift; examples; exit 0 ;;
    help)         shift; scaffold_emit_topic_help "${1:-}"; exit 0 ;;
  esac
fi
# ====== END canonical-cli scaffold ======

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

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-04-receipt-callback-envelope.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-88-content-addressed-evidence-pack.md`
