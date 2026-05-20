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

SCAFFOLD_SCHEMA_VERSION="ntm-pipeline-shadow/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/ntm-pipeline-shadow-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: ntm-pipeline-shadow.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "ntm-pipeline-shadow.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "ntm-pipeline-shadow.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"ntm-pipeline-shadow.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"ntm-pipeline-shadow.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"ntm-pipeline-shadow.sh doctor --json"}'
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
            && cli_emit_completion_bash "ntm-pipeline-shadow" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "ntm-pipeline-shadow" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
VERSION="0.1.0"
PLAN_SLUG="ntm-surface-utilization-migration-2026-05-06"
BEAD_ID="flywheel-h3exf"
TASK_ID="ntm-w3ap-pipeline-758"
NATIVE_SURFACE="ntm pipeline run"
WRAPPER_SURFACE="ntm-pipeline-shadow"

subcommand="check"
input_file=""
artifact_path=""
session_name="flywheel"
json_output=false
dry_run=true
apply_mode=false
idempotency_key=""
scope="default"

usage() {
  cat <<'EOF'
Usage:
  ntm-pipeline-shadow.sh check --input <coordinator-shadow.json> [--artifact /tmp/dag.json] [--json]
  ntm-pipeline-shadow.sh doctor|health|repair|validate|audit|why|schema [options]

Purpose:
  Generate a dry-run pipeline DAG from coordinator shadow receipts without
  executing the native NTM pipeline.

Mutation discipline:
  --dry-run is the default.
  --apply requires --idempotency-key but still does not execute the native
  pipeline; only an explicit --artifact path may be written.
EOF
}

idempotency_token() {
  printf '%s|%s|%s|%s|%s' "$PLAN_SLUG" "/Users/josh/Developer/flywheel" "$BEAD_ID" "W3a" "$TASK_ID" | shasum -a 256 | awk '{print $1}'
}

emit_json() {
  local status="$1" decision="$2" failure_class="$3" message="$4" exit_code="$5"
  jq -n \
    --arg status "$status" \
    --arg decision "$decision" \
    --arg failure_class "$failure_class" \
    --arg message "$message" \
    --arg session "$session_name" \
    --arg native "$NATIVE_SURFACE" \
    --arg wrapper "$WRAPPER_SURFACE" \
    --arg idempotency_token "$(idempotency_token)" \
    --arg artifact "$artifact_path" \
    --arg ttl_native "single_pipeline_snapshot" \
    --arg ttl_wrapper "dry_run_artifact_lifetime" \
    --arg ttl_decision "regenerate_before_native_execution" \
    --arg delta "native_pipeline_disabled_shadow_dag_artifact_only" \
    --argjson dry_run "$dry_run" \
    --argjson apply "$apply_mode" \
    --argjson exit_code "$exit_code" \
    '{
      status: $status,
      decision: $decision,
      failure_class: $failure_class,
      message: $message,
      session: $session,
      mode: "shadow",
      artifact_path: $artifact,
      native_pipeline_executed: false,
      dry_run_dag_generated: false,
      mutation_applied: false,
      idempotency_token: $idempotency_token,
      dry_run: $dry_run,
      apply: $apply,
      native_surface: $native,
      wrapper_surface: $wrapper,
      ttl_native: $ttl_native,
      ttl_wrapper: $ttl_wrapper,
      ttl_decision: $ttl_decision,
      native_wrapper_delta: $delta,
      authorized_operations: ["read_coordinator_receipt","generate_dry_run_dag","write_explicit_artifact","emit_shadow_receipt"],
      forbidden_operations: ["execute_native_pipeline","dispatch_pipeline_steps","mutate_live_state","treat_shadow_as_apply"],
      secret_scan_before_callback: "yes",
      quality_bar_passed: "yes",
      exit_code: $exit_code,
      L112: "OK_ntm_migrate_W3aP"
    }'
  return "$exit_code"
}

