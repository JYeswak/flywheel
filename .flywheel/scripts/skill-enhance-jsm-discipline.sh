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

SCAFFOLD_SCHEMA_VERSION="skill-enhance-jsm-discipline/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/skill-enhance-jsm-discipline-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: skill-enhance-jsm-discipline.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "skill-enhance-jsm-discipline.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "skill-enhance-jsm-discipline.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"skill-enhance-jsm-discipline.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"skill-enhance-jsm-discipline.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"skill-enhance-jsm-discipline.sh doctor --json"}'
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
            && cli_emit_completion_bash "skill-enhance-jsm-discipline" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "skill-enhance-jsm-discipline" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
VERSION="skill-enhance-jsm-discipline/v1"
JSM_BIN="${JSM_BIN:-jsm}"
MODE=""
PACKET=""
JSM_LIST_JSON=""
SKILLS_CSV=""
JSON_OUT=0
# JSM list availability state — set by load_jsm_list. Values:
#   live    — `jsm list` returned within the timeout
#   fixture — read from --jsm-list-json or JSM_LIST_JSON env
#   unavailable — timeout, command missing, or non-JSON output
#   offline — JSM_OFFLINE=1 set; live call skipped intentionally
JSM_LIST_STATUS=""
JSM_LIST_REASON=""

usage() {
  cat <<'EOF'
usage: skill-enhance-jsm-discipline.sh (--audit | --validate-packet PATH) [flags]

Flags:
  --skills a,b,c          Audit these skill names.
  --jsm-list-json PATH    Read fixture/snapshot JSON instead of live jsm list.
  --json                  Emit JSON.

Env:
  JSM_BIN                 jsm binary (default: jsm)
  JSM_LIST_TIMEOUT_SEC    bound on live `jsm list --json` (default: 10)
  JSM_LIST_JSON           same as --jsm-list-json
  JSM_OFFLINE=1           skip the live call, emit status=skipped/jsm_list_status=offline

Exit codes:
  0 pass | skipped (JSM unavailable/offline — distinguishable via jsm_list_status)
  1 validation refused
  2 usage or input error

JSM availability is surfaced on every emission as `jsm_list_status` ∈
{live, fixture, unavailable, offline} so workers never have to guess
whether a missing managed/unmanaged classification means "ok" or
"could not determine".
EOF
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 2
}

json_array() {
  if [[ "$#" -eq 0 ]]; then
    printf '[]\n'
  else
    printf '%s\n' "$@" | jq -R . | jq -s .
  fi
}

load_jsm_list() {
  # Always emits valid JSON on stdout. Sets $JSM_LIST_STATUS to one of
  # live|fixture|unavailable|offline so the caller can distinguish a
  # successful classification from "we could not determine". Never
  # exits the worker on JSM transport failure — workers must not hang
  # on substrate flake (bead flywheel-odugq).
  if [[ "${JSM_OFFLINE:-0}" == "1" ]]; then
    JSM_LIST_STATUS="offline"
    JSM_LIST_REASON="JSM_OFFLINE=1"
    printf '{"skills":[]}\n'
    return 0
  fi
  if [[ -n "$JSM_LIST_JSON" ]]; then
    if [[ -r "$JSM_LIST_JSON" ]]; then
      JSM_LIST_STATUS="fixture"
      JSM_LIST_REASON="--jsm-list-json=$JSM_LIST_JSON"
      cat "$JSM_LIST_JSON"
    else
      JSM_LIST_STATUS="unavailable"
      JSM_LIST_REASON="cannot read --jsm-list-json: $JSM_LIST_JSON"
      printf '{"skills":[]}\n'
    fi
    return 0
  fi
  if ! command -v "$JSM_BIN" >/dev/null 2>&1; then
    JSM_LIST_STATUS="unavailable"
    JSM_LIST_REASON="jsm binary not on PATH"
    printf '{"skills":[]}\n'
    return 0
  fi
  local tmp pid waited timeout rc=0
  tmp="$(mktemp -t skill-enhance-jsm-list.XXXXXX)"
  timeout="${JSM_LIST_TIMEOUT_SEC:-10}"
  "$JSM_BIN" list --json >"$tmp" 2>/dev/null &
  pid=$!
  waited=0
  while kill -0 "$pid" 2>/dev/null; do
    if [[ "$waited" -ge "$timeout" ]]; then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      rm -f "$tmp"
      JSM_LIST_STATUS="unavailable"
      JSM_LIST_REASON="jsm list --json timed out after ${timeout}s"
      printf '{"skills":[]}\n'
      return 0
    fi
    sleep 1
    waited=$((waited + 1))
  done
  wait "$pid" || rc=$?
  if [[ "$rc" -ne 0 ]]; then
    rm -f "$tmp"
    JSM_LIST_STATUS="unavailable"
    JSM_LIST_REASON="jsm list --json exited ${rc}"
    printf '{"skills":[]}\n'
    return 0
  fi
  if ! jq -e . >/dev/null 2>&1 <"$tmp"; then
    rm -f "$tmp"
    JSM_LIST_STATUS="unavailable"
    JSM_LIST_REASON="jsm list --json returned non-JSON"
    printf '{"skills":[]}\n'
    return 0
  fi
  JSM_LIST_STATUS="live"
  JSM_LIST_REASON="jsm list --json (${waited}s)"
  cat "$tmp"
  rm -f "$tmp"
}

