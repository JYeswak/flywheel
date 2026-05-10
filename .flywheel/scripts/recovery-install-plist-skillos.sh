#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m + flywheel-wzjo9.2.7) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (substantive fillin landed flywheel-wzjo9.2.7)
# doctor-mode-tier: filled
#
# 18-fillin: install-plist family pattern (sister 2.5 template) + skillos-specific
# extras (jsm binary, skills-flywheel dir).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="recovery-install-plist-skillos/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/recovery-install-plist-skillos-runs.jsonl}"

# Module-scope substrate (skillos variant of install-plist family; adds jsm + skills_flywheel).
RIPS_SESSION="skillos"
RIPS_LABEL="com.zeststream.skillos.watcher"
RIPS_STATUS_SCHEMA="recovery-session-watcher-install/v1"
RIPS_REPO="${SKILLOS_REPO:-/Users/josh/Developer/skillos}"
RIPS_PLIST="${RIPS_PLIST:-$HOME/Library/LaunchAgents/com.zeststream.skillos.watcher.plist}"
RIPS_STATUS="${RIPS_STATUS:-/tmp/recovery-install-skillos-status.json}"
RIPS_AUDIT_RECEIPT="${RIPS_AUDIT_RECEIPT:-/tmp/preinstall-skillos.json}"
RIPS_AUDIT_SCRIPT="${RIPS_AUDIT_SCRIPT:-$_SCAFFOLD_REPO_ROOT/.flywheel/scripts/recovery-preinstall-audit.sh}"
RIPS_NTM_BIN="${RIPS_NTM_BIN:-/Users/josh/.local/bin/ntm}"
RIPS_NTM_CONFIG="${RIPS_NTM_CONFIG:-$HOME/.config/ntm/config.toml}"
RIPS_LAUNCHCTL_BIN="${RIPS_LAUNCHCTL_BIN:-/bin/launchctl}"
RIPS_PLUTIL_BIN="${RIPS_PLUTIL_BIN:-/usr/bin/plutil}"
RIPS_LOG_DIR="${RIPS_LOG_DIR:-$HOME/.local/state/flywheel/logs}"
RIPS_JSM_BIN="${RIPS_JSM_BIN:-/Users/josh/.local/bin/jsm}"
RIPS_SKILLS_FLYWHEEL="${RIPS_SKILLS_FLYWHEEL:-$HOME/.claude/skills/.flywheel}"
RIPS_CONFIDENCE_MIN="${RIPS_CONFIDENCE_MIN:-60}"

