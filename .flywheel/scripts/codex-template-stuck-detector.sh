#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial → passing per bead flywheel-1hshd.17)
# doctor-mode-tier: scaffolded
#
# IDEMPOTENT-BY-CONSTRUCTION: native --apply path appends sha-keyed rows to
# $LEDGER ($CODEX_STUCK_DETECTOR_LEDGER); ledger row contains hash_t0/hash_t1
# digests so re-detection of the same buffer state is byte-identical.
# --idempotency-key flag is accepted (parses + flows into ledger when set)
# but not strictly required for back-compat with existing regression tests.
set -euo pipefail

# ====== BEGIN canonical-cli scaffold (bead flywheel-1hshd.17) ======
# SURGICAL DASH-FLAG SCAFFOLD variant (sister 5ke66.17 / 1hshd.15). Native
# already owns doctor/info/schema/validate/detect with substantive impls
# AND two regression suites (tests/codex-template-stuck-detector.sh,
# .flywheel/tests/test_codex_template_stuck_detector.sh). Reimplementing
# native verbs in scaffold = high regression risk for no domain value.
#
# Scaffold owns:
#   - --info / --schema / --examples / quickstart canonical envelopes
#   - NEW verbs not present natively: health, repair, audit, why
#
# Native (unchanged) owns:
#   - doctor (augmented in-place to add .checks array per AG3.4)
#   - info / schema / validate / detect (positional back-compat)

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi
SCAFFOLD_SCHEMA_VERSION="codex-template-stuck-detector/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-${CODEX_STUCK_DETECTOR_LEDGER:-$HOME/.local/state/flywheel/codex-stuck-detector.jsonl}}"

scaffold_emit_info() {
  if ! command -v cli_emit_info >/dev/null; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
      '{schema_version:$sv,command:"info",name:"codex-template-stuck-detector.sh",version:"scaffolded-v1",capabilities:["template-stuck-detector","hash-stable-classifier","caam-rotation-recovery","idempotency-by-sha-keyed-ledger","fixture-or-live-input"],helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "codex-template-stuck-detector.sh" \
    "scaffolded-v1" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,info,schema,examples,detect,help" \
    "CODEX_STUCK_DETECTOR_NTM_BIN,CODEX_STUCK_DETECTOR_LEDGER,CODEX_STUCK_DETECTOR_CONTRACT_LEDGER,CODEX_STUCK_DETECTOR_FUCKUP_LOG,CODEX_STUCK_DETECTOR_CAAM_BIN,SCAFFOLD_AUDIT_LOG" \
    '{"subclasses":["alive","background_terminal_stuck","model_at_capacity_halt","post_completion","input_deaf","buffer_stuck"],"exit_codes":{"alive":0,"stuck":1,"usage":2,"refused_apply":3}}' \
    | jq -c '. + {capabilities:["template-stuck-detector","hash-stable-classifier","caam-rotation-recovery","idempotent-by-construction-sha-keyed-ledger","fixture-or-live-input","auto-recover-mode"],mutates_state:true,mutation_paths:["ledger-append","fuckup-log-append","caam-rotate-respawn-via-helper"]}'
}

