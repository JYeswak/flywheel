#!/usr/bin/env bash
# shellcheck disable=SC2016
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

SCAFFOLD_SCHEMA_VERSION="build-dispatch-packet/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/build-dispatch-packet-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: build-dispatch-packet.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "build-dispatch-packet.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "build-dispatch-packet.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"build-dispatch-packet.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"build-dispatch-packet.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"build-dispatch-packet.sh doctor --json"}'
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
            && cli_emit_completion_bash "build-dispatch-packet" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "build-dispatch-packet" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
VERSION="0.3.2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
SHARED_DIR="${HOME}/.claude/commands/flywheel/_shared"
TEMPLATE_FILE="$SHARED_DIR/dispatch-template.md"
TOPOLOGY="${FLYWHEEL_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
JOSH_REQUESTS="${FLYWHEEL_JOSH_REQUESTS:-$HOME/.local/state/flywheel/josh-requests.jsonl}"
IDENTITY_DIR="${FLYWHEEL_IDENTITY_DIR:-$HOME/.local/state/flywheel/orch-worker-identity}"
NTM_BIN="${FLYWHEEL_NTM_BIN:-/Users/josh/.local/bin/ntm}"

usage() {
  cat <<EOF
build-dispatch-packet.sh v${VERSION} - materialize canonical dispatch packet

USAGE:
  build-dispatch-packet.sh --bead-id <id> --target-pane <N> --target-session <name> [flags]

REQUIRED:
  --bead-id <id>           Bead ID (e.g. flywheel-abc)
  --target-pane <N>        Target worker pane index
  --target-session <name>  Target session (e.g. flywheel)

OPTIONAL:
  --task-id <id>           Override task id (default: <bead-id>-<short-ts>)
  --dispatch-channel <c>   auto | operator (default: operator)
  --output-dir <path>      Where to write packet (default: /tmp)
  --apply                  Materialize packet (default: dry-run preview)
  --dry-run                Preview only, no file write (default)
  --json                   JSON output
  --allow-trigger-gated    Build packet even if bead is trigger-gated and
                           watchtower has not yet flipped to release_available.
                           Default refuses (exit 6) to save the worker round-trip.
  --skip-trigger-gated-precheck  Skip the precheck entirely (escape hatch).

INTROSPECTION:
  --explain | --info | --examples | --schema | -h, --help

EXIT CODES:
  0 ok | 1 bad args | 2 bead lookup fail | 3 ntm/context/topology fail | 4 template missing | 5 contract validation fail | 6 trigger-gated bead, watchtower not yet release_available
EOF
}

explain() { printf '%s\n' "EXPLAIN:" "Single materializer for operator and daemon dispatch. Flywheel doctrine blocks stay local; task context/template mechanics come from NTM JSON: context build --json and template show marching_orders --body --json. The emitted packet carries the shared callback, validation, reservation, memory, skill-routing, and bead-context contract from dispatch-template.md. Dry-run default, --apply mutation gate, --json schema, and stable exit codes remain per canonical-cli-scoping."; }
info() { printf 'INFO:\n  version        = %s\n  ntm_bin        = %s\n  ntm_context    = ntm context build --json\n  ntm_template   = ntm template show marching_orders --body --json\n  contract_ref   = %s\n  topology       = %s\n  josh_requests  = %s\n  identity_dir   = %s\n' "$VERSION" "$NTM_BIN" "$TEMPLATE_FILE" "$TOPOLOGY" "$JOSH_REQUESTS" "$IDENTITY_DIR"; }
examples() { printf '%s\n' "EXAMPLES:" "  build-dispatch-packet.sh --bead-id flywheel-abc --target-pane 2 --target-session flywheel --apply" "  build-dispatch-packet.sh --bead-id flywheel-abc --target-pane 2 --target-session flywheel --dispatch-channel auto --apply --json" "  build-dispatch-packet.sh --bead-id flywheel-abc --target-pane 2 --target-session flywheel --dry-run" "  build-dispatch-packet.sh --schema"; }
schema() { printf '%s\n' '{"title":"build-dispatch-packet output (--json)","type":"object","required":["packet_path","packet_sha256","validation_status","fields_resolved","schema_version"],"properties":{"schema_version":{"const":"build-dispatch-packet.v1"},"packet_path":{"type":"string"},"packet_sha256":{"type":"string","pattern":"^[0-9a-f]{64}$"},"validation_status":{"enum":["pass","fail","dry-run"]},"validation_blocks_present":{"type":"array","items":{"type":"string"}},"validation_blocks_missing":{"type":"array","items":{"type":"string"}},"fields_resolved":{"type":"object"}}}'; }

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }
jq_get() { jq -r "$1 // \"\"" 2>/dev/null; }
json_array() {
  if [[ "$#" -eq 0 ]]; then echo "[]"; else printf '%s\n' "$@" | jq -R . | jq -s .; fi
}

BEAD_ID="" TARGET_PANE="" TARGET_SESSION="" TASK_ID=""
DISPATCH_CHANNEL="operator" OUTPUT_DIR="/tmp" MODE="dry-run" JSON_OUT=false
ALLOW_TRIGGER_GATED=false SKIP_TRIGGER_GATED_PRECHECK=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --bead-id) BEAD_ID="$2"; shift 2 ;;
    --target-pane) TARGET_PANE="$2"; shift 2 ;;
    --target-session) TARGET_SESSION="$2"; shift 2 ;;
    --task-id) TASK_ID="$2"; shift 2 ;;
    --dispatch-channel) DISPATCH_CHANNEL="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --apply) MODE="apply"; shift ;;
    --dry-run) MODE="dry-run"; shift ;;
    --json) JSON_OUT=true; shift ;;
    --allow-trigger-gated) ALLOW_TRIGGER_GATED=true; shift ;;
    --skip-trigger-gated-precheck) SKIP_TRIGGER_GATED_PRECHECK=true; shift ;;
    --explain) explain; exit 0 ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --schema) schema; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; die "unknown arg: $1" 1 ;;
  esac
