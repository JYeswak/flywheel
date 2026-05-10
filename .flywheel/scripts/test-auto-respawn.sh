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

SCAFFOLD_SCHEMA_VERSION="test-auto-respawn/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/test-auto-respawn-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: test-auto-respawn.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "test-auto-respawn.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "test-auto-respawn.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"test-auto-respawn.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"test-auto-respawn.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"test-auto-respawn.sh doctor --json"}'
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
            && cli_emit_completion_bash "test-auto-respawn" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "test-auto-respawn" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
DETECTOR="${DETECTOR:-/Users/josh/.claude/skills/.flywheel/bin/auto-respawn-detector.sh}"
REAL_NTM_BIN="${REAL_NTM_BIN:-/Users/josh/.local/bin/ntm}"
ts="$(date -u +%Y%m%dT%H%M%SZ)"
session="auto-respawn-test-${ts}-$$"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/auto-respawn-test.XXXXXX")"
state_dir="$tmp/state"
topology="$tmp/session-topology.jsonl"
fake_ntm="$tmp/ntm"
calls="$tmp/calls.log"
mkdir -p "$state_dir"
touch "$calls"

cleanup() {
  if command -v "$REAL_NTM_BIN" >/dev/null 2>&1; then
    "$REAL_NTM_BIN" kill "$session" --force >/dev/null 2>&1 || true
  fi
  rm -rf "$tmp"
}
trap cleanup EXIT HUP INT TERM

if command -v "$REAL_NTM_BIN" >/dev/null 2>&1; then
  "$REAL_NTM_BIN" kill "$session" --force >/dev/null 2>&1 || true
  "$REAL_NTM_BIN" create "$session" --panes=2 --json >/dev/null
fi

state_since="$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
print((datetime.now(timezone.utc) - timedelta(minutes=10)).strftime("%Y-%m-%dT%H:%M:%SZ"))
PY
)"

jq -nc --arg session "$session" --arg effective_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{session:$session, effective_at:$effective_at, human_pane:0, orchestrator_pane:2, callback_pane:2}' > "$topology"

cat > "$fake_ntm" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
calls="${AUTO_RESPAWN_TEST_CALLS:?}"
session="${AUTO_RESPAWN_TEST_SESSION:?}"
state_since="${AUTO_RESPAWN_TEST_STATE_SINCE:?}"

log_call() {
  printf '%s\n' "$*" >> "$calls"
}

case "${1:-}" in
  list)
    if [[ "${2:-}" == "--json" ]]; then
      jq -nc --arg s "$session" '{sessions:[{name:$s}]}'
      exit 0
    fi
    ;;
  --robot-activity=*)
    jq -nc --arg s "$session" --arg since "$state_since" '{
      session:$s,
      success:true,
      agents:[
        {pane:"0",pane_idx:0,agent_type:"codex",state:"ERROR",state_since:$since,velocity:0},
        {pane:"1",pane_idx:1,agent_type:"codex",state:"ERROR",state_since:$since,velocity:0},
        {pane:"2",pane_idx:2,agent_type:"codex",state:"WAITING",state_since:$since,velocity:0}
      ],
      summary:{total_agents:3,by_state:{ERROR:2,WAITING:1}}
    }'
    exit 0
    ;;
  --robot-tail=*)
    pane="unknown"
    for arg in "$@"; do
      case "$arg" in
        --panes=*) pane="${arg#--panes=}" ;;
      esac
    done
    jq -nc --arg pane "$pane" '{panes:{($pane):{lines:["synthetic dead pane output"]}}}'
    exit 0
    ;;
  respawn)
    log_call "respawn session=$2 panes=${3#--panes=}"
    exit 0
    ;;
  send)
    pane="unknown"
    file=""
    prompt=""
    shift
    sess="$1"; shift
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --pane=*) pane="${1#--pane=}" ; shift ;;
        --pane) pane="$2"; shift 2 ;;
        --file) file="$2"; shift 2 ;;
        --no-cass-check) shift ;;
        *) prompt="$1"; shift ;;
      esac
    done
    if [[ -n "$file" ]]; then
      log_call "send session=$sess pane=$pane file=$file"
    else
      log_call "send session=$sess pane=$pane prompt=$prompt"
    fi
    exit 0
    ;;
esac

printf 'fake ntm unsupported args: %s\n' "$*" >&2
exit 9
FAKE
chmod +x "$fake_ntm"

set +e
AUTO_RESPAWN_NTM_BIN="$fake_ntm" \
AUTO_RESPAWN_STATE_DIR="$state_dir" \
AUTO_RESPAWN_TOPOLOGY_FILE="$topology" \
AUTO_RESPAWN_TEST_CALLS="$calls" \
AUTO_RESPAWN_TEST_SESSION="$session" \
AUTO_RESPAWN_TEST_STATE_SINCE="$state_since" \
AUTO_RESPAWN_WAIT_SECONDS=0 \
"$DETECTOR" --session "$session" --threshold-seconds 60 --throttle-seconds 1800 >"$tmp/first.out" 2>"$tmp/first.err"
first_rc=$?

AUTO_RESPAWN_NTM_BIN="$fake_ntm" \
AUTO_RESPAWN_STATE_DIR="$state_dir" \
AUTO_RESPAWN_TOPOLOGY_FILE="$topology" \
AUTO_RESPAWN_TEST_CALLS="$calls" \
AUTO_RESPAWN_TEST_SESSION="$session" \
AUTO_RESPAWN_TEST_STATE_SINCE="$state_since" \
AUTO_RESPAWN_WAIT_SECONDS=0 \
"$DETECTOR" --session "$session" --threshold-seconds 60 --throttle-seconds 1800 >"$tmp/second.out" 2>"$tmp/second.err"
second_rc=$?
set -e

if [[ "$first_rc" -ne 1 ]]; then
  echo "FAIL: first detector run rc=$first_rc expected 1"
  cat "$tmp/first.err"
  exit 1
fi
if [[ "$second_rc" -ne 2 ]]; then
  echo "FAIL: second detector run rc=$second_rc expected 2 throttle"
  cat "$tmp/second.err"
  exit 1
fi

if ! grep -q '^respawn session=.* panes=1$' "$calls"; then
  echo "FAIL: pane 1 was not respawned"
  cat "$calls"
  exit 1
fi
if grep -q 'panes=0\\|panes=2' "$calls"; then
  echo "FAIL: excluded/live pane was respawned"
  cat "$calls"
  exit 1
fi
if [[ "$(grep -c '^respawn ' "$calls")" -ne 1 ]]; then
  echo "FAIL: expected exactly one respawn call"
  cat "$calls"
  exit 1
fi
if [[ "$(grep -c '^send ' "$calls")" -lt 2 ]]; then
  echo "FAIL: expected relaunch and resume send calls"
  cat "$calls"
  exit 1
fi

jq -e 'select(.respawn_outcome=="success" and .session=="'"$session"'" and .pane==1)' "$state_dir/auto-respawn.jsonl" >/dev/null
jq -e 'select(.respawn_outcome=="throttled" and .session=="'"$session"'" and .pane==1)' "$state_dir/auto-respawn.jsonl" >/dev/null

echo "PASS: auto-respawn detector respawned synthetic dead pane, left live/excluded panes untouched, and enforced throttle"