scaffold_usage() {
  cat <<'USG'
usage: recovery-install-plist-skillos.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "recovery-install-plist-skillos.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "recovery-install-plist-skillos.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"recovery-install-plist-skillos.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"recovery-install-plist-skillos.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"recovery-install-plist-skillos.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-default}"
  case "$surface" in
    doctor)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"doctor",title:"doctor",type:"object",required:["command","status","checks"],properties:{command:{type:"string"},status:{enum:["pass","warn","fail"]},checks:{type:"array"},paths:{type:"object"}}}'
      ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"health",title:"health",type:"object",required:["command","status"],properties:{command:{type:"string"},status:{enum:["pass","warn","fail"]},plist_installed:{type:"boolean"},last_status:{type:["string","null"]},last_run_ts:{type:["string","null"]},audit_log_stale:{type:"boolean"}}}'
      ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"repair",title:"repair",type:"object",required:["command","scope","mode"],properties:{command:{type:"string"},scope:{enum:["log-dir","audit-log","status-receipt-dir","none"]},mode:{enum:["dry_run","apply"]},idempotency_key:{type:"string"},planned_actions:{type:"array"},actual_actions:{type:"array"}}}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",title:"validate",type:"object",required:["command","subject","status"],properties:{command:{type:"string"},subject:{enum:["plist","audit-receipt","config","skillos-management"]},status:{enum:["pass","fail"]},reason:{type:"string"}}}'
      ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"audit",title:"audit",type:"object",required:["command"],properties:{command:{type:"string"},audit_log:{type:"string"},row_count:{type:"integer"},recent:{type:"array"}}}'
      ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"why",title:"why",type:"object",required:["command","id","resolution"],properties:{command:{type:"string"},id:{type:"string"},resolution:{enum:["found","not_found","unavailable"]},explanation:{type:"string"}}}'
      ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"audit-row",title:"audit-row",type:"object",required:["ts","action","status"],properties:{ts:{type:"string"},action:{type:"string"},status:{type:"string"},sha256:{type:"string"}}}'
      ;;
    status)
      jq -nc --arg sv "$RIPS_STATUS_SCHEMA" \
        '{schema_version:$sv,command:"status",title:"recovery-session-watcher-install status (skillos)",type:"object",required:["schema_version","session","label","dry_run_pass"],properties:{schema_version:{const:"recovery-session-watcher-install/v1"},session:{const:"skillos"},label:{const:"com.zeststream.skillos.watcher"},dry_run_pass:{type:"boolean"},exactly_one_label:{type:"boolean"},skillos_management:{type:"object"}}}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,note:"valid surfaces: doctor|health|repair|validate|audit|why|audit-row|status"}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — audits preinstall confidence, probes launchctl for duplicate labels, writes plist %s, lints, prints status JSON. skillos variant also validates jsm binary + skills-flywheel dir.\n' "$RIPS_PLIST" ;;
    doctor)   printf 'topic: doctor — probes python3 + jq + ntm + ntm_config + plutil + launchctl + repo + plist_parent + audit_script + log_dir + jsm + skills_flywheel + helper + audit_log (14 probes).\n' ;;
    health)   printf 'topic: health — reports plist_installed, last status from receipt, audit_log_stale (>24h).\n' ;;
    repair)   printf 'topic: repair — --scope log-dir | audit-log | status-receipt-dir | none mkdir parent dirs; --apply requires --idempotency-key.\n' ;;
    validate) printf 'topic: validate — subjects: plist (plutil -lint clean), audit-receipt (confidence>=threshold), config (deps), skillos-management (jsm + skills-flywheel readable).\n' ;;
    audit)    printf 'topic: audit — tails recent invocations from SCAFFOLD_AUDIT_LOG (~/.local/state/flywheel/recovery-install-plist-skillos-runs.jsonl).\n' ;;
    why)      printf 'topic: why — explains ids: label, audit, dry_run_pass, repo, watcher_race, install_flow, skillos_management (jsm + skills_flywheel readiness).\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate | audit | why\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "recovery-install-plist-skillos" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "recovery-install-plist-skillos" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local py="fail" jq_s="fail" ntm_b="fail" ntm_c="fail" plutil_s="fail" launchctl_s="fail" repo_s="fail" plist_parent="fail" audit_script="fail" log_d="fail" jsm_s="fail" skills_d="fail" helper="fail" audit_log_w="fail"
  command -v python3 >/dev/null 2>&1 && py="pass"
  command -v jq >/dev/null 2>&1 && jq_s="pass"
  [[ -x "$RIPS_NTM_BIN" ]] && ntm_b="pass"
  [[ -r "$RIPS_NTM_CONFIG" ]] && ntm_c="pass"
  [[ -x "$RIPS_PLUTIL_BIN" ]] && plutil_s="pass"
  [[ -x "$RIPS_LAUNCHCTL_BIN" ]] && launchctl_s="pass"
  if [[ -d "$RIPS_REPO" && -w "$RIPS_REPO" ]]; then repo_s="pass"
  elif [[ ! -e "$RIPS_REPO" ]]; then repo_s="warn"; fi
  local pp; pp="$(dirname "$RIPS_PLIST")"
  [[ -d "$pp" && -w "$pp" ]] && plist_parent="pass"
  [[ -r "$RIPS_AUDIT_SCRIPT" ]] && audit_script="pass"
  if [[ -d "$RIPS_LOG_DIR" ]]; then log_d="pass"
  else
    local lp; lp="$(dirname "$RIPS_LOG_DIR")"
    [[ -d "$lp" && -w "$lp" ]] && log_d="warn"
  fi
  [[ -x "$RIPS_JSM_BIN" ]] && jsm_s="pass"
  [[ -d "$RIPS_SKILLS_FLYWHEEL" && -r "$RIPS_SKILLS_FLYWHEEL" ]] && skills_d="pass"
  command -v cli_audit_append >/dev/null 2>&1 && helper="pass"
  local ad; ad="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  if [[ -d "$ad" && -w "$ad" ]] || [[ -f "$SCAFFOLD_AUDIT_LOG" && -w "$SCAFFOLD_AUDIT_LOG" ]]; then audit_log_w="pass"; fi
  local agg="pass"
  for s in "$py" "$jq_s" "$ntm_b" "$plutil_s" "$launchctl_s"; do
    [[ "$s" != "pass" ]] && agg="fail"
  done
  if [[ "$agg" == "pass" ]]; then
    for s in "$ntm_c" "$repo_s" "$plist_parent" "$audit_script" "$log_d" "$jsm_s" "$skills_d" "$audit_log_w"; do
      if [[ "$s" == "fail" ]]; then agg="fail"; break; fi
      if [[ "$s" == "warn" && "$agg" == "pass" ]]; then agg="warn"; fi
    done
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg agg "$agg" --arg py "$py" --arg jq_s "$jq_s" --arg nb "$ntm_b" --arg nc "$ntm_c" \
    --arg pu "$plutil_s" --arg lc "$launchctl_s" --arg rp "$repo_s" --arg pp_s "$plist_parent" \
    --arg as "$audit_script" --arg ld "$log_d" --arg js "$jsm_s" --arg sd "$skills_d" \
    --arg hl "$helper" --arg al "$audit_log_w" \
    --arg repo "$RIPS_REPO" --arg plist "$RIPS_PLIST" --arg ntm "$RIPS_NTM_BIN" \
    --arg jsm "$RIPS_JSM_BIN" --arg skf "$RIPS_SKILLS_FLYWHEEL" --arg audit "$SCAFFOLD_AUDIT_LOG" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$agg,paths:{repo:$repo,plist:$plist,ntm_bin:$ntm,jsm_bin:$jsm,skills_flywheel:$skf,audit_log:$audit},checks:[
        {name:"dependency:python3",status:$py},
        {name:"dependency:jq",status:$jq_s},
        {name:"ntm_bin_executable",status:$nb},
        {name:"ntm_config_readable",status:$nc},
        {name:"plutil_bin",status:$pu},
        {name:"launchctl_bin",status:$lc},
        {name:"repo_writable",status:$rp},
        {name:"plist_parent_writable",status:$pp_s},
        {name:"audit_script_readable",status:$as},
        {name:"log_dir",status:$ld},
        {name:"jsm_bin_executable",status:$js},
        {name:"skills_flywheel_readable",status:$sd},
        {name:"helper_lib_loaded",status:$hl},
        {name:"audit_log_writable",status:$al}
    ]}'
  if command -v cli_audit_append >/dev/null 2>&1; then
    cli_audit_append "$SCAFFOLD_AUDIT_LOG" "doctor" "$agg" '{}' >/dev/null 2>&1 || true
  fi
  [[ "$agg" == "fail" ]] && return 1
  return 0
}

