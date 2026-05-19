#!/usr/bin/env bash
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

SCAFFOLD_SCHEMA_VERSION="worker-auto-respawn-watchdog/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/worker-auto-respawn-watchdog-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: worker-auto-respawn-watchdog.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "worker-auto-respawn-watchdog.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "worker-auto-respawn-watchdog.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"worker-auto-respawn-watchdog.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"worker-auto-respawn-watchdog.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"worker-auto-respawn-watchdog.sh doctor --json"}'
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
            && cli_emit_completion_bash "worker-auto-respawn-watchdog" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "worker-auto-respawn-watchdog" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
VERSION="worker-auto-respawn-watchdog.v2.1.0"
SCHEMA="worker-auto-respawn-watchdog.v2"
STATE_DIR="${WORKER_AUTO_RESPAWN_STATE_DIR:-$HOME/.local/state/flywheel}"
TOPOLOGY="${WORKER_AUTO_RESPAWN_TOPOLOGY:-$STATE_DIR/session-topology.jsonl}"
ATTEMPTS="${WORKER_AUTO_RESPAWN_ATTEMPTS:-$STATE_DIR/auto-respawn-attempts.jsonl}"
NTM="${WORKER_AUTO_RESPAWN_NTM_BIN:-/Users/josh/.local/bin/ntm}"
MAX="${WORKER_AUTO_RESPAWN_MAX_ATTEMPTS_PER_HOUR:-3}"
TIMEOUT="${WORKER_AUTO_RESPAWN_WAIT_TIMEOUT:-1s}"
# flywheel-8p6fz.1: deep-liveness probe wire-in. Watchdog now consults the
# probe per tick to catch hung-but-running panes (stdout-stale; ntm wait
# wouldn't catch these because the pane process IS alive).
DEEP_LIVENESS_PROBE="${WORKER_AUTO_RESPAWN_DEEP_LIVENESS_PROBE:-$HOME/.claude/skills/.flywheel/scripts/worker-deep-liveness-probe.sh}"
DEEP_LIVENESS_FIXTURE="${WORKER_AUTO_RESPAWN_DEEP_LIVENESS_FIXTURE:-}"
SESSION=""; PANE=""; APPLY=false; JSON=false; QUIET=false

usage() { printf 'usage: worker-auto-respawn-watchdog.sh [--dry-run|--apply] [--json] [--session NAME] [--pane N]\n'; }
now_epoch() { date +%s; }
now_iso() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
emit() { if $JSON; then jq -c . <<<"$1"; elif ! $QUIET; then jq -r '"worker-auto-respawn-watchdog status=\(.status) checked=\(.targets_checked) respawned=\(.auto_respawns_fired)"' <<<"$1"; fi; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=true; shift ;;
    --dry-run) APPLY=false; shift ;;
    --json) JSON=true; shift ;;
    --quiet) QUIET=true; shift ;;
    --session) SESSION="${2:?}"; shift 2 ;;
    --session=*) SESSION="${1#*=}"; shift ;;
    --pane) PANE="${2:?}"; shift 2 ;;
    --pane=*) PANE="${1#*=}"; shift ;;
    --topology) TOPOLOGY="${2:?}"; shift 2 ;;
    --attempts) ATTEMPTS="${2:?}"; shift 2 ;;
    --ntm-bin) NTM="${2:?}"; shift 2 ;;
    --deep-liveness-probe) DEEP_LIVENESS_PROBE="${2:?}"; shift 2 ;;
    --deep-liveness-fixture) DEEP_LIVENESS_FIXTURE="${2:?}"; shift 2 ;;
    --info) jq -nc --arg s "$SCHEMA" --arg v "$VERSION" --arg t "$TOPOLOGY" --arg a "$ATTEMPTS" --arg n "$NTM" --arg dl "$DEEP_LIVENESS_PROBE" --argjson m "$MAX" '{schema_version:$s,mode:"info",version:$v,worker_scope_only:true,native_commands:["ntm wait --condition=DEAD","ntm respawn"],topology_file:$t,attempts_file:$a,ntm_bin:$n,deep_liveness_probe:$dl,respawn_triggers:["native_ntm_wait_dead","deep_liveness_hung"],budget:{max_attempts_per_hour:$m},canonical_cli:{doctor_health_repair:"n/a wrapper delegates to ntm",validate_audit_why:"n/a wrapper emits receipts",json:true,dry_run_apply:true},source_bead:"flywheel-8p6fz.1"}'; exit 0 ;;
    --examples) printf '%s\n' 'worker-auto-respawn-watchdog.sh --dry-run --json' 'worker-auto-respawn-watchdog.sh --apply --json --session flywheel --pane 2'; exit 0 ;;
    -h|--help|help) usage; exit 0 ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

