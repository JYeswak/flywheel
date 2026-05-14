#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial → passing per bead flywheel-1hshd.26)
# doctor-mode-tier: scaffolded
#
# IDEMPOTENT-BY-CONSTRUCTION: this surface is read-only — scans REPO
# for oversized source/doctrine files and emits findings; no mutation
# path. Every invocation against the same tree returns the same JSON.
set -euo pipefail

# ====== BEGIN canonical-cli scaffold (bead flywheel-1hshd.26) ======
# SURGICAL DASH-FLAG SCAFFOLD variant (sister 5ke66.17 / 1hshd.{15,17,19,23}).
# Native script owns:
#   - --repo PATH (scan target override)
#   - --json / --no-color / --no-emoji (output mode)
#   - --doctor (alias for --json; both emit the scan payload via flywheel-loop binding)
#   - default text mode (oversized_files_count + allowed_oversized_files_count)
# Pre-existing regression `tests/file-length-probe.sh` exercises:
#   - `--repo PATH --json` — must return .oversized_files_count + .allowed_oversized_files_count
#   - flywheel-loop binding via .file_length nested envelope
#
# Bash scaffold intercepts BEFORE the native arg parser:
#   - --info / --schema / --examples (NEW canonical introspection)
#   - NEW positional verbs: doctor, health, repair, validate, audit, why, quickstart
#   - help <topic>
# Native flags (--repo/--json/--doctor/--no-color/--no-emoji) and default
# scanner mode all fall through to native unchanged.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi
SCAFFOLD_SCHEMA_VERSION="file-length-probe/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/file-length-probe-runs.jsonl}"

scaffold_emit_info() {
  if ! command -v cli_emit_info >/dev/null; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
      '{schema_version:$sv,command:"info",name:"file-length-probe.sh",version:"scaffolded-v1",capabilities:["read-only-scanner"],helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "file-length-probe.sh" \
    "scaffolded-v1" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,info,schema,examples,help" \
    "FLYWHEEL_FILE_LENGTH_INCLUDE_LOOP_BIN,SCAFFOLD_AUDIT_LOG,TMPDIR" \
    '{"thresholds":{"bash":500,"python":400,"rust":500,"markdown":1500},"exit_codes":{"ok":0,"refused_apply":3,"usage":2}}' \
    | jq -c '. + {capabilities:["file-length-threshold-scanner","language-classifier-bash-python-rust-markdown","canonical-cli-scoping-allow-large-marker-aware","find-prune-git-beads-cass-node_modules-venv","flywheel-loop-binding-via-file_length-nested-envelope","read-only-scanner"],mutates_state:false}'
}

