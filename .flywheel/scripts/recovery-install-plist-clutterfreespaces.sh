#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m + flywheel-wzjo9.2.5) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (substantive fillin landed flywheel-wzjo9.2.5)
# doctor-mode-tier: filled
#
# 18-fillin: per-surface schemas, single-printf topic_help, 11-probe doctor,
# audit-log + plist-status health, log-dir/audit-log/status-receipt-dir repair
# scopes, plist/audit-receipt/config validate subjects, multi-resolution why.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="recovery-install-plist-clutterfreespaces/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/recovery-install-plist-clutterfreespaces-runs.jsonl}"

# flywheel-mbt3z: source shared canonical-cli helper for this family.
# Provides 6 identical-across-the-family functions:
#   scaffold_usage, scaffold_emit_info, scaffold_emit_examples,
#   scaffold_emit_quickstart, scaffold_emit_completion, scaffold_main
# Per-client divergent functions (doctor/health/repair/validate/audit/why
# + emit_schema + emit_topic_help) stay inline below.
SCAFFOLD_BASENAME="recovery-install-plist-clutterfreespaces.sh"
source "$_SCAFFOLD_REPO_ROOT/.flywheel/lib/recovery-install-plist-canonical-cli.sh"

# Module-scope substrate (mirror python defaults for shell-side probing).
RIPC_SESSION="clutterfreespaces"
RIPC_LABEL="com.zeststream.clutterfreespaces.watcher"
RIPC_STATUS_SCHEMA="recovery-session-watcher-install/v1"
RIPC_REPO="${CLUTTERFREESPACES_REPO:-/Users/josh/Developer/clutterfreespaces}"
RIPC_PLIST="${RIPC_PLIST:-$HOME/Library/LaunchAgents/com.zeststream.clutterfreespaces.watcher.plist}"
RIPC_STATUS="${RIPC_STATUS:-$_SCAFFOLD_REPO_ROOT/.flywheel/receipts/recovery-install-clutterfreespaces-status.json}"
RIPC_AUDIT_RECEIPT="${RIPC_AUDIT_RECEIPT:-/tmp/preinstall-clutterfreespaces.json}"
RIPC_AUDIT_SCRIPT="${RIPC_AUDIT_SCRIPT:-$_SCAFFOLD_REPO_ROOT/.flywheel/scripts/recovery-preinstall-audit.sh}"
RIPC_NTM_BIN="${RIPC_NTM_BIN:-/Users/josh/.local/bin/ntm}"
RIPC_NTM_CONFIG="${RIPC_NTM_CONFIG:-$HOME/.config/ntm/config.toml}"
RIPC_LAUNCHCTL_BIN="${RIPC_LAUNCHCTL_BIN:-/bin/launchctl}"
RIPC_PLUTIL_BIN="${RIPC_PLUTIL_BIN:-/usr/bin/plutil}"
RIPC_LOG_DIR="${RIPC_LOG_DIR:-$HOME/.local/state/flywheel/logs}"
RIPC_CONFIDENCE_MIN="${RIPC_CONFIDENCE_MIN:-60}"

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
        '{schema_version:$sv,command:"validate",title:"validate",type:"object",required:["command","subject","status"],properties:{command:{type:"string"},subject:{enum:["plist","audit-receipt","config"]},status:{enum:["pass","fail"]},reason:{type:"string"}}}'
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
      jq -nc --arg sv "$RIPC_STATUS_SCHEMA" \
        '{schema_version:$sv,command:"status",title:"recovery-session-watcher-install status",type:"object",required:["schema_version","session","label","dry_run_pass"],properties:{schema_version:{const:"recovery-session-watcher-install/v1"},session:{const:"clutterfreespaces"},label:{const:"com.zeststream.clutterfreespaces.watcher"},dry_run_pass:{type:"boolean"},exactly_one_label:{type:"boolean"},launchctl_load_attempted:{type:"boolean"},reboot_recovery_claimed:{type:"boolean"}}}'
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
    run)      printf 'topic: run — audits preinstall confidence, probes launchctl for duplicate labels, writes plist %s, lints plutil, prints status JSON.\n' "$RIPC_PLIST" ;;
    doctor)   printf 'topic: doctor — probes python3, jq, ntm binary, ntm config, plutil, launchctl, repo dir, plist parent, audit script, log dir, helper lib, audit log writability.\n' ;;
    health)   printf 'topic: health — reports plist_installed, last status from receipt, audit_log_stale (>24h).\n' ;;
    repair)   printf 'topic: repair — --scope log-dir | audit-log | status-receipt-dir mkdir the missing parent dir; --apply requires --idempotency-key.\n' ;;
    validate) printf 'topic: validate — subjects: plist (plutil -lint clean), audit-receipt (JSON parseable + confidence), config (deps + paths).\n' ;;
    audit)    printf 'topic: audit — tails recent invocations from SCAFFOLD_AUDIT_LOG (~/.local/state/flywheel/recovery-install-plist-clutterfreespaces-runs.jsonl).\n' ;;
    why)      printf 'topic: why — explains ids: label (canonical uniqueness rule), audit (preinstall confidence threshold), dry_run_pass (6 checks), repo (target repo), watcher_race (plist lint + label count + readiness probe coverage), install_flow (4-stage flow).\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate | audit | why\n' ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local py="fail" jq_s="fail" ntm_b="fail" ntm_c="fail" plutil_s="fail" launchctl_s="fail" repo_s="fail" plist_parent="fail" audit_script="fail" log_d="fail" helper="fail" audit_log_w="fail"
  command -v python3 >/dev/null 2>&1 && py="pass"
  command -v jq >/dev/null 2>&1 && jq_s="pass"
  [[ -x "$RIPC_NTM_BIN" ]] && ntm_b="pass"
  [[ -r "$RIPC_NTM_CONFIG" ]] && ntm_c="pass"
  [[ -x "$RIPC_PLUTIL_BIN" ]] && plutil_s="pass"
  [[ -x "$RIPC_LAUNCHCTL_BIN" ]] && launchctl_s="pass"
  if [[ -d "$RIPC_REPO" && -w "$RIPC_REPO" ]]; then repo_s="pass"
  elif [[ ! -e "$RIPC_REPO" ]]; then repo_s="warn"; fi
  local pp; pp="$(dirname "$RIPC_PLIST")"
  [[ -d "$pp" && -w "$pp" ]] && plist_parent="pass"
  [[ -r "$RIPC_AUDIT_SCRIPT" ]] && audit_script="pass"
  if [[ -d "$RIPC_LOG_DIR" ]]; then log_d="pass"
  else
    local lp; lp="$(dirname "$RIPC_LOG_DIR")"
    [[ -d "$lp" && -w "$lp" ]] && log_d="warn"
  fi
  command -v cli_audit_append >/dev/null 2>&1 && helper="pass"
  local ad; ad="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  if [[ -d "$ad" && -w "$ad" ]] || [[ -f "$SCAFFOLD_AUDIT_LOG" && -w "$SCAFFOLD_AUDIT_LOG" ]]; then audit_log_w="pass"; fi
  local agg="pass"
  for s in "$py" "$jq_s" "$ntm_b" "$plutil_s" "$launchctl_s"; do
    [[ "$s" != "pass" ]] && agg="fail"
  done
  if [[ "$agg" == "pass" ]]; then
    for s in "$ntm_c" "$repo_s" "$plist_parent" "$audit_script" "$log_d" "$audit_log_w"; do
      if [[ "$s" == "fail" ]]; then agg="fail"; break; fi
      if [[ "$s" == "warn" && "$agg" == "pass" ]]; then agg="warn"; fi
    done
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg agg "$agg" --arg py "$py" --arg jq_s "$jq_s" --arg nb "$ntm_b" --arg nc "$ntm_c" \
    --arg pu "$plutil_s" --arg lc "$launchctl_s" --arg rp "$repo_s" --arg pp_s "$plist_parent" \
    --arg as "$audit_script" --arg ld "$log_d" --arg hl "$helper" --arg al "$audit_log_w" \
    --arg repo "$RIPC_REPO" --arg plist "$RIPC_PLIST" --arg ntm "$RIPC_NTM_BIN" --arg log "$RIPC_LOG_DIR" --arg audit "$SCAFFOLD_AUDIT_LOG" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$agg,paths:{repo:$repo,plist:$plist,ntm_bin:$ntm,log_dir:$log,audit_log:$audit},checks:[
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
  if [[ -f "$RIPC_PLIST" ]]; then plist_installed="true"; fi
  if [[ -r "$RIPC_STATUS" ]]; then
    local s ts
    s="$(jq -r '.status // ""' "$RIPC_STATUS" 2>/dev/null || true)"
    ts="$(jq -r '.generated_at // ""' "$RIPC_STATUS" 2>/dev/null || true)"
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
    --argjson stale "$audit_log_stale" --arg plist "$RIPC_PLIST" --arg al "$SCAFFOLD_AUDIT_LOG" --arg sr "$RIPC_STATUS" \
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
      target_dir="$RIPC_LOG_DIR"
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
      target_dir="$(dirname "$RIPC_STATUS")"
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
      '{schema_version:$sv,command:"validate",status:"info",reason:"no subject specified",valid_subjects:["plist","audit-receipt","config"]}'
    return 0
  fi
  local status="fail" reason="unknown"
  case "$subject" in
    plist)
      if [[ ! -f "$RIPC_PLIST" ]]; then
        reason="plist $RIPC_PLIST does not exist; run the surface to install it"
      elif [[ ! -x "$RIPC_PLUTIL_BIN" ]]; then
        reason="plutil binary $RIPC_PLUTIL_BIN not executable; cannot lint"
      else
        local lint_out
        lint_out="$("$RIPC_PLUTIL_BIN" -lint "$RIPC_PLIST" 2>&1 || true)"
        if [[ "$lint_out" == *": OK"* ]]; then
          status="pass"; reason="plutil -lint clean for $RIPC_PLIST"
        else
          reason="plutil -lint failed: ${lint_out:0:200}"
        fi
      fi
      ;;
    audit-receipt)
      if [[ ! -r "$RIPC_AUDIT_RECEIPT" ]]; then
        reason="audit receipt $RIPC_AUDIT_RECEIPT not readable; run the surface to generate it"
      else
        local conf
        conf="$(jq -r --arg s "$RIPC_SESSION" '(.confidence_per_session // {})[$s] // empty' "$RIPC_AUDIT_RECEIPT" 2>/dev/null || true)"
        if [[ -z "$conf" ]]; then
          reason="audit receipt $RIPC_AUDIT_RECEIPT lacks confidence_per_session.$RIPC_SESSION"
        elif (( conf >= RIPC_CONFIDENCE_MIN )); then
          status="pass"; reason="audit confidence $conf >= threshold $RIPC_CONFIDENCE_MIN"
        else
          reason="audit confidence $conf < threshold $RIPC_CONFIDENCE_MIN"
        fi
      fi
      ;;
    config)
      local missing=()
      command -v python3 >/dev/null 2>&1 || missing+=("python3")
      command -v jq >/dev/null 2>&1 || missing+=("jq")
      [[ -x "$RIPC_NTM_BIN" ]] || missing+=("ntm_bin:$RIPC_NTM_BIN")
      [[ -x "$RIPC_PLUTIL_BIN" ]] || missing+=("plutil:$RIPC_PLUTIL_BIN")
      [[ -x "$RIPC_LAUNCHCTL_BIN" ]] || missing+=("launchctl:$RIPC_LAUNCHCTL_BIN")
      [[ -r "$RIPC_NTM_CONFIG" ]] || missing+=("ntm_config:$RIPC_NTM_CONFIG")
      [[ -r "$RIPC_AUDIT_SCRIPT" ]] || missing+=("audit_script:$RIPC_AUDIT_SCRIPT")
      if [[ ${#missing[@]} -eq 0 ]]; then
        status="pass"; reason="python3 + jq + ntm + plutil + launchctl + ntm_config + audit_script all present"
      else
        reason="missing: $(IFS=,; echo "${missing[*]}")"
      fi
      ;;
    *)
      printf 'ERR: unknown validate subject %s (plist|audit-receipt|config)\n' "$subject" >&2
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
      explanation="Canonical label: $RIPC_LABEL. The launchctl namespace requires each label loaded at most once; the surface refuses install when launchctl list shows >1 matching row (status=blocked, block_reason=duplicate_launchd_label, exit 5)."
      ;;
    audit)
      resolution="found"
      explanation="Preinstall audit runs $RIPC_AUDIT_SCRIPT --session=$RIPC_SESSION; output lands at $RIPC_AUDIT_RECEIPT. Confidence threshold: $RIPC_CONFIDENCE_MIN. Below threshold → status=blocked, exit 4."
      ;;
    dry_run_pass)
      resolution="found"
      explanation="dry_run_pass requires ALL six checks: plutil -lint OK, HOME exists, ntm binary executable, ntm config exists, repo dir exists, log dir exists. Any false → exit 6."
      ;;
    repo)
      if [[ -d "$RIPC_REPO" ]]; then
        resolution="found"
        explanation="Target repo: $RIPC_REPO (exists). Set CLUTTERFREESPACES_REPO to override; surface validates writability before plist install."
      else
        resolution="unavailable"
        explanation="Target repo $RIPC_REPO does not exist; set CLUTTERFREESPACES_REPO or create the directory before running."
      fi
      ;;
    watcher_race)
      resolution="found"
      explanation="Race-failure mode covered_by_plist_lint_label_count_and_readiness_probe — plutil -lint catches malformed plists; label-count probe catches duplicate registrations; readiness probe catches missing deps before the watcher starts."
      ;;
    install_flow)
      resolution="found"
      explanation="4-stage flow: (1) preinstall audit + confidence check, (2) launchctl list probe for duplicate label, (3) atomic plist write + plutil -lint, (4) readiness probe (paths + binaries). status=installed_not_loaded on success; activation is a separate ticket."
      ;;
    *)
      resolution="not_found"
      explanation="unknown id '$id'; valid ids: label, audit, dry_run_pass, repo, watcher_race, install_flow"
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

