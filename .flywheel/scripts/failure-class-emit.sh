#!/usr/bin/env bash
set -euo pipefail

VERSION="failure-class-emit 1.0.0"
SCHEMA_VERSION="failure-taxonomy-envelope/v1"
DOC_PATH=".flywheel/doctrine/failure-taxonomy.md"

usage() {
  cat <<'EOF'
Usage:
  failure-class-emit.sh classify --raw <failure-shape> [--source <surface>] [--json]
  failure-class-emit.sh --raw <failure-shape> [--source <surface>] [--json]
  failure-class-emit.sh --info
  failure-class-emit.sh --examples
  failure-class-emit.sh quickstart
  failure-class-emit.sh schema
  failure-class-emit.sh help taxonomy
  failure-class-emit.sh completion <bash|zsh>

Classifies legacy flywheel failure strings into failure_class, retry_policy,
and recovery_hint JSON fields.
EOF
}

emit_info() {
  jq -nc \
    --arg version "$VERSION" \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg doc_path "$DOC_PATH" \
    '{tool:$version,schema_version:$schema_version,doc_path:$doc_path,default_output:"json",mutates:false}'
}

emit_examples() {
  cat <<'EOF'
Examples:
  .flywheel/scripts/failure-class-emit.sh --raw 'validator_verdict=BLOCK_CLOSE_open_child_wbnb'
  .flywheel/scripts/failure-class-emit.sh classify --raw 'dcg_block_handled=redirect_truncate_varfolders'
  .flywheel/scripts/failure-class-emit.sh --raw 'bead_close_blocked_by=.beads_reservation_conflict_PurpleMeadow'
EOF
}

emit_schema() {
  jq -nc \
    --arg schema_version "$SCHEMA_VERSION" \
    '{schema_version:$schema_version,required:["schema_version","raw_failure","failure_class","retry_policy","recovery_hint","reason_code","matched_alias"],retry_policy_enum:["none","exponential","manual","permanent"],failure_class_enum:["transient","persistent","correctness","missing_artifact","invalid_callback","context_drift","gate_unmet_open_children","dcg_blocked_destructive_command","file_reservation_conflict","unknown"]}'
}

emit_completion() {
  local shell_name="$1"
  case "$shell_name" in
    bash)
      cat <<'EOF'
_failure_class_emit() {
  COMPREPLY=($(compgen -W "--raw --source --json --info --examples quickstart schema classify help completion" -- "${COMP_WORDS[COMP_CWORD]}"))
}
complete -F _failure_class_emit failure-class-emit.sh
EOF
      ;;
    zsh)
      cat <<'EOF'
#compdef failure-class-emit.sh
_arguments \
  '--raw[raw failure shape]:raw:' \
  '--source[source surface]:source:' \
  '--json[emit JSON]' \
  '--info[tool info]' \
  '--examples[examples]' \
  '1:command:(classify quickstart schema help completion)'
EOF
      ;;
    *)
      printf 'unsupported shell: %s\n' "$shell_name" >&2
      return 2
      ;;
  esac
}

