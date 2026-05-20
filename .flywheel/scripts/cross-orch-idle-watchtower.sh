#!/usr/bin/env bash
# cross-orch-idle-watchtower.sh — fleet-wide nudge for idle sister-orch codex panes.
#
# Joshua-direct 2026-05-20T03:45Z: "every time I come back skillos is idle" (15+ times today).
# Trauma class: orchestrator-idle-with-ready-beads.
# Solution: periodic probe → if sister orch's codex pane is idle-chat + their own ready
# queue has P0/P1 work → either:
#   (a) send a NUDGE handoff to sister orch CC pane (default — respects autonomy)
#   (b) DIRECT cross-orch /goal dispatch (per flywheel-owns-orch-pane-recovery memory
#       authority — use sparingly, only when sister CC unresponsive)
#
# Designed to run as launchd cadence every 5min.
#
# Exit codes:
#   0 = no idle panes detected, or all nudges sent
#   1 = config/probe error

set -uo pipefail

VERSION="cross-orch-idle-watchtower.v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
LABEL="ai.zeststream.cross-orch-idle-watchtower"
INTERVAL_DEFAULT=300
MODE="${WATCHTOWER_MODE:-report-only}"
JSON_OUT=false
APPLY=false
DRY_RUN=true
COMMAND="run"
SUBJECT=""
NTM_BIN="${WATCHTOWER_NTM_BIN:-/Users/josh/.local/bin/ntm}"
TMUX_BIN="${WATCHTOWER_TMUX_BIN:-tmux}"
BR_BIN="${WATCHTOWER_BR_BIN:-/Users/josh/.cargo/bin/br}"
PLIST_PATH="${WATCHTOWER_PLIST:-$ROOT/.flywheel/launchd/$LABEL.plist}"
SESSIONS=(
  "skillos:/Users/josh/Developer/skillos"
  "mobile-eats:/Users/josh/Developer/mobile-eats"
  "picoz:/Users/josh/Developer/picoz"
  "clutterfreespaces:/Users/josh/Developer/clutterfreespaces"
  "alpsinsurance:/Users/josh/Developer/alpsinsurance"
  "vrtx:/Users/josh/Developer/vrtx"
  "zesttube:/Users/josh/Developer/zesttube"
)
LEDGER="${HOME}/.local/state/flywheel/cross-orch-idle-watchtower.jsonl"

usage() {
  cat <<USAGE
Usage:
  cross-orch-idle-watchtower.sh [run] [--mode report-only|nudge|direct-dispatch] [--dry-run|--apply] [--json]
  cross-orch-idle-watchtower.sh doctor|health|schema|info|examples [--json]
  cross-orch-idle-watchtower.sh validate plist [--plist PATH] [--json]

Fleet-wide watchtower for sister-orch idle Codex panes with ready P0/P1 beads.
USAGE
}

json_bool() {
  [[ "${1:-false}" == "true" ]] && printf 'true' || printf 'false'
}

load_sessions_override() {
  [[ -n "${WATCHTOWER_SESSIONS:-}" ]] || return 0
  SESSIONS=()
  while IFS= read -r entry; do
    [[ -n "$entry" ]] && SESSIONS+=("$entry")
  done < <(printf '%s\n' "$WATCHTOWER_SESSIONS" | tr ',' '\n')
}

emit_info() {
  jq -nc --arg version "$VERSION" --arg label "$LABEL" --arg ledger "$LEDGER" --arg plist "$PLIST_PATH" '{
    schema_version:$version,
    command:"info",
    label:$label,
    purpose:"fleet-wide sister-orch idle-pane nudge watchtower",
    ledger:$ledger,
    source_plist:$plist,
    mutation_contract:"report-only by default; nudge/direct-dispatch require --apply",
    canonical_flags:["--json","--dry-run","--apply","--mode","--ledger","--plist"],
    surfaces:["run","doctor","health","validate plist","schema","info","examples"]
  }'
}

emit_examples() {
  jq -nc '{
    examples:[
      "cross-orch-idle-watchtower.sh run --mode report-only --dry-run --json",
      "cross-orch-idle-watchtower.sh run --mode nudge --apply --json",
      "cross-orch-idle-watchtower.sh validate plist --json",
      "cross-orch-idle-watchtower.sh doctor --json"
    ]
  }'
}