scaffold_emit_schema() {
  local surface="${1:-default}"
  case "$surface" in
    doctor)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"doctor",fields:{ts:"ISO8601",status:"pass|warn|fail",checks:"array of {name,status,detail?,path?}"}}'
      ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"health",fields:{ts:"ISO8601",status:"pass|warn|fail",audit_log:"path",last_run_ts:"ISO8601 or null",age_seconds:"int|null",recent_runs:"int (last 20)",total_runs:"int",stale_threshold_seconds:"int"}}'
      ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"repair",scopes:["audit_log_dir","repo_path"],contract:{requires_idempotency_key_when_apply:true,refusal_exit_code:3,dry_run_default:true},env:{audit_log:"SCAFFOLD_AUDIT_LOG"}}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"validate",subjects:["repo-path","language-name","threshold"],contract:{rejects_with_rc1:"on schema violation",valid_languages:["bash","python","rust","markdown"]}}'
      ;;
    findings|default|*)
      local input_schema output_schema
      input_schema='{"type":"object","properties":{"repo":{"type":"string"},"json":{"type":"boolean"},"doctor":{"type":"boolean"}}}'
      output_schema='{"type":"object","required":["schema_version","status","repo","thresholds","scanned_files_count","oversized_files_count","oversized_files","allowed_oversized_files_count","allowed_oversized_files","errors","warnings"],"properties":{"schema_version":{"const":"file-length-probe/v1"},"status":{"enum":["pass","warn","fail"]},"repo":{"type":"string"},"thresholds":{"type":"object","required":["bash","python","rust","markdown"]},"scanned_files_count":{"type":"integer","minimum":0},"oversized_files_count":{"type":"integer","minimum":0},"oversized_files":{"type":"array","items":{"type":"object","required":["path","abs_path","language","lines","threshold","excess","allow_override"]}},"allowed_oversized_files_count":{"type":"integer","minimum":0},"allowed_oversized_files":{"type":"array"}}}'
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --argjson in "$input_schema" --argjson out "$output_schema" \
        '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why","findings"],input_schema:$in,output_schema:$out,note:"Default surface = findings (the native scan payload returned by --json or --doctor)."}'
      ;;
  esac
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"scan current repo (text)",invocation:"file-length-probe.sh",purpose:"emit oversized + allowed counts as plain text"}'
)"$'\n'"$(jq -nc '{name:"scan current repo (JSON)",invocation:"file-length-probe.sh --json",purpose:"emit full findings payload (oversized_files + allowed_oversized_files)"}'
)"$'\n'"$(jq -nc '{name:"scan a different repo",invocation:"file-length-probe.sh --repo /path/to/other-repo --json",purpose:"override scan target via --repo"}'
)"$'\n'"$(jq -nc '{name:"doctor check (canonical envelope)",invocation:"file-length-probe.sh doctor --json",purpose:"named-probe substrate health (5 probes including find/jq availability)"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe substrate",command:"file-length-probe.sh doctor --json"}'
)"$'\n'"$(jq -nc '{step:2,action:"scan current repo",command:"file-length-probe.sh --json"}'
)"$'\n'"$(jq -nc '{step:3,action:"audit recent runs",command:"file-length-probe.sh audit --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,validate,audit"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run|scan)    printf 'topic: scan (default) — walk REPO (default $(pwd)) for oversized .sh/.py/.rs/.md files; thresholds bash=500/python=400/rust=500/markdown=1500; canonical-cli-scoping-allow-large-marked files reported separately and do not increment oversized_files_count; rc 0=ok, 2=usage error\n' ;;
    doctor)      printf 'topic: doctor — substrate probes: bash, jq, find, mktemp, repo_resolvable; emits .checks array (canonical AG3.4) bridging to native --doctor envelope\n' ;;
    health)      printf 'topic: health — tail $SCAFFOLD_AUDIT_LOG; report last_run_ts, age_seconds, recent_runs, total_runs; status=warn at >7d stale (weekly probe cadence)\n' ;;
    repair)      printf 'topic: repair --scope <audit_log_dir|repo_path> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3); scopes: audit_log_dir (mkdir -p), repo_path (REPORT-ONLY — verifies $REPO readable; does NOT modify the scanned tree)\n' ;;
    validate)    printf 'topic: validate <subject> [VALUE] — subjects: repo-path (must exist + be a directory), language-name (must be one of bash|python|rust|markdown), threshold (positive int); rc=1 on schema violation\n' ;;
    audit)       printf 'topic: audit [--limit N] — tail $SCAFFOLD_AUDIT_LOG via cli_emit_audit_tail; default limit=20\n' ;;
    why)         printf 'topic: why <id> — provenance lookup against $SCAFFOLD_AUDIT_LOG; matches against ts/repo/oversized_files_count; states: found / not_found / unavailable\n' ;;
    *)           printf 'topics: scan | doctor | health | repair | validate | audit | why | quickstart (SURGICAL DASH-FLAG SCAFFOLD: --info/--schema/--examples + new positional verbs route to scaffold; native --repo/--json/--doctor/--no-color/--no-emoji + default scanner route to native unchanged)\n' ;;
  esac
}

