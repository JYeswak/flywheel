#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
NTM="${RECENCY_CLASSIFIER_NTM_BIN:-/Users/josh/.local/bin/ntm}"
SESSION=""; PANE=""; PEER="${RECENCY_CLASSIFIER_PEER_PANE:-}"; LINES=80; JSON=0; MODE=classify
usage(){ cat <<'USAGE'
usage: recency-weighted-two-truth-classifier.sh [--json] [--lines N] < tail.txt
       recency-weighted-two-truth-classifier.sh --session NAME --pane N [--peer-pane N] [--json]
       recency-weighted-two-truth-classifier.sh --info|--check|--schema|--doctor|--health|--validate|--audit|--why|--repair [--json]
USAGE
}
info(){ jq -nc --arg root "$ROOT" '{name:"recency_weighted_two_truth_classifier",schema_version:"recency-weighted-two-truth-classifier/v2",root:$root,native_surface:["ntm diff --json","ntm --robot-activity --json"],mutation_default:"dry-run",verdicts:["WAITING","THINKING","ERROR","UNKNOWN"]}'; }
schema(){ jq -nc '{schema_version:"recency-weighted-two-truth-classifier/schema/v2",properties:{verdict:{enum:["WAITING","THINKING","ERROR","UNKNOWN"]},diff_disagreement:{type:"boolean"},robot_activity_verdict:{type:"string"}}}'; }
activity_state(){ local raw; raw="$(jq -r --arg p "$PANE" 'if ((.agents//[])|type)=="array" then ([(.agents//[])[]?|select(((.pane_idx//.pane)//"")|tostring==$p)|.state][0] // ((.agents//[])[0].state? // "UNKNOWN")) else "UNKNOWN" end' 2>/dev/null <<<"${1:-{}}" || printf UNKNOWN)"; raw="${raw%%$'\n'*}"; raw="$(printf '%s' "$raw" | tr '[:lower:]' '[:upper:]')"; case "$raw" in GENERATING) echo THINKING;; WAITING|THINKING|ERROR) echo "$raw";; *) echo UNKNOWN;; esac; }
classify_text(){ local v=UNKNOWN line; while IFS= read -r line || [[ -n "$line" ]]; do
  if grep -Eq 'panic|SIGKILL|segmentation fault|fatal|process exited' <<<"$line"; then v=ERROR; continue; fi
  if grep -Eq 'failed_text|api_error|Traceback|Exception|ERROR|failed|error:' <<<"$line"; then v=ERROR; fi
  if grep -Eq 'Working \(|esc to interrupt|Waiting for background terminal|tool_call|exec_command|apply_patch' <<<"$line"; then v=THINKING; fi
  if grep -Eq '(❯|›)[[:space:]]*$|codex_chevron_prompt|bypass permissions|^>[[:space:]]*$' <<<"$line"; then v=WAITING; fi
done <<<"$1"; printf '%s\n' "$v"; }
collect_diff_text(){
  local diff="${RECENCY_CLASSIFIER_DIFF_JSON:-}"
  if [[ -z "$diff" && -n "$SESSION" && -n "$PANE" && -x "$NTM" ]]; then
    [[ -n "$PEER" ]] || { [[ "$PANE" == "1" ]] && PEER=2 || PEER=1; }
    diff="$($NTM diff "$SESSION" "$PANE" "$PEER" --json 2>/dev/null || true)"
  fi
  jq -r '..|strings?' 2>/dev/null <<<"$diff" || true
}
collect_tail_text(){
  if [[ -n "$SESSION" && -n "$PANE" && -x "$NTM" ]]; then
    $NTM "--robot-tail=$SESSION" "--panes=$PANE" "--lines=$LINES" 2>/dev/null | jq -r --arg p "$PANE" '(.panes[$p].lines//.panes[($p|tostring)].lines//[])[]?' 2>/dev/null || true
  else cat; fi
}
run(){
  [[ "$LINES" =~ ^[0-9]+$ && "$LINES" -gt 0 ]] || { echo "invalid --lines" >&2; exit 2; }
  local diff_text tail_text text activity av bv verdict disagree=false
  diff_text="$(collect_diff_text)"; tail_text="$(collect_tail_text)"; text="${diff_text:-$tail_text}"
  activity="${RECENCY_CLASSIFIER_ACTIVITY_JSON:-}"; [[ -n "$activity" || -z "$SESSION" || ! -x "$NTM" ]] || activity="$($NTM "--robot-activity=$SESSION" "--panes=$PANE" --json 2>/dev/null || true)"
  av="$(activity_state "${activity:-{}}")"; bv="$(classify_text "$text")"; verdict="$bv"
  [[ "$bv" == "UNKNOWN" && "$av" != "UNKNOWN" ]] && verdict="$av"
  [[ "$bv" != "UNKNOWN" && "$av" != "UNKNOWN" && "$bv" != "$av" ]] && disagree=true
  if [[ "$JSON" -eq 1 ]]; then jq -nc --arg v "$verdict" --arg b "$bv" --arg a "$av" --argjson d "$disagree" --argjson lc "$(wc -l <<<"$text" | tr -d ' ')" '{schema_version:"recency-weighted-two-truth-classifier/v2",verdict:$v,diff_verdict:$b,robot_activity_verdict:$a,diff_disagreement:$d,line_count:$lc,native_surface:["ntm diff --json","ntm --robot-activity --json"]}'; else printf '%s\n' "$verdict"; fi
}
while [[ $# -gt 0 ]]; do case "$1" in
  --info|--doctor|--health|--validate|--audit|--why|--repair) MODE=info; shift;; --schema) MODE=schema; shift;; --check) MODE=check; shift;; --json) JSON=1; shift;; --session) SESSION="${2:?}"; shift 2;; --session=*) SESSION="${1#*=}"; shift;; --pane) PANE="${2:?}"; shift 2;; --pane=*) PANE="${1#*=}"; shift;; --peer-pane) PEER="${2:?}"; shift 2;; --peer-pane=*) PEER="${1#*=}"; shift;; --lines) LINES="${2:?}"; shift 2;; --lines=*) LINES="${1#*=}"; shift;; --dry-run|--explain) shift;; -h|--help) usage; exit 0;; *) echo "invalid arg: $1" >&2; usage >&2; exit 2;; esac; done
case "$MODE" in info) info;; schema) schema;; check) out="$(printf 'ERROR failed_text old\napi_error old\n❯ \n' | "$0" --json)"; jq -e '.verdict=="WAITING"' >/dev/null <<<"$out"; [[ "$JSON" -eq 1 ]] && jq -nc '{status:"pass"}' || echo pass;; classify) run;; esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
