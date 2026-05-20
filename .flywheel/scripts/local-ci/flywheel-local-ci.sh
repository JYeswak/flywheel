#!/usr/bin/env bash
# shellcheck disable=SC2016
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
POLICY="$ROOT/.flywheel/CI-POLICY.json"
RECEIPT_PATH=""
JSON=0

usage() {
  cat <<'EOF'
usage:
  flywheel-local-ci run [--receipt PATH] [--json]
  flywheel-local-ci doctor [--json]
  flywheel-local-ci health [--json]
  flywheel-local-ci repair --dry-run [--json]
  flywheel-local-ci validate policy [--json]
  flywheel-local-ci audit [--json]
  flywheel-local-ci why local-first-ci [--json]
  flywheel-local-ci --info
  flywheel-local-ci --examples
  flywheel-local-ci quickstart
  flywheel-local-ci help <topic>
  flywheel-local-ci completion <shell>
EOF
}

json_emit() {
  jq -nc "$@"
}

need() {
  command -v "$1" >/dev/null 2>&1
}

now_utc() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

run_gate() {
  local label="$1"
  shift
  local start end status
  start="$(date +%s)"
  if "$@" >/tmp/flywheel-local-ci-last.out 2>&1; then
    status="pass"
  else
    status="fail"
  fi
  end="$(date +%s)"
  jq -nc \
    --arg label "$label" \
    --arg command "$*" \
    --arg status "$status" \
    --argjson elapsed "$((end - start))" \
    '{label:$label,command:$command,status:$status,elapsed_seconds:$elapsed}'
  [[ "$status" == "pass" ]]
}

write_receipt() {
  local receipt="$1"
  if [[ -n "$RECEIPT_PATH" ]]; then
    mkdir -p "$(dirname "$RECEIPT_PATH")"
    printf '%s\n' "$receipt" >"$RECEIPT_PATH"
  fi
}

cmd_run() {
  local gates=()
  local failures=0
  local gate

  gate="$(run_gate bash_syntax bash -n "$ROOT/.flywheel/scripts/local-ci/flywheel-local-ci.sh")" || failures=$((failures + 1))
  gates+=("$gate")
  gate="$(run_gate workflow_contract bash "$ROOT/tests/github-workflows.sh")" || failures=$((failures + 1))
  gates+=("$gate")
  gate="$(run_gate local_ci_policy bash "$ROOT/tests/local-ci-policy.sh")" || failures=$((failures + 1))
  gates+=("$gate")

  local status
  status="pass"
  [[ "$failures" -eq 0 ]] || status="fail"
  local receipt
  receipt="$(
    printf '%s\n' "${gates[@]}" |
      jq -s \
        --arg ts "$(now_utc)" \
        --arg repo "$ROOT" \
        --arg status "$status" \
        --arg policy "$POLICY" \
        '{schema_version:"flywheel.local_ci.receipt.v1",verified_at:$ts,repo:$repo,policy:$policy,status:$status,gates:.}'
  )"
  write_receipt "$receipt"
  if [[ "$JSON" -eq 1 ]]; then
    printf '%s\n' "$receipt"
  else
    jq -r --arg receipt_path "${RECEIPT_PATH:-none}" '"SUMMARY flywheel_local_ci=\(.status) gates=\(.gates|length) receipt=\($receipt_path)"' <<<"$receipt"
  fi
  [[ "$failures" -eq 0 ]]
}

cmd_doctor() {
  local jq_status=fail policy_status=fail workflow_status=fail
  need jq && jq_status=pass
  [[ -s "$POLICY" ]] && jq -e '.schema_version == "flywheel.ci_policy.v1"' "$POLICY" >/dev/null && policy_status=pass
  [[ -d "$ROOT/.github/workflows" ]] && workflow_status=pass
  json_emit \
    --arg jq_status "$jq_status" \
    --arg policy_status "$policy_status" \
    --arg workflow_status "$workflow_status" \
    '{schema_version:"flywheel.local_ci.doctor.v1",status:(if [$jq_status,$policy_status,$workflow_status] | all(. == "pass") then "pass" else "fail" end),checks:{jq:$jq_status,policy:$policy_status,workflows:$workflow_status}}'
}

