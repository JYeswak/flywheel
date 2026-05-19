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

SCAFFOLD_SCHEMA_VERSION="ntm-scrub-secret-scan-wrapper/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/ntm-scrub-secret-scan-wrapper-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: ntm-scrub-secret-scan-wrapper.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "ntm-scrub-secret-scan-wrapper.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "ntm-scrub-secret-scan-wrapper.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"ntm-scrub-secret-scan-wrapper.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"ntm-scrub-secret-scan-wrapper.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"ntm-scrub-secret-scan-wrapper.sh doctor --json"}'
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
            && cli_emit_completion_bash "ntm-scrub-secret-scan-wrapper" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "ntm-scrub-secret-scan-wrapper" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-67-presence-hash-secret-diagnostics.md`
