#!/usr/bin/env bash
# cost-telemetry-token-burn-probe.sh — smallest recurring measurement
# for value-gap dimension `cost-telemetry-token-burn`.
#
# Owns: bead flywheel-1rmp.5 (Step 4o value-gap-hunter dimension #4).
# Sibling: .flywheel/scripts/value-gap-probe.sh (parent paradigm-tier scan).
#
# What this measures (proxy-only — Anthropic API token usage data is not
# exposed via any flywheel substrate today):
#   - dispatches_observed   (last N hours, default 24)
#   - by_event              (dispatch_sent / l52_issues_to_beads / orchestrator_dispatched / ...)
#   - by_agent_type         (codex / claude / unknown)
#   - by_dispatch_status    (queued_for_send / sent / blocked / declined / ...)
#   - by_wave               (wave 1..N)
#   - retry_proxy           (count of repeated task_sha256 within window)
#   - retry_ratio           (retries / unique_task_sha256)
#   - declines              (rows where event mentions DECLINED or dispatch_status=declined)
#
# Step 4o anti-pattern guardrail: this script SURFACES the gap; it does
# NOT auto-create beads or dispatch fixes. The parent value-gap-probe.sh
# already enforces that contract (PARENT_BEAD=flywheel-1rmp). Any beads
# filed in response to this probe's output go through Joshua's hand.
#
# Stable exit codes: 0 ok | 1 domain | 64 usage
# Triad: doctor / info / schema; --json default for robot consumers.

set -uo pipefail

VERSION="cost-telemetry-token-burn-probe.v1"
SCRIPT_VERSION="2026-05-09.1"

DISPATCH_LOG="${COST_TELEMETRY_DISPATCH_LOG:-/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl}"
LEDGER="${COST_TELEMETRY_LEDGER:-$HOME/.local/state/flywheel/cost-telemetry-token-burn.jsonl}"
HOURS_BACK="${COST_TELEMETRY_HOURS:-24}"
JSON_OUT=0
MODE="run"
APPLY=0
DRY_RUN=0

usage() {
  cat <<'USAGE'
Usage:
  cost-telemetry-token-burn-probe.sh [--apply|--dry-run] [--hours N] [--json]
  cost-telemetry-token-burn-probe.sh --doctor [--json]
  cost-telemetry-token-burn-probe.sh --info [--json]
  cost-telemetry-token-burn-probe.sh --schema [--json]
  cost-telemetry-token-burn-probe.sh --help

Smallest recurring measurement for the value-gap-hunter dimension
"cost-telemetry-token-burn" (Meadows #8 information flow). Proxy
metrics from dispatch-log.jsonl; explicit no-surface receipt for
first-party Anthropic token telemetry.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --dry-run) DRY_RUN=1; APPLY=0; shift ;;
    --hours) HOURS_BACK="${2:?}"; shift 2 ;;
    --hours=*) HOURS_BACK="${1#*=}"; shift ;;
    --dispatch-log) DISPATCH_LOG="${2:?}"; shift 2 ;;
    --dispatch-log=*) DISPATCH_LOG="${1#*=}"; shift ;;
    --ledger) LEDGER="${2:?}"; shift 2 ;;
    --ledger=*) LEDGER="${1#*=}"; shift ;;
    --doctor) MODE="doctor"; shift ;;
    --info) MODE="info"; shift ;;
    --schema) MODE="schema"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "cost-telemetry-token-burn-probe.sh: unknown arg: $1" >&2; usage >&2; exit 64 ;;
  esac
done

if [[ $MODE == "run" && $APPLY -eq 0 && $DRY_RUN -eq 0 ]]; then
  DRY_RUN=1
fi

emit() {
  if [[ $JSON_OUT -eq 1 || $MODE == "info" || $MODE == "schema" || $MODE == "doctor" ]]; then
    printf '%s\n' "$1"
  fi
}

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }
since_iso() { date -u -v "-${HOURS_BACK}H" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
                || date -u -d "-${HOURS_BACK} hours" +%Y-%m-%dT%H:%M:%SZ; }

