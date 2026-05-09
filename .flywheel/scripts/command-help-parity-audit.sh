#!/usr/bin/env bash
set -euo pipefail

COMMAND_DIR="${COMMAND_DIR:-$HOME/.claude/commands/flywheel}"
CODEX_AGENTS="${CODEX_AGENTS:-$HOME/.codex/AGENTS.md}"
JSON_OUT=0
DOCTOR_MODE=0
MODE="audit"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --command-dir) COMMAND_DIR="$2"; shift 2 ;;
    --codex-agents) CODEX_AGENTS="$2"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --doctor) DOCTOR_MODE=1; shift ;;
    parity-fixture) MODE="parity-fixture"; shift ;;
    -h|--help)
      cat <<'HELP'
usage: command-help-parity-audit.sh [--command-dir DIR] [--codex-agents FILE] [--doctor] [--json]
       command-help-parity-audit.sh parity-fixture [--json]
HELP
      exit 0 ;;
    *) echo "ERR unknown argument: $1" >&2; exit 2 ;;
  esac
done

commands=(loop cron tick worker-tick deep-audit adopt)
required_doc_terms=("--help" "--help-long" "--help-best-for" "## Codex equivalent" "## SEE ALSO")
required_codex_terms=(
  "flywheel-loop tick --repo"
  "flywheel-loop tick --worker-mode"
  "flywheel-loop doctor --repo"
  "flywheel-adopt.sh --repo"
  "flywheel-cron.sh register"
)
tick_receipt_fields=("mode" "checks_run" "violations" "dispatch_status" "hold_reason" "decision" "action" "receipt")

json_array() {
  jq -R . | jq -s -c .
}

parity_fixture_json() {
  local fields_json
  fields_json="$(printf '%s\n' "${tick_receipt_fields[@]}" | json_array)"
  jq -nc --argjson fields "$fields_json" '{
    schema_version:"flywheel-command-parity-fixture/v1",
    command:"tick",
    status:"pass",
    claude:{invocation:"/flywheel:tick --dry-run", receipt_fields:$fields},
    codex:{invocation:"/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop tick --repo \"$PWD\" --dry-run --json", receipt_fields:$fields},
    equivalent_receipt_fields:true
  }'
}

audit_json() {
  local rows='[]' errors='[]' warnings='[]' matrix="$COMMAND_DIR/COMMAND-MATRIX.md"
  local command path term missing_terms row codex_missing='[]' parity

  for command in "${commands[@]}"; do
    path="$COMMAND_DIR/$command.md"
    missing_terms='[]'
    if [[ ! -f "$path" ]]; then
      missing_terms="$(jq -nc --arg term "file" '[$term]')"
    else
      for term in "${required_doc_terms[@]}"; do
        if ! rg -q -F -- "$term" "$path"; then
          missing_terms="$(jq -c --arg term "$term" '. + [$term]' <<<"$missing_terms")"
        fi
      done
    fi
    row="$(jq -nc --arg command "$command" --arg path "$path" --argjson missing "$missing_terms" '{
      command:$command,
      path:$path,
      status:(if ($missing|length)==0 then "pass" else "fail" end),
      missing:$missing
    }')"
    rows="$(jq -c --argjson row "$row" '. + [$row]' <<<"$rows")"
  done

  if [[ ! -f "$matrix" ]]; then
    errors="$(jq -c --arg path "$matrix" '. + [{code:"command_matrix_missing", path:$path}]' <<<"$errors")"
  else
    for command in "${commands[@]}"; do
      if ! rg -q -F -- "/flywheel:$command" "$matrix"; then
        errors="$(jq -c --arg command "$command" '. + [{code:"command_matrix_missing_command", command:$command}]' <<<"$errors")"
      fi
    done
  fi

  if [[ ! -f "$CODEX_AGENTS" ]]; then
    errors="$(jq -c --arg path "$CODEX_AGENTS" '. + [{code:"codex_agents_missing", path:$path}]' <<<"$errors")"
  else
    for term in "${required_codex_terms[@]}"; do
      if ! rg -q -F -- "$term" "$CODEX_AGENTS"; then
        codex_missing="$(jq -c --arg term "$term" '. + [$term]' <<<"$codex_missing")"
      fi
    done
  fi

  parity="$(parity_fixture_json)"

  jq -nc \
    --arg schema_version "flywheel-command-help-parity-audit/v1" \
    --arg command_dir "$COMMAND_DIR" \
    --arg codex_agents "$CODEX_AGENTS" \
    --arg matrix "$matrix" \
    --argjson rows "$rows" \
    --argjson errors "$errors" \
    --argjson warnings "$warnings" \
    --argjson codex_missing "$codex_missing" \
    --argjson parity "$parity" '
      ($rows | map(select(.status != "pass"))) as $failed
      | ($errors
          + ($failed | map({code:"command_help_sections_missing", command:.command, missing:.missing, path:.path}))
          + (if ($codex_missing|length)>0 then [{code:"codex_equivalents_missing", missing:$codex_missing, path:$codex_agents}] else [] end)
          + (if ($parity.equivalent_receipt_fields == true) then [] else [{code:"tick_parity_fixture_failed"}] end)
        ) as $all_errors
      | {
          schema_version:$schema_version,
          command:"command-help-parity-audit",
          doctor_scope:"command-help-parity",
          status:(if ($all_errors|length)==0 then "pass" else "fail" end),
          command_dir:$command_dir,
          codex_agents:$codex_agents,
          command_matrix:$matrix,
          commands:$rows,
          codex_missing:$codex_missing,
          parity_fixture:$parity,
          errors:$all_errors,
          warnings:$warnings
        }'
}

if [[ "$MODE" == "parity-fixture" ]]; then
  parity_fixture_json
  exit 0
fi

payload="$(audit_json)"
if [[ "$JSON_OUT" -eq 1 || "$DOCTOR_MODE" -eq 1 ]]; then
  printf '%s\n' "$payload"
else
  jq -r '"command-help-parity " + .status + " commands=" + ((.commands|length)|tostring) + " errors=" + ((.errors|length)|tostring)' <<<"$payload"
fi

[[ "$(jq -r '.status' <<<"$payload")" == "pass" ]]
