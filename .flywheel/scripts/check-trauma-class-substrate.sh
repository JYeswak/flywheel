#!/usr/bin/env bash
set -euo pipefail

# ====== BEGIN canonical-cli scaffold (bead flywheel-1hshd.12) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial → passing per bead flywheel-1hshd.12)
# doctor-mode-tier: scaffolded
#
# WZJO9.1.7 FULL-BYPASS variant — native has NO --info/--schema/--examples
# and NO verb subcommands, so scaffold owns every canonical surface.
# Native's only behavior is the read-only B56 trauma-class scanner reached
# by default invocation (no canonical arg). The early-dispatch intercept
# below fires BEFORE the original arg parser sees argv.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="check-trauma-class-substrate/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/check-trauma-class-substrate-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: check-trauma-class-substrate.sh [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
read-only B56 trauma-class scanner (silent-write, destructive-default,
unregistered-process classes).

Canonical CLI surfaces:
  doctor [--json]          probe substrate health (6 named probes)
  health [--json]          last-run status from audit log
  repair --scope <s>       repair scaffold-owned state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
                            Scopes: audit_log_dir (mkdir), registry_path (REPORT-ONLY)
  validate <subject> [v]   per-subject contract validation
                            Subjects: root-path, class-name, audit-row
  audit [--limit N]        recent run history from audit log
  why <id>                 explain provenance for a given id
  quickstart [--json]      operator orientation
  help <topic>             topic help

Introspection:
  --info --json            version, paths, env vars, dependencies, sha256
  --schema [<surface>]     JSON Schema for output envelopes
  --examples --json        curated workflow examples
  --help / -h              this help

Native scanner flags (default invocation, see scanner usage block below):
  --root PATH              scan root (repeatable)
  --repo PATH              alias for primary scan root
  --skill-scripts-dir PATH override skill-scripts root
  --local-bin-dir PATH     override local-bin root
  --launchagents-dir PATH  override LaunchAgents directory
  --registry PATH          plist registry JSONL
  --ps-fixture PATH        deterministic ps replacement (test fixture)
  --json                   emit findings as JSON
USG
}