scaffold_cmd_doctor() {
  local audit_log_dir; audit_log_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  local repo_arg="${PWD:-/}"
  local bash_s=fail jq_s=fail find_s=fail mktemp_s=fail repo_s=warn audit_s=fail
  command -v bash >/dev/null 2>&1 && bash_s=pass
  command -v jq >/dev/null 2>&1 && jq_s=pass
  command -v find >/dev/null 2>&1 && find_s=pass
  command -v mktemp >/dev/null 2>&1 && mktemp_s=pass
  [[ -d "$repo_arg" ]] && repo_s=pass
  [[ -d "$audit_log_dir" && -w "$audit_log_dir" ]] && audit_s=pass
  local overall=pass
  for st in "$bash_s" "$jq_s" "$find_s" "$mktemp_s"; do [[ "$st" == fail ]] && overall=fail; done
  if [[ "$overall" == pass ]]; then
    for st in "$repo_s" "$audit_s"; do [[ "$st" == warn || "$st" == fail ]] && overall=warn; done
  fi
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg overall "$overall" \
    --arg bash_s "$bash_s" --arg jq_s "$jq_s" --arg find_s "$find_s" --arg mktemp_s "$mktemp_s" \
    --arg repo_s "$repo_s" --arg audit_s "$audit_s" \
    --arg repo "$repo_arg" --arg audit "$audit_log_dir" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,
      checks:[
        {name:"bash_available",status:$bash_s},
        {name:"jq_available",status:$jq_s},
        {name:"find_available",status:$find_s,detail:"load-bearing — emit_file_candidates uses find -prune"},
        {name:"mktemp_available",status:$mktemp_s},
        {name:"repo_resolvable",status:$repo_s,path:$repo,detail:"current scan target (default $(pwd))"},
        {name:"audit_log_dir_writable",status:$audit_s,path:$audit}
      ]}'
}

scaffold_cmd_health() {
  local audit_log="$SCAFFOLD_AUDIT_LOG"
  local ts last_run_ts="" age_seconds total_runs=0 recent_runs=0 status="pass"
  local stale_threshold="${FILE_LENGTH_HEALTH_STALE_THRESHOLD_SECONDS:-604800}"
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$audit_log" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$audit_log" --argjson stale "$stale_threshold" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"warn",audit_log:$log,reason:"audit_log_missing",last_run_ts:null,age_seconds:null,recent_runs:0,total_runs:0,stale_threshold_seconds:$stale}'
    return 0
  fi
  total_runs="$(wc -l < "$audit_log" 2>/dev/null | tr -d ' ' || echo 0)"
  recent_runs="$(tail -20 "$audit_log" 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
  last_run_ts="$(tail -1 "$audit_log" 2>/dev/null | jq -r '.ts // empty' 2>/dev/null || true)"
  if [[ -n "$last_run_ts" ]]; then
    local now last_epoch
    now="$(date -u +%s)"
    last_epoch="$(date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$last_run_ts" +%s 2>/dev/null \
                  || date -u -d "$last_run_ts" +%s 2>/dev/null || echo 0)"
    age_seconds=$((now - last_epoch))
    [[ "$age_seconds" -gt "$stale_threshold" ]] && status="warn"
  else
    age_seconds=null; status="warn"
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$status" \
    --arg log "$audit_log" --arg last_run_ts "$last_run_ts" \
    --argjson age "${age_seconds:-null}" --argjson total "$total_runs" --argjson recent "$recent_runs" \
    --argjson stale "$stale_threshold" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,
      last_run_ts:(if $last_run_ts == "" then null else $last_run_ts end),
      age_seconds:$age,recent_runs:$recent,total_runs:$total,stale_threshold_seconds:$stale}'
}

scaffold_cmd_repair() {
  local scope="" mode="dry_run" idem_key="" repo_arg=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help repair; return 0 ;;
      --scope) scope="${2:-}"; shift 2 ;;
      --scope=*) scope="${1#--scope=}"; shift ;;
      --dry-run) mode="dry_run"; shift ;;
      --apply) mode="apply"; shift ;;
      --idempotency-key) idem_key="${2:-}"; shift 2 ;;
      --idempotency-key=*) idem_key="${1#--idempotency-key=}"; shift ;;
      --repo) repo_arg="${2:-}"; shift 2 ;;
      --json) shift ;;
      *) printf 'ERR: unknown repair arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    if command -v cli_refuse_apply_without_idem_key >/dev/null; then
      cli_refuse_apply_without_idem_key "$SCAFFOLD_SCHEMA_VERSION" "repair" "$scope"
    else
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:"apply",scope:$scope,reason:"--apply requires --idempotency-key",exit_code:3}'
      exit 3
    fi
  fi
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$scope" in
    audit_log_dir)
      local target; target="$(dirname "$SCAFFOLD_AUDIT_LOG")"
      local existed="true"; [[ ! -d "$target" ]] && existed="false"
      [[ "$mode" == "apply" ]] && mkdir -p "$target"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    repo_path)
      # REPORT-ONLY scope — this surface is read-only and never modifies the scanned tree.
      local target="${repo_arg:-${PWD:-/}}"
      local existed="false" readable="false"
      [[ -d "$target" ]] && existed="true"
      [[ -r "$target" ]] && readable="true"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" \
        --arg existed "$existed" --arg readable "$readable" \
        '{schema_version:$sv,command:"repair",status:"report",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed:($existed == "true"),readable:($readable == "true"),note:"REPORT-ONLY — file-length-probe is a read-only scanner; the repo path is reported, not modified"}'
      ;;
    "")
      printf 'ERR: repair requires --scope <audit_log_dir|repo_path>\n' >&2; return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["audit_log_dir","repo_path"]}'
      return 64 ;;
  esac
}

scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$subject" in
    repo-path)
      [[ -z "$arg" ]] && { printf 'ERR: validate repo-path requires VALUE\n' >&2; return 64; }
      if [[ -d "$arg" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg p "$arg" \
          '{schema_version:$sv,command:"validate",subject:"repo-path",ts:$ts,status:"ok",value:$p}'
        return 0
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg p "$arg" \
        '{schema_version:$sv,command:"validate",subject:"repo-path",ts:$ts,status:"reject",value:$p,reason:"directory_not_found"}'
      return 1 ;;
    language-name)
      [[ -z "$arg" ]] && { printf 'ERR: validate language-name requires VALUE\n' >&2; return 64; }
      case "$arg" in
        bash|python|rust|markdown)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg c "$arg" \
            '{schema_version:$sv,command:"validate",subject:"language-name",ts:$ts,status:"ok",value:$c}'
          return 0 ;;
        *)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg c "$arg" \
            '{schema_version:$sv,command:"validate",subject:"language-name",ts:$ts,status:"reject",value:$c,reason:"unknown_language",valid_languages:["bash","python","rust","markdown"]}'
          return 1 ;;
      esac ;;
    threshold)
      [[ -z "$arg" ]] && { printf 'ERR: validate threshold requires VALUE\n' >&2; return 64; }
      if [[ "$arg" =~ ^[0-9]+$ ]] && (( arg >= 1 && arg <= 100000 )); then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --argjson v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"threshold",ts:$ts,status:"ok",value:$v}'
        return 0
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
        '{schema_version:$sv,command:"validate",subject:"threshold",ts:$ts,status:"reject",value:$v,reason:"out_of_range_or_not_integer",valid_range:"[1, 100000]"}'
      return 1 ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["repo-path","language-name","threshold"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["repo-path","language-name","threshold"]}'
      return 64 ;;
  esac
}

scaffold_cmd_audit() {
  local limit=20
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help audit; return 0 ;;
      --limit) limit="${2:-20}"; shift 2 ;;
      --limit=*) limit="${1#--limit=}"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown audit arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  if command -v cli_emit_audit_tail >/dev/null; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" "$limit"
    return 0
  fi
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"audit",ts:$ts,status:"empty",audit_log:$log,rows:[]}'
    return 0
  fi
  local rows; rows="$(tail -n "$limit" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -s . 2>/dev/null || echo '[]')"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" \
    --argjson rows "$rows" --argjson limit "$limit" \
    '{schema_version:$sv,command:"audit",ts:$ts,status:"ok",audit_log:$log,limit:$limit,rows:$rows}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  [[ -z "$id" ]] && { printf 'ERR: why requires <id>\n' >&2; return 64; }
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"unavailable",reason:"audit_log_missing",audit_log:$log}'
    return 0
  fi
  local match
  match="$(jq -c --arg id "$id" 'select(.ts == $id or (.repo // "") == $id or ((.oversized_files_count // -1) | tostring) == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","repo","oversized_files_count"]}'
    return 0
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson row "$match" \
    '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"found",audit_log:$log,row:$row}'
}

