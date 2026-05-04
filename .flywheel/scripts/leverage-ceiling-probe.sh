#!/usr/bin/env bash
set -uo pipefail

VERSION="leverage-ceiling-probe.v1"
SCRIPT_VERSION="2026-05-03.1"
LEDGER="${LEVERAGE_CEILING_LEDGER:-$HOME/.local/state/flywheel/leverage-ceiling.jsonl}"
NTM_BIN="${LEVERAGE_CEILING_NTM_BIN:-/Users/josh/.local/bin/ntm}"
TARGET_ACCOUNTS="${LEVERAGE_CEILING_TARGET_ACCOUNTS:-2}"
SESSION_LIST="${LEVERAGE_CEILING_SESSIONS:-flywheel mobile-eats skillos picoz alps alpsinsurance}"
ACTIVITY_TYPE="${LEVERAGE_CEILING_ACTIVITY_TYPE:-codex,claude}"
TIMEOUT_SECONDS="${LEVERAGE_CEILING_TIMEOUT_SECONDS:-30}"
MODE="probe"

usage() {
  cat <<'USAGE'
Usage:
  leverage-ceiling-probe.sh [--json]
  leverage-ceiling-probe.sh --doctor --json
  leverage-ceiling-probe.sh --info [--json]
  leverage-ceiling-probe.sh --schema
  leverage-ceiling-probe.sh --examples
  leverage-ceiling-probe.sh --help

Read-only, fail-open probe for the current flywheel leverage ceiling.
USAGE
}

examples() {
  cat <<'EXAMPLES'
Examples:
  .flywheel/scripts/leverage-ceiling-probe.sh --json
  .flywheel/scripts/leverage-ceiling-probe.sh --doctor --json
  LEVERAGE_CEILING_TARGET_ACCOUNTS=3 .flywheel/scripts/leverage-ceiling-probe.sh --json
  LEVERAGE_CEILING_ANTHROPIC_PCT=72 LEVERAGE_CEILING_XAI_PCT=91 .flywheel/scripts/leverage-ceiling-probe.sh --json
EXAMPLES
}

schema_json() {
  jq -nc --arg version "$VERSION" '{
    version:$version,
    schema:"flywheel.leverage_ceiling_probe.v1",
    required_fields:[
      "version","ts","accounts_active","accounts_active_source",
      "worker_panes_total","worker_panes_idle_pct","worker_panes_thinking_pct","worker_panes_error_pct",
      "token_budget_remaining_pct_anthropic","token_budget_remaining_pct_xai","token_budget_source_anthropic",
      "leverage_ceiling_score","binding_constraint","binding_evidence","warnings"
    ],
    formula:{
      leverage_ceiling_score:"round(1000 * min(accounts_norm, machines_norm, tokens_norm))",
      accounts_norm:"min(1, accounts_active / target_accounts), target default 2 via LEVERAGE_CEILING_TARGET_ACCOUNTS",
      machines_norm:"worker_panes_idle_pct == 100 ? 1 : worker_panes_thinking_pct / 100",
      tokens_norm:"min(anthropic_pct, xai_pct) / 100; fail-open uses available provider, or 1.0 if both unknown with warning",
      binding_constraint:"arg-min(accounts_norm, machines_norm, tokens_norm)"
    },
    data_sources:{
      accounts:["LEVERAGE_CEILING_ACCOUNTS_ACTIVE","recent Claude .credentials.json files","safe token environment presence"],
      worker_panes:"ntm --robot-activity=<session> --activity-type=codex,claude",
      tokens:["LEVERAGE_CEILING_ANTHROPIC_PCT","LEVERAGE_CEILING_XAI_PCT","provider-specific *_TOKEN_BUDGET_REMAINING_PCT env vars"]
    },
    ledger:"~/.local/state/flywheel/leverage-ceiling.jsonl"
  }'
}

info_json() {
  jq -nc \
    --arg version "$VERSION" \
    --arg script_version "$SCRIPT_VERSION" \
    --arg ntm "$NTM_BIN" \
    --arg ledger "$LEDGER" \
    --arg sessions "$SESSION_LIST" \
    --arg activity_type "$ACTIVITY_TYPE" \
    --argjson target_accounts "$(number_or_zero "$TARGET_ACCOUNTS")" \
    --argjson timeout_seconds "$(number_or_zero "$TIMEOUT_SECONDS")" \
    '{
      success:true,
      mode:"info",
      version:$version,
      script_version:$script_version,
      ntm_bin:$ntm,
      ledger:$ledger,
      sessions:($sessions | split(" ") | map(select(length > 0))),
      activity_type:$activity_type,
      target_accounts:$target_accounts,
      timeout_seconds:$timeout_seconds,
      read_only:true,
      fail_open:true
    }'
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

