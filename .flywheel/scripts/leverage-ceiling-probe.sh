#!/usr/bin/env bash
set -euo pipefail

VERSION="leverage-ceiling-probe.v1"
LEDGER="${LEVERAGE_CEILING_LEDGER:-$HOME/.local/state/flywheel/leverage-ceiling.jsonl}"
NTM_BIN="${LEVERAGE_CEILING_NTM_BIN:-/Users/josh/.local/bin/ntm}"
JSONL_APPEND_LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"
TARGET_ACCOUNTS="${LEVERAGE_CEILING_TARGET_ACCOUNTS:-2}"
SESSIONS="${LEVERAGE_CEILING_SESSIONS:-flywheel mobile-eats skillos picoz alps alpsinsurance}"

usage() {
  cat <<'USAGE'
usage: leverage-ceiling-probe.sh [--json|--doctor|--info|--schema|--examples]

Thin flywheel economics probe backed by native ntm activity/summary surfaces.
USAGE
}

emit_info() {
  jq -nc --arg version "$VERSION" '{
    version:$version,
    native_surfaces:["ntm activity --json","ntm summary --json"],
    retained_policy:"flywheel leverage ceiling scoring",
    read_only:true,
    ledger_jsonl:true
  }'
}

emit_schema() {
  jq -nc '{fields:["version","success","status","leverage_ceiling_score","binding_constraint","binding_evidence","warnings","accounts_active","worker_panes_total","worker_panes_working_count","native_activity_sessions","native_summary_sessions"]}'
}

emit_examples() {
  cat <<'EXAMPLES'
LEVERAGE_CEILING_SESSIONS=flywheel leverage-ceiling-probe.sh --json
LEVERAGE_CEILING_ACCOUNTS_ACTIVE=2 LEVERAGE_CEILING_ANTHROPIC_PCT=80 LEVERAGE_CEILING_XAI_PCT=90 leverage-ceiling-probe.sh --json
EXAMPLES
}

json_source() {
  [[ -f "$JSONL_APPEND_LIB" ]] && source "$JSONL_APPEND_LIB" || true
}

numeric_env() {
  local value
  for value in "$@"; do
    [[ -n "${value:-}" ]] && [[ "$value" =~ ^[0-9]+([.][0-9]+)?$ ]] && { printf '%s\n' "$value"; return 0; }
  done
  return 1
}

clamp_pct() {
  awk -v v="${1:-}" 'BEGIN { if (v == "") print ""; else if (v < 0) print 0; else if (v > 100) print 100; else print v }'
}

detect_accounts() {
  if [[ -n "${LEVERAGE_CEILING_ACCOUNTS_ACTIVE:-}" ]]; then
    printf '%s\n' "$LEVERAGE_CEILING_ACCOUNTS_ACTIVE"
  elif [[ -n "${ANTHROPIC_API_KEY:-}" || -n "${XAI_API_KEY:-}" || -n "${OPENAI_API_KEY:-}" ]]; then
    printf '1\n'
  else
    printf '0\n'
  fi
}

ntm_activity() {
  local session="$1"
  "$NTM_BIN" activity "$session" --json 2>/dev/null ||
    "$NTM_BIN" "--robot-activity=$session" "--activity-type=codex,claude" 2>/dev/null ||
    jq -nc '{agents:[]}'
}

ntm_summary() {
  local session="$1"
  "$NTM_BIN" summary "$session" --json 2>/dev/null ||
    "$NTM_BIN" summary "$session" --format json 2>/dev/null ||
    jq -nc '{}'
}

append_payload() {
  local payload="$1"
  mkdir -p "$(dirname "$LEDGER")" 2>/dev/null || true
  if declare -F fw_jsonl_append_validated >/dev/null 2>&1; then
    fw_jsonl_append_validated "$LEDGER" "$payload" 2>/dev/null ||
      printf 'WARN: leverage-ceiling ledger append failed path=%s\n' "$LEDGER" >&2
  elif ! printf '%s\n' "$payload" >>"$LEDGER" 2>/dev/null; then
    printf 'WARN: leverage-ceiling ledger append failed path=%s\n' "$LEDGER" >&2
  fi
}