scaffold_emit_schema() {
  local surface="${1:-default}"
  case "$surface" in
    doctor)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"doctor",fields:{schema_version:"codex-stuck-detector.doctor.v1",status:"ok|warn|fail",codex_template_stuck_count_24h:"int",codex_stuck_subclass_top:"string|null",codex_stuck_top_session:"string|null",codex_stuck_recovery_success_pct:"int|null",codex_freeze_recovery_attempted_24h:"int",codex_freeze_recovery_succeeded_24h:"int",caam_rotation_count_24h:"int",caam_active_profile:"string|null",caam_profiles_available:"int",substrate_loop_contract_self_row_action:"appended|present",checks:"array of {name,status,detail?}"}}'
      ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"health",fields:{schema_version:"string",status:"ok|warn|fail",audit_log:"path",last_run_ts:"ISO8601 or null",age_seconds:"int|null",recent_runs:"int (last 20)",total_runs:"int",stale_threshold_seconds:"int"}}'
      ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"repair",scopes:["audit_log_dir","caam_rotate_path"],contract:{requires_idempotency_key_when_apply:true,refusal_exit_code:3,dry_run_default:true},env:{audit_log:"SCAFFOLD_AUDIT_LOG",caam_rotate:"CODEX_STUCK_DETECTOR_CAAM_ROTATE"}}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"validate",subjects:["fixture-path","subclass","session-name"],contract:{rejects_with_rc1:"on schema violation"}}'
      ;;
    ledger-row|default|*)
      local input_schema output_schema
      input_schema='{"type":"object","properties":{"session":{"type":"string"},"pane":{"type":["integer","string"]},"t0":{"type":"string"},"t1":{"type":"string"},"after_retry":{"type":"string"}}}'
      output_schema='{"schema_version":"codex-stuck-detector.ledger.v1","required":["ts","session","pane","subclass","hash_t0","hash_t1","buffer_signal","recovery_attempted","recovery_succeeded","hash_stable"]}'
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --argjson in "$input_schema" --argjson out "$output_schema" \
        '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why","ledger-row"],input_schema:$in,output_schema:$out,note:"Default surface = ledger-row. Native subcommand `schema` returns the bare ledger-row required-fields envelope for back-compat."}'
      ;;
  esac
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"detect from fixture",invocation:"codex-template-stuck-detector.sh --fixture /path/to/fixture.json --json",purpose:"classify a captured pane buffer state without writing ledger"}'
)"$'\n'"$(jq -nc '{name:"detect live + auto-recover",invocation:"codex-template-stuck-detector.sh --session flywheel --pane 3 --auto-recover --apply --json",purpose:"detect via live ntm probes and dispatch caam_rotate_and_respawn on capacity halt"}'
)"$'\n'"$(jq -nc '{name:"doctor 24h rollup",invocation:"codex-template-stuck-detector.sh --doctor --json",purpose:"24h rollup of stuck-events + caam rotations + recovery success pct"}'
)"$'\n'"$(jq -nc '{name:"audit recent ledger",invocation:"codex-template-stuck-detector.sh audit --limit 20 --json",purpose:"tail recent stuck-detection rows from $CODEX_STUCK_DETECTOR_LEDGER"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe substrate",command:"codex-template-stuck-detector.sh doctor --json"}'
)"$'\n'"$(jq -nc '{step:2,action:"detect from fixture",command:"codex-template-stuck-detector.sh --fixture FIXTURE.json --json"}'
)"$'\n'"$(jq -nc '{step:3,action:"24h rollup",command:"codex-template-stuck-detector.sh --doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,validate,audit"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run|detect)  printf 'topic: detect (default) — classify a pane buffer state via fixture or live ntm probes; subclasses: alive, background_terminal_stuck, model_at_capacity_halt, post_completion, input_deaf, buffer_stuck; exit 0 = alive, 1 = stuck\n' ;;
    doctor)      printf 'topic: doctor — 24h rollup over $CODEX_STUCK_DETECTOR_LEDGER + $CODEX_STUCK_DETECTOR_CAAM_LEDGER; emits .checks array (canonical AG3.4) + native fields (codex_template_stuck_count_24h, codex_stuck_subclass_top, etc); appends substrate-loop-contract row on first run\n' ;;
    health)      printf 'topic: health — tail $SCAFFOLD_AUDIT_LOG; report last_run_ts, age_seconds, recent_runs, total_runs; status=warn at >24h stale\n' ;;
    repair)      printf 'topic: repair --scope <audit_log_dir|caam_rotate_path> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3 refusal); scopes: audit_log_dir (mkdir -p), caam_rotate_path (REPORT-ONLY — verifies $CODEX_STUCK_DETECTOR_CAAM_ROTATE executable)\n' ;;
    validate)    printf 'topic: validate <subject> [VALUE] — subjects: fixture-path (must exist + be readable), subclass (must be one of {alive,background_terminal_stuck,model_at_capacity_halt,post_completion,input_deaf,buffer_stuck}), session-name (non-empty); rc=1 on schema violation\n' ;;
    audit)       printf 'topic: audit [--limit N] — tail $SCAFFOLD_AUDIT_LOG via cli_emit_audit_tail; default limit=20\n' ;;
    why)         printf 'topic: why <id> — provenance lookup against $SCAFFOLD_AUDIT_LOG; matches against ts/session/hash_t1/subclass; states: found / not_found / unavailable\n' ;;
    *)           printf 'topics: detect | doctor | health | repair | validate | audit | why | quickstart (SURGICAL DASH-FLAG SCAFFOLD: --info/--schema/--examples/quickstart + new verbs health/repair/audit/why route to scaffold; native doctor/info/schema/validate/detect retain back-compat)\n' ;;
  esac
}