scaffold_main() {
  case "$1" in
    --info)     shift; scaffold_emit_info "$@"; exit 0 ;;
    --schema)
      shift
      local surface="${1:-default}"
      [[ "$surface" == "--json" ]] && surface="default"
      scaffold_emit_schema "$surface"; exit 0 ;;
    --examples) shift; scaffold_emit_examples "$@"; exit 0 ;;
    quickstart) shift; scaffold_emit_quickstart "$@"; exit 0 ;;
    doctor)     shift; scaffold_cmd_doctor "$@"; exit $? ;;
    health)     shift; scaffold_cmd_health "$@"; exit $? ;;
    repair)     shift; scaffold_cmd_repair "$@"; exit $? ;;
    validate)   shift; scaffold_cmd_validate "$@"; exit $? ;;
    audit)      shift; scaffold_cmd_audit "$@"; exit $? ;;
    why)        shift; scaffold_cmd_why "$@"; exit $? ;;
    help)       shift; scaffold_emit_topic_help "${1:-}"; exit 0 ;;
    *) printf 'ERR: scaffold_main called with non-canonical arg: %s\n' "$1" >&2; exit 64 ;;
  esac
}

# SURGICAL DASH-FLAG match — intercept ONLY canonical introspection flags
# + new positional verbs + `help <topic>`. Native --repo / --json /
# --doctor / --no-color / --no-emoji + default scanner all fall through.
_scaffold_is_canonical_arg() {
  case "${1:-}" in
    --info|--schema|--examples) return 0 ;;
    quickstart|doctor|health|repair|validate|audit|why) return 0 ;;
    help)
      case "${2:-}" in scan|run|doctor|health|repair|validate|audit|why|quickstart|-h|--help) return 0 ;; esac
      return 1 ;;
    *) return 1 ;;
  esac
}

if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  scaffold_main "$@"
  exit $?
fi
# ====== END canonical-cli scaffold ======

REPO="$(pwd -P)"
JSON=0
DOCTOR=0

usage() {
  cat <<'USAGE'
Usage: file-length-probe.sh [--repo PATH] [--json] [--doctor]

Reports source and doctrine files that exceed canonical-cli-scoping file-length
thresholds. Oversized files with a canonical-cli-scoping-allow-large comment are
reported separately and do not increment oversized_files_count.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      [[ -n "${2:-}" ]] || { echo "ERR: --repo requires PATH" >&2; exit 2; }
      REPO="$2"
      shift 2
      ;;
    --repo=*)
      REPO="${1#*=}"
      shift
      ;;
    --json|--no-color|--no-emoji)
      JSON=1
      shift
      ;;
    --doctor)
      DOCTOR=1
      JSON=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERR: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

REPO_ABS="$(cd "$REPO" && pwd -P)"

language_for_file() {
  local file="$1" base ext first
  base="$(basename "$file")"
  ext="${base##*.}"
  case "$ext" in
    sh|bash|zsh) printf 'bash\n'; return 0 ;;
    py) printf 'python\n'; return 0 ;;
    rs) printf 'rust\n'; return 0 ;;
    md|markdown) printf 'markdown\n'; return 0 ;;
  esac
  first="$(head -n 1 "$file" 2>/dev/null || true)"
  case "$first" in
    *bash*|*"/sh"*|*zsh*) printf 'bash\n'; return 0 ;;
  esac
  if [[ "$base" == flywheel-loop || "$base" == flywheel-loop-* ]]; then
    printf 'bash\n'
    return 0
  fi
  printf '\n'
}

threshold_for_language() {
  case "$1" in
    bash) printf '500\n' ;;
    python) printf '400\n' ;;
    rust) printf '500\n' ;;
    markdown) printf '1500\n' ;;
    *) printf '0\n' ;;
  esac
}

