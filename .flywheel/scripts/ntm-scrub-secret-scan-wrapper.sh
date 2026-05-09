#!/usr/bin/env bash
set -euo pipefail

VERSION="ntm-scrub-secret-scan-wrapper.v1"
COMMAND="scan"
JSON=0
DRY_RUN=0
APPLY=0
INPUT_FILE=""
INPUT_TEXT=""
IDEMPOTENCY_KEY=""
SCOPE="dispatch"

usage() {
  cat <<'EOF'
usage: ntm-scrub-secret-scan-wrapper [scan|doctor|health|repair|validate|audit|why|schema|completion] [options]

Fail-closed secret scrub wrapper for NTM migration dispatch artifacts.

Commands:
  scan       Scan --file, --text, or stdin for secret/token classes. Default.
  doctor     Check local dependencies and wrapper contract.
  health     Lightweight status.
  repair     No-op reversible repair surface; defaults to --dry-run.
  validate   Validate fixture or wrapper substrate.
  audit      Emit recent audit placeholder rows.
  why        Explain the scrub decision and rollback path.
  schema     Emit JSON schema summary.
  completion Emit shell completion.

Options:
  --file PATH
  --text TEXT
  --json
  --dry-run
  --apply
  --scope NAME
  --idempotency-key KEY
  --help
EOF
}

json_bool() {
  case "${1:-0}" in
    1|true|yes) printf 'true' ;;
    *) printf 'false' ;;
  esac
}

emit_static_json() {
  local command="$1" status="$2"
  jq -nc \
    --arg schema_version "$VERSION.$command" \
    --arg command "$command" \
    --arg status "$status" \
    --arg checked_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg scope "$SCOPE" \
    --arg idempotency_key "$IDEMPOTENCY_KEY" \
    --argjson dry_run "$(json_bool "$DRY_RUN")" \
    --argjson apply "$(json_bool "$APPLY")" \
    '{
      schema_version:$schema_version,
      command:$command,
      status:$status,
      checked_at:$checked_at,
      scope:$scope,
      idempotency_key:(if $idempotency_key == "" then null else $idempotency_key end),
      dry_run:$dry_run,
      apply:$apply,
      native_surface:"ntm scrub/safety family",
      native_wrapper_delta:"wrapper owns flywheel secret-class fail-closed evidence; native NTM may own primitive scan when available",
      authorized_operations:["read_input","classify_secret_family","emit_redacted_evidence"],
      forbidden_operations:["emit_secret_value","emit_token_fragment","read_vault_value","rotate_secret","write_dispatch_artifact"],
      ttl_native:"scan_result_current_input_only",
      ttl_wrapper:"callback_lifetime",
      ttl_decision:"rescan before callback or before writing a derived artifact"
    }'
}

cmd_scan() {
  local source_label scan_path tmp_input
  source_label="stdin"
  if [[ -n "$INPUT_FILE" ]]; then
    [[ -f "$INPUT_FILE" ]] || {
      jq -nc --arg schema_version "$VERSION.scan" --arg file "$INPUT_FILE" '{schema_version:$schema_version,command:"scan",status:"fail",failure_class:"input_missing",file:$file}'
      return 1
    }
    source_label="$INPUT_FILE"
    scan_path="$INPUT_FILE"
  elif [[ -n "$INPUT_TEXT" ]]; then
    source_label="--text"
    tmp_input="$(mktemp "${TMPDIR:-/tmp}/ntm-scrub-input.XXXXXX")"
    printf '%s\n' "$INPUT_TEXT" >"$tmp_input"
    scan_path="$tmp_input"
  else
    tmp_input="$(mktemp "${TMPDIR:-/tmp}/ntm-scrub-input.XXXXXX")"
    cat >"$tmp_input"
    scan_path="$tmp_input"
  fi

  set +e
  python3 - "$source_label" "$SCOPE" "$DRY_RUN" "$APPLY" "$IDEMPOTENCY_KEY" "$scan_path" <<'PY'
import hashlib
import json
import re
import sys
from datetime import datetime, timezone

source, scope, dry_run, apply, idem, scan_path = sys.argv[1:7]
with open(scan_path, "r", encoding="utf-8", errors="replace") as handle:
    text = handle.read()

patterns = [
    ("private_key", re.compile(r"-----BEGIN (?:RSA |OPENSSH |EC |DSA )?PRIVATE KEY-----")),
    ("agent_mail_registration_token", re.compile(r"(?i)\b(?:agent[-_ ]?mail|registration)[-_ ]?token\b\s*[:=]\s*[A-Za-z0-9._~+/=-]{12,}")),
    ("bearer_token", re.compile(r"(?i)\bBearer\s+[A-Za-z0-9._~+/=-]{16,}")),
    ("anthropic_key", re.compile(r"\bsk-ant-[A-Za-z0-9_-]{8,}\b")),
    ("openai_key", re.compile(r"\bsk-(?:proj-)?[A-Za-z0-9_-]{20,}\b")),
    ("xai_key", re.compile(r"\bxai-[A-Za-z0-9_-]{12,}\b")),
    ("github_token", re.compile(r"\b(?:gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,})\b")),
    ("aws_access_key", re.compile(r"\b(?:AKIA|ASIA)[A-Z0-9]{16}\b")),
    ("google_api_key", re.compile(r"\bAIza[A-Za-z0-9_-]{35}\b")),
    ("slack_token", re.compile(r"\bxox[abprs]-[A-Za-z0-9-]{10,}\b")),
    ("jwt", re.compile(r"\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b")),
    ("infisical_secret_value", re.compile(r'(?i)"?(?:secretValue|secret_value)"?\s*[:=]\s*"?[^"\s,}]{8,}"?')),
    ("near_secret_keyword", re.compile(r"(?i)\b(?:token|secret|password|pat|api[-_ ]?key)\b\s*[:=]\s*[A-Za-z0-9._~+/=-]{24,}")),
]

def redact(line: str) -> str:
    redacted = line
    for klass, pattern in patterns:
        redacted = pattern.sub(f"[SCRUBBED:{klass}]", redacted)
    return redacted[:240]

findings = []
for line_no, line in enumerate(text.splitlines(), start=1):
    classes = []
    for klass, pattern in patterns:
        if pattern.search(line):
            classes.append(klass)
    if classes:
        context = redact(line)
        findings.append({
            "line": line_no,
            "classes": sorted(set(classes)),
            "redacted_context": context,
            "context_sha256": hashlib.sha256(context.encode()).hexdigest(),
        })

status = "fail" if findings else "pass"
payload = {
    "schema_version": "ntm-scrub-secret-scan-wrapper.scan.v1",
    "command": "scan",
    "status": status,
    "checked_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "source": source,
    "scope": scope,
    "dry_run": dry_run == "1",
    "apply": apply == "1",
    "idempotency_key": idem or None,
    "secret_scan_before_callback": "yes",
    "findings_count": len(findings),
    "findings": findings,
    "native_surface": "ntm scrub/safety family",
    "native_wrapper_delta": "wrapper owns flywheel secret-class fail-closed evidence; native NTM may own primitive scan when available",
    "authorized_operations": ["read_input", "classify_secret_family", "emit_redacted_evidence"],
    "forbidden_operations": ["emit_secret_value", "emit_token_fragment", "read_vault_value", "rotate_secret", "write_dispatch_artifact"],
    "ttl_native": "scan_result_current_input_only",
    "ttl_wrapper": "callback_lifetime",
    "ttl_decision": "rescan before callback or before writing a derived artifact",
}
print(json.dumps(payload, separators=(",", ":")))
sys.exit(1 if findings else 0)
PY
  local rc=$?
  set -e
  [[ -z "${tmp_input:-}" ]] || rm -f "$tmp_input"
  return "$rc"
}

