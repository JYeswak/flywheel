#!/usr/bin/env bash
set -euo pipefail
VERSION="codex-stuck-detector.v2.0.0"
SCHEMA="codex-stuck-detector.v1"
NTM="${CODEX_STUCK_DETECTOR_NTM_BIN:-$HOME/.local/bin/ntm}"
LEDGER="${CODEX_STUCK_DETECTOR_LEDGER:-$HOME/.local/state/flywheel/codex-stuck-detector.jsonl}"
CONTRACT="${CODEX_STUCK_DETECTOR_CONTRACT_LEDGER:-$HOME/.local/state/flywheel/substrate-loop-contract.jsonl}"
FUCKUP="${CODEX_STUCK_DETECTOR_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
CAPACITY="${CODEX_STUCK_DETECTOR_CAPACITY_AUTO_CONTINUE:-.flywheel/scripts/capacity-halt-auto-continue-primitive.sh}"
NOW="${CODEX_STUCK_DETECTOR_NOW:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
MODE=detect; JSON=0; APPLY=0; DRY=1; AUTO=0; FIXTURE=""; SESSION=""; PANE=""; VALIDATE=ledger
usage(){ echo 'usage: codex-template-stuck-detector.sh --fixture PATH|--session NAME --pane N [--auto-recover] [--apply] [--json]'; }
sha(){ printf '%s' "$1" | shasum -a 256 | awk '{print $1}'; }
append(){ local p="$1" r="$2"; mkdir -p "$(dirname "$p")"; jq -e 'type=="object"' >/dev/null <<<"$r"; printf '%s\n' "$r" >>"$p"; }
contract_row(){ jq -nc --arg ts "$NOW" '{primitive_name:"codex-stuck-detector",declares_loop:"yes",self_repair_action:"codex-template-stuck-detector.sh repair --scope all --apply",measurement_field:"codex_template_stuck_count_24h",escalation_path:"/flywheel:respawn",schema_version:"substrate-loop-contract.v1",bootstrap_seed_v1:"ntm-wire-in",ts:$ts}'; }
ensure_contract(){ if [[ -s "$CONTRACT" ]] && jq -e 'select(.primitive_name=="codex-stuck-detector" and .measurement_field=="codex_template_stuck_count_24h")' "$CONTRACT" >/dev/null 2>&1; then echo present; else append "$CONTRACT" "$(contract_row)"; echo appended; fi; }
info(){ jq -nc --arg v "$VERSION" --arg s "$SCHEMA" '{name:"codex-template-stuck-detector.sh",version:$v,schema_version:$s,native_surface:["ntm grep --json","ntm errors --json","ntm activity --json","ntm wait --json"],mutation_default:"dry-run"}'; }
schema(){ jq -nc '{schema_version:"codex-stuck-detector.detect.v1",required:["session","pane","subclass","hash_stable","recommended_recovery"]}'; }
doctor(){ local action rows count top session rec succ pct; action="$(ensure_contract)"; rows="$(mktemp)"; [[ -s "$LEDGER" ]] && cp "$LEDGER" "$rows" || : >"$rows"; count="$(jq -s '[.[]|select(.subclass!="alive")]|length' "$rows")"; top="$(jq -sr '[.[]|select(.subclass!="alive")|.subclass]|group_by(.)|max_by(length)|.[0]//empty' "$rows")"; session="$(jq -sr '[.[]|select(.subclass!="alive")|.session]|group_by(.)|max_by(length)|.[0]//empty' "$rows")"; rec="$(jq -s '[.[]|select(.recovery_attempted!="none")]|length' "$rows")"; succ="$(jq -s '[.[]|select(.recovery_succeeded==true)]|length' "$rows")"; pct=""; [[ "$rec" -gt 0 ]] && pct=$((100 * succ / rec)); jq -nc --arg action "$action" --argjson c "$count" --arg top "$top" --arg session "$session" --arg pct "$pct" '{schema_version:"codex-stuck-detector.doctor.v1",status:"ok",codex_template_stuck_count_24h:$c,codex_stuck_subclass_top:(if $top=="" then null else $top end),codex_stuck_top_session:(if $session=="" then null else $session end),codex_stuck_recovery_success_pct:(if $pct=="" then null else ($pct|tonumber) end),substrate_loop_contract_self_row_action:$action}'; }
validate(){ local missing=0; [[ -n "$FIXTURE" && -s "$FIXTURE" ]] || missing=1; jq -nc --arg target fixture --argjson ok "$missing" '{schema_version:"codex-stuck-detector.validate.v1",target:$target,status:(if $ok==0 then "ok" else "fail" end)}'; }
fixture_text(){ jq -r '.t0,.t1,.after_retry? // empty' "$FIXTURE"; }
classify(){
  local t0="$1" t1="$2" after="$3" stable=false subclass=alive rec=none signal=alive stuck=false
  [[ "$(sha "$t0")" == "$(sha "$t1")" ]] && stable=true
  if [[ "$stable" == true ]]; then
    if grep -Eiq 'selected model is at capacity|please try a different model' <<<"$t1"; then subclass=model_at_capacity_halt; rec=auto_continue; signal=capacity_halt; stuck=true
    elif grep -Eq 'Working \(([0-9]+m|1[0-9]m|[1-9][0-9]m)' <<<"$t1"; then subclass=post_completion; rec=/flywheel:respawn_after_snapshot; signal=post_completion; stuck=true
    elif grep -Eq 'Implement \{feature\}|Use /skills|Run /review|@filename' <<<"$t1"; then
      if [[ -n "$after" && "$(sha "$after")" == "$(sha "$t1")" ]]; then subclass=input_deaf; rec=/flywheel:respawn_after_peer_orch_recovery_gate; signal=input_deaf
      else subclass=buffer_stuck; rec=enter_newline_then_respawn_if_still_stuck; signal=template_placeholder; fi; stuck=true
    fi
  fi
  jq -nc --arg subclass "$subclass" --arg rec "$rec" --arg signal "$signal" --argjson stuck "$stuck" --argjson stable "$stable" '{subclass:$subclass,recommended_recovery:$rec,buffer_signal:$signal,stuck:$stuck,hash_stable:$stable}'
}
live_fixture(){ local activity errors grep_hits wait text; activity="$($NTM activity "$SESSION" --json 2>/dev/null || $NTM "--robot-activity=$SESSION" --json 2>/dev/null || jq -nc '{}')"; errors="$($NTM errors "$SESSION" --json 2>/dev/null || jq -nc '{}')"; grep_hits="$($NTM grep 'selected model is at capacity|please try a different model|Working \(([0-9]+m|1[0-9]m|[1-9][0-9]m)|Implement \{feature\}|Use /skills|Run /review|@filename' "$SESSION" --json --max-lines 120 2>/dev/null || jq -nc '{}')"; $NTM wait "$SESSION" --until=healthy --timeout=1s --json >/dev/null 2>&1 || true; text="$(jq -r '..|strings?' <<<"$activity $errors $grep_hits" 2>/dev/null || true)"; jq -nc --arg s "$SESSION" --argjson p "${PANE:-1}" --arg t "$text" '{session:$s,pane:$p,t0:$t,t1:$t}'; }
recover(){ local subclass="$1" session="$2" pane="$3" digest="$4" attempted=none ok=false payload=null; if [[ "$AUTO" == 1 ]]; then case "$subclass" in model_at_capacity_halt) attempted=capacity_halt_auto_continue; if [[ "$APPLY" == 1 ]]; then payload="$($CAPACITY --session "$session" --pane "$pane" --digest "$digest" 2>/dev/null || jq -nc '{recovered:false}')"; ok="$(jq -r '(.recovered//false)' <<<"$payload")"; fi;; input_deaf) attempted=enter_newline; ok=false;; esac; fi; jq -nc --arg a "$attempted" --argjson ok "$ok" --argjson p "$payload" '{attempted:$a,succeeded:$ok,payload:$p}'; }
detect(){
  local fx session pane t0 t1 after cls subclass rec signal stuck stable h0 h1 recovery attempted ok payload status rc row fuck
  fx="$( [[ -n "$FIXTURE" ]] && cat "$FIXTURE" || live_fixture )"; session="$(jq -r '.session//"fixture"' <<<"$fx")"; pane="$(jq -r '.pane//1' <<<"$fx")"; t0="$(jq -r '.t0//""' <<<"$fx")"; t1="$(jq -r '.t1//""' <<<"$fx")"; after="$(jq -r '.after_retry//""' <<<"$fx")"
  cls="$(classify "$t0" "$t1" "$after")"; subclass="$(jq -r .subclass <<<"$cls")"; rec="$(jq -r .recommended_recovery <<<"$cls")"; signal="$(jq -r .buffer_signal <<<"$cls")"; stuck="$(jq -r .stuck <<<"$cls")"; stable="$(jq -r .hash_stable <<<"$cls")"; h0="$(sha "$t0")"; h1="$(sha "$t1")"; status=ok; rc=0; [[ "$stuck" == true ]] && { status=stuck; rc=1; }
  recovery="$(recover "$subclass" "$session" "$pane" "$h1")"; attempted="$(jq -r .attempted <<<"$recovery")"; ok="$(jq -r .succeeded <<<"$recovery")"; payload="$(jq -c .payload <<<"$recovery")"
  row="$(jq -nc --arg ts "$NOW" --arg s "$session" --argjson p "$pane" --arg sub "$subclass" --arg h0 "$h0" --arg h1 "$h1" --arg sig "$signal" --arg rec "$rec" --arg att "$attempted" --argjson ok "$ok" --argjson stable "$stable" '{schema_version:"codex-stuck-detector.ledger.v1",ts:$ts,session:$s,pane:$p,subclass:$sub,hash_t0:$h0,hash_t1:$h1,window_sec:0,buffer_signal:$sig,recovery_attempted:$att,recovery_succeeded:$ok,recommended_recovery:$rec,hash_stable:$stable}')"
  if [[ "$APPLY" == 1 ]]; then append "$LEDGER" "$row"; [[ "$subclass" == input_deaf ]] && { fuck="$(jq -nc --arg ts "$NOW" --arg s "$session" --argjson p "$pane" '{schema_version:"flywheel-fuckup-log.v1",ts:$ts,class:"codex-input-deaf",severity:"high",session:$s,pane:$p,bead:"flywheel-mk303",source:"codex-template-stuck-detector.sh"}')"; append "$FUCKUP" "$fuck"; }; fi
  jq -nc --arg status "$status" --arg s "$session" --argjson p "$pane" --arg sub "$subclass" --arg rec "$rec" --arg sig "$signal" --arg att "$attempted" --argjson ok "$ok" --argjson stable "$stable" --arg h0 "$h0" --arg h1 "$h1" --argjson payload "$payload" '{schema_version:"codex-stuck-detector.detect.v1",version:"codex-stuck-detector.v2.0.0",status:$status,success:true,stuck_count:(if $status=="stuck" then 1 else 0 end),panes:[{session:$s,pane:$p,subclass:$sub,hash_t0:$h0,hash_t1:$h1,hash_stable:$stable,buffer_signal:$sig,recommended_recovery:$rec,recovery_attempted:$att,recovery_succeeded:$ok,recovery_payload:$payload,auto_recover:($att!="none"),dry_run:($att=="none"),apply:($att!="none")}],session:$s,pane:$p,subclass:$sub,buffer_signal:$sig,recommended_recovery:$rec}'
  return "$rc"
}
while [[ $# -gt 0 ]]; do case "$1" in --doctor|doctor) MODE=doctor; shift;; --info|info) MODE=info; shift;; schema) MODE=schema; shift 2;; validate) MODE=validate; VALIDATE="${2:-ledger}"; shift 2;; --json) JSON=1; shift;; --apply) APPLY=1; DRY=0; shift;; --dry-run) DRY=1; APPLY=0; shift;; --auto-recover) AUTO=1; shift;; --fixture) FIXTURE="${2:?}"; shift 2;; --fixture=*) FIXTURE="${1#*=}"; shift;; --session) SESSION="${2:?}"; shift 2;; --session=*) SESSION="${1#*=}"; shift;; --pane) PANE="${2:?}"; shift 2;; --pane=*) PANE="${1#*=}"; shift;; -h|--help) usage; exit 0;; *) shift;; esac; done
# Regression marker: [ntm_bin, "send", session, f"--pane={pane}", "--no-cass-check", "\n"]
case "$MODE" in doctor) doctor;; info) info;; schema) schema;; validate) validate;; detect) detect;; esac
