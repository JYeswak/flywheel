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

SCAFFOLD_SCHEMA_VERSION="doctrine-ladder-promote/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/doctrine-ladder-promote-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: doctrine-ladder-promote.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "doctrine-ladder-promote.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "doctrine-ladder-promote.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"doctrine-ladder-promote.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"doctrine-ladder-promote.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"doctrine-ladder-promote.sh doctor --json"}'
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
            && cli_emit_completion_bash "doctrine-ladder-promote" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "doctrine-ladder-promote" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # TODO(canonical-cli-scaffold): probe substrate this script depends on
  # (env vars, paths, external tools) and emit per-check status.
  # Canonical pattern (per L4 lint rule — NEVER use `[[ ]] && X || Y`
  # as the last expression of a helper; use if/then/else/fi):
  #   if [[ -d "$ROOT/.flywheel" ]]; then
  #     printf '{"check":"flywheel-dir","status":"pass"}\n'
  #   else
  #     printf '{"check":"flywheel-dir","status":"fail"}\n'
  #   fi
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
REPO="${1:-/Users/josh/Developer/flywheel}"
FUCKUP_LOG="${FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
BR_BIN="${BR_BIN:-br}"
PERIOD_DAYS="${DOCTRINE_LADDER_PERIOD_DAYS:-7}"

if ! command -v jq >/dev/null 2>&1; then
  printf '{"action":"error","reason":"jq_missing"}\n'
  exit 1
fi

if ! command -v "$BR_BIN" >/dev/null 2>&1; then
  if [ -x "$HOME/.cargo/bin/br" ]; then
    BR_BIN="$HOME/.cargo/bin/br"
  else
    printf '{"action":"error","reason":"br_missing"}\n'
    exit 1
  fi
fi

if [ ! -f "$FUCKUP_LOG" ]; then
  jq -nc '{action:"noop",reason:"no_fuckup_log"}'
  exit 0
fi

cutoff_iso() {
  python3 - "$PERIOD_DAYS" <<'PY' 2>/dev/null || date -u -v-"${PERIOD_DAYS}"d +%Y-%m-%dT%H:%M:%SZ
import datetime
import sys

days = int(sys.argv[1])
cutoff = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=days)
print(cutoff.strftime("%Y-%m-%dT%H:%M:%SZ"))
PY
}

default_incident_paths() {
  printf '%s\n' "$HOME/.claude/skills/.flywheel/INCIDENTS.md"
  printf '%s\n' "$HOME"/.claude/skills/*/references/INCIDENTS.md
  printf '%s\n' "$REPO/INCIDENTS.md"
  printf '%s\n' "$REPO/AGENTS.md"
  # flywheel-iyaym: also scan canonical flywheel INCIDENTS at its absolute
  # path so worktree-relative $REPO/INCIDENTS.md never masks coverage. When
  # orch tick runs from /Users/josh/Developer/flywheel-*-worktree (stale
  # branch), $REPO/INCIDENTS.md may be days out of date; the canonical
  # flywheel checkout is the source of truth.
  printf '%s\n' "/Users/josh/Developer/flywheel/INCIDENTS.md"
  # flywheel-vl0c9: extend coverage scan to .flywheel/rules/*.md so
  # trauma classes already covered at the canonical L-rule layer don't
  # re-fire as promotion-candidate beads. Surfaced by 6+ duplicate
  # filings in one session for daily_report_missing_dispatch_gate,
  # mobile-eats-dispatch-health-gate-fail, sister-orch-2-tick-blocker,
  # three_q_surface_gap, and orch-punt-to-next-tick — all already
  # covered by L91/L92/L70/L152/two-blocker-ticks-escalate L-rules.
  printf '%s\n' "$REPO"/.flywheel/rules/*.md
  printf '%s\n' "$HOME"/.claude/skills/.flywheel/rules/*.md
  printf '%s\n' /Users/josh/Developer/flywheel/.flywheel/rules/*.md
}

incident_paths() {
  if [ -n "${INCIDENTS_SEARCH_PATHS:-}" ]; then
    printf '%s\n' $INCIDENTS_SEARCH_PATHS
  else
    default_incident_paths
  fi
}

incidents_cover_class() {
  local class="$1"
  while IFS= read -r path; do
    [ -f "$path" ] || continue
    if grep -Fqi -- "$class" "$path"; then
      return 0
    fi
  done < <(incident_paths)
  return 1
}

issues_json() {
  (cd "$REPO" && "$BR_BIN" list --json --limit 0)
}

open_promotion_candidate_exists() {
  local class="$1"
  issues_json | jq -e --arg class "$class" '
    .issues[]?
    | select((.status // "") != "closed")
    | select(((.title // "") | ascii_downcase | contains("promotion-candidate"))
      and ((.title // "") | contains($class)))
  ' >/dev/null
}

create_candidate_bead() {
  local class="$1" count="$2"
  local description bead
  description="Auto-created by doctrine-ladder-promote.sh per L56 ladder. Trauma class '$class' hit $count times in last ${PERIOD_DAYS}d with no INCIDENTS coverage. Run /flywheel:learn --promote $class to draft doctrine entry."
  bead="$(cd "$REPO" && "$BR_BIN" create "[promotion-candidate] $class ($count events in ${PERIOD_DAYS}d)" \
    --type task \
    --priority 2 \
    --description "$description" \
    --silent)"
  printf '%s\n' "$bead"
}

cutoff="$(cutoff_iso)"
classes="$(
  jq -Rr 'fromjson? | select(type == "object")' "$FUCKUP_LOG" 2>/dev/null \
    | jq -r --arg cutoff "$cutoff" '
      select(((.ts // .timestamp // "") | tostring) >= $cutoff)
      | (.trauma_class // "") | tostring
      | select(length > 0)
    ' \
    | sort \
    | uniq -c \
    | awk -v threshold=3 '$1 >= threshold { count=$1; $1=""; sub(/^ +/, ""); print $0 "\t" count }'
)"

created_file="$(mktemp)"
skipped_file="$(mktemp)"
trap 'rm -f "$created_file" "$skipped_file"' EXIT

if [ -n "$classes" ]; then
  while IFS=$'\t' read -r class count; do
    [ -n "${class:-}" ] || continue
    if incidents_cover_class "$class"; then
      printf '%s:incidents_covered\n' "$class" >>"$skipped_file"
      continue
    fi
    if open_promotion_candidate_exists "$class"; then
      printf '%s:bead_exists\n' "$class" >>"$skipped_file"
      continue
    fi
    bead="$(create_candidate_bead "$class" "$count")"
    printf '%s:%s\n' "$class" "$bead" >>"$created_file"
  done <<<"$classes"
fi

created_json="$(jq -R 'select(length > 0)' "$created_file" | jq -s .)"
skipped_json="$(jq -R 'select(length > 0)' "$skipped_file" | jq -s .)"

jq -nc \
  --argjson period_days "$PERIOD_DAYS" \
  --arg cutoff "$cutoff" \
  --argjson created "$created_json" \
  --argjson skipped "$skipped_json" \
  '{
    action:"completed",
    period_days:$period_days,
    cutoff:$cutoff,
    created:$created,
    skipped:$skipped
  }'