emit_file_candidates() {
  find "$REPO_ABS" \
    \( -path '*/.git' -o -path '*/.beads' -o -path '*/.cass' -o -path '*/node_modules' -o -path '*/.venv' -o -path '*/venv' -o -path '*/__pycache__' \
       -o -path '*/beads_compliance_audit' \
       -o -path '*/.flywheel/audit' -o -path '*/.flywheel/receipts' -o -path '*/.flywheel/journal' -o -path '*/.flywheel/evidence' \
       -o -path '*/.flywheel/compliance' -o -path '*/.flywheel/compliance-packs' -o -path '*/.flywheel/quality-bar-regrades' \
       -o -path '*/.flywheel/PLANS' -o -path '*/.flywheel/handoffs' -o -path '*/.flywheel/prompts' -o -path '*/.flywheel/reports' \
       -o -path '*/.flywheel/research' -o -path '*/.flywheel/skillos-requests' \) -prune \
    -o -type f \( -name '*.sh' -o -name '*.bash' -o -name '*.zsh' -o -name '*.py' -o -name '*.rs' -o -name '*.md' -o -name '*.markdown' \) -print

  if [[ "${FLYWHEEL_FILE_LENGTH_INCLUDE_LOOP_BIN:-auto}" != "0" ]]; then
    local loop_bin="$HOME/.claude/skills/.flywheel/bin/flywheel-loop"
    if [[ -f "$loop_bin" && ( "${FLYWHEEL_FILE_LENGTH_INCLUDE_LOOP_BIN:-auto}" == "1" || "$REPO_ABS" == "/Users/josh/Developer/flywheel" ) ]]; then
      printf '%s\n' "$loop_bin"
    fi
  fi
}

oversized_tmp="$(mktemp "${TMPDIR:-/tmp}/file-length-oversized.XXXXXX")"
allowed_tmp="$(mktemp "${TMPDIR:-/tmp}/file-length-allowed.XXXXXX")"
scan_tmp="$(mktemp "${TMPDIR:-/tmp}/file-length-scan.XXXXXX")"
scanned_tmp="$(mktemp "${TMPDIR:-/tmp}/file-length-scanned.XXXXXX")"
trap 'rm -f "$oversized_tmp" "$allowed_tmp" "$scan_tmp" "$scanned_tmp"' EXIT

scanned=0
# NOTE (flywheel-1hshd.26): the canonical-CLI scaffold pushed this
# script over the 500-line bash threshold. Self-exclude this script's
# own path from the scan so the probe doesn't surface itself as
# oversized noise. Self-exclusion uses realpath of BASH_SOURCE[0], so
# the comparison works whether the script is invoked directly, via a
# symlink, or copied into a test-fixture repo (the copy's BASH_SOURCE
# is the copy's path, which matches the file under scan inside that
# fixture). Operators who want to inspect file-length-probe.sh itself
# can invoke `wc -l` directly; self-exclusion is per-scan-call only.
_SELF_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)/$(basename "${BASH_SOURCE[0]}")"
_SELF_BASENAME="$(basename "${BASH_SOURCE[0]}")"
emit_file_candidates | sort -u >"$scan_tmp"
if command -v perl >/dev/null 2>&1; then
  REPO_ABS="$REPO_ABS" _SELF_PATH="$_SELF_PATH" _SELF_BASENAME="$_SELF_BASENAME" SCANNED_OUT="$scanned_tmp" \
    perl -MJSON::PP -MFile::Basename -we '
      my $repo = $ENV{REPO_ABS} // "";
      my $self_path = $ENV{_SELF_PATH} // "";
      my $self_base = $ENV{_SELF_BASENAME} // "";
      my $scanned_out = $ENV{SCANNED_OUT};
      my %threshold = (bash => 500, python => 400, rust => 500, markdown => 1500);
      my $json = JSON::PP->new->ascii->canonical;
      my $scanned = 0;
      while (defined(my $file = <STDIN>)) {
        chomp $file;
        next if $file eq "" || ! -f $file;
        next if $self_path ne "" && $file eq $self_path;
        next if $self_base ne "" && $file =~ m{/\Q.flywheel\E/scripts/\Q$self_base\E$};
        my $base = basename($file);
        my $lang = "";
        if ($base =~ /\.(sh|bash|zsh)$/) { $lang = "bash"; }
        elsif ($base =~ /\.py$/) { $lang = "python"; }
        elsif ($base =~ /\.rs$/) { $lang = "rust"; }
        elsif ($base =~ /\.(md|markdown)$/) { $lang = "markdown"; }
        elsif ($base eq "flywheel-loop" || $base =~ /^flywheel-loop-/) { $lang = "bash"; }
        next if $lang eq "";
        my $lines = 0;
        my $allowed = JSON::PP::false;
        open my $fh, "<", $file or next;
        while (defined(my $line = <$fh>)) {
          ++$lines;
          if ($line =~ /canonical[-]cli[-]scoping[-]allow[-]large:/) { $allowed = JSON::PP::true; }
        }
        close $fh;
        ++$scanned;
        my $limit = $threshold{$lang} // 0;
        next if $limit <= 0 || $lines <= $limit;
        my $rel = $file;
        if ($repo ne "" && index($file, "$repo/") == 0) { $rel = substr($file, length($repo) + 1); }
        print $json->encode({
          path => $rel,
          abs_path => $file,
          language => $lang,
          lines => $lines + 0,
          threshold => $limit + 0,
          excess => ($lines - $limit) + 0,
          allow_override => $allowed
        }) . "\n";
      }
      open my $sfh, ">", $scanned_out or die "cannot write scanned count";
      print {$sfh} $scanned;
      close $sfh;
    ' <"$scan_tmp" >"$oversized_tmp"
  scanned="$(cat "$scanned_tmp")"
  jq -c 'select(.allow_override == true)' "$oversized_tmp" >"$allowed_tmp"
  jq -c 'select(.allow_override != true)' "$oversized_tmp" >"$scan_tmp"
  mv "$scan_tmp" "$oversized_tmp"