number_or_zero() {
  local value="$1"
  awk -v v="$value" 'BEGIN { if (v ~ /^[0-9]+([.][0-9]+)?$/) print v + 0; else print 0 }'
}

pct_or_null() {
  local value="$1"
  awk -v v="$value" 'BEGIN {
    if (v ~ /^[0-9]+([.][0-9]+)?$/) {
      if (v < 0) v = 0
      if (v > 100) v = 100
      print v + 0
    } else {
      print "null"
    }
  }'
}

timeout_bin() {
  if command -v gtimeout >/dev/null 2>&1; then
    command -v gtimeout
  elif command -v timeout >/dev/null 2>&1; then
    command -v timeout
  elif [ -x /opt/homebrew/bin/gtimeout ]; then
    printf '%s\n' /opt/homebrew/bin/gtimeout
  elif [ -x /opt/homebrew/bin/timeout ]; then
    printf '%s\n' /opt/homebrew/bin/timeout
  else
    printf '%s\n' ""
  fi
}

run_with_timeout() {
  local out_file="$1"
  local err_file="$2"
  shift 2

  local timeout_cmd
  timeout_cmd="$(timeout_bin)"
  if [ -n "$timeout_cmd" ]; then
    "$timeout_cmd" "$TIMEOUT_SECONDS" "$@" >"$out_file" 2>"$err_file"
  else
    "$@" >"$out_file" 2>"$err_file"
  fi
}

warn() {
  local message="$1"
  jq -Rn --arg v "$message" '$v' >>"$WARNINGS_FILE" 2>/dev/null || true
}

env_pct() {
  local name
  for name in "$@"; do
    eval "value=\${$name:-}"
    if [ -n "${value:-}" ]; then
      pct_or_null "$value"
      return 0
    fi
  done
  printf 'null\n'
}

env_pct_source() {
  local name
  for name in "$@"; do
    eval "value=\${$name:-}"
    if [ -n "${value:-}" ]; then
      printf 'env:%s\n' "$name"
      return 0
    fi
  done
  printf 'unknown\n'
}