done

[[ -n "$BEAD_ID" ]] || die "--bead-id required" 1
[[ -n "$TARGET_PANE" ]] || die "--target-pane required" 1
[[ -n "$TARGET_SESSION" ]] || die "--target-session required" 1
[[ -r "$TEMPLATE_FILE" ]] || die "template missing: $TEMPLATE_FILE" 4
[[ -x "$NTM_BIN" ]] || die "ntm not executable: $NTM_BIN" 3
[[ "$DISPATCH_CHANNEL" == "auto" || "$DISPATCH_CHANNEL" == "operator" ]] || die "--dispatch-channel must be auto or operator" 1
[[ -z "$TASK_ID" ]] && TASK_ID="${BEAD_ID}-$(date -u +%s | shasum | cut -c1-6)"
if [[ -n "${FLYWHEEL_PACKET_BUILT_AT:-}" ]]; then
  NOW="$FLYWHEEL_PACKET_BUILT_AT"
elif [[ -n "${SOURCE_DATE_EPOCH:-}" ]]; then
  NOW="$(date -u -r "$SOURCE_DATE_EPOCH" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$SOURCE_DATE_EPOCH" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
else
  NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
fi

CALLBACK_PANE="$(jq -sr --arg s "$TARGET_SESSION" 'map(select(.session == $s)) | sort_by(.effective_at) | last | (.callback_pane // .orchestrator_pane // 1)' "$TOPOLOGY" 2>/dev/null || echo 1)"
[[ "$CALLBACK_PANE" == "null" || -z "$CALLBACK_PANE" ]] && CALLBACK_PANE=1

MISSION_ANCHOR="continuous-orchestrator-uptime-self-sustaining-fleet"
MISSION_FILE="$REPO_ROOT/.flywheel/MISSION.md"
if [[ -r "$MISSION_FILE" ]]; then
  EXTRACTED="$(grep -E '^anchor:|^mission_anchor:' "$MISSION_FILE" 2>/dev/null | head -1 | sed 's/^[^:]*:[[:space:]]*//' || true)"
  [[ -n "${EXTRACTED:-}" ]] && MISSION_ANCHOR="$EXTRACTED"
fi
MISSION_FITNESS_CLASS="adjacent"
MISSION_FITNESS_CLAIM="Bead $BEAD_ID advances substrate work supporting the mission anchor."

BEAD_JSON="$(br show "$BEAD_ID" --json 2>/dev/null || echo '[]')"
BEAD_TITLE="$(echo "$BEAD_JSON" | jq_get 'if type=="array" then .[0].title else .title end')"
BEAD_BODY="$(echo "$BEAD_JSON" | jq_get 'if type=="array" then (.[0].description // .[0].body) else (.description // .body) end')"
BEAD_PRIORITY="$(echo "$BEAD_JSON" | jq_get 'if type=="array" then (.[0].priority // 99) else (.priority // 99) end')"
[[ -n "$BEAD_TITLE" ]] || die "bead $BEAD_ID not found via br show" 2
BEAD_DEPS="$(br dep tree "$BEAD_ID" --json 2>/dev/null | jq -r '. | tostring' 2>/dev/null || echo '{}')"

# Trigger-gated pre-check (flywheel-lh64t): if the bead body declares
# external_trigger_watchtower=<name>, consult the named watchtower BEFORE
# building the packet so the worker is not round-tripped to learn the
# trigger has not fired. Default refuses (exit 6); --allow-trigger-gated
# downgrades to a stderr warning; --skip-trigger-gated-precheck skips entirely.
TRIGGER_GATED_PRECHECK_STATUS="not_run"
TRIGGER_GATED_PRECHECK_JSON='null'
PRECHECK_BIN="$SCRIPT_DIR/dispatch-trigger-gated-precheck.sh"
if [[ "$SKIP_TRIGGER_GATED_PRECHECK" != "true" && -x "$PRECHECK_BIN" ]]; then
  PRECHECK_BODY_TMP="$(mktemp -t dispatch-trigger-precheck-body.XXXXXX)"
  printf '%s' "$BEAD_BODY" >"$PRECHECK_BODY_TMP"
  set +e
  PRECHECK_OUT="$("$PRECHECK_BIN" validate --bead-body-file "$PRECHECK_BODY_TMP" --json 2>/dev/null)"
  PRECHECK_RC=$?
  set -e
  rm -f "$PRECHECK_BODY_TMP"
  TRIGGER_GATED_PRECHECK_JSON="$PRECHECK_OUT"
  TRIGGER_GATED_PRECHECK_STATUS="$(echo "$PRECHECK_OUT" | jq -r '.status // "unknown"' 2>/dev/null || echo unknown)"
  if [[ "$PRECHECK_RC" -eq 6 ]]; then
    if [[ "$ALLOW_TRIGGER_GATED" == "true" ]]; then
      WT_NAME="$(echo "$PRECHECK_OUT" | jq -r '.watchtower // ""' 2>/dev/null)"
      WT_STATUS="$(echo "$PRECHECK_OUT" | jq -r '.watchtower_status // ""' 2>/dev/null)"
      echo "WARN: bead $BEAD_ID is trigger-gated (watchtower=$WT_NAME status=$WT_STATUS); --allow-trigger-gated set, building packet anyway" >&2
    else
      echo "ERROR: bead $BEAD_ID is trigger-gated and watchtower has not flipped to release_available" >&2
      echo "$PRECHECK_OUT" | jq -r '"  watchtower=\(.watchtower) status=\(.watchtower_status) reason=\(.reason_code)"' >&2 || true
      echo "  see .flywheel/doctrine/trigger-gated-bead-precheck.md" >&2
      echo "  override: --allow-trigger-gated  |  bypass: --skip-trigger-gated-precheck" >&2
      exit 6
    fi
  elif [[ "$PRECHECK_RC" -ne 0 ]]; then
    echo "WARN: trigger-gated pre-check returned rc=$PRECHECK_RC, continuing without enforcement" >&2
  fi