classify_raw() {
  local raw="$1"
  local normalized
  normalized="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')"

  local failure_class retry_policy recovery_hint reason_code matched_alias

  case "$normalized" in
    *block_close_open_child*|*block_close_open_children*|*open_child_blocks_close*|*open_child_*)
      failure_class="gate_unmet_open_children"
      retry_policy="none"
      recovery_hint="Close or explicitly preserve the named child blocker before retrying parent close."
      reason_code="open_child_blocks_close"
      matched_alias="block_close_open_child"
      ;;
    *dcg_block*|*redirect_truncate_*)
      failure_class="dcg_blocked_destructive_command"
      retry_policy="manual"
      recovery_hint="Read the DCG reason and use a non-destructive alternate command; do not retry the same blocked command."
      reason_code="destructive_command_blocked"
      matched_alias="dcg_block_or_redirect"
      ;;
    *file_reservation_conflict*|*shared_append_reservation_conflict*|*append_reservation_conflict*|*.beads_reservation_conflict_*)
      failure_class="file_reservation_conflict"
      retry_policy="manual"
      recovery_hint="Coordinate with the active reservation holder, wait for lease expiry, or release the stale reservation before writing."
      reason_code="reservation_conflict"
      matched_alias="reservation_conflict"
      ;;
    *runtime_unresponsive*|*test_timeout*|*doctor_timeout*|*timeout*)
      failure_class="transient"
      retry_policy="exponential"
      recovery_hint="Rerun the bounded probe once; if it repeats, promote to persistent with the timeout source attached."
      reason_code="runtime_timeout"
      matched_alias="runtime_timeout"
      ;;
    *artifact_missing*|*missing_artifact*|*evidence_missing*|*closed_bead_artifact_missing_count*)
      failure_class="missing_artifact"
      retry_policy="manual"
      recovery_hint="Restore or regenerate the referenced evidence artifact, then rerun validation with the same evidence path."
      reason_code="artifact_missing"
      matched_alias="artifact_or_evidence_missing"
      ;;
    *invalid_callback*|*callback_malformed*|*missing_did_didnt_gaps*|*orch_callback_missing_l61_fields*|*remediation_missing*)
      failure_class="invalid_callback"
      retry_policy="manual"
      recovery_hint="Resend a callback with the required numeric fields, evidence, and durable no-bead/bead routing receipt."
      reason_code="callback_contract_invalid"
      matched_alias="callback_contract_invalid"
      ;;
    *context_drift*|*agent_context_probe_drift_count*)
      failure_class="context_drift"
      retry_policy="manual"
      recovery_hint="Reprobe from both orchestrator and agent contexts; do not summarize until the contexts agree or the drift is named."
      reason_code="context_drift"
      matched_alias="context_drift"
      ;;
    *test_failed*|*assertion_failed*|*l112_verify_failed*|*dependency_inversion*|*cycle_detected*)
      failure_class="correctness"
      retry_policy="permanent"
      recovery_hint="Fix the implementation, dependency graph, or failing assertion before retry; do not silence or ignore."
      reason_code="correctness_regression"
      matched_alias="correctness_or_dependency"
      ;;
    *database_locked*|*schema_mismatch*|*io_error*)
      failure_class="persistent"
      retry_policy="manual"
      recovery_hint="Repair the persistent substrate condition, then rerun the validator from the same receipt."
      reason_code="persistent_substrate"
      matched_alias="persistent_substrate"
      ;;
    *)
      failure_class="unknown"
      retry_policy="manual"
      recovery_hint="Preserve the raw failure string, add a taxonomy alias or new migration-tested class, then rerun classification."
      reason_code="unknown"
      matched_alias="unknown"
      ;;
  esac

  jq -nc \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg raw_failure "$raw" \
    --arg failure_class "$failure_class" \
    --arg retry_policy "$retry_policy" \
    --arg recovery_hint "$recovery_hint" \
    --arg reason_code "$reason_code" \
    --arg matched_alias "$matched_alias" \
    --arg taxonomy_doc "$DOC_PATH" \
    '{schema_version:$schema_version,raw_failure:$raw_failure,failure_class:$failure_class,retry_policy:$retry_policy,recovery_hint:$recovery_hint,reason_code:$reason_code,matched_alias:$matched_alias,taxonomy_doc:$taxonomy_doc}'
}

main() {
  local raw="" source_surface="" command="classify"

  if [[ "$#" -eq 0 ]]; then
    usage >&2
    return 2
  fi

  case "${1:-}" in
    --help|-h)
      usage
      return 0
      ;;
    --version)
      printf '%s\n' "$VERSION"
      return 0
      ;;
    --info)
      emit_info
      return 0
      ;;
    --examples)
      emit_examples
      return 0
      ;;
    quickstart)
      usage
      printf '\n'
      emit_examples
      return 0
      ;;
    schema)
      emit_schema
      return 0
      ;;
    help)
      if [[ "${2:-}" == "taxonomy" ]]; then
        printf 'Taxonomy doc: %s\n' "$DOC_PATH"
        emit_schema
        return 0
      fi
      usage >&2
      return 2
      ;;
    completion)
      emit_completion "${2:-}"
      return $?
      ;;
    classify)
      command="classify"
      shift
      ;;
  esac

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --raw)
        raw="${2:-}"
        shift 2
        ;;
      --source)
        source_surface="${2:-}"
        shift 2
        ;;
      --json)
        shift
        ;;
      *)
        printf 'unknown argument: %s\n' "$1" >&2
        return 2
        ;;
    esac
  done

  if [[ "$command" != "classify" ]]; then
    usage >&2
    return 2
  fi

  if [[ -z "$raw" ]] && [[ ! -t 0 ]]; then
    raw="$(cat)"
  fi
  if [[ -z "${raw// }" ]]; then
    printf 'missing required --raw failure shape\n' >&2
    return 2
  fi

  if [[ -n "$source_surface" ]]; then
    classify_raw "$raw" | jq --arg source "$source_surface" '. + {source:$source}'
  else
    classify_raw "$raw"
  fi
}

main "$@"