emit_schema() {
  jq -nc --arg version "$VERSION" '{
    "$schema":"https://json-schema.org/draft/2020-12/schema",
    title:"cross-orch idle watchtower run output",
    type:"object",
    required:["schema_version","ts","mode","dry_run","apply","idle_panes_with_ready_beads","nudges_sent","ledger"],
    properties:{
      schema_version:{const:$version},
      ts:{type:"string"},
      mode:{enum:["report-only","nudge","direct-dispatch"]},
      dry_run:{type:"boolean"},
      apply:{type:"boolean"},
      idle_panes_with_ready_beads:{type:"integer"},
      nudges_sent:{type:"integer"},
      direct_dispatches:{type:"integer"},
      ledger:{type:"string"}
    }
  }'
}

emit_doctor() {
  local checks="" overall="pass" ledger_dir
  ledger_dir="$(dirname "$LEDGER")"
  for bin_name in jq python3; do
    if command -v "$bin_name" >/dev/null 2>&1; then
      checks+="$(jq -nc --arg n "$bin_name" --arg p "$(command -v "$bin_name")" '{name:$n,status:"pass",path:$p}')"$'\n'
    else
      checks+="$(jq -nc --arg n "$bin_name" '{name:$n,status:"fail"}')"$'\n'
      overall="fail"
    fi
  done
  if command -v "$TMUX_BIN" >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$TMUX_BIN" '{name:"tmux",status:"pass",path:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$TMUX_BIN" '{name:"tmux",status:"warn",path:$p,detail:"run mode skips absent sessions but live cadence needs tmux"}')"$'\n'
  fi
  if [[ -x "$NTM_BIN" ]]; then
    checks+="$(jq -nc --arg p "$NTM_BIN" '{name:"ntm_bin",status:"pass",path:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$NTM_BIN" '{name:"ntm_bin",status:"warn",path:$p,detail:"nudge mode cannot send without ntm"}')"$'\n'
  fi
  if [[ -x "$BR_BIN" ]]; then
    checks+="$(jq -nc --arg p "$BR_BIN" '{name:"br_bin",status:"pass",path:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$BR_BIN" '{name:"br_bin",status:"warn",path:$p,detail:"ready queue counts fall back to 0 without br"}')"$'\n'
  fi
  if mkdir -p "$ledger_dir" 2>/dev/null && [[ -w "$ledger_dir" ]]; then
    checks+="$(jq -nc --arg p "$ledger_dir" '{name:"ledger_dir_writable",status:"pass",path:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$ledger_dir" '{name:"ledger_dir_writable",status:"fail",path:$p}')"$'\n'
    overall="fail"
  fi
  if [[ -f "$PLIST_PATH" ]] && plutil -lint "$PLIST_PATH" >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$PLIST_PATH" '{name:"source_plist_lint",status:"pass",path:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$PLIST_PATH" '{name:"source_plist_lint",status:"warn",path:$p}')"$'\n'
  fi
  printf '%s' "$checks" | jq -sc --arg version "$VERSION" --arg status "$overall" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$version,command:"doctor",ts:$ts,status:$status,checks:.}'
}

emit_health() {
  local last="null" rows=0 status="warn"
  if [[ -r "$LEDGER" ]]; then
    rows="$(wc -l < "$LEDGER" 2>/dev/null | tr -d ' ' || echo 0)"
    last="$(tail -n 1 "$LEDGER" 2>/dev/null || printf 'null')"
    printf '%s' "$last" | jq -e . >/dev/null 2>&1 && status="pass" || last="null"
  fi
  jq -nc --arg version "$VERSION" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg ledger "$LEDGER" --arg status "$status" --argjson rows "${rows:-0}" --argjson last "$last" \
    '{schema_version:$version,command:"health",ts:$ts,status:$status,ledger:$ledger,row_count:$rows,last_row:$last}'
}

