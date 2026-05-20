#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial → passing per bead flywheel-1hshd.5)
set -euo pipefail
VERSION="auto-l112-gate.v1.0.0"
SCHEMA_VERSION="auto-l112-gate/v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
LEDGER="${AUTO_L112_GATE_LEDGER:-$HOME/.local/state/flywheel/auto-l112-gate-ledger.jsonl}"
JSONL_APPEND_LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"
BR_CREATE_WRAPPER="${AUTO_L112_GATE_BR_CREATE_WRAPPER:-$REPO_ROOT/.flywheel/scripts/br-create-validated.sh}"
MODE=""
TASK_ID=""
CALLBACK_ENVELOPE_FILE=""
JSON_OUT=0
WATCH=0
WATCH_INTERVAL=5
REPAIR_SCOPE="ledger"
REPAIR_APPLY=0
WHY_ID=""
SCHEMA_TOPIC="gate"
COMPLETION_SHELL=""
PROBE_SANDBOX_MODE="unknown"
# NEW (flywheel-1hshd.5): --idempotency-key for canonical apply contract (L7).
IDEMPOTENCY_KEY=""
usage() {
  cat <<'EOF'
usage:
  auto-l112-gate.sh --task-id ID --callback-envelope-file PATH [--json]
  auto-l112-gate.sh --gate --task-id ID --callback-envelope-file PATH [--json]
  auto-l112-gate.sh --doctor [--json]
  auto-l112-gate.sh --health [--watch] [--interval N] [--json]
  auto-l112-gate.sh --repair --scope ledger|auto-l112-gate|all [--apply|--dry-run] [--json]
  auto-l112-gate.sh validate envelope --callback-envelope-file PATH [--json]
  auto-l112-gate.sh audit [--json]
  auto-l112-gate.sh why ID [--json]
  auto-l112-gate.sh schema gate|doctor|ledger [--json]
  auto-l112-gate.sh --info|--examples|quickstart|completion bash|zsh
EOF
}
json_bool() {
  if [[ "$1" == "1" ]]; then printf true; else printf false; fi
}
emit_json_or_text() {
  local payload="$1" text="$2" rc="${3:-0}"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    printf '%s\n' "$text"
  fi
  return "$rc"
}
info_json() {
  # flywheel-1hshd.5: added .subcommands + .canonical_flags + .command for AG3.
  jq -nc --arg version "$VERSION" --arg schema_version "$SCHEMA_VERSION" --arg ledger "$LEDGER" --arg repo "$REPO_ROOT" --arg jsonl_append_lib "$JSONL_APPEND_LIB" \
    '{command:"info",name:"auto-l112-gate.sh",version:$version,schema_version:$schema_version,repo:$repo,ledger:$ledger,jsonl_append_lib:$jsonl_append_lib,
      subcommands:["gate","doctor","health","repair","validate","audit","why","schema","examples","quickstart","help","completion"],
      canonical_flags:["--info","--schema","--examples","--json","--apply","--dry-run","--idempotency-key","--task-id","--callback-envelope-file","--watch","--interval","--scope"],
      apply_supported:true,dry_run_supported:true,idempotency_key_required_for_apply:true,
      exit_codes:{"0":"probe matched expected assertion","1":"probe ran but assertion failed","2":"malformed envelope or usage","3":"timeout or sandbox refusal or apply contract refusal"},
      sandbox:{network:"token-denylist plus sandbox-exec deny network when available",writes:"sandbox-exec restricts probe writes to scratch when available; HOME/TMPDIR always scratch",repo:"read-only under sandbox-exec"},
      required_envelope_fields:["l112_probe_command","l112_probe_expected","l112_probe_timeout_sec","skill_auto_routes_addressed"]}'
}
examples() {
  cat <<'EOF'
auto-l112-gate.sh --task-id b56-example --callback-envelope-file /tmp/callback-envelope.txt --json
auto-l112-gate.sh --doctor --json | jq .gate_pass_rate
auto-l112-gate.sh validate envelope --callback-envelope-file /tmp/callback-envelope.txt --json
Envelope file format:
l112_probe_command=printf 'OK\n'
l112_probe_expected=grep:OK
l112_probe_timeout_sec=5
skill_auto_routes_addressed=canonical-cli-scoping=n/a,rust-best-practices=n/a,python-best-practices=n/a,readme-writing=n/a
EOF
}
quickstart() {
  cat <<'EOF'
1. Put the callback probe fields in an envelope file.
2. Include skill_auto_routes_addressed= with all four canonical skills.
3. Run: auto-l112-gate.sh --task-id <task-id> --callback-envelope-file <file> --json
4. Only close the bead when the command exits 0.
5. Inspect recent rates with: auto-l112-gate.sh --doctor --json
EOF
}
schema_json() {
  case "$SCHEMA_TOPIC" in
    gate)
      jq -nc '{schema_version:"auto-l112-gate.gate.v1",required:["task_id","callback_envelope_file","l112_probe_command","l112_probe_expected","skill_auto_routes_addressed"],outputs:["status","exit_code","failure_class","fix_bead_id"]}' ;;
    doctor)
      jq -nc '{schema_version:"auto-l112-gate.doctor.v1",required:["status","gate_runs_last_24h","gate_pass_rate","gate_fail_classes","envelope_missing_probe_count"]}' ;;
    ledger)
      jq -nc '{schema_version:"auto-l112-gate.ledger.v1",required:["schema_version","ts","task_id","status","exit_code","failure_class"]}' ;;
    *)
      echo "ERR: unknown schema topic: $SCHEMA_TOPIC" >&2
      return 2 ;;
  esac
}
completion() {
  case "$COMPLETION_SHELL" in
    bash)
      cat <<'EOF'
