#!/usr/bin/env bash
# skill-bandit-measurement-probe.sh — closes flywheel-1rmp.3 (value-gap
# `skill-bandit-auto-experiments`).
#
# The smallest recurring measurement that makes the value gap visible:
# scan recent `dispatch_sent` rows in the canonical dispatch-log, read each
# row's task_file (the dispatch packet), extract `skill_auto_routes_matched=`
# from the packet body, and emit a per-skill match-frequency histogram.
#
# Surfacing: tick / dashboard consumers read the JSON receipt. Distribution
# entropy is reported so the "mostly-static skill selection" claim is
# observable as a single number.
#
# Anti-pattern preservation (Step 4o): probe is READ-ONLY. It does not call
# `br create`, `br close`, `ntm send`, `gh`, or any external API. It does not
# auto-dispatch from its own findings. Output is structured JSON only.
#
# Canonical-cli-scoping triad: --doctor / --health / --info / --schema /
# --json / stable exit codes.
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

SCAFFOLD_SCHEMA_VERSION="skill-bandit-measurement-probe/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/skill-bandit-measurement-probe-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: skill-bandit-measurement-probe.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "skill-bandit-measurement-probe.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "skill-bandit-measurement-probe.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"skill-bandit-measurement-probe.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"skill-bandit-measurement-probe.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"skill-bandit-measurement-probe.sh doctor --json"}'
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
            && cli_emit_completion_bash "skill-bandit-measurement-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "skill-bandit-measurement-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
SCHEMA_VERSION="skill-bandit-measurement-probe.v1"
DEFAULT_LOG="${FLYWHEEL_DISPATCH_LOG:-/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl}"

LOG_PATH="$DEFAULT_LOG"
SAMPLES=200
JSON_OUT=0
MODE=run

usage() {
  cat <<'USAGE'
usage: skill-bandit-measurement-probe.sh [--samples N] [--dispatch-log PATH] [--json]
       skill-bandit-measurement-probe.sh --doctor|--health|--info|--schema [--json]

Reads the last --samples (default 200) dispatch-log rows of event=dispatch_sent,
follows each row's task_file to extract skill_auto_routes_matched, and emits a
per-skill frequency histogram with distribution entropy.

Output JSON (run mode):
  {
    schema_version,
    samples_window,
    samples_resolved,            # rows whose task_file was readable
    samples_unresolved,
    skills_observed_count,
    per_skill: [
      {skill, match_count, match_fraction}
    ],
    top_skill,
    distribution_entropy,        # Shannon entropy in bits; 0 = single skill
                                 # always picked, log2(N) = uniform across N
    static_selection_indicator,  # true if entropy <= 1.0 bit
    canonical_set_match_fraction # fraction of dispatches whose matched
                                 # skill set is exactly the canonical
                                 # 4-skill set; surfaces near-static behavior
                                 # even when entropy is low
  }

Exit codes:
  0  measurement emitted
  1  no dispatch-log rows in window
  2  config / usage error
USAGE
}

doctor() {
  jq -nc --arg schema "$SCHEMA_VERSION" --arg log "$LOG_PATH" \
    '{schema_version:$schema, success:true, mode:"doctor",
      dispatch_log:$log, log_present:true,
      reads_only:true,
      auto_dispatch:false,
      surfaces:["tick receipt consumer","dashboard tile","doctor signal candidate"],
      anti_pattern_step_4o:"preserved"}'
}

info() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema, success:true, mode:"info",
      measurement:"per-skill match-frequency histogram + Shannon entropy",
      input:"dispatch-log dispatch_sent rows -> task_file -> skill_auto_routes_matched",
      output:"per_skill[] + distribution_entropy + static_selection_indicator",
      reads_only:true,
      step_4o_compliance:"no auto-dispatch from findings; emits JSON only"}'
}

schema() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema,
      properties:{
        samples_window:{type:"integer"},
        samples_resolved:{type:"integer"},
        samples_unresolved:{type:"integer"},
        skills_observed_count:{type:"integer"},
        per_skill:{type:"array",
          items:{properties:{skill:{type:"string"},match_count:{type:"integer"},match_fraction:{type:"number"}}}},
        top_skill:{type:["string","null"]},
        distribution_entropy:{type:"number"},
        static_selection_indicator:{type:"boolean"},
        canonical_set_match_fraction:{type:"number"}}}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --samples) SAMPLES="${2:?--samples requires N}"; shift 2;;
    --dispatch-log) LOG_PATH="${2:?--dispatch-log requires PATH}"; shift 2;;
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

[[ -f "$LOG_PATH" ]] || { echo "ERR: dispatch-log not found: $LOG_PATH" >&2; exit 2; }

# Pull the last N dispatch_sent rows into a tmp file.
RAW_TMP="$(mktemp "${TMPDIR:-/tmp}/skill-bandit-probe.XXXXXX")"
SKILLS_TMP="$(mktemp "${TMPDIR:-/tmp}/skill-bandit-skills.XXXXXX")"
trap 'rm -f "$RAW_TMP" "$SKILLS_TMP"' EXIT
: >"$SKILLS_TMP"

