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

SCAFFOLD_SCHEMA_VERSION="doctrine-broadcast-send/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/doctrine-broadcast-send-runs.jsonl}"

# Module-load env vars (also re-resolved in cmd_run for backward compat).
# These must be visible to the canonical-cli stubs (doctor/health/repair/etc.)
# which run BEFORE cmd_run is dispatched.
STATE_DIR="${STATE_DIR:-${FLYWHEEL_DOCTRINE_BROADCAST_STATE:-$HOME/.local/state/flywheel/doctrine-broadcasts}}"
RECEIPT_DIR="${RECEIPT_DIR:-${FLYWHEEL_DOCTRINE_BROADCAST_RECEIPTS:-/Users/josh/Developer/flywheel/.flywheel/receipts/doctrine-broadcasts}}"
SOURCE_ORCH="${SOURCE_ORCH:-${FLYWHEEL_SOURCE_ORCH:-flywheel}}"

scaffold_usage() {
  cat <<'USG'
usage: doctrine-broadcast-send.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "doctrine-broadcast-send.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "doctrine-broadcast-send.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"doctrine-broadcast-send.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"doctrine-broadcast-send.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"doctrine-broadcast-send.sh doctor --json"}'
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
            && cli_emit_completion_bash "doctrine-broadcast-send" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "doctrine-broadcast-send" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # Probe doctrine-broadcast-send substrate: state dir, receipt dir,
  # rg dependency, source orch identity, recent inbox writability.
  local checks
  checks="$(jq -cs '.' <(
    if [[ -d "$STATE_DIR" ]]; then
      jq -nc --arg p "$STATE_DIR" '{check:"state_dir",path:$p,status:"pass"}'
    else
      jq -nc --arg p "$STATE_DIR" '{check:"state_dir",path:$p,status:"warn",reason:"missing — repair --scope state will create"}'
    fi
    if [[ -d "$RECEIPT_DIR" ]]; then
      jq -nc --arg p "$RECEIPT_DIR" '{check:"receipt_dir",path:$p,status:"pass"}'
    else
      jq -nc --arg p "$RECEIPT_DIR" '{check:"receipt_dir",path:$p,status:"warn",reason:"missing — repair --scope state will create"}'
    fi
    if command -v rg >/dev/null 2>&1; then
      jq -nc '{check:"rg",status:"pass",dependency:"forbidden_reference_scan"}'
    else
      jq -nc '{check:"rg",status:"fail",reason:"rg required for forbidden-reference scan"}'
    fi
    if command -v jq >/dev/null 2>&1 && command -v shasum >/dev/null 2>&1; then
      jq -nc '{check:"core_deps",status:"pass",found:["jq","shasum"]}'
    else
      jq -nc '{check:"core_deps",status:"fail",reason:"jq+shasum required"}'
    fi
    if [[ -n "$SOURCE_ORCH" ]]; then
      jq -nc --arg orch "$SOURCE_ORCH" '{check:"source_orch",value:$orch,status:"pass"}'
    else
      jq -nc '{check:"source_orch",status:"warn",reason:"FLYWHEEL_SOURCE_ORCH unset"}'
    fi
  ))"
  local fails warns
  fails="$(jq -r '[.[] | select(.status=="fail")] | length' <<<"$checks")"
  warns="$(jq -r '[.[] | select(.status=="warn")] | length' <<<"$checks")"
  local status
  if [[ "$fails" -gt 0 ]]; then
    status="fail"
  elif [[ "$warns" -gt 0 ]]; then
    status="warn"
  else
    status="pass"
  fi
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg status "$status" \
    --argjson checks "$checks" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$status,checks:$checks}'
}