scaffold_emit_info() {
  if ! command -v cli_emit_info >/dev/null; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "check-trauma-class-substrate.sh" \
      '{schema_version:$sv,command:"info",name:$name,capabilities:["read-only-scanner"],helper_lib_missing:true}'
    return 0
  fi
  # Helper emits .subcommands + .canonical_cli_surfaces but not .capabilities.
  # AG3.1 requires .name + .version + .capabilities — augment via jq pipeline
  # so the canonical envelope carries an explicit capabilities array.
  cli_emit_info \
    "check-trauma-class-substrate.sh" \
    "scaffolded-v1" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help" \
    "FLYWHEEL_TRAUMA_SCAN_REPO,FLYWHEEL_TRAUMA_SCAN_SKILL_SCRIPTS_DIR,FLYWHEEL_TRAUMA_SCAN_LOCAL_BIN,FLYWHEEL_TRAUMA_SCAN_LAUNCHAGENTS_DIR,FLYWHEEL_TRAUMA_SCAN_REGISTRY,FLYWHEEL_TRAUMA_SCAN_PS_FIXTURE,SCAFFOLD_AUDIT_LOG" \
    "$(jq -nc --arg audit "$SCAFFOLD_AUDIT_LOG" '{audit_log:$audit,exit_codes:{no_findings:0,findings_emitted:1,usage_error:2,refused_apply:3,unknown_subject:64}}')" \
    | jq -c '. + {capabilities:["read-only-scanner","b56-trauma-class-detection","silent-write-detector","destructive-default-detector","unregistered-process-detector","plist-registry-cross-check","ps-fixture-injectable"],mutates_state:false,scanner_classes:["silent-write","destructive-default","unregistered-process"]}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default scan",invocation:"check-trauma-class-substrate.sh --json",purpose:"emit B56 trauma-class findings as JSON"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"check-trauma-class-substrate.sh doctor --json",purpose:"probe substrate health (6 named probes)"}'
)"$'\n'"$(jq -nc '{name:"validate class-name",invocation:"check-trauma-class-substrate.sh validate class-name silent-write",purpose:"contract check on a finding class"}'
)"$'\n'"$(jq -nc '{name:"repair audit_log_dir",invocation:"check-trauma-class-substrate.sh repair --scope audit_log_dir --apply --idempotency-key tcs-$(date +%Y%m%d) --json",purpose:"create audit log dir under canonical apply contract"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe substrate",command:"check-trauma-class-substrate.sh doctor --json"}'
)"$'\n'"$(jq -nc '{step:2,action:"run scanner",command:"check-trauma-class-substrate.sh --json"}'
)"$'\n'"$(jq -nc '{step:3,action:"audit recent runs",command:"check-trauma-class-substrate.sh audit --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,validate,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-default}"
  local input_schema output_schema
  input_schema='{"type":"object","properties":{"root":{"type":"string","description":"--root PATH (repeatable)"},"repo":{"type":"string"},"registry":{"type":"string"},"launchagents_dir":{"type":"string"},"ps_fixture":{"type":"string"},"json":{"type":"boolean"}}}'
  output_schema='{"type":"array","items":{"type":"object","required":["scan_ts","class","file","line","severity","suggested_bead","matched_pattern"],"properties":{"scan_ts":{"type":"string","format":"date-time"},"class":{"type":"string","enum":["silent-write","destructive-default","unregistered-process"]},"file":{"type":"string"},"line":{"type":["integer","null"]},"severity":{"type":"string","enum":["medium","high","critical"]},"suggested_bead":{"type":"string"},"matched_pattern":{"type":"string"},"exempt_reason":{"type":["string","null"]}}}}'
  case "$surface" in
    doctor)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"doctor",fields:{ts:"ISO8601",status:"pass|warn|fail",checks:"array of {name,status,detail?,path?}"}}'
      ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"health",fields:{ts:"ISO8601",status:"pass|warn|fail",audit_log:"path",last_run_ts:"ISO8601 or null",age_seconds:"int or null",recent_runs:"int (last 20)",total_runs:"int",stale_threshold_seconds:"int"}}'
      ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"repair",scopes:["audit_log_dir","registry_path"],contract:{requires_idempotency_key_when_apply:true,refusal_exit_code:3,dry_run_default:true},env:{audit_log:"SCAFFOLD_AUDIT_LOG",registry:"FLYWHEEL_TRAUMA_SCAN_REGISTRY"}}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"validate",subjects:["root-path","class-name","audit-row"],contract:{rejects_with_rc1:"on schema violation",root_path_must_be_absolute:true,class_name_enum:["silent-write","destructive-default","unregistered-process"]}}'
      ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit",audit_log_env:"SCAFFOLD_AUDIT_LOG",row_shape:{ts:"ISO8601",action:"string"},limit_default:20}'
      ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"why",input:"id (ts OR file OR class OR run_id)",states:["found","not_found","unavailable"],source:"$SCAFFOLD_AUDIT_LOG"}'
      ;;
    findings|default|*)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --argjson in "$input_schema" --argjson out "$output_schema" \
        '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why","findings"],input_schema:$in,output_schema:$out,note:"check-trauma-class-substrate.sh = read-only B56 trauma-class scanner; default invocation emits findings array"}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default invocation routes to the original read-only B56 trauma-class scanner: walks --root paths (default REPO_ROOT + skill-scripts-dir + local-bin-dir), greps for silent-write / destructive-default patterns in shell sources, cross-references LaunchAgents + ps output against the plist registry; exit 0 = no findings, 1 = findings emitted, 2 = usage error\n' ;;
    doctor)   printf 'topic: doctor — substrate probes: bash, jq, mktemp, PlistBuddy (load-bearing — used by scan_unregistered_plists), registry_path_readable (FLYWHEEL_TRAUMA_SCAN_REGISTRY), audit_log_dir_writable (SCAFFOLD_AUDIT_LOG dirname)\n' ;;
    health)   printf 'topic: health — tails $SCAFFOLD_AUDIT_LOG (default ~/.local/state/flywheel/check-trauma-class-substrate-runs.jsonl); reports last_run_ts, age_seconds, recent_runs, total_runs; status=warn at >24h stale (daily scanner cadence)\n' ;;
    repair)   printf 'topic: repair --scope <audit_log_dir|registry_path> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3 refusal); scopes: audit_log_dir (mkdir -p $SCAFFOLD_AUDIT_LOG dirname), registry_path (REPORT-ONLY — verifies $REGISTRY readability; does NOT write registry rows)\n' ;;
    validate) printf 'topic: validate <subject> [VALUE] — subjects: root-path (must be absolute path matching --root arg semantic), class-name (must be one of silent-write|destructive-default|unregistered-process matching scanner enum), audit-row (JSONL with ts + action required); rc=1 on schema violation\n' ;;
    audit)    printf 'topic: audit [--limit N] — tail $SCAFFOLD_AUDIT_LOG via cli_emit_audit_tail; default limit=20\n' ;;
    why)      printf 'topic: why <id> — provenance lookup against $SCAFFOLD_AUDIT_LOG; matches against ts/file/class/run_id; states: found / not_found / unavailable\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate | audit | why | quickstart (FULL-BYPASS: native has no canonical surfaces; scaffold owns --info, --schema, --examples, all verbs)\n' ;;
  esac
}

