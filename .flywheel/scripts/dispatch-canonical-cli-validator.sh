#!/usr/bin/env bash
set -euo pipefail

VERSION="dispatch-canonical-cli-validator/v1"
SCHEMA_VERSION="dispatch-canonical-cli-decision/v1"
LEDGER="${DISPATCH_CANONICAL_CLI_LEDGER:-$HOME/.local/state/flywheel/dispatch-canonical-cli-validator-ledger.jsonl}"
DISPATCH_FILE=""
DISPATCH_STDIN=0
JSON_OUT=0

usage() {
  cat <<'USAGE'
usage:
  dispatch-canonical-cli-validator.sh check --dispatch-file PATH [--json]
  dispatch-canonical-cli-validator.sh check --dispatch-stdin [--json]
  dispatch-canonical-cli-validator.sh --info|--help|--examples [--json]

Validates that dispatch packets introducing CLI surfaces include canonical
CLI scoping acceptance gates before dispatch is sent.

Exit codes:
  0  allow
  1  refuse
  2  usage error or malformed dispatch packet fail-open
USAGE
}

examples() {
  cat <<'EXAMPLES'
dispatch-canonical-cli-validator.sh check --dispatch-file /tmp/dispatch_abc123.md --json
dispatch-canonical-cli-validator.sh check --dispatch-stdin --json < /tmp/dispatch_abc123.md
DISPATCH_CANONICAL_CLI_LEDGER=/tmp/ledger.jsonl dispatch-canonical-cli-validator.sh check --dispatch-file fixture.md
EXAMPLES
}

info() {
  jq -nc \
    --arg name "dispatch-canonical-cli-validator.sh" \
    --arg version "$VERSION" \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg ledger "$LEDGER" \
    '{
      name:$name,
      version:$version,
      schema_version:$schema_version,
      ledger:$ledger,
      purpose:"pre-dispatch canonical-cli-scoping acceptance gate",
      output_schema:".flywheel/validation-schema/v1/dispatch-canonical-cli-decision.schema.json",
      exit_codes:{"0":"allow","1":"refuse","2":"usage or malformed dispatch fail-open"}
    }'
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

fail_usage() {
  printf 'ERR: %s\n' "$1" >&2
  usage >&2
  exit 2
}

append_ledger() {
  local row="$1"
  mkdir -p "$(dirname "$LEDGER")"
  jq -c . <<<"$row" >>"$LEDGER"
}

missing_array_json() {
  if [[ "$#" -eq 0 ]]; then
    printf '[]'
    return 0
  fi
  printf '%s\n' "$@" | jq -R -s -c 'split("\n")[:-1]'
}

emit_decision() {
  local decision="$1" introduces_cli="$2" reason="$3" exit_code="$4"
  shift 4
  local missing_json payload
  missing_json="$(missing_array_json "$@")"
  payload="$(jq -nc \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg ts "$(now_iso)" \
    --arg decision "$decision" \
    --argjson introduces_cli "$introduces_cli" \
    --argjson missing_elements "$missing_json" \
    --arg reason "$reason" \
    --arg ledger "$LEDGER" \
    '{
      schema_version:$schema_version,
      ts:$ts,
      decision:$decision,
      introduces_cli:$introduces_cli,
      missing_elements:$missing_elements,
      reason:$reason,
      ledger_appended:$ledger
    }')"
  append_ledger "$payload" || true
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    jq -r '"decision=\(.decision) introduces_cli=\(.introduces_cli) reason=\(.reason) missing=\(.missing_elements|join(","))"' <<<"$payload"
  fi
  exit "$exit_code"
}

contains_ci() {
  grep -Eiq "$1" <<<"$2"
}

has_markdown_shape() {
  [[ "${#1}" -ge 20 ]] && grep -Eq '^#{1,6}[[:space:]]+' <<<"$1"
}

introduces_cli_surface() {
  local text="$1"
  if contains_ci '(^|[[:space:]`"])\.flywheel/scripts/[^[:space:]`")]+\.sh' "$text"; then
    return 0
  fi
  if contains_ci '(^|[[:space:]])--(info|help|examples|json)([[:space:]|,`.)]|$)' "$text"; then
    return 0
  fi
  if contains_ci '\b(CLI|command|flag|subcommand|operator-facing tool)\b' "$text"; then
    return 0
  fi
  return 1
}

has_info_help_examples() {
  local text="$1"
  if grep -Fq -- '--info|--help|--examples' <<<"$text"; then
    return 0
  fi
  grep -Fq -- '--info' <<<"$text" \
    && grep -Fq -- '--help' <<<"$text" \
    && grep -Fq -- '--examples' <<<"$text"
}

has_json_output() {
  local text="$1"
  grep -Fq -- '--json' <<<"$text" \
    && contains_ci '(json output|output[^[:alpha:]]+.*--json|--json.*output|machine-readable)' "$text"
}

has_exit_codes() {
  local text="$1"
  if contains_ci '(canonical-cli-scoping.*exit codes stable|exit codes stable.*canonical-cli-scoping)' "$text"; then
    return 0
  fi
  contains_ci 'exit[- ]codes?' "$text" \
    && contains_ci '(^|[^0-9])0[[:space:]]*[:=]' "$text" \
    && contains_ci '(^|[^0-9])1[[:space:]]*[:=]' "$text" \
    && contains_ci '(^|[^0-9])2[[:space:]]*[:=]' "$text"
}

has_canonical_skill() {
  local text="$1"
  grep -Fqi -- 'canonical-cli-scoping' <<<"$text" \
    && contains_ci '(skill|SKILL\.md|skills consulted|acceptance gate)' "$text"
}

run_check() {
  local body missing=()
  if [[ -n "$DISPATCH_FILE" ]]; then
    [[ -r "$DISPATCH_FILE" ]] || fail_usage "dispatch file not readable: $DISPATCH_FILE"
    body="$(<"$DISPATCH_FILE")"
  elif [[ "$DISPATCH_STDIN" -eq 1 ]]; then
    body="$(cat)"
  else
    fail_usage "check requires --dispatch-file or --dispatch-stdin"
  fi

  if ! has_markdown_shape "$body"; then
    emit_decision "allow" "false" "malformed_dispatch_packet_fail_open" 2
  fi

  if ! introduces_cli_surface "$body"; then
    emit_decision "allow" "false" "not_introducing_cli" 0
  fi

  has_info_help_examples "$body" || missing+=("info_help_examples")
  has_json_output "$body" || missing+=("json")
  has_exit_codes "$body" || missing+=("exit_codes")
  has_canonical_skill "$body" || missing+=("canonical_cli_skill")

  if [[ "${#missing[@]}" -eq 0 ]]; then
    emit_decision "allow" "true" "canonical_cli_acceptance_present" 0
  fi
  emit_decision "refuse" "true" "dispatch_packet_missing_canonical_cli_acceptance" 1 "${missing[@]}"
}

if [[ "$#" -eq 0 ]]; then
  fail_usage "missing command"
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    check) shift ;;
    --dispatch-file) DISPATCH_FILE="${2:-}"; shift 2 ;;
    --dispatch-file=*) DISPATCH_FILE="${1#*=}"; shift ;;
    --dispatch-stdin) DISPATCH_STDIN=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) fail_usage "unknown argument: $1" ;;
  esac
done

[[ "$DISPATCH_STDIN" -eq 0 || -z "$DISPATCH_FILE" ]] || fail_usage "use either --dispatch-file or --dispatch-stdin"
run_check
