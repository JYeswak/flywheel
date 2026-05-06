#!/usr/bin/env bash
set -u

VERSION="orch-donella-trace-gate.v1.0.0"
SCHEMA_VERSION="orch-donella-trace-decision/v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO_ROOT="${ORCH_DONELLA_REPO:-$REPO_ROOT_DEFAULT}"
LEDGER="${ORCH_DONELLA_LEDGER:-$HOME/.local/state/flywheel/orch-donella-trace-gate-ledger.jsonl}"
SESSION="flywheel"
MODE=""
TEXT_FILE=""
TEXT_STDIN=0
JSON_OUT=0
REQUIRED_KEYWORDS=5

usage() {
  cat <<'EOF'
usage:
  orch-donella-trace-gate.sh check --text-file PATH [--session NAME] [--json]
  orch-donella-trace-gate.sh check --text-stdin [--session NAME] [--json]
  orch-donella-trace-gate.sh --info|--help|--examples
EOF
}

info() {
  jq -nc \
    --arg name "orch-donella-trace-gate.sh" \
    --arg version "$VERSION" \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg ledger "$LEDGER" \
    --arg repo "$REPO_ROOT" \
    '{name:$name,version:$version,schema_version:$schema_version,ledger:$ledger,repo:$repo,purpose:"refuse Joshua-disposes or substrate-action prose that lacks a Donella trace",required_keywords:5,fail_open:true}'
}

