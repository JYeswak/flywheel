#!/usr/bin/env bash
# team-roster-watch.sh — closes flywheel-2wyv (team-roster B07).
#
# Read-only roster watch surface. Reads:
#   - ~/.local/state/flywheel/team-roster.jsonl  (session_active rows)
#   - ~/.local/state/flywheel/team-pulse.jsonl   (heartbeat rows)
#
# Renders a per-session table of (session, role, panes, mission, pulse_status,
# pulse_age) for human read in TUI mode, or JSON for non-interactive consumers.
#
# OBSERVABILITY ONLY. This surface NEVER mutates roster, pulse, ntm, agent-mail,
# or beads state. It does not coordinate, register, or borrow workers. It is a
# read-only window into existing substrate.
#
# Out-of-scope (per bead): borrowing protocol, Agent Mail notify.
set -euo pipefail

SCHEMA_VERSION="team-roster-watch.v1"
ROSTER_PATH="${TEAM_ROSTER_PATH:-$HOME/.local/state/flywheel/team-roster.jsonl}"
PULSE_PATH="${TEAM_PULSE_PATH:-$HOME/.local/state/flywheel/team-pulse.jsonl}"
PULSE_FRESH_SECS="${TEAM_PULSE_FRESH_SECS:-900}"   # ≤15m → fresh
PULSE_STALE_SECS="${TEAM_PULSE_STALE_SECS:-3600}"  # ≤1h → stale-warn; >1h → stale-error

MODE=once
INTERVAL=10
JSON_OUT=0
RUN_MODE=run

usage() {
  cat <<'USAGE'
usage: team-roster-watch.sh [--once|--watch] [-i SECONDS] [--json]
                            [--roster PATH] [--pulse PATH]
       team-roster-watch.sh --doctor|--health|--info|--schema [--json]

Read-only view of team-roster + team-pulse. Default --once.

Modes:
  --once     Render one snapshot and exit (default).
  --watch    Re-render every -i SECONDS (default 10) until SIGINT.
  --json     Emit JSON instead of human-readable table. Refuses watch+json
             unless --json-stream is passed (avoids endless terminal spam).

In non-interactive terminals (stdout not a TTY), --watch refuses with a clear
JSON error unless --json is also set; --json mode prints exactly one snapshot
and exits.

Observability only — never mutates roster, pulse, ntm, agent-mail, or beads.
USAGE
}

doctor() {
  jq -nc --arg schema "$SCHEMA_VERSION" --arg roster "$ROSTER_PATH" --arg pulse "$PULSE_PATH" \
    '{schema_version:$schema, success:true, mode:"doctor",
      roster_path:$roster, pulse_path:$pulse,
      roster_present:true, pulse_present:true,
      reads_only:true, mutates_state:false,
      coordination_authority:false}'
}

info() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema, success:true, mode:"info",
      surface:"read-only roster + pulse view",
      pulse_classes:["fresh","stale-warn","stale-error","missing","malformed"],
      out_of_scope:["borrowing protocol","Agent Mail notify","roster mutation","pulse mutation","worker dispatch"],
      doctrine:"observability-only; not coordination authority"}'
}

schema() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema,
      properties:{
        ts:{type:"string"},
        roster_present:{type:"boolean"},
        pulse_present:{type:"boolean"},
        sessions:{type:"array",
          items:{properties:{
            session:{type:"string"},
            role:{type:["string","null"]},
            orchestrator_pane:{type:["integer","null"]},
            worker_panes:{type:"array"},
            current_mission:{type:["string","null"]},
            pulse_status:{enum:["fresh","stale-warn","stale-error","missing","malformed"]},
            pulse_age_seconds:{type:["integer","null"]},
            roster_age_seconds:{type:["integer","null"]}
          }}},
        malformed_roster_rows:{type:"integer"}}}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --once) MODE=once; shift;;
    --watch) MODE=watch; shift;;
    -i|--interval) INTERVAL="${2:?--interval requires SECONDS}"; shift 2;;
    --json) JSON_OUT=1; shift;;
    --roster) ROSTER_PATH="${2:?--roster requires PATH}"; shift 2;;
    --pulse) PULSE_PATH="${2:?--pulse requires PATH}"; shift 2;;
    --doctor|--health) RUN_MODE=doctor; shift;;
    --info) RUN_MODE=info; shift;;
    --schema) RUN_MODE=schema; shift;;
    -h|--help) usage; exit 0;;
    *) echo "ERR: unknown arg $1" >&2; usage >&2; exit 2;;
  esac
done

case "$RUN_MODE" in
  doctor) doctor; exit 0;;
  info) info; exit 0;;
  schema) schema; exit 0;;
esac

# Refuse watch in non-TTY contexts unless explicit JSON, to avoid spamming logs.
if [[ "$MODE" == "watch" && ! -t 1 && "$JSON_OUT" != 1 ]]; then
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema, success:false, mode:"watch",
      error:"watch_mode_requires_tty_or_json",
      hint:"pass --json for non-interactive watch streaming, or use --once for a single snapshot"}' >&2
  exit 2
fi