# ---------- canonical-cli verb implementations ----------

scaffold_cmd_doctor() {
  local repo_root="$_SCAFFOLD_REPO_ROOT"
  local registry="${FLYWHEEL_TRAUMA_SCAN_REGISTRY:-$HOME/.local/state/flywheel/plist-registry.jsonl}"
  local launchagents="${FLYWHEEL_TRAUMA_SCAN_LAUNCHAGENTS_DIR:-$HOME/Library/LaunchAgents}"
  local audit_log_dir; audit_log_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  local bash_status="fail" jq_status="fail" mktemp_status="fail"
  local plistbuddy_status="warn" registry_status="warn" launchagents_status="warn" audit_dir_status="fail"
  local overall="pass"

  command -v bash >/dev/null 2>&1 && bash_status="pass"
  command -v jq >/dev/null 2>&1 && jq_status="pass"
  command -v mktemp >/dev/null 2>&1 && mktemp_status="pass"
  [[ -x /usr/libexec/PlistBuddy ]] && plistbuddy_status="pass"
  [[ -r "$registry" ]] && registry_status="pass"
  [[ -d "$launchagents" ]] && launchagents_status="pass"
  if [[ -d "$audit_log_dir" && -w "$audit_log_dir" ]]; then
    audit_dir_status="pass"
  fi

  for st in "$bash_status" "$jq_status" "$mktemp_status"; do
    [[ "$st" == "fail" ]] && overall="fail"
  done
  if [[ "$overall" == "pass" ]]; then
    for st in "$plistbuddy_status" "$registry_status" "$launchagents_status" "$audit_dir_status"; do
      [[ "$st" == "warn" || "$st" == "fail" ]] && overall="warn"
    done
  fi

  local ts
  if command -v cli_iso_now >/dev/null; then ts="$(cli_iso_now)"; else ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"; fi

  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$ts" \
    --arg overall "$overall" \
    --arg bash_s "$bash_status" --arg jq_s "$jq_status" --arg mktemp_s "$mktemp_status" \
    --arg plist_s "$plistbuddy_status" --arg reg_s "$registry_status" --arg la_s "$launchagents_status" --arg ad_s "$audit_dir_status" \
    --arg registry "$registry" --arg launchagents "$launchagents" --arg audit_dir "$audit_log_dir" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,
      checks:[
        {name:"bash_available",status:$bash_s},
        {name:"jq_available",status:$jq_s},
        {name:"mktemp_available",status:$mktemp_s},
        {name:"PlistBuddy_available",status:$plist_s,path:"/usr/libexec/PlistBuddy",detail:"load-bearing — used by scan_unregistered_plists"},
        {name:"registry_path_readable",status:$reg_s,path:$registry,detail:"plist registry JSONL"},
        {name:"launchagents_dir_present",status:$la_s,path:$launchagents},
        {name:"audit_log_dir_writable",status:$ad_s,path:$audit_dir}
      ]
    }'
}