run_probe() {
  json_source
  local tmp accounts_active anthropic_pct xai_pct token_floor
  tmp="$(mktemp)"
  accounts_active="$(detect_accounts)"
  anthropic_pct="$(clamp_pct "$(numeric_env "${LEVERAGE_CEILING_ANTHROPIC_PCT:-}" "${ANTHROPIC_TOKEN_BUDGET_REMAINING_PCT:-}" "${TOKEN_BUDGET_REMAINING_PCT_ANTHROPIC:-}" "${CAUT_ANTHROPIC_REMAINING_PCT:-}" || true)")"
  xai_pct="$(clamp_pct "$(numeric_env "${LEVERAGE_CEILING_XAI_PCT:-}" "${XAI_TOKEN_BUDGET_REMAINING_PCT:-}" "${TOKEN_BUDGET_REMAINING_PCT_XAI:-}" "${CAUT_XAI_REMAINING_PCT:-}" || true)")"

  local session activity summary summaries=0
  for session in $SESSIONS; do
    activity="$(ntm_activity "$session")"
    summary="$(ntm_summary "$session")"
    jq -c --arg session "$session" '.agents[]? | {session:$session,state:(.state // .status // "UNKNOWN")}' <<<"$activity" >>"$tmp" || true
    jq -e 'type=="object" and length > 0' >/dev/null 2>&1 <<<"$summary" && summaries=$((summaries + 1))
  done

  local worker_json payload
  worker_json="$(jq -sc '.' "$tmp")"
  token_floor="$(jq -nc --arg a "$anthropic_pct" --arg x "$xai_pct" '[($a|select(length>0)|tonumber),($x|select(length>0)|tonumber)] | if length == 0 then 100 else min end')"

  payload="$(
    jq -ncS \
      --arg version "$VERSION" \
      --argjson accounts "$accounts_active" \
      --argjson target "$TARGET_ACCOUNTS" \
      --argjson workers "$worker_json" \
      --argjson token_floor "$token_floor" \
      --arg anthropic_pct "$anthropic_pct" \
      --arg xai_pct "$xai_pct" \
      --argjson summaries "$summaries" '
        def count_states($names): [$workers[].state | ascii_upcase | select(IN($names[]))] | length;
        def min3($a;$b;$c): [$a,$b,$c] | min;
        ($workers|length) as $total |
        count_states(["THINKING","GENERATING","WORKING","BUSY"]) as $working |
        count_states(["WAITING","IDLE","READY"]) as $idle |
        count_states(["ERROR","FAILED","STALLED","DEAD"]) as $error |
        (if $target <= 0 then 1 else ([1, ($accounts / $target)] | min) end) as $accounts_norm |
        (if $total == 0 then 0 elif (($idle * 100 / $total) == 100) then 1 else ($working / $total) end) as $machines_norm |
        ($token_floor / 100) as $tokens_norm |
        min3($accounts_norm;$machines_norm;$tokens_norm) as $ceiling |
        ([
          {name:"accounts", value:$accounts_norm},
          {name:"machines", value:$machines_norm},
          {name:"tokens", value:$tokens_norm}
        ] | min_by(.value).name) as $binding |
        {
          version:$version,
          success:true,
          status:(if $ceiling >= 0.75 then "ok" elif $ceiling >= 0.5 then "warn" else "critical" end),
          leverage_ceiling_score:($ceiling * 1000 | round),
          binding_constraint:$binding,
          binding_evidence:{
            accounts_norm:$accounts_norm,
            machines_norm:$machines_norm,
            tokens_norm:$tokens_norm,
            anthropic_pct:(if $anthropic_pct == "" then null else ($anthropic_pct|tonumber) end),
            xai_pct:(if $xai_pct == "" then null else ($xai_pct|tonumber) end)
          },
          warnings:(if $accounts == 0 then ["no_active_account_detected"] else [] end),
          accounts_active:$accounts,
          worker_panes_total:$total,
          worker_panes_working_count:$working,
          worker_panes_idle_count:$idle,
          worker_panes_error_count:$error,
          native_activity_sessions:($workers | map(.session) | unique),
          native_summary_sessions:$summaries,
          observed_at:(now | todateiso8601)
        }'
  )"
  append_payload "$payload"
  printf '%s\n' "$payload"
}

mode="${1:---json}"
case "$mode" in
  --json|"") run_probe ;;
  --doctor|--health) run_probe | jq -e '.success == true' >/dev/null && printf 'ok\n' ;;
  --info) emit_info ;;
  --schema) emit_schema ;;
  --examples) emit_examples ;;
  --help|-h) usage ;;
  *) usage >&2; exit 2 ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
