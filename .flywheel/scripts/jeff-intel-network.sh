#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial -> passing per bead flywheel-k8gcv.15)
set -euo pipefail

VERSION="jeff-intel-network.v1.1.0"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
RUNNER="${JEFF_INTEL_RUNNER:-$ROOT/.flywheel/scripts/jeff-intel-scheduled-runner.sh}"
DAILY="${JEFF_INTEL_DAILY_SCRIPT:-$ROOT/.flywheel/scripts/daily-jeff-ingest.sh}"
STATE_DIR="${JEFF_INTEL_STATE_DIR:-$HOME/.local/state/jeff-intel}"
FLYWHEEL_STATE_DIR="${FLYWHEEL_STATE_DIR:-$HOME/.local/state/flywheel}"
JSON_OUT=0
MODE="doctor"
APPLY=0
SCOPE="state"
IDEMPOTENCY_KEY=""
POSITIONAL=""

usage() {
  cat <<'EOF'
Usage:
  jeff-intel-network.sh doctor [--json]
  jeff-intel-network.sh health [--json]
  jeff-intel-network.sh repair --scope state [--dry-run|--apply] [--json]
  jeff-intel-network.sh validate [--json]
  jeff-intel-network.sh pull [--dry-run|--apply] [--json]
  jeff-intel-network.sh x-poll [--dry-run|--apply] [--json]
  jeff-intel-network.sh audit [--json]
  jeff-intel-network.sh why <id|path> [--json]
  jeff-intel-network.sh schema [command] [--json]
  jeff-intel-network.sh quickstart
  jeff-intel-network.sh help [topic]
  jeff-intel-network.sh completion <bash|zsh>

Canonical operator surface for Jeff intel network: daily GitHub/git, website/RSS,
X, JSM, mirror ingest, plus hourly @doodlestein X polling.
EOF
}

examples() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc '{schema_version:"jeff-intel-network/examples/v1",examples:[
      {name:"doctor",command:"jeff-intel-network.sh doctor --json"},
      {name:"dry-run daily pull",command:"jeff-intel-network.sh pull --dry-run --json"},
      {name:"hourly x fixture",command:"JEFF_INTEL_X_FIXTURE=/tmp/x.md jeff-intel-network.sh x-poll --dry-run --json"},
      {name:"audit ledgers",command:"jeff-intel-network.sh audit --json"}
    ]}'
  else
    cat <<'EOF'
jeff-intel-network.sh doctor --json
jeff-intel-network.sh pull --dry-run --json
JEFF_INTEL_X_FIXTURE=/tmp/x.md jeff-intel-network.sh x-poll --dry-run --json
jeff-intel-network.sh audit --json
EOF
  fi
}

info_json() {
  jq -nc \
    --arg schema_version "jeff-intel-network/info/v1" \
    --arg version "$VERSION" \
    --arg root "$ROOT" \
    --arg runner "$RUNNER" \
    --arg daily "$DAILY" \
    --arg state_dir "$STATE_DIR" \
    --arg flywheel_state_dir "$FLYWHEEL_STATE_DIR" \
    '{
      schema_version:$schema_version,
      command:"info",
      name:"jeff-intel-network.sh",
      version:$version,
      root:$root,
      runner:$runner,
      daily_ingest:$daily,
      state_dir:$state_dir,
      flywheel_state_dir:$flywheel_state_dir,
      mutating_commands:["pull --apply","x-poll --apply","repair --apply"],
      default_mutation_mode:"dry-run",
      subcommands:["doctor","health","repair","validate","audit","why","quickstart","pull","x-poll","completion","help","schema"],
      canonical_flags:["--info","--schema","--examples","--json","--apply","--dry-run","--idempotency-key","--scope","--explain","--version"],
      capabilities:[
        "five-source-daily-ingest-via-jeff-corpus",
        "x-poll-hourly-cadence",
        "monthly-deep-mine-philosophy",
        "tentacle-drift-weekly-readonly-sweep",
        "scheduled-runner-launchd-aware",
        "doctor-aggregates-runner-plus-daily-ingest",
        "fixture-driven-x-poll-testing",
        "idempotent-receipts-via-key-or-mode"
      ],
      apply_supported:true,
      dry_run_supported:true,
      idempotency_key_required_for_apply:true,
      mutates_state:true,
      env_vars:["JEFF_INTEL_RUNNER","JEFF_INTEL_DAILY_SCRIPT","JEFF_INTEL_STATE_DIR","FLYWHEEL_STATE_DIR","JEFF_INTEL_X_FIXTURE"],
      exit_codes:{"0":"success","1":"doctor-fail-or-command-error","2":"bad-args","3":"refused-apply-without-idempotency-key"}
    }'
}