SESSION = "clutterfreespaces"
LABEL = "com.zeststream.clutterfreespaces.watcher"
SOURCE_PLAN = ".flywheel/PLANS/recovery-system-2026-05-01/00-PLAN.md"
DEFAULT_REPO = "/Users/josh/Developer/clutterfreespaces"
DEFAULT_PLIST = "~/Library/LaunchAgents/com.zeststream.clutterfreespaces.watcher.plist"
DEFAULT_STATUS = ".flywheel/receipts/recovery-install-clutterfreespaces-status.json"
DEFAULT_AUDIT = "/tmp/preinstall-clutterfreespaces.json"
DEFAULT_AUDIT_SCRIPT = ".flywheel/scripts/recovery-preinstall-audit.sh"
DEFAULT_NTM = "/Users/josh/.local/bin/ntm"
DEFAULT_NTM_CONFIG = "/Users/josh/.config/ntm/config.toml"
DEFAULT_LOG_DIR = "~/.local/state/flywheel/logs"


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
    if not audit_path.exists() and result.get("stdout"):
        try:
            write_json(audit_path, json.loads(result["stdout"]))
        except json.JSONDecodeError:
            pass
    if not audit_path.exists():
        return None, result
    try:
        return json.loads(audit_path.read_text(encoding="utf-8")), result
    except json.JSONDecodeError as exc:
        return {"parse_error": str(exc)}, result