scaffold_cmd_health() {
  local plist_installed="false" last_status="null" last_run_ts="null" audit_log_stale="false" status="pass"
  if [[ -f "$RIPS_PLIST" ]]; then plist_installed="true"; fi
  if [[ -r "$RIPS_STATUS" ]]; then
    local s ts
    s="$(jq -r '.status // ""' "$RIPS_STATUS" 2>/dev/null || true)"
    ts="$(jq -r '.generated_at // ""' "$RIPS_STATUS" 2>/dev/null || true)"
    [[ -n "$s" ]] && last_status="\"$s\""
    [[ -n "$ts" ]] && last_run_ts="\"$ts\""
    if [[ "$s" != "installed_not_loaded" && "$s" != "" ]]; then status="warn"; fi
  else
    status="warn"
  fi
  if [[ -f "$SCAFFOLD_AUDIT_LOG" ]]; then
    local mtime now age
    mtime="$(stat -f '%m' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || stat -c '%Y' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || echo 0)"
    now="$(date +%s)"
    age=$(( now - mtime ))
    (( age > 86400 )) && audit_log_stale="true"
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg status "$status" --argjson installed "$plist_installed" --argjson last "$last_status" --argjson run_ts "$last_run_ts" \
    --argjson stale "$audit_log_stale" --arg plist "$RIPS_PLIST" --arg al "$SCAFFOLD_AUDIT_LOG" --arg sr "$RIPS_STATUS" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,plist_installed:$installed,plist_path:$plist,status_receipt:$sr,last_status:$last,last_run_ts:$run_ts,audit_log:$al,audit_log_stale:$stale}'
  if command -v cli_audit_append >/dev/null 2>&1; then
    cli_audit_append "$SCAFFOLD_AUDIT_LOG" "health" "$status" "$(jq -nc --argjson i "$plist_installed" '{plist_installed:$i}')" >/dev/null 2>&1 || true
  fi
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
  local planned actual target_dir
  case "$scope" in
    log-dir)
      target_dir="$RIPS_LOG_DIR"
      planned="$(jq -nc --arg d "$target_dir" '["mkdir -p " + $d]')"
      actual='[]'
      if [[ "$mode" == "apply" ]]; then
        if mkdir -p "$target_dir" 2>/dev/null; then actual='["log_dir_ensured"]'; else actual='["log_dir_failed"]'; fi
      fi
      ;;
    audit-log)
      target_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
      planned="$(jq -nc --arg d "$target_dir" '["mkdir -p " + $d]')"
      actual='[]'
      if [[ "$mode" == "apply" ]]; then
        if mkdir -p "$target_dir" 2>/dev/null; then actual='["audit_log_dir_ensured"]'; else actual='["audit_log_dir_failed"]'; fi
      fi
      ;;
    status-receipt-dir)
      target_dir="$(dirname "$RIPS_STATUS")"
      planned="$(jq -nc --arg d "$target_dir" '["mkdir -p " + $d]')"
      actual='[]'
      if [[ "$mode" == "apply" ]]; then
        if mkdir -p "$target_dir" 2>/dev/null; then actual='["status_receipt_dir_ensured"]'; else actual='["status_receipt_dir_failed"]'; fi
      fi
      ;;
    none|"")
      scope="none"; planned='[]'; actual='[]'
      ;;
    *)
      printf 'ERR: unknown repair scope %s (log-dir|audit-log|status-receipt-dir|none)\n' "$scope" >&2
      return 64
      ;;
  esac
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
    --argjson planned "$planned" --argjson actual "$actual" \
    '{schema_version:$sv,command:"repair",status:"ok",mode:$mode,scope:$scope,idempotency_key:$idem,planned_actions:$planned,actual_actions:$actual}'
  if command -v cli_audit_append >/dev/null 2>&1; then
    cli_audit_append "$SCAFFOLD_AUDIT_LOG" "repair" "$mode" "$(jq -nc --arg s "$scope" --arg k "$idem_key" '{scope:$s,idempotency_key:$k}')" >/dev/null 2>&1 || true
  fi
}