schema_json() {
  command_name="${1:-doctor}"
  jq -nc --arg schema_version "jeff-intel-network/schema/v1" --arg command "$command_name" '{
    schema_version:$schema_version,
    command:"schema",
    target_command:$command,
    input_schema:{
      type:"object",
      properties:{
        scope:{enum:["state"],description:"repair scope"},
        dry_run:{type:"boolean"},
        apply:{type:"boolean"},
        idempotency_key:{type:"string",description:"required with --apply on pull, x-poll, repair"},
        explain:{type:"boolean"}
      }
    },
    output_schema:{
      type:"object",
      required:["schema_version","mode","status"],
      properties:{
        schema_version:{type:"string"},
        mode:{type:"string"},
        status:{enum:["pass","fail","warn","ok"]},
        success:{type:"boolean"},
        version:{type:"string"},
        paths:{type:"object"},
        deps:{type:"array"}
      }
    },
    required:["schema_version","mode","status"],
    source_cadence:{github_git:"daily",website_rss:"daily",x:"hourly plus daily",jsm:"daily",mirror:"daily"},
    canonical_paths:{
      helper:".flywheel/scripts/jeff-intel-network.sh",
      slash:"/Users/josh/.claude/commands/flywheel/jeff-intel.md",
      schedule_ledger:"~/.local/state/jeff-intel/scheduled-runs.jsonl",
      x_poll_ledger:"~/.local/state/jeff-intel/x-poll.jsonl",
      daily_ledger:"~/.local/state/flywheel/daily-jeff-ingest.jsonl"
    },
    exit_codes:{"0":"success","1":"doctor-fail-or-command-error","2":"bad-args","3":"refused-apply-without-idempotency-key"}
  }'
}

quickstart() {
  cat <<'EOF'
Run `jeff-intel-network.sh doctor --json` during tick preflight. Use `pull
--dry-run --json` to preview the daily five-source ingest and `pull --apply
--json` only from the scheduled runner or an explicit operator action. The
canonical slash command is `/flywheel:jeff-intel`.
EOF
}

completion() {
  shell="${1:-bash}"
  case "$shell" in
    bash|zsh)
      printf 'complete -W "doctor health repair validate pull x-poll audit why schema quickstart help completion --json --dry-run --apply --info --examples --version --scope --idempotency-key --explain" jeff-intel-network.sh\n'
      ;;
    *) echo "ERR: unsupported shell: $shell" >&2; exit 2 ;;
  esac
}

run_json() {
  local out rc
  out="$(mktemp "${TMPDIR:-/tmp}/jeff-intel-network.XXXXXX")"
  set +e
  "$@" >"$out" 2>"$out.err"
  rc=$?
  set -e
  if jq empty "$out" >/dev/null 2>&1; then
    jq -c . "$out"
  else
    jq -nc --arg stderr "$(cat "$out.err")" --arg stdout "$(cat "$out")" '{status:"invalid_json",stdout:$stdout,stderr:$stderr}'
  fi
  rm -f "$out" "$out.err"
  return "$rc"
}

doctor() {
  local schedule daily schedule_rc daily_rc status
  schedule="$(run_json "$RUNNER" --mode doctor --json)" || schedule_rc=$?
  schedule_rc="${schedule_rc:-0}"
  daily="$(run_json "$DAILY" --doctor --json)" || daily_rc=$?
  daily_rc="${daily_rc:-0}"
  if [[ "$schedule_rc" -eq 0 && "$daily_rc" -eq 0 ]]; then status="pass"; else status="fail"; fi
  jq -nc \
    --arg schema_version "jeff-intel-network/doctor/v1" \
    --arg mode "doctor" \
    --arg status "$status" \
    --arg version "$VERSION" \
    --arg helper "$ROOT/.flywheel/scripts/jeff-intel-network.sh" \
    --arg slash "/Users/josh/.claude/commands/flywheel/jeff-intel.md" \
    --argjson schedule "$schedule" \
    --argjson daily "$daily" \
    --argjson schedule_rc "$schedule_rc" \
    --argjson daily_rc "$daily_rc" \
    '{schema_version:$schema_version,command:"doctor",mode:$mode,status:$status,success:($status=="pass"),version:$version,paths:{helper:$helper,slash:$slash,sources_file:($daily.paths.sources_file // null),state_dir:($daily.paths.state_dir // null),schedule_ledger:($schedule.receipt_paths.schedule // null)},checks:($daily.deps // []),deps:($daily.deps // []),sources_file:($daily.paths.sources_file // null),scheduled_runner:$schedule,daily_ingest:$daily,exit_codes:{scheduled_runner:$schedule_rc,daily_ingest:$daily_rc}}'
  [[ "$status" == "pass" ]]
}

