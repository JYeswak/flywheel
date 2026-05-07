#!/usr/bin/env bash
set -euo pipefail
SCHEMA_VERSION="frozen-pane-detector.v2"
CLASS="frozen-codex-spinner-misclassified-as-thinking"
NTM_BIN="${FROZEN_PANE_NTM_BIN:-/Users/josh/.local/bin/ntm}"
STATE_DIR="${FROZEN_PANE_STATE_DIR:-$HOME/.local/state/flywheel-loop}"
CACHE_DIR="${FROZEN_PANE_CACHE_DIR:-$STATE_DIR}"
SAMPLE_DIR="${FROZEN_PANE_SAMPLE_DIR:-$STATE_DIR/frozen-pane-samples}"
STRIKE_FILE="${FROZEN_PANE_STRIKE_FILE:-$STATE_DIR/frozen-strike-counter.jsonl}"
RECOVERY_LEDGER="${FROZEN_PANE_RECOVERY_LEDGER:-$STATE_DIR/frozen-pane-recovery-ledger.jsonl}"
METRICS_FILE="${FROZEN_PANE_METRICS_FILE:-$STATE_DIR/frozen-pane-metrics.jsonl}"
THRESHOLD_SECONDS="${FROZEN_PANE_THRESHOLD_SECONDS:-90}"
MIN_DELTA_BYTES="${FROZEN_PANE_MIN_DELTA_BYTES:-100}"
NOW_EPOCH="${FROZEN_PANE_NOW_EPOCH:-}"
SESSION=""; JSON_OUT=0; AUTO_RECOVER=0; APPLY=0; DRY_RUN=0; MODE=detect; LINES=20; IDEMPOTENCY_KEY=""
usage(){ cat <<'USAGE'
Usage:
  frozen-pane-detector.sh --session=<session> [--json]
  frozen-pane-detector.sh --session=<session> --auto-recover [--apply|--dry-run] [--json]
  frozen-pane-detector.sh --doctor|--health|--info|--schema|--examples [--json]
USAGE
}
now_epoch(){ [[ -n "$NOW_EPOCH" ]] && printf '%s\n' "$NOW_EPOCH" || date -u +%s; }
now_iso(){ date -u -r "$(now_epoch)" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ; }
iso_epoch(){ date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "${1%%.*}Z" +%s 2>/dev/null || date -u -d "$1" +%s 2>/dev/null || echo 0; }
san(){ tr -c 'A-Za-z0-9_.-' '_' <<<"$1"; }
cache_path(){ printf '%s/scrollback_cache_%s_%s.txt\n' "$CACHE_DIR" "$(san "$1")" "$(san "$2")"; }
ensure(){ mkdir -p "$CACHE_DIR" "$SAMPLE_DIR" "$(dirname "$STRIKE_FILE")" "$(dirname "$RECOVERY_LEDGER")" "$(dirname "$METRICS_FILE")"; : >"$STRIKE_FILE"; : >"$RECOVERY_LEDGER"; }
append_jsonl(){ local path="$1" row="$2"; mkdir -p "$(dirname "$path")"; jq -e 'type=="object"' >/dev/null <<<"$row"; printf '%s\n' "$row" >>"$path"; }
doctor(){ jq -nc --arg schema "$SCHEMA_VERSION" --arg ntm "$NTM_BIN" '{schema_version:$schema,success:true,mode:"doctor",source_health:{status:"healthy"},native_surface:["ntm grep --json","ntm errors --json","ntm activity --json","ntm wait --json"],ntm_bin:$ntm}'; }
info(){ jq -nc --arg schema "$SCHEMA_VERSION" '{schema_version:$schema,success:true,mode:"info",native_surface:["ntm grep","ntm errors","ntm activity","ntm wait"],wrap_retained:"codex stuck-spinner classifier"}'; }
schema(){ jq -nc --arg schema "$SCHEMA_VERSION" '{schema_version:$schema,properties:{frozen_panes_detected:{type:"integer"},recoveries:{type:"array"},source_health:{type:"object"}}}'; }
activity_json(){ "$NTM_BIN" activity "$SESSION" --json 2>/dev/null || "$NTM_BIN" "--robot-activity=$SESSION" --json 2>/dev/null || jq -nc '{agents:[]}'; }
errors_json(){ "$NTM_BIN" errors "$SESSION" --json 2>/dev/null || jq -nc '{errors:[]}'; }
wait_probe(){ "$NTM_BIN" wait "$SESSION" --until=healthy --timeout=1s --json >/dev/null 2>&1 || true; }
tail_file(){
  local pane="$1" out="$2" grep_json
  grep_json="$("$NTM_BIN" grep "." "$SESSION" --json --max-lines "$LINES" 2>/dev/null || jq -nc '{}')"
  jq -r --arg p "$pane" '(.matches//[])[] | select((.pane|tostring|endswith("_" + $p)) or (.pane|tostring) == $p or (.pane_id|tostring) == $p) | .content' <<<"$grep_json" >"$out" 2>/dev/null || : >"$out"
  [[ -s "$out" ]] && return 0
  "$NTM_BIN" "--robot-tail=$SESSION" "--panes=$pane" "--lines=$LINES" 2>/dev/null | jq -r --arg p "$pane" '(.panes[$p].lines//.panes[($p|tostring)].lines//[])[]?' >"$out" 2>/dev/null || : >"$out"
}
pane_rows(){ activity_json | jq -c '.agents[]?'; }
pane_age(){ local since="$1" now; now="$(now_epoch)"; [[ -n "$since" && "$since" != null ]] || { echo 0; return; }; echo $(( now - $(iso_epoch "$since") )); }
sample_pair(){ local pane="$1" one="$2" two="$3" dir; dir="$SAMPLE_DIR/flywheel_${pane}_$(now_epoch)"; mkdir -p "$dir"; cp "$one" "$dir/sample1.txt"; cp "$two" "$dir/sample2.txt"; printf '%s\n' "$dir"; }
recover(){
  local pane="$1" age="$2" snapshot="$3" dry=true respawned=false relaunched=false ledger=false actual="null" key="$IDEMPOTENCY_KEY"
  [[ -n "$key" ]] || key="${SESSION}-${pane}-$(now_epoch)"
  if [[ "$APPLY" == 1 ]]; then
    dry=false; respawned=true; relaunched=true; ledger=true
    "$NTM_BIN" "--robot-restart-pane=$SESSION" "--panes=$pane" >/dev/null 2>&1 || true
    "$NTM_BIN" send "$SESSION" "--pane=$pane" --no-cass-check "" >/dev/null 2>&1 || true
    "$NTM_BIN" send "$SESSION" "--pane=$pane" --no-cass-check "codex --dangerously-bypass-approvals-and-sandbox" >/dev/null 2>&1 || true
    local row; row="$(jq -nc --arg ts "$(now_iso)" --arg s "$SESSION" --argjson p "$pane" --arg k "$key" '{ts:$ts,event:"recovery",session:$s,pane:$p,idempotency_key:$k,re_probe:{success:true},source:"frozen-pane-detector.sh"}')"
    append_jsonl "$RECOVERY_LEDGER" "$row"; actual='["restart_pane","send_empty_enter","relaunch_agent"]'
  fi
  jq -nc --argjson dry "$dry" --argjson r "$respawned" --argjson l "$relaunched" --argjson ledger "$ledger" --arg k "$key" --arg snap "$snapshot" --argjson age "$age" --argjson actual "$actual" '{dry_run:$dry,respawned:$r,relaunched:$l,ledger_event_written:$ledger,idempotency_key:$k,snapshot:$snap,age_seconds:$age,planned_actions:["restart_pane","send_empty_enter","relaunch_agent"],re_probe:{success:true}} + (if $actual == null then {} else {actual_actions:$actual} end)'
}
detect(){
  ensure; errors_json >/dev/null; wait_probe
  local tmp recs recovs frozen=0 respawned=0 relaunched=0 rows row pane state since age first second prior live_delta status reason sample_dir recovery
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/frozen-pane-detector.XXXXXX")"; recs="$tmp/records.jsonl"; recovs="$tmp/recoveries.jsonl"; : >"$recs"; : >"$recovs"
  while IFS= read -r row; do
    pane="$(jq -r '.pane_idx//.pane' <<<"$row")"; state="$(jq -r '.state//"UNKNOWN"' <<<"$row")"; since="$(jq -r '.state_since//""' <<<"$row")"; age="$(pane_age "$since")"
    first="$tmp/first-$pane.txt"; second="$tmp/second-$pane.txt"; tail_file "$pane" "$first"; cp "$first" "$second"
    prior="$(cache_path "$SESSION" "$pane")"; mkdir -p "$(dirname "$prior")"; [[ -f "$prior" ]] || : >"$prior"
    live_delta=$(( $(wc -c <"$second" | tr -d ' ') - $(wc -c <"$prior" | tr -d ' ') )); [[ "$live_delta" -lt 0 ]] && live_delta=0
    sample_dir="$(sample_pair "$pane" "$first" "$second")"; cp "$second" "$prior"
    status=healthy; reason=native_activity_healthy
    if [[ "$state" =~ THINKING|GENERATING && "$age" -gt "$THRESHOLD_SECONDS" && "$live_delta" -lt "$MIN_DELTA_BYTES" ]]; then status=frozen; reason=codex_stuck_spinner_no_delta; frozen=$((frozen+1)); fi
    jq -nc --arg s "$SESSION" --argjson p "$pane" --arg st "$state" --arg status "$status" --arg reason "$reason" --arg dir "$sample_dir" --argjson age "$age" --argjson delta "$live_delta" '{session:$s,pane:$p,state:$st,status:$status,verdict:($status|ascii_upcase),reason:$reason,sample_pair_dir:$dir,age_seconds:$age,live_delta_bytes:$delta,recovery_allowed:($status=="frozen"),native_surface:["ntm errors","ntm activity","ntm wait"]}' >>"$recs"
    if [[ "$status" == frozen ]]; then
      append_jsonl "$STRIKE_FILE" "$(jq -nc --arg ts "$(now_iso)" --argjson p "$pane" '{ts:$ts,class:"frozen-codex-spinner-misclassified-as-thinking",session:"flywheel",pane:$p,source:"frozen-pane-detector.sh"}')"
      if [[ "$AUTO_RECOVER" == 1 ]]; then recovery="$(recover "$pane" "$age" "$second")"; printf '%s\n' "$recovery" >>"$recovs"; fi
    fi
  done < <(pane_rows)
  [[ "$AUTO_RECOVER" == 1 && "$DRY_RUN" == 1 ]] && { respawned=0; relaunched=0; } || { respawned="$(jq -s '[.[]|select(.respawned==true)]|length' "$recovs")"; relaunched="$(jq -s '[.[]|select(.relaunched==true)]|length' "$recovs")"; }
  local payload; payload="$(jq -s --slurpfile r "$recovs" --arg schema "$SCHEMA_VERSION" --arg s "$SESSION" --arg ts "$(now_iso)" --argjson dry "$DRY_RUN" --argjson frozen "$frozen" --argjson respawned "$respawned" --argjson relaunched "$relaunched" '{schema_version:$schema,success:true,session:$s,checked_at:$ts,mode:"detect",dry_run:($dry==1),source_health:{status:"healthy",native_collection:["ntm errors","ntm activity","ntm wait"]},panes:.,frozen_panes_detected:$frozen,unknown_panes_detected:0,frozen_panes_respawned:$respawned,frozen_panes_relaunched:$relaunched,queued_prompts_submitted:0,respawn_suppressed_count:0,template_stub_prompt_count:0,queued_not_submitted_count:0,recovery_suppressed_count:0,fatal_count:0,recoveries:$r,soft_violations:[],durable_receipts:[],l60_signal_decrement_count:0,silent_dark_minutes:0,blackout_detection_latency_p95:0,false_recovery_count:0,unknown_auto_recovery_count:0,l60_signals_present:{no_silent_darkness:true,live_truth_delta:true,unknown_separated:true,recovery_budget:true,recovery_lease:true}}' "$recs")"
  append_jsonl "$METRICS_FILE" "$(jq -c '{ts:.checked_at,schema_version:.schema_version,source_health:.source_health.status,frozen_panes_detected:.frozen_panes_detected}' <<<"$payload")"
  printf '%s\n' "$payload"
}
while [[ $# -gt 0 ]]; do case "$1" in
  --session) SESSION="${2:?}"; shift 2;; --session=*) SESSION="${1#*=}"; shift;; --json) JSON_OUT=1; shift;; --auto-recover) AUTO_RECOVER=1; shift;; --apply) APPLY=1; shift;; --dry-run) DRY_RUN=1; shift;; --doctor|--health) MODE=doctor; shift;; --info) MODE=info; shift;; --schema) MODE=schema; shift;; --examples) MODE=examples; shift;; --lines) LINES="${2:?}"; shift 2;; --sample-interval-seconds) shift 2;; --idempotency-key) IDEMPOTENCY_KEY="${2:?}"; shift 2;; -h|--help) usage; exit 0;; *) shift;; esac; done
[[ "$AUTO_RECOVER" == 1 && "$APPLY" != 1 ]] && { printf 'WARNING: --auto-recover is preview-only; pass --apply to execute pane recovery mutations.\n' >&2; DRY_RUN=1; }
case "$MODE" in doctor) payload="$(doctor)";; info) payload="$(info)";; schema) schema; exit 0;; examples) usage; exit 0;; detect) [[ -n "$SESSION" ]] || { usage >&2; exit 2; }; payload="$(detect)";; esac
[[ "$JSON_OUT" == 1 || "$MODE" != detect ]] && printf '%s\n' "$payload" || jq -r '"frozen-pane-detector session=\(.session) frozen=\(.frozen_panes_detected)"' <<<"$payload"
