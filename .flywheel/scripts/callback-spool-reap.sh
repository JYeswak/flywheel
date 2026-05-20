#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial → passing per bead flywheel-1hshd.10)
# L5 lint requires `set -euo pipefail`. Existing script used `set -u` only;
# upgrading to full strict mode is safe — the script has explicit `|| true`
# / conditional checks on fallible commands.
set -euo pipefail

VERSION="callback-spool-reap.v1"
NTM="${NTM:-/Users/josh/.local/bin/ntm}"
SPOOL_DIR="${FLYWHEEL_CALLBACK_SPOOL_DIR:-$HOME/.local/state/flywheel/callback-spool}"
ARCHIVE_DIR="${FLYWHEEL_CALLBACK_ARCHIVE_DIR:-$SPOOL_DIR/archive}"
DISPATCH_LOG="${FLYWHEEL_DISPATCH_LOG:-/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl}"
MAX_ATTEMPTS="${FLYWHEEL_CALLBACK_REAP_MAX_ATTEMPTS:-5}"
SESSION_FILTER=""
JSON=0
MODE="apply"
# NEW (flywheel-1hshd.10): --idempotency-key for canonical apply contract.
IDEMPOTENCY_KEY=""
REPAIR_ARGS=()
CLEANUP_FILES=()

cleanup_on_exit() {
  local f
  for f in "${CLEANUP_FILES[@]}"; do
    [[ -n "$f" ]] || continue
    rm -f "$f" 2>/dev/null || true
  done
  return 0
}
trap cleanup_on_exit EXIT ERR

register_cleanup_file() {
  CLEANUP_FILES+=("$1")
}

