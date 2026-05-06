#!/usr/bin/env bash
set -u

VERSION="orch-no-punt-output-gate.v1.0.0"
SCHEMA_VERSION="orch-no-punt-decision/v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO_ROOT="${ORCH_NO_PUNT_REPO:-$REPO_ROOT_DEFAULT}"
LEDGER="${ORCH_NO_PUNT_LEDGER:-$HOME/.local/state/flywheel/orch-no-punt-output-gate-ledger.jsonl}"
NTM_BIN="${ORCH_NO_PUNT_NTM_BIN:-$HOME/.local/bin/ntm}"
READY_FILE="${ORCH_NO_PUNT_READY_FILE:-$REPO_ROOT/.beads/issues.jsonl}"
ACTIVITY_FILE="${ORCH_NO_PUNT_ACTIVITY_FILE:-}"
SESSION="flywheel"
MODE=""
TEXT_FILE=""
TEXT_STDIN=0
JSON_OUT=0

usage() {
  cat <<'EOF'
usage:
  orch-no-punt-output-gate.sh check --text-file PATH [--session NAME] [--json]
  orch-no-punt-output-gate.sh check --text-stdin [--session NAME] [--json]
  orch-no-punt-output-gate.sh --info|--help|--examples
EOF
}

info() {
  jq -nc \
    --arg name "orch-no-punt-output-gate.sh" \
    --arg version "$VERSION" \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg ledger "$LEDGER" \
    --arg repo "$REPO_ROOT" \
    '{name:$name,version:$version,schema_version:$schema_version,ledger:$ledger,repo:$repo,purpose:"refuse orchestrator punt prose when worker capacity and ready beads exist",fail_open:true}'
}