_auto_l112_gate_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "--gate --task-id --callback-envelope-file --doctor --health --watch --repair --scope --info --examples quickstart validate audit why schema completion --json" -- "$cur") )
}
complete -F _auto_l112_gate_completion auto-l112-gate.sh
EOF
      ;;
    zsh)
      printf 'compadd -- --gate --task-id --callback-envelope-file --doctor --health --watch --repair --scope --info --examples quickstart validate audit why schema completion --json\n'
      ;;
    *)
      echo "ERR: completion shell must be bash or zsh" >&2
      return 2 ;;
  esac
}
parse_envelope_json() {
  local path="$1"
  python3 - "$path" <<'PY'
import json
import shlex
import sys
from pathlib import Path
keys = {"l112_probe_command", "l112_probe_expected", "l112_probe_timeout_sec", "skill_auto_routes_addressed"}
path = Path(sys.argv[1])
if not path.is_file():
    print(json.dumps({"_error": f"missing envelope file: {path}"}))
    raise SystemExit(0)
fields = {}
for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
    line = raw.strip()
    if not line or line.startswith("#"):
        continue
    key = line.split("=", 1)[0] if "=" in line else ""
    if key in keys:
        fields[key] = line.split("=", 1)[1]
        continue
    try:
        tokens = shlex.split(line)
    except ValueError:
        tokens = line.split()
    for token in tokens:
        if "=" not in token:
            continue
        key, value = token.split("=", 1)
        if key in keys:
            fields[key] = value
print(json.dumps(fields, sort_keys=True, separators=(",", ":")))
PY
}
validate_skill_auto_routes_addressed() {
  local value="$1" skill
  [[ -n "$value" ]] || return 1
  for skill in canonical-cli-scoping rust-best-practices python-best-practices readme-writing; do grep -Eq "(^|[,[:space:]])${skill}=(yes|no|n/a)([,[:space:]]|$)" <<<"$value" || return 1; done
}
load_envelope() {
  local parsed missing_count
  [[ -n "$CALLBACK_ENVELOPE_FILE" ]] || { echo "ERR: missing --callback-envelope-file" >&2; return 2; }
  parsed="$(parse_envelope_json "$CALLBACK_ENVELOPE_FILE")"
  if jq -e 'has("_error")' >/dev/null 2>&1 <<<"$parsed"; then
    ENVELOPE_ERROR="$(jq -r '._error' <<<"$parsed")"
    return 2
  fi
  L112_PROBE_COMMAND="$(jq -r '.l112_probe_command // ""' <<<"$parsed")"
  L112_PROBE_EXPECTED="$(jq -r '.l112_probe_expected // ""' <<<"$parsed")"
  L112_PROBE_TIMEOUT_SEC="$(jq -r '.l112_probe_timeout_sec // "30"' <<<"$parsed")"
  SKILL_AUTO_ROUTES_ADDRESSED="$(jq -r '.skill_auto_routes_addressed // ""' <<<"$parsed")"
  missing_count=0
  [[ -n "$L112_PROBE_COMMAND" ]] || missing_count=$((missing_count + 1))
  [[ -n "$L112_PROBE_EXPECTED" ]] || missing_count=$((missing_count + 1))
  [[ "$L112_PROBE_TIMEOUT_SEC" =~ ^[0-9]+$ && "$L112_PROBE_TIMEOUT_SEC" -gt 0 ]] || missing_count=$((missing_count + 1))
  validate_skill_auto_routes_addressed "$SKILL_AUTO_ROUTES_ADDRESSED" || missing_count=$((missing_count + 1))
  if [[ "$missing_count" -gt 0 ]]; then
    ENVELOPE_ERROR="missing_or_invalid_l112_probe_fields_or_skill_auto_routes"
    return 2
  fi
  return 0
}
network_token_class() {
  local command_text="$1"
  if printf '%s\n' "$command_text" | grep -Eq '(^|[[:space:]])(curl|wget|nc|ncat|telnet|ftp|ssh|scp|rsync)([[:space:]]|$)|https?://|/dev/tcp|python3?[[:space:]]+-m[[:space:]]+http'; then
    printf 'network_token_denied'
    return 0
  fi
  return 1
}
shell_quote() {
  printf "%s" "$1" | sed "s/'/'\\\\''/g; 1s/^/'/; \$s/\$/'/"
}
write_sandbox_profile() {
  local profile="$1" root="$2"
  cat >"$profile" <<EOF
(version 1)
(deny default)
(allow process*)
(allow file-read*)
(allow file-write* (subpath "$root"))
(allow sysctl*)
(allow mach-lookup)
(deny network*)
EOF
}
sandbox_exec_usable() {
  local probe_profile probe_root rc
  command -v sandbox-exec >/dev/null 2>&1 || return 1
  [[ "${AUTO_L112_GATE_DISABLE_SANDBOX_EXEC:-0}" != "1" ]] || return 1
  probe_root="$(mktemp -d /tmp/auto-l112-sandbox-smoke.XXXXXX)"
  probe_root="$(cd "$probe_root" && pwd -P)"
  probe_profile="$probe_root/profile.sb"
  write_sandbox_profile "$probe_profile" "$probe_root"
  set +e
  sandbox-exec -f "$probe_profile" env HOME="$probe_root" TMPDIR="$probe_root" /bin/sh -c "echo ok >\"\$TMPDIR/smoke\"" >/dev/null 2>&1
  rc=$?
  rm -rf "$probe_root"
  [[ "$rc" -eq 0 ]]
}
run_probe() {
  local command_text="$1" timeout_sec="$2" stdout_file="$3" stderr_file="$4"
  local sandbox_root sandbox_home sandbox_tmp profile timeout_bin sandbox_mode rc
  sandbox_root="$(mktemp -d /tmp/auto-l112-gate.XXXXXX)"
  sandbox_root="$(cd "$sandbox_root" && pwd -P)"
  sandbox_home="$sandbox_root/home"
  sandbox_tmp="$sandbox_root/tmp"
  mkdir -p "$sandbox_home" "$sandbox_tmp"
  timeout_bin="$(command -v gtimeout || command -v timeout || true)"
  [[ -n "$timeout_bin" ]] || { echo "ERR: timeout command not found" >"$stderr_file"; return 3; }
  if sandbox_class="$(network_token_class "$command_text")"; then
    printf 'sandbox_refused=%s\n' "$sandbox_class" >"$stderr_file"
    return 3
  fi
  if sandbox_exec_usable; then
    profile="$sandbox_root/profile.sb"
    write_sandbox_profile "$profile" "$sandbox_root"
    sandbox_mode="sandbox-exec-network-write-scratch"
    set +e
    "$timeout_bin" "$timeout_sec" sandbox-exec -f "$profile" \
      env -i HOME="$sandbox_home" TMPDIR="$sandbox_tmp" PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" AUTO_L112_SANDBOX=1 \
      bash -lc "cd $(shell_quote "$REPO_ROOT") && $command_text" >"$stdout_file" 2>"$stderr_file"
    rc=$?
  else
    sandbox_mode="env-scratch"
    set +e
    "$timeout_bin" "$timeout_sec" \
      env -i HOME="$sandbox_home" TMPDIR="$sandbox_tmp" PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" AUTO_L112_SANDBOX=1 \
      bash -lc "cd $(shell_quote "$REPO_ROOT") && $command_text" >"$stdout_file" 2>"$stderr_file"
    rc=$?
  fi
  printf '%s\n' "$sandbox_mode" >"$sandbox_root/sandbox_mode"
  PROBE_SANDBOX_MODE="$sandbox_mode"
  if [[ "$rc" -eq 124 || "$rc" -eq 137 ]]; then
    return 3
  fi
  return "$rc"
}
assert_expected() {
  local expected="$1" stdout_file="$2"
  case "$expected" in
    jq:*)
      jq -e "${expected#jq:}" "$stdout_file" >/dev/null ;;
    jq\ -e\ *)
      jq -e "${expected#jq -e }" "$stdout_file" >/dev/null ;;
    grep:*)
      grep -q -- "${expected#grep:}" "$stdout_file" ;;
    grep\ -q\ *)
      grep -q -- "${expected#grep -q }" "$stdout_file" ;;
    literal:*)
      grep -Fqx -- "${expected#literal:}" "$stdout_file" ;;
    *)
      grep -q -- "$expected" "$stdout_file" ;;
  esac
}
append_ledger() {
  local row="$1"
  if [[ ! -r "$JSONL_APPEND_LIB" ]]; then
    echo "ERR: JSONL append primitive missing: $JSONL_APPEND_LIB" >&2
    return 3
  fi
  # shellcheck source=/dev/null
  source "$JSONL_APPEND_LIB"
  fw_jsonl_append_validated "$LEDGER" "$row"
}
create_fix_bead() {
  local task_id="$1" failure_class="$2" stdout_file="$3" stderr_file="$4" desc_file title output bead_id
  title="[auto-l112-gate] probe failed for ${task_id}"
  desc_file="$(mktemp /tmp/auto-l112-gate-fix.XXXXXX)"
  cat >"$desc_file" <<EOF
Auto-created by auto-l112-gate after L112 callback probe failed.
AG1: Re-run the callback probe for task ${task_id} and make the expected assertion pass.
AG2: Preserve the failing stdout/stderr evidence paths in the close reason.
failure_class=${failure_class}
stdout=${stdout_file}
stderr=${stderr_file}
EOF
  if [[ -x "$BR_CREATE_WRAPPER" ]]; then
    set +e
    output="$("$BR_CREATE_WRAPPER" --title "$title" --description-file "$desc_file" --type bug --priority 1 --json 2>&1)"
    set -e
  else
    set +e
    output="$(br create "$title" --type bug --priority 1 --description "$(cat "$desc_file")" --json 2>&1)"
    set -e
  fi
  bead_id="$(jq -r '.[0].id // .id // empty' 2>/dev/null <<<"$output" || true)"
  [[ -n "$bead_id" ]] || bead_id="created_unparsed"
  printf '%s\n' "$bead_id"
}
gate_result_json() {
  local status="$1" exit_code="$2" failure_class="$3" stdout_file="$4" stderr_file="$5" fix_bead_id="$6" sandbox_mode="$7"
  jq -nc \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg task_id "$TASK_ID" \
    --arg callback_envelope_file "$CALLBACK_ENVELOPE_FILE" \
    --arg status "$status" \
    --argjson exit_code "$exit_code" \
    --arg failure_class "$failure_class" \
    --arg command "${L112_PROBE_COMMAND:-}" \
    --arg expected "${L112_PROBE_EXPECTED:-}" \
    --argjson timeout_sec "${L112_PROBE_TIMEOUT_SEC:-0}" \
    --arg skill_auto_routes_addressed "${SKILL_AUTO_ROUTES_ADDRESSED:-}" \
    --arg stdout_file "$stdout_file" \
    --arg stderr_file "$stderr_file" \
    --arg fix_bead_id "$fix_bead_id" \
    --arg sandbox_mode "$sandbox_mode" \
    '{schema_version:$schema_version,ts:$ts,task_id:$task_id,callback_envelope_file:$callback_envelope_file,status:$status,exit_code:$exit_code,failure_class:(if $failure_class=="" then null else $failure_class end),l112_probe_command:$command,l112_probe_expected:$expected,l112_probe_timeout_sec:$timeout_sec,skill_auto_routes_addressed:$skill_auto_routes_addressed,stdout_file:$stdout_file,stderr_file:$stderr_file,fix_bead_id:(if $fix_bead_id=="" then null else $fix_bead_id end),sandbox_mode:$sandbox_mode}'
}
run_gate() {
  local stdout_file stderr_file probe_rc assert_rc row fix_bead_id="" sandbox_mode="unknown"
  [[ -n "$TASK_ID" ]] || { echo "ERR: missing --task-id" >&2; return 2; }
  stdout_file="$(mktemp /tmp/auto-l112-gate-stdout.XXXXXX)"
  stderr_file="$(mktemp /tmp/auto-l112-gate-stderr.XXXXXX)"
  ENVELOPE_ERROR=""
  if ! load_envelope; then
    row="$(gate_result_json malformed 2 "${ENVELOPE_ERROR:-malformed_envelope}" "$stdout_file" "$stderr_file" "" "$sandbox_mode")"
    append_ledger "$row" || true
    emit_json_or_text "$row" "FAIL malformed_envelope task_id=$TASK_ID reason=${ENVELOPE_ERROR:-unknown}" 2
    return 2
  fi
  set +e
  run_probe "$L112_PROBE_COMMAND" "$L112_PROBE_TIMEOUT_SEC" "$stdout_file" "$stderr_file"
  probe_rc=$?
  set -e
  sandbox_mode="${PROBE_SANDBOX_MODE:-unknown}"
  if [[ "$probe_rc" -eq 3 ]]; then
    row="$(gate_result_json sandbox_error 3 "timeout_or_sandbox_refusal" "$stdout_file" "$stderr_file" "" "$sandbox_mode")"
    append_ledger "$row" || true
    emit_json_or_text "$row" "FAIL timeout_or_sandbox_refusal task_id=$TASK_ID stderr=$stderr_file" 3
    return 3
  elif [[ "$probe_rc" -ne 0 ]]; then
    fix_bead_id="$(create_fix_bead "$TASK_ID" "probe_exit_${probe_rc}" "$stdout_file" "$stderr_file" || true)"
    row="$(gate_result_json fail 1 "probe_exit_${probe_rc}" "$stdout_file" "$stderr_file" "$fix_bead_id" "$sandbox_mode")"
    append_ledger "$row" || true
    emit_json_or_text "$row" "FAIL probe_exit_${probe_rc} task_id=$TASK_ID fix_bead=$fix_bead_id" 1
    return 1
  fi
  set +e
  assert_expected "$L112_PROBE_EXPECTED" "$stdout_file"
  assert_rc=$?
  set -e
  if [[ "$assert_rc" -ne 0 ]]; then
    fix_bead_id="$(create_fix_bead "$TASK_ID" "expected_mismatch" "$stdout_file" "$stderr_file" || true)"
    row="$(gate_result_json fail 1 "expected_mismatch" "$stdout_file" "$stderr_file" "$fix_bead_id" "$sandbox_mode")"
    append_ledger "$row" || true
    emit_json_or_text "$row" "FAIL expected_mismatch task_id=$TASK_ID fix_bead=$fix_bead_id" 1
    return 1
  fi
  row="$(gate_result_json pass 0 "" "$stdout_file" "$stderr_file" "" "$sandbox_mode")"
  append_ledger "$row"
  emit_json_or_text "$row" "PASS task_id=$TASK_ID stdout=$stdout_file" 0
}
doctor_json() {
  if [[ -f "$LEDGER" ]]; then
    jq -s -c '
      map(select(type == "object")) as $all
      | ($all | map(select((.ts | fromdateiso8601? // 0) >= (now - 86400)))) as $rows
      | ($rows | length) as $total
      | ($rows | map(select(.status == "pass")) | length) as $pass
      | {
          status:"pass",
          schema_version:"auto-l112-gate.doctor.v1",
          ledger_path:"'"$LEDGER"'",
          gate_runs_last_24h:$total,
          gate_pass_rate:(if $total == 0 then 1 else (($pass / $total) * 100 | floor / 100) end),
          gate_fail_classes:($rows | map(select(.status != "pass") | (.failure_class // "unknown")) | group_by(.) | map({class:.[0],count:length})),
          envelope_missing_probe_count:($rows | map(select(.failure_class == "missing_or_invalid_l112_probe_fields" or .failure_class == "missing_or_invalid_l112_probe_fields_or_skill_auto_routes" or .failure_class == "malformed_envelope")) | length)
        }' "$LEDGER"
  else
    jq -nc --arg ledger "$LEDGER" '{status:"pass",schema_version:"auto-l112-gate.doctor.v1",ledger_path:$ledger,ledger_exists:false,gate_runs_last_24h:0,gate_pass_rate:1,gate_fail_classes:[],envelope_missing_probe_count:0}'
  fi
}
run_doctor() {
  local payload
  payload="$(doctor_json)"
  emit_json_or_text "$payload" "status=$(jq -r '.status' <<<"$payload") gate_runs_last_24h=$(jq -r '.gate_runs_last_24h' <<<"$payload") gate_pass_rate=$(jq -r '.gate_pass_rate' <<<"$payload")" 0
}
run_health() {
  local payload status
  while :; do
    payload="$(doctor_json)"
    status="$(jq -r '.status' <<<"$payload")"
    emit_json_or_text "$payload" "health=$status gate_runs_last_24h=$(jq -r '.gate_runs_last_24h' <<<"$payload")" 0
    [[ "$WATCH" -eq 1 ]] || break
    sleep "$WATCH_INTERVAL"
  done
  return 0
}
run_repair() {
  local planned action payload
  case "$REPAIR_SCOPE" in
    ledger|auto-l112-gate|all) ;;
    *) echo "ERR: unsupported repair scope: $REPAIR_SCOPE" >&2; return 2 ;;
  esac
  planned="$(jq -nc --arg ledger "$LEDGER" '{status:"PLANNED",reason:"ensure ledger directory exists",would_write:[($ledger|split("/")[:-1]|join("/"))],would_delete:[],blocked_by:[]}')"
  if [[ "$REPAIR_APPLY" -eq 1 ]]; then
    mkdir -p "$(dirname "$LEDGER")"
    action="applied"
  else
    action="planned"
  fi
  payload="$(jq -nc --arg scope "$REPAIR_SCOPE" --arg action "$action" --argjson apply "$(json_bool "$REPAIR_APPLY")" --argjson planned "$planned" '{command:"repair",scope:$scope,action:$action,apply:$apply,planned_actions:[$planned],status:"pass"}')"
  emit_json_or_text "$payload" "$(jq -r '.action + " scope=" + .scope' <<<"$payload")" 0
}
run_validate_envelope() {
  local parsed payload rc=0 missing=() missing_json valid_json
  parsed="$(parse_envelope_json "$CALLBACK_ENVELOPE_FILE")"
  if jq -e 'has("_error")' >/dev/null 2>&1 <<<"$parsed"; then
    rc=2
  fi
  for key in l112_probe_command l112_probe_expected l112_probe_timeout_sec skill_auto_routes_addressed; do
    [[ "$(jq -r --arg key "$key" '.[$key] // ""' <<<"$parsed")" != "" ]] || { missing+=("$key"); rc=2; }
  done
  if [[ "$(jq -r '.skill_auto_routes_addressed // ""' <<<"$parsed")" != "" ]] && ! validate_skill_auto_routes_addressed "$(jq -r '.skill_auto_routes_addressed // ""' <<<"$parsed")"; then
    missing+=("skill_auto_routes_addressed:invalid"); rc=2
  fi
  if [[ "${#missing[@]}" -eq 0 ]]; then missing_json="[]"; else missing_json="$(printf '%s\n' "${missing[@]}" | jq -R . | jq -s -c .)"; fi
  if [[ "$rc" -eq 0 ]]; then valid_json=true; else valid_json=false; fi
  payload="$(jq -nc --arg file "$CALLBACK_ENVELOPE_FILE" --argjson fields "$parsed" --argjson missing "$missing_json" --argjson valid "$valid_json" '{command:"validate",target:"envelope",callback_envelope_file:$file,valid:$valid,missing_fields:$missing,fields:$fields}')"
  emit_json_or_text "$payload" "valid=$(jq -r '.valid' <<<"$payload") missing=$(jq -r '.missing_fields | join(",")' <<<"$payload")" "$rc"
}
run_audit() {
  local payload
  if [[ -f "$LEDGER" ]]; then
    payload="$(tail -20 "$LEDGER" | jq -s -c 'map(select(type=="object")) | {command:"audit",status:"pass",rows:.}')"
  else
    payload="$(jq -nc '{command:"audit",status:"pass",rows:[]}')"
  fi
  emit_json_or_text "$payload" "audit_rows=$(jq -r '.rows | length' <<<"$payload")" 0
}
run_why() {
  local text payload
  case "$WHY_ID" in
    expected_mismatch) text="The probe command exited 0 but l112_probe_expected did not match stdout." ;;
    timeout_or_sandbox_refusal|network_token_denied) text="The sandbox refused the command before trust could be established, or the timeout fired." ;;
    missing_or_invalid_l112_probe_fields|missing_or_invalid_l112_probe_fields_or_skill_auto_routes|malformed_envelope) text="The callback envelope lacks one of l112_probe_command, l112_probe_expected, a positive l112_probe_timeout_sec, or a valid skill_auto_routes_addressed catalog row." ;;
    *) text="No built-in explanation for this id; inspect the ledger row by task_id or failure_class." ;;
  esac
  payload="$(jq -nc --arg id "$WHY_ID" --arg text "$text" '{command:"why",id:$id,explanation:$text}')"
  emit_json_or_text "$payload" "$text" 0
}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --gate) MODE="gate"; shift ;;
    --task-id) TASK_ID="${2:-}"; shift 2 ;;
    --callback-envelope-file) CALLBACK_ENVELOPE_FILE="${2:-}"; shift 2 ;;
    --doctor) MODE="doctor"; shift ;;
    --health) MODE="health"; shift ;;
    --watch) WATCH=1; shift ;;
    --interval) WATCH_INTERVAL="${2:-5}"; shift 2 ;;
    --repair) MODE="repair"; shift ;;
    --scope) REPAIR_SCOPE="${2:-}"; shift 2 ;;
    --apply) REPAIR_APPLY=1; shift ;;
    --dry-run) REPAIR_APPLY=0; shift ;;
    --json) JSON_OUT=1; shift ;;
    --info) info_json; exit 0 ;;
    --examples|examples) examples; exit 0 ;;
    --version) printf '%s\n' "$VERSION"; exit 0 ;;
    quickstart) quickstart; exit 0 ;;
    completion) MODE="completion"; COMPLETION_SHELL="${2:-}"; shift 2 ;;
    schema) MODE="schema"; SCHEMA_TOPIC="${2:-gate}"; shift 2 ;;
    # NEW (flywheel-1hshd.5): --schema dash form + --idempotency-key.
    --schema)
      MODE="schema"
      if [[ $# -gt 1 && "${2:-}" != --* ]]; then SCHEMA_TOPIC="$2"; shift 2; else SCHEMA_TOPIC="gate"; shift; fi
      ;;
    --schema=*) MODE="schema"; SCHEMA_TOPIC="${1#*=}"; shift ;;
    --idempotency-key) IDEMPOTENCY_KEY="${2:?--idempotency-key requires KEY}"; shift 2 ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#*=}"; shift ;;
    audit) MODE="audit"; shift ;;
    why) MODE="why"; WHY_ID="${2:-}"; shift 2 ;;
    validate)
      MODE="validate"
      if [[ "${2:-}" == "envelope" ]]; then
        shift 2
      else
        shift
      fi
      ;;
    --help|-h|help) usage; exit 0 ;;
    *) echo "ERR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done