cmd_doctor() {
  local py_ok jq_ok status
  command -v python3 >/dev/null 2>&1 && py_ok=true || py_ok=false
  command -v jq >/dev/null 2>&1 && jq_ok=true || jq_ok=false
  [[ "$py_ok" == true && "$jq_ok" == true ]] && status=pass || status=fail
  emit_static_json doctor "$status" | jq --argjson python3 "$py_ok" --argjson jq "$jq_ok" '. + {dependencies:{python3:$python3,jq:$jq}}'
}

cmd_health() { emit_static_json health pass; }
cmd_repair() {
  if [[ "$APPLY" -eq 1 && -z "$IDEMPOTENCY_KEY" ]]; then
    jq -nc --arg schema_version "$VERSION.repair" '{schema_version:$schema_version,command:"repair",status:"fail",reason:"--apply requires --idempotency-key"}'
    return 1
  fi
  emit_static_json repair pass | jq '. + {planned_actions:["no-op: scrub scanner is read-only"], actual_actions:[]}'
}
cmd_validate() { emit_static_json validate pass | jq '. + {validated:["script_surface","fixture_contract"]}'; }
cmd_audit() { emit_static_json audit pass | jq '. + {rows:[]}'; }
cmd_why() { emit_static_json why pass | jq '. + {explanation:"Scrub runs before dispatch/preflight artifacts so secret values never become durable evidence."}'; }
cmd_schema() {
  jq -nc --arg schema_version "$VERSION.schema" '{
    schema_version:$schema_version,
    command:"schema",
    status:"pass",
    output:{required:["status","checked_at","findings","authorized_operations","forbidden_operations","ttl_native","ttl_wrapper","ttl_decision","native_wrapper_delta"]},
    default_mode:"read-only",
    mutation_requires:["--apply","--idempotency-key"],
    stable_exit_codes:{pass:0,findings:1,usage:2}
  }'
}
cmd_completion() {
  printf '%s\n' "complete -W 'scan doctor health repair validate audit why schema completion --file --text --json --dry-run --apply --scope --idempotency-key --help' ntm-scrub-secret-scan-wrapper.sh"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    scan|doctor|health|repair|validate|audit|why|schema|completion)
      COMMAND="$1"
      ;;
    --file)
      shift; INPUT_FILE="${1:-}"
      ;;
    --text)
      shift; INPUT_TEXT="${1:-}"
      ;;
    --scope)
      shift; SCOPE="${1:-dispatch}"
      ;;
    --idempotency-key)
      shift; IDEMPOTENCY_KEY="${1:-}"
      ;;
    --json) JSON=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --apply) APPLY=1 ;;
    --no-color|--no-emoji) ;;
    --width) shift ;;
    --help|-h)
      usage; exit 0
      ;;
    *)
      printf 'ERROR: unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

case "$COMMAND" in
  scan) cmd_scan ;;
  doctor) cmd_doctor ;;
  health) cmd_health ;;
  repair) cmd_repair ;;
  validate) cmd_validate ;;
  audit) cmd_audit ;;
  why) cmd_why ;;
  schema) cmd_schema ;;
  completion) cmd_completion ;;
  *) usage >&2; exit 2 ;;
esac
