#!/usr/bin/env bash
# disk-reclaim-batch-2026-05-07.sh
#
# One-shot disk reclamation script for the 2026-05-07 storage emergency.
# Reclaims ~165+ GB by removing scratch directories and bulk source corpus
# while preserving all indexed/embedded data (qdrant collections, socraticode
# data, picoz live databases).
#
# DESIGN PRINCIPLE: explicit named paths only. No recursive find. No globs
# in rm. Each phase pauses for confirmation.
#
# Run from your shell (DCG blocks rm -rf inside Claude Code):
#   bash ~/Developer/flywheel/.flywheel/scripts/disk-reclaim-batch-2026-05-07.sh
#
# WHAT GETS PRESERVED (NEVER TOUCHED):
#   - ~/.socraticode/qdrant-data/        (~669 MB indexed embeddings)
#   - ~/.knowledge/qdrant_*              (~2.5 GB OpenAI/server storage)
#   - ~/Developer/polymarket-pico-z/data/kalshi.db  (79 GB pico-z data, paused)
#   - ~/Library/Application Support/*    (app state)
#   - ~/.local/state/                    (flywheel state, ledgers, fuckup-log)
#
# WHAT GETS DELETED (ALL DISPOSABLE - either auto-regenerates or is test scratch):
#   Phase 1: jsm test scratch (~140 GB)
#   Phase 2: beads-rust + mobile-eats + alps test scratch (~17 GB)
#   Phase 3: bulk jeff-corpus source repos (~9 GB; indexed data preserved)
#
# All actions logged to ~/.local/state/flywheel/disk-reclaim-2026-05-07.jsonl

set -euo pipefail

LEDGER="$HOME/.local/state/flywheel/disk-reclaim-2026-05-07.jsonl"
mkdir -p "$(dirname "$LEDGER")"

log() {
  local action="$1" path="${2:-}" extra="${3:-}"
  local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  echo "{\"ts\":\"$ts\",\"action\":\"$action\",\"path\":\"$path\",\"extra\":\"$extra\"}" >> "$LEDGER"
}

show_disk() {
  df -h / | tail -1
}

confirm() {
  local prompt="$1"
  read -r -p "$prompt [y/N] " ans
  case "$ans" in
    y|Y|yes|YES) return 0 ;;
    *) echo "skipped"; return 1 ;;
  esac
}

remove_explicit() {
  local path="$1"
  if [ ! -e "$path" ]; then
    echo "  [skip] missing: $path"
    return 0
  fi
  local size_before
  size_before=$(du -sk "$path" 2>/dev/null | awk '{print $1}')
  if rm -rf "$path"; then
    echo "  [ok]   removed: $path  (${size_before}KB)"
    log "removed" "$path" "size_kb=$size_before"
  else
    echo "  [FAIL] $path"
    log "failed" "$path"
  fi
}


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (filled-in per bead flywheel-5ke66.7)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# Canonical-cli subcommands intercept BEFORE the interactive reclaim flow
# below runs. Default invocation (no canonical subcommand / intro flag)
# falls through to the original three-phase reclaim with read -p prompts.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="disk-reclaim-batch-2026-05-07/v1"
# The reclaim script's existing LEDGER is the audit log for this surface;
# health and audit bind to it directly per AG3 ("health binds audit log").
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$LEDGER}"

# Phase-1/2/3 explicit named paths the original reclaim flow targets.
# Canonical phase-paths-prime + validate --phase-paths probe these read-only.
_SCAFFOLD_PHASE1_PATHS=(
  "/private/tmp/jsm-auth-isolation.ZQM9pq"
  "/private/tmp/jsm-auth-isolation.G1oVHv"
  "/private/tmp/jsm-health-sandbox.QzcyWE"
  "/private/tmp/jsm-health-sandbox.oqso3K"
  "/private/tmp/jsm-health-sandbox.Gjx1J3"
  "/private/tmp/jsm-health-sandbox.Ft29hm"
  "/private/tmp/jsm-health-sandbox.BUSm5h"
  "/private/tmp/jsm-health-sandbox.9pbbfU"
  "/private/tmp/jsm-health-sandbox.m4C85z"
  "/private/tmp/jsm-health-sandbox.eVsgrC"
  "/private/tmp/jsm-health-sandbox.C7W3Og"
  "/private/tmp/jsm-health-sandbox.rJ26vj"
  "/private/tmp/jsm-health-sandbox.VgUC38"
)
_SCAFFOLD_PHASE2_PATHS=(
  "/private/tmp/beads-rust-2k0fd"
  "/private/tmp/beads-rust-1l4fw"
  "/private/tmp/beads_rust-f505-build"
  "/private/tmp/mobile-eats-next-dev-cache-20260506151112-953"
  "/private/tmp/mobile-eats-next-failed-density-20260506122512"
  "/private/tmp/alps-demo-smoke-fix-pass"
  "/private/tmp/alpsinsurance-demo-dryrun-smoke-v2"
)
_SCAFFOLD_PHASE3_PATHS=(
  "$HOME/Developer/jeff-corpus"
)
# Preserved (NEVER-DELETE) paths the script guards before Phase 3.
_SCAFFOLD_INDEXED_PATHS=(
  "$HOME/.socraticode/qdrant-data"
  "$HOME/.knowledge/qdrant_server_storage"
  "$HOME/.knowledge/qdrant_storage_openai"
)

scaffold_usage() {
  cat <<'USG'
usage: disk-reclaim-batch-2026-05-07.sh [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
interactive three-phase reclaim flow (now reachable as `cmd_run`) — Phase 1
jsm scratch (~140 GB), Phase 2 beads/mobile-eats/alps scratch (~17 GB),
Phase 3 jeff-corpus bulk source (~9 GB; indexed data preserved).

Canonical CLI surfaces:
  doctor [--json]          probe substrate health (jq/du/df/ledger/indexed-data)
  health [--json]          last-run status (ledger tail + reclaimed_count)
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
                            Scopes: audit-log-rotate, phase-paths-prime
  validate <subject> [...] validate per-subject contract
                            Subjects: row, schema, config, indexed-data, phase-paths
  audit [--json]           recent run history (ledger tail)
  why <id>                 explain provenance for a given id
                            (id matches path, action, or any ledger field)
  quickstart [--json]      operator orientation
  help <topic>             topic help (run | doctor | health | repair | validate)
  completion <shell>       emit bash or zsh completion

Introspection:
  --info --json            version, paths, env vars, dependencies, sha256
  --schema [<surface>]     JSON Schema for output envelopes
  --examples --json        curated workflow examples
  --help / -h              this help

Original interactive flow remains the default — no canonical args invokes
the three-phase reclaim with read -p prompts.
USG
}

scaffold_emit_info() {
  if ! command -v cli_emit_info >/dev/null; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "disk-reclaim-batch-2026-05-07.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "disk-reclaim-batch-2026-05-07.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"interactive reclaim (default)",invocation:"disk-reclaim-batch-2026-05-07.sh",purpose:"3-phase prompted reclaim; runs from operator shell only (rm -rf is DCG-blocked under Claude)"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"disk-reclaim-batch-2026-05-07.sh doctor --json",purpose:"probe jq/du/df/ledger/indexed-data presence"}'
)"$'\n'"$(jq -nc '{name:"validate phase-paths",invocation:"disk-reclaim-batch-2026-05-07.sh validate --phase-paths",purpose:"see how many Phase-1/2/3 targets still exist before running"}'
)"$'\n'"$(jq -nc '{name:"why",invocation:"disk-reclaim-batch-2026-05-07.sh why jsm-health-sandbox",purpose:"search ledger for path/action substring"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"disk-reclaim-batch-2026-05-07.sh doctor --json"}'
)"$'\n'"$(jq -nc '{step:2,action:"see what would be reclaimed",command:"disk-reclaim-batch-2026-05-07.sh validate --phase-paths"}'
)"$'\n'"$(jq -nc '{step:3,action:"run interactive reclaim (from operator shell)",command:"bash ~/Developer/flywheel/.flywheel/scripts/disk-reclaim-batch-2026-05-07.sh"}'
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
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["ts","status","checks[]"],check_fields:["name","status","value?","detail?"]}' ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["ts","status","audit_log","stale_seconds","last_row?","removed_count","failed_count"]}' ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,scopes:["audit-log-rotate","phase-paths-prime"],fields:["status","mode","scope","idempotency_key?","rotated?","phase_paths?","present_count?","missing_count?"]}' ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,subjects:["row","schema","config","indexed-data","phase-paths"],fields:["status","subject","valid?","missing?","reason?","present_count?","total_count?"]}' ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["audit_log","row_count","rows[]"]}' ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["id","status","matches[]"],id_pattern:"path-substring|action|any-field"}' ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,required:["ts","action"],optional:["path","extra"]}' ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,note:"disk-reclaim-batch-2026-05-07: one-shot 3-phase reclaim with interactive prompts; ledger at ~/.local/state/flywheel/disk-reclaim-2026-05-07.jsonl"}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — interactive 3-phase reclaim. Phase 1 jsm scratch (~140 GB), Phase 2 beads/mobile-eats/alps scratch (~17 GB), Phase 3 jeff-corpus bulk source (~9 GB; indexed data preserved). Each phase prompts y/N via read -p. Run from operator shell only — rm -rf is DCG-blocked inside Claude Code.\n' ;;
    doctor)   printf 'topic: doctor — probes substrate: jq, du, df, ledger writable, indexed-data preservation paths (~/.socraticode/qdrant-data + ~/.knowledge/qdrant_*), flywheel root.\n' ;;
    health)   printf 'topic: health — tails ledger (= audit log); warn stale >7d. Counts removed vs failed ledger rows.\n' ;;
    repair)   printf 'topic: repair — scopes: audit-log-rotate (>5MB → mv .ts), phase-paths-prime (read-only — counts how many Phase-1/2/3 targets currently exist).\n' ;;
    validate) printf 'topic: validate — subjects: --row-json JSON, --schema, --config, --indexed-data (probes qdrant safety paths), --phase-paths (probes Phase-1/2/3 explicit target paths).\n' ;;
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
            && cli_emit_completion_bash "disk-reclaim-batch-2026-05-07" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "disk-reclaim-batch-2026-05-07" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (filled-in per flywheel-5ke66.7) ----------

scaffold_cmd_doctor() {
  # Substrate: jq, du, df, ledger writable, indexed-data preservation paths, flywheel root.
  local script_root; script_root="$_SCAFFOLD_REPO_ROOT"
  local checks="" overall="pass"

  if command -v jq >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v jq)" '{name:"jq_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"jq_on_path",status:"fail"}')"$'\n'
    overall="fail"
  fi

  if command -v du >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v du)" '{name:"du_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"du_on_path",status:"fail",detail:"used to measure size_before each rm"}')"$'\n'
    overall="fail"
  fi

  if command -v df >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v df)" '{name:"df_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"df_on_path",status:"fail",detail:"used by show_disk before/after each phase"}')"$'\n'
    overall="fail"
  fi

  local ledger_dir; ledger_dir="$(dirname "$LEDGER")"
  if [[ -d "$ledger_dir" && -w "$ledger_dir" ]] || mkdir -p "$ledger_dir" 2>/dev/null; then
    local row_count=0
    [[ -r "$LEDGER" ]] && row_count="$(wc -l < "$LEDGER" 2>/dev/null | tr -d ' ' || echo 0)"
    checks+="$(jq -nc --arg p "$LEDGER" --argjson rc "${row_count:-0}" '{name:"ledger_writable",status:"pass",value:$p,row_count:$rc}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$LEDGER" '{name:"ledger_writable",status:"fail",value:$p}')"$'\n'
    overall="fail"
  fi

  # Indexed-data preservation probe — the Phase 3 safety guard.
  local indexed_present=0 indexed_missing=0 indexed_total=0
  for p in "${_SCAFFOLD_INDEXED_PATHS[@]}"; do
    indexed_total=$((indexed_total + 1))
    if [[ -d "$p" ]]; then indexed_present=$((indexed_present + 1)); else indexed_missing=$((indexed_missing + 1)); fi
  done
  local indexed_status="pass"
  # If ALL indexed paths are missing, Phase 3 would abort — flag fail.
  [[ "$indexed_present" -eq 0 ]] && indexed_status="fail" && overall="fail"
  checks+="$(jq -nc --arg s "$indexed_status" --argjson tp "$indexed_present" --argjson tt "$indexed_total" --argjson tm "$indexed_missing" \
    '{name:"indexed_data_preservation",status:$s,present_count:$tp,missing_count:$tm,total_count:$tt,detail:"qdrant paths Phase 3 guards against deleting"}')"$'\n'

  if [[ -d "$script_root" ]]; then
    checks+="$(jq -nc --arg p "$script_root" '{name:"flywheel_root_resolvable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$script_root" '{name:"flywheel_root_resolvable",status:"fail",value:$p}')"$'\n'
    overall="fail"
  fi

  local ts; ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s' "$checks" | jq -sc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$overall" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$status,checks:.}'
}

scaffold_cmd_health() {
  local ts; ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local log="$SCAFFOLD_AUDIT_LOG"
  local last_row="null" stale_seconds=-1 status="warn"
  local removed_count=0 failed_count=0
  if [[ -r "$log" ]]; then
    local row_raw; row_raw="$(tail -n 1 "$log" 2>/dev/null || true)"
    if [[ -n "$row_raw" ]] && printf '%s' "$row_raw" | jq -e '.' >/dev/null 2>&1; then
      last_row="$row_raw"
      local last_ts; last_ts="$(printf '%s' "$row_raw" | jq -r '.ts // empty' 2>/dev/null || true)"
      if [[ -n "$last_ts" ]]; then
        local last_epoch now_epoch
        last_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_ts" +%s 2>/dev/null || echo 0)"
        now_epoch="$(date -u +%s)"
        if [[ "$last_epoch" -gt 0 ]]; then
          stale_seconds=$((now_epoch - last_epoch))
          if [[ "$stale_seconds" -le 604800 ]]; then status="pass"; fi
        fi
      fi
    fi
    removed_count="$(grep -c '"action":"removed"' "$log" 2>/dev/null; true)"
    failed_count="$(grep -c '"action":"failed"' "$log" 2>/dev/null; true)"
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log" \
    --arg status "$status" --argjson stale "$stale_seconds" --argjson row "$last_row" \
    --argjson rc "${removed_count:-0}" --argjson fc "${failed_count:-0}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,stale_seconds:$stale,last_row:$row,removed_count:$rc,failed_count:$fc}'
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
  case "$scope" in
    audit-log-rotate)
      local log="$SCAFFOLD_AUDIT_LOG"
      local size_bytes=0 rotated=false
      [[ -r "$log" ]] && size_bytes="$(stat -f '%z' "$log" 2>/dev/null || echo 0)"
      if [[ "$mode" == "apply" && "$size_bytes" -gt 5242880 ]]; then
        local rotated_path="${log}.$(date -u +%Y%m%dT%H%M%SZ)"
        if mv "$log" "$rotated_path" 2>/dev/null; then
          : > "$log" 2>/dev/null || true
          rotated=true
        fi
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg idem "$idem_key" --arg log "$log" --argjson sz "$size_bytes" --argjson r "$rotated" \
        '{schema_version:$sv,command:"repair",status:"pass",mode:$mode,scope:$scope,idempotency_key:$idem,audit_log:$log,size_bytes:$sz,rotation_threshold:5242880,rotated:$r}'
      ;;
    phase-paths-prime)
      # Read-only: count how many Phase-1/2/3 explicit paths currently exist.
      local p1_present=0 p1_total=0 p2_present=0 p2_total=0 p3_present=0 p3_total=0
      for p in "${_SCAFFOLD_PHASE1_PATHS[@]}"; do p1_total=$((p1_total + 1)); [[ -e "$p" ]] && p1_present=$((p1_present + 1)); done
      for p in "${_SCAFFOLD_PHASE2_PATHS[@]}"; do p2_total=$((p2_total + 1)); [[ -e "$p" ]] && p2_present=$((p2_present + 1)); done
      for p in "${_SCAFFOLD_PHASE3_PATHS[@]}"; do p3_total=$((p3_total + 1)); [[ -e "$p" ]] && p3_present=$((p3_present + 1)); done
      local total_present=$((p1_present + p2_present + p3_present))
      local total=$((p1_total + p2_total + p3_total))
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg idem "$idem_key" \
        --argjson p1p "$p1_present" --argjson p1t "$p1_total" \
        --argjson p2p "$p2_present" --argjson p2t "$p2_total" \
        --argjson p3p "$p3_present" --argjson p3t "$p3_total" \
        --argjson tp "$total_present" --argjson tt "$total" \
        '{schema_version:$sv,command:"repair",status:"pass",mode:$mode,scope:$scope,idempotency_key:$idem,phase1:{present:$p1p,total:$p1t},phase2:{present:$p2p,total:$p2t},phase3:{present:$p3p,total:$p3t},total_present:$tp,total_targets:$tt,note:"read-only probe — no rm performed"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
        '{schema_version:$sv,command:"repair",status:"unknown_scope",mode:$mode,scope:$scope,idempotency_key:$idem,known_scopes:["audit-log-rotate","phase-paths-prime"]}'
      ;;
  esac
}

scaffold_cmd_validate() {
  local subject="" row_json=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help validate; return 0 ;;
      --row-json) subject="row"; row_json="${2:-}"; shift 2 ;;
      --row-json=*) subject="row"; row_json="${1#--row-json=}"; shift ;;
      --schema) subject="schema"; shift ;;
      --config) subject="config"; shift ;;
      --indexed-data) subject="indexed-data"; shift ;;
      --phase-paths) subject="phase-paths"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown validate arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  case "$subject" in
    row)
      local valid=true missing=""
      if [[ -z "$row_json" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",subject:"row",status:"fail",valid:false,reason:"--row-json required"}'
        return 0
      fi
      if ! printf '%s' "$row_json" | jq -e '.' >/dev/null 2>&1; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",subject:"row",status:"fail",valid:false,reason:"invalid_json"}'
        return 0
      fi
      for f in ts action; do
        if ! printf '%s' "$row_json" | jq -e --arg k "$f" 'has($k)' >/dev/null 2>&1; then
          valid=false; missing="${missing}${f},"
        fi
      done
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson v "$valid" --arg m "${missing%,}" \
        '{schema_version:$sv,command:"validate",subject:"row",status:(if $v then "pass" else "fail" end),valid:$v,missing:$m}'
      ;;
    schema)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",subject:"schema",status:"pass",surfaces:["doctor","health","repair","validate","audit","why","audit-row"]}'
      ;;
    config)
      local jq_ok=false du_ok=false df_ok=false ledger_dir_ok=false root_ok=false
      command -v jq >/dev/null 2>&1 && jq_ok=true
      command -v du >/dev/null 2>&1 && du_ok=true
      command -v df >/dev/null 2>&1 && df_ok=true
      [[ -d "$(dirname "$LEDGER")" ]] && ledger_dir_ok=true
      [[ -d "$_SCAFFOLD_REPO_ROOT" ]] && root_ok=true
      local overall=pass
      [[ "$jq_ok" != true || "$du_ok" != true || "$df_ok" != true || "$ledger_dir_ok" != true || "$root_ok" != true ]] && overall=fail
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$overall" \
        --argjson jqq "$jq_ok" --argjson du "$du_ok" --argjson df "$df_ok" \
        --argjson ld "$ledger_dir_ok" --argjson rt "$root_ok" \
        --arg root "$_SCAFFOLD_REPO_ROOT" --arg ledger "$LEDGER" \
        '{schema_version:$sv,command:"validate",subject:"config",status:$s,jq_present:$jqq,du_present:$du,df_present:$df,ledger_dir_present:$ld,flywheel_root_present:$rt,flywheel_root:$root,ledger:$ledger}'
      ;;
    indexed-data)
      # surface-specific: probe qdrant safety paths Phase 3 guards.
      local present=0 missing=0 total=0
      local rows=""
      for p in "${_SCAFFOLD_INDEXED_PATHS[@]}"; do
        total=$((total + 1))
        if [[ -d "$p" ]]; then
          present=$((present + 1))
          local sz="0"
          sz="$(du -sk "$p" 2>/dev/null | awk '{print $1}' || echo 0)"
          rows+="$(jq -nc --arg p "$p" --argjson sz "${sz:-0}" '{path:$p,present:true,size_kb:$sz}')"$'\n'
        else
          missing=$((missing + 1))
          rows+="$(jq -nc --arg p "$p" '{path:$p,present:false}')"$'\n'
        fi
      done
      local status="pass"
      # If any indexed path is missing, Phase 3 would abort — flag warn.
      [[ "$missing" -gt 0 ]] && status="warn"
      [[ "$present" -eq 0 ]] && status="fail"
      local paths_json
      paths_json="$(printf '%s' "$rows" | jq -sc '.' 2>/dev/null || echo '[]')"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" \
        --argjson p "$present" --argjson m "$missing" --argjson t "$total" \
        --argjson paths "$paths_json" \
        '{schema_version:$sv,command:"validate",subject:"indexed-data",status:$s,present_count:$p,missing_count:$m,total_count:$t,paths:$paths}'
      ;;
    phase-paths)
      # surface-specific: probe Phase-1/2/3 explicit reclaim targets.
      local p1p=0 p1t=0 p2p=0 p2t=0 p3p=0 p3t=0
      for p in "${_SCAFFOLD_PHASE1_PATHS[@]}"; do p1t=$((p1t + 1)); [[ -e "$p" ]] && p1p=$((p1p + 1)); done
      for p in "${_SCAFFOLD_PHASE2_PATHS[@]}"; do p2t=$((p2t + 1)); [[ -e "$p" ]] && p2p=$((p2p + 1)); done
      for p in "${_SCAFFOLD_PHASE3_PATHS[@]}"; do p3t=$((p3t + 1)); [[ -e "$p" ]] && p3p=$((p3p + 1)); done
      local total_present=$((p1p + p2p + p3p))
      local total=$((p1t + p2t + p3t))
      local status="pass"
      [[ "$total_present" -eq 0 ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" \
        --argjson p1p "$p1p" --argjson p1t "$p1t" \
        --argjson p2p "$p2p" --argjson p2t "$p2t" \
        --argjson p3p "$p3p" --argjson p3t "$p3t" \
        --argjson tp "$total_present" --argjson tt "$total" \
        '{schema_version:$sv,command:"validate",subject:"phase-paths",status:$s,phase1:{present:$p1p,total:$p1t},phase2:{present:$p2p,total:$p2t},phase3:{present:$p3p,total:$p3t},total_present:$tp,total_targets:$tt}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"pass",subjects:["row","schema","config","indexed-data","phase-paths"],usage:"validate --row-json JSON or --schema or --config or --indexed-data or --phase-paths"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",subject:$s,status:"unknown_subject",known:["row","schema","config","indexed-data","phase-paths"]}'
      ;;
  esac
}

scaffold_cmd_audit() {
  local limit=50
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --limit) limit="${2:-50}"; shift 2 ;;
      --limit=*) limit="${1#--limit=}"; shift ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help audit; return 0 ;;
      *) shift ;;
    esac
  done
  if command -v cli_emit_audit_tail >/dev/null 2>&1; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" "$limit"
  else
    local rows="[]" count=0
    if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
      rows="$(tail -n "$limit" "$SCAFFOLD_AUDIT_LOG" | jq -sc '. // []' 2>/dev/null || echo '[]')"
      count="$(printf '%s' "$rows" | jq 'length' 2>/dev/null || echo 0)"
    fi
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson rows "$rows" --argjson count "$count" \
      '{schema_version:$sv,command:"audit",audit_log:$log,row_count:$count,rows:$rows}'
  fi
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  local matches="[]" status="not_found"
  local any_source_present=false
  if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    any_source_present=true
    local raw
    raw="$(grep -F "$id" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true)"
    if [[ -n "$raw" ]]; then
      matches="$(printf '%s' "$raw" | jq -sc '.' 2>/dev/null || echo '[]')"
    fi
  fi
  if [[ "$any_source_present" != true ]]; then
    status="unavailable"
  else
    local n; n="$(printf '%s' "$matches" | jq 'length' 2>/dev/null || echo 0)"
    n="${n//[^0-9]/}"; [[ -z "$n" ]] && n=0
    [[ "$n" -gt 0 ]] && status="found"
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg s "$status" \
    --arg log "$SCAFFOLD_AUDIT_LOG" --argjson m "$matches" \
    '{schema_version:$sv,command:"why",id:$id,status:$s,audit_log:$log,matches:$m,total_matches:($m|length)}'
}

# ---------- scaffolded main dispatcher ----------

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

# Early-dispatch intercept: canonical subcommand or intro flag → run the
# canonical surface and exit BEFORE the interactive reclaim flow below runs.
_scaffold_is_canonical_arg() {
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --info|--schema|--examples) return 0 ;;
    -h|--help) return 0 ;;
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

echo "================================================================"
echo "  disk-reclaim-batch-2026-05-07.sh"
echo "  Target: reclaim 165+ GB from /private/tmp + jeff-corpus source"
echo "================================================================"
echo ""
echo "BEFORE:"
show_disk
echo ""
log "start" "" "starting reclaim batch"

# ============================================================
# PHASE 1: jsm test scratch sandboxes (~140 GB)
# Confirmed by lsof: zero open handles. Confirmed by mtime: 1-3 days old.
# ============================================================
echo ""
echo "=== Phase 1: jsm test scratch (~140 GB) ==="
echo "Removes 13 jsm-auth-isolation.* + jsm-health-sandbox.* dirs"
if confirm "Proceed with Phase 1?"; then
  remove_explicit /private/tmp/jsm-auth-isolation.ZQM9pq
  remove_explicit /private/tmp/jsm-auth-isolation.G1oVHv
  remove_explicit /private/tmp/jsm-health-sandbox.QzcyWE
  remove_explicit /private/tmp/jsm-health-sandbox.oqso3K
  remove_explicit /private/tmp/jsm-health-sandbox.Gjx1J3
  remove_explicit /private/tmp/jsm-health-sandbox.Ft29hm
  remove_explicit /private/tmp/jsm-health-sandbox.BUSm5h
  remove_explicit /private/tmp/jsm-health-sandbox.9pbbfU
  remove_explicit /private/tmp/jsm-health-sandbox.m4C85z
  remove_explicit /private/tmp/jsm-health-sandbox.eVsgrC
  remove_explicit /private/tmp/jsm-health-sandbox.C7W3Og
  remove_explicit /private/tmp/jsm-health-sandbox.rJ26vj
  remove_explicit /private/tmp/jsm-health-sandbox.VgUC38
  echo ""
  echo "AFTER PHASE 1:"
  show_disk
fi

# ============================================================
# PHASE 2: beads-rust + mobile-eats + alps scratch (~17 GB)
# ============================================================
echo ""
echo "=== Phase 2: beads/mobile-eats/alps scratch (~17 GB) ==="
if confirm "Proceed with Phase 2?"; then
  remove_explicit /private/tmp/beads-rust-2k0fd
  remove_explicit /private/tmp/beads-rust-1l4fw
  remove_explicit /private/tmp/beads_rust-f505-build
  remove_explicit /private/tmp/mobile-eats-next-dev-cache-20260506151112-953
  remove_explicit /private/tmp/mobile-eats-next-failed-density-20260506122512
  remove_explicit /private/tmp/alps-demo-smoke-fix-pass
  remove_explicit /private/tmp/alpsinsurance-demo-dryrun-smoke-v2
  echo ""
  echo "AFTER PHASE 2:"
  show_disk
fi

# ============================================================
# PHASE 3: jeff-corpus bulk source removal (~9 GB)
# Joshua: "we don't want to delete jeff-corpus - we want the indexed stuff
#  to stay but the bulk of the repos - as long as our indexed data doesn't
#  leave - can go"
#
# Indexed data (PRESERVED — never touched):
#   ~/.socraticode/qdrant-data         (669 MB) socraticode collections
#   ~/.knowledge/qdrant_server_storage  (1.7 GB) jeff-stack collections
#   ~/.knowledge/qdrant_storage_openai  (703 MB) openai-embedded collections
#
# Bulk source (REMOVED — repos can be re-cloned anytime; indices already mined):
#   ~/Developer/jeff-corpus/<180 repos>  (~9 GB)
#
# Strategy: remove the directory itself. If you want to re-clone any specific
# repo, the indexed embeddings still answer questions about it — you only
# need to re-clone if you want to *modify* it.
# ============================================================
echo ""
echo "=== Phase 3: jeff-corpus bulk source removal (~9 GB) ==="
echo "PRESERVES: ~/.socraticode/qdrant-data + ~/.knowledge/qdrant_*"
echo "REMOVES: ~/Developer/jeff-corpus/ (180 repos source code)"
echo ""
echo "Verifying indexed data is intact BEFORE deletion..."
if [ -d "$HOME/.socraticode/qdrant-data" ] && [ -d "$HOME/.knowledge/qdrant_server_storage" ]; then
  echo "  [ok] indexed data confirmed present"
  du -sh "$HOME/.socraticode/qdrant-data" "$HOME/.knowledge/qdrant_server_storage" "$HOME/.knowledge/qdrant_storage_openai" 2>/dev/null
else
  echo "  [ABORT] indexed data missing — refusing to delete source corpus"
  echo "          fix indexed data first, then re-run Phase 3"
  exit 1
fi
echo ""
if confirm "Proceed with Phase 3 (jeff-corpus source removal)?"; then
  remove_explicit "$HOME/Developer/jeff-corpus"
  echo ""
  echo "AFTER PHASE 3:"
  show_disk
fi

# ============================================================
# DONE
# ============================================================
echo ""
echo "================================================================"
echo "  COMPLETE"
echo "================================================================"
echo ""
echo "FINAL:"
show_disk
echo ""
echo "Ledger: $LEDGER"
log "complete" "" "batch complete"

exit 0

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