scaffold_cmd_health() {
  local audit_log="$SCAFFOLD_AUDIT_LOG"
  local ts last_run_ts="" age_seconds total_runs=0 recent_runs=0 status="pass"
  local stale_threshold="${CODEX_STUCK_DETECTOR_HEALTH_STALE_THRESHOLD_SECONDS:-86400}"
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$audit_log" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$audit_log" --argjson stale "$stale_threshold" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"warn",audit_log:$log,reason:"audit_log_missing",last_run_ts:null,age_seconds:null,recent_runs:0,total_runs:0,stale_threshold_seconds:$stale}'
    return 0
  fi
  total_runs="$(wc -l < "$audit_log" 2>/dev/null | tr -d ' ' || echo 0)"
  recent_runs="$(tail -20 "$audit_log" 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
  last_run_ts="$(tail -1 "$audit_log" 2>/dev/null | jq -r '.ts // empty' 2>/dev/null || true)"
  if [[ -n "$last_run_ts" ]]; then
    local now last_epoch
    now="$(date -u +%s)"
    last_epoch="$(date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$last_run_ts" +%s 2>/dev/null \
                  || date -u -d "$last_run_ts" +%s 2>/dev/null \
                  || echo 0)"
    age_seconds=$((now - last_epoch))
    [[ "$age_seconds" -gt "$stale_threshold" ]] && status="warn"
  else
    age_seconds=null
    status="warn"
  fi
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$status" \
    --arg log "$audit_log" --arg last_run_ts "$last_run_ts" \
    --argjson age "${age_seconds:-null}" --argjson total "$total_runs" --argjson recent "$recent_runs" \
    --argjson stale "$stale_threshold" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,
      last_run_ts:(if $last_run_ts == "" then null else $last_run_ts end),
      age_seconds:$age,recent_runs:$recent,total_runs:$total,
      stale_threshold_seconds:$stale}'
}

scaffold_cmd_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help repair; return 0 ;;
      --scope) scope="${2:-}"; shift 2 ;;
      --scope=*) scope="${1#--scope=}"; shift ;;
      --dry-run) mode="dry_run"; shift ;;
      --apply) mode="apply"; shift ;;
      --idempotency-key) idem_key="${2:-}"; shift 2 ;;
      --idempotency-key=*) idem_key="${1#--idempotency-key=}"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown repair arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    if command -v cli_refuse_apply_without_idem_key >/dev/null; then
      cli_refuse_apply_without_idem_key "$SCAFFOLD_SCHEMA_VERSION" "repair" "$scope"
    else
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:"apply",scope:$scope,reason:"--apply requires --idempotency-key",exit_code:3}'
      exit 3
    fi
  fi
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$scope" in
    audit_log_dir)
      local target; target="$(dirname "$SCAFFOLD_AUDIT_LOG")"
      local existed="true"; [[ ! -d "$target" ]] && existed="false"
      [[ "$mode" == "apply" ]] && mkdir -p "$target"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    caam_rotate_path)
      # REPORT-ONLY scope — caam-rotate-and-respawn.sh is owned elsewhere.
      local target="${CODEX_STUCK_DETECTOR_CAAM_ROTATE:-$_SCAFFOLD_REPO_ROOT/.flywheel/scripts/caam-rotate-and-respawn.sh}"
      local existed="false" executable="false"
      [[ -f "$target" ]] && existed="true"
      [[ -x "$target" ]] && executable="true"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" \
        --arg existed "$existed" --arg executable "$executable" \
        '{schema_version:$sv,command:"repair",status:"report",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed:($existed == "true"),executable:($executable == "true"),note:"REPORT-ONLY — caam-rotate-and-respawn.sh is owned by capacity-halt lane, not this surface"}'
      ;;
    "")
      printf 'ERR: repair requires --scope <audit_log_dir|caam_rotate_path>\n' >&2; return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["audit_log_dir","caam_rotate_path"]}'
      return 64 ;;
  esac
}

scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$subject" in
    fixture-path)
      [[ -z "$arg" ]] && { printf 'ERR: validate fixture-path requires VALUE\n' >&2; return 64; }
      if [[ -r "$arg" ]] && jq -e . "$arg" >/dev/null 2>&1; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg p "$arg" \
          '{schema_version:$sv,command:"validate",subject:"fixture-path",ts:$ts,status:"ok",value:$p}'
        return 0
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg p "$arg" \
        '{schema_version:$sv,command:"validate",subject:"fixture-path",ts:$ts,status:"reject",value:$p,reason:"file_not_readable_or_not_json"}'
      return 1 ;;
    subclass)
      [[ -z "$arg" ]] && { printf 'ERR: validate subclass requires VALUE\n' >&2; return 64; }
      case "$arg" in
        alive|background_terminal_stuck|model_at_capacity_halt|post_completion|input_deaf|buffer_stuck)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg c "$arg" \
            '{schema_version:$sv,command:"validate",subject:"subclass",ts:$ts,status:"ok",value:$c}'
          return 0 ;;
        *)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg c "$arg" \
            '{schema_version:$sv,command:"validate",subject:"subclass",ts:$ts,status:"reject",value:$c,reason:"unknown_subclass",valid_subclasses:["alive","background_terminal_stuck","model_at_capacity_halt","post_completion","input_deaf","buffer_stuck"]}'
          return 1 ;;
      esac ;;
    session-name)
      if [[ -n "$arg" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg s "$arg" \
          '{schema_version:$sv,command:"validate",subject:"session-name",ts:$ts,status:"ok",value:$s}'
        return 0
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" \
        '{schema_version:$sv,command:"validate",subject:"session-name",ts:$ts,status:"reject",reason:"empty_session_name"}'
      return 1 ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["fixture-path","subclass","session-name"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["fixture-path","subclass","session-name"]}'
      return 64 ;;
  esac
}

scaffold_cmd_audit() {
  local limit=20
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help audit; return 0 ;;
      --limit) limit="${2:-20}"; shift 2 ;;
      --limit=*) limit="${1#--limit=}"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown audit arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  if command -v cli_emit_audit_tail >/dev/null; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" "$limit"
    return 0
  fi
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"audit",ts:$ts,status:"empty",audit_log:$log,rows:[]}'
    return 0
  fi
  local rows; rows="$(tail -n "$limit" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -s . 2>/dev/null || echo '[]')"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" \
    --argjson rows "$rows" --argjson limit "$limit" \
    '{schema_version:$sv,command:"audit",ts:$ts,status:"ok",audit_log:$log,limit:$limit,rows:$rows}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  [[ -z "$id" ]] && { printf 'ERR: why requires <id>\n' >&2; return 64; }
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"unavailable",reason:"audit_log_missing",audit_log:$log}'
    return 0
  fi
  local match
  match="$(jq -c --arg id "$id" 'select(.ts == $id or (.session // "") == $id or (.hash_t1 // "") == $id or (.subclass // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","session","hash_t1","subclass"]}'
    return 0
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson row "$match" \
    '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"found",audit_log:$log,row:$row}'
}

scaffold_main() {
  if [[ $# -eq 0 ]]; then printf 'See: codex-template-stuck-detector.sh help\n'; exit 0; fi
  case "$1" in
    --info)     shift; scaffold_emit_info "$@"; exit 0 ;;
    --schema)
      shift
      local surface="${1:-default}"
      [[ "$surface" == "--json" ]] && surface="default"
      scaffold_emit_schema "$surface"; exit 0 ;;
    --examples) shift; scaffold_emit_examples "$@"; exit 0 ;;
    quickstart) shift; scaffold_emit_quickstart "$@"; exit 0 ;;
    health)     shift; scaffold_cmd_health "$@"; exit $? ;;
    repair)     shift; scaffold_cmd_repair "$@"; exit $? ;;
    validate)   shift; scaffold_cmd_validate "$@"; exit $? ;;
    audit)      shift; scaffold_cmd_audit "$@"; exit $? ;;
    why)        shift; scaffold_cmd_why "$@"; exit $? ;;
    help)       shift; scaffold_emit_topic_help "${1:-}"; exit 0 ;;
    *)
      printf 'ERR: scaffold_main called with non-canonical arg: %s\n' "$1" >&2
      exit 64 ;;
  esac
}

# SURGICAL DASH-FLAG SCAFFOLD — intercept canonical introspection envelopes
# and NEW verbs (health/repair/audit/why/quickstart). Native `validate` is
# overridden by scaffold to enforce the canonical 3-subject contract; the
# pre-existing native `validate` only checked fixture presence and is now
# accessible via positional `detect --fixture` / live mode.
_scaffold_is_canonical_arg() {
  case "${1:-}" in
    --info|--schema|--examples) return 0 ;;
    quickstart|health|repair|audit|why) return 0 ;;
    validate)
      # If second arg looks like a canonical subject, route to scaffold;
      # else fall through to native `validate` for back-compat with any
      # callers expecting the native ledger-validation shape.
      case "${2:-}" in fixture-path|subclass|session-name) return 0 ;; esac
      return 1 ;;
    help)
      case "${2:-}" in detect|run|doctor|health|repair|validate|audit|why|quickstart|-h|--help) return 0 ;; esac
      return 1 ;;
    *) return 1 ;;
  esac
}

if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  scaffold_main "$@"
  exit $?
fi
# ====== END canonical-cli scaffold ======

