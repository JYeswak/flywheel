#!/usr/bin/env bash
# dispatch-surface-conflict-probe.sh — close flywheel-x6h.1.
#
# Detects when a candidate dispatch packet would write the same on-disk surface
# as another in-flight dispatch in the recent window. Replaces per-bead-only
# dedupe with per-write-surface dedupe so two beads pointing at the same file
# can't be assigned to two panes concurrently.
#
# Inputs:
#   --candidate-task-file PATH    dispatch packet path (preferred)
#   --candidate-text-file PATH    arbitrary text file (any markdown with paths)
#   --lookback-minutes N          how far back to look in dispatch-log (default 30)
#   --dispatch-log PATH           override default ~/.flywheel/dispatch-log.jsonl
#   --extra-surface-pattern RE    regex to match additional surface paths
#                                 (default: /Users/josh/[A-Za-z0-9_./-]+)
#   --self-task-id ID             ignore in-flight rows whose task_id matches
#                                 (so re-running the probe on a packet that
#                                 already lives in dispatch-log is clean)
#   --json                        emit JSON receipt (default for CI use)
#   --doctor|--health|--info|--schema   canonical-cli-scoping triad
#
# Output JSON shape:
#   {
#     verdict: "ok" | "conflict",
#     candidate_task_file, candidate_bead_id, candidate_surfaces[],
#     in_flight_count,
#     conflicts: [{ bead_id, task_id, task_file, overlapping_surfaces[] }]
#   }
#
# Exit codes:
#   0  no conflict (verdict=ok)
#   1  conflict detected (verdict=conflict)
#   2  config / usage error
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

SCAFFOLD_SCHEMA_VERSION="dispatch-surface-conflict-probe/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-surface-conflict-probe-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: dispatch-surface-conflict-probe.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "dispatch-surface-conflict-probe.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "dispatch-surface-conflict-probe.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"dispatch-surface-conflict-probe.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"dispatch-surface-conflict-probe.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"dispatch-surface-conflict-probe.sh doctor --json"}'
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
            && cli_emit_completion_bash "dispatch-surface-conflict-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "dispatch-surface-conflict-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
SCHEMA_VERSION="dispatch-surface-conflict-probe.v1"
DEFAULT_LOG="${FLYWHEEL_DISPATCH_LOG:-/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl}"
DEFAULT_PATTERN='/Users/josh/[A-Za-z0-9_./-]+'

CANDIDATE_TASK_FILE=""
CANDIDATE_TEXT_FILE=""
LOOKBACK_MIN=30
LOG_PATH="$DEFAULT_LOG"
EXTRA_PATTERN="$DEFAULT_PATTERN"
SELF_TASK_ID=""
JSON_OUT=0
MODE=run

usage() {
  cat <<'USAGE'
usage: dispatch-surface-conflict-probe.sh
         (--candidate-task-file PATH | --candidate-text-file PATH)
         [--lookback-minutes N]
         [--dispatch-log PATH]
         [--extra-surface-pattern RE]
         [--self-task-id ID]
         [--json]
       dispatch-surface-conflict-probe.sh --doctor|--health|--info|--schema [--json]

Detects whether a candidate dispatch packet's write surfaces overlap with
any in-flight dispatch in the recent window.

Default lookback: 30 minutes. Default surface regex: /Users/josh/[A-Za-z0-9_./-]+

Exit 0 = no conflict, 1 = conflict, 2 = config error.
USAGE
}

doctor() {
  jq -nc --arg schema "$SCHEMA_VERSION" --arg log "$LOG_PATH" \
    '{schema_version:$schema, success:true, mode:"doctor",
      dispatch_log:$log,
      log_present:($log | (. as $p | "" + $p) | test("\\.jsonl$")),
      reads_only:true,
      enforces:["per-write-surface dedupe across panes"]}'
}

info() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema, success:true, mode:"info",
      verdict_classes:["ok","conflict"],
      surface_extraction:"absolute /Users/josh/... paths in candidate body, sorted+unique",
      in_flight_window:"dispatch-log rows with event=dispatch_sent in lookback window"}'
}