scaffold_cmd_health() {
  # Health: count inbox files + most-recent receipt timestamp + total broadcasts.
  local inbox_count receipt_count latest_receipt latest_ts status
  inbox_count=0
  receipt_count=0
  latest_receipt=""
  latest_ts=""
  if [[ -d "$STATE_DIR" ]]; then
    inbox_count="$(find "$STATE_DIR" -maxdepth 1 -name 'inbox-*.jsonl' -type f 2>/dev/null | wc -l | tr -d ' ')"
  fi
  if [[ -d "$RECEIPT_DIR" ]]; then
    receipt_count="$(find "$RECEIPT_DIR" -maxdepth 1 -name '*.json' -type f 2>/dev/null | wc -l | tr -d ' ')"
    latest_receipt="$(find "$RECEIPT_DIR" -maxdepth 1 -name '*.json' -type f 2>/dev/null | sort | tail -1)"
    if [[ -n "$latest_receipt" && -r "$latest_receipt" ]]; then
      latest_ts="$(jq -r '.ts // empty' "$latest_receipt" 2>/dev/null)"
    fi
  fi
  if [[ "$receipt_count" -gt 0 ]]; then
    status="ok"
  elif [[ ! -d "$STATE_DIR" || ! -d "$RECEIPT_DIR" ]]; then
    status="not_initialized"
  else
    status="empty"
  fi
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg status "$status" \
    --arg latest_receipt "$latest_receipt" \
    --arg latest_ts "$latest_ts" \
    --argjson inbox_count "$inbox_count" \
    --argjson receipt_count "$receipt_count" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,inbox_count:$inbox_count,receipt_count:$receipt_count,latest_receipt:(if $latest_receipt=="" then null else $latest_receipt end),latest_broadcast_ts:(if $latest_ts=="" then null else $latest_ts end)}'
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
  # repair --scope state: ensure STATE_DIR + RECEIPT_DIR exist with 0755.
  local planned applied
  planned="$(jq -cs '.' <(
    if [[ "$scope" != "state" ]]; then
      jq -nc --arg s "$scope" '{action:"none",reason:"unsupported scope (state only)",scope:$s}'
    else
      if [[ ! -d "$STATE_DIR" ]]; then
        jq -nc --arg p "$STATE_DIR" '{action:"mkdir",path:$p,mode:"0755"}'
      fi
      if [[ ! -d "$RECEIPT_DIR" ]]; then
        jq -nc --arg p "$RECEIPT_DIR" '{action:"mkdir",path:$p,mode:"0755"}'
      fi
    fi
  ))"
  applied='[]'
  if [[ "$mode" == "apply" && "$scope" == "state" ]]; then
    local applied_rows=()
    if [[ ! -d "$STATE_DIR" ]]; then
      mkdir -p "$STATE_DIR" && chmod 755 "$STATE_DIR" 2>/dev/null
      applied_rows+=("$(jq -nc --arg p "$STATE_DIR" --arg key "$idem_key" '{action:"mkdir",path:$p,mode:"0755",idempotency_key:$key}')")
    fi
    if [[ ! -d "$RECEIPT_DIR" ]]; then
      mkdir -p "$RECEIPT_DIR" && chmod 755 "$RECEIPT_DIR" 2>/dev/null
      applied_rows+=("$(jq -nc --arg p "$RECEIPT_DIR" --arg key "$idem_key" '{action:"mkdir",path:$p,mode:"0755",idempotency_key:$key}')")
    fi
    if [[ "${#applied_rows[@]}" -eq 0 ]]; then
      applied='[]'
    else
      applied="$(printf '%s\n' "${applied_rows[@]}" | jq -cs '.')"
    fi
    if command -v cli_audit_append >/dev/null; then
      cli_audit_append "$SCAFFOLD_AUDIT_LOG" "repair_state_apply" "ok" \
        "$(jq -nc --arg key "$idem_key" --argjson actions "$applied" '{idempotency_key:$key,actions:$actions}')"
    fi
  fi
  local status
  if [[ "$mode" == "apply" ]]; then
    status="applied"
  else
    status="dry_run"
  fi
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg scope "$scope" \
    --arg mode "$mode" \
    --arg idem "$idem_key" \
    --arg status "$status" \
    --argjson planned "$planned" \
    --argjson applied "$applied" \
    '{schema_version:$sv,command:"repair",status:$status,mode:$mode,scope:$scope,idempotency_key:$idem,planned_actions:$planned,applied_actions:$applied}'
}

scaffold_cmd_validate() {
  local subject="${1:-receipt}"
  if [[ "$subject" == "-h" || "$subject" == "--help" ]]; then
    scaffold_emit_topic_help validate
    return 0
  fi
  shift 2>/dev/null || true
  local results
  case "$subject" in
    receipt)
      # Validate every receipt JSON has the canonical broadcast envelope.
      # Schema: {ts, schema_version, target_project, sent, inbox_path,
      #          receipt_path, row:{ts,source_orch,target_project,subject,
      #                             body_path,doctrine_version,importance,
      #                             ack_required,broadcast_id}}
      if [[ ! -d "$RECEIPT_DIR" ]]; then
        results='[]'
      else
        results="$(find "$RECEIPT_DIR" -maxdepth 1 -name '*.json' -type f 2>/dev/null \
          | while read -r f; do
              if jq -e 'has("ts") and has("target_project") and has("row") and (.row | has("source_orch") and has("subject") and has("doctrine_version") and has("broadcast_id"))' "$f" >/dev/null 2>&1; then
                jq -nc --arg p "$f" '{path:$p,status:"pass"}'
              else
                jq -nc --arg p "$f" '{path:$p,status:"fail",reason:"missing required broadcast envelope or row field(s)"}'
              fi
            done | jq -cs '.')"
        if [[ -z "$results" ]]; then results='[]'; fi
      fi
      ;;
    *)
      results="$(jq -nc --arg s "$subject" '[{status:"unsupported",subject:$s,supported:["receipt"]}]')"
      ;;
  esac
  local status fails
  fails="$(jq -r '[.[] | select(.status=="fail")] | length' <<<"$results")"
  if [[ "$fails" -gt 0 ]]; then
    status="fail"
  else
    status="pass"
  fi
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg subject "$subject" \
    --arg status "$status" \
    --argjson results "$results" \
    '{schema_version:$sv,command:"validate",subject:$subject,status:$status,results:$results}'
}