attempts() {
  local cutoff=$(( $(now_epoch) - 3600 ))
  [[ -s "$ATTEMPTS" ]] || { printf '0\n'; return; }
  jq -sr --arg s "$1" --arg p "$2" --argjson c "$cutoff" '[.[] | select(type=="object" and .action=="respawn_attempt" and .session==$s and (.pane|tostring)==$p and ((.epoch // 0) >= $c))] | length' "$ATTEMPTS"
}

append_attempt() {
  mkdir -p "$(dirname "$ATTEMPTS")"
  jq -nc --arg ts "$(now_iso)" --argjson e "$(now_epoch)" --arg s "$1" --arg p "$2" --argjson n "$3" '{ts:$ts,epoch:$e,action:"respawn_attempt",session:$s,pane:($p|tonumber? // $p),attempt_number:$n,reason:"native_ntm_wait_dead",source:"worker-auto-respawn-watchdog",actor:"watchdog",trauma_class:"dead_worker_pane",primitive_invoked:"ntm respawn"}' >>"$ATTEMPTS"
}

target_lines() {
  [[ -s "$TOPOLOGY" ]] || return 3
  jq -rs --arg sf "$SESSION" --arg pf "$PANE" 'map(select(type=="object" and .session)) | sort_by(.effective_at // .ts // "") | group_by(.session) | map(last)[] as $t | ($t.worker_panes // [])[] | {session:($t.session|tostring),pane:(.|tostring),role:"worker"} | select(($sf=="" or .session==$sf) and ($pf=="" or .pane==$pf)) | [.session,.pane,.role] | @tsv' "$TOPOLOGY"
}

wait_dead() {
  local out rc
  set +e; out="$("$NTM" wait "$1" --pane="$2" --condition=DEAD --timeout "$TIMEOUT" --json 2>&1)"; rc=$?; set -e
  if [[ "$rc" -eq 0 ]]; then
    jq -nc --arg o "$out" '{dead:true,rc:0,output:$o}'
  else
    jq -nc --arg o "$out" --argjson rc "$rc" '{dead:false,rc:$rc,output:$o}'
  fi
}

respawn() { "$NTM" respawn "$1" --panes="$2" --json >/dev/null; }

# flywheel-8p6fz.1: deep-liveness probe wire-in.
# Invoke the probe once per watchdog run, cache JSON, then query per-pane.
# Probe lives in skill substrate (~/.claude/skills/.flywheel/scripts/);
# cross-repo consumer pattern (sister to flywheel-loop sourcing skill lib).
# WORKER_AUTO_RESPAWN_DEEP_LIVENESS_FIXTURE env-var overrides probe invocation
# for testing (fixture = path to a JSON file matching the probe's output shape).
deep_liveness_snapshot() {
  if [[ -n "$DEEP_LIVENESS_FIXTURE" && -r "$DEEP_LIVENESS_FIXTURE" ]]; then
    cat "$DEEP_LIVENESS_FIXTURE"
    return 0
  fi
  if [[ ! -x "$DEEP_LIVENESS_PROBE" ]]; then
    # Probe missing — emit empty envelope (graceful degradation).
    jq -nc '{status:"deep_liveness_probe_missing",worker_deep_liveness:[],hung_count:0,unknown_count:0}'
    return 0
  fi
  local out rc
  set +e; out="$("$DEEP_LIVENESS_PROBE" --json 2>/dev/null)"; rc=$?; set -e
  if [[ -z "$out" ]] || ! jq -e . >/dev/null 2>&1 <<<"$out"; then
    jq -nc --argjson rc "$rc" '{status:"deep_liveness_probe_invalid",rc:$rc,worker_deep_liveness:[],hung_count:0,unknown_count:0}'
    return 0
  fi
  printf '%s' "$out"
}