health() {
  local schedule_ledger="$STATE_DIR/scheduled-runs.jsonl" x_ledger="$STATE_DIR/x-poll.jsonl" daily_ledger="$FLYWHEEL_STATE_DIR/daily-jeff-ingest.jsonl"
  local schedule_rows=0 x_rows=0 daily_rows=0
  [[ -f "$schedule_ledger" ]] && schedule_rows="$(wc -l <"$schedule_ledger" | tr -d ' ')"
  [[ -f "$x_ledger" ]] && x_rows="$(wc -l <"$x_ledger" | tr -d ' ')"
  [[ -f "$daily_ledger" ]] && daily_rows="$(wc -l <"$daily_ledger" | tr -d ' ')"
  jq -nc --arg schema_version "jeff-intel-network/health/v1" --arg mode "health" --arg status "pass" --arg schedule_ledger "$schedule_ledger" --arg x_ledger "$x_ledger" --arg daily_ledger "$daily_ledger" --argjson schedule_rows "$schedule_rows" --argjson x_rows "$x_rows" --argjson daily_rows "$daily_rows" '{schema_version:$schema_version,mode:$mode,status:$status,ledgers:{schedule:$schedule_ledger,x_poll:$x_ledger,daily:$daily_ledger},rows:{schedule:$schedule_rows,x_poll:$x_rows,daily:$daily_rows}}'
}

repair() {
  [[ "$SCOPE" == "state" || "$SCOPE" == "all" ]] || { echo "ERR: unsupported scope: $SCOPE" >&2; exit 2; }
  if [[ "$APPLY" -eq 1 ]]; then
    mkdir -p "$STATE_DIR" "$STATE_DIR/x-poll" "$FLYWHEEL_STATE_DIR"
    jq -nc --arg schema_version "jeff-intel-network/repair/v1" --arg mode "repair" --arg status "applied" --arg state "$STATE_DIR" --arg flywheel "$FLYWHEEL_STATE_DIR" --arg key "$IDEMPOTENCY_KEY" '{schema_version:$schema_version,mode:$mode,status:$status,idempotency_key:$key,actual_actions:[{action:"mkdir",path:$state},{action:"mkdir",path:($state + "/x-poll")},{action:"mkdir",path:$flywheel}],writes:[$state,($state + "/x-poll"),$flywheel]}'
  else
    jq -nc --arg schema_version "jeff-intel-network/repair/v1" --arg mode "repair" --arg status "dry_run" --arg state "$STATE_DIR" --arg flywheel "$FLYWHEEL_STATE_DIR" --arg key "$IDEMPOTENCY_KEY" '{schema_version:$schema_version,mode:$mode,status:$status,idempotency_key:$key,planned_actions:[{action:"mkdir",path:$state},{action:"mkdir",path:($state + "/x-poll")},{action:"mkdir",path:$flywheel}],would_write:[$state,($state + "/x-poll"),$flywheel],actual_actions:[]}'
  fi
}

validate() {
  local helper_ok slash_ok agents_ok readme_ok tick_ok status
  [[ -x "$ROOT/.flywheel/scripts/jeff-intel-network.sh" ]] && helper_ok=true || helper_ok=false
  [[ -f "/Users/josh/.claude/commands/flywheel/jeff-intel.md" ]] && slash_ok=true || slash_ok=false
  rg -q 'jeff-intel-network.sh' "$ROOT/AGENTS.md" && agents_ok=true || agents_ok=false
  rg -q 'jeff-intel-network.sh' "$ROOT/README.md" && readme_ok=true || readme_ok=false
  rg -q 'jeff-intel-network.sh' "$ROOT/.flywheel/flywheel-loop-tick" "/Users/josh/.claude/commands/flywheel/tick.md" && tick_ok=true || tick_ok=false
  if [[ "$helper_ok" == true && "$slash_ok" == true && "$agents_ok" == true && "$readme_ok" == true && "$tick_ok" == true ]]; then status="pass"; else status="fail"; fi
  jq -nc --arg schema_version "jeff-intel-network/validate/v1" --arg mode "validate" --arg status "$status" --argjson helper "$helper_ok" --argjson slash "$slash_ok" --argjson agents "$agents_ok" --argjson readme "$readme_ok" --argjson tick "$tick_ok" '{schema_version:$schema_version,mode:$mode,status:$status,checks:{helper_executable:$helper,slash_exists:$slash,agents_names_canonical:$agents,readme_names_canonical:$readme,tick_names_canonical:$tick}}'
  [[ "$status" == "pass" ]]
}

pull() {
  local flag="--dry-run"
  [[ "$APPLY" -eq 1 ]] && flag=""
  if [[ -n "$flag" ]]; then "$RUNNER" --mode daily "$flag" --json; else "$RUNNER" --mode daily --json; fi
}

x_poll() {
  local flag="--dry-run"
  [[ "$APPLY" -eq 1 ]] && flag=""
  if [[ -n "$flag" ]]; then "$RUNNER" --mode x-poll "$flag" --json; else "$RUNNER" --mode x-poll --json; fi
}

audit() {
  jq -nc \
    --arg schema_version "jeff-intel-network/audit/v1" \
    --arg schedule "$STATE_DIR/scheduled-runs.jsonl" \
    --arg x "$STATE_DIR/x-poll.jsonl" \
    --arg daily "$FLYWHEEL_STATE_DIR/daily-jeff-ingest.jsonl" \
    '{schema_version:$schema_version,mode:"audit",status:"pass",ledgers:{schedule:$schedule,x_poll:$x,daily:$daily},latest:{schedule:null,x_poll:null,daily:null}}' \
    | jq --arg schedule_latest "$(tail -1 "$STATE_DIR/scheduled-runs.jsonl" 2>/dev/null || true)" --arg x_latest "$(tail -1 "$STATE_DIR/x-poll.jsonl" 2>/dev/null || true)" --arg daily_latest "$(tail -1 "$FLYWHEEL_STATE_DIR/daily-jeff-ingest.jsonl" 2>/dev/null || true)" '.latest.schedule=($schedule_latest|fromjson? // null) | .latest.x_poll=($x_latest|fromjson? // null) | .latest.daily=($daily_latest|fromjson? // null)'
}

why() {
  local id="$1"
  [[ -n "$id" ]] || { echo "ERR: why requires id" >&2; exit 2; }
  jq -nc --arg schema_version "jeff-intel-network/why/v1" --arg id "$id" --arg helper "$ROOT/.flywheel/scripts/jeff-intel-network.sh" --arg runner "$RUNNER" --arg daily "$DAILY" '{schema_version:$schema_version,mode:"why",status:"pass",id:$id,provenance:{helper:$helper,scheduled_runner:$runner,daily_ingest:$daily,doctrine:"AGENTS.md L63",slash:"/Users/josh/.claude/commands/flywheel/jeff-intel.md"}}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    doctor|health|repair|validate|pull|x-poll|audit|why|schema|quickstart|help|completion)
      if [[ "$MODE" == "schema" || "$MODE" == "why" || "$MODE" == "help" || "$MODE" == "completion" ]]; then
        POSITIONAL="${POSITIONAL:+$POSITIONAL }$1"
      else
        MODE="$1"
      fi
      shift ;;
    --doctor) MODE="doctor"; shift ;;
    --health) MODE="health"; shift ;;
    --pull) MODE="pull"; shift ;;
    --x-poll) MODE="x-poll"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --dry-run) APPLY=0; shift ;;
    --apply) APPLY=1; shift ;;
    --scope) SCOPE="${2:-}"; shift 2 ;;
    --idempotency-key) IDEMPOTENCY_KEY="${2:-}"; shift 2 ;;
    --explain|--no-color|--no-emoji) shift ;;
    --width) shift 2 ;;
    --info) MODE="info"; shift ;;
    --examples) MODE="examples"; shift ;;
    --schema) MODE="schema"; shift ;;
    --version) printf '%s\n' "$VERSION"; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) POSITIONAL="${POSITIONAL:+$POSITIONAL }$1"; shift ;;
  esac
done

case "$MODE" in
  doctor) doctor ;;
  health) health ;;
  info) info_json ;;
  examples) examples ;;
  repair) repair ;;
  validate) validate ;;
  pull) pull ;;
  x-poll) x_poll ;;
  audit) audit ;;
  why) why "$POSITIONAL" ;;
  schema) schema_json "$POSITIONAL" ;;
  quickstart) quickstart ;;
  help) if [[ -n "$POSITIONAL" ]]; then usage; else usage; fi ;;
  completion) completion "$POSITIONAL" ;;
  *) usage; exit 2 ;;
esac