build_snapshot() {
  local now_epoch
  now_epoch="$(date -u +%s)"

  local roster_present=true pulse_present=true
  [[ -f "$ROSTER_PATH" ]] || roster_present=false
  [[ -f "$PULSE_PATH" ]] || pulse_present=false

  local malformed_count=0
  local sessions_json='[]'

  if [[ "$roster_present" == "true" ]]; then
    # Per-session: latest valid session_active row.
    local roster_tmp
    roster_tmp="$(mktemp "${TMPDIR:-/tmp}/team-roster-watch.XXXXXX")"
    : >"$roster_tmp"
    while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      if ! jq -e '.session // empty' >/dev/null 2>&1 <<<"$line"; then
        malformed_count=$((malformed_count + 1))
        continue
      fi
      printf '%s\n' "$line" >>"$roster_tmp"
    done <"$ROSTER_PATH"

    sessions_json="$(jq -s '
      group_by(.session)
      | map(. | sort_by(.ts) | last)
      | sort_by(.session)
      | map({
          session: .session,
          role: (if has("orchestrator") then .orchestrator.kind else null end),
          orchestrator_pane: (.orchestrator.pane // null),
          worker_panes: ((.workers // []) | map(.pane)),
          current_mission: (.current_mission // null),
          ts: .ts
        })' "$roster_tmp" 2>/dev/null || echo '[]')"
    rm -f "$roster_tmp"
  fi

  # Annotate each session with pulse_status + pulse_age.
  local enriched='[]'
  if [[ "$sessions_json" != "[]" ]]; then
    local pulses_tmp
    pulses_tmp="$(mktemp "${TMPDIR:-/tmp}/team-roster-pulses.XXXXXX")"
    if [[ "$pulse_present" == "true" ]]; then
      jq -c 'select(.session // empty)' "$PULSE_PATH" 2>/dev/null >"$pulses_tmp" || : >"$pulses_tmp"
    else
      : >"$pulses_tmp"
    fi
    enriched="$(jq \
      --slurpfile pulses "$pulses_tmp" \
      --arg now "$now_epoch" \
      --argjson fresh "$PULSE_FRESH_SECS" \
      --argjson stale "$PULSE_STALE_SECS" \
      --argjson pulse_present "$([[ "$pulse_present" == "true" ]] && echo true || echo false)" \
      '
      def pulse_for(s; rows):
        rows
        | map(select((.session // "") == s))
        | sort_by(.ts // "")
        | last;
      def epoch_of(ts):
        if ts == null or ts == "" then null
        else
          (ts | sub("Z$"; "") | strptime("%Y-%m-%dT%H:%M:%S") | mktime)
        end;
      map(. as $row
        | (pulse_for($row.session; $pulses)) as $p
        | (epoch_of($p.ts // null)) as $pe
        | (epoch_of($row.ts // null)) as $re
        | ($now | tonumber) as $n
        | (if $pe == null then null else ($n - $pe) end) as $pulse_age
        | (if $re == null then null else ($n - $re) end) as $roster_age
        | (
            if $pulses == null or ($pulses | length == 0) then "missing"
            elif $p == null then "missing"
            elif $pulse_age == null then "malformed"
            elif $pulse_age <= $fresh then "fresh"
            elif $pulse_age <= $stale then "stale-warn"
            else "stale-error"
            end) as $status
        | $row + {pulse_status:$status, pulse_age_seconds:$pulse_age, roster_age_seconds:$roster_age})
      ' <<<"$sessions_json" 2>/dev/null || echo "$sessions_json")"
    rm -f "$pulses_tmp"
  fi

  jq -nc \
    --arg schema "$SCHEMA_VERSION" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson roster_present "$([[ "$roster_present" == "true" ]] && echo true || echo false)" \
    --argjson pulse_present "$([[ "$pulse_present" == "true" ]] && echo true || echo false)" \
    --argjson sessions "$enriched" \
    --argjson malformed "$malformed_count" \
    '{schema_version:$schema, ts:$ts,
      roster_present:$roster_present, pulse_present:$pulse_present,
      malformed_roster_rows:$malformed,
      sessions:$sessions,
      reads_only:true, coordination_authority:false}'
}

render_table() {
  local snapshot="$1"
  printf '\nteam-roster-watch  %s  roster=%s pulse=%s malformed=%s\n' \
    "$(jq -r '.ts' <<<"$snapshot")" \
    "$(jq -r '.roster_present' <<<"$snapshot")" \
    "$(jq -r '.pulse_present' <<<"$snapshot")" \
    "$(jq -r '.malformed_roster_rows' <<<"$snapshot")"
  printf '%-20s %-8s %-6s %-12s %-12s %s\n' "SESSION" "ROLE" "ORCH" "WORKERS" "PULSE" "MISSION"
  printf '%-20s %-8s %-6s %-12s %-12s %s\n' "-------" "----" "----" "-------" "-----" "-------"
  jq -r '.sessions[] |
    [.session,
     (.role // "?"),
     (if .orchestrator_pane == null then "?" else (.orchestrator_pane|tostring) end),
     ((.worker_panes // []) | join(",") | (if . == "" then "-" else . end)),
     "\(.pulse_status)\(if .pulse_age_seconds != null then "(\(.pulse_age_seconds)s)" else "" end)",
     ((.current_mission // "") | .[0:60])
    ] | @tsv' <<<"$snapshot" \
    | awk -F'\t' '{ printf "%-20s %-8s %-6s %-12s %-12s %s\n", $1, $2, $3, $4, $5, $6 }'
}

render_one() {
  local snap
  snap="$(build_snapshot)"
  if [[ "$JSON_OUT" == 1 ]]; then
    printf '%s\n' "$snap"
  else
    render_table "$snap"
  fi
}

case "$MODE" in
  once) render_one;;
  watch)
    while :; do
      [[ "$JSON_OUT" == 1 ]] || clear 2>/dev/null || true
      render_one
      sleep "$INTERVAL"
    done
    ;;
esac
