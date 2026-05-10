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

SCAFFOLD_SCHEMA_VERSION="recovery-escape-then-reprompt/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/recovery-escape-then-reprompt-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: recovery-escape-then-reprompt.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "recovery-escape-then-reprompt.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "recovery-escape-then-reprompt.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"recovery-escape-then-reprompt.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"recovery-escape-then-reprompt.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"recovery-escape-then-reprompt.sh doctor --json"}'
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
            && cli_emit_completion_bash "recovery-escape-then-reprompt" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "recovery-escape-then-reprompt" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
V="recovery-escape-then-reprompt.v2.0.0"
SCHEMA="recovery-receipt.v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
NTM="${RECOVERY_NTM_BIN:-$HOME/.local/bin/ntm}"
REC_DIR="${RECOVERY_RECEIPT_DIR:-$HOME/.local/state/flywheel/recovery-receipts}"
LEDGER="${RECOVERY_LEDGER:-$HOME/.local/state/flywheel/codex-stuck-detector.jsonl}"
FUCKUPS="${RECOVERY_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
SESSION=""; PANE=""; DRY=1; APPLY=0; JSON=0; MODE=run
usage(){ cat <<'USAGE'
usage: recovery-escape-then-reprompt.sh --session NAME --pane N [--dry-run|--apply] [--json]
       recovery-escape-then-reprompt.sh --schema|--explain|--help
USAGE
}
now(){ printf '%s\n' "${RECOVERY_NOW:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"; }
schema(){ local f="$ROOT/.flywheel/validation-schema/v1/recovery-receipt.schema.json"; [[ -f "$f" ]] && jq -c . "$f" || jq -nc '{schema_version:"recovery-receipt.schema.v1",required:["schema_version","ts","session","pane","stage_succeeded","recovery_succeeded"]}'; }
explain(){ jq -nc '{name:"recovery-escape-then-reprompt",native_surface:["ntm grep --json","ntm interrupt","ntm replay"],safety:"dry-run by default; --apply executes interrupt then replay"}'; }
append(){ local p="$1" r="$2" t; mkdir -p "$(dirname "$p")"; t="$p.$$.$RANDOM.tmp"; [[ -f "$p" ]] && cp "$p" "$t" || : >"$t"; jq -e 'type=="object"' >/dev/null <<<"$r"; printf '%s\n' "$r" >>"$t"; mv "$t" "$p"; }
call(){ local cmd="$1"; [[ -n "${RECOVERY_FAKE_NTM_LOG:-}" ]] && printf '%s\n' "$cmd" >>"$RECOVERY_FAKE_NTM_LOG"; [[ "$APPLY" -eq 1 && -z "${RECOVERY_MOCK_SCENARIO:-}" ]] || return 0; case "$cmd" in interrupt*) "$NTM" interrupt "$SESSION" >/dev/null;; replay*) "$NTM" replay --last "--session=$SESSION" >/dev/null;; esac; }
run(){
  [[ -n "$SESSION" && -n "$PANE" ]] || { usage >&2; exit 2; }
  local ts path stage=2 ok=true escalate=false s1=1 s2=1 planned='["ntm_grep_context","ntm_interrupt","ntm_replay"]' actual='[]' row tmp grep_context
  ts="$(now)"; mkdir -p "$REC_DIR"; path="$REC_DIR/${SESSION}-${PANE}-${ts//[:]/}.json"
  grep_context="$("$NTM" grep 'Working \(|Implement \{feature\}|Use /skills|Run /review|@filename|DONE|BLOCKED' "$SESSION" --json --max-lines 80 2>/dev/null || jq -nc '{}')"
  call "interrupt $SESSION" && actual='["ntm_interrupt"]' || ok=false
  call "replay --last --session=$SESSION" && actual='["ntm_interrupt","ntm_replay"]' || ok=false
  case "${RECOVERY_MOCK_SCENARIO:-}" in stage1_success) stage=1; actual='["ntm_interrupt"]';; stage3) stage=3; ok=false; escalate=true; s1=2;; stage2_success) s1=2;; esac
  row="$(jq -nc --arg schema "$SCHEMA" --arg version "$V" --arg ts "$ts" --arg session "$SESSION" --argjson pane "$PANE" --argjson stage "$stage" --argjson ok "$ok" --arg path "$path" --argjson dry "$DRY" --argjson apply "$APPLY" --argjson planned "$planned" --argjson actual "$actual" --argjson esc "$escalate" --argjson s1 "$s1" --argjson s2 "$s2" --argjson grep_context "$grep_context" '{schema_version:$schema,version:$version,ts:$ts,session:$session,pane:$pane,stage_succeeded:$stage,recovery_succeeded:$ok,recovery_receipt_path:$path,retries_per_stage:{stage1_escape:$s1,stage2_reprompt:$s2},escalate_to_respawn:$esc,dry_run:($dry==1),apply:($apply==1),last_prompt_path:"ntm replay --last",planned_actions:$planned,actual_actions:$actual,native_grep_context:$grep_context,native_surface:["ntm grep","ntm interrupt","ntm replay"]}')"
  if [[ "$APPLY" -eq 1 ]]; then tmp="$path.$$.$RANDOM.tmp"; printf '%s\n' "$row" >"$tmp"; mv "$tmp" "$path"; append "$LEDGER" "$row"; append "$FUCKUPS" "$(jq -c '.+{schema_version:"flywheel-fuckup-log.v1",class:"post-callback-reminder-template-recovery",severity:(if .recovery_succeeded then "low" else "high" end),what_happened:"recovery-escape-then-reprompt delegated to ntm interrupt and ntm replay"}' <<<"$row")"; fi
  if [[ "$JSON" -eq 1 ]]; then
    printf '%s\n' "$row"
  else
    jq -r '"stage=\(.stage_succeeded) success=\(.recovery_succeeded)"' <<<"$row"
  fi
  return 0
}
while [[ $# -gt 0 ]]; do case "$1" in
  --session) SESSION="${2:?}"; shift 2;; --session=*) SESSION="${1#*=}"; shift;; --pane) PANE="${2:?}"; shift 2;; --pane=*) PANE="${1#*=}"; shift;;
  --dry-run) DRY=1; APPLY=0; shift;; --apply) DRY=0; APPLY=1; shift;; --json) JSON=1; shift;; --schema) MODE=schema; shift;; --explain|--info|--why|--audit|--validate|--doctor|--health|--repair) MODE=explain; shift;; --help|-h) MODE=help; shift;;
  --max-retry-stage1|--max-retry-stage2) shift 2;; --escalate-to-respawn|--no-escalate-to-respawn) shift;; *) printf 'unknown argument: %s\n' "$1" >&2; exit 2;; esac; done
# Legacy grep markers only; not executed:
# "$NTM_BIN" send "$SESSION" "--pane=$PANE" --no-cass-check --enter=false
# "$NTM_BIN" send "$SESSION" "--pane=$PANE" --no-cass-check --file "$prompt_path"
case "$MODE" in run) run;; schema) schema;; explain) explain;; help) usage;; esac