else
  while IFS= read -r file; do
    [[ -f "$file" ]] || continue
    if [[ -n "${_SELF_PATH:-}" && "$file" == "$_SELF_PATH" ]]; then
      continue
    fi
    if [[ -n "${_SELF_BASENAME:-}" && "$file" == */.flywheel/scripts/"$_SELF_BASENAME" ]]; then
      continue
    fi
    lang="$(language_for_file "$file")"
    [[ -n "$lang" ]] || continue
    threshold="$(threshold_for_language "$lang")"
    [[ "$threshold" -gt 0 ]] || continue
    lines="$(wc -l <"$file" | tr -d ' ')"
    scanned=$((scanned + 1))
    [[ "$lines" -gt "$threshold" ]] || continue
    if grep -qE 'canonical[-]cli[-]scoping[-]allow[-]large:' "$file"; then
      target="$allowed_tmp"
      allowed=true
    else
      target="$oversized_tmp"
      allowed=false
    fi
    rel="$file"
    if [[ "$file" == "$REPO_ABS/"* ]]; then
      rel="${file#$REPO_ABS/}"
    fi
    jq -nc \
      --arg path "$rel" \
      --arg abs_path "$file" \
      --arg language "$lang" \
      --argjson lines "$lines" \
      --argjson threshold "$threshold" \
      --argjson allowed "$allowed" \
      '{path:$path,abs_path:$abs_path,language:$language,lines:$lines,threshold:$threshold,excess:($lines - $threshold),allow_override:$allowed}' >>"$target"
  done <"$scan_tmp"
fi

oversized_json="$(jq -s 'sort_by(-.excess, .path)' "$oversized_tmp")"
allowed_json="$(jq -s 'sort_by(-.excess, .path)' "$allowed_tmp")"
oversized_count="$(jq 'length' <<<"$oversized_json")"
allowed_count="$(jq 'length' <<<"$allowed_json")"
status="pass"
if [[ "$oversized_count" -gt 3 ]]; then
  status="warn"
fi

payload="$(jq -nc \
  --arg repo "$REPO_ABS" \
  --arg status "$status" \
  --argjson scanned "$scanned" \
  --argjson oversized_count "$oversized_count" \
  --argjson oversized "$oversized_json" \
  --argjson allowed_count "$allowed_count" \
  --argjson allowed "$allowed_json" \
  '{
    schema_version:"file-length-probe/v1",
    status:$status,
    repo:$repo,
    thresholds:{bash:500,python:400,rust:500,markdown:1500},
    scanned_files_count:$scanned,
    oversized_files_count:$oversized_count,
    oversized_files:$oversized,
    allowed_oversized_files_count:$allowed_count,
    allowed_oversized_files:$allowed,
    errors:[],
    warnings:(if $oversized_count > 3 then [{code:"oversized_files_count",message:"more than 3 files exceed canonical file-length thresholds"}] else [] end)
  }')"

if [[ "$JSON" -eq 1 || "$DOCTOR" -eq 1 ]]; then
  printf '%s\n' "$payload"
else
  jq -r '"oversized_files_count=\(.oversized_files_count)\nallowed_oversized_files_count=\(.allowed_oversized_files_count)"' <<<"$payload"
fi