scaffold_cmd_audit() {
  if command -v cli_emit_audit_tail >/dev/null; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" 20
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"audit",audit_log:$log,status:"helper_lib_missing"}'
  fi
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  # <id> is a broadcast receipt id (format: doctrine-<16-hex>).
  local receipt="$RECEIPT_DIR/$id.json"
  if [[ -r "$receipt" ]]; then
    jq -nc \
      --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
      --arg id "$id" \
      --arg path "$receipt" \
      --argjson body "$(cat "$receipt")" \
      '{schema_version:$sv,command:"why",id:$id,status:"found",receipt_path:$path,broadcast:$body}'
  else
    jq -nc \
      --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
      --arg id "$id" \
      --arg dir "$RECEIPT_DIR" \
      '{schema_version:$sv,command:"why",id:$id,status:"not_found",receipt_dir:$dir,note:"id not present in receipt dir"}'
  fi
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
STATE_DIR="${FLYWHEEL_DOCTRINE_BROADCAST_STATE:-$HOME/.local/state/flywheel/doctrine-broadcasts}"
RECEIPT_DIR="${FLYWHEEL_DOCTRINE_BROADCAST_RECEIPTS:-/Users/josh/Developer/flywheel/.flywheel/receipts/doctrine-broadcasts}"
SOURCE_ORCH="${FLYWHEEL_SOURCE_ORCH:-flywheel}"
TARGET_PROJECT=""
SUBJECT=""
BODY_PATH=""
DOCTRINE_VERSION=""
IMPORTANCE="normal"
ACK_REQUIRED=0
JSON_OUT=0
DRY_RUN=0

usage() {
  cat <<'USAGE'
usage: doctrine-broadcast-send.sh --target-project NAME --subject TEXT --body-path PATH --doctrine-version STAMP [--importance high|normal] [--ack-required] [--dry-run] [--json]

Writes one doctrine broadcast row to:
  ~/.local/state/flywheel/doctrine-broadcasts/inbox-<project>.jsonl

Default mutates the inbox and writes a receipt. --dry-run prints the planned
row without writing.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-project)
      [[ -n "${2:-}" ]] || { echo "ERR: --target-project requires NAME" >&2; exit 2; }
      TARGET_PROJECT="$2"; shift 2 ;;
    --subject)
      [[ -n "${2:-}" ]] || { echo "ERR: --subject requires TEXT" >&2; exit 2; }
      SUBJECT="$2"; shift 2 ;;
    --body-path)
      [[ -n "${2:-}" ]] || { echo "ERR: --body-path requires PATH" >&2; exit 2; }
      BODY_PATH="$2"; shift 2 ;;
    --doctrine-version)
      [[ -n "${2:-}" ]] || { echo "ERR: --doctrine-version requires STAMP" >&2; exit 2; }
      DOCTRINE_VERSION="$2"; shift 2 ;;
    --importance)
      [[ -n "${2:-}" ]] || { echo "ERR: --importance requires VALUE" >&2; exit 2; }
      IMPORTANCE="$2"; shift 2 ;;
    --ack-required)
      ACK_REQUIRED=1; shift ;;
    --dry-run)
      DRY_RUN=1; shift ;;
    --json)
      JSON_OUT=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "ERR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$TARGET_PROJECT" ]] || { echo "ERR: --target-project is required" >&2; exit 2; }