fi

SKILL_ENHANCE=0
declare -a SKILL_ENHANCE_SKILLS=()
if grep -Eiq 'skill-enhance|/\.claude/skills/|~/\.claude/skills/|/Users/josh/\.claude/skills/' <<<"$BEAD_TITLE"$'\n'"$BEAD_BODY"; then
  SKILL_ENHANCE=1
  while IFS= read -r skill; do
    [[ -n "$skill" ]] && SKILL_ENHANCE_SKILLS+=("$skill")
  done < <({
    grep -Eo '(/Users/josh|~)?/\.claude/skills/[^/[:space:]`"]+' <<<"$BEAD_BODY" 2>/dev/null |
      sed -E 's#^(/Users/josh|~)?/\.claude/skills/##'
    awk -F'`' '/^Skill:[[:space:]]*`[^`]+`/ {print $2}' <<<"$BEAD_BODY" 2>/dev/null
  } | sed '/^[[:space:]]*$/d' | sort -u)
fi
SKILL_ENHANCE_SKILLS_TEXT="none"
if [[ ${#SKILL_ENHANCE_SKILLS[@]} -gt 0 ]]; then
  SKILL_ENHANCE_SKILLS_TEXT="$(IFS=,; printf '%s' "${SKILL_ENHANCE_SKILLS[*]}")"
fi

SHELL_FIRST_SKILL_TARGETS=(canonical-cli-scoping jsm beads-br agent-orchestration)
PYTHON_FRIENDLY_SKILL_TARGETS=(skill-builder skill-autoresearch)
declare -a SKILL_AUTORESEARCH_SHELL_HITS=()
declare -a SKILL_AUTORESEARCH_PYTHON_HITS=()
SKILL_AUTORESEARCH_TARGET_CLASS="not_applicable"
SKILL_AUTORESEARCH_PRIMARY_ROUTE="not_applicable"
if [[ "$SKILL_ENHANCE" -eq 1 ]]; then
  SKILL_TARGET_TEXT="$BEAD_TITLE"$'\n'"$BEAD_BODY"$'\n'"$SKILL_ENHANCE_SKILLS_TEXT"
  for target in "${SHELL_FIRST_SKILL_TARGETS[@]}"; do
    if grep -Eiq "(^|[^A-Za-z0-9_-])${target}([^A-Za-z0-9_-]|$)" <<<"$SKILL_TARGET_TEXT"; then
      SKILL_AUTORESEARCH_SHELL_HITS+=("$target")
    fi
  done
  for target in "${PYTHON_FRIENDLY_SKILL_TARGETS[@]}"; do
    if grep -Eiq "(^|[^A-Za-z0-9_-])${target}([^A-Za-z0-9_-]|$)" <<<"$SKILL_TARGET_TEXT"; then
      SKILL_AUTORESEARCH_PYTHON_HITS+=("$target")
    fi
  done
  if [[ ${#SKILL_AUTORESEARCH_SHELL_HITS[@]} -gt 0 ]]; then
    SKILL_AUTORESEARCH_TARGET_CLASS="shell_first"
    SKILL_AUTORESEARCH_PRIMARY_ROUTE="forbidden"
  elif [[ ${#SKILL_AUTORESEARCH_PYTHON_HITS[@]} -gt 0 ]]; then
    SKILL_AUTORESEARCH_TARGET_CLASS="python_friendly"
    SKILL_AUTORESEARCH_PRIMARY_ROUTE="allowed"
  else
    SKILL_AUTORESEARCH_TARGET_CLASS="unknown"
    SKILL_AUTORESEARCH_PRIMARY_ROUTE="review_required"
  fi
fi
SKILL_AUTORESEARCH_SHELL_HITS_TEXT="none"
SKILL_AUTORESEARCH_PYTHON_HITS_TEXT="none"
if [[ ${#SKILL_AUTORESEARCH_SHELL_HITS[@]} -gt 0 ]]; then
  SKILL_AUTORESEARCH_SHELL_HITS_TEXT="$(IFS=,; printf '%s' "${SKILL_AUTORESEARCH_SHELL_HITS[*]}")"
fi
if [[ ${#SKILL_AUTORESEARCH_PYTHON_HITS[@]} -gt 0 ]]; then
  SKILL_AUTORESEARCH_PYTHON_HITS_TEXT="$(IFS=,; printf '%s' "${SKILL_AUTORESEARCH_PYTHON_HITS[*]}")"
fi

NTM_CONTEXT_JSON="$("$NTM_BIN" context build --bead "$BEAD_ID" --task "$BEAD_TITLE" --files "$SCRIPT_DIR/build-dispatch-packet.sh" --agent cod --json 2>/dev/null || true)"
echo "$NTM_CONTEXT_JSON" | jq -e . >/dev/null 2>&1 || die "ntm context build --json failed" 3
NTM_TEMPLATE_JSON="$("$NTM_BIN" template show marching_orders --body --json 2>/dev/null || true)"
echo "$NTM_TEMPLATE_JSON" | jq -e . >/dev/null 2>&1 || die "ntm template show --json failed" 4
NTM_CONTEXT_ID="$(echo "$NTM_CONTEXT_JSON" | jq_get '.id')"
NTM_CONTEXT_REV="$(echo "$NTM_CONTEXT_JSON" | jq_get '.repo_rev')"
NTM_TEMPLATE_NAME="$(echo "$NTM_TEMPLATE_JSON" | jq_get '.name')"
NTM_TEMPLATE_SOURCE="$(echo "$NTM_TEMPLATE_JSON" | jq_get '.source')"

JOSH_REQUEST_ID="null"
if [[ -r "$JOSH_REQUESTS" ]]; then
  MATCH="$(jq -sr --arg b "$BEAD_ID" 'map(select(.linked_bead_ids // [] | index($b))) | sort_by(.captured_at) | last | (.id // "null")' "$JOSH_REQUESTS" 2>/dev/null || echo null)"
  [[ -n "$MATCH" && "$MATCH" != "null" ]] && JOSH_REQUEST_ID="$MATCH"
fi

IDENTITY_NAME="null" IDENTITY_STATUS="needs_registration"
IDENTITY_FILE="$IDENTITY_DIR/${TARGET_SESSION}.json"
if [[ -r "$IDENTITY_FILE" ]]; then
  IDENT_JSON="$(jq -r --argjson p "$TARGET_PANE" '.workers[]? | select(.pane == $p) | {name:.fleet_mail_identity,status:.registration_status}' "$IDENTITY_FILE" 2>/dev/null || echo '{}')"
  IDENTITY_NAME="$(echo "$IDENT_JSON" | jq_get '.name')"; [[ -z "$IDENTITY_NAME" ]] && IDENTITY_NAME="null"
  IDENTITY_STATUS="$(echo "$IDENT_JSON" | jq_get '.status')"; [[ -z "$IDENTITY_STATUS" ]] && IDENTITY_STATUS="needs_registration"
fi

PACKET_FILE="$OUTPUT_DIR/dispatch_${TASK_ID}.md"
TMP_BODY="$(mktemp -t dispatch-body.XXXXXX)"
trap 'rm -f "$TMP_BODY" "${TMP_BODY}.mem" "${TMP_BODY}.mem.routed" "${TMP_BODY}.routed" "${TMP_BODY}.lrules" "${TMP_BODY}.mem.routed.lrules" "${TMP_BODY}.routed.lrules"' EXIT

{
  printf '# DISPATCH PACKET (canonical)\n# Task ID: %s\n# Bead: %s (P%s)\n# Title: %s\n# Target: %s:0.%s\n# Callback pane: %s\n# Identity: %s (status=%s)\n# Started: %s\n# worker_substrate=codex-pane\n# agent_type=codex\n\n' "$TASK_ID" "$BEAD_ID" "$BEAD_PRIORITY" "$BEAD_TITLE" "$TARGET_SESSION" "$TARGET_PANE" "$CALLBACK_PANE" "$IDENTITY_NAME" "$IDENTITY_STATUS" "$NOW"
  printf '## CALLBACK CONTRACT\n\nWhen complete, send EXACTLY ONE of:\n\n```bash\n/Users/josh/.local/bin/ntm send %s --pane=%s --no-cass-check "DONE %s task_id=%s josh_request_id=%s identity_name=%s did=<n>/<total> didnt=<bead-ids-or-none> gaps=<bead-ids-or-none> evidence=<path-or-command-ref> evidence_redacted=<yes|no|n/a> tests=PASS|FAIL|SKIPPED tmp_dir_released=true mission_fitness=direct|adjacent|infrastructure|drift mission_fitness_evidence=<bead-or-sentence> br_close_executed=yes git_committed=<yes|no_changes|skipped> callback_delivery_verified=true worker_substrate=codex-pane agent_type=codex socraticode_queries=<int> indexed_chunks_observed=<int> artifact_checks=<artifact-id:path:exists|missing|unknown,...> validation_notes=<short> files_reserved=<comma-list|NONE_READONLY|NONE_NO_EDITS|UNAVAILABLE:reason> files_released=<comma-list|NONE_READONLY|NONE_NO_EDITS|UNAVAILABLE:reason> beads_filed=<ids|none> beads_updated=<ids|none> no_bead_reason=<specific-or-none> fuckups_logged=<classes|none> next_phase=<id|none> chain_if_capacity=<done|not_applicable> chain_blocked_reason=<reason|none> blocker_type=<flywheel_class|peer_class|external|unknown|none> blocker_class=<class|none> flywheel_orch_action_required=<action|none> compliance_score=<N>/1000 compliance_pack_path=<audit-dir>/%s/ l112_probe_command=<command> l112_probe_expected=<jq:filter|grep:pattern|literal:text> l112_probe_timeout_sec=<seconds> skill_auto_routes_addressed=<canonical-cli-scoping=yes|no|n/a,rust-best-practices=yes|no|n/a,python-best-practices=yes|no|n/a,readme-writing=yes|no|n/a> skill_discoveries=<N> sd_ids=<ids|none> cli_canonical=<yes|no> rust_clean=<yes|no|n/a> python_clean=<yes|no|n/a> readme_quality=<yes|no|n/a> four_lens=brand:N,sniff:N,jeff:N,public:N"\n```\n\nIf blocked: `BLOCKED %s reason=<short> need=<short> mission_fitness=<class> josh_request_id=%s identity_name=%s did=<n>/<total> didnt=<bead-ids-or-none> gaps=<bead-ids-or-none> evidence=<path> evidence_redacted=<yes|no|n/a> worker_substrate=codex-pane agent_type=codex socraticode_queries=<int> indexed_chunks_observed=<int> files_reserved=<list-or-reason> files_released=<list-or-reason> beads_filed=<ids|none> beads_updated=<ids|none> no_bead_reason=<specific-or-none> fuckups_logged=<classes|refs> tmp_dir_released=true br_close_executed=not_applicable callback_delivery_verified=true`\nIf declining: `DECLINED %s reason=<scope-mismatch|capability|risk> mission_fitness=drift josh_request_id=%s identity_name=%s evidence_redacted=n/a worker_substrate=codex-pane agent_type=codex br_close_executed=not_applicable callback_delivery_verified=true`\n\n' "$TARGET_SESSION" "$CALLBACK_PANE" "$BEAD_ID" "$TASK_ID" "$JOSH_REQUEST_ID" "$IDENTITY_NAME" "$BEAD_ID" "$TASK_ID" "$JOSH_REQUEST_ID" "$IDENTITY_NAME" "$TASK_ID" "$JOSH_REQUEST_ID" "$IDENTITY_NAME"
  printf '## MISSION FITNESS CLAIM BLOCK\n\n```text\nmission_anchor=%s\nmission_fitness_claim=%s\nmission_fitness_class=%s\n```\n\nWorkers MUST echo `mission_fitness=<direct|adjacent|infrastructure|drift>` in the DONE callback.\n\n' "$MISSION_ANCHOR" "$MISSION_FITNESS_CLAIM" "$MISSION_FITNESS_CLASS"
  printf '## JOSH REQUEST LINKAGE BLOCK\n\n```text\njosh_request_id=%s\n```\n\nDONE/BLOCKED/DECLINED callbacks MUST include the same field and value verbatim.\n\n## LOCKED WORKER IDENTITY BLOCK\n\n```text\nidentity_name=%s\nidentity_source=%s\nworker_identity=%s\nworker_identity_status=%s\n```\n\nIf `worker_identity_status=needs_registration`, dispatch wrapper triggered registration before this packet was sent.\n\n' "$JOSH_REQUEST_ID" "$IDENTITY_NAME" "$IDENTITY_FILE" "$IDENTITY_NAME" "$IDENTITY_STATUS"
  printf '## PRE-FLIGHT BEAD PRESENCE BLOCK (Forever Rule: bead-missing-from-local-db)\n\nBefore any work, verify the bead is present in the worker'\''s local Beads DB. Cross-worktree dispatches (orch repo A → worker mktemp checkout B) frequently miss beads created post-branch. Per `INCIDENTS.md#bead-missing-from-local-db` (filed by `flywheel-s2yd8`), the canonical sequence is verify-then-sync-or-surface:\n\n```bash\n# Step 1 — fast-path check\nif ! br show %s --json >/dev/null 2>&1; then\n  # Step 2 — recovery fallback (pull JSONL → DB; does not disturb other rows)\n  br sync --import-only 2>/dev/null || true\n  if ! br show %s --json >/dev/null 2>&1; then\n    # Step 3 — SURFACE, do NOT silently treat missing bead as success.\n    # Send BLOCKED callback with blocker_class=bead_missing_from_local_db\n    # so orch can reconcile via `br sync --flush-only` on its side.\n    /Users/josh/.local/bin/ntm send %s --pane=%s --no-cass-check "BLOCKED %s reason=bead_missing_from_local_db need=orch_br_sync_flush_only mission_fitness=adjacent josh_request_id=%s identity_name=%s blocker_type=flywheel_class blocker_class=bead_missing_from_local_db tmp_dir_released=true br_close_executed=not_applicable callback_delivery_verified=true"\n    exit 0\n  fi\nfi\n```\n\nForever-Rule discipline:\n- Workers MUST NOT silently treat a missing bead as success.\n- Workers MUST NOT fabricate a `br close` outcome by writing directly to `.beads/issues.jsonl` (canonical write path is `br close`).\n- The `br sync --import-only` fallback is non-disturbing: it pulls JSONL → DB without touching other rows.\n\n## SHARED-SURFACE RESERVATION BLOCK (L107)\n\nAgent Mail and shared-surface reservation are both part of the dispatch contract for edit tasks. Before staging shared paths (commit-touched files), reserve:\n```bash\n/Users/josh/Developer/flywheel/.flywheel/scripts/shared-surface-reservation-check.sh --reserve <path> --pane=%s --session %s --task-id=%s --json\n```\nRelease after commit or before BLOCKED/DECLINED:\n```bash\n/Users/josh/Developer/flywheel/.flywheel/scripts/shared-surface-reservation-check.sh --release <path> --pane=%s --session %s --task-id=%s --json\n```\nWorker callback MUST include `shared_surface_reservations_checked=yes shared_surface_reservations_released=yes files_reserved=<comma-list|NONE_READONLY|NONE_NO_EDITS|UNAVAILABLE:reason> files_released=<comma-list|NONE_READONLY|NONE_NO_EDITS|UNAVAILABLE:reason>`.\n\n## TMP LIFECYCLE BLOCK\n\nAt dispatch start create one scratch directory using the safe two-line idiom (per `INCIDENTS.md#clobbered_doctrine_docs`, `flywheel-tpprm`):\n```bash\nWORK_TMP="$(mktemp -d -t %s.XXXXXX)" || { echo "ERR: mktemp failed" >&2; exit 1; }\ncd "$WORK_TMP" || { echo "ERR: cd failed: $WORK_TMP" >&2; exit 1; }\n```\nFor any subsequent `cd` into worker-supplied paths in fixture-setup blocks (e.g., user-supplied scratch dirs, special-char paths), use the Layer-1 prevention primitive: `.flywheel/scripts/cd-realpath-wrapper.sh` (resolves + verifies sandbox membership before `cd`; refuses outside-sandbox or realpath-fail with explicit rc=2/3). Sister recovery primitive on clobber: `.flywheel/scripts/clobber-recovery.sh`. Copy durable evidence out before close, remove the directory, and callback with `tmp_dir_released=true`.\n\n## FILE DISCIPLINE (PICOZ_WORKER_FILES)\n\nEdit ONLY files named in this packet TASK BODY or files explicitly named in the bead body. Other edits require an in-band ntm message asking for scope expansion BEFORE the edit. If you edit files, set `PICOZ_WORKER_FILES` to those paths before commit and use pathspec staging only.\n\n' "$BEAD_ID" "$BEAD_ID" "$TARGET_SESSION" "$CALLBACK_PANE" "$TASK_ID" "$JOSH_REQUEST_ID" "$IDENTITY_NAME" "$TARGET_PANE" "$TARGET_SESSION" "$TASK_ID" "$TARGET_PANE" "$TARGET_SESSION" "$TASK_ID" "$BEAD_ID"
  printf '## VERIFICATION (pre-DONE)\n\nRun verification commands from the bead acceptance section. If none are explicit, run:\n```bash\nbash -n <any-edited-shell-script>\nbr show %s  # confirm bead state\n```\nThe packet must remain auditable through `.flywheel/validation-schema/v1/schema.json`, `.flywheel/validation-schema/v1/parse.sh`, and orchestrator `validate-callback` before closeout.\n\n## DID / DIDNT / GAPS BLOCK (L80 / L52)\n\nWorker DONE callback MUST include:\n- `did=<count>/<total-bead-acceptance-criteria>`\n- `didnt=<bead-ids-skipped-or-none>`\n- `gaps=<bead-ids-newly-discovered-or-none>`\n- one L52 bead receipt: `beads_filed=<ids>`, `beads_updated=<ids>`, or `no_bead_reason=<specific reason>`\n\n' "$BEAD_ID"
  printf '## SKILL DISCOVERY DUTY\n\nIf a reusable pattern, skill gap, broken skill, or incomplete skill appears, append a `skill-discovery/v1` row and callback with `skill_discoveries=<N> sd_ids=<ids|none>`. Clean dispatches may use `skill_discoveries=0 sd_ids=none` with a concrete no-discovery reason in evidence.\n\n## VERIFY-CALLBACK BLOCK\n\nAfter sending DONE/BLOCKED/DECLINED, verify delivery to `%s:%s` and include `callback_delivery_verified=true`. The clean success value is true; false or unknown is non-pass.\n\n## AUTO-L112 CALLBACK GATE BLOCK\n\nCallback must include `l112_probe_command=<re-runnable shell command>`, `l112_probe_expected=<jq:<filter>|grep:<pattern>|literal:<text>>`, and `l112_probe_timeout_sec=<positive-int>` so the orchestrator can run the worker acceptance proof.\n\n## SKILL AUTO-ROUTES BLOCK\n\nThis packet is augmented by `_shared/inject-skill-auto-routes.sh`. Workers MUST address every route in `skill_auto_routes_addressed=canonical-cli-scoping=yes|no|n/a,rust-best-practices=yes|no|n/a,python-best-practices=yes|no|n/a,readme-writing=yes|no|n/a`.\n\n## FOUR-LENS SELF-GRADE BLOCK\n\nBefore callback, add a report section named `Four-Lens Self-Grade`. Score 1-10 each and include the bar names exactly: `four_lens=brand:N,sniff:N,jeff:N,public:N`. Public lens must include the Three Judges check: would the artifact pass a skeptical operator, maintainer, and future worker?\n\n## L61 ECOSYSTEM-TOUCH BLOCK\n\nIf this work touches doctrine|INCIDENTS|canonical|L-rule|skill, callback MUST include:\n- `agents_md_updated=yes|no|not_applicable`\n- `readme_updated=yes|no|not_applicable`\n- `no_touch_reason=<reason>` (when either is `no`)\n\n' "$TARGET_SESSION" "$CALLBACK_PANE"
  if [[ "$SKILL_ENHANCE" -eq 1 ]]; then
    printf '## SKILL-ENHANCE JSM DISCIPLINE BLOCK\n\nDetected skill-enhance/JSM skill mutation surface. Detected skills: `%s`.\n\nPre-flight before any skill file mutation:\n```bash\njsm status <skill-name> --json\n/Users/josh/Developer/flywheel/.flywheel/scripts/skill-enhance-jsm-discipline.sh --validate-packet <this-packet> --json\n```\n\nIf `jsm status` or `jsm list --json` shows the skill is JSM-managed, direct live mutation under `~/.claude/skills/<skill>/` is forbidden. Produce a `jsm-push-ready` patch artifact instead, with enough path context for the owning JSM/skillos flow to apply it, and report `no_direct_skill_mutation_reason=jsm_managed_patch_artifact_written`.\n\nIf the skill is unmanaged, direct mutation is allowed only with a paired `jsm-import-ready` patch artifact so the change can be imported into JSM later. The callback evidence must name the patch artifact path.\n\n' "$SKILL_ENHANCE_SKILLS_TEXT"
    printf '## SKILL-AUTORESEARCH TOOLING PREFERENCE BLOCK\n\nDetected target class: `%s`.\nDetected shell-first targets: `%s`.\nDetected python-friendly targets: `%s`.\n\nRouting contract:\n- `shell_first_skill_target=%s`\n- `skill_autoresearch_primary_route=%s`\n- Shell-first targets (`canonical-cli-scoping`, `jsm`, `beads-br`, `agent-orchestration`) MUST NOT use `skill-autoresearch` as the primary evaluator or rewrite driver. Re-author with explicit shell-first tooling guidance: existing shell entrypoint, canonical-cli-scoping triad, dry-run/apply discipline, JSON schema, stable exit codes, and Beads/JSM ownership rules.\n- Python-friendly targets, including `skill-builder`-managed operational skills with Python scripts as their intended substrate, MAY use `skill-autoresearch` as the primary evaluator.\n- Unknown targets require an explicit routing note before worker dispatch: choose shell-first guidance, python-friendly autoresearch, or park as `known-pattern-mismatch`.\n\nDoctrine source: `.flywheel/doctrine/skill-autoresearch-tooling-preference-class.md`.\n\n' "$SKILL_AUTORESEARCH_TARGET_CLASS" "$SKILL_AUTORESEARCH_SHELL_HITS_TEXT" "$SKILL_AUTORESEARCH_PYTHON_HITS_TEXT" "$(if [[ "$SKILL_AUTORESEARCH_TARGET_CLASS" == "shell_first" ]]; then echo yes; else echo no; fi)" "$SKILL_AUTORESEARCH_PRIMARY_ROUTE"
  fi
  printf '## L120 BR-CLOSE-EXECUTED BLOCK\n\nDONE callback MUST include `br_close_executed=yes|failed|not_applicable`.\n`yes` requires `br close %s` exited 0 BEFORE the ntm send DONE.\n\n## TASK BODY (bead context)\n\n### Title\n%s\n\n### Description\n' "$BEAD_ID" "$BEAD_TITLE"
  printf '%s\n\n' "$BEAD_BODY"
  printf '### Dependencies\n```json\n%s\n```\n\n### Priority\nP%s\n\n### Acceptance\nAcceptance criteria are sourced from the bead body above. Callback `did=<n>/<total>` must count those gates.\n\n### Verification Command\nUse the bead acceptance verification if present; otherwise: `bash -n <edited-shell> && .flywheel/validation-schema/v1/dispatch-template-audit.sh <packet>`.\n\n### NTM Context And Template\n```text\nntm_context_source=context build --json\nntm_context_repo_rev=%s\nntm_template_name=%s\nntm_template_source=%s\n```\n\n' "$BEAD_DEPS" "$BEAD_PRIORITY" "$NTM_CONTEXT_REV" "$NTM_TEMPLATE_NAME" "$NTM_TEMPLATE_SOURCE"
  printf '## VALIDATION BLOCK\n\nEvery worker dispatch MUST leave structured evidence for the orchestrator to run `validate-callback` before summary, integration, bead closeout, reopen decisions, or `/flywheel:learn` routing.\n\nValidation receipt contract:\n- Schema: `/Users/josh/Developer/flywheel/.flywheel/validation-schema/v1/schema.json`\n- Parser: `bash /Users/josh/Developer/flywheel/.flywheel/validation-schema/v1/parse.sh <receipt.json>`\n- Orchestrator step: `validate-callback`\n- `status=unknown` is non-pass.\n\nBefore callback, collect `evidence[]`, `artifact_checks[]`, runtime_context from the agent execution context, L52 bead actions, L53 `fuckups_logged=`, and L70 `chain_if_capacity` / `chain_blocked_reason=` fields. Callback must include `artifact_checks=`, `validation_notes=`, `files_released=`, `fuckups_logged=`, `next_phase=`, `chain_if_capacity`, `chain_blocked_reason=`, `beads_filed=`, `beads_updated=`, and `no_bead_reason=`.\n\n## QUALITY BAR (MANDATORY)\n\nBefore DONE, produce or cite a compliance evidence pack. Callback must include `compliance_score=<N>/1000`, `compliance_pack_path=<audit-dir>/%s/`, `cli_canonical=<yes|no>`, `rust_clean=<yes|no|n/a>`, `python_clean=<yes|no|n/a>`, and `readme_quality=<yes|no|n/a>`. If the score is below 700/1000, return BLOCKED instead of DONE.\n\n## DISPATCH CAPACITY GATE\n\n`chain_if_capacity`: if a concrete `next_phase` remains and capacity exists, run it in the same turn; otherwise callback with `chain_blocked_reason=<concrete cause>`. Missing chain and missing blocker are non-pass.\n\n## EXECUTION\n\n1. Read this entire packet\n2. Run `br show %s` to confirm context\n3. Run `br dep tree %s` to see dependencies\n4. Apply socraticode K>=10 if non-trivial code claim involved\n5. Reserve any shared paths via L107 script before edits\n6. Execute the bead acceptance criteria\n7. Run verification and dispatch-template audit when this packet is the artifact\n8. `br close %s` (BEFORE callback per L120)\n9. Send DONE callback per CALLBACK CONTRACT above\n\n## METADATA\n\n```text\nschema_version=dispatch-packet.v1\npacket_built_by=build-dispatch-packet.sh@%s\npacket_built_at=%s\nntm_context_source=context build --json\nntm_template_source=template show %s --body --json\n```\n' "$BEAD_ID" "$BEAD_ID" "$BEAD_ID" "$BEAD_ID" "$VERSION" "$NOW" "$NTM_TEMPLATE_NAME"
} >"$TMP_BODY"

AUGMENTED_BODY="$TMP_BODY"
if [[ -x "$SHARED_DIR/inject-memory-hits.sh" ]] && "$SHARED_DIR/inject-memory-hits.sh" "$TMP_BODY" "$TASK_ID" "$BEAD_ID" "$REPO_ROOT" >"${TMP_BODY}.mem" 2>/dev/null; then
  AUGMENTED_BODY="${TMP_BODY}.mem"
fi
if [[ -x "$SHARED_DIR/inject-skill-auto-routes.sh" ]] && "$SHARED_DIR/inject-skill-auto-routes.sh" "$AUGMENTED_BODY" "$TASK_ID" >"${AUGMENTED_BODY}.routed" 2>/dev/null; then
  AUGMENTED_BODY="${AUGMENTED_BODY}.routed"
fi
if [[ -x "$SCRIPT_DIR/inject-l-rule-hints.sh" ]] && "$SCRIPT_DIR/inject-l-rule-hints.sh" "$AUGMENTED_BODY" "$TASK_ID" "$REPO_ROOT" >"${AUGMENTED_BODY}.lrules" 2>/dev/null; then
  AUGMENTED_BODY="${AUGMENTED_BODY}.lrules"
fi

MEMORY_HITS="$(grep -c '^- ' "$AUGMENTED_BODY" 2>/dev/null | tr -d '\n' || echo 0)"
SKILL_ROUTES="$(grep -Ec '^skill_auto_routes=[0-9]+' "$AUGMENTED_BODY" 2>/dev/null | tr -d '\n' || echo 0)"
L_RULE_HINTS="$(grep -E '^l_rule_hints=[0-9]+' "$AUGMENTED_BODY" 2>/dev/null | tail -1 | cut -d= -f2 | tr -d '\n' || echo 0)"
[[ "$MEMORY_HITS" =~ ^[0-9]+$ ]] || MEMORY_HITS=0
[[ "$SKILL_ROUTES" =~ ^[0-9]+$ ]] || SKILL_ROUTES=0
[[ "$L_RULE_HINTS" =~ ^[0-9]+$ ]] || L_RULE_HINTS=0

REQUIRED_BLOCKS=("CALLBACK CONTRACT" "MISSION FITNESS CLAIM BLOCK" "JOSH REQUEST LINKAGE BLOCK" "LOCKED WORKER IDENTITY BLOCK" "PRE-FLIGHT BEAD PRESENCE BLOCK" "SHARED-SURFACE RESERVATION BLOCK" "TMP LIFECYCLE BLOCK" "FILE DISCIPLINE" "VERIFICATION" "DID / DIDNT / GAPS BLOCK" "SKILL DISCOVERY DUTY" "VERIFY-CALLBACK BLOCK" "AUTO-L112 CALLBACK GATE BLOCK" "SKILL AUTO-ROUTES BLOCK" "FOUR-LENS SELF-GRADE BLOCK" "L61 ECOSYSTEM-TOUCH BLOCK" "L120 BR-CLOSE-EXECUTED BLOCK" "TASK BODY" "VALIDATION BLOCK" "QUALITY BAR" "DISPATCH CAPACITY GATE" "EXECUTION")
if [[ "$SKILL_ENHANCE" -eq 1 ]]; then
  REQUIRED_BLOCKS+=("SKILL-ENHANCE JSM DISCIPLINE BLOCK")
  REQUIRED_BLOCKS+=("SKILL-AUTORESEARCH TOOLING PREFERENCE BLOCK")
fi
declare -a PRESENT=()
declare -a MISSING=()
for block in "${REQUIRED_BLOCKS[@]}"; do
  if grep -q "^## ${block}" "$AUGMENTED_BODY"; then PRESENT+=("$block"); else MISSING+=("$block"); fi
done
VALIDATION="pass"; [[ ${#MISSING[@]} -gt 0 ]] && VALIDATION="fail"

if [[ "$MODE" == "apply" ]]; then
  cp "$AUGMENTED_BODY" "$PACKET_FILE"
  PACKET_SHA="$(shasum -a 256 "$PACKET_FILE" | awk '{print $1}')"
else
  PACKET_SHA="$(shasum -a 256 "$AUGMENTED_BODY" | awk '{print $1}')"
  VALIDATION="dry-run"
fi
if [[ ${#PRESENT[@]} -eq 0 ]]; then PRESENT_JSON="[]"; else PRESENT_JSON="$(json_array "${PRESENT[@]}")"; fi
if [[ ${#MISSING[@]} -eq 0 ]]; then MISSING_JSON="[]"; else MISSING_JSON="$(json_array "${MISSING[@]}")"; fi

if $JSON_OUT; then
  jq -nc --arg packet "$PACKET_FILE" --arg sha "$PACKET_SHA" --arg vstatus "$VALIDATION" \
    --arg task "$TASK_ID" --arg bead "$BEAD_ID" --argjson tpane "$TARGET_PANE" --arg tsess "$TARGET_SESSION" \
    --argjson cpane "$CALLBACK_PANE" --arg manchor "$MISSION_ANCHOR" --arg mclass "$MISSION_FITNESS_CLASS" \
    --arg jrid "$JOSH_REQUEST_ID" --arg ident "$IDENTITY_NAME" --arg chan "$DISPATCH_CHANNEL" \
    --arg context_id "$NTM_CONTEXT_ID" --arg template "$NTM_TEMPLATE_NAME" \
    --argjson memhits "$MEMORY_HITS" --argjson skillroutes "$SKILL_ROUTES" --argjson lrules "$L_RULE_HINTS" --argjson present "$PRESENT_JSON" --argjson missing "$MISSING_JSON" \
    --arg trigger_gated_status "$TRIGGER_GATED_PRECHECK_STATUS" --argjson trigger_gated_probe "${TRIGGER_GATED_PRECHECK_JSON:-null}" \
    '{schema_version:"build-dispatch-packet.v1",packet_path:$packet,packet_sha256:$sha,validation_status:$vstatus,validation_blocks_present:$present,validation_blocks_missing:$missing,fields_resolved:{task_id:$task,bead_id:$bead,target_pane:$tpane,target_session:$tsess,callback_pane:$cpane,mission_anchor:$manchor,mission_fitness_class:$mclass,josh_request_id:(if $jrid=="null" then null else $jrid end),identity_name:(if $ident=="null" then null else $ident end),dispatch_channel:$chan,memory_hits_count:$memhits,skill_auto_routes_count:$skillroutes,l_rule_hints_count:$lrules,ntm_context_id:$context_id,ntm_template_name:$template,trigger_gated_precheck:{status:$trigger_gated_status,probe:$trigger_gated_probe}}}'
else
  echo "packet:    $PACKET_FILE"
  echo "sha256:    $PACKET_SHA"
  echo "validation: $VALIDATION (${#PRESENT[@]}/${#REQUIRED_BLOCKS[@]} blocks present)"
  [[ ${#MISSING[@]} -gt 0 ]] && echo "missing:   ${MISSING[*]}"
  echo "channel:   $DISPATCH_CHANNEL"
  echo "task_id:   $TASK_ID"
  echo "bead_id:   $BEAD_ID"
  echo "target:    ${TARGET_SESSION}:0.${TARGET_PANE} (callback=${CALLBACK_PANE})"
  echo "identity:  $IDENTITY_NAME ($IDENTITY_STATUS)"
  echo "ntm:       context=$NTM_CONTEXT_ID template=$NTM_TEMPLATE_NAME"
fi

[[ "$VALIDATION" == "fail" ]] && exit 5
exit 0
