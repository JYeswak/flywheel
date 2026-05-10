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

SCAFFOLD_SCHEMA_VERSION="mission-lock-readiness-doctor/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/mission-lock-readiness-doctor-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: mission-lock-readiness-doctor.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "mission-lock-readiness-doctor.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "mission-lock-readiness-doctor.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"mission-lock-readiness-doctor.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"mission-lock-readiness-doctor.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"mission-lock-readiness-doctor.sh doctor --json"}'
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
            && cli_emit_completion_bash "mission-lock-readiness-doctor" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "mission-lock-readiness-doctor" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
VERSION="mission-lock-readiness-doctor/v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MISSION_PATH="$ROOT/.flywheel/MISSION.md"
PLAN_PATH="$ROOT/.flywheel/PLANS/mission-lock-paradigm-extension-2026-05-06"
COMMAND="doctor"
JSON_OUT=0
QUIET=0
for arg in "$@"; do [[ "$arg" == "--json" ]] && JSON_OUT=1; done

usage() {
  printf '%s\n' \
    'usage:' \
    '  mission-lock-readiness-doctor.sh [doctor|health|validate|audit|schema] [--mission MISSION.md] [--plan PLAN_DIR] [--json] [--quiet]' \
    '  mission-lock-readiness-doctor.sh --info|--help|--examples [--json]'
}

examples() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc '{examples:["mission-lock-readiness-doctor.sh --json","mission-lock-readiness-doctor.sh doctor --mission .flywheel/MISSION.md --json","mission-lock-readiness-doctor.sh validate --plan .flywheel/PLANS/mission-lock-paradigm-extension-2026-05-06 --json"]}'
  else
    printf '%s\n' 'mission-lock-readiness-doctor.sh --json' 'mission-lock-readiness-doctor.sh doctor --mission .flywheel/MISSION.md --json' 'mission-lock-readiness-doctor.sh validate --plan .flywheel/PLANS/mission-lock-paradigm-extension-2026-05-06 --json'
  fi
}

info() {
  jq -nc --arg version "$VERSION" '{name:"mission-lock-readiness-doctor.sh",version:$version,mutates:false,audit_only_default:true,canonical_cli_flags:["--info","--help","--examples","--json","--quiet"],canonical_cli_verbs:["doctor","health","validate","audit","schema"],doctor_fields:["mission_lock_readiness_health_score","blocked_surfaces","phase0_scaffold_bead_suggestions","repair_receipt_identity_fields"],exit_codes:{"0":"healthy","1":"readiness_incomplete","2":"usage"}}'
}

schema_payload() {
  jq -nc --arg version "$VERSION" '{schema_version:$version,score_range:[0,1],producer_inputs:["mission-lock-output-schema-validator","mission-lock-scaffold-validator","plan-state-lens-merge validate"],consumer:"flywheel-loop doctor field set",promotion:"health<1 emits Phase 0 scaffold suggestions; no mutation in audit-only mode"}'
}

die_usage() { printf 'ERR: %s\n' "$1" >&2; exit 2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    doctor|health|validate|audit|schema) COMMAND="$1"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --mission) [[ $# -ge 2 ]] || die_usage "--mission requires a path"; MISSION_PATH="$2"; shift 2 ;;
    --plan) [[ $# -ge 2 ]] || die_usage "--plan requires a path"; PLAN_PATH="$2"; shift 2 ;;
    --info) info; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    --examples) examples; exit 0 ;;
    --*) die_usage "unknown argument: $1" ;;
    *) MISSION_PATH="$1"; shift ;;
  esac
done

if [[ "$COMMAND" == "schema" ]]; then schema_payload; exit 0; fi
[[ -r "$MISSION_PATH" ]] || die_usage "mission file not readable: $MISSION_PATH"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/mission-lock-readiness.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
SCHEMA_VALIDATOR="$ROOT/.flywheel/scripts/mission-lock-output-schema-validator.sh"
SCAFFOLD_VALIDATOR="$ROOT/.flywheel/scripts/mission-lock-scaffold-validator.sh"
LENS_MERGE="$ROOT/.flywheel/scripts/plan-state-lens-merge.sh"

run_json() {
  local out="$1"; shift
  set +e
  "$@" --json >"$out" 2>"$out.err"
  local rc=$?
  set -e
  return "$rc"
}

schema_rc=2
if [[ -x "$SCHEMA_VALIDATOR" ]]; then
  run_json "$TMP/schema.json" bash "$SCHEMA_VALIDATOR" --mission "$MISSION_PATH" || schema_rc=$?
  schema_rc="${schema_rc:-0}"
else
  jq -nc '{status:"skip",errors:[]}' >"$TMP/schema.json"
fi
schema_status="$(jq -r '.status // "skip"' "$TMP/schema.json" 2>/dev/null || printf 'fail')"
[[ "$schema_status" == "pass" ]] && schema_verdict=pass || schema_verdict=fail
[[ -x "$SCHEMA_VALIDATOR" ]] || schema_verdict=skip

scaffold_rc=2
if [[ -x "$SCAFFOLD_VALIDATOR" ]]; then
  run_json "$TMP/scaffold.json" bash "$SCAFFOLD_VALIDATOR" --mission "$MISSION_PATH" || scaffold_rc=$?
  scaffold_rc="${scaffold_rc:-0}"
else
  jq -nc '{verdict:"skip",blockers:[],checks:{blocked_readiness_states:[]}}' >"$TMP/scaffold.json"
fi
scaffold_verdict="$(jq -r '.verdict // "skip"' "$TMP/scaffold.json" 2>/dev/null || printf 'fail')"
[[ -x "$SCAFFOLD_VALIDATOR" ]] || scaffold_verdict=skip

