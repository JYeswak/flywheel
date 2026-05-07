#!/usr/bin/env bash
set -euo pipefail

VERSION="peer-orch-blocker-watch/v2"
NTM_BIN="${PEER_ORCH_BLOCKER_WATCH_NTM_BIN:-${NTM_BIN:-/Users/josh/.local/bin/ntm}}"
SESSION="${PEER_ORCH_BLOCKER_WATCH_SESSION:-flywheel}"
THRESHOLD_SECONDS="${FLYWHEEL_PEER_ORCH_BLOCKER_THRESHOLD_SECONDS:-300}"
MODE="doctor"; JSON=0; DRY_RUN=1

usage() {
  cat <<'USAGE'
Usage: peer-orch-blocker-watch.sh [--doctor|--validate|--schema|--examples] [--json] [--session NAME] [--dry-run] [--apply]
Native sources: ntm swarm status --json; ntm rebalance <session> --dry-run --format json.
USAGE
}

schema() {
  jq -nc --arg version "$VERSION" '{schema_version:$version,native_sources:["ntm swarm status --json","ntm rebalance <session> --dry-run --format json"],wrapper_policy:["requested_owner=flywheel:1","threshold_seconds is L75 escalation policy"],output_fields:["status","peer_orch_blocker_age_seconds","stale_blockers_count","stale_blockers","native"]}'
}

json_or_envelope() {
  local source="$1" out err rc
  shift
  out="$(mktemp)"; err="$(mktemp)"
  set +e; "$@" >"$out" 2>"$err"; rc=$?; set -e
  if jq -e . "$out" >/dev/null 2>&1; then
    jq -c --arg source "$source" --argjson rc "$rc" '{source:$source,exit_code:$rc,ok:($rc==0),json:.}' "$out"
  else
    jq -nc --arg source "$source" --argjson rc "$rc" --arg stdout "$(head -c 4000 "$out")" --arg stderr "$(head -c 2000 "$err")" '{source:$source,exit_code:$rc,ok:false,json:null,stdout:$stdout,stderr:$stderr}'
  fi
  rm -f "$out" "$err"
}

run_watch() {
  [[ -x "$NTM_BIN" ]] || { jq -nc --arg version "$VERSION" --arg ntm "$NTM_BIN" '{schema_version:$version,status:"fail",error:"ntm_not_executable",ntm_bin:$ntm}'; return 127; }
  local swarm rebalance count status
  swarm="$(json_or_envelope "ntm swarm status --json" "$NTM_BIN" swarm status --json)"
  rebalance="$(json_or_envelope "ntm rebalance --dry-run --format json" "$NTM_BIN" rebalance "$SESSION" --dry-run --format json)"
  count="$(jq '[.json.transfers[]?] | length' <<<"$rebalance")"
  status="pass"; [[ "$count" -gt 0 ]] && status="fail"; [[ "$(jq -r '.ok' <<<"$rebalance")" != "true" ]] && status="warn"
  jq -nc --arg version "$VERSION" --arg session "$SESSION" --arg status "$status" --argjson dry "$DRY_RUN" --argjson threshold "$THRESHOLD_SECONDS" --argjson swarm "$swarm" --argjson rebalance "$rebalance" '
    ($rebalance.json.transfers // []) as $transfers
    | {
      schema_version:$version,status:$status,session:$session,dry_run:$dry,threshold_seconds:$threshold,
      native:{swarm:$swarm,rebalance:$rebalance},
      peer_orch_blocker_age_seconds:(if ($transfers|length)>0 then $threshold else 0 end),
      stale_blockers_count:($transfers|length),
      stale_blockers:($transfers|map({blocker_type:"flywheel_class",blocker_class:"peer_swarm_rebalance_recommended",requested_owner:"flywheel:1",peer:(.to_agent//.to_pane//"unknown"|tostring),age_seconds:$threshold,threshold_seconds:$threshold,proposed_action:"rebalance peer orchestrator workload",native_transfer:.})),
      blockers:($transfers|map({acked:false,blocker_type:"flywheel_class",blocker_class:"peer_swarm_rebalance_recommended",requested_owner:"flywheel:1",native_transfer:.})),
      signals:[{name:"peer_orch_blocker_age_seconds",producer:"ntm swarm/rebalance JSON via .flywheel/scripts/peer-orch-blocker-watch.sh",measurement:"wrapper policy projection from native rebalance recommendations",gate_behavior:"fail when native rebalance transfers are recommended"}]
    }'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --doctor) MODE="doctor"; shift ;;
    --validate) MODE="validate"; shift ;;
    --schema) MODE="schema"; shift ;;
    --examples) MODE="examples"; shift ;;
    --json) JSON=1; shift ;;
    --session) SESSION="${2:-}"; shift 2 ;;
    --threshold-seconds) THRESHOLD_SECONDS="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --apply) DRY_RUN=0; shift ;;
    --ledger|--now) shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$MODE" in
  schema) schema ;;
  examples) printf 'peer-orch-blocker-watch.sh --doctor --json\npeer-orch-blocker-watch.sh --session flywheel --dry-run --json\n' ;;
  doctor|validate)
    result="$(run_watch)"
    [[ "$JSON" -eq 1 ]] && printf '%s\n' "$result" || jq -r '"status=\(.status) peer_orch_blocker_age_seconds=\(.peer_orch_blocker_age_seconds) stale_blockers_count=\(.stale_blockers_count)"' <<<"$result"
    [[ "$MODE" == "validate" ]] && jq -e '.native.rebalance.json != null' <<<"$result" >/dev/null
    exit 0
    ;;
esac