scaffold_cmd_health() {
  local audit_log="$SCAFFOLD_AUDIT_LOG"
  local ts last_run_ts="" age_seconds total_runs=0 recent_runs=0 status="pass"
  local stale_threshold="${CHECK_TRAUMA_CLASS_SUBSTRATE_HEALTH_STALE_THRESHOLD_SECONDS:-86400}"
  if command -v cli_iso_now >/dev/null; then ts="$(cli_iso_now)"; else ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"; fi
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
                  || date -u -d "$last_run_ts" +%s 2>/dev/null \
                  || echo 0)"
    age_seconds=$((now - last_epoch))
    [[ "$age_seconds" -gt "$stale_threshold" ]] && status="warn"
  else
    age_seconds=null
    status="warn"
  fi
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$status" \
    --arg log "$audit_log" --arg last_run_ts "$last_run_ts" \
    --argjson age "${age_seconds:-null}" \
    --argjson total "$total_runs" --argjson recent "$recent_runs" \
    --argjson stale "$stale_threshold" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,
      last_run_ts:(if $last_run_ts == "" then null else $last_run_ts end),
      age_seconds:$age,recent_runs:$recent,total_runs:$total,
      stale_threshold_seconds:$stale}'
}

scaffold_cmd_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help repair; return 0 ;;
      --scope) scope="${2:-}"; shift 2 ;;
      --scope=*) scope="${1#--scope=}"; shift ;;
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
        '{schema_version:$sv,command:"repair",status:"refused",mode:"apply",scope:$scope,reason:"--apply requires --idempotency-key",exit_code:3}'
      exit 3
    fi
  fi
  local ts
  if command -v cli_iso_now >/dev/null; then ts="$(cli_iso_now)"; else ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"; fi
  case "$scope" in
    audit_log_dir)
      local target; target="$(dirname "$SCAFFOLD_AUDIT_LOG")"
      local existed="true"
      [[ ! -d "$target" ]] && existed="false"
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        if command -v cli_audit_append >/dev/null; then
          cli_audit_append --action repair --status apply --scope audit_log_dir \
            --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
        fi
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    registry_path)
      # REPORT-ONLY scope — registry rows are written by plist register/
      # unregister scripts elsewhere; this surface only reads. We report
      # whether the configured path exists + is readable. Sister 1hshd.11
      # established the REPORT-ONLY pattern (sync_helper_path scope).
      local target="${FLYWHEEL_TRAUMA_SCAN_REGISTRY:-$HOME/.local/state/flywheel/plist-registry.jsonl}"
      local existed="false" readable="false"
      [[ -f "$target" ]] && existed="true"
      [[ -r "$target" ]] && readable="true"
      if [[ "$mode" == "apply" ]] && command -v cli_audit_append >/dev/null; then
        cli_audit_append --action repair --status report --scope registry_path \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" \
        --arg existed "$existed" --arg readable "$readable" \
        '{schema_version:$sv,command:"repair",status:"report",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed:($existed == "true"),readable:($readable == "true"),note:"REPORT-ONLY scope — registry rows owned by plist register/unregister scripts; this surface is read-only against the registry"}'
      ;;
    "")
      printf 'ERR: repair requires --scope <audit_log_dir|registry_path>\n' >&2
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["audit_log_dir","registry_path"]}'
      return 64 ;;
  esac
}

scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts
  if command -v cli_iso_now >/dev/null; then ts="$(cli_iso_now)"; else ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"; fi
  case "$subject" in
    root-path)
      [[ -z "$arg" ]] && { printf 'ERR: validate root-path requires VALUE arg\n' >&2; return 64; }
      if [[ "$arg" == /* ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg p "$arg" \
          '{schema_version:$sv,command:"validate",subject:"root-path",ts:$ts,status:"ok",value:$p}'
        return 0
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg p "$arg" \
        '{schema_version:$sv,command:"validate",subject:"root-path",ts:$ts,status:"reject",value:$p,reason:"not_absolute_path",contract:"--root arg must be an absolute path"}'
      return 1 ;;
    class-name)
      [[ -z "$arg" ]] && { printf 'ERR: validate class-name requires VALUE arg\n' >&2; return 64; }
      case "$arg" in
        silent-write|destructive-default|unregistered-process)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg c "$arg" \
            '{schema_version:$sv,command:"validate",subject:"class-name",ts:$ts,status:"ok",value:$c}'
          return 0 ;;
        *)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg c "$arg" \
            '{schema_version:$sv,command:"validate",subject:"class-name",ts:$ts,status:"reject",value:$c,reason:"unknown_class",valid_classes:["silent-write","destructive-default","unregistered-process"]}'
          return 1 ;;
      esac ;;
    audit-row)
      if [[ -z "$arg" || ! -r "$arg" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg path "$arg" \
          '{schema_version:$sv,command:"validate",subject:"audit-row",ts:$ts,status:"reject",path:$path,reason:"file_not_readable"}'
        return 1
      fi
      local bad
      bad="$(jq -c 'select((.ts // empty) == "" or (.action // empty) == "") | {missing: ([(if (.ts // empty) == "" then "ts" else empty end), (if (.action // empty) == "" then "action" else empty end)])}' "$arg" 2>/dev/null | head -5 || true)"
      if [[ -n "$bad" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg path "$arg" --arg bad "$bad" \
          '{schema_version:$sv,command:"validate",subject:"audit-row",ts:$ts,status:"reject",path:$path,reason:"missing_required_fields",sample:$bad}'
        return 1
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg path "$arg" \
        '{schema_version:$sv,command:"validate",subject:"audit-row",ts:$ts,status:"ok",path:$path}' ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["root-path","class-name","audit-row"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["root-path","class-name","audit-row"]}'
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
      '{schema_version:$sv,command:"audit",ts:$ts,status:"empty",audit_log:$log,reason:"audit_log_missing",rows:[]}'
    return 0
  fi
  local rows; rows="$(tail -n "$limit" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -s . 2>/dev/null || echo '[]')"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" \
    --argjson rows "$rows" --argjson limit "$limit" \
    '{schema_version:$sv,command:"audit",ts:$ts,status:"ok",audit_log:$log,limit:$limit,rows:$rows}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  [[ -z "$id" ]] && { printf 'ERR: why requires <id> argument\n' >&2; return 64; }
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"unavailable",reason:"audit_log_missing",audit_log:$log}'
    return 0
  fi
  local match
  match="$(jq -c --arg id "$id" 'select(.ts == $id or (.file // "") == $id or (.class // "") == $id or (.run_id // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","file","class","run_id"]}'
    return 0
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson row "$match" \
    '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"found",audit_log:$log,row:$row}'
}

# ---------- scaffolded main dispatcher ----------

scaffold_main() {
  if [[ $# -eq 0 ]]; then scaffold_usage; exit 0; fi
  case "$1" in
    -h|--help)  scaffold_usage; exit 0 ;;
    --info)     shift; scaffold_emit_info "$@"; exit 0 ;;
    --schema)   shift; scaffold_emit_schema "${1:-default}"; exit 0 ;;
    --examples) shift; scaffold_emit_examples "$@"; exit 0 ;;
    doctor)     shift; scaffold_cmd_doctor "$@"; exit $? ;;
    health)     shift; scaffold_cmd_health "$@"; exit $? ;;
    repair)     shift; scaffold_cmd_repair "$@"; exit $? ;;
    validate)   shift; scaffold_cmd_validate "$@"; exit $? ;;
    audit)      shift; scaffold_cmd_audit "$@"; exit $? ;;
    why)        shift; scaffold_cmd_why "$@"; exit $? ;;
    quickstart) shift; scaffold_emit_quickstart "$@"; exit 0 ;;
    help)       shift; scaffold_emit_topic_help "${1:-}"; exit 0 ;;
    *)
      printf 'ERR: unknown canonical subcommand: %s\n' "$1" >&2
      scaffold_usage >&2
      exit 64 ;;
  esac
}

# WZJO9.1.7 FULL-BYPASS — every canonical surface is owned by scaffold.
# Native owns only the default-invocation read-only B56 scanner.
_scaffold_is_canonical_arg() {
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart) return 0 ;;
    --info|--schema|--examples) return 0 ;;
    help)
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

OUTPUT_JSON=0
ROOTS=()
ROOTS_OVERRIDE=0

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/$(basename "${BASH_SOURCE[0]}")"
REPO_ROOT="${FLYWHEEL_TRAUMA_SCAN_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
SKILL_SCRIPTS_DIR="${FLYWHEEL_TRAUMA_SCAN_SKILL_SCRIPTS_DIR:-$HOME/.claude/skills/.flywheel/scripts}"
LOCAL_BIN_DIR="${FLYWHEEL_TRAUMA_SCAN_LOCAL_BIN:-$HOME/.local/bin}"
LAUNCHAGENTS_DIR="${FLYWHEEL_TRAUMA_SCAN_LAUNCHAGENTS_DIR:-$HOME/Library/LaunchAgents}"
REGISTRY="${FLYWHEEL_TRAUMA_SCAN_REGISTRY:-$HOME/.local/state/flywheel/plist-registry.jsonl}"
PS_FIXTURE="${FLYWHEEL_TRAUMA_SCAN_PS_FIXTURE:-}"
SCAN_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
FINDINGS='[]'

usage() {
    cat <<'USAGE'
Usage:
  check-trauma-class-substrate.sh [--json] [--root PATH ...]
  check-trauma-class-substrate.sh --repo PATH --json

Read-only B56 trauma-class scanner.

Exit:
  0 = no findings
  1 = findings emitted
  2 = usage error
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) OUTPUT_JSON=1; shift ;;
        --root) [[ $# -ge 2 ]] || { printf 'usage error: --root requires PATH\n' >&2; exit 2; }; ROOTS+=("$2"); ROOTS_OVERRIDE=1; shift 2 ;;
        --root=*) ROOTS+=("${1#*=}"); ROOTS_OVERRIDE=1; shift ;;
        --repo) [[ $# -ge 2 ]] || { printf 'usage error: --repo requires PATH\n' >&2; exit 2; }; REPO_ROOT="$2"; shift 2 ;;
        --repo=*) REPO_ROOT="${1#*=}"; shift ;;
        --skill-scripts-dir) [[ $# -ge 2 ]] || { printf 'usage error: --skill-scripts-dir requires PATH\n' >&2; exit 2; }; SKILL_SCRIPTS_DIR="$2"; shift 2 ;;
        --skill-scripts-dir=*) SKILL_SCRIPTS_DIR="${1#*=}"; shift ;;
        --local-bin-dir) [[ $# -ge 2 ]] || { printf 'usage error: --local-bin-dir requires PATH\n' >&2; exit 2; }; LOCAL_BIN_DIR="$2"; shift 2 ;;
        --local-bin-dir=*) LOCAL_BIN_DIR="${1#*=}"; shift ;;
        --launchagents-dir) [[ $# -ge 2 ]] || { printf 'usage error: --launchagents-dir requires PATH\n' >&2; exit 2; }; LAUNCHAGENTS_DIR="$2"; shift 2 ;;
        --launchagents-dir=*) LAUNCHAGENTS_DIR="${1#*=}"; shift ;;
        --registry) [[ $# -ge 2 ]] || { printf 'usage error: --registry requires PATH\n' >&2; exit 2; }; REGISTRY="$2"; shift 2 ;;
        --registry=*) REGISTRY="${1#*=}"; shift ;;
        --ps-fixture) [[ $# -ge 2 ]] || { printf 'usage error: --ps-fixture requires PATH\n' >&2; exit 2; }; PS_FIXTURE="$2"; shift 2 ;;
        --ps-fixture=*) PS_FIXTURE="${1#*=}"; shift ;;
        --help|-h) usage; exit 0 ;;
        --) shift; break ;;
        -*) printf 'usage error: unknown arg: %s\n' "$1" >&2; usage >&2; exit 2 ;;
        *) ROOTS+=("$1"); ROOTS_OVERRIDE=1; shift ;;
    esac
done

if [[ "$ROOTS_OVERRIDE" -eq 0 ]]; then
    ROOTS=("$REPO_ROOT" "$SKILL_SCRIPTS_DIR" "$LOCAL_BIN_DIR")
fi

add_finding() {
    local class="$1" file="$2" line="$3" severity="$4" suggested="$5" matched="$6"
    local line_json
    if [[ "$line" == "null" ]]; then
        line_json="null"
    else
        line_json="$line"
    fi
    FINDINGS="$(jq \
        --arg scan_ts "$SCAN_TS" \
        --arg class "$class" \
        --arg file "$file" \
        --arg severity "$severity" \
        --arg suggested_bead "$suggested" \
        --arg matched_pattern "$matched" \
        --argjson line "$line_json" \
        '. + [{
          scan_ts:$scan_ts,
          class:$class,
          file:$file,
          line:$line,
          severity:$severity,
          suggested_bead:$suggested_bead,
          matched_pattern:$matched_pattern,
          exempt_reason:null
        }]' <<<"$FINDINGS")"
}

is_probable_source_file() {
    local file="$1"
    [[ -f "$file" ]] || return 1
    [[ "$file" == "$SCRIPT_PATH" ]] && return 1
    case "$file" in
        "$REPO_ROOT/.git/"*|"$REPO_ROOT/.beads/"*|"$REPO_ROOT/.socraticode/"*|"$REPO_ROOT/.flywheel/jeff-corpus/"*) return 1 ;;
        "$REPO_ROOT/tests/"*) return 1 ;;
        "$REPO_ROOT/.flywheel/PLANS/"*|"$REPO_ROOT/.flywheel/archive/"*) return 1 ;;
    esac
    case "$file" in
        *.sh|*.bash|*.zsh|*.command) return 0 ;;
    esac
    [[ -x "$file" ]] && return 0
    return 1
}

context_for_line() {
    local file="$1" line="$2" span="${3:-12}" start end
    start=$((line - span))
    [[ "$start" -lt 1 ]] && start=1
    end=$((line + span))
    sed -n "${start},${end}p" "$file" 2>/dev/null || true
}

silent_write_exempt() {
    local file="$1" line="$2"
    case "$file" in
        */lib/jsonl-append.sh|*/flywheel-watchers/lib/jsonl-append.sh) return 0 ;;
    esac
    context_for_line "$file" "$line" 8 | grep -Eq 'fw_jsonl_append_validated|source .*(jsonl-append\.sh)' && return 0
    return 1
}