examples() {
  cat <<'EOF'
printf 'options: A or B\n' | orch-no-punt-output-gate.sh check --text-stdin --session flywheel --json
orch-no-punt-output-gate.sh check --text-file /tmp/assistant-final.txt --session skillos --json
ORCH_NO_PUNT_ACTIVITY_FILE=/tmp/activity.json ORCH_NO_PUNT_READY_FILE=/tmp/ready.json orch-no-punt-output-gate.sh check --text-stdin --json
EOF
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

fail_usage() {
  printf 'ERR: %s\n' "$1" >&2
  usage >&2
  exit 2
}

detect_punt_pattern() {
  local text="$1"
  local phrase regex
  while IFS='|' read -r phrase regex; do
    if printf '%s\n' "$text" | grep -Eiq -- "$regex"; then
      printf '%s\n' "$phrase"
      return 0
    fi
  done <<'EOF'
want me to|want me to
should I|should[[:space:]]+i
do you want|do[[:space:]]+you[[:space:]]+want
Options:|(^|[[:space:]])options:
my pick:|my[[:space:]]+pick:
my read is|my[[:space:]]+read[[:space:]]+is
let me know if|let[[:space:]]+me[[:space:]]+know[[:space:]]+if
standing by for|standing[[:space:]]+by[[:space:]]+for
q?:|q[123]\?:
EOF
  return 1
}

detect_blocker_class() {
  local text="$1"
  local class regex
  while IFS='|' read -r class regex; do
    if printf '%s\n' "$text" | grep -Eiq -- "$regex"; then
      printf '%s\n' "$class"
      return 0
    fi
  done <<'EOF'
credential_or_secret_rotation|(rotat(e|ing|ion).*(token|secret|api[[:space:]-]?key|credential|bearer))|(token|secret|credential|api[[:space:]-]?key).*(rotat(e|ing|ion))|cloudflare[[:space:]-]?access|agentmail[[:space:]-]?bearer|vercel[[:space:]-]?api[[:space:]-]?key
destructive_approval|delete[[:space:]]+production|drop[[:space:]]+database|destroy|reset[[:space:]]+--hard|force[[:space:]-]?push|irreversible|destructive[[:space:]-]?approval
production_deploy_or_incident|prod(uction)?[[:space:]-]?(deploy|incident|outage|rollback)|customer[[:space:]-]?visible[[:space:]-]?incident
privacy_or_phi|PHI|HIPAA|patient|medical[[:space:]-]?record|client[[:space:]-]?confidential|PII[[:space:]-]?export
legal_or_contract|legal[[:space:]-]?decision|contract[[:space:]-]?(term|approval|change)|regulatory|compliance[[:space:]-]?signoff
paradigm_or_business_decision|paradigm[[:space:]-]?shift|pricing[[:space:]-]?decision|client[[:space:]-]?commitment|scope[[:space:]-]?decision|business[[:space:]-]?decision
EOF
  return 1
}

activity_json() {
  if [[ -n "$ACTIVITY_FILE" ]]; then
    cat "$ACTIVITY_FILE"
    return $?
  fi
  "$NTM_BIN" --robot-activity="$SESSION" --activity-type=codex,claude --json
}

waiting_panes_json() {
  local payload="$1"
  jq -c '
    def rows:
      [ .agents[]?, .panes[]?, .workers[]?, .rows[]? | select(type == "object") ];
    def pane_num:
      (.pane_idx // .pane // .idx // .pane_id // null) as $p
      | if $p == null then empty else ($p | tonumber? // $p) end;
    def waiting:
      (((.state // .robot_state // .activity_state // "") | tostring | ascii_upcase) == "WAITING")
      or (((.idle_state_class // "") | tostring) | test("dispatching|waiting"; "i"))
      or (((.detected_patterns // []) | map(tostring) | any(test("waiting"; "i"))));
    rows | map(select(waiting) | pane_num) | unique
  ' <<<"$payload"
}

ready_bead_count() {
  local path="$1"
  [[ -r "$path" ]] || { printf '0\n'; return 0; }
  local raw
  raw="$(cat "$path")" || { printf '0\n'; return 1; }
  if [[ "$(jq -s 'length' <<<"$raw" 2>/dev/null || printf 0)" == "1" ]]; then
    jq -s -r '
      def openish:
        (((.status // "") | tostring | ascii_downcase) == "open");
      def items:
        if type == "array" then .
        elif type == "object" then (.issues // .items // .beads // .rows // [])
        else [] end;
      .[0]
      | if type == "object" and ((has("issues") or has("items") or has("beads") or has("rows")) | not)
        then [.]
        else items
        end
      | map(select(openish)) | length
    ' <<<"$raw"
  else
    jq -R -s -r '
      split("\n")
      | map(select(length > 0) | try fromjson catch empty | select(type == "object"))
      | map(select(((.status // "") | tostring | ascii_downcase) == "open"))
      | length
    ' "$path" 2>/dev/null || grep -c '"status":"open"' "$path" 2>/dev/null || printf '0\n'
  fi
}

append_ledger() {
  local row="$1"
  mkdir -p "$(dirname "$LEDGER")" 2>/dev/null || return 1
  jq -c . <<<"$row" >>"$LEDGER" 2>/dev/null
}

emit_decision() {
  local decision="$1" reason="$2" pattern="$3" waiting="$4" ready="$5" blocker="$6" warnings="$7" rc="$8"
  local ts payload ledger_written=false
  ts="$(now_iso)"
  payload="$(jq -nc \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg ts "$ts" \
    --arg session "$SESSION" \
    --arg decision "$decision" \
    --arg reason "$reason" \
    --arg pattern "$pattern" \
    --arg blocker "$blocker" \
    --arg ledger "$LEDGER" \
    --arg warnings "$warnings" \
    --argjson waiting "$waiting" \
    --argjson ready "$ready" \
    '{
      schema_version:$schema_version,
      version:$version,
      ts:$ts,
      session:$session,
      decision:$decision,
      reason:$reason,
      punt_pattern_matched:(if $pattern == "" then null else $pattern end),
      panes_waiting:$waiting,
      ready_beads:$ready,
      blocker_class_matched:(if $blocker == "" then null else $blocker end),
      ledger_appended:$ledger,
      warnings:($warnings | split("\n") | map(select(length > 0)))
    }')"
  if append_ledger "$payload"; then
    ledger_written=true
  fi
  payload="$(jq -c --argjson written "$ledger_written" '. + {ledger_written:$written}' <<<"$payload")"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    printf 'decision=%s reason=%s punt_pattern=%s ready_beads=%s panes_waiting=%s\n' \
      "$decision" "$reason" "${pattern:-null}" "$ready" "$waiting"
  fi
  exit "$rc"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    check)
      MODE="check"; shift ;;
    --text-file)
      [[ -n "${2:-}" ]] || fail_usage "--text-file requires PATH"
      TEXT_FILE="$2"; shift 2 ;;
    --text-stdin)
      TEXT_STDIN=1; shift ;;
    --session)
      [[ -n "${2:-}" ]] || fail_usage "--session requires NAME"
      SESSION="$2"; shift 2 ;;
    --json)
      JSON_OUT=1; shift ;;
    --info)
      info; exit 0 ;;
    --examples)
      examples; exit 0 ;;
    --help|-h)
      usage; exit 0 ;;
    *)
      fail_usage "unknown argument: $1" ;;
  esac
done

[[ "$MODE" == "check" ]] || fail_usage "missing command: check"
if [[ -n "$TEXT_FILE" && "$TEXT_STDIN" -eq 1 ]]; then
  fail_usage "choose one of --text-file or --text-stdin"
fi
if [[ -z "$TEXT_FILE" && "$TEXT_STDIN" -eq 0 ]]; then
  fail_usage "missing --text-file or --text-stdin"
fi

TEXT=""
WARNINGS=""
if [[ -n "$TEXT_FILE" ]]; then
  if [[ -r "$TEXT_FILE" && -f "$TEXT_FILE" ]]; then
    TEXT="$(cat "$TEXT_FILE" 2>/dev/null || true)"
  else
    WARNINGS="text_file_unreadable_fail_open:$TEXT_FILE"
    emit_decision "allow" "text_file_unreadable_fail_open" "" "[]" "0" "" "$WARNINGS" 0
  fi
else
  TEXT="$(cat 2>/dev/null || true)"
fi

PUNT_PATTERN=""
if ! PUNT_PATTERN="$(detect_punt_pattern "$TEXT" 2>/dev/null)"; then
  PUNT_PATTERN=""
fi

BLOCKER_CLASS=""
if [[ -n "$PUNT_PATTERN" ]]; then
  if ! BLOCKER_CLASS="$(detect_blocker_class "$TEXT" 2>/dev/null)"; then
    BLOCKER_CLASS=""
  fi
fi

ACTIVITY=""
WAITING="[]"
READY="0"
PROBE_ERROR=0

if ! ACTIVITY="$(activity_json 2>/dev/null)"; then
  PROBE_ERROR=1
  WARNINGS="${WARNINGS}${WARNINGS:+$'\n'}ntm_activity_probe_failed"
elif ! jq -e . >/dev/null 2>&1 <<<"$ACTIVITY"; then
  PROBE_ERROR=1
  WARNINGS="${WARNINGS}${WARNINGS:+$'\n'}ntm_activity_json_invalid"
elif ! WAITING="$(waiting_panes_json "$ACTIVITY" 2>/dev/null)"; then
  PROBE_ERROR=1
  WAITING="[]"
  WARNINGS="${WARNINGS}${WARNINGS:+$'\n'}waiting_pane_parse_failed"
fi

if ! READY="$(ready_bead_count "$READY_FILE" 2>/dev/null)"; then
  PROBE_ERROR=1
  READY="0"
  WARNINGS="${WARNINGS}${WARNINGS:+$'\n'}ready_bead_probe_failed"
fi
READY="${READY:-0}"
[[ "$READY" =~ ^[0-9]+$ ]] || READY="0"

if [[ -z "$PUNT_PATTERN" ]]; then
  emit_decision "allow" "no_punt_pattern" "" "$WAITING" "$READY" "" "$WARNINGS" 0
fi

if [[ -n "$BLOCKER_CLASS" ]]; then
  emit_decision "allow" "blocker_class_detected" "$PUNT_PATTERN" "$WAITING" "$READY" "$BLOCKER_CLASS" "$WARNINGS" 0
fi

if [[ "$PROBE_ERROR" -ne 0 ]]; then
  emit_decision "allow" "probe_error_fail_open" "$PUNT_PATTERN" "$WAITING" "$READY" "" "$WARNINGS" 0
fi

WAITING_COUNT="$(jq -r 'length' <<<"$WAITING" 2>/dev/null || printf '0')"
if [[ "$WAITING_COUNT" -gt 0 && "$READY" -gt 0 ]]; then
  emit_decision "refuse" "punt_pattern_with_idle_worker_and_ready_beads" "$PUNT_PATTERN" "$WAITING" "$READY" "" "$WARNINGS" 1
fi

if [[ "$WAITING_COUNT" -eq 0 ]]; then
  emit_decision "allow" "no_idle_worker_capacity" "$PUNT_PATTERN" "$WAITING" "$READY" "" "$WARNINGS" 0
fi

emit_decision "allow" "no_ready_beads" "$PUNT_PATTERN" "$WAITING" "$READY" "" "$WARNINGS" 0