schema() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema,
      properties:{
        verdict:{enum:["ok","conflict"]},
        candidate_task_file:{type:["string","null"]},
        candidate_bead_id:{type:["string","null"]},
        candidate_surfaces:{type:"array"},
        in_flight_count:{type:"integer"},
        conflicts:{type:"array"}}}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --candidate-task-file) CANDIDATE_TASK_FILE="${2:?--candidate-task-file requires PATH}"; shift 2;;
    --candidate-text-file) CANDIDATE_TEXT_FILE="${2:?--candidate-text-file requires PATH}"; shift 2;;
    --lookback-minutes) LOOKBACK_MIN="${2:?--lookback-minutes requires N}"; shift 2;;
    --dispatch-log) LOG_PATH="${2:?--dispatch-log requires PATH}"; shift 2;;
    --extra-surface-pattern) EXTRA_PATTERN="${2:?--extra-surface-pattern requires RE}"; shift 2;;
    --self-task-id) SELF_TASK_ID="${2:?--self-task-id requires ID}"; shift 2;;
    --json) JSON_OUT=1; shift;;
    --doctor|--health) MODE=doctor; shift;;
    --info) MODE=info; shift;;
    --schema) MODE=schema; shift;;
    -h|--help) usage; exit 0;;
    *) echo "ERR: unknown arg $1" >&2; usage >&2; exit 2;;
  esac
done

case "$MODE" in
  doctor) doctor; exit 0;;
  info) info; exit 0;;
  schema) schema; exit 0;;
esac

if [[ -z "$CANDIDATE_TASK_FILE" && -z "$CANDIDATE_TEXT_FILE" ]]; then
  echo "ERR: must pass --candidate-task-file or --candidate-text-file" >&2
  usage >&2; exit 2
fi
[[ -f "$LOG_PATH" ]] || { echo "ERR: dispatch-log not found: $LOG_PATH" >&2; exit 2; }

CANDIDATE_PATH="${CANDIDATE_TASK_FILE:-$CANDIDATE_TEXT_FILE}"
[[ -f "$CANDIDATE_PATH" ]] || { echo "ERR: candidate file not found: $CANDIDATE_PATH" >&2; exit 2; }

extract_surfaces() {
  # Match candidates, then strip trailing prose punctuation that the regex's
  # `+` quantifier may have absorbed (e.g. `.md.` at end-of-sentence).
  local file="$1"
  grep -oE "$EXTRA_PATTERN" "$file" 2>/dev/null \
    | sed -E 's/[.,;:)>"'"'"'\)]+$//' \
    | sort -u
}

CANDIDATE_BEAD_ID=""
if [[ -n "$CANDIDATE_TASK_FILE" ]]; then
  CANDIDATE_BEAD_ID="$(grep -oE '^# Bead: [a-zA-Z0-9._-]+' "$CANDIDATE_TASK_FILE" 2>/dev/null | head -1 | awk '{print $3}' || echo "")"
fi

CANDIDATE_SURFACES_RAW="$(extract_surfaces "$CANDIDATE_PATH")"
CANDIDATE_SURFACES_JSON="$(printf '%s\n' "$CANDIDATE_SURFACES_RAW" | jq -R -s 'split("\n") | map(select(length > 0))')"

# Window cutoff in epoch seconds
NOW_EPOCH="$(date -u +%s)"
WINDOW_CUTOFF=$((NOW_EPOCH - LOOKBACK_MIN * 60))

# Read in-flight rows (event=dispatch_sent within window).
IN_FLIGHT_TMP="$(mktemp "${TMPDIR:-/tmp}/dispatch-conflict-inflight.XXXXXX")"
trap 'rm -f "$IN_FLIGHT_TMP"' EXIT