[[ -n "$SUBJECT" ]] || { echo "ERR: --subject is required" >&2; exit 2; }
[[ -n "$BODY_PATH" ]] || { echo "ERR: --body-path is required" >&2; exit 2; }
[[ -n "$DOCTRINE_VERSION" ]] || { echo "ERR: --doctrine-version is required" >&2; exit 2; }
[[ "$TARGET_PROJECT" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ERR: unsafe target project: $TARGET_PROJECT" >&2; exit 2; }
[[ "$IMPORTANCE" == "high" || "$IMPORTANCE" == "normal" ]] || { echo "ERR: --importance must be high or normal" >&2; exit 2; }
[[ -f "$BODY_PATH" ]] || { echo "ERR: body path not found: $BODY_PATH" >&2; exit 2; }

if rg -i 'josh|/Users/josh|flywheel-[a-z0-9]+|zeststream' "$BODY_PATH" >/dev/null 2>&1; then
  echo "ERR: body contains forbidden internal reference" >&2
  exit 6
fi

mkdir -p "$STATE_DIR" "$RECEIPT_DIR"
chmod 755 "$STATE_DIR" "$RECEIPT_DIR" 2>/dev/null || true

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
BODY_ABS="$(cd "$(dirname "$BODY_PATH")" && pwd -P)/$(basename "$BODY_PATH")"
BROADCAST_ID="$(printf '%s|%s|%s|%s|%s' "$TARGET_PROJECT" "$SUBJECT" "$BODY_ABS" "$DOCTRINE_VERSION" "$TS" | shasum -a 256 | awk '{print "doctrine-" substr($1,1,16)}')"
INBOX="$STATE_DIR/inbox-${TARGET_PROJECT}.jsonl"
LOCKDIR="$INBOX.lock"
TMP_INBOX="$INBOX.tmp"
ROW_FILE="$(mktemp "${TMPDIR:-/tmp}/doctrine-broadcast-row.XXXXXX")"
RECEIPT_PATH="$RECEIPT_DIR/$BROADCAST_ID.json"
TMP_RECEIPT="$RECEIPT_PATH.tmp"

cleanup() {
  rm -f "$ROW_FILE" "$TMP_INBOX" "$TMP_RECEIPT" 2>/dev/null || true
  rmdir "$LOCKDIR" 2>/dev/null || true
}
trap cleanup EXIT

jq -nc \
  --arg ts "$TS" \
  --arg source_orch "$SOURCE_ORCH" \
  --arg target_project "$TARGET_PROJECT" \
  --arg subject "$SUBJECT" \
  --arg body_path "$BODY_ABS" \
  --arg doctrine_version "$DOCTRINE_VERSION" \
  --arg importance "$IMPORTANCE" \
  --arg broadcast_id "$BROADCAST_ID" \
  --argjson ack_required "$ACK_REQUIRED" \
  '{
    ts:$ts,
    source_orch:$source_orch,
    target_project:$target_project,
    subject:$subject,
    body_path:$body_path,
    doctrine_version:$doctrine_version,
    importance:$importance,
    ack_required:($ack_required == 1),
    broadcast_id:$broadcast_id
  }' >"$ROW_FILE"

if [[ "$DRY_RUN" -eq 0 ]]; then
  until mkdir "$LOCKDIR" 2>/dev/null; do sleep 0.05; done
  if [[ -f "$INBOX" ]]; then
    cat "$INBOX" >"$TMP_INBOX"
  else
    : >"$TMP_INBOX"
  fi
  cat "$ROW_FILE" >>"$TMP_INBOX"
  chmod 0644 "$TMP_INBOX"
  mv "$TMP_INBOX" "$INBOX"
  chmod 0644 "$INBOX"
  jq -nc \
    --arg ts "$TS" \
    --arg target_project "$TARGET_PROJECT" \
    --arg inbox "$INBOX" \
    --arg receipt_path "$RECEIPT_PATH" \
    --argjson row "$(cat "$ROW_FILE")" \
    '{schema_version:"flywheel.doctrine_broadcast.receipt.v1",ts:$ts,target_project:$target_project,inbox_path:$inbox,receipt_path:$receipt_path,row:$row,sent:true}' >"$TMP_RECEIPT"
  chmod 0644 "$TMP_RECEIPT"
  mv "$TMP_RECEIPT" "$RECEIPT_PATH"
  chmod 0644 "$RECEIPT_PATH"
fi

payload="$(jq -nc \
  --arg mode "$([[ "$DRY_RUN" -eq 1 ]] && printf dry-run || printf sent)" \
  --arg inbox "$INBOX" \
  --arg receipt_path "$RECEIPT_PATH" \
  --argjson dry_run "$DRY_RUN" \
  --argjson row "$(cat "$ROW_FILE")" \
  '{schema_version:"flywheel.doctrine_broadcast.send.v1",status:$mode,dry_run:($dry_run == 1),inbox_path:$inbox,receipt_path:$receipt_path,row:$row}')"

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$payload"
else
  jq -r '"doctrine-broadcast status=\(.status) target=\(.row.target_project) broadcast_id=\(.row.broadcast_id) inbox=\(.inbox_path)"' <<<"$payload"
fi

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