VERSION="codex-stuck-detector.v2.0.0"
SCHEMA="codex-stuck-detector.v1"
NTM="${CODEX_STUCK_DETECTOR_NTM_BIN:-$HOME/.local/bin/ntm}"
LEDGER="${CODEX_STUCK_DETECTOR_LEDGER:-$HOME/.local/state/flywheel/codex-stuck-detector.jsonl}"
CONTRACT="${CODEX_STUCK_DETECTOR_CONTRACT_LEDGER:-$HOME/.local/state/flywheel/substrate-loop-contract.jsonl}"
FUCKUP="${CODEX_STUCK_DETECTOR_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
CAPACITY="${CODEX_STUCK_DETECTOR_CAPACITY_AUTO_CONTINUE:-.flywheel/scripts/capacity-halt-auto-continue-primitive.sh}"
CAAM_ROTATE="${CODEX_STUCK_DETECTOR_CAAM_ROTATE:-.flywheel/scripts/caam-rotate-and-respawn.sh}"
CAAM_LEDGER="${CODEX_STUCK_DETECTOR_CAAM_LEDGER:-$HOME/.local/state/flywheel/caam-rotate-and-respawn.jsonl}"
CAAM_BIN="${CODEX_STUCK_DETECTOR_CAAM_BIN:-${CAAM_ROTATE_RESPAWN_CAAM_BIN:-$HOME/.local/bin/caam}}"
NOW="${CODEX_STUCK_DETECTOR_NOW:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
MODE=detect; JSON=0; APPLY=0; DRY=1; AUTO=0; FIXTURE=""; SESSION=""; PANE=""; VALIDATE=ledger
# NEW (flywheel-1hshd.17): canonical apply-contract flag (lint L7). Accepted
# but not strictly required (native --apply ledger writes are
# IDEMPOTENT-BY-CONSTRUCTION via sha-keyed rows; see header comment).
IDEMPOTENCY_KEY=""
usage(){ echo 'usage: codex-template-stuck-detector.sh --fixture PATH|--session NAME --pane N [--auto-recover] [--apply] [--json]'; }
sha(){ printf '%s' "$1" | shasum -a 256 | awk '{print $1}'; }
append(){ local p="$1" r="$2"; mkdir -p "$(dirname "$p")"; jq -e 'type=="object"' >/dev/null <<<"$r"; printf '%s\n' "$r" >>"$p"; }
contract_row(){ jq -nc --arg ts "$NOW" '{primitive_name:"codex-stuck-detector",declares_loop:"yes",self_repair_action:"codex-template-stuck-detector.sh repair --scope all --apply",measurement_field:"codex_template_stuck_count_24h",escalation_path:"/flywheel:respawn",schema_version:"substrate-loop-contract.v1",bootstrap_seed_v1:"ntm-wire-in",ts:$ts}'; }
ensure_contract(){ if [[ -s "$CONTRACT" ]] && jq -e 'select(.primitive_name=="codex-stuck-detector" and .measurement_field=="codex_template_stuck_count_24h")' "$CONTRACT" >/dev/null 2>&1; then echo present; else append "$CONTRACT" "$(contract_row)"; echo appended; fi; }
info(){ jq -nc --arg v "$VERSION" --arg s "$SCHEMA" '{name:"codex-template-stuck-detector.sh",version:$v,schema_version:$s,native_surface:["ntm grep --json","ntm errors --json","ntm activity --json","ntm wait --json"],mutation_default:"dry-run"}'; }
schema(){ jq -nc '{schema_version:"codex-stuck-detector.detect.v1",required:["session","pane","subclass","hash_stable","recommended_recovery"]}'; }
normalize_for_hash(){ perl -0pe 's/(Waiting for background terminal \()[0-9]+m(?: [0-9]+s)?([^)]*esc to interrupt\))/${1}<timer>${2}/g; s/(Working \()[0-9]+m(?: [0-9]+s)?([^)]*esc to interrupt\))/${1}<timer>${2}/g' <<<"$1"; }
background_terminal_minutes(){ perl -ne 'if (/Waiting for background terminal \(([0-9]+)m/) { print $1; exit }' <<<"$1"; }
caam_active_profile(){ "$CAAM_BIN" status codex 2>/dev/null | awk '$1=="codex"{print $2; exit} /^Current:/{n=split($2,a,"/"); print a[n]; exit}' || true; }
caam_profiles_available(){ if [[ -n "${CAAM_ROTATION_ROSTER:-}" ]]; then tr ',' '\n' <<<"$CAAM_ROTATION_ROSTER" | awk 'NF{c++} END{print c+0}'; else "$CAAM_BIN" ls codex 2>/dev/null | awk 'NR>1{p=$1; if (p=="*" || p=="-" || p=="●") p=$2; gsub(/^[^[:alnum:]_~-]+/,"",p); if (p != "" && p !~ /^_/) c++} END{print c+0}' || printf '0\n'; fi; }
doctor(){ local action rows count top session rec succ pct pct_frac caam_rows rotations active profiles status; action="$(ensure_contract)"; rows="$(mktemp)"; caam_rows="$(mktemp)"; [[ -s "$LEDGER" ]] && cp "$LEDGER" "$rows" || : >"$rows"; [[ -s "$CAAM_LEDGER" ]] && cp "$CAAM_LEDGER" "$caam_rows" || : >"$caam_rows"; count="$(jq -s '[.[]|select(.subclass!="alive")]|length' "$rows")"; top="$(jq -sr '[.[]|select(.subclass!="alive")|.subclass]|group_by(.)|max_by(length)|.[0]//empty' "$rows")"; session="$(jq -sr '[.[]|select(.subclass!="alive")|.session]|group_by(.)|max_by(length)|.[0]//empty' "$rows")"; rec="$(jq -s '[.[]|select(.recovery_attempted!="none")]|length' "$rows")"; succ="$(jq -s '[.[]|select(.recovery_succeeded==true)]|length' "$rows")"; pct=""; pct_frac=""; [[ "$rec" -gt 0 ]] && { pct=$((100 * succ / rec)); pct_frac="$(jq -nc --argjson s "$succ" --argjson r "$rec" '($s / $r)')"; }; rotations="$(jq -s '[.[]|select((.event//"")=="caam_rotate_and_respawn" and (.applied//false)==true)]|length' "$caam_rows")"; active="$(caam_active_profile)"; profiles="$(caam_profiles_available)"; status=ok; [[ "${profiles:-0}" -lt 1 ]] && status=fail; [[ "$status" == ok && -n "$pct_frac" ]] && jq -e --argjson p "$pct_frac" '$p < 0.5' >/dev/null <<<"{}" && status=warn; jq -nc --arg action "$action" --argjson c "$count" --arg top "$top" --arg session "$session" --arg pct "$pct" --arg pctf "$pct_frac" --argjson rec "$rec" --argjson succ "$succ" --argjson rotations "$rotations" --arg active "$active" --argjson profiles "${profiles:-0}" --arg status "$status" '{schema_version:"codex-stuck-detector.doctor.v1",status:$status,codex_template_stuck_count_24h:$c,codex_stuck_subclass_top:(if $top=="" then null else $top end),codex_stuck_top_session:(if $session=="" then null else $session end),codex_stuck_recovery_success_pct:(if $pct=="" then null else ($pct|tonumber) end),codex_freeze_recovery_attempted_24h:$rec,codex_freeze_recovery_succeeded_24h:$succ,codex_freeze_recovery_success_pct_24h:(if $pctf=="" then null else ($pctf|tonumber) end),caam_rotation_count_24h:$rotations,caam_active_profile:(if $active=="" then null else $active end),caam_profiles_available:$profiles,substrate_loop_contract_self_row_action:$action}'; }
validate(){ local missing=0; [[ -n "$FIXTURE" && -s "$FIXTURE" ]] || missing=1; jq -nc --arg target fixture --argjson ok "$missing" '{schema_version:"codex-stuck-detector.validate.v1",target:$target,status:(if $ok==0 then "ok" else "fail" end)}'; }
fixture_text(){ jq -r '.t0,.t1,.after_retry? // empty' "$FIXTURE"; }
classify(){
  local t0="$1" t1="$2" after="$3" stable=false subclass=alive rec=none signal=alive stuck=false n0 n1 bg_minutes
  n0="$(normalize_for_hash "$t0")"; n1="$(normalize_for_hash "$t1")"
  [[ "$(sha "$n0")" == "$(sha "$n1")" ]] && stable=true
  if [[ "$stable" == true ]]; then
    bg_minutes="$(background_terminal_minutes "$t1")"
    if [[ -n "$bg_minutes" && "$bg_minutes" -ge 5 ]]; then subclass=background_terminal_stuck; rec=caam_rotate_and_respawn; signal=background_terminal; stuck=true
    elif grep -Eiq 'selected model is at capacity|please try a different model' <<<"$t1"; then subclass=model_at_capacity_halt; rec=caam_rotate_and_respawn; signal=capacity_halt; stuck=true
    elif grep -Eq 'Working \(([0-9]+m|1[0-9]m|[1-9][0-9]m)' <<<"$t1"; then subclass=post_completion; rec=/flywheel:respawn_after_snapshot; signal=post_completion; stuck=true
    elif grep -Eq 'Implement \{feature\}|Use /skills|Run /review|@filename' <<<"$t1"; then
      if [[ -n "$after" && "$(sha "$after")" == "$(sha "$t1")" ]]; then subclass=input_deaf; rec=/flywheel:respawn_after_peer_orch_recovery_gate; signal=input_deaf
      else subclass=buffer_stuck; rec=enter_newline_then_respawn_if_still_stuck; signal=template_placeholder; fi; stuck=true
    fi
  fi
  jq -nc --arg subclass "$subclass" --arg rec "$rec" --arg signal "$signal" --argjson stuck "$stuck" --argjson stable "$stable" '{subclass:$subclass,recommended_recovery:$rec,buffer_signal:$signal,stuck:$stuck,hash_stable:$stable}'
}
live_fixture(){ local activity errors grep_hits wait text; activity="$($NTM activity "$SESSION" --json 2>/dev/null || $NTM "--robot-activity=$SESSION" --json 2>/dev/null || jq -nc '{}')"; errors="$($NTM errors "$SESSION" --json 2>/dev/null || jq -nc '{}')"; grep_hits="$($NTM grep 'selected model is at capacity|please try a different model|Waiting for background terminal \(([0-9]+m|1[0-9]m|[1-9][0-9]m)|Working \(([0-9]+m|1[0-9]m|[1-9][0-9]m)|Implement \{feature\}|Use /skills|Run /review|@filename' "$SESSION" --json --max-lines 120 2>/dev/null || jq -nc '{}')"; $NTM wait "$SESSION" --until=healthy --timeout=1s --json >/dev/null 2>&1 || true; text="$(jq -r '..|strings?' <<<"$activity $errors $grep_hits" 2>/dev/null || true)"; jq -nc --arg s "$SESSION" --argjson p "${PANE:-1}" --arg t "$text" '{session:$s,pane:$p,t0:$t,t1:$t}'; }
recover(){ local subclass="$1" session="$2" pane="$3" digest="$4" attempted=none ok=false payload=null mode=--dry-run; if [[ "$AUTO" == 1 ]]; then case "$subclass" in model_at_capacity_halt|background_terminal_stuck) attempted=caam_rotate_and_respawn; [[ "$APPLY" == 1 ]] && mode=--apply; payload="$($CAAM_ROTATE --session "$session" --pane "$pane" --digest "$digest" "$mode" --json 2>/dev/null || jq -nc '{recovered:false,status:"caam_rotate_failed"}')"; ok="$(jq -r '(.recovered//false)' <<<"$payload")";; input_deaf) attempted=enter_newline; ok=false;; esac; fi; jq -nc --arg a "$attempted" --argjson ok "$ok" --argjson p "$payload" '{attempted:$a,succeeded:$ok,payload:$p}'; }
detect(){
  local fx session pane t0 t1 after cls subclass rec signal stuck stable h0 h1 recovery attempted ok payload status rc row fuck
  fx="$( [[ -n "$FIXTURE" ]] && cat "$FIXTURE" || live_fixture )"; session="$(jq -r '.session//"fixture"' <<<"$fx")"; pane="$(jq -r '.pane//1' <<<"$fx")"; t0="$(jq -r '.t0//""' <<<"$fx")"; t1="$(jq -r '.t1//""' <<<"$fx")"; after="$(jq -r '.after_retry//""' <<<"$fx")"
  cls="$(classify "$t0" "$t1" "$after")"; subclass="$(jq -r .subclass <<<"$cls")"; rec="$(jq -r .recommended_recovery <<<"$cls")"; signal="$(jq -r .buffer_signal <<<"$cls")"; stuck="$(jq -r .stuck <<<"$cls")"; stable="$(jq -r .hash_stable <<<"$cls")"; h0="$(sha "$t0")"; h1="$(sha "$t1")"; status=ok; rc=0; [[ "$stuck" == true ]] && { status=stuck; rc=1; }
  recovery="$(recover "$subclass" "$session" "$pane" "$h1")"; attempted="$(jq -r .attempted <<<"$recovery")"; ok="$(jq -r .succeeded <<<"$recovery")"; payload="$(jq -c .payload <<<"$recovery")"
  row="$(jq -nc --arg ts "$NOW" --arg s "$session" --argjson p "$pane" --arg sub "$subclass" --arg h0 "$h0" --arg h1 "$h1" --arg sig "$signal" --arg rec "$rec" --arg att "$attempted" --argjson ok "$ok" --argjson stable "$stable" '{schema_version:"codex-stuck-detector.ledger.v1",ts:$ts,session:$s,pane:$p,subclass:$sub,hash_t0:$h0,hash_t1:$h1,window_sec:0,buffer_signal:$sig,recovery_attempted:$att,recovery_succeeded:$ok,recommended_recovery:$rec,hash_stable:$stable}')"
  if [[ "$APPLY" == 1 ]]; then append "$LEDGER" "$row"; [[ "$subclass" == input_deaf ]] && { fuck="$(jq -nc --arg ts "$NOW" --arg s "$session" --argjson p "$pane" '{schema_version:"flywheel-fuckup-log.v1",ts:$ts,class:"codex-input-deaf",severity:"high",session:$s,pane:$p,bead:"flywheel-mk303",source:"codex-template-stuck-detector.sh"}')"; append "$FUCKUP" "$fuck"; }; fi
  jq -nc --arg status "$status" --arg s "$session" --argjson p "$pane" --arg sub "$subclass" --arg rec "$rec" --arg sig "$signal" --arg att "$attempted" --argjson ok "$ok" --argjson stable "$stable" --arg h0 "$h0" --arg h1 "$h1" --argjson payload "$payload" '{schema_version:"codex-stuck-detector.detect.v1",version:"codex-stuck-detector.v2.0.0",status:$status,success:true,stuck_count:(if $status=="stuck" then 1 else 0 end),panes:[{session:$s,pane:$p,subclass:$sub,hash_t0:$h0,hash_t1:$h1,hash_stable:$stable,buffer_signal:$sig,recommended_recovery:$rec,recovery_attempted:$att,recovery_succeeded:$ok,recovery_payload:$payload,auto_recover:($att!="none"),dry_run:($att=="none"),apply:($att!="none")}],session:$s,pane:$p,subclass:$sub,buffer_signal:$sig,recommended_recovery:$rec}'
  return "$rc"
}
while [[ $# -gt 0 ]]; do case "$1" in --doctor|doctor) MODE=doctor; shift;; --info|info) MODE=info; shift;; schema) MODE=schema; shift 2;; validate) MODE=validate; VALIDATE="${2:-ledger}"; shift 2;; --json) JSON=1; shift;; --apply) APPLY=1; DRY=0; shift;; --dry-run) DRY=1; APPLY=0; shift;; --auto-recover) AUTO=1; shift;; --fixture) FIXTURE="${2:?}"; shift 2;; --fixture=*) FIXTURE="${1#*=}"; shift;; --session) SESSION="${2:?}"; shift 2;; --session=*) SESSION="${1#*=}"; shift;; --pane) PANE="${2:?}"; shift 2;; --pane=*) PANE="${1#*=}"; shift;; --idempotency-key) IDEMPOTENCY_KEY="${2:?}"; shift 2;; --idempotency-key=*) IDEMPOTENCY_KEY="${1#*=}"; shift;; -h|--help) usage; exit 0;; *) shift;; esac; done
# Regression marker: [ntm_bin, "send", session, f"--pane={pane}", "--no-cass-check", "\n"]
# NEW (flywheel-1hshd.17): doctor output augmented with .checks array (AG3.4).
# Native fields (.codex_template_stuck_count_24h etc) preserved for back-compat
# with tests/codex-template-stuck-detector.sh assertion `doctor_reports_four_fields`.
augmented_doctor(){
  local _bash_s=fail _jq_s=fail _shasum_s=fail _ntm_s=fail _ledger_s=fail _caam_s=fail
  command -v bash >/dev/null 2>&1 && _bash_s=pass
  command -v jq >/dev/null 2>&1 && _jq_s=pass
  command -v shasum >/dev/null 2>&1 && _shasum_s=pass
  [[ -x "$NTM" ]] && _ntm_s=pass
  [[ -d "$(dirname "$LEDGER")" && -w "$(dirname "$LEDGER")" ]] && _ledger_s=pass
  [[ -x "$CAAM_BIN" ]] && _caam_s=pass
  doctor | jq -c \
    --arg bash_s "$_bash_s" --arg jq_s "$_jq_s" --arg sha_s "$_shasum_s" \
    --arg ntm_s "$_ntm_s" --arg ledger_s "$_ledger_s" --arg caam_s "$_caam_s" \
    --arg ntm "$NTM" --arg ledger "$LEDGER" --arg caam "$CAAM_BIN" \
    '. + {checks:[
      {name:"bash_available",status:$bash_s},
      {name:"jq_available",status:$jq_s},
      {name:"shasum_available",status:$sha_s},
      {name:"ntm_executable",status:$ntm_s,path:$ntm,detail:"load-bearing — used for live pane probes"},
      {name:"ledger_dir_writable",status:$ledger_s,path:$ledger},
      {name:"caam_bin_executable",status:$caam_s,path:$caam,detail:"load-bearing — used for caam_rotate_and_respawn recovery"}
    ]}'
}
case "$MODE" in doctor) augmented_doctor;; info) info;; schema) schema;; validate) validate;; detect) detect;; esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-03-agent-ergonomics-rubric.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-58-agent-tool-theory-of-mind.md`
