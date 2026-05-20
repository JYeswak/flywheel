#!/usr/bin/env bash
set -u

VERSION="orch-no-punt-output-gate.v2.0.0"
SCHEMA_VERSION="orch-no-punt-decision/v2"
LEDGER="${FLYWHEEL_ORCH_NO_PUNT_LOG:-${ORCH_NO_PUNT_LEDGER:-$HOME/.local/state/flywheel/orch-no-punt-log.jsonl}}"
NTM_BIN="${ORCH_NO_PUNT_NTM_BIN:-$HOME/.local/bin/ntm}"
ACTIVITY_FILE="${ORCH_NO_PUNT_ACTIVITY_FILE:-}"
JSONL_APPEND_LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"
SESSION="${FLYWHEEL_SESSION:-flywheel}"
MODE="${FLYWHEEL_ORCH_NO_PUNT_MODE:-warn}"
TEXT_FILE=""
TEXT_STDIN=0
JSON_OUT=0
TEXT=""

usage() {
  cat <<'EOF'
usage:
  orch-no-punt-output-gate.sh [check] [--mode warn|refuse|measure] [--session NAME] [--text-file PATH|--text-stdin] [--json]
  orch-no-punt-output-gate.sh --info
EOF
}

info() {
  jq -nc \
    --arg name "orch-no-punt-output-gate.sh" \
    --arg version "$VERSION" \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg ledger "$LEDGER" \
    '{name:$name,version:$version,schema_version:$schema_version,ledger:$ledger,modes:["warn","refuse","measure"],true_blocker_classes:["new-platform-or-vendor-not-in-mission-lock","secret-rotation-or-new-credential-creation","financial-commitment-above-mission-budget","legal-or-compliance-decision","destructive-irreversible-on-shared-state","paradigm-conflict-with-active-mission"],fail_open:true}'
}