def compact_command_result(result):
    compact = dict(result)
    stdout = compact.get("stdout") or ""
    compact["stdout_bytes"] = len(stdout.encode("utf-8"))
    compact["stdout"] = "[see audit_receipt_path]" if stdout else ""
    return compact


def launchctl_probe(args):
    result = run_cmd([args.launchctl_bin, "list"], timeout=8)
    rows = []
    if result["ok"]:
        rows = [line for line in result["stdout"].splitlines() if LABEL in line]
    probe_path = ep(args.launchctl_probe_path)
    probe_path.parent.mkdir(parents=True, exist_ok=True)
    probe_path.write_text("\n".join(rows) + ("\n" if rows else ""), encoding="utf-8")
    return {"ok": result["ok"], "count": len(rows), "rows": rows, "result": result, "path": str(probe_path)}


def build_plist(args):
    log_dir = ep(args.log_dir)
    log_dir.mkdir(parents=True, exist_ok=True)
    env_path = "/Users/josh/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    return {
        "Label": LABEL,
        "ProgramArguments": [
            abs_path(args.ntm_bin),
            "watch",
            args.session,
            "--activity",
            "--interval",
            "2s",
            "--tail",
            "20",
            "--no-color",
            "--no-timestamps",
            "--config",
            abs_path(args.ntm_config),
        ],
        "WorkingDirectory": abs_path(args.repo),
        "StandardOutPath": str(log_dir / "clutterfreespaces-watcher.stdout.log"),
        "StandardErrorPath": str(log_dir / "clutterfreespaces-watcher.stderr.log"),
        "EnvironmentVariables": {
            "PATH": env_path,
            "HOME": str(Path.home()),
            "NTM_CONFIG": abs_path(args.ntm_config),
            "CLUTTERFREESPACES_REPO": abs_path(args.repo),
        },
        "KeepAlive": {"SuccessfulExit": False},
        "RunAtLoad": True,
        "ThrottleInterval": 10,
    }


