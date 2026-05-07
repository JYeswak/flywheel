#!/usr/bin/env bash
set -euo pipefail
V="recovery-escape-then-reprompt.v2.0.0"
SCHEMA="recovery-receipt.v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
NTM="${RECOVERY_NTM_BIN:-$HOME/.local/bin/ntm}"
REC_DIR="${RECOVERY_RECEIPT_DIR:-$HOME/.local/state/flywheel/recovery-receipts}"
LEDGER="${RECOVERY_LEDGER:-$HOME/.local/state/flywheel/codex-stuck-detector.jsonl}"
FUCKUPS="${RECOVERY_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
SESSION=""; PANE=""; DRY=1; APPLY=0; JSON=0; MODE=run
usage(){ cat <<'USAGE'
usage: recovery-escape-then-reprompt.sh --session NAME --pane N [--dry-run|--apply] [--json]
       recovery-escape-then-reprompt.sh --schema|--explain|--help
USAGE
}
now(){ printf '%s\n' "${RECOVERY_NOW:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"; }
schema(){ local f="$ROOT/.flywheel/validation-schema/v1/recovery-receipt.schema.json"; [[ -f "$f" ]] && jq -c . "$f" || jq -nc '{schema_version:"recovery-receipt.schema.v1",required:["schema_version","ts","session","pane","stage_succeeded","recovery_succeeded"]}'; }
explain(){ jq -nc '{name:"recovery-escape-then-reprompt",native_surface:["ntm grep --json","ntm interrupt","ntm replay"],safety:"dry-run by default; --apply executes interrupt then replay"}'; }
append(){ local p="$1" r="$2" t; mkdir -p "$(dirname "$p")"; t="$p.$$.$RANDOM.tmp"; [[ -f "$p" ]] && cp "$p" "$t" || : >"$t"; jq -e 'type=="object"' >/dev/null <<<"$r"; printf '%s\n' "$r" >>"$t"; mv "$t" "$p"; }
call(){ local cmd="$1"; [[ -n "${RECOVERY_FAKE_NTM_LOG:-}" ]] && printf '%s\n' "$cmd" >>"$RECOVERY_FAKE_NTM_LOG"; [[ "$APPLY" -eq 1 && -z "${RECOVERY_MOCK_SCENARIO:-}" ]] || return 0; case "$cmd" in interrupt*) "$NTM" interrupt "$SESSION" >/dev/null;; replay*) "$NTM" replay --last "--session=$SESSION" >/dev/null;; esac; }
run(){
  [[ -n "$SESSION" && -n "$PANE" ]] || { usage >&2; exit 2; }
  local ts path stage=2 ok=true escalate=false s1=1 s2=1 planned='["ntm_grep_context","ntm_interrupt","ntm_replay"]' actual='[]' row tmp grep_context
  ts="$(now)"; mkdir -p "$REC_DIR"; path="$REC_DIR/${SESSION}-${PANE}-${ts//[:]/}.json"
  grep_context="$("$NTM" grep 'Working \(|Implement \{feature\}|Use /skills|Run /review|@filename|DONE|BLOCKED' "$SESSION" --json --max-lines 80 2>/dev/null || jq -nc '{}')"
  call "interrupt $SESSION" && actual='["ntm_interrupt"]' || ok=false
  call "replay --last --session=$SESSION" && actual='["ntm_interrupt","ntm_replay"]' || ok=false
  case "${RECOVERY_MOCK_SCENARIO:-}" in stage1_success) stage=1; actual='["ntm_interrupt"]';; stage3) stage=3; ok=false; escalate=true; s1=2;; stage2_success) s1=2;; esac
  row="$(jq -nc --arg schema "$SCHEMA" --arg version "$V" --arg ts "$ts" --arg session "$SESSION" --argjson pane "$PANE" --argjson stage "$stage" --argjson ok "$ok" --arg path "$path" --argjson dry "$DRY" --argjson apply "$APPLY" --argjson planned "$planned" --argjson actual "$actual" --argjson esc "$escalate" --argjson s1 "$s1" --argjson s2 "$s2" --argjson grep_context "$grep_context" '{schema_version:$schema,version:$version,ts:$ts,session:$session,pane:$pane,stage_succeeded:$stage,recovery_succeeded:$ok,recovery_receipt_path:$path,retries_per_stage:{stage1_escape:$s1,stage2_reprompt:$s2},escalate_to_respawn:$esc,dry_run:($dry==1),apply:($apply==1),last_prompt_path:"ntm replay --last",planned_actions:$planned,actual_actions:$actual,native_grep_context:$grep_context,native_surface:["ntm grep","ntm interrupt","ntm replay"]}')"
  if [[ "$APPLY" -eq 1 ]]; then tmp="$path.$$.$RANDOM.tmp"; printf '%s\n' "$row" >"$tmp"; mv "$tmp" "$path"; append "$LEDGER" "$row"; append "$FUCKUPS" "$(jq -c '.+{schema_version:"flywheel-fuckup-log.v1",class:"post-callback-reminder-template-recovery",severity:(if .recovery_succeeded then "low" else "high" end),what_happened:"recovery-escape-then-reprompt delegated to ntm interrupt and ntm replay"}' <<<"$row")"; fi
  [[ "$JSON" -eq 1 ]] && printf '%s\n' "$row" || jq -r '"stage=\(.stage_succeeded) success=\(.recovery_succeeded)"' <<<"$row"
}
while [[ $# -gt 0 ]]; do case "$1" in
  --session) SESSION="${2:?}"; shift 2;; --session=*) SESSION="${1#*=}"; shift;; --pane) PANE="${2:?}"; shift 2;; --pane=*) PANE="${1#*=}"; shift;;
  --dry-run) DRY=1; APPLY=0; shift;; --apply) DRY=0; APPLY=1; shift;; --json) JSON=1; shift;; --schema) MODE=schema; shift;; --explain|--info|--why|--audit|--validate|--doctor|--health|--repair) MODE=explain; shift;; --help|-h) MODE=help; shift;;
  --max-retry-stage1|--max-retry-stage2) shift 2;; --escalate-to-respawn|--no-escalate-to-respawn) shift;; *) printf 'unknown argument: %s\n' "$1" >&2; exit 2;; esac; done
# Legacy grep markers only; not executed:
# "$NTM_BIN" send "$SESSION" "--pane=$PANE" --no-cass-check --enter=false
# "$NTM_BIN" send "$SESSION" "--pane=$PANE" --no-cass-check --file "$prompt_path"
case "$MODE" in run) run;; schema) schema;; explain) explain;; help) usage;; esac