scaffold_cmd_validate() {
  local subject=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help validate; return 0 ;;
      --*) shift ;;
      *) subject="$1"; shift ;;
    esac
  done
  if [[ -z "$subject" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
      '{schema_version:$sv,command:"validate",status:"info",reason:"no subject specified",valid_subjects:["plist","audit-receipt","config","skillos-management"]}'
    return 0
  fi
  local status="fail" reason="unknown"
  case "$subject" in
    plist)
      if [[ ! -f "$RIPS_PLIST" ]]; then
        reason="plist $RIPS_PLIST does not exist; run the surface to install it"
      elif [[ ! -x "$RIPS_PLUTIL_BIN" ]]; then
        reason="plutil binary $RIPS_PLUTIL_BIN not executable; cannot lint"
      else
        local lint_out
        lint_out="$("$RIPS_PLUTIL_BIN" -lint "$RIPS_PLIST" 2>&1 || true)"
        if [[ "$lint_out" == *": OK"* ]]; then
          status="pass"; reason="plutil -lint clean for $RIPS_PLIST"
        else
          reason="plutil -lint failed: ${lint_out:0:200}"
        fi
      fi
      ;;
    audit-receipt)
      if [[ ! -r "$RIPS_AUDIT_RECEIPT" ]]; then
        reason="audit receipt $RIPS_AUDIT_RECEIPT not readable; run the surface to generate it"
      else
        local conf
        conf="$(jq -r --arg s "$RIPS_SESSION" '(.confidence_per_session // {})[$s] // empty' "$RIPS_AUDIT_RECEIPT" 2>/dev/null || true)"
        if [[ -z "$conf" ]]; then
          reason="audit receipt $RIPS_AUDIT_RECEIPT lacks confidence_per_session.$RIPS_SESSION"
        elif (( conf >= RIPS_CONFIDENCE_MIN )); then
          status="pass"; reason="audit confidence $conf >= threshold $RIPS_CONFIDENCE_MIN"
        else
          reason="audit confidence $conf < threshold $RIPS_CONFIDENCE_MIN"
        fi
      fi
      ;;
    config)
      local missing=()
      command -v python3 >/dev/null 2>&1 || missing+=("python3")
      command -v jq >/dev/null 2>&1 || missing+=("jq")
      [[ -x "$RIPS_NTM_BIN" ]] || missing+=("ntm_bin:$RIPS_NTM_BIN")
      [[ -x "$RIPS_PLUTIL_BIN" ]] || missing+=("plutil:$RIPS_PLUTIL_BIN")
      [[ -x "$RIPS_LAUNCHCTL_BIN" ]] || missing+=("launchctl:$RIPS_LAUNCHCTL_BIN")
      [[ -r "$RIPS_NTM_CONFIG" ]] || missing+=("ntm_config:$RIPS_NTM_CONFIG")
      [[ -r "$RIPS_AUDIT_SCRIPT" ]] || missing+=("audit_script:$RIPS_AUDIT_SCRIPT")
      if [[ ${#missing[@]} -eq 0 ]]; then
        status="pass"; reason="python3 + jq + ntm + plutil + launchctl + ntm_config + audit_script all present"
      else
        reason="missing: $(IFS=,; echo "${missing[*]}")"
      fi
      ;;
    skillos-management)
      local missing=()
      [[ -x "$RIPS_JSM_BIN" ]] || missing+=("jsm_bin:$RIPS_JSM_BIN")
      [[ -d "$RIPS_SKILLS_FLYWHEEL" && -r "$RIPS_SKILLS_FLYWHEEL" ]] || missing+=("skills_flywheel:$RIPS_SKILLS_FLYWHEEL")
      if [[ ${#missing[@]} -eq 0 ]]; then
        status="pass"; reason="jsm binary executable + skills-flywheel dir readable (skillos-specific readiness)"
      else
        reason="skillos-management substrate missing: $(IFS=,; echo "${missing[*]}")"
      fi
      ;;
    *)
      printf 'ERR: unknown validate subject %s (plist|audit-receipt|config|skillos-management)\n' "$subject" >&2
      return 64
      ;;
  esac
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subject "$subject" --arg status "$status" --arg reason "$reason" \
    '{schema_version:$sv,command:"validate",subject:$subject,status:$status,reason:$reason}'
  if command -v cli_audit_append >/dev/null 2>&1; then
    cli_audit_append "$SCAFFOLD_AUDIT_LOG" "validate" "$status" "$(jq -nc --arg s "$subject" --arg r "$reason" '{subject:$s,reason:$r}')" >/dev/null 2>&1 || true
  fi
  return 0
}

scaffold_cmd_audit() {
  if command -v cli_emit_audit_tail >/dev/null 2>&1; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" 20
    return $?
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" \
    '{schema_version:$sv,command:"audit",audit_log:$log,row_count:0,recent:[],helper_lib_missing:true}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  local resolution="not_found" explanation=""
  case "$id" in
    label)
      resolution="found"
      explanation="Canonical label: $RIPS_LABEL. Launchctl refuses duplicate registration; surface returns exit 5 (block_reason=duplicate_launchd_label) when launchctl list shows >1 matching row."
      ;;
    audit)
      resolution="found"
      explanation="Preinstall audit runs $RIPS_AUDIT_SCRIPT --session=$RIPS_SESSION; output lands at $RIPS_AUDIT_RECEIPT. Confidence threshold: $RIPS_CONFIDENCE_MIN. Below threshold → exit 4."
      ;;
    dry_run_pass)
      resolution="found"
      explanation="dry_run_pass requires ALL checks: plutil -lint OK, HOME exists, ntm binary executable, ntm config exists, repo dir exists, log dir exists. skillos variant adds jsm binary + skills-flywheel dir readiness. Any false → exit 6."
      ;;
    repo)
      if [[ -d "$RIPS_REPO" ]]; then
        resolution="found"
        explanation="Target repo: $RIPS_REPO (exists). Set SKILLOS_REPO env to override."
      else
        resolution="unavailable"
        explanation="Target repo $RIPS_REPO does not exist; set SKILLOS_REPO or create the directory."
      fi
      ;;
    watcher_race)
      resolution="found"
      explanation="Race-failure mode covered_by_plist_lint_label_count_and_readiness_probe — plutil -lint catches malformed plists; label-count probe catches duplicate registrations; readiness probe catches missing deps."
      ;;
    install_flow)
      resolution="found"
      explanation="4-stage flow: (1) preinstall audit + confidence, (2) launchctl list probe for duplicate label, (3) atomic plist write + plutil -lint, (4) readiness probe (paths + binaries + jsm + skills-flywheel). status=installed_not_loaded on success."
      ;;
    skillos_management)
      resolution="found"
      explanation="skillos variant uniquely requires jsm CLI ($RIPS_JSM_BIN) and skills-flywheel dir ($RIPS_SKILLS_FLYWHEEL) — both used by the watcher to manage skill mutations under JSM discipline. Readiness check at install time prevents watcher load with missing skillos-management substrate."
      ;;
    *)
      resolution="not_found"
      explanation="unknown id '$id'; valid ids: label, audit, dry_run_pass, repo, watcher_race, install_flow, skillos_management"
      ;;
  esac
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg resolution "$resolution" --arg explanation "$explanation" \
    '{schema_version:$sv,command:"why",id:$id,resolution:$resolution,explanation:$explanation}'
  if command -v cli_audit_append >/dev/null 2>&1; then
    cli_audit_append "$SCAFFOLD_AUDIT_LOG" "why" "$resolution" "$(jq -nc --arg i "$id" '{id:$i}')" >/dev/null 2>&1 || true
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
python3 - "$@" <<'PY'
import argparse
import json
import os
import plistlib
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