examples() {
  cat <<'EOF'
printf 'Should we deploy this?\n' | orch-donella-trace-gate.sh check --text-stdin --session flywheel --json
printf 'Boundary: repo. Stock: idle panes. Flow: callbacks. Loop: dispatch. Leverage: rules. Should we deploy this?\n' | orch-donella-trace-gate.sh check --text-stdin --json
orch-donella-trace-gate.sh check --text-file /tmp/assistant-final.txt --session flywheel --json
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

detect_joshua_disposes_pattern() {
  local text="$1"
  local phrase regex
  while IFS='|' read -r phrase regex; do
    if printf '%s\n' "$text" | grep -Eiq -- "$regex"; then
      printf '%s\n' "$phrase"
      return 0
    fi
  done <<'EOF'
should we|should[[:space:]]+we
do we|do[[:space:]]+we
want me to|want[[:space:]]+me[[:space:]]+to
approve?|approve[[:space:]]*\?
y/n|(^|[^[:alnum:]])y/n([^[:alnum:]]|$)
sign-off|sign[[:space:]-]?off
disposes?|disposes[[:space:]]*\?
EOF
  return 1
}

detect_action_without_trace_pattern() {
  local text="$1"
  local phrase regex
  while IFS='|' read -r phrase regex; do
    if printf '%s\n' "$text" | grep -Eiq -- "$regex"; then
      printf '%s\n' "$phrase"
      return 0
    fi
  done <<'EOF'
substrate action|(i|we)[[:space:]]+(will|can|should|am|are|ll|'ll)[[:space:]].*(wire|register|enable|disable|deploy|rotate|delete|drop|create|update|modify|change|close|reopen|dispatch|install|uninstall|restart|merge|commit|push|ship|add|remove).*(gate|hook|settings|launchd|bead|schema|ledger|doctor|worker|orchestrator|pane|ntm|agent[[:space:]-]?mail|cloudflare|vercel|token|secret|api[[:space:]-]?key|database|production|incident|substrate)
substrate action|let'?s[[:space:]].*(wire|register|enable|disable|deploy|rotate|delete|drop|create|update|modify|change|close|reopen|dispatch|install|uninstall|restart|merge|commit|push|ship|add|remove).*(gate|hook|settings|launchd|bead|schema|ledger|doctor|worker|orchestrator|pane|ntm|agent[[:space:]-]?mail|cloudflare|vercel|token|secret|api[[:space:]-]?key|database|production|incident|substrate)
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

donella_keywords_json() {
  local text="$1"
  printf '%s\n' "$text" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -c '[:alnum:]_' '\n' \
    | awk '
      $0 == "boundary" || $0 == "stock" || $0 == "flow" || $0 == "loop" ||
      $0 == "leverage" || $0 == "intervention" || $0 == "measurement" { seen[$0] = 1 }
      END {
        printf "["
        sep = ""
        split("boundary stock flow loop leverage intervention measurement", keys, " ")
        for (i = 1; i <= 7; i++) {
          if (seen[keys[i]]) {
            printf "%s\"%s\"", sep, keys[i]
            sep = ","
          }
        }
        printf "]"
      }'
}

append_ledger() {
  local row="$1"
  mkdir -p "$(dirname "$LEDGER")" 2>/dev/null || return 1
  jq -c . <<<"$row" >>"$LEDGER" 2>/dev/null
}

emit_decision() {
  local decision="$1" reason="$2" joshua_pattern="$3" action_pattern="$4" keywords="$5" blocker="$6" warnings="$7" rc="$8"
  local ts payload ledger_written=false
  ts="$(now_iso)"
  payload="$(jq -nc \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg ts "$ts" \
    --arg session "$SESSION" \
    --arg decision "$decision" \
    --arg reason "$reason" \
    --arg joshua_pattern "$joshua_pattern" \
    --arg action_pattern "$action_pattern" \
    --arg blocker "$blocker" \
    --arg ledger "$LEDGER" \
    --arg warnings "$warnings" \
    --argjson required "$REQUIRED_KEYWORDS" \
    --argjson keywords "$keywords" \
    '{
      schema_version:$schema_version,
      version:$version,
      ts:$ts,
      session:$session,
      decision:$decision,
      reason:$reason,
      joshua_disposes_pattern:(if $joshua_pattern == "" then null else $joshua_pattern end),
      action_without_trace_pattern:(if $action_pattern == "" then null else $action_pattern end),
      donella_keywords:$keywords,
      donella_keywords_found:($keywords | length),
      required_keywords:$required,
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
    printf 'decision=%s reason=%s joshua_disposes_pattern=%s donella_keywords_found=%s blocker_class=%s\n' \
      "$decision" "$reason" "${joshua_pattern:-null}" "$(jq -r '.donella_keywords_found' <<<"$payload")" "${blocker:-null}"
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
    emit_decision "allow" "text_file_unreadable_fail_open" "" "" "[]" "" "$WARNINGS" 0
  fi
else
  TEXT="$(cat 2>/dev/null || true)"
fi

JOSHUA_PATTERN=""
if ! JOSHUA_PATTERN="$(detect_joshua_disposes_pattern "$TEXT" 2>/dev/null)"; then
  JOSHUA_PATTERN=""
fi

ACTION_PATTERN=""
if ! ACTION_PATTERN="$(detect_action_without_trace_pattern "$TEXT" 2>/dev/null)"; then
  ACTION_PATTERN=""
fi

KEYWORDS="$(donella_keywords_json "$TEXT" 2>/dev/null || printf '[]')"
KEYWORD_COUNT="$(jq -r 'length' <<<"$KEYWORDS" 2>/dev/null || printf '0')"
[[ "$KEYWORD_COUNT" =~ ^[0-9]+$ ]] || KEYWORD_COUNT=0

BLOCKER_CLASS=""
if [[ -n "$JOSHUA_PATTERN" || -n "$ACTION_PATTERN" ]]; then
  if ! BLOCKER_CLASS="$(detect_blocker_class "$TEXT" 2>/dev/null)"; then
    BLOCKER_CLASS=""
  fi
fi

if [[ -z "$JOSHUA_PATTERN" && -z "$ACTION_PATTERN" ]]; then
  emit_decision "allow" "no_donella_gated_pattern" "" "" "$KEYWORDS" "" "$WARNINGS" 0
fi

if [[ -n "$BLOCKER_CLASS" ]]; then
  emit_decision "allow" "blocker_class_detected" "$JOSHUA_PATTERN" "$ACTION_PATTERN" "$KEYWORDS" "$BLOCKER_CLASS" "$WARNINGS" 0
fi

if [[ "$KEYWORD_COUNT" -ge "$REQUIRED_KEYWORDS" ]]; then
  emit_decision "allow" "donella_trace_present" "$JOSHUA_PATTERN" "$ACTION_PATTERN" "$KEYWORDS" "" "$WARNINGS" 0
fi

if [[ -n "$JOSHUA_PATTERN" ]]; then
  emit_decision "refuse" "joshua_disposes_without_donella_trace" "$JOSHUA_PATTERN" "$ACTION_PATTERN" "$KEYWORDS" "" "$WARNINGS" 1
fi

emit_decision "refuse" "substrate_action_without_donella_trace" "$JOSHUA_PATTERN" "$ACTION_PATTERN" "$KEYWORDS" "" "$WARNINGS" 1