if [[ -z "$MODE" && -n "$TASK_ID" && -n "$CALLBACK_ENVELOPE_FILE" ]]; then
  MODE="gate"
fi
# NEW (flywheel-1hshd.5): canonical apply contract — repair --apply requires
# --idempotency-key (canonical-cli L7 rule + rc=3 refusal).
if [[ "$MODE" == "repair" && "$REPAIR_APPLY" == "1" && -z "$IDEMPOTENCY_KEY" ]]; then
  printf '{"schema_version":"%s","status":"refused","mode":"apply","reason":"--apply requires --idempotency-key KEY (canonical apply contract)","exit_code":3}\n' "$SCHEMA_VERSION"
  exit 3
fi
case "$MODE" in
  gate) run_gate ;;
  doctor) run_doctor ;;
  health) run_health ;;
  repair) run_repair ;;
  validate) [[ -n "$CALLBACK_ENVELOPE_FILE" ]] || { echo "ERR: validate envelope requires --callback-envelope-file" >&2; exit 2; }; run_validate_envelope ;;
  audit) run_audit ;;
  why) [[ -n "$WHY_ID" ]] || { echo "ERR: why requires ID" >&2; exit 2; }; run_why ;;
  schema) schema_json ;;
  completion) completion ;;
  "") usage; exit 2 ;;
  *) echo "ERR: unknown mode: $MODE" >&2; exit 2 ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