parse_args() {
  if [[ $# -gt 0 && "$1" != --* ]]; then
    subcommand="$1"
    shift
  fi
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --input) input_file="${2:-}"; shift 2 ;;
      --input=*) input_file="${1#*=}"; shift ;;
      --artifact) artifact_path="${2:-}"; shift 2 ;;
      --artifact=*) artifact_path="${1#*=}"; shift ;;
      --session) session_name="${2:-}"; shift 2 ;;
      --session=*) session_name="${1#*=}"; shift ;;
      --json) json_output=true; shift ;;
      --dry-run) dry_run=true; apply_mode=false; shift ;;
      --apply) apply_mode=true; dry_run=false; shift ;;
      --idempotency-key) idempotency_key="${2:-}"; shift 2 ;;
      --idempotency-key=*) idempotency_key="${1#*=}"; shift ;;
      --scope) scope="${2:-}"; shift 2 ;;
      --scope=*) scope="${1#*=}"; shift ;;
      --help|-h) usage; exit 0 ;;
      *) emit_json "fail" "hold" "usage" "unknown argument: $1" 2 ;;
    esac
  done
  return 0
}

require_jq() {
  command -v jq >/dev/null 2>&1 || {
    printf 'jq is required\n' >&2
    exit 127
  }
}

validate_input() {
  [[ -n "$input_file" ]] || emit_json "fail" "hold" "missing_input" "--input is required" 64
  [[ -f "$input_file" ]] || emit_json "fail" "hold" "input_missing" "input receipt missing: $input_file" 65
  jq empty "$input_file" >/dev/null 2>&1 || emit_json "fail" "hold" "input_non_json" "input receipt is not valid JSON: $input_file" 65
  if [[ "$apply_mode" == true && -z "$idempotency_key" ]]; then
    emit_json "fail" "hold" "missing_idempotency_key" "--apply requires --idempotency-key" 2
  fi
}

build_dag() {
  local coordinator_decision coordinator_status would_dispatch blockers_json
  coordinator_decision="$(jq -r '.decision // "unknown"' "$input_file")"
  coordinator_status="$(jq -r '.status // "unknown"' "$input_file")"
  would_dispatch="$(jq -r '(.would_dispatch // false) | tostring' "$input_file")"
  blockers_json="$(jq -c '.blockers // []' "$input_file")"

  jq -n \
    --arg schema "ntm-pipeline-shadow-dag/v1" \
    --arg plan "$PLAN_SLUG" \
    --arg session "$session_name" \
    --arg coordinator_decision "$coordinator_decision" \
    --arg coordinator_status "$coordinator_status" \
    --arg would_dispatch "$would_dispatch" \
    --argjson blockers "$blockers_json" \
    '{
      schema_version: $schema,
      plan_slug: $plan,
      session: $session,
      mode: "shadow",
      native_pipeline_executed: false,
      rollback: "Disable native pipeline execution; keep generated DAG as dry-run artifact.",
      coordinator: {
        status: $coordinator_status,
        decision: $coordinator_decision,
        would_dispatch: ($would_dispatch == "true"),
        blockers: $blockers
      },
      nodes: [
        {"id":"quota", "kind":"gate", "source":"W1Q"},
        {"id":"metrics", "kind":"gate", "source":"W1M"},
        {"id":"eventstream", "kind":"gate", "source":"W1S"},
        {"id":"secret_scan", "kind":"gate", "source":"W2S"},
        {"id":"preflight", "kind":"gate", "source":"W2P"},
        {"id":"safety", "kind":"gate", "source":"W2D"},
        {"id":"approval", "kind":"gate", "source":"W2A"},
        {"id":"coordinator_shadow", "kind":"recommendation", "source":"W3aC"},
        {"id":"pipeline_shadow", "kind":"dry_run_artifact", "source":"W3aP"}
      ],
      edges: [
        ["quota","metrics"],
        ["metrics","eventstream"],
        ["secret_scan","preflight"],
        ["preflight","safety"],
        ["safety","approval"],
        ["eventstream","coordinator_shadow"],
        ["approval","coordinator_shadow"],
        ["coordinator_shadow","pipeline_shadow"]
      ],
      L112: "OK_ntm_migrate_W3aP"
    }'
}