def main(argv):
    parser = argparse.ArgumentParser(description="Install the clutterfreespaces recovery watcher plist without activating it.")
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
    parser.add_argument("--log-dir", default=DEFAULT_LOG_DIR)
    parser.add_argument("--launchctl-probe-path", default="/tmp/clutterfreespaces-watcher-launchctl-labels.txt")
    parser.add_argument("--confidence-min", type=int, default=60)
    parser.add_argument("--json", action="store_true", help="Compatibility flag; output is always JSON.")
    args = parser.parse_args(argv)

    audit, audit_result = run_audit(args)
    confidence = None
    if isinstance(audit, dict):
        confidence = (audit.get("confidence_per_session") or {}).get(args.session)
    low_confidence = confidence is None or confidence < args.confidence_min

    status = {
        "schema_version": "recovery-session-watcher-install/v1",
        "source_plan": SOURCE_PLAN,
        "generated_at": now_iso(),
        "session": args.session,
        "label": LABEL,
        "plist_path": str(ep(args.plist)),
        "audit_receipt_path": str(ep(args.audit_receipt)),
        "audit_command": compact_command_result(audit_result),
        "audit_confidence": confidence,
        "audit_low_confidence": low_confidence,
        "dry_run_pass": False,
        "exactly_one_label": False,
        "launchctl_load_attempted": False,
        "reboot_recovery_claimed": False,
        "clutterfreespaces_repo_path_validated": False,
        "watcher_race_failure_mode": "covered_by_plist_lint_label_count_and_readiness_probe",
    }
    if low_confidence:
        status["status"] = "blocked"
        status["block_reason"] = "low_preinstall_confidence"
        write_json(args.status, status)
        print(json.dumps(status, sort_keys=True))
        return 4

    label_probe = launchctl_probe(args)
    status["loaded_label_count"] = label_probe["count"]
    status["launchctl_list_probe_path"] = label_probe["path"]
    status["exactly_one_label"] = bool(label_probe["ok"] and label_probe["count"] <= 1)
    if not status["exactly_one_label"]:
        status["status"] = "blocked"
        status["block_reason"] = "duplicate_launchd_label"
        status["launchctl_label_rows"] = label_probe["rows"]
        write_json(args.status, status)
        print(json.dumps(status, sort_keys=True))
        return 5

    plist_path = ep(args.plist)
    plist_path.parent.mkdir(parents=True, exist_ok=True)
    plist_payload = build_plist(args)
    with plist_path.open("wb") as fh:
        plistlib.dump(plist_payload, fh, sort_keys=False)

    lint = run_cmd([args.plutil_bin, "-lint", str(plist_path)], timeout=8)
    repo_path = ep(args.repo)
    logs_dir = ep(args.log_dir)
    readiness = {
        "path": plist_payload["EnvironmentVariables"]["PATH"],
        "home": {"path": str(Path.home()), "exists": Path.home().is_dir()},
        "ntm_binary": {"path": plist_payload["ProgramArguments"][0], "executable": os.access(plist_payload["ProgramArguments"][0], os.X_OK)},
        "ntm_config": {"path": abs_path(args.ntm_config), "exists": ep(args.ntm_config).is_file()},
        "repo": {"path": abs_path(args.repo), "exists": repo_path.is_dir(), "writable": os.access(repo_path, os.W_OK)},
        "logs_dir": {"path": str(logs_dir), "exists": logs_dir.is_dir()},
        "stdout_path": plist_payload["StandardOutPath"],
        "stderr_path": plist_payload["StandardErrorPath"],
    }
    status.update({
        "status": "installed_not_loaded",
        "plutil_lint": "OK" if lint["ok"] else "FAIL",
        "plutil_result": lint,
        "readiness": readiness,
        "clutterfreespaces_repo_path_validated": bool(readiness["repo"]["exists"] and readiness["repo"]["writable"]),
        "dry_run_pass": bool(
            lint["ok"]
            and readiness["home"]["exists"]
            and readiness["ntm_binary"]["executable"]
            and readiness["ntm_config"]["exists"]
            and readiness["repo"]["exists"]
            and readiness["logs_dir"]["exists"]
        ),
    })
    write_json(args.status, status)
    print(json.dumps(status, sort_keys=True))
    return 0 if status["dry_run_pass"] else 6


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-92-reversible-recovery-ladder.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-45-reversible-cleanup-bundle.md`