info_payload() {
  jq -nc \
    --arg version "$VERSION" \
    --arg script_version "$SCRIPT_VERSION" \
    --arg dispatch_log "$DISPATCH_LOG" \
    --arg ledger "$LEDGER" \
    --argjson hours "$HOURS_BACK" \
    '{
      version: $version,
      script_version: $script_version,
      schema_version: "cost-telemetry-token-burn/v1",
      mode: "info",
      dispatch_log: $dispatch_log,
      ledger: $ledger,
      hours_back_default: $hours,
      modes: ["run","doctor","info","schema"],
      owns: "flywheel-1rmp.5",
      parent: "flywheel-1rmp",
      value_gap_dimension: "cost-telemetry-token-burn",
      meadows_tier: "#8 information flow",
      first_party_token_telemetry: "no_surface_yet",
      first_party_no_surface_reason: "Anthropic / xAI / OpenAI billing data is not exposed via flywheel substrate; the smallest recurring measurement is proxy-only against dispatch-log.jsonl until a billing API surface is wired.",
      step_4o_anti_pattern_guardrail: "this probe surfaces; it does NOT auto-dispatch fixes",
      status: "ok"
    }'
}

schema_payload() {
  jq -nc '{
    schema_version: "cost-telemetry-token-burn/v1",
    ledger_row_required_fields: [
      "schema_version","ts","window_start","window_end","hours_back",
      "dispatches_observed","unique_task_sha256","retry_proxy",
      "retry_ratio","declines","by_event","by_agent_type",
      "by_dispatch_status","by_wave","by_pane",
      "actual_token_burn","actual_token_burn_no_surface_reason"
    ],
    proxy_metrics: [
      {"name":"dispatches_observed","describes":"raw dispatch row count"},
      {"name":"retry_proxy","describes":"count of repeated task_sha256 within window"},
      {"name":"retry_ratio","describes":"retries / unique_task_sha256 (0..1)"},
      {"name":"declines","describes":"rows mentioning DECLINED disposition or dispatch_status=declined"}
    ],
    actual_token_burn: {
      type: "string",
      enum: ["no_surface_yet","computed","partial"],
      no_surface_explanation: "Anthropic billing API not wired; first-party LLM token data not flowing into flywheel substrate today"
    },
    surfaced_via: ["ledger:~/.local/state/flywheel/cost-telemetry-token-burn.jsonl","cli:cost-telemetry-token-burn-probe.sh","value-gap-probe parent ledger"],
    exit_codes: {"0":"ok","1":"domain","64":"usage"},
    mode: "schema",
    status: "ok"
  }'
}