tail -n "$SAMPLES" "$LOG_PATH" \
  | jq -c 'select(.event == "dispatch_sent") | {task_file: (.task_file // "")}' \
  > "$RAW_TMP" 2>/dev/null || true

SAMPLES_WINDOW="$(wc -l <"$RAW_TMP" | tr -d ' ')"
if [[ "$SAMPLES_WINDOW" -eq 0 ]]; then
  echo "ERR: no dispatch_sent rows in last $SAMPLES dispatch-log lines" >&2
  exit 1
fi

SAMPLES_RESOLVED=0
SAMPLES_UNRESOLVED=0
CANONICAL_MATCH_COUNT=0

while IFS= read -r row; do
  tf="$(jq -r '.task_file' <<<"$row")"
  if [[ -z "$tf" || ! -f "$tf" ]]; then
    SAMPLES_UNRESOLVED=$((SAMPLES_UNRESOLVED + 1))
    continue
  fi
  matched_line="$(grep -m1 -E '^skill_auto_routes_matched=' "$tf" 2>/dev/null || true)"
  [[ -n "$matched_line" ]] || { SAMPLES_UNRESOLVED=$((SAMPLES_UNRESOLVED + 1)); continue; }
  SAMPLES_RESOLVED=$((SAMPLES_RESOLVED + 1))
  list="${matched_line#skill_auto_routes_matched=}"
  if [[ "$list" == "canonical-cli-scoping,rust-best-practices,python-best-practices,readme-writing" ]]; then
    CANONICAL_MATCH_COUNT=$((CANONICAL_MATCH_COUNT + 1))
  fi
  IFS=',' read -r -a skills <<<"$list"
  for s in "${skills[@]}"; do
    s="$(printf '%s' "$s" | tr -d ' \r\n')"
    [[ -n "$s" ]] || continue
    printf '%s\n' "$s" >>"$SKILLS_TMP"
  done
done <"$RAW_TMP"

PER_SKILL_JSON='[]'
ENTROPY=0
TOP_SKILL=null
SKILLS_OBSERVED_COUNT=0
if [[ "$SAMPLES_RESOLVED" -gt 0 ]]; then
  PER_SKILL_JSON="$(sort "$SKILLS_TMP" | uniq -c | awk '{c=$1; $1=""; sub(/^ /,""); print c"\t"$0}' \
    | jq -R -s --argjson total "$SAMPLES_RESOLVED" '
        split("\n") | map(select(length > 0)
          | split("\t")
          | {skill:.[1], match_count: (.[0]|tonumber), match_fraction: ((.[0]|tonumber) / $total)})
        | sort_by(-.match_count)')"
  SKILLS_OBSERVED_COUNT="$(jq 'length' <<<"$PER_SKILL_JSON")"
  TOP_SKILL="$(jq -c '.[0].skill // null' <<<"$PER_SKILL_JSON")"
  # Shannon entropy in bits over fraction-of-total-resolved.
  ENTROPY="$(jq '[.[] | .match_fraction
    | if . > 0 then (- . * (log / (2|log))) else 0 end] | add // 0' <<<"$PER_SKILL_JSON")"
fi

CANONICAL_FRACTION=0
[[ "$SAMPLES_RESOLVED" -gt 0 ]] && CANONICAL_FRACTION="$(awk -v n="$CANONICAL_MATCH_COUNT" -v d="$SAMPLES_RESOLVED" 'BEGIN{ printf "%.6f", n/d }')"

STATIC_INDICATOR=$(jq -nc --argjson e "$ENTROPY" '$e <= 1.0')

PAYLOAD="$(jq -nc \
  --arg schema "$SCHEMA_VERSION" \
  --argjson samples_window "$SAMPLES_WINDOW" \
  --argjson samples_resolved "$SAMPLES_RESOLVED" \
  --argjson samples_unresolved "$SAMPLES_UNRESOLVED" \
  --argjson skills_observed_count "$SKILLS_OBSERVED_COUNT" \
  --argjson per_skill "$PER_SKILL_JSON" \
  --argjson top_skill "$TOP_SKILL" \
  --argjson entropy "$ENTROPY" \
  --argjson static_indicator "$STATIC_INDICATOR" \
  --argjson canonical_fraction "$CANONICAL_FRACTION" \
  '{schema_version:$schema, success:true, mode:"run",
    samples_window:$samples_window,
    samples_resolved:$samples_resolved,
    samples_unresolved:$samples_unresolved,
    skills_observed_count:$skills_observed_count,
    per_skill:$per_skill,
    top_skill:$top_skill,
    distribution_entropy:$entropy,
    static_selection_indicator:$static_indicator,
    canonical_set_match_fraction:$canonical_fraction,
    reads_only:true,
    auto_dispatch:false,
    step_4o_compliance:"preserved"}')"

if [[ "$JSON_OUT" == 1 ]]; then
  printf '%s\n' "$PAYLOAD"
else
  jq -r '"skill-bandit measurement window=\(.samples_window) resolved=\(.samples_resolved) unresolved=\(.samples_unresolved) skills=\(.skills_observed_count) top=\(.top_skill // "none") entropy=\(.distribution_entropy) static=\(.static_selection_indicator) canonical_fraction=\(.canonical_set_match_fraction)"' <<<"$PAYLOAD"
fi