if [[ -x "$LENS_MERGE" && -e "$PLAN_PATH" ]]; then
  if run_json "$TMP/lens.json" bash "$LENS_MERGE" validate --plan "$PLAN_PATH"; then
    lens_consistent=true
  else
    lens_consistent=false
  fi
else
  jq -nc '{status:"fail",malformed_count:1}' >"$TMP/lens.json"
  lens_consistent=false
fi

: >"$TMP/surfaces.txt"
: >"$TMP/suggestions.jsonl"
suggest() {
  local slug="$1" summary="$2" finding="$3"
  printf '%s\n' "$slug" >>"$TMP/surfaces.txt"
  jq -nc --arg slug "$slug" --arg summary "$summary" --arg finding "$finding" '{slug:$slug,summary:$summary,blocking_finding:$finding}' >>"$TMP/suggestions.jsonl"
}

if [[ "$schema_verdict" != "pass" ]]; then
  codes="$(jq -r '[.errors[]?.code] | unique | join(",")' "$TMP/schema.json")"
  suggest "mission-lock-output-schema" "Backfill mission-lock output schema fields and sidecar JSON until schema validator passes." "schema:${codes:-validator_unavailable}"
fi
if [[ "$scaffold_verdict" == "blocked" ]]; then
  jq -r '.blockers[]?' "$TMP/scaffold.json" | while read -r item; do [[ -n "$item" ]] && printf 'mission-lock-scaffold:%s\n' "$item" >>"$TMP/surfaces.txt"; done
  suggest "mission-lock-scaffold" "Repair required markdown sections, section hashes, substrate pointers, or negative invariants." "scaffold:blocked"
elif [[ "$scaffold_verdict" != "ready" ]]; then
  suggest "mission-lock-scaffold-backfill" "Add section-hash receipts and substrate inventory so legacy mission lock reaches ready." "scaffold:${scaffold_verdict}"
fi
if [[ "$lens_consistent" != "true" ]]; then
  suggest "plan-state-lens-merge" "Repair plan STATE lens merge rows so readiness can trust parallel audit state." "IDEM-004"
fi
jq -r '.checks.blocked_readiness_states[]?' "$TMP/scaffold.json" 2>/dev/null | while read -r item; do [[ -n "$item" ]] && printf 'blocked-readiness:%s\n' "$item" >>"$TMP/surfaces.txt"; done

score="$(python3 - "$schema_verdict" "$scaffold_verdict" "$lens_consistent" <<'PY'
import sys
schema, scaffold, lens = sys.argv[1:]
score = 1.0
if schema == "fail": score -= 0.55
elif schema == "skip": score -= 0.20
if scaffold == "blocked": score -= 0.35
elif scaffold in {"incomplete","skip","fail"}: score -= 0.15
if lens != "true": score -= 0.45
print(f"{max(0.0, min(1.0, score)):.2f}")
PY
)"
surfaces_json="$(jq -R -s -c 'split("\n")[:-1] | unique' "$TMP/surfaces.txt")"
suggestions_json="$(jq -s -c '.' "$TMP/suggestions.jsonl")"
identity_payload="$(jq -nc --arg mission_sha "$(shasum -a 256 "$MISSION_PATH" | awk '{print $1}')" --arg schema "$schema_verdict" --arg scaffold "$scaffold_verdict" --argjson lens "$lens_consistent" --argjson surfaces "$surfaces_json" '{mission_sha:$mission_sha,schema:$schema,scaffold:$scaffold,lens:$lens,surfaces:$surfaces}')"
repair_key="$(printf '%s' "$identity_payload" | shasum -a 256 | awk '{print "sha256:" $1}')"

payload="$(jq -nc \
  --arg version "$VERSION" \
  --arg command "$COMMAND" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg mission "$(cd "$(dirname "$MISSION_PATH")" && pwd -P)/$(basename "$MISSION_PATH")" \
  --arg schema "$schema_verdict" \
  --arg scaffold "$scaffold_verdict" \
  --argjson lens "$lens_consistent" \
  --argjson score "$score" \
  --argjson surfaces "$surfaces_json" \
  --argjson suggestions "$suggestions_json" \
  --arg repair_key "$repair_key" \
  --argjson schema_result "$(cat "$TMP/schema.json")" \
  --argjson scaffold_result "$(cat "$TMP/scaffold.json")" \
  --argjson lens_result "$(cat "$TMP/lens.json")" \
  '{schema_version:$version,command:$command,ts:$ts,mission_md_path:$mission,schema_validator_verdict:$schema,scaffold_validator_verdict:$scaffold,lens_merge_consistent:$lens,mission_lock_readiness_health_score:$score,blocked_surfaces:$surfaces,phase0_scaffold_bead_suggestions:$suggestions,repair_receipt_identity_fields:{repair_idempotency_key:$repair_key,expected_blocked_surfaces_resolved:$surfaces},audit_only:true,upstream_results:{schema:$schema_result,scaffold:$scaffold_result,lens_merge:$lens_result}}')"

if [[ "$QUIET" -eq 0 && "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$payload"
elif [[ "$QUIET" -eq 0 ]]; then
  jq -r '"health=\(.mission_lock_readiness_health_score) schema=\(.schema_validator_verdict) scaffold=\(.scaffold_validator_verdict) lens=\(.lens_merge_consistent)"' <<<"$payload"
fi
[[ "$(jq -r '.mission_lock_readiness_health_score == 1' <<<"$payload")" == true ]]