validate_plist() {
  local plist="$PLIST_PATH"
  [[ -n "${1:-}" ]] && plist="$1"
  if [[ ! -f "$plist" ]]; then
    jq -nc --arg version "$VERSION" --arg plist "$plist" '{schema_version:$version,command:"validate",subject:"plist",status:"fail",plist:$plist,reason:"missing"}'
    return 1
  fi
  if ! plutil -lint "$plist" >/dev/null 2>&1; then
    jq -nc --arg version "$VERSION" --arg plist "$plist" '{schema_version:$version,command:"validate",subject:"plist",status:"fail",plist:$plist,reason:"plutil_lint_failed"}'
    return 1
  fi
  python3 - "$VERSION" "$LABEL" "$INTERVAL_DEFAULT" "$plist" <<'PY'
import json
import plistlib
import sys

version, expected_label, expected_interval, path = sys.argv[1:]
with open(path, "rb") as handle:
    plist = plistlib.load(handle)
args = plist.get("ProgramArguments", [])
checks = {
    "label_ok": plist.get("Label") == expected_label,
    "cadence_ok": plist.get("StartInterval") == int(expected_interval),
    "runs_watchtower": bool(args) and args[0].endswith("/.flywheel/scripts/cross-orch-idle-watchtower.sh"),
    "nudge_apply_json": "--mode" in args and "nudge" in args and "--apply" in args and "--json" in args,
}
status = "pass" if all(checks.values()) else "fail"
print(json.dumps({
    "schema_version": version,
    "command": "validate",
    "subject": "plist",
    "status": status,
    "plist": path,
    **checks,
}, separators=(",", ":")))
sys.exit(0 if status == "pass" else 1)
PY
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    run|doctor|health|schema|info|examples) COMMAND="$1"; shift ;;
    validate) COMMAND="validate"; SUBJECT="${2:-}"; shift; [[ -n "${1:-}" ]] && shift ;;
    --mode) MODE="$2"; shift 2 ;;       # nudge | direct-dispatch | report-only
    --mode=*) MODE="${1#*=}"; shift ;;
    --json) JSON_OUT=true; shift ;;
    --apply) APPLY=true; DRY_RUN=false; shift ;;
    --dry-run) APPLY=false; DRY_RUN=true; shift ;;
    --ledger) LEDGER="$2"; shift 2 ;;
    --ledger=*) LEDGER="${1#*=}"; shift ;;
    --plist) PLIST_PATH="$2"; shift 2 ;;
    --plist=*) PLIST_PATH="${1#*=}"; shift ;;
    --info) COMMAND="info"; shift ;;
    --examples) COMMAND="examples"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 1 ;;
  esac
done

case "$MODE" in
  report-only|nudge|direct-dispatch) ;;
  *) echo "unknown mode: $MODE" >&2; exit 1 ;;
esac

case "$COMMAND" in
  info) emit_info; exit 0 ;;
  examples) emit_examples; exit 0 ;;
  schema) emit_schema; exit 0 ;;
  doctor) emit_doctor; exit 0 ;;
  health) emit_health; exit 0 ;;
  validate)
    [[ "$SUBJECT" == "plist" ]] || { echo "unknown validate subject: ${SUBJECT:-}" >&2; exit 1; }
    validate_plist "$PLIST_PATH"
    exit $?
    ;;
esac

load_sessions_override
mkdir -p "$(dirname "$LEDGER")"

classify_pane_state() {
  local target="$1"
  local snap
  snap="$("$TMUX_BIN" capture-pane -t "$target" -p 2>/dev/null | tail -30)"
  if echo "$snap" | grep -qE 'Pursuing goal \('; then echo "goal-in-progress"
  elif echo "$snap" | grep -q "Goal paused"; then echo "goal-paused"
  elif echo "$snap" | grep -qE "Working \([0-9]+s"; then echo "working-non-goal"
  elif echo "$snap" | grep -q "Goal achieved\|Goal complete"; then echo "goal-completing"
  elif echo "$snap" | grep -qE "› (Use /skills|Explain this codebase|Implement \{|Write tests|Find and fix|Run /review|Summarize recent|Improve documentation)"; then echo "idle-chat-default-placeholder"
  elif echo "$snap" | grep -q "Application not found\|josh@.*%"; then echo "shell-no-codex"
  else echo "idle-chat-or-unknown"
  fi
}