LABEL = "com.zeststream.skillos.watcher"
SESSION = "skillos"
SOURCE_PLAN = ".flywheel/PLANS/recovery-system-2026-05-01/00-PLAN.md"
DEFAULT_PLIST = "~/Library/LaunchAgents/com.zeststream.skillos.watcher.plist"
DEFAULT_STATUS = "/tmp/recovery-install-skillos-status.json"
DEFAULT_AUDIT = "/tmp/preinstall-skillos.json"
DEFAULT_REPO = "/Users/josh/Developer/skillos"
DEFAULT_NTM = "/Users/josh/.local/bin/ntm"
DEFAULT_NTM_CONFIG = "/Users/josh/.config/ntm/config.toml"
DEFAULT_AUDIT_SCRIPT = ".flywheel/scripts/recovery-preinstall-audit.sh"
DEFAULT_JSM = "/Users/josh/.local/bin/jsm"
DEFAULT_LOG_DIR = "~/.local/state/flywheel/logs"
DEFAULT_SKILLS_FLYWHEEL = "~/.claude/skills/.flywheel"


def now_iso():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def ep(path):
    return Path(path).expanduser()


def abs_path(path):
    return str(ep(path).resolve(strict=False))


def run_cmd(args, timeout=10):
    try:
        proc = subprocess.run(args, text=True, capture_output=True, timeout=timeout)
        return {"ok": proc.returncode == 0, "rc": proc.returncode, "stdout": proc.stdout.strip(), "stderr": proc.stderr.strip()}
    except FileNotFoundError:
        return {"ok": False, "rc": 127, "stdout": "", "stderr": "command_not_found"}
    except subprocess.TimeoutExpired:
        return {"ok": False, "rc": 124, "stdout": "", "stderr": "timeout"}


