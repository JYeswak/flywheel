#!/usr/bin/env bash
set -u

VERSION="callback-spool-reap.v1"
NTM="${NTM:-/Users/josh/.local/bin/ntm}"
SPOOL_DIR="${FLYWHEEL_CALLBACK_SPOOL_DIR:-$HOME/.local/state/flywheel/callback-spool}"
ARCHIVE_DIR="${FLYWHEEL_CALLBACK_ARCHIVE_DIR:-$SPOOL_DIR/archive}"
DISPATCH_LOG="${FLYWHEEL_DISPATCH_LOG:-/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl}"
MAX_ATTEMPTS="${FLYWHEEL_CALLBACK_REAP_MAX_ATTEMPTS:-5}"
SESSION_FILTER=""
JSON=0
MODE="apply"

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

  jq --argjson attempts "$new_attempts" \
     --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     --arg send_stderr "$err_text" \
     '. + {attempts:$attempts,last_attempt_ts:$ts,last_send_stderr:$send_stderr}' "$f" >"$f.tmp" 2>/dev/null \
    && mv -f "$f.tmp" "$f"
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
    --info) printf '{"name":"callback-spool-reap.sh","version":"%s","spool_dir":"%s","archive_dir":"%s","dispatch_log":"%s","max_attempts":%s}\n' "$VERSION" "$SPOOL_DIR" "$ARCHIVE_DIR" "$DISPATCH_LOG" "$MAX_ATTEMPTS"; exit 0;;
    --examples) printf '{"examples":["callback-spool-reap.sh --dry-run --json","callback-spool-reap.sh --apply --json","callback-spool-reap.sh doctor --json","callback-spool-reap.sh audit --session flywheel --json"]}\n'; exit 0;;
    --help|-h) usage; exit 0;;
    --version) printf '%s\n' "$VERSION"; exit 0;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2;;
  esac
done

case "$CMD" in
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