doctor_payload() {
  local issues=()
  command -v jq >/dev/null 2>&1 || issues+=("jq_missing")
  [[ -f "$DISPATCH_LOG" ]] || issues+=("dispatch_log_missing=$DISPATCH_LOG")
  mkdir -p "$(dirname "$LEDGER")" 2>/dev/null
  [[ -w "$(dirname "$LEDGER")" ]] || issues+=("ledger_dir_not_writable=$(dirname "$LEDGER")")
  local issues_json
  if [[ ${#issues[@]} -gt 0 ]]; then
    issues_json=$(printf '%s\n' "${issues[@]}" | jq -R . | jq -s .)
  else
    issues_json='[]'
  fi
  jq -nc \
    --arg version "$VERSION" \
    --argjson issues "$issues_json" \
    '{
      version: $version,
      schema_version: "cost-telemetry-token-burn/v1",
      mode: "doctor",
      issues: $issues,
      status: (if ($issues|length)==0 then "ok" else "degraded" end)
    }'
}

# --- core measurement ---------------------------------------------------------
run_pass() {
  local mode_label="$1"   # apply | dry-run
  local window_start window_end
  window_start="$(since_iso)"
  window_end="$(now_iso)"

  if [[ ! -f "$DISPATCH_LOG" ]]; then
    emit "$(jq -nc \
      --arg ts "$(now_iso)" \
      --arg log "$DISPATCH_LOG" \
      '{status:"fail",error:"dispatch_log_missing",dispatch_log:$log}')"
    return 1
  fi

  # Filter rows to window via jq
  local payload
  payload=$(awk -v start="$window_start" '
    {
      n = index($0, "\"ts\":\"")
      if (n == 0) next
      tail = substr($0, n+6)
      m = index(tail, "\"")
      if (m == 0) next
      ts = substr(tail, 1, m-1)
      if (ts >= start) print
    }
  ' "$DISPATCH_LOG" | jq -sc '
    def get(k): map(.[k] // "unknown");
    def counts: reduce .[] as $x ({}; .[$x] += 1);
    {
      dispatches_observed: length,
      unique_task_sha256: ([.[] | .task_sha256 // empty] | unique | length),
      retry_proxy: (length - ([.[] | .task_sha256 // empty] | unique | length)),
      declines: ([.[] | select((.dispatch_status // "") == "declined" or (.event // "" | test("DECLINED"; "i")))] | length),
      by_event: ([.[] | .event // "unknown"] | counts),
      by_agent_type: ([.[] | .agent_type // "unknown"] | counts),
      by_dispatch_status: ([.[] | .dispatch_status // "unknown"] | counts),
      by_wave: ([.[] | (.wave // "unknown" | tostring)] | counts),
      by_pane: ([.[] | (.pane // "unknown" | tostring)] | counts)
    }
    | . + {
        retry_ratio: (if .unique_task_sha256 > 0 then (.retry_proxy / .unique_task_sha256) else 0 end)
      }
  ')

  local row
  row=$(jq -nc \
    --arg ts "$(now_iso)" \
    --arg ws "$window_start" \
    --arg we "$window_end" \
    --argjson hours "$HOURS_BACK" \
    --argjson p "$payload" \
    '{
      schema_version: "cost-telemetry-token-burn/v1",
      ts: $ts,
      window_start: $ws,
      window_end: $we,
      hours_back: $hours,
      dispatches_observed: $p.dispatches_observed,
      unique_task_sha256: $p.unique_task_sha256,
      retry_proxy: $p.retry_proxy,
      retry_ratio: $p.retry_ratio,
      declines: $p.declines,
      by_event: $p.by_event,
      by_agent_type: $p.by_agent_type,
      by_dispatch_status: $p.by_dispatch_status,
      by_wave: $p.by_wave,
      by_pane: $p.by_pane,
      actual_token_burn: "no_surface_yet",
      actual_token_burn_no_surface_reason: "Anthropic / xAI / OpenAI billing API is not wired into flywheel substrate; smallest recurring measurement is proxy-only against dispatch-log.jsonl until a first-party telemetry surface is filed as a separate value-gap follow-up bead."
    }')

  if [[ "$mode_label" == "apply" ]]; then
    mkdir -p "$(dirname "$LEDGER")" 2>/dev/null
    printf '%s\n' "$row" >> "$LEDGER" 2>/dev/null
  fi

  emit "$(printf '%s' "$row" | jq -c \
    --arg mode "$mode_label" \
    --arg ledger "$LEDGER" \
    '{mode:$mode,ledger:$ledger} + .')"
  return 0
}

case "$MODE" in
  info)   emit "$(info_payload)"; exit 0 ;;
  schema) emit "$(schema_payload)"; exit 0 ;;
  doctor)
    payload="$(doctor_payload)"
    emit "$payload"
    [[ "$(printf '%s' "$payload" | jq -r .status)" == "ok" ]] && exit 0 || exit 1
    ;;
esac

if [[ $DRY_RUN -eq 1 ]]; then
  run_pass dry-run
  exit $?
fi
run_pass apply
exit $?
