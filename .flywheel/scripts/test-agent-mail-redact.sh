#!/usr/bin/env bash
# Synthetic regression test for agent-mail-send-redacted.sh.
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

SCAFFOLD_SCHEMA_VERSION="test-agent-mail-redact/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/test-agent-mail-redact-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: test-agent-mail-redact.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "test-agent-mail-redact.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "test-agent-mail-redact.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"test-agent-mail-redact.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"test-agent-mail-redact.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"test-agent-mail-redact.sh doctor --json"}'
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
            && cli_emit_completion_bash "test-agent-mail-redact" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "test-agent-mail-redact" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
ROOT="/Users/josh/Developer/flywheel"
WRAPPER="$ROOT/.flywheel/scripts/agent-mail-send-redacted.sh"
FAKE_TOKEN="FAKE_AGENT_MAIL_TOKEN_1234567890"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/agent-mail-redact-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

VAULT="$TMP/vault"
CAPTURE="$TMP/capture"
REGISTER_CAPTURE="$TMP/register-capture"
STDOUT="$TMP/stdout.txt"
STDERR="$TMP/stderr.txt"

mkdir -p "$VAULT"
chmod 700 "$VAULT"
printf '%s' "$FAKE_TOKEN" >"$VAULT/SyntheticAgent.token"
chmod 600 "$VAULT/SyntheticAgent.token"

AGENT_MAIL_TOKEN_VAULT_DIR="$VAULT" "$WRAPPER" send_message \
  --project-key "/tmp/synthetic-agent-mail-project" \
  --sender-name "SyntheticAgent" \
  --to "SyntheticRecipient" \
  --subject "Synthetic redaction test" \
  --body "Synthetic body with no credential material" \
  --sender-token-handle "vault:SyntheticAgent" \
  --capture-dir "$CAPTURE" \
  --dry-run >"$STDOUT" 2>"$STDERR"

for file in "$CAPTURE/dispatch.txt" "$CAPTURE/wrapper.log" "$CAPTURE/pane-visible-tool-call-args.json" "$STDOUT" "$STDERR"; do
  if [[ ! -f "$file" ]]; then
    printf 'FAIL: missing capture file: %s\n' "$file" >&2
    exit 1
  fi
  if grep -Fq "$FAKE_TOKEN" "$file"; then
    printf 'FAIL: synthetic token appeared in %s\n' "$file" >&2
    exit 1
  fi
done

if ! grep -Fq '[REDACTED]' "$CAPTURE/pane-visible-tool-call-args.json"; then
  printf 'FAIL: pane-visible args did not include redacted token marker\n' >&2
  exit 1
fi

AGENT_MAIL_TOKEN_VAULT_DIR="$VAULT" "$WRAPPER" register_agent \
  --project-key "/tmp/synthetic-agent-mail-project" \
  --agent-name "SyntheticAgent" \
  --program "synthetic" \
  --model "synthetic-model" \
  --task-description "Synthetic registration redaction test" \
  --registration-token-handle "vault:SyntheticAgent" \
  --capture-dir "$REGISTER_CAPTURE" \
  --dry-run >"$TMP/register-stdout.txt" 2>"$TMP/register-stderr.txt"

for file in "$REGISTER_CAPTURE/dispatch.txt" "$REGISTER_CAPTURE/wrapper.log" "$REGISTER_CAPTURE/pane-visible-tool-call-args.json" "$TMP/register-stdout.txt" "$TMP/register-stderr.txt"; do
  if [[ ! -f "$file" ]]; then
    printf 'FAIL: missing register capture file: %s\n' "$file" >&2
    exit 1
  fi
  if grep -Fq "$FAKE_TOKEN" "$file"; then
    printf 'FAIL: synthetic token appeared in %s\n' "$file" >&2
    exit 1
  fi
done

if ! grep -Fq '[REDACTED]' "$REGISTER_CAPTURE/pane-visible-tool-call-args.json"; then
  printf 'FAIL: register pane-visible args did not include redacted token marker\n' >&2
  exit 1
fi

FAIL_TMPDIR="$TMP/failtmp"
FAKE_NTM="$TMP/failing-ntm"
mkdir -p "$FAIL_TMPDIR"
cat >"$FAKE_NTM" <<'SH'
#!/usr/bin/env bash
exit 7
SH
chmod +x "$FAKE_NTM"

if TMPDIR="$FAIL_TMPDIR" AGENT_MAIL_TOKEN_VAULT_DIR="$VAULT" AGENT_MAIL_SEND_REDACTED_NTM_BIN="$FAKE_NTM" "$WRAPPER" send_message \
  --project-key "/tmp/synthetic-agent-mail-project" \
  --sender-name "SyntheticAgent" \
  --to "SyntheticRecipient" \
  --subject "Synthetic redact failure cleanup test" \
  --body "Synthetic body" \
  --sender-token-handle "vault:SyntheticAgent" \
  --capture-dir "$TMP/failure-capture" \
  --dry-run >"$TMP/failure-stdout.txt" 2>"$TMP/failure-stderr.txt"; then
  printf 'FAIL: failing redact helper unexpectedly succeeded\n' >&2
  exit 1
fi

if find "$FAIL_TMPDIR" -maxdepth 1 -type f -name 'agent-mail-redact-input.*' | grep -q .; then
  printf 'FAIL: redact failure left temp input files behind\n' >&2
  find "$FAIL_TMPDIR" -maxdepth 1 -type f -print >&2
  exit 1
fi

if ! "$WRAPPER" send_message \
  --project-key "/tmp/synthetic-agent-mail-project" \
  --sender-name "SyntheticAgent" \
  --to "SyntheticRecipient" \
  --subject "Synthetic direct literal rejection test" \
  --body "Synthetic body" \
  --sender-token-handle "$FAKE_TOKEN" \
  --dry-run >"$TMP/reject-stdout.txt" 2>"$TMP/reject-stderr.txt"; then
  if grep -Fq "$FAKE_TOKEN" "$TMP/reject-stdout.txt" "$TMP/reject-stderr.txt"; then
    printf 'FAIL: literal-token rejection echoed the synthetic token\n' >&2
    exit 1
  fi
  printf 'PASS: synthetic token absent from dispatch text, wrapper logs, and pane-visible args\n'
  exit 0
fi

  printf 'FAIL: wrapper accepted a literal token-shaped handle\n' >&2
exit 1