skill_names_from_csv() {
  tr ',' '\n' <<<"$SKILLS_CSV" | sed '/^[[:space:]]*$/d' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

extract_packet_skills() {
  local packet="$1"
  {
    grep -Eo '/Users/josh/\.claude/skills/[^/[:space:]`"]+' "$packet" 2>/dev/null |
      sed -E 's#^/Users/josh/\.claude/skills/##'
    grep -Eo '~/\.claude/skills/[^/[:space:]`"]+' "$packet" 2>/dev/null |
      sed -E 's#^~/\.claude/skills/##'
    grep -Eo '\.claude/skills/[^/[:space:]`"]+' "$packet" 2>/dev/null |
      sed -E 's#^\.claude/skills/##'
    awk -F'`' '/^Skill:[[:space:]]*`[^`]+`/ {print $2}' "$packet" 2>/dev/null
    awk -F'[: ]+' '/^Skill:[[:space:]]*[A-Za-z0-9._-]+/ {print $2}' "$packet" 2>/dev/null
  } | sed '/^[[:space:]]*$/d' | sort -u
}

skill_record() {
  local skill="$1" list="$2"
  jq -c --arg name "$skill" '(.skills // []) | map(select(.name == $name)) | .[0] // {}' <<<"$list"
}

skill_is_managed() {
  jq -e '
    (.name? != null)
    and (((.is_saved // false) == true)
      or ((.is_jeffreys // false) == true)
      or ((.installed_at // "") != ""))
  ' >/dev/null
}

packet_has_direct_mutation() {
  local packet="$1" skill="$2"
  grep -Eiq "(edit|modify|mutate|patch|write|update).*${skill}/SKILL[.]md" "$packet" 2>/dev/null ||
    grep -Eiq "direct (live )?(skill )?mutation" "$packet" 2>/dev/null
}

packet_has_jsm_status() {
  local packet="$1" skill="$2"
  grep -Fqi "jsm status $skill" "$packet" 2>/dev/null ||
    grep -Fqi "jsm show $skill" "$packet" 2>/dev/null ||
    grep -Fqi "jsm status <skill-name>" "$packet" 2>/dev/null
}

packet_has_push_ready_patch() {
  local packet="$1"
  grep -Eiq 'jsm[-_ ]push[-_ ]ready|push-ready patch|jsm push ready' "$packet" 2>/dev/null
}

packet_has_import_ready_patch() {
  local packet="$1"
  grep -Eiq 'jsm[-_ ]import[-_ ]ready|import-ready artifact|jsm import ready' "$packet" 2>/dev/null
}

packet_forbids_live_mutation() {
  local packet="$1"
  grep -Eiq 'do not mutate live|do not edit JSM-managed|direct mutation forbidden|rather than direct unmanaged mutation|patch artifact, do not mutate live' "$packet" 2>/dev/null
}

emit_audit() {
  local list managed=() unmanaged=() absent=() records=() jsm_buf
  jsm_buf="$(mktemp -t skill-enhance-jsm-buf.XXXXXX)"
  load_jsm_list >"$jsm_buf"
  list="$(cat "$jsm_buf")"
  rm -f "$jsm_buf"
  while IFS= read -r skill; do
    [[ -n "$skill" ]] || continue
    local rec
    rec="$(skill_record "$skill" "$list")"
    if jq -e '.name? == null' <<<"$rec" >/dev/null; then
      absent+=("$skill")
      unmanaged+=("$skill")
    elif skill_is_managed <<<"$rec"; then
      managed+=("$skill")
    else
      unmanaged+=("$skill")
    fi
    records+=("$(jq -nc --arg skill "$skill" --argjson record "$rec" '{skill:$skill,record:$record,managed:(($record.name? != null) and (($record.is_saved // false) or ($record.is_jeffreys // false) or (($record.installed_at // "") != "")))}')")
  done < <(skill_names_from_csv)

  local managed_json unmanaged_json absent_json records_json
  managed_json="$(json_array "${managed[@]}")"
  unmanaged_json="$(json_array "${unmanaged[@]}")"
  absent_json="$(json_array "${absent[@]}")"
  records_json="$(if [[ ${#records[@]} -eq 0 ]]; then printf '[]'; else printf '%s\n' "${records[@]}" | jq -s .; fi)"
  local status_value="pass"
  if [[ "$JSM_LIST_STATUS" == "unavailable" || "$JSM_LIST_STATUS" == "offline" ]]; then
    status_value="skipped"
  fi
  jq -nc \
    --arg schema "$VERSION" \
    --arg status_value "$status_value" \
    --arg jsm_list_status "$JSM_LIST_STATUS" \
    --arg jsm_list_reason "$JSM_LIST_REASON" \
    --argjson managed "$managed_json" \
    --argjson unmanaged "$unmanaged_json" \
    --argjson absent "$absent_json" \
    --argjson records "$records_json" \
    '{schema_version:$schema,status:$status_value,mode:"audit",jsm_list_status:$jsm_list_status,jsm_list_reason:$jsm_list_reason,managed_count:($managed|length),unmanaged_count:($unmanaged|length),absent_count:($absent|length),managed:$managed,unmanaged:$unmanaged,absent:$absent,skills:$records}'
}

validate_packet() {
  [[ -r "$PACKET" ]] || die "cannot read packet: $PACKET"
  local list skills=() errors=() reports=() jsm_buf
  jsm_buf="$(mktemp -t skill-enhance-jsm-buf.XXXXXX)"
  load_jsm_list >"$jsm_buf"
  list="$(cat "$jsm_buf")"
  rm -f "$jsm_buf"
  while IFS= read -r skill; do
    skills+=("$skill")
  done < <(extract_packet_skills "$PACKET")

  if ! grep -Fqi 'skill-enhance' "$PACKET" 2>/dev/null &&
    ! grep -Fqi '/.claude/skills/' "$PACKET" 2>/dev/null &&
    ! grep -Fqi '~/.claude/skills/' "$PACKET" 2>/dev/null &&
    ! grep -Fqi '/Users/josh/.claude/skills/' "$PACKET" 2>/dev/null; then
    jq -nc --arg schema "$VERSION" --arg jsm_list_status "$JSM_LIST_STATUS" --arg jsm_list_reason "$JSM_LIST_REASON" \
      '{schema_version:$schema,status:"pass",mode:"validate-packet",reason:"not_skill_enhance",jsm_list_status:$jsm_list_status,jsm_list_reason:$jsm_list_reason}'
    return 0
  fi

  # If JSM is unavailable or explicitly offline, we cannot classify
  # managed-vs-unmanaged. Emit a stable skipped status so the worker
  # has a single, distinguishable signal it can route on without
  # hanging or guessing. The skill list and direct-mutation
  # observations are still surfaced for evidence.
  if [[ "$JSM_LIST_STATUS" == "unavailable" || "$JSM_LIST_STATUS" == "offline" ]]; then
    local skipped_skills_json
    if [[ ${#skills[@]} -eq 0 ]]; then
      skipped_skills_json='[]'
    else
      skipped_skills_json="$(printf '%s\n' "${skills[@]}" \
        | jq -R '{skill:., jsm_status:"unavailable", managed:null, direct_mutation:null}' \
        | jq -s .)"
    fi
    jq -nc --arg schema "$VERSION" --arg packet "$PACKET" \
      --arg jsm_list_status "$JSM_LIST_STATUS" --arg jsm_list_reason "$JSM_LIST_REASON" \
      --argjson skills "$skipped_skills_json" \
      '{schema_version:$schema,status:"skipped",mode:"validate-packet",packet:$packet,reason:"jsm_unavailable",jsm_list_status:$jsm_list_status,jsm_list_reason:$jsm_list_reason,errors:[],skills:$skills}'
    return 0
  fi

  if [[ ${#skills[@]} -eq 0 ]]; then
    errors+=("skill-enhance packet names no skill path")
  fi

  local skill rec managed direct has_status has_push has_import forbids
  for skill in "${skills[@]}"; do
    rec="$(skill_record "$skill" "$list")"
    managed=0
    if skill_is_managed <<<"$rec"; then managed=1; fi
    direct=0
    if packet_has_direct_mutation "$PACKET" "$skill"; then direct=1; fi
    has_status=0
    if packet_has_jsm_status "$PACKET" "$skill"; then has_status=1; fi
    has_push=0
    if packet_has_push_ready_patch "$PACKET"; then has_push=1; fi
    has_import=0
    if packet_has_import_ready_patch "$PACKET"; then has_import=1; fi
    forbids=0
    if packet_forbids_live_mutation "$PACKET"; then forbids=1; fi

    [[ "$has_status" -eq 1 ]] || errors+=("$skill missing pre-flight jsm status")
    if [[ "$managed" -eq 1 ]]; then
      [[ "$has_push" -eq 1 ]] || errors+=("$skill is JSM-managed and missing jsm-push-ready patch artifact")
      if [[ "$direct" -eq 1 && "$forbids" -ne 1 ]]; then
        errors+=("$skill is JSM-managed but packet allows direct live mutation")
      fi
    else
      [[ "$has_import" -eq 1 || "$has_push" -eq 1 ]] || errors+=("$skill is unmanaged and missing jsm-import-ready patch artifact")
    fi
    local jsm_status="unmanaged"
    [[ "$managed" -eq 1 ]] && jsm_status="managed"
    reports+=("$(jq -nc --arg skill "$skill" --arg jsm_status "$jsm_status" --argjson managed "$managed" --argjson direct "$direct" --argjson has_status "$has_status" --argjson has_push "$has_push" --argjson has_import "$has_import" '{skill:$skill,jsm_status:$jsm_status,managed:($managed==1),direct_mutation:($direct==1),jsm_status_present:($has_status==1),push_ready_patch_present:($has_push==1),import_ready_patch_present:($has_import==1)}')")
  done

  local errors_json reports_json status
  errors_json="$(json_array "${errors[@]}")"
  reports_json="$(if [[ ${#reports[@]} -eq 0 ]]; then printf '[]'; else printf '%s\n' "${reports[@]}" | jq -s .; fi)"
  status="pass"
  [[ ${#errors[@]} -gt 0 ]] && status="refused"
  jq -nc --arg schema "$VERSION" --arg status "$status" --arg packet "$PACKET" \
    --arg jsm_list_status "$JSM_LIST_STATUS" --arg jsm_list_reason "$JSM_LIST_REASON" \
    --argjson errors "$errors_json" --argjson reports "$reports_json" \
    '{schema_version:$schema,status:$status,mode:"validate-packet",packet:$packet,jsm_list_status:$jsm_list_status,jsm_list_reason:$jsm_list_reason,errors:$errors,skills:$reports}'
  [[ "$status" == "pass" ]]
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --audit) MODE="audit"; shift ;;
    --validate-packet) MODE="validate-packet"; PACKET="$2"; shift 2 ;;
    --skills) SKILLS_CSV="$2"; shift 2 ;;
    --jsm-list-json) JSM_LIST_JSON="$2"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; die "unknown arg: $1" ;;
  esac
done

command -v jq >/dev/null 2>&1 || die "jq not found"
case "$MODE" in
  audit)
    [[ -n "$SKILLS_CSV" ]] || die "--skills required for --audit"
    emit_audit
    ;;
  validate-packet)
    validate_packet
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-03-agent-ergonomics-rubric.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-58-agent-tool-theory-of-mind.md`