collect_accounts() {
  if [ -n "${LEVERAGE_CEILING_ACCOUNTS_ACTIVE:-}" ]; then
    ACCOUNTS_ACTIVE="$(number_or_zero "$LEVERAGE_CEILING_ACCOUNTS_ACTIVE")"
    ACCOUNTS_SOURCE="env:LEVERAGE_CEILING_ACCOUNTS_ACTIVE"
    return 0
  fi

  local creds_file="$TMP_ROOT/credentials.txt"
  local timeout_cmd
  timeout_cmd="$(timeout_bin)"
  : >"$creds_file"

  if [ -n "$timeout_cmd" ]; then
    "$timeout_cmd" 5 find "$HOME/.claude" "$HOME/.codex" "$HOME/.config" "$HOME/Library/Application Support" \
      -name '.credentials.json' -path '*/claude*' -mtime -7 -print >"$creds_file" 2>/dev/null || true
  else
    find "$HOME/.claude" "$HOME/.codex" "$HOME/.config" \
      -name '.credentials.json' -path '*/claude*' -mtime -7 -print >"$creds_file" 2>/dev/null || true
  fi

  ACCOUNTS_ACTIVE="$(awk 'NF { c++ } END { print c + 0 }' "$creds_file")"
  ACCOUNTS_SOURCE="$(sed -n '1p' "$creds_file")"

  if [ "$ACCOUNTS_ACTIVE" -gt 0 ]; then
    [ -n "$ACCOUNTS_SOURCE" ] || ACCOUNTS_SOURCE="credentials_search"
    return 0
  fi

  ACCOUNTS_ACTIVE=0
  ACCOUNTS_SOURCE="unknown"
  if [ -n "${ANTHROPIC_API_KEY:-}" ] || [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
    ACCOUNTS_ACTIVE=1
    ACCOUNTS_SOURCE="env:anthropic_or_claude_token_present"
  else
    warn "accounts source unavailable: no recent Claude .credentials.json found in bounded search"
  fi
}

session_exists() {
  local session="$1"
  if [ ! -s "$SESSION_LIST_JSON" ]; then
    return 0
  fi
  jq -e --arg s "$session" '.sessions[]? | select(.name == $s)' "$SESSION_LIST_JSON" >/dev/null 2>&1
}

collect_workers() {
  local session out_file err_file active_sessions_found=0
  local pid_file pid status
  : >"$WORKERS_FILE"
  : >"$SESSION_LIST_JSON"
  pid_file="$TMP_ROOT/worker-pids.txt"
  : >"$pid_file"

  if [ -x "$NTM_BIN" ]; then
    run_with_timeout "$SESSION_LIST_JSON" "$TMP_ROOT/ntm-list.err" "$NTM_BIN" list --json || true
    jq -e . "$SESSION_LIST_JSON" >/dev/null 2>&1 || : >"$SESSION_LIST_JSON"
  else
    warn "ntm unavailable at $NTM_BIN"
  fi

  for session in $SESSION_LIST; do
    [ -n "$session" ] || continue
    if ! session_exists "$session"; then
      continue
    fi
    active_sessions_found=$((active_sessions_found + 1))
    out_file="$TMP_ROOT/robot-${session}.json"
    err_file="$TMP_ROOT/robot-${session}.err"
    if ! [ -x "$NTM_BIN" ]; then
      continue
    fi
    ( run_with_timeout "$out_file" "$err_file" "$NTM_BIN" "--robot-activity=$session" "--activity-type=$ACTIVITY_TYPE" ) &
    printf '%s %s\n' "$session" "$!" >>"$pid_file"
  done

  if [ "$active_sessions_found" -eq 0 ]; then
    warn "no target ntm sessions found from configured list"
  fi

  while read -r session pid; do
    [ -n "${session:-}" ] || continue
    wait "$pid"
    status=$?
    out_file="$TMP_ROOT/robot-${session}.json"
    if [ "$status" -eq 0 ] && jq -e . "$out_file" >/dev/null 2>&1; then
      jq -c --arg session "$session" '.agents[]? | {
        session:$session,
        pane:(.pane_idx // .pane),
        agent_type:(.agent_type // "unknown"),
        state:(.state // "UNKNOWN")
      }' "$out_file" >>"$WORKERS_FILE" 2>/dev/null || true
    else
      warn "worker pane source unavailable for session=$session"
    fi
  done <"$pid_file"
}

append_ledger() {
  local payload="$1"
  mkdir -p "$(dirname "$LEDGER")" 2>/dev/null || return 0
  printf '%s\n' "$payload" >>"$LEDGER" 2>/dev/null || true
}

build_payload() {
  collect_accounts
  collect_workers

  local anthropic_pct xai_pct anthropic_source
  anthropic_pct="$(env_pct \
    LEVERAGE_CEILING_ANTHROPIC_PCT \
    ANTHROPIC_TOKEN_BUDGET_REMAINING_PCT \
    TOKEN_BUDGET_REMAINING_PCT_ANTHROPIC \
    CAUT_ANTHROPIC_REMAINING_PCT)"
  xai_pct="$(env_pct \
    LEVERAGE_CEILING_XAI_PCT \
    XAI_TOKEN_BUDGET_REMAINING_PCT \
    GROK_TOKEN_BUDGET_REMAINING_PCT \
    TOKEN_BUDGET_REMAINING_PCT_XAI \
    CAUT_XAI_REMAINING_PCT)"
  anthropic_source="$(env_pct_source \
    LEVERAGE_CEILING_ANTHROPIC_PCT \
    ANTHROPIC_TOKEN_BUDGET_REMAINING_PCT \
    TOKEN_BUDGET_REMAINING_PCT_ANTHROPIC \
    CAUT_ANTHROPIC_REMAINING_PCT)"

  if [ "$anthropic_pct" = "null" ]; then
    warn "anthropic token budget unavailable"
  fi
  if [ "$xai_pct" = "null" ]; then
    warn "xai token budget unavailable"
  fi
  if [ "$anthropic_source" = "unknown" ]; then
    anthropic_source="unknown"
  fi

  local worker_counts warnings_json payload
  worker_counts="$(jq -s '{
    total:length,
    idle:map(select(.state == "WAITING")) | length,
    thinking:map(select(.state == "THINKING" or .state == "GENERATING")) | length,
    error:map(select(.state == "ERROR" or .state == "STALLED" or .state == "UNKNOWN")) | length
  }' "$WORKERS_FILE" 2>/dev/null || printf '{"total":0,"idle":0,"thinking":0,"error":0}')"
  warnings_json="$(jq -s '.' "$WARNINGS_FILE" 2>/dev/null || printf '[]')"

  payload="$(
    jq -nc \
      --arg version "$VERSION" \
      --arg ts "$(now_iso)" \
      --arg mode "$MODE" \
      --arg accounts_source "$ACCOUNTS_SOURCE" \
      --arg token_source_anthropic "$anthropic_source" \
      --argjson accounts_active "$(number_or_zero "$ACCOUNTS_ACTIVE")" \
      --argjson target_accounts "$(number_or_zero "$TARGET_ACCOUNTS")" \
      --argjson anthropic "$anthropic_pct" \
      --argjson xai "$xai_pct" \
      --argjson workers "$worker_counts" \
      --argjson warnings "$warnings_json" \
      '
      def round0: (. + 0.5 | floor);
      def round1: ((. * 10 + 0.5) | floor) / 10;
      def pct($n; $d): if $d > 0 then (($n * 100 / $d) | round1) else 0 end;
      def min2($a; $b): if $a < $b then $a else $b end;
      def min3($a; $b; $c): min2(min2($a; $b); $c);
      ($workers.total // 0) as $total
      | ($workers.idle // 0) as $idle
      | ($workers.thinking // 0) as $thinking
      | ($workers.error // 0) as $error
      | pct($idle; $total) as $idle_pct
      | pct($thinking; $total) as $thinking_pct
      | pct($error; $total) as $error_pct
      | (if $target_accounts > 0 then min2(1; ($accounts_active / $target_accounts)) else 1 end) as $accounts_norm
      | (if $total == 0 then 0 elif $idle_pct == 100 then 1 else ($thinking_pct / 100) end) as $machines_norm
      | (if $anthropic == null and $xai == null then 1
         elif $anthropic == null then ($xai / 100)
         elif $xai == null then ($anthropic / 100)
         else (min2($anthropic; $xai) / 100) end) as $tokens_norm
      | min3($accounts_norm; $machines_norm; $tokens_norm) as $min_norm
      | (if $min_norm >= 1 then "none"
         elif $accounts_norm <= $machines_norm and $accounts_norm <= $tokens_norm then "accounts"
         elif $machines_norm <= $tokens_norm then "machines"
         else "tokens" end) as $binding
      | {
          version:$version,
          ts:$ts,
          mode:$mode,
          accounts_active:$accounts_active,
          accounts_active_source:$accounts_source,
          worker_panes_total:$total,
          worker_panes_idle_pct:$idle_pct,
          worker_panes_thinking_pct:$thinking_pct,
          worker_panes_error_pct:$error_pct,
          token_budget_remaining_pct_anthropic:$anthropic,
          token_budget_remaining_pct_xai:$xai,
          token_budget_source_anthropic:$token_source_anthropic,
          leverage_ceiling_score:((1000 * $min_norm) | round0),
          binding_constraint:$binding,
          binding_evidence:(
            "accounts_norm=" + (($accounts_norm * 100 | round1) | tostring) + "% " +
            "machines_norm=" + (($machines_norm * 100 | round1) | tostring) + "% " +
            "tokens_norm=" + (($tokens_norm * 100 | round1) | tostring) + "%"
          ),
          warnings:$warnings,
          target_accounts:$target_accounts,
          worker_panes_working_count:$thinking,
          worker_panes_idle_count:$idle,
          worker_panes_error_count:$error,
          status:(if ($warnings | length) > 0 then "warn" else "ok" end),
          success:true
        }'
  )"

  append_ledger "$payload"
  printf '%s\n' "$payload"
}

main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --help|-h)
        usage
        exit 0
        ;;
      --json)
        shift
        ;;
      --doctor|--health)
        MODE="${1#--}"
        shift
        ;;
      --info)
        info_json
        exit 0
        ;;
      --schema)
        schema_json
        exit 0
        ;;
      --examples)
        examples
        exit 0
        ;;
      *)
        printf 'ERROR: unknown argument: %s\n' "$1" >&2
        usage >&2
        exit 2
        ;;
    esac
  done

  if ! command -v jq >/dev/null 2>&1; then
    printf '{"version":"%s","ts":"%s","success":false,"warnings":["jq unavailable"]}\n' "$VERSION" "$(now_iso)"
    exit 0
  fi

  TMP_ROOT="$(mktemp -d /tmp/leverage-ceiling-probe-XXXXXX)"
  WARNINGS_FILE="$TMP_ROOT/warnings.jsonl"
  WORKERS_FILE="$TMP_ROOT/workers.jsonl"
  SESSION_LIST_JSON="$TMP_ROOT/ntm-list.json"
  : >"$WARNINGS_FILE"
  : >"$WORKERS_FILE"
  trap 'rm -rf "$TMP_ROOT"' EXIT

  build_payload
}

main "$@"