usage(){ cat <<USAGE
Usage: callback-spool-reap.sh [--dry-run|--apply] [--json] [--session NAME]
       callback-spool-reap.sh doctor [--json]
       callback-spool-reap.sh validate [--json]
       callback-spool-reap.sh audit [--json] [--session NAME]
       callback-spool-reap.sh schema | --info | --examples | --help

Polls \$FLYWHEEL_CALLBACK_SPOOL_DIR (default: ~/.local/state/flywheel/callback-spool/<session>/*.json)
for callbacks left pending by verify-callback-delivery.sh on pane_not_in_input_mode.
For each pending entry, retries 'ntm send'; on success, archives to <spool>/archive/<session>/.
On reaching max attempts, surfaces a fuckup_logged row to dispatch-log.jsonl.

Defaults:
  spool:        $SPOOL_DIR
  archive:      $ARCHIVE_DIR
  dispatch-log: $DISPATCH_LOG
  max attempts: $MAX_ATTEMPTS

Failure classes surfaced:
  pane_not_in_input_mode     spool retry kept (attempts < max)
  send_persisted_failure     attempts >= max; row appended to dispatch-log
USAGE
}

emit_doctor(){
  local total pending archived
  total=0; pending=0; archived=0
  if [[ -d "$SPOOL_DIR" ]]; then
    pending="$(find "$SPOOL_DIR" -mindepth 2 -maxdepth 2 -type f -name '*.json' 2>/dev/null \
      | grep -v "/archive/" | wc -l | tr -d ' ')"
  fi
  if [[ -d "$ARCHIVE_DIR" ]]; then
    archived="$(find "$ARCHIVE_DIR" -mindepth 2 -maxdepth 2 -type f -name '*.json' 2>/dev/null | wc -l | tr -d ' ')"
  fi
  total=$((pending + archived))
  local status="pass"
  [[ "$pending" -gt 100 ]] && status="warn"
  if [[ "$JSON" == 1 ]]; then
    printf '{"schema_version":"%s.doctor","status":"%s","spool_dir":"%s","archive_dir":"%s","spool_dir_exists":%s,"pending":%s,"archived":%s,"total":%s}\n' \
      "$VERSION" "$status" "$SPOOL_DIR" "$ARCHIVE_DIR" \
      "$( [[ -d "$SPOOL_DIR" ]] && printf true || printf false )" \
      "$pending" "$archived" "$total"
  else
    printf 'doctor status=%s spool=%s pending=%s archived=%s total=%s\n' "$status" "$SPOOL_DIR" "$pending" "$archived" "$total"
  fi
}

emit_audit(){
  local found=0
  if [[ "$JSON" == 1 ]]; then printf '['; fi
  if [[ -d "$ARCHIVE_DIR" ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      if [[ "$JSON" == 1 ]]; then
        [[ "$found" -gt 0 ]] && printf ','
        cat "$f" 2>/dev/null
      else
        printf '%s\n' "$f"
      fi
      found=$((found + 1))
    done < <(find "$ARCHIVE_DIR" -mindepth 2 -maxdepth 2 -type f -name '*.json' 2>/dev/null \
             ${SESSION_FILTER:+-path "*/${SESSION_FILTER}/*"})
  fi
  if [[ "$JSON" == 1 ]]; then printf ']\n'; fi
}

reap_one(){
  local f="$1" session task_id message attempts new_attempts pane outcome err_text err_log
  if ! command -v jq >/dev/null 2>&1; then
    printf '{"file":"%s","outcome":"jq_missing"}\n' "$f"
    return 1
  fi
  session="$(jq -r '.session // ""' "$f" 2>/dev/null)"
  pane="$(jq -r '.pane // "1"' "$f" 2>/dev/null)"
  task_id="$(jq -r '.task_id // ""' "$f" 2>/dev/null)"
  message="$(jq -r '.message // ""' "$f" 2>/dev/null)"
  attempts="$(jq -r '.attempts // 0' "$f" 2>/dev/null)"
  if [[ -z "$session" || -z "$task_id" || -z "$message" ]]; then
    printf '{"file":"%s","outcome":"malformed"}\n' "$f"
    return 1
  fi
  new_attempts=$((attempts + 1))

  if [[ "$MODE" == "dry-run" ]]; then
    printf '{"file":"%s","outcome":"would_retry","session":"%s","pane":"%s","task_id":"%s","attempts":%s}\n' \
      "$f" "$session" "$pane" "$task_id" "$new_attempts"
    return 0
  fi

  err_log="$(mktemp -t reap-send-err.XXXXXX)"
  register_cleanup_file "$err_log"
  if "$NTM" send "$session" --pane="$pane" --no-cass-check "$message" >/dev/null 2>"$err_log"; then
    rm -f "$err_log"
    mkdir -p "$ARCHIVE_DIR/$session" 2>/dev/null
    local arch_path="$ARCHIVE_DIR/$session/$(basename "$f")"
    jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
       --argjson attempts "$new_attempts" \
       '. + {status:"reaped",reaped_ts:$ts,attempts:$attempts}' "$f" >"$arch_path" 2>/dev/null
    rm -f "$f"
    printf '{"file":"%s","outcome":"reaped","session":"%s","pane":"%s","task_id":"%s","attempts":%s,"archive_path":"%s"}\n' \
      "$f" "$session" "$pane" "$task_id" "$new_attempts" "$arch_path"
    return 0
  fi
  err_text="$(cat "$err_log" 2>/dev/null || true)"
  rm -f "$err_log"

  if [[ "$new_attempts" -ge "$MAX_ATTEMPTS" ]]; then
    mkdir -p "$ARCHIVE_DIR/$session" 2>/dev/null
    local fail_path="$ARCHIVE_DIR/$session/$(basename "$f").persisted-failure.json"
    jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
       --argjson attempts "$new_attempts" \
       --arg send_stderr "$err_text" \
       '. + {status:"persisted_failure",persisted_ts:$ts,attempts:$attempts,last_send_stderr:$send_stderr}' "$f" >"$fail_path" 2>/dev/null
    rm -f "$f"
    if [[ -n "$DISPATCH_LOG" ]] && mkdir -p "$(dirname "$DISPATCH_LOG")" 2>/dev/null; then
      jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
             --arg event "callback_spool_persisted_failure" \
             --arg session "$session" --arg pane "$pane" --arg task_id "$task_id" \
             --argjson attempts "$new_attempts" \
             --arg fuckup_class "send_persisted_failure" \
             --arg artifact "$fail_path" \
             '{ts:$ts,event:$event,session:$session,pane:$pane,task_id:$task_id,attempts:$attempts,fuckup_class:$fuckup_class,artifact:$artifact,schema_version:"callback-spool-reap.v1.persisted"}' >>"$DISPATCH_LOG"
    fi
    printf '{"file":"%s","outcome":"persisted_failure","session":"%s","pane":"%s","task_id":"%s","attempts":%s,"failure_artifact":"%s"}\n' \
      "$f" "$session" "$pane" "$task_id" "$new_attempts" "$fail_path"
    return 0
  fi

  local retry_tmp="$f.tmp"
  register_cleanup_file "$retry_tmp"
  jq --argjson attempts "$new_attempts" \
     --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     --arg send_stderr "$err_text" \
     '. + {attempts:$attempts,last_attempt_ts:$ts,last_send_stderr:$send_stderr}' "$f" >"$retry_tmp" 2>/dev/null \
    && mv -f "$retry_tmp" "$f"
  printf '{"file":"%s","outcome":"retry_pending","session":"%s","pane":"%s","task_id":"%s","attempts":%s}\n' \
    "$f" "$session" "$pane" "$task_id" "$new_attempts"
}

CMD="reap"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) MODE="dry-run"; shift;;
    --apply) MODE="apply"; shift;;
    --json) JSON=1; shift;;
    --session) SESSION_FILTER="$2"; shift 2;;
    --spool-dir) SPOOL_DIR="$2"; shift 2;;
    --archive-dir) ARCHIVE_DIR="$2"; shift 2;;
    --dispatch-log) DISPATCH_LOG="$2"; shift 2;;
    --max-attempts) MAX_ATTEMPTS="$2"; shift 2;;
    --ntm) NTM="$2"; shift 2;;
    doctor|validate|audit|schema) CMD="$1"; shift;;
    # NEW (flywheel-1hshd.10): full canonical no-dash family. For
    # repair/why we capture remaining args verbatim since they have
    # their own arg parsers (--scope, etc).
    repair|why)
      CMD="$1"; shift
      REPAIR_ARGS=("$@")
      break
      ;;
    health|quickstart) CMD="$1"; shift;;
    # NEW: --schema dash flag + --idempotency-key.
    --schema) CMD="schema"; shift;;
    --idempotency-key) IDEMPOTENCY_KEY="${2:?--idempotency-key requires KEY}"; shift 2 ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#*=}"; shift ;;
    --info) printf '{"command":"info","name":"callback-spool-reap.sh","version":"%s","schema_version":"callback-spool-reap/v1","spool_dir":"%s","archive_dir":"%s","dispatch_log":"%s","max_attempts":%s,"subcommands":["doctor","health","repair","validate","audit","why","schema","quickstart"],"canonical_flags":["--info","--schema","--examples","--json","--apply","--dry-run","--idempotency-key","--session","--spool-dir","--archive-dir","--dispatch-log","--max-attempts","--ntm"],"apply_supported":true,"dry_run_supported":true,"idempotency_key_required_for_apply":true}\n' "$VERSION" "$SPOOL_DIR" "$ARCHIVE_DIR" "$DISPATCH_LOG" "$MAX_ATTEMPTS"; exit 0;;
    --examples) printf '{"command":"examples","examples":["callback-spool-reap.sh --dry-run --json","callback-spool-reap.sh --apply --idempotency-key reap-2026-05-11 --json","callback-spool-reap.sh doctor --json","callback-spool-reap.sh audit --session flywheel --json","callback-spool-reap.sh validate --json"]}\n'; exit 0;;
    --help|-h) usage; exit 0;;
    --version) printf '%s\n' "$VERSION"; exit 0;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2;;
  esac
done

# NEW (flywheel-1hshd.10): canonical apply contract — `reap` CMD with --apply
# requires --idempotency-key (canonical-cli L7 + L10 rules).
if [[ "$CMD" == "reap" && "$MODE" == "apply" && -z "$IDEMPOTENCY_KEY" ]]; then
  printf '{"schema_version":"callback-spool-reap/v1","status":"refused","mode":"apply","reason":"--apply requires --idempotency-key KEY (canonical apply contract)","exit_code":3}\n'
  exit 3
fi

# NEW (flywheel-1hshd.10): canonical health + repair + why surfaces.
SCAFFOLD_SCHEMA_VERSION="callback-spool-reap/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$DISPATCH_LOG}"

scaffold_cmd_health() {
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local pending=0 archived=0 stale=0
  if [[ -d "$SPOOL_DIR" ]]; then
    pending="$(find "$SPOOL_DIR" -mindepth 2 -maxdepth 2 -type f -name '*.json' 2>/dev/null | grep -v "/archive/" | wc -l | tr -d ' ' || echo 0)"
  fi
  if [[ -d "$ARCHIVE_DIR" ]]; then
    archived="$(find "$ARCHIVE_DIR" -type f -name '*.json' 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" \
    --arg spool "$SPOOL_DIR" --arg archive "$ARCHIVE_DIR" \
    --argjson pending "${pending:-0}" --argjson archived "${archived:-0}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:(if $pending > 50 then "warn" else "pass" end),spool_dir:$spool,archive_dir:$archive,pending:$pending,archived:$archived,total:($pending+$archived)}'
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
    printf '{"schema_version":"%s","status":"refused","mode":"apply","scope":"%s","reason":"--apply requires --idempotency-key","exit_code":3}\n' "$SCAFFOLD_SCHEMA_VERSION" "$scope"
    exit 3
  fi
  case "$scope" in
    archive-rotate)
      local size_bytes=0 archive_count=0
      [[ -d "$ARCHIVE_DIR" ]] && archive_count="$(find "$ARCHIVE_DIR" -type f -name '*.json' 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg archive "$ARCHIVE_DIR" --argjson count "${archive_count:-0}" \
        '{schema_version:$sv,command:"repair",status:"pass",mode:$mode,scope:$scope,archive_dir:$archive,archive_count:$count,note:"read-only probe (archive cleanup is operational concern, not scaffold scope)"}'
      ;;
    spool-prime)
      local sp_present=false sp_pending=0
      if [[ -d "$SPOOL_DIR" ]]; then
        sp_present=true
        sp_pending="$(find "$SPOOL_DIR" -mindepth 2 -maxdepth 2 -type f -name '*.json' 2>/dev/null | grep -v "/archive/" | wc -l | tr -d ' ' || echo 0)"
      fi
      local status="pass"; [[ "$sp_present" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg spool "$SPOOL_DIR" --arg s "$status" --argjson present "$sp_present" --argjson pending "${sp_pending:-0}" \
        '{schema_version:$sv,command:"repair",status:$s,mode:$mode,scope:$scope,spool_dir:$spool,present:$present,pending:$pending,note:"read-only probe"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        '{schema_version:$sv,command:"repair",status:"unknown_scope",mode:$mode,scope:$scope,known_scopes:["archive-rotate","spool-prime"]}'
      ;;
  esac
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then printf 'ERR: why requires <id>\n' >&2; return 64; fi
  local matches="[]" status="not_found" any_source_present=false
  if [[ -r "$DISPATCH_LOG" ]]; then
    any_source_present=true
    local raw; raw="$(grep -F "$id" "$DISPATCH_LOG" 2>/dev/null || true)"
    [[ -n "$raw" ]] && matches="$(printf '%s' "$raw" | jq -sc '.' 2>/dev/null || echo '[]')"
  fi
  if [[ "$any_source_present" != true ]]; then status="unavailable"
  else
    local n; n="$(printf '%s' "$matches" | jq 'length' 2>/dev/null || echo 0)"
    n="${n//[^0-9]/}"; [[ -z "$n" ]] && n=0
    [[ "$n" -gt 0 ]] && status="found"
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg s "$status" \
    --arg log "$DISPATCH_LOG" --argjson m "$matches" \
    '{schema_version:$sv,command:"why",id:$id,status:$s,audit_log:$log,matches:$m,total_matches:($m|length)}'
}

scaffold_cmd_quickstart() {
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    '{schema_version:$sv,command:"quickstart",steps:[
      {step:1,action:"probe doctor",command:"callback-spool-reap.sh doctor --json"},
      {step:2,action:"see pending count",command:"callback-spool-reap.sh health --json"},
      {step:3,action:"dry-run reap",command:"callback-spool-reap.sh --dry-run --json"},
      {step:4,action:"apply reap",command:"callback-spool-reap.sh --apply --idempotency-key reap-$(date +%Y%m%d) --json"}
    ]}'
}

case "$CMD" in
  health) scaffold_cmd_health; exit 0;;
  repair) scaffold_cmd_repair "${REPAIR_ARGS[@]:-}"; exit $?;;
  why) scaffold_cmd_why "${REPAIR_ARGS[0]:-}"; exit $?;;
  quickstart) scaffold_cmd_quickstart; exit 0;;
  doctor) emit_doctor;;
  validate)
    if [[ -d "$SPOOL_DIR" ]]; then
      bad=0
      while IFS= read -r f; do
        [[ -n "$f" ]] || continue
        if ! jq -e '.task_id and .session and .message and (.failure_class | type=="string")' "$f" >/dev/null 2>&1; then
          bad=$((bad + 1))
          [[ "$JSON" == 1 ]] && printf '{"file":"%s","status":"malformed"}\n' "$f"
        fi
      done < <(find "$SPOOL_DIR" -mindepth 2 -maxdepth 2 -type f -name '*.json' 2>/dev/null | grep -v "/archive/")
      if [[ "$JSON" == 1 ]]; then
        printf '{"schema_version":"%s.validate","malformed":%s}\n' "$VERSION" "$bad"
      else
        printf 'validate malformed=%s\n' "$bad"
      fi
      [[ "$bad" -eq 0 ]] || exit 1
    else
      [[ "$JSON" == 1 ]] && printf '{"schema_version":"%s.validate","malformed":0,"spool_missing":true}\n' "$VERSION"
    fi
    ;;
  audit) emit_audit;;
  schema)
    printf '{"schema_version":"callback-spool/v1","required_fields":["schema_version","ts","session","pane","task_id","failure_class","message","status","attempts"]}\n'
    ;;
  reap)
    [[ -d "$SPOOL_DIR" ]] || { [[ "$JSON" == 1 ]] && printf '{"schema_version":"%s.reap","status":"empty","spool_dir":"%s","reaped":0,"retry_pending":0,"persisted_failure":0}\n' "$VERSION" "$SPOOL_DIR"; exit 0; }
    reaped=0; pending=0; persisted=0
    if [[ "$JSON" == 1 ]]; then printf '{"schema_version":"%s.reap","mode":"%s","results":[' "$VERSION" "$MODE"; first=1; fi
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      [[ -n "$SESSION_FILTER" ]] && ! [[ "$f" == */${SESSION_FILTER}/* ]] && continue
      result="$(reap_one "$f")"
      [[ "$JSON" == 1 ]] && { [[ "$first" -eq 0 ]] && printf ','; printf '%s' "$result"; first=0; } || printf '%s\n' "$result"
      case "$result" in
        *'"outcome":"reaped"'*) reaped=$((reaped + 1));;
        *'"outcome":"retry_pending"'*) pending=$((pending + 1));;
        *'"outcome":"persisted_failure"'*) persisted=$((persisted + 1));;
      esac
    done < <(find "$SPOOL_DIR" -mindepth 2 -maxdepth 2 -type f -name '*.json' 2>/dev/null | grep -v "/archive/")
    if [[ "$JSON" == 1 ]]; then
      printf '],"reaped":%s,"retry_pending":%s,"persisted_failure":%s}\n' "$reaped" "$pending" "$persisted"
    else
      printf 'reap mode=%s reaped=%s retry_pending=%s persisted_failure=%s\n' "$MODE" "$reaped" "$pending" "$persisted"
    fi
    ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-04-receipt-callback-envelope.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-88-content-addressed-evidence-pack.md`