has_nearby_apply_or_dry_run_gate() {
    local file="$1" line="$2"
    context_for_line "$file" "$line" 16 | grep -Eq -- '--apply|--dry-run|FW_APPLY|FW_DRY_RUN|DRY_RUN|dry_run|fw_effective_dry_run|apply_required|preview|planned_actions'
}

scan_silent_writes() {
    local file="$1" lineno text
    while IFS=: read -r lineno text; do
        [[ -n "$lineno" ]] || continue
        [[ "$text" =~ ^[[:space:]]*# ]] && continue
        if grep -Eq '(^|[^[:alnum:]_])(printf|echo)([[:space:]]|$).*>>' <<<"$text" \
            && grep -Eq '(\.(jsonl|json|log)([^[:alnum:]_]|$)|LEDGER|REGISTRY|LOG|STATE|DISPATCH|HISTORY)' <<<"$text"; then
            if ! silent_write_exempt "$file" "$lineno"; then
                add_finding "silent-write" "$file" "$lineno" "high" "B56-FIX-02 or new" "printf/echo append without validated readback"
            fi
        fi
    done < <(grep -nE '(^|[^[:alnum:]_])(printf|echo)([[:space:]]|$).*>>' "$file" 2>/dev/null || true)
}

scan_destructive_defaults() {
    local file="$1" lineno text label regex
    local labels=(
        "launchctl bootout"
        "launchctl unload"
        "kill -9"
        "rm -rf"
        "docker prune --force"
        "git reset --hard"
    )
    local regexes=(
        '(^|[^[:alnum:]_-])launchctl[[:space:]]+bootout([[:space:]]|$)'
        '(^|[^[:alnum:]_-])launchctl[[:space:]]+unload([[:space:]]|$)'
        '(^|[^[:alnum:]_-])kill[[:space:]]+-9([[:space:]]|$)'
        '(^|[^[:alnum:]_-])rm[[:space:]]+-[^[:space:]]*r[^[:space:]]*f|(^|[^[:alnum:]_-])rm[[:space:]]+-[^[:space:]]*f[^[:space:]]*r'
        '(^|[^[:alnum:]_-])docker([[:space:]]|$).*prune([[:space:]]|$).*--force'
        '(^|[^[:alnum:]_-])git[[:space:]]+reset[[:space:]]+--hard([[:space:]]|$)'
    )
    for idx in "${!labels[@]}"; do
        label="${labels[$idx]}"
        regex="${regexes[$idx]}"
        while IFS=: read -r lineno text; do
            [[ -n "$lineno" ]] || continue
            [[ "$text" =~ ^[[:space:]]*# ]] && continue
            if ! has_nearby_apply_or_dry_run_gate "$file" "$lineno"; then
                case "$label" in
                    "docker prune --force"|"rm -rf") severity="critical" ;;
                    *) severity="high" ;;
                esac
                add_finding "destructive-default" "$file" "$lineno" "$severity" "B56-FIX-05/B56-FIX-06/B56-FIX-10 or new" "$label without nearby apply/dry-run gate"
            fi
        done < <(grep -nE "$regex" "$file" 2>/dev/null || true)
    done
    return 0
}

scan_script_file() {
    local file="$1"
    is_probable_source_file "$file" || return 0
    grep -Iq . "$file" 2>/dev/null || return 0
    scan_silent_writes "$file"
    scan_destructive_defaults "$file"
}

registry_active_labels() {
    if [[ ! -s "$REGISTRY" ]]; then
        printf '[]\n'
        return 0
    fi
    jq -s 'map(select(type == "object" and (.label? | type == "string")))
      | sort_by(.label, (.ts // ""))
      | group_by(.label)
      | map(last | select((.action // "register") != "unregister") | .label)' "$REGISTRY" 2>/dev/null || printf '[]\n'
}

is_registered_label() {
    local label="$1" labels="$2"
    jq -e --arg label "$label" 'index($label)' <<<"$labels" >/dev/null
}

plist_label() {
    local plist="$1" label
    label="$(/usr/libexec/PlistBuddy -c 'Print :Label' "$plist" 2>/dev/null || true)"
    [[ -n "$label" ]] || label="$(basename "$plist" .plist)"
    printf '%s\n' "$label"
}

scan_unregistered_plists() {
    local labels plist label
    labels="$(registry_active_labels)"
    [[ -d "$LAUNCHAGENTS_DIR" ]] || return 0
    while IFS= read -r plist; do
        [[ -n "$plist" ]] || continue
        label="$(plist_label "$plist")"
        case "$label" in
            ai.zeststream.*) ;;
            *) continue ;;
        esac
        if ! is_registered_label "$label" "$labels"; then
            add_finding "unregistered-process" "$plist" "null" "high" "B56-FIX-07/B56-FIX-08 or new" "ai.zeststream LaunchAgent absent from plist registry"
        fi
    done < <(find "$LAUNCHAGENTS_DIR" -maxdepth 1 -type f -name 'ai.zeststream.*.plist' -print 2>/dev/null | sort)
}

process_rows() {
    if [[ -n "$PS_FIXTURE" ]]; then
        cat "$PS_FIXTURE"
    else
        ps -eo pid=,args= 2>/dev/null || true
    fi
}

scan_unregistered_processes() {
    local labels line path base
    labels="$(registry_active_labels)"
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        [[ "$line" == *"check-trauma-class-substrate.sh"* ]] && continue
        [[ "$line" =~ (watcher|auto-dispatch|auto-act|fleet-watch|flywheel-loop|idle-pane) ]] || continue
        path="$(grep -Eo "(/tmp/[^[:space:]]+|${LOCAL_BIN_DIR//\//\\/}/[^[:space:]]+)" <<<"$line" | head -n 1 || true)"
        [[ -n "$path" ]] || continue
        base="$(basename "$path")"
        if ! is_registered_label "$base" "$labels"; then
            add_finding "unregistered-process" "$path" "null" "medium" "B56-FIX-08 or new" "watcher-like background script absent from plist registry"
        fi
    done < <(process_rows)
    return 0
}

for root in "${ROOTS[@]}"; do
    if [[ -f "$root" ]]; then
        scan_script_file "$root"
    elif [[ -d "$root" ]]; then
        while IFS= read -r file; do
            scan_script_file "$file"
        done < <(find "$root" -type f -print 2>/dev/null | sort)
    fi
done

scan_unregistered_plists
scan_unregistered_processes

if [[ "$OUTPUT_JSON" -eq 1 ]]; then
    jq '.' <<<"$FINDINGS"
else
    count="$(jq 'length' <<<"$FINDINGS")"
    if [[ "$count" -eq 0 ]]; then
        printf 'trauma-class-scan findings=0\n'
    else
        printf 'trauma-class-scan findings=%s\n' "$count"
        jq -r '.[] | [.class, .severity, (.file + ":" + ((.line // "null")|tostring)), .matched_pattern, .suggested_bead] | @tsv' <<<"$FINDINGS"
    fi
fi

[[ "$(jq 'length' <<<"$FINDINGS")" -eq 0 ]]