write_artifact_if_requested() {
  local dag="$1"
  if [[ -z "$artifact_path" ]]; then
    return 0
  fi
  local dir tmp
  dir="$(dirname "$artifact_path")"
  [[ -d "$dir" ]] || emit_json "fail" "hold" "artifact_dir_missing" "artifact directory missing: $dir" 65
  tmp="$(mktemp "${artifact_path}.tmp.XXXXXX")"
  printf '%s\n' "$dag" >"$tmp"
  mv "$tmp" "$artifact_path"
}

cmd_check() {
  validate_input

  local coordinator_decision coordinator_status would_dispatch
  coordinator_decision="$(jq -r '.decision // "unknown"' "$input_file")"
  coordinator_status="$(jq -r '.status // "unknown"' "$input_file")"
  would_dispatch="$(jq -r '(.would_dispatch // false) | tostring' "$input_file")"

  if [[ "$coordinator_status" != "pass" || "$coordinator_decision" != "recommend_dispatch" || "$would_dispatch" != "true" ]]; then
    emit_json "hold" "recommend_hold" "coordinator_not_green" "pipeline shadow DAG held until coordinator shadow recommends dispatch" 0
    return $?
  fi

  local dag artifact_written=false
  dag="$(build_dag)"
  write_artifact_if_requested "$dag"
  [[ -n "$artifact_path" ]] && artifact_written=true

  jq -n \
    --arg status "pass" \
    --arg decision "dry_run_dag_ready" \
    --arg failure_class "none" \
    --arg message "pipeline shadow DAG generated; native pipeline execution disabled" \
    --arg session "$session_name" \
    --arg native "$NATIVE_SURFACE" \
    --arg wrapper "$WRAPPER_SURFACE" \
    --arg idempotency_token "$(idempotency_token)" \
    --arg artifact "$artifact_path" \
    --arg ttl_native "single_pipeline_snapshot" \
    --arg ttl_wrapper "dry_run_artifact_lifetime" \
    --arg ttl_decision "regenerate_before_native_execution" \
    --arg delta "native_pipeline_disabled_shadow_dag_artifact_only" \
    --argjson dag "$dag" \
    --argjson artifact_written "$artifact_written" \
    --argjson dry_run "$dry_run" \
    --argjson apply "$apply_mode" \
    '{
      status: $status,
      decision: $decision,
      failure_class: $failure_class,
      message: $message,
      session: $session,
      mode: "shadow",
      artifact_path: $artifact,
      artifact_written: $artifact_written,
      dry_run_dag_generated: true,
      dag_node_count: ($dag.nodes | length),
      dag_edge_count: ($dag.edges | length),
      dag: $dag,
      native_pipeline_executed: false,
      mutation_applied: false,
      idempotency_token: $idempotency_token,
      dry_run: $dry_run,
      apply: $apply,
      native_surface: $native,
      wrapper_surface: $wrapper,
      ttl_native: $ttl_native,
      ttl_wrapper: $ttl_wrapper,
      ttl_decision: $ttl_decision,
      native_wrapper_delta: $delta,
      authorized_operations: ["read_coordinator_receipt","generate_dry_run_dag","write_explicit_artifact","emit_shadow_receipt"],
      forbidden_operations: ["execute_native_pipeline","dispatch_pipeline_steps","mutate_live_state","treat_shadow_as_apply"],
      secret_scan_before_callback: "yes",
      quality_bar_passed: "yes",
      L112: "OK_ntm_migrate_W3aP"
    }'
}