die_usage() {
  printf 'ERR: %s\n' "$1" >&2
  usage >&2
  exit 2
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

detect_punt_pattern() {
  local phrase regex
  while IFS='|' read -r phrase regex; do
    if printf '%s\n' "$TEXT" | grep -Eiq -- "$regex"; then
      printf '%s\n' "$phrase"
      return 0
    fi
  done <<'EOF'
want me to|want[[:space:]]+me[[:space:]]+to
should I|should[[:space:]]+i
do you want|do[[:space:]]+you[[:space:]]+want
options:|(^|[[:space:]])options:
my pick:|my[[:space:]]+pick:
my read:|my[[:space:]]+read:
EOF
  return 1
}

detect_blocker_class() {
  local class regex
  while IFS='|' read -r class regex; do
    if printf '%s\n' "$TEXT" | grep -Eiq -- "$regex"; then
      printf '%s\n' "$class"
      return 0
    fi
  done <<'EOF'
new-platform-or-vendor-not-in-mission-lock|(new[[:space:]-]+(platform|vendor)|vendor[[:space:]-]+not[[:space:]-]+in[[:space:]-]+mission|unapproved[[:space:]-]+vendor|render[[:space:]-]+deploy|not[[:space:]-]+named[[:space:]-]+in[[:space:]-]+mission)
secret-rotation-or-new-credential-creation|(rotat(e|ing|ion)|regenerate|create[[:space:]-]+new).*(secret|token|credential|api[[:space:]-]*key|password|bearer)|(secret|token|credential|api[[:space:]-]*key|password|bearer).*(rotat(e|ing|ion)|regenerate|create[[:space:]-]+new)
financial-commitment-above-mission-budget|(paid[[:space:]-]+plan|upgrade|pro[[:space:]-]+plan|credit[[:space:]-]+card|budget[[:space:]-]+envelope|financial[[:space:]-]+commitment|\$[0-9])
legal-or-compliance-decision|(legal|compliance|contract|dpa|terms[[:space:]-]+of[[:space:]-]+service|tos|regulatory|audit[[:space:]-]+signoff)
destructive-irreversible-on-shared-state|(drop[[:space:]-]+(prod|production|database|db)|delete[[:space:]-]+(prod|production|deployed|shared)|force[[:space:]-]+push|destroy|irreversible|wipe[[:space:]-]+shared)
paradigm-conflict-with-active-mission|(paradigm[[:space:]-]+conflict|rewrite[[:space:]-]+mission[[:space:]-]+anchor|contradict[[:space:]-]+axiom|active[[:space:]-]+mission[[:space:]-]+conflict)
EOF
  return 1
}

detect_fix_signal() {
  local regex
  while IFS= read -r regex; do
    if printf '%s\n' "$TEXT" | grep -Eq -- "$regex"; then
      printf 'named-fix-artifact\n'
      return 0
    fi
  done <<'EOF'
flywheel-[A-Za-z0-9._-]+
/tmp/dispatch_[^[:space:]]+
[.]flywheel/(scripts|tests)/[A-Za-z0-9._/-]+
(^|[[:space:]])tests/[A-Za-z0-9._/-]+
(^|[[:space:]])scripts/[A-Za-z0-9._/-]+
OK_[A-Za-z0-9_]+|L112
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
  jq -c '
    [(.agents // [])[], (.panes // [])[], (.workers // [])[], (.rows // [])[]]
    | map(select(type == "object"))
    | map(select(
        (((.state // .robot_state // .activity_state // "") | tostring | ascii_upcase) == "WAITING")
        or (((.idle_state_class // "") | tostring) | test("waiting"; "i"))
        or (((.detected_patterns // []) | map(tostring) | any(test("waiting"; "i"))))
      ))
    | map(.pane_idx // .pane // .idx // .pane_id // empty)
    | unique
  '
}

append_ledger() {
  local row="$1"
  mkdir -p "$(dirname "$LEDGER")" 2>/dev/null || return 1
  if [[ -r "$JSONL_APPEND_LIB" ]]; then
    # shellcheck source=/dev/null
    source "$JSONL_APPEND_LIB"
    if declare -F fw_jsonl_append_validated >/dev/null 2>&1; then
      fw_jsonl_append_validated "$LEDGER" "$row"
      return $?
    fi
  fi
  jq -c . <<<"$row" >>"$LEDGER"
}

emit_decision() {
  local decision="$1" reason="$2" pattern="$3" waiting="$4" fix="$5" blocker="$6" warnings="$7" rc="$8"
  local payload ledger_written=false ts
  ts="$(now_iso)"
  payload="$(jq -nc \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg ts "$ts" \
    --arg session "$SESSION" \
    --arg mode "$MODE" \
    --arg decision "$decision" \
    --arg reason "$reason" \
    --arg pattern "$pattern" \
    --arg fix "$fix" \
    --arg blocker "$blocker" \
    --arg ledger "$LEDGER" \
    --arg warnings "$warnings" \
    --argjson waiting "$waiting" \
    '{schema_version:$schema_version,version:$version,ts:$ts,session:$session,mode:$mode,decision:$decision,reason:$reason,punt_pattern_matched:(if $pattern=="" then null else $pattern end),panes_waiting:$waiting,fix_signal_matched:(if $fix=="" then null else $fix end),blocker_class_matched:(if $blocker=="" then null else $blocker end),ledger_appended:$ledger,warnings:($warnings|split("\n")|map(select(length>0)))}')"
  append_ledger "$payload" && ledger_written=true
  payload="$(jq -c --argjson ledger_written "$ledger_written" '. + {ledger_written:$ledger_written}' <<<"$payload")"
  if [[ "$decision" == "refuse" ]]; then
    printf 'orch-no-punt-output-gate refused punt pattern "%s"; TRUE Joshua-blocker classes are: new-platform-or-vendor-not-in-mission-lock, secret-rotation-or-new-credential-creation, financial-commitment-above-mission-budget, legal-or-compliance-decision, destructive-irreversible-on-shared-state, paradigm-conflict-with-active-mission\n' "$pattern" >&2
  fi
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    printf '%s' "$TEXT"
  fi
  exit "$rc"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    check|--check) shift ;;
    --mode) [[ -n "${2:-}" ]] || die_usage "--mode requires value"; MODE="$2"; shift 2 ;;
    --session) [[ -n "${2:-}" ]] || die_usage "--session requires NAME"; SESSION="$2"; shift 2 ;;
    --text-file) [[ -n "${2:-}" ]] || die_usage "--text-file requires PATH"; TEXT_FILE="$2"; shift 2 ;;
    --text-stdin) TEXT_STDIN=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --info) info; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) die_usage "unknown argument: $1" ;;
  esac
done

case "$MODE" in
  warn|refuse|measure) ;;
  *) die_usage "--mode must be warn, refuse, or measure" ;;
esac

if [[ -n "$TEXT_FILE" ]]; then
  [[ -r "$TEXT_FILE" ]] || die_usage "cannot read --text-file: $TEXT_FILE"
  TEXT="$(cat "$TEXT_FILE")"
elif [[ "$TEXT_STDIN" -eq 1 || ! -t 0 ]]; then
  TEXT="$(cat)"
else
  TEXT=""
fi

pattern="$(detect_punt_pattern || true)"
[[ -n "$pattern" ]] || emit_decision "allow" "no_punt_pattern" "" "[]" "" "" "" 0

blocker="$(detect_blocker_class || true)"
[[ -z "$blocker" ]] || emit_decision "allow" "true_joshua_blocker" "$pattern" "[]" "" "$blocker" "" 0

fix_signal="$(detect_fix_signal || true)"
[[ -n "$fix_signal" ]] || emit_decision "allow" "no_fix_signal" "$pattern" "[]" "" "" "" 0

activity="$(activity_json 2>/dev/null)"
activity_rc=$?
if [[ "$activity_rc" -ne 0 || -z "$activity" ]]; then
  emit_decision "allow" "activity_probe_failed_fail_open" "$pattern" "[]" "$fix_signal" "" "ntm activity probe failed" 0
fi

waiting="$(waiting_panes_json <<<"$activity" 2>/dev/null || printf '[]')"
[[ "$waiting" != "null" && "$waiting" != "" ]] || waiting="[]"
if [[ "$(jq 'length' <<<"$waiting" 2>/dev/null || printf 0)" -eq 0 ]]; then
  emit_decision "allow" "no_waiting_worker_pane" "$pattern" "$waiting" "$fix_signal" "" "" 0
fi

if [[ "$MODE" == "refuse" ]]; then
  emit_decision "refuse" "punt_pattern_with_waiting_worker_and_fix_signal" "$pattern" "$waiting" "$fix_signal" "" "" 1
fi
emit_decision "warn" "punt_pattern_with_waiting_worker_and_fix_signal" "$pattern" "$waiting" "$fix_signal" "" "" 0

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