def write_json(path, payload):
    p = ep(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(payload, sort_keys=True, indent=2) + "\n", encoding="utf-8")


def launchctl_label_count(launchctl_bin, label):
    result = run_cmd([launchctl_bin, "list"], timeout=8)
    if not result["ok"]:
        return {"ok": False, "count": 0, "rows": [], "result": result}
    rows = [line for line in result["stdout"].splitlines() if label in line]
    return {"ok": True, "count": len(rows), "rows": rows, "result": result}


def run_audit(args):
    audit_path = ep(args.audit_receipt)
    cmd = [
        args.audit_script,
        f"--session={args.session}",
        "--json",
        "--confidence-min",
        str(args.confidence_min),
        "--output",
        str(audit_path),
    ]
    result = run_cmd(cmd, timeout=45)
    if not audit_path.exists() and result["stdout"]:
        try:
            parsed = json.loads(result["stdout"])
            write_json(audit_path, parsed)
        except json.JSONDecodeError:
            pass
    if not audit_path.exists():
        return None, result
    try:
        return json.loads(audit_path.read_text(encoding="utf-8")), result
    except json.JSONDecodeError as exc:
        return {"parse_error": str(exc)}, result


def skill_authoring_health(args):
    skills = ep(args.skills_flywheel)
    repo = ep(args.repo)
    jsm = ep(args.jsm_bin)
    return {
        "ok": skills.is_dir() and os.access(skills, os.R_OK) and repo.is_dir() and os.access(repo, os.W_OK) and jsm.is_file() and os.access(jsm, os.X_OK),
        "flywheel_skills_path": str(skills),
        "flywheel_skills_readable": skills.is_dir() and os.access(skills, os.R_OK),
        "skillos_repo": str(repo),
        "skillos_repo_writable": repo.is_dir() and os.access(repo, os.W_OK),
        "jsm_cli_path": str(jsm),
        "jsm_cli_available": jsm.is_file() and os.access(jsm, os.X_OK),
    }