deep_liveness_state_for() {
  # $1=snapshot_json, $2=session, $3=pane
  jq -r --arg s "$2" --arg p "$3" 'first(.worker_deep_liveness[]? | select((.session // "")==$s and (.pane | tostring)==$p) | .deep_liveness_state) // "unknown"' <<<"$1"
}

tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
set +e; targets="$(target_lines)"; target_rc=$?; set -e
if [[ "$target_rc" -ne 0 ]]; then
  emit '{"schema_version":"worker-auto-respawn-watchdog.v2","success":false,"status":"probe_error","reason":"topology_lookup_failed","targets_checked":0,"auto_respawns_fired":0,"results":[]}'
  exit 3
fi

# flywheel-8p6fz.1: snapshot deep-liveness state once per run.
dl_snapshot="$(deep_liveness_snapshot)"

while IFS=$'\t' read -r session pane role; do
  [[ -n "${session:-}" ]] || continue
  wait_json="$(wait_dead "$session" "$pane")"; dead="$(jq -r '.dead' <<<"$wait_json")"; count="$(attempts "$session" "$pane")"
  # flywheel-8p6fz.1: deep-liveness signal per-pane
  hung_state="$(deep_liveness_state_for "$dl_snapshot" "$session" "$pane")"
  trigger=""
  if [[ "$dead" == true ]]; then trigger="native_ntm_wait_dead"; fi
  if [[ -z "$trigger" && "$hung_state" == "hung" ]]; then trigger="deep_liveness_hung"; fi
  action="none"; reason="not_dead"; rc=0
  if [[ -n "$trigger" && "$count" -ge "$MAX" ]]; then action="notify_fallback"; reason="auto_respawn_budget_exhausted_via_${trigger}"; fi
  if [[ -n "$trigger" && "$count" -lt "$MAX" && "$APPLY" == true ]]; then action="auto_respawn_fired"; reason="$trigger"; append_attempt "$session" "$pane" "$((count + 1))"; respawn "$session" "$pane" || rc=$?; fi
  if [[ -n "$trigger" && "$count" -lt "$MAX" && "$APPLY" == false ]]; then action="would_auto_respawn"; reason="$trigger"; fi
  jq -nc --arg s "$session" --arg p "$pane" --arg r "$role" --arg a "$action" --arg y "$reason" --arg h "$hung_state" --argjson c "$count" --argjson rc "$rc" --argjson w "$wait_json" '{session:$s,pane:($p|tonumber? // $p),role:$r,action:$a,reason:$y,attempts_last_hour:$c,action_rc:$rc,wait:$w,deep_liveness_state:$h}' >>"$tmp"
done <<<"$targets"

payload="$(jq -s --arg s "$SCHEMA" --arg v "$VERSION" --arg t "$TOPOLOGY" --arg a "$ATTEMPTS" --argjson apply "$APPLY" '{schema_version:$s,version:$v,success:true,status:(if any(.[];.action=="auto_respawn_fired") then "auto_respawn_fired" elif any(.[];.action=="would_auto_respawn") then "dry_run_actions_planned" elif any(.[];.action=="notify_fallback") then "notify_fallback" else "no_action_needed" end),dry_run:($apply|not),apply:$apply,topology_file:$t,attempts_file:$a,targets_checked:length,workers_checked:length,auto_respawns_fired:([.[]|select(.action=="auto_respawn_fired")]|length),would_auto_respawns:([.[]|select(.action=="would_auto_respawn")]|length),notify_fallbacks_fired:([.[]|select(.action=="notify_fallback")]|length),results:.}' "$tmp")"
emit "$payload"
jq -e '.auto_respawns_fired > 0' >/dev/null <<<"$payload" && exit 1
jq -e '.notify_fallbacks_fired > 0' >/dev/null <<<"$payload" && exit 2
exit 0

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