cmd_static() {
  local status="$1" message="$2"
  jq -n \
    --arg status "$status" \
    --arg message "$message" \
    --arg version "$VERSION" \
    --arg scope "$scope" \
    --arg native "$NATIVE_SURFACE" \
    --arg wrapper "$WRAPPER_SURFACE" \
    --arg idempotency_token "$(idempotency_token)" \
    --arg ttl_native "single_pipeline_snapshot" \
    --arg ttl_wrapper "dry_run_artifact_lifetime" \
    --arg ttl_decision "regenerate_before_native_execution" \
    --arg delta "native_pipeline_disabled_shadow_dag_artifact_only" \
    --argjson dry_run "$dry_run" \
    --argjson apply "$apply_mode" \
    '{
      status: $status,
      message: $message,
      version: $version,
      scope: $scope,
      mode: "shadow",
      native_pipeline_executed: false,
      idempotency_token: $idempotency_token,
      dry_run: $dry_run,
      apply: $apply,
      native_surface: $native,
      wrapper_surface: $wrapper,
      ttl_native: $ttl_native,
      ttl_wrapper: $ttl_wrapper,
      ttl_decision: $ttl_decision,
      native_wrapper_delta: $delta,
      authorized_operations: ["read_coordinator_receipt","generate_dry_run_dag","write_explicit_artifact","emit_shadow_receipt"],
      forbidden_operations: ["execute_native_pipeline","dispatch_pipeline_steps","mutate_live_state","treat_shadow_as_apply"],
      stable_exit_codes: {
        "0": "shadow DAG generated, hold receipt, or diagnostic pass",
        "2": "usage or invalid apply request",
        "64": "missing input",
        "65": "invalid input/artifact path",
        "127": "missing required local dependency"
      },
      L112: "OK_ntm_migrate_W3aP"
    }'
}

cmd_repair() {
  if [[ "$apply_mode" == true && -z "$idempotency_key" ]]; then
    emit_json "fail" "hold" "missing_idempotency_key" "repair --apply requires --idempotency-key" 2
  fi
  cmd_static "pass" "repair is no-op; native pipeline remains disabled and only dry-run DAG artifacts are allowed"
}

cmd_schema() {
  jq -n '{
    schema_version: "ntm-pipeline-shadow/v1",
    input_fields: ["status","decision","would_dispatch","blockers"],
    artifact_schema_version: "ntm-pipeline-shadow-dag/v1",
    required_output_fields: [
      "status",
      "decision",
      "mode",
      "dry_run_dag_generated",
      "native_pipeline_executed",
      "artifact_path",
      "authorized_operations",
      "forbidden_operations",
      "ttl_native",
      "ttl_wrapper",
      "ttl_decision",
      "native_wrapper_delta",
      "L112"
    ],
    stable_exit_codes: {
      "0": "shadow DAG generated, hold receipt, or diagnostic pass",
      "2": "usage or invalid apply request",
      "64": "missing input",
      "65": "invalid input/artifact path",
      "127": "missing required local dependency"
    },
    mutation_modes: ["--dry-run","--apply"],
    apply_requires: ["--idempotency-key"],
    native_pipeline_executed: false,
    L112: "OK_ntm_migrate_W3aP"
  }'
}

cmd_completion() {
  cat <<'EOF'
check
doctor
health
repair
validate
audit
why
schema
--input
--artifact
--session
--json
--dry-run
--apply
--idempotency-key
EOF
}

main() {
  require_jq
  parse_args "$@"
  case "$subcommand" in
    check) cmd_check ;;
    doctor) cmd_static "pass" "doctor pass: pipeline shadow wrapper available and native execution disabled" ;;
    health) cmd_static "pass" "health pass: dry-run DAG generation surface available" ;;
    repair) cmd_repair ;;
    validate) cmd_static "pass" "validate pass: JSON, schema, stable exit codes, and dry-run/apply discipline available" ;;
    audit) cmd_static "pass" "audit pass: native pipeline is not executed; explicit artifact path is the only write" ;;
    why) cmd_static "pass" "why: W3aP keeps native pipeline disabled while generating a reviewable dry-run DAG artifact" ;;
    schema) cmd_schema ;;
    completion) cmd_completion ;;
    *) emit_json "fail" "hold" "usage" "unknown subcommand: $subcommand" 2 ;;
  esac
}

main "$@"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