count_ready_beads() {
  local repo_path="$1"
  if [[ -d "$repo_path/.beads" ]]; then
    (cd "$repo_path" && "$BR_BIN" ready --json 2>/dev/null | \
      python3 -c "
import json,sys
try:
    d=json.load(sys.stdin); items=d if isinstance(d,list) else d.get('items',[])
    p0=sum(1 for i in items if i.get('priority')==0)
    p1=sum(1 for i in items if i.get('priority')==1)
    print(f'{p0} {p1}')
except: print('0 0')
")
  else
    echo "0 0"
  fi
}

emit_row() {
  printf '{"schema_version":"%s","ts":"%s","session":"%s","pane":%d,"state":"%s","p0_ready":%d,"p1_ready":%d,"action":"%s","reason":"%s"}\n' \
    "$VERSION" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2" "$3" "$4" "$5" "$6" "$7" \
    | tee -a "$LEDGER"
}

idle_detected=0
nudges_sent=0
direct_dispatches=0

for entry in "${SESSIONS[@]}"; do
  sess="${entry%:*}"
  repo="${entry#*:}"
  if ! "$TMUX_BIN" has-session -t "$sess" 2>/dev/null; then
    continue
  fi
  read -r p0 p1 <<< "$(count_ready_beads "$repo")"

  for pane in 2 3 4; do
    if ! "$TMUX_BIN" list-panes -t "${sess}:0" -F '#{pane_index}' 2>/dev/null | grep -q "^${pane}$"; then
      continue
    fi
    state="$(classify_pane_state "${sess}:0.${pane}")"
    is_idle=0
    case "$state" in
      idle-chat-*|goal-completing) is_idle=1 ;;
    esac

    if (( is_idle == 1 )) && (( p0 + p1 > 0 )); then
      idle_detected=$((idle_detected + 1))
      action="report-only"
      reason="sister-orch-cc-may-handle"
      if [[ "$MODE" == "nudge" ]] && [[ "$APPLY" != "true" ]]; then
        action="would-nudge"
        reason="requires-apply"
      elif [[ "$MODE" == "nudge" ]]; then
        # Send handoff-style nudge to sister orch CC pane (pane 1)
        nudge_msg="ORCH-IDLE NUDGE from flywheel:1 cross-orch-idle-watchtower at $(date -u +%H:%MZ): your pane ${pane} is ${state} but your repo has P0=${p0} P1=${p1} ready beads. Dispatch via your own /skillos:dispatch (or equivalent) using /goal-mode workaround per memory feedback_goal_mode_is_codex_usage_limit_workaround. Don't go idle when work is available."
        if "$NTM_BIN" send "$sess" --pane=1 --no-cass-check "$nudge_msg" >/dev/null 2>&1; then
          action="nudge-sent"
          nudges_sent=$((nudges_sent + 1))
        else
          action="nudge-failed"
          reason="ntm-send-error"
        fi
      elif [[ "$MODE" == "direct-dispatch" ]] && [[ "$APPLY" == "true" ]]; then
        # ONLY use when sister CC confirmed unresponsive — needs explicit override
        action="direct-dispatch-suppressed"
        reason="direct-dispatch-needs-explicit-override-flag-NOT-yet-built"
      fi
    fi

    if (( is_idle == 1 )) && (( p0 + p1 > 0 )); then
      emit_row "$sess" "$pane" "$state" "$p0" "$p1" "$action" "$reason" >/dev/null
    fi
  done
done

if [[ "$JSON_OUT" == "true" ]]; then
  printf '{"schema_version":"%s","ts":"%s","mode":"%s","dry_run":%s,"apply":%s,"idle_panes_with_ready_beads":%d,"nudges_sent":%d,"direct_dispatches":%d,"ledger":"%s"}\n' \
    "$VERSION" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$MODE" "$DRY_RUN" "$APPLY" "$idle_detected" "$nudges_sent" "$direct_dispatches" "$LEDGER"
else
  echo "idle_panes_with_ready_beads=$idle_detected nudges_sent=$nudges_sent direct_dispatches=$direct_dispatches apply=$APPLY"
fi