while IFS= read -r row; do
  ev="$(jq -r '.event // ""' <<<"$row" 2>/dev/null)"
  [[ "$ev" == "dispatch_sent" ]] || continue
  ts_iso="$(jq -r '.ts // ""' <<<"$row")"
  [[ -n "$ts_iso" ]] || continue
  row_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "${ts_iso%%.*}Z" +%s 2>/dev/null \
            || date -u -d "$ts_iso" +%s 2>/dev/null \
            || echo 0)"
  [[ "$row_epoch" -ge "$WINDOW_CUTOFF" ]] || continue
  rid="$(jq -r '.task_id // ""' <<<"$row")"
  [[ -n "$SELF_TASK_ID" && "$rid" == "$SELF_TASK_ID" ]] && continue
  printf '%s\n' "$row" >>"$IN_FLIGHT_TMP"
done < <(tail -n 500 "$LOG_PATH")

CONFLICTS_TMP="$(mktemp "${TMPDIR:-/tmp}/dispatch-conflict-out.XXXXXX")"
trap 'rm -f "$IN_FLIGHT_TMP" "$CONFLICTS_TMP"' EXIT
: >"$CONFLICTS_TMP"

IN_FLIGHT_COUNT=0
while IFS= read -r row; do
  IN_FLIGHT_COUNT=$((IN_FLIGHT_COUNT + 1))
  task_id="$(jq -r '.task_id // ""' <<<"$row")"
  bead_id="$(jq -r '.bead_id // ""' <<<"$row")"
  task_file="$(jq -r '.task_file // ""' <<<"$row")"

  [[ -n "$task_file" && -f "$task_file" ]] || continue

  in_flight_surfaces="$(extract_surfaces "$task_file")"
  [[ -n "$in_flight_surfaces" ]] || continue

  overlap="$(comm -12 <(printf '%s\n' "$CANDIDATE_SURFACES_RAW" | sort -u) \
                       <(printf '%s\n' "$in_flight_surfaces" | sort -u))"
  if [[ -n "$overlap" ]]; then
    overlap_json="$(printf '%s\n' "$overlap" | jq -R -s 'split("\n") | map(select(length > 0))')"
    jq -nc \
      --arg bead_id "$bead_id" \
      --arg task_id "$task_id" \
      --arg task_file "$task_file" \
      --argjson overlap "$overlap_json" \
      '{bead_id:$bead_id, task_id:$task_id, task_file:$task_file, overlapping_surfaces:$overlap}' \
      >>"$CONFLICTS_TMP"
  fi
done <"$IN_FLIGHT_TMP"

CONFLICT_COUNT="$(wc -l <"$CONFLICTS_TMP" | tr -d ' ')"
VERDICT=ok
EXIT_CODE=0
[[ "$CONFLICT_COUNT" -gt 0 ]] && { VERDICT=conflict; EXIT_CODE=1; }

CONFLICTS_JSON="$(jq -s '.' "$CONFLICTS_TMP")"

PAYLOAD="$(jq -nc \
  --arg schema "$SCHEMA_VERSION" \
  --arg verdict "$VERDICT" \
  --arg candidate_path "$CANDIDATE_PATH" \
  --arg candidate_bead "$CANDIDATE_BEAD_ID" \
  --argjson candidate_surfaces "$CANDIDATE_SURFACES_JSON" \
  --argjson in_flight "$IN_FLIGHT_COUNT" \
  --argjson conflicts "$CONFLICTS_JSON" \
  '{schema_version:$schema, success:($verdict == "ok"),
    mode:"run", verdict:$verdict,
    candidate_task_file:$candidate_path,
    candidate_bead_id:(if $candidate_bead == "" then null else $candidate_bead end),
    candidate_surfaces:$candidate_surfaces,
    in_flight_count:$in_flight,
    conflicts:$conflicts}')"

if [[ "$JSON_OUT" == 1 ]]; then
  printf '%s\n' "$PAYLOAD"
else
  jq -r '"dispatch-surface-conflict verdict=\(.verdict) candidate=\(.candidate_bead_id // "?") candidate_surfaces=\(.candidate_surfaces | length) in_flight=\(.in_flight_count) conflicts=\(.conflicts | length)"' <<<"$PAYLOAD"
fi

exit "$EXIT_CODE"
