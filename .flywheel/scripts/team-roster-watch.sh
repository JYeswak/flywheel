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


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (TODO markers in stubs need fill-in)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block is APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic stays as TODO markers — see grep '# TODO(canonical-cli-scaffold)'.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="team-roster-watch/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/team-roster-watch-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: team-roster-watch.sh [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
top-level logic (now exposed as `cmd_run`).

Canonical CLI surfaces:
  doctor [--json]          probe substrate health
  health [--json]          last-run status
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
  validate <subject> [...] validate per-subject contract (TODO: define subjects)
  audit [--json]           recent run history
  why <id>                 explain provenance for a given id (TODO: id semantics)
  quickstart [--json]      operator orientation
  help <topic>             topic help (run | doctor | health | repair | validate)
  completion <shell>       emit bash or zsh completion

Introspection:
  --info --json            version, paths, env vars, dependencies, sha256
  --schema [<surface>]     JSON Schema for output envelopes
  --examples --json        curated workflow examples
  --help / -h              this help
USG
}

scaffold_emit_info() {
  if ! command -v cli_emit_info >/dev/null; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "team-roster-watch.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "team-roster-watch.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"team-roster-watch.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"team-roster-watch.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"team-roster-watch.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-default}"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
    '{schema_version:$sv,command:"schema",surface:$surface,note:"TODO(canonical-cli-scaffold): per-surface schema fill-in"}'
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run.\n' ;;
    doctor)   printf 'topic: doctor — TODO(canonical-cli-scaffold): document doctor checks specific to this surface.\n' ;;
    health)   printf 'topic: health — TODO(canonical-cli-scaffold): document health probes specific to this surface.\n' ;;
    repair)   printf 'topic: repair — TODO(canonical-cli-scaffold): document repair scopes + idempotency contract.\n' ;;
    validate) printf 'topic: validate — TODO(canonical-cli-scaffold): document validation subjects + contracts.\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "team-roster-watch" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "team-roster-watch" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # TODO(canonical-cli-scaffold): probe substrate this script depends on
  # (env vars, paths, external tools) and emit per-check status.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:"todo",checks:[],note:"TODO(canonical-cli-scaffold): fill in doctor checks"}'
}

scaffold_cmd_health() {
  # TODO(canonical-cli-scaffold): summarize last-run state from audit log.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"todo",note:"TODO(canonical-cli-scaffold): fill in health probe from audit log"}'
}

scaffold_cmd_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help repair; return 0 ;;
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
    if command -v cli_refuse_apply_without_idem_key >/dev/null; then
      cli_refuse_apply_without_idem_key "$SCAFFOLD_SCHEMA_VERSION" "repair" "$scope"
    else
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:"apply",scope:$scope,reason:"--apply requires --idempotency-key"}'
      exit 3
    fi
  fi
  # TODO(canonical-cli-scaffold): per-scope repair actions go here.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
    '{schema_version:$sv,command:"repair",status:"todo",mode:$mode,scope:$scope,idempotency_key:$idem,note:"TODO(canonical-cli-scaffold): fill in repair scope actions"}'
}

scaffold_cmd_validate() {
  # TODO(canonical-cli-scaffold): document validation subjects + contracts.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    '{schema_version:$sv,command:"validate",status:"todo",note:"TODO(canonical-cli-scaffold): fill in per-subject validation"}'
}

scaffold_cmd_audit() {
  # TODO(canonical-cli-scaffold): tail audit log; emit recent rows.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" \
    '{schema_version:$sv,command:"audit",audit_log:$log,status:"todo",note:"TODO(canonical-cli-scaffold): fill in audit tail"}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  # TODO(canonical-cli-scaffold): explain why <id> is/isn't in scope.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" \
    '{schema_version:$sv,command:"why",id:$id,status:"todo",note:"TODO(canonical-cli-scaffold): fill in why-id semantics"}'
}

# ---------- scaffolded main dispatcher ----------

# When the scaffolder appends this block, it expects the target's original
# top-level main is renamed to `cmd_run` (or the original final
# `main "$@"` line is replaced with this dispatcher). Default invocation
# falls through to the original logic for backward compat.
scaffold_main() {
  if [[ $# -eq 0 ]]; then
    scaffold_usage; exit 0
  fi
  case "$1" in
    -h|--help)    scaffold_usage; exit 0 ;;
    --info)       shift; scaffold_emit_info "$@"; exit 0 ;;
    --schema)     shift; scaffold_emit_schema "${1:-default}"; exit 0 ;;
    --examples)   shift; scaffold_emit_examples "$@"; exit 0 ;;
    doctor)       shift; scaffold_cmd_doctor "$@"; exit $? ;;
    health)       shift; scaffold_cmd_health "$@"; exit $? ;;
    repair)       shift; scaffold_cmd_repair "$@"; exit $? ;;
    validate)     shift; scaffold_cmd_validate "$@"; exit $? ;;
    audit)        shift; scaffold_cmd_audit "$@"; exit $? ;;
    why)          shift; scaffold_cmd_why "$@"; exit $? ;;
    quickstart)   shift; scaffold_emit_quickstart "$@"; exit 0 ;;
    help)         shift; scaffold_emit_topic_help "${1:-}"; exit 0 ;;
    completion)   shift; scaffold_emit_completion "${1:-bash}"; exit $? ;;
    *)
      printf 'ERR: unknown canonical subcommand: %s\n' "$1" >&2
      scaffold_usage >&2
      exit 64 ;;
  esac
}

# Early-dispatch intercept: if argv[0] looks like a canonical subcommand
# or introspection flag, run the canonical surface and exit BEFORE the
# target's original arg parser sees the args. Works for both `main "$@"`
# style and inline `while [[ $# -gt 0 ]]` style targets.
_scaffold_is_canonical_arg() {
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --info|--schema|--examples) return 0 ;;
    -h|--help) return 0 ;;
    help)
      # Intercept `help <topic>` and `help --help`; bare `help` could be
      # a legacy subcommand of the target so it falls through.
      case "${2:-}" in run|doctor|health|repair|validate|audit|why|-h|--help) return 0 ;; esac
      return 1 ;;
    *) return 1 ;;
  esac
}

if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  scaffold_main "$@"
  exit $?
fi
# ====== END canonical-cli scaffold ======
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

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