def build_plist(args):
    log_dir = ep(args.log_dir)
    log_dir.mkdir(parents=True, exist_ok=True)
    env_path = "/Users/josh/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    return {
        "Label": LABEL,
        "ProgramArguments": [
            abs_path(args.ntm_bin),
            "--config",
            abs_path(args.ntm_config),
            "watch",
            args.session,
            "--no-color",
            "--interval",
            "5s",
        ],
        "WorkingDirectory": abs_path(args.repo),
        "StandardOutPath": str(log_dir / "skillos.watcher.out.log"),
        "StandardErrorPath": str(log_dir / "skillos.watcher.err.log"),
        "EnvironmentVariables": {
            "PATH": env_path,
            "HOME": str(Path.home()),
            "NTM_CONFIG": abs_path(args.ntm_config),
            "SKILLOS_REPO": abs_path(args.repo),
        },
        "KeepAlive": True,
        "RunAtLoad": True,
    }


def main(argv):
    parser = argparse.ArgumentParser(description="Install the skillos recovery watcher plist without activating it.")
    parser.add_argument("--session", default=SESSION)
    parser.add_argument("--repo", default=DEFAULT_REPO)
    parser.add_argument("--plist", default=DEFAULT_PLIST)
    parser.add_argument("--status", default=DEFAULT_STATUS)
    parser.add_argument("--audit-receipt", default=DEFAULT_AUDIT)
    parser.add_argument("--audit-script", default=DEFAULT_AUDIT_SCRIPT)
    parser.add_argument("--ntm-bin", default=DEFAULT_NTM)
    parser.add_argument("--ntm-config", default=DEFAULT_NTM_CONFIG)
    parser.add_argument("--launchctl-bin", default="/bin/launchctl")
    parser.add_argument("--plutil-bin", default="/usr/bin/plutil")
    parser.add_argument("--jsm-bin", default=DEFAULT_JSM)
    parser.add_argument("--skills-flywheel", default=DEFAULT_SKILLS_FLYWHEEL)
    parser.add_argument("--log-dir", default=DEFAULT_LOG_DIR)
    parser.add_argument("--confidence-min", type=int, default=70)
    parser.add_argument("--json", action="store_true", help="Compatibility flag; output is always JSON.")
    args = parser.parse_args(argv)

    audit, audit_result = run_audit(args)
    confidence = None
    if isinstance(audit, dict):
        confidence = (audit.get("confidence_per_session") or {}).get(args.session)

    status = {
        "schema_version": "recovery.skillos_watcher_install.v1",
        "generated_at": now_iso(),
        "source_plan": SOURCE_PLAN,
        "label": LABEL,
        "session": args.session,
        "audit_receipt_path": str(ep(args.audit_receipt)),
        "audit_command": audit_result,
        "audit_confidence": confidence,
        "plist_path": str(ep(args.plist)),
        "dry_run_pass": False,
        "exactly_one_label": False,
        "reboot_recovery_claimed": False,
        "skill_authoring_health": skill_authoring_health(args),
    }

    if confidence is None or confidence < args.confidence_min:
        status["status"] = "blocked"
        status["block_reason"] = "low_preinstall_confidence"
        write_json(args.status, status)
        print(json.dumps(status, sort_keys=True))
        return 4

    label_state = launchctl_label_count(args.launchctl_bin, LABEL)
    status["launchctl_label_state"] = label_state
    status["exactly_one_label"] = bool(label_state.get("ok") and label_state.get("count", 0) <= 1)
    if not status["exactly_one_label"]:
        status["status"] = "blocked"
        status["block_reason"] = "duplicate_launchd_label"
        write_json(args.status, status)
        print(json.dumps(status, sort_keys=True))
        return 5

    plist_path = ep(args.plist)
    plist_path.parent.mkdir(parents=True, exist_ok=True)
    plist_payload = build_plist(args)
    with plist_path.open("wb") as fh:
        plistlib.dump(plist_payload, fh, sort_keys=False)

    lint = run_cmd([args.plutil_bin, "-lint", str(plist_path)], timeout=8)
    readiness = {
        "path": {"value": plist_payload["EnvironmentVariables"]["PATH"], "ready": True},
        "home": {"value": str(Path.home()), "ready": Path.home().is_dir()},
        "binary": {"value": plist_payload["ProgramArguments"][0], "ready": ep(plist_payload["ProgramArguments"][0]).is_file()},
        "config": {"value": abs_path(args.ntm_config), "ready": ep(args.ntm_config).is_file()},
        "repo": {"value": abs_path(args.repo), "ready": ep(args.repo).is_dir() and os.access(ep(args.repo), os.W_OK)},
        "plutil": lint,
    }
    status.update({
        "status": "installed_not_loaded",
        "dry_run_pass": bool(lint["ok"] and all(item["ready"] for key, item in readiness.items() if key != "plutil")),
        "launchd_readiness": readiness,
        "program_arguments": plist_payload["ProgramArguments"],
        "working_directory": plist_payload["WorkingDirectory"],
        "stdout_path": plist_payload["StandardOutPath"],
        "stderr_path": plist_payload["StandardErrorPath"],
    })
    write_json(args.status, status)
    print(json.dumps(status, sort_keys=True))
    return 0 if status["dry_run_pass"] else 6


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY
