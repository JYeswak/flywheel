#!/usr/bin/env bash
# canonical-cli-scoping-allow-large: one portable recovery primitive with canonical CLI, doctor, ledger, and fixture-facing recovery logic.
set -euo pipefail

VERSION="beads-db-recover.v1.0.0"
SCHEMA_VERSION="beads-db-recover/v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO="${BEADS_DB_RECOVER_REPO:-$REPO_ROOT_DEFAULT}"
LEDGER="${BEADS_DB_RECOVER_LEDGER:-$HOME/.local/state/flywheel/beads-recovery.jsonl}"
CONTRACT_LEDGER="${BEADS_DB_RECOVER_CONTRACT_LEDGER:-$HOME/.local/state/flywheel/substrate-loop-contract.jsonl}"
JSONL_APPEND_LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"
BR_BIN="${BEADS_DB_RECOVER_BR_BIN:-br}"
ALT_BR_BIN="${BEADS_DB_RECOVER_ALT_BR_BIN:-}"
NOW_OVERRIDE="${BEADS_DB_RECOVER_NOW:-}"

MODE="recover"
JSON_OUT=0
APPLY=0
DRY_RUN=1
FORCE=0
WATCH=0
WATCH_INTERVAL=5
REPAIR_SCOPE="openread"
VALIDATE_TARGET="repo"
WHY_ID=""
SCHEMA_TOPIC="doctor"
HELP_TOPIC=""
COMPLETION_SHELL=""
WIDTH=100
EXPLAIN=0
IDEMPOTENCY_KEY=""

usage() {
  cat <<'EOF'
usage:
  beads-db-recover.sh --repo PATH [--dry-run|--apply] [--force] [--json]
  beads-db-recover.sh doctor|--doctor [--repo PATH] [--json]
  beads-db-recover.sh health [--repo PATH] [--watch] [--interval N] [--json]
  beads-db-recover.sh repair --scope openread|substrate-contract|all [--dry-run|--apply] [--repo PATH] [--json]
  beads-db-recover.sh validate repo|ledger [--repo PATH] [--json]
  beads-db-recover.sh audit [--json]
  beads-db-recover.sh why ID [--json]
  beads-db-recover.sh schema recovery|doctor|ledger|contract [--json]
  beads-db-recover.sh --info|--examples|quickstart|help TOPIC|completion bash|zsh
EOF
}

now_iso() {
  if [[ -n "$NOW_OVERRIDE" ]]; then
    printf '%s\n' "$NOW_OVERRIDE"
  else
    date -u +%Y-%m-%dT%H:%M:%SZ
  fi
}

json_bool() {
  if [[ "$1" == "1" ]]; then printf true; else printf false; fi
}

emit() {
  local payload="$1" text="$2" rc="${3:-0}"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    printf '%s\n' "$text"
  fi
  return "$rc"
}

append_validated() {
  local path="$1" row="$2"
  [[ -r "$JSONL_APPEND_LIB" ]] || { echo "ERR: JSONL append primitive missing: $JSONL_APPEND_LIB" >&2; return 3; }
  # shellcheck source=/dev/null
  source "$JSONL_APPEND_LIB"
  fw_jsonl_append_validated "$path" "$row"
}

repo_abs() {
  local repo="$1"
  if [[ -d "$repo" ]]; then
    (cd "$repo" && pwd -P)
  else
    python3 - "$repo" <<'PY'
from pathlib import Path
import sys
print(Path(sys.argv[1]).expanduser())
PY
  fi
}

br_version() {
  local bin="$1"
  "$bin" --version 2>&1 | head -1 || printf 'unknown\n'
}

integrity_json() {
  local repo="$1" db out status
  db="$repo/.beads/beads.db"
  if [[ ! -f "$db" ]]; then
    jq -nc --arg db "$db" '{db_path:$db,beads_db_integrity_check_status:"missing_db",integrity_output:"missing_db",status:"missing_db"}'
    return 0
  fi
  if ! command -v sqlite3 >/dev/null 2>&1; then
    jq -nc --arg db "$db" '{db_path:$db,beads_db_integrity_check_status:"sqlite3_missing",integrity_output:"sqlite3_missing",status:"error"}'
    return 0
  fi
  out="$(sqlite3 "$db" 'PRAGMA integrity_check;' 2>&1 || true)"
  if [[ "$out" == "ok" ]]; then status="ok"; else status="$out"; fi
  jq -nc --arg db "$db" --arg status "$status" --arg out "$out" \
    '{db_path:$db,beads_db_integrity_check_status:$status,integrity_output:$out,status:(if $status=="ok" then "ok" else "error" end)}'
}

ledger_summary_json() {
  local now
  now="$(now_iso)"
  python3 - "$LEDGER" "$now" <<'PY'
from __future__ import annotations
import json, sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

ledger = Path(sys.argv[1]).expanduser()
now_raw = sys.argv[2]

def parse_dt(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except Exception:
        return None

now = parse_dt(now_raw) or datetime.now(timezone.utc)
rows = []
if ledger.exists():
    for line in ledger.read_text(encoding="utf-8", errors="replace").splitlines():
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        if isinstance(row, dict):
            rows.append(row)
last_ts = None
count_24h = 0
for row in rows:
    ts = parse_dt(row.get("ts"))
    if ts is None:
        continue
    if last_ts is None or ts > last_ts:
        last_ts = ts
    if ts >= now - timedelta(hours=24):
        count_24h += 1
print(json.dumps({
    "beads_db_recovery_last_24h_count": count_24h,
    "beads_db_recovery_last_ts": last_ts.isoformat().replace("+00:00", "Z") if last_ts else None,
    "ledger_path": str(ledger),
}, separators=(",", ":")))
PY
}

doctor_json() {
  local repo_abs_path summary integrity status
  repo_abs_path="$(repo_abs "$REPO")"
  summary="$(ledger_summary_json)"
  integrity="$(integrity_json "$repo_abs_path")"
  status="$(jq -r --argjson summary "$summary" '
    if .beads_db_integrity_check_status != "ok" and .beads_db_integrity_check_status != "missing_db" then "error"
    elif ($summary.beads_db_recovery_last_24h_count // 0) >= 2 then "warn"
    else "pass" end
  ' <<<"$integrity")"
  jq -nc \
    --arg schema_version "$SCHEMA_VERSION.doctor" \
    --arg version "$VERSION" \
    --arg repo "$repo_abs_path" \
    --arg status "$status" \
    --argjson summary "$summary" \
    --argjson integrity "$integrity" \
    '{schema_version:$schema_version,version:$version,command:"doctor",scope:"beads-db-recovery",repo:$repo,status:$status,
      beads_db_recovery_last_24h_count:($summary.beads_db_recovery_last_24h_count // 0),
      beads_db_recovery_last_ts:$summary.beads_db_recovery_last_ts,
      beads_db_integrity_check_status:$integrity.beads_db_integrity_check_status,
      integrity_output:$integrity.integrity_output,
      ledger_path:$summary.ledger_path,
      thresholds:{recurring_warn_last_24h:2,integrity_error:"beads_db_integrity_check_status != ok"},
      warnings:(if (($summary.beads_db_recovery_last_24h_count // 0) >= 2) then [{code:"beads_db_recovery_recurring",message:"two or more Beads DB recoveries in 24h"}] else [] end),
      errors:(if ($integrity.beads_db_integrity_check_status != "ok" and $integrity.beads_db_integrity_check_status != "missing_db") then [{code:"beads_db_integrity_check_failed",message:$integrity.integrity_output}] else [] end)}'
}

health_json() {
  local doc
  doc="$(doctor_json)"
  jq -c '{schema_version:"beads-db-recover.health.v1",command:"health",status:.status,repo:.repo,beads_db_integrity_check_status:.beads_db_integrity_check_status,beads_db_recovery_last_24h_count:.beads_db_recovery_last_24h_count}' <<<"$doc"
}

active_lock_reason() {
  local repo="$1"
  if [[ -e "$repo/.beads/.lock" ]]; then
    printf 'active_lock:%s\n' "$repo/.beads/.lock"
    return 0
  fi
  if command -v pgrep >/dev/null 2>&1 && pgrep -fl '(^|/)br([[:space:]]|$)' >/dev/null 2>&1; then
    pgrep -fl '(^|/)br([[:space:]]|$)' | head -3 | tr '\n' ';'
    return 0
  fi
  return 1
}

recovery_plan_json() {
  local repo="$1" integrity
  integrity="$(integrity_json "$repo")"
  jq -nc --arg repo "$repo" --arg ledger "$LEDGER" --argjson integrity "$integrity" '{
    schema_version:"beads-db-recover.plan.v1",
    command:"recover",
    dry_run:true,
    repo:$repo,
    ledger_path:$ledger,
    integrity_check_pre:$integrity.integrity_output,
    planned_actions:[
      "halt_check_no_active_beads_lock_or_br_process",
      "backup_.beads/beads.db",
      "probe_sqlite_integrity_check",
      "remove_db_wal_shm_and_br_init",
      "br_sync_import_only_rebuild_force_with_fk_orphan_tolerance",
      "sqlite_vacuum",
      "verify_integrity_check_ok",
      "br_ready_and_dep_cycles_smoke",
      "try_alternative_br_version_if_smoke_fails"
    ],
    would_write:[],
    would_delete:[],
    would_call_external:["br init","br sync --import-only --rebuild --force","sqlite3 VACUUM","br ready --json","br dep cycles --json"],
    blocked_by:[]
  }'
}

append_recovery_row() {
  local repo="$1" trigger="$2" backup="$3" step="$4" pre="$5" post="$6" fk="$7" brv="$8" success="$9" wall="${10}" reason="${11:-}"
  local row
  row="$(jq -nc \
    --arg ts "$(now_iso)" \
    --arg repo "$repo" \
    --arg trigger "$trigger" \
    --arg backup_path "$backup" \
    --arg integrity_pre "$pre" \
    --arg integrity_post "$post" \
    --arg br_version_used "$brv" \
    --arg reason "$reason" \
    --argjson step_completed "$step" \
    --argjson fk_errors_count "$fk" \
    --argjson success "$success" \
    --argjson recovery_walltime_sec "$wall" \
    '{ts:$ts,repo:$repo,trigger:$trigger,backup_path:$backup_path,step_completed:$step_completed,integrity_check_pre:$integrity_pre,integrity_check_post:$integrity_post,fk_errors_count:$fk_errors_count,br_version_used:$br_version_used,success:$success,recovery_walltime_sec:$recovery_walltime_sec} + (if $reason != "" then {reason:$reason} else {} end)')"
  append_validated "$LEDGER" "$row"
}

run_cmd_capture() {
  local outfile="$1"; shift
  set +e
  "$@" >"$outfile" 2>&1
  local rc=$?
  set -e
  return "$rc"
}

run_recovery() {
  local repo_abs_path db jsonl lock_reason pre_json pre backup="" start end wall brv trigger="openread_storage_cursor_root_page_unknown"
  local sync_out sync_rc sync_retry_out sync_retry_rc fk_errors=0 post post_json ready_out cycles_out step=0 rc=0 reason=""
  repo_abs_path="$(repo_abs "$REPO")"
  db="$repo_abs_path/.beads/beads.db"
  jsonl="$repo_abs_path/.beads/issues.jsonl"
  brv="$(br_version "$BR_BIN")"

  [[ -d "$repo_abs_path" ]] || { emit "$(jq -nc --arg repo "$repo_abs_path" '{schema_version:"beads-db-recover.run.v1",status:"fail",reason:"repo_missing",repo:$repo}')" "FAIL reason=repo_missing repo=$repo_abs_path" 1; return 1; }

  if [[ "$DRY_RUN" -eq 1 ]]; then
    emit "$(recovery_plan_json "$repo_abs_path")" "DRY-RUN repo=$repo_abs_path" 0
    return 0
  fi

  if [[ ! -s "$jsonl" ]]; then
    reason="no_jsonl_to_sync_from"
    append_recovery_row "$repo_abs_path" "$trigger" "" 0 "" "" 0 "$brv" false 0 "$reason" || true
    emit "$(jq -nc --arg repo "$repo_abs_path" --arg reason "$reason" '{schema_version:"beads-db-recover.run.v1",status:"fail",success:false,repo:$repo,reason:$reason,step_completed:0}')" "FAIL reason=$reason repo=$repo_abs_path" 1
    return 1
  fi

  if [[ "$FORCE" -ne 1 ]] && lock_reason="$(active_lock_reason "$repo_abs_path")"; then
    reason="active_lock"
    append_recovery_row "$repo_abs_path" "$trigger" "" 1 "" "" 0 "$brv" false 0 "$reason" || true
    emit "$(jq -nc --arg repo "$repo_abs_path" --arg reason "$reason" --arg detail "$lock_reason" '{schema_version:"beads-db-recover.run.v1",status:"blocked",success:false,repo:$repo,reason:$reason,detail:$detail,step_completed:1}')" "BLOCKED reason=$reason detail=$lock_reason" 1
    return 1
  fi
  step=1

  if [[ ! -f "$db" ]]; then
    reason="no_db_to_backup"
    append_recovery_row "$repo_abs_path" "$trigger" "" "$step" "" "" 0 "$brv" false 0 "$reason" || true
    emit "$(jq -nc --arg repo "$repo_abs_path" --arg reason "$reason" '{schema_version:"beads-db-recover.run.v1",status:"fail",success:false,repo:$repo,reason:$reason,step_completed:1}')" "FAIL reason=$reason repo=$repo_abs_path" 1
    return 1
  fi

  start="$(date +%s)"
  backup="$repo_abs_path/.beads/beads.db.bak.$(date -u +%Y%m%dT%H%M%SZ)"
  cp "$db" "$backup"
  step=2

  pre_json="$(integrity_json "$repo_abs_path")"
  pre="$(jq -r '.integrity_output' <<<"$pre_json")"
  step=3

  rm -f "$db" "$repo_abs_path/.beads/beads.db-wal" "$repo_abs_path/.beads/beads.db-shm"
  (cd "$repo_abs_path" && "$BR_BIN" init --force --json >/dev/null)
  step=4

  sync_out="$(mktemp "${TMPDIR:-/tmp}/beads-db-recover-sync.XXXXXX")"
  set +e
  (cd "$repo_abs_path" && "$BR_BIN" sync --import-only --rebuild --force --json) >"$sync_out" 2>&1
  sync_rc=$?
  set -e
  if [[ "$sync_rc" -ne 0 ]] && rg -qi 'foreign key|fk|orphan' "$sync_out"; then
    fk_errors="$(rg -ci 'foreign key|fk|orphan' "$sync_out" || printf '0')"
    sync_retry_out="$(mktemp "${TMPDIR:-/tmp}/beads-db-recover-sync-retry.XXXXXX")"
    set +e
    (cd "$repo_abs_path" && "$BR_BIN" sync --import-only --rebuild --force --orphans skip --json) >"$sync_retry_out" 2>&1
    sync_retry_rc=$?
    set -e
    cat "$sync_retry_out" >>"$sync_out"
    sync_rc="$sync_retry_rc"
  fi
  fk_errors="$(rg -ci 'foreign key|fk|orphan' "$sync_out" || printf '0')"
  if [[ "$sync_rc" -ne 0 ]]; then
    reason="sync_import_failed"
    end="$(date +%s)"; wall=$((end - start))
    append_recovery_row "$repo_abs_path" "$trigger" "$backup" 5 "$pre" "" "$fk_errors" "$brv" false "$wall" "$reason" || true
    emit "$(jq -Rs --arg repo "$repo_abs_path" --arg reason "$reason" --arg backup "$backup" --argjson fk "$fk_errors" '{schema_version:"beads-db-recover.run.v1",status:"fail",success:false,repo:$repo,reason:$reason,backup_path:$backup,fk_errors_count:$fk,step_completed:5,sync_output:.}' <"$sync_out")" "FAIL reason=$reason repo=$repo_abs_path" 1
    return 1
  fi
  step=5

  sqlite3 "$db" 'VACUUM;'
  step=6

  post_json="$(integrity_json "$repo_abs_path")"
  post="$(jq -r '.integrity_output' <<<"$post_json")"
  if [[ "$post" != "ok" ]]; then
    reason="post_integrity_check_failed"
    end="$(date +%s)"; wall=$((end - start))
    append_recovery_row "$repo_abs_path" "$trigger" "$backup" 7 "$pre" "$post" "$fk_errors" "$brv" false "$wall" "$reason" || true
    emit "$(jq -nc --arg repo "$repo_abs_path" --arg reason "$reason" --arg backup "$backup" --arg pre "$pre" --arg post "$post" '{schema_version:"beads-db-recover.run.v1",status:"fail",success:false,repo:$repo,reason:$reason,backup_path:$backup,integrity_check_pre:$pre,integrity_check_post:$post,step_completed:7}')" "FAIL reason=$reason integrity=$post" 1
    return 1
  fi
  step=7

  ready_out="$(mktemp "${TMPDIR:-/tmp}/beads-db-recover-ready.XXXXXX")"
  cycles_out="$(mktemp "${TMPDIR:-/tmp}/beads-db-recover-cycles.XXXXXX")"
  run_cmd_capture "$ready_out" bash -c "cd $(printf '%q' "$repo_abs_path") && $(printf '%q' "$BR_BIN") ready --json" || rc=$?
  run_cmd_capture "$cycles_out" bash -c "cd $(printf '%q' "$repo_abs_path") && $(printf '%q' "$BR_BIN") dep cycles --json" || rc=$?
  if [[ "$rc" -ne 0 && -n "$ALT_BR_BIN" && -x "$ALT_BR_BIN" ]]; then
    brv="$(br_version "$ALT_BR_BIN")"
    run_cmd_capture "$ready_out" bash -c "cd $(printf '%q' "$repo_abs_path") && $(printf '%q' "$ALT_BR_BIN") ready --json" || rc=$?
    run_cmd_capture "$cycles_out" bash -c "cd $(printf '%q' "$repo_abs_path") && $(printf '%q' "$ALT_BR_BIN") dep cycles --json" || rc=$?
  fi
  if [[ "$rc" -ne 0 ]]; then
    reason="br_smoke_failed"
    end="$(date +%s)"; wall=$((end - start))
    append_recovery_row "$repo_abs_path" "$trigger" "$backup" 8 "$pre" "$post" "$fk_errors" "$brv" false "$wall" "$reason" || true
    emit "$(jq -Rs --arg repo "$repo_abs_path" --arg reason "$reason" --arg backup "$backup" --arg pre "$pre" --arg post "$post" '{schema_version:"beads-db-recover.run.v1",status:"fail",success:false,repo:$repo,reason:$reason,backup_path:$backup,integrity_check_pre:$pre,integrity_check_post:$post,step_completed:8,smoke_output:.}' <"$ready_out")" "FAIL reason=$reason repo=$repo_abs_path" 1
    return 1
  fi
  step=9

  end="$(date +%s)"; wall=$((end - start))
  append_recovery_row "$repo_abs_path" "$trigger" "$backup" "$step" "$pre" "$post" "$fk_errors" "$brv" true "$wall"
  emit "$(jq -nc \
    --arg repo "$repo_abs_path" \
    --arg backup "$backup" \
    --arg ledger "$LEDGER" \
    --arg pre "$pre" \
    --arg post "$post" \
    --arg brv "$brv" \
    --argjson fk "$fk_errors" \
    --argjson wall "$wall" \
    '{schema_version:"beads-db-recover.run.v1",status:"pass",success:true,repo:$repo,backup_path:$backup,ledger_path:$ledger,step_completed:9,integrity_check_pre:$pre,integrity_check_post:$post,fk_errors_count:$fk,br_version_used:$brv,recovery_walltime_sec:$wall,actual_actions:["halt_check","backup","integrity_pre","reinit","jsonl_import","vacuum","integrity_post","br_ready_and_dep_cycles","alt_br_fallback_if_needed"]}')" \
    "PASS repo=$repo_abs_path backup=$backup"
}

contract_row_json() {
  jq -nc --arg ts "$(now_iso)" '{
    primitive_name:"beads-db-recover",
    declares_loop:"yes",
    self_repair_action:"recover --apply",
    measurement_field:"beads_db_recovery_last_24h_count",
    escalation_path:"doctor scope beads-db-recovery error -> fuckup-log:class=beads-db-corruption-recurring",
    schema_version:"substrate-loop-contract.v1",
    bootstrap_seed_v1:"see flywheel-jnc7a",
    ts:$ts
  }'
}

repair_contract() {
  local row
  row="$(contract_row_json)"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    emit "$(jq -nc --argjson row "$row" '{schema_version:"beads-db-recover.repair.v1",command:"repair",scope:"substrate-contract",dry_run:true,would_write:[$row],actual_actions:[]}')" "DRY-RUN scope=substrate-contract" 0
    return 0
  fi
  append_validated "$CONTRACT_LEDGER" "$row"
  emit "$(jq -nc --arg ledger "$CONTRACT_LEDGER" --argjson row "$row" '{schema_version:"beads-db-recover.repair.v1",command:"repair",scope:"substrate-contract",dry_run:false,status:"pass",ledger_path:$ledger,actual_actions:["append_substrate_loop_contract_row"],row:$row}')" "PASS scope=substrate-contract ledger=$CONTRACT_LEDGER" 0
}

validate_json() {
  local repo_abs_path payload rc=0 jsonl_present=0
  repo_abs_path="$(repo_abs "$REPO")"
  case "$VALIDATE_TARGET" in
    repo)
      payload="$(integrity_json "$repo_abs_path")"
      if [[ -s "$repo_abs_path/.beads/issues.jsonl" ]]; then jsonl_present=1; else rc=1; fi
      jq -c --arg repo "$repo_abs_path" --argjson jsonl_present "$(json_bool "$jsonl_present")" \
        '. + {schema_version:"beads-db-recover.validate.v1",command:"validate",target:"repo",repo:$repo,jsonl_present:$jsonl_present}' <<<"$payload"
      return "$rc"
      ;;
    ledger)
      if [[ ! -f "$LEDGER" ]]; then
        jq -nc --arg ledger "$LEDGER" '{schema_version:"beads-db-recover.validate.v1",command:"validate",target:"ledger",ledger_path:$ledger,status:"missing",parseable:true,row_count:0}'
        return 0
      fi
      jq -s -c --arg ledger "$LEDGER" '{schema_version:"beads-db-recover.validate.v1",command:"validate",target:"ledger",ledger_path:$ledger,status:"pass",parseable:true,row_count:length}' "$LEDGER"
      ;;
    *)
      echo "ERR: unknown validate target: $VALIDATE_TARGET" >&2
      return 2 ;;
  esac
}

audit_json() {
  if [[ ! -f "$LEDGER" ]]; then
    jq -nc --arg ledger "$LEDGER" '{schema_version:"beads-db-recover.audit.v1",command:"audit",ledger_path:$ledger,rows:[]}'
    return 0
  fi
  jq -s -c --arg ledger "$LEDGER" '{schema_version:"beads-db-recover.audit.v1",command:"audit",ledger_path:$ledger,rows:(.[-20:] // [])}' "$LEDGER"
}

why_json() {
  if [[ ! -f "$LEDGER" ]]; then
    jq -nc --arg id "$WHY_ID" --arg ledger "$LEDGER" '{schema_version:"beads-db-recover.why.v1",command:"why",id:$id,ledger_path:$ledger,match:null}'
    return 0
  fi
  jq -s -c --arg id "$WHY_ID" --arg ledger "$LEDGER" '{schema_version:"beads-db-recover.why.v1",command:"why",id:$id,ledger_path:$ledger,match:(map(select((.repo // "" | contains($id)) or (.trigger // "" | contains($id)) or (.backup_path // "" | contains($id)))) | last // null)}' "$LEDGER"
}

info_json() {
  jq -nc --arg version "$VERSION" --arg schema_version "$SCHEMA_VERSION" --arg repo "$REPO" --arg ledger "$LEDGER" --arg contract "$CONTRACT_LEDGER" --arg br "$BR_BIN" --arg br_version "$(br_version "$BR_BIN")" --arg jsonl_append_lib "$JSONL_APPEND_LIB" \
    '{name:"beads-db-recover.sh",version:$version,schema_version:$schema_version,repo:$repo,ledger_path:$ledger,substrate_loop_contract_ledger:$contract,br_bin:$br,br_version:$br_version,jsonl_append_lib:$jsonl_append_lib,exit_codes:{"0":"success","1":"domain failure or doctor error","2":"usage error","3":"append primitive unavailable"},canonical_cli_surfaces:["doctor","health","repair","validate","audit","why","schema","--info","--examples","quickstart","help","completion"],mutation_requires:"--apply",force_gate:"--force bypasses halt check only"}'
}

examples_json() {
  jq -nc '{command:"examples",examples:[
    {name:"dry-run current repo",command:".flywheel/scripts/beads-db-recover.sh --repo /Users/josh/Developer/flywheel --dry-run --json"},
    {name:"apply after confirming backup",command:".flywheel/scripts/beads-db-recover.sh --repo /path/to/repo --apply --json"},
    {name:"doctor scope",command:"~/.claude/skills/.flywheel/bin/flywheel-loop doctor --repo /Users/josh/Developer/flywheel --scope beads-db-recovery --json"},
    {name:"append self-row",command:".flywheel/scripts/beads-db-recover.sh repair --scope substrate-contract --apply --json"},
    {name:"audit recoveries",command:".flywheel/scripts/beads-db-recover.sh audit --json"}
  ]}'
}

quickstart_json() {
  jq -nc '{command:"quickstart",status:"ok",steps:[
    "Run doctor to inspect current integrity and 24h recovery frequency.",
    "Run dry-run to see the planned backup/rebuild/import/vacuum sequence.",
    "Use --apply only on the affected repo after file reservations and no active br locks.",
    "Keep the backup path from the JSON output.",
    "Run audit or flywheel-loop doctor --scope beads-db-recovery after recovery."
  ]}'
}

schema_json() {
  case "$SCHEMA_TOPIC" in
    recovery) jq -nc '{schema_version:"beads-db-recover.recovery.schema.v1",required:["repo","backup_path","step_completed","integrity_check_pre","integrity_check_post","fk_errors_count","br_version_used","success","recovery_walltime_sec"]}' ;;
    doctor) jq -nc '{schema_version:"beads-db-recover.doctor.schema.v1",required:["beads_db_recovery_last_24h_count","beads_db_recovery_last_ts","beads_db_integrity_check_status"]}' ;;
    ledger) jq -nc '{schema_version:"beads-db-recover.ledger.schema.v1",required:["ts","repo","trigger","backup_path","step_completed","integrity_check_pre","integrity_check_post","fk_errors_count","br_version_used","success","recovery_walltime_sec"]}' ;;
    contract) jq -nc '{schema_version:"substrate-loop-contract.v1",required:["primitive_name","declares_loop","self_repair_action","measurement_field","escalation_path","schema_version"]}' ;;
    *) echo "ERR: unknown schema topic: $SCHEMA_TOPIC" >&2; return 2 ;;
  esac
}

completion() {
  if [[ -z "$COMPLETION_SHELL" || "$COMPLETION_SHELL" == "--help" || "$COMPLETION_SHELL" == "-h" ]]; then
    usage
    return 0
  fi
  case "$COMPLETION_SHELL" in
    bash)
      cat <<'EOF'
_beads_db_recover_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "--repo --dry-run --apply --force --json doctor --doctor health repair validate audit why schema --scope --info --examples quickstart help completion --watch --interval" -- "$cur") )
}
complete -F _beads_db_recover_completion beads-db-recover.sh
EOF
      ;;
    zsh)
      printf 'compadd -- --repo --dry-run --apply --force --json doctor --doctor health repair validate audit why schema --scope --info --examples quickstart help completion --watch --interval\n'
      ;;
    *) echo "ERR: completion shell must be bash or zsh" >&2; return 2 ;;
  esac
}

help_json() {
  jq -nc --arg topic "$HELP_TOPIC" '{command:"help",topic:$topic,text:"Topics: recovery, doctor, repair, ledger. Recovery backs up .beads/beads.db, rebuilds from .beads/issues.jsonl, tolerates FK/orphan import fallout, vacuums, verifies integrity, and records a validated JSONL audit row."}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="${2:-}"; shift 2 ;;
    --repo=*) REPO="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --dry-run) DRY_RUN=1; APPLY=0; shift ;;
    --force) FORCE=1; shift ;;
    --doctor|doctor) MODE="doctor"; shift ;;
    --health|health) MODE="health"; shift ;;
    --repair|repair) MODE="repair"; shift ;;
    validate) MODE="validate"; VALIDATE_TARGET="${2:-repo}"; shift $(( $# >= 2 ? 2 : 1 )) ;;
    audit) MODE="audit"; shift ;;
    why) MODE="why"; WHY_ID="${2:-}"; shift 2 ;;
    schema) MODE="schema"; SCHEMA_TOPIC="${2:-doctor}"; shift 2 ;;
    --scope) REPAIR_SCOPE="${2:-}"; shift 2 ;;
    --scope=*) REPAIR_SCOPE="${1#*=}"; shift ;;
    --watch) WATCH=1; shift ;;
    --interval|-i) WATCH_INTERVAL="${2:-5}"; shift 2 ;;
    --explain) EXPLAIN=1; shift ;;
    --idempotency-key) IDEMPOTENCY_KEY="${2:-}"; shift 2 ;;
    --no-color|--no-emoji) shift ;;
    --width) WIDTH="${2:-100}"; shift 2 ;;
    --info) MODE="info"; shift ;;
    --examples|examples) MODE="examples"; shift ;;
    quickstart) MODE="quickstart"; shift ;;
    help) MODE="help"; HELP_TOPIC="${2:-recovery}"; shift $(( $# >= 2 ? 2 : 1 )) ;;
    completion) MODE="completion"; COMPLETION_SHELL="${2:-}"; shift $(( $# >= 2 ? 2 : 1 )) ;;
    --help|-h) usage; exit 0 ;;
    *) echo "ERR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$MODE" in
  recover) run_recovery ;;
  doctor)
    payload="$(doctor_json)"
    if [[ "$JSON_OUT" -eq 1 ]]; then printf '%s\n' "$payload"; else jq -r '"status=\(.status) beads_db_recovery_last_24h_count=\(.beads_db_recovery_last_24h_count) beads_db_integrity_check_status=\(.beads_db_integrity_check_status)"' <<<"$payload"; fi
    [[ "$(jq -r '.status' <<<"$payload")" != "error" ]]
    ;;
  health)
    if [[ "$WATCH" -eq 1 ]]; then
      while true; do health_json; sleep "$WATCH_INTERVAL"; done
    else
      payload="$(health_json)"
      if [[ "$JSON_OUT" -eq 1 ]]; then printf '%s\n' "$payload"; else jq -r '"status=\(.status) integrity=\(.beads_db_integrity_check_status)"' <<<"$payload"; fi
    fi
    ;;
  repair)
    case "$REPAIR_SCOPE" in
      openread|recovery|beads-db-recovery) run_recovery ;;
      substrate-contract) repair_contract ;;
      all)
        repair_contract
        ;;
      *) echo "ERR: unknown repair scope: $REPAIR_SCOPE" >&2; exit 2 ;;
    esac
    ;;
  validate) validate_json ;;
  audit) audit_json ;;
  why) why_json ;;
  schema) schema_json ;;
  info) info_json ;;
  examples) examples_json ;;
  quickstart) quickstart_json ;;
  help) if [[ "$JSON_OUT" -eq 1 ]]; then help_json; else jq -r '.text' <<<"$(help_json)"; fi ;;
  completion) completion ;;
  *) echo "ERR: unknown mode: $MODE" >&2; exit 2 ;;
esac