cmd_health() {
  local receipt="${RECEIPT_PATH:-$ROOT/.flywheel/runtime/local-ci-receipt.json}"
  local status=warn
  [[ -s "$receipt" ]] && status="$(jq -r '.status // "warn"' "$receipt" 2>/dev/null || printf warn)"
  json_emit --arg status "$status" --arg receipt "$receipt" '{schema_version:"flywheel.local_ci.health.v1",status:$status,receipt:$receipt}'
}

cmd_repair() {
  local dry_run=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) dry_run=1 ;;
      --json) JSON=1 ;;
      *) printf 'unknown repair arg: %s\n' "$1" >&2; exit 64 ;;
    esac
    shift
  done
  [[ "$dry_run" -eq 1 ]] || { printf 'repair requires --dry-run\n' >&2; exit 64; }
  json_emit '{schema_version:"flywheel.local_ci.repair.v1",status:"dry_run",actual_actions:[],planned_actions:[]}'
}

cmd_validate() {
  [[ "${1:-}" == "policy" ]] || { printf 'validate subject must be policy\n' >&2; exit 64; }
  bash "$ROOT/tests/local-ci-policy.sh" >/tmp/flywheel-local-ci-last.out 2>&1
  json_emit --arg status "pass" --arg policy "$POLICY" '{schema_version:"flywheel.local_ci.validate.v1",subject:"policy",status:$status,policy:$policy}'
}

cmd_audit() {
  local receipt="${RECEIPT_PATH:-$ROOT/.flywheel/runtime/local-ci-receipt.json}"
  if [[ -s "$receipt" ]]; then
    jq '{schema_version:"flywheel.local_ci.audit.v1",status:"pass",latest:.}' "$receipt"
  else
    json_emit --arg receipt "$receipt" '{schema_version:"flywheel.local_ci.audit.v1",status:"warn",reason:"receipt_missing",receipt:$receipt}'
  fi
}

cmd_why() {
  [[ "${1:-}" == "local-first-ci" ]] || { printf 'unknown why topic: %s\n' "${1:-}" >&2; exit 64; }
  json_emit '{schema_version:"flywheel.local_ci.why.v1",topic:"local-first-ci",reason:"GitHub hosted runners are the last-drop proof surface; branch-tip CI runs locally from CI-POLICY before push."}'
}

cmd_examples() {
  cat <<'EOF'
flywheel-local-ci run --receipt .flywheel/runtime/local-ci-receipt.json
flywheel-local-ci run --json --receipt /tmp/flywheel-local-ci.json
flywheel-local-ci doctor --json
flywheel-local-ci validate policy --json
EOF
}

cmd_quickstart() {
  cat <<'EOF'
1. Edit code.
2. Run: .flywheel/scripts/local-ci/flywheel-local-ci.sh run --receipt .flywheel/runtime/local-ci-receipt.json
3. Push only when the receipt status is pass.
EOF
}

cmd_completion() {
  case "${1:-}" in
    zsh|bash)
      printf 'compctl -k "(run doctor health repair validate audit why quickstart help completion)" flywheel-local-ci\n'
      ;;
    *)
      printf 'unsupported shell: %s\n' "${1:-}" >&2
      exit 64
      ;;
  esac
}

cmd="${1:-run}"
shift || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --receipt)
      RECEIPT_PATH="$2"
      shift 2
      ;;
    --json)
      JSON=1
      shift
      ;;
    *)
      break
      ;;
  esac
done

case "$cmd" in
  run) cmd_run "$@" ;;
  doctor) cmd_doctor "$@" ;;
  health) cmd_health "$@" ;;
  repair) cmd_repair "$@" ;;
  validate) cmd_validate "$@" ;;
  audit) cmd_audit "$@" ;;
  why) cmd_why "$@" ;;
  --info) json_emit --arg root "$ROOT" --arg policy "$POLICY" '{schema_version:"flywheel.local_ci.info.v1",name:"flywheel-local-ci",root:$root,policy:$policy}' ;;
  --examples|examples) cmd_examples ;;
  quickstart) cmd_quickstart ;;
  help) usage ;;
  completion) cmd_completion "$@" ;;
  -h|--help) usage ;;
  *) printf 'unknown command: %s\n' "$cmd" >&2; usage >&2; exit 64 ;;
esac
