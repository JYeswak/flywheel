#!/usr/bin/env bash
# Meta-pattern Adoption stance:
# Embodies MP-20-cross-orch-handoff.md and MP-75-actionable-slo-burn-alert-contract.md.
# Source: /Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/
set -euo pipefail

VERSION="peer-orch-blocker-watch/v2"
NTM_BIN="${PEER_ORCH_BLOCKER_WATCH_NTM_BIN:-${NTM_BIN:-/Users/josh/.local/bin/ntm}}"
SESSION="${PEER_ORCH_BLOCKER_WATCH_SESSION:-flywheel}"
THRESHOLD_SECONDS="${FLYWHEEL_PEER_ORCH_BLOCKER_THRESHOLD_SECONDS:-300}"
LEDGER="${FLYWHEEL_CROSS_ORCH_COORDINATION_LEDGER:-}"
NOW="${FLYWHEEL_PEER_ORCH_BLOCKER_NOW:-}"
MODE="doctor"; JSON=0; DRY_RUN=1

usage() {
  cat <<'USAGE'
Usage: peer-orch-blocker-watch.sh [--doctor|--validate|--schema|--examples|--info|--capabilities] [--json] [--session NAME] [--dry-run] [--apply]
Native sources: ntm swarm status --json; ntm rebalance <session> --dry-run --format json.

Agent automation:
  peer-orch-blocker-watch.sh --capabilities --json
  peer-orch-blocker-watch.sh --doctor --json --session flywheel --dry-run
  peer-orch-blocker-watch.sh --validate --json --ledger .flywheel/state/cross-orch-coordination.jsonl
  Exit codes: 0 success, 2 usage error, 127 ntm executable missing.
USAGE
}

schema() {
  jq -nc --arg version "$VERSION" '{schema_version:$version,native_sources:["ntm swarm status --json","ntm rebalance <session> --dry-run --format json"],wrapper_policy:["requested_owner=flywheel:1","threshold_seconds is L75 escalation policy"],output_fields:["status","peer_orch_blocker_age_seconds","stale_blockers_count","stale_blockers","native"]}'
}

capabilities() {
  jq -nc --arg version "$VERSION" '{
    schema_version:$version,
    command:"capabilities",
    contract_version:"1",
    features:["json_output","doctor","validate","dry_run_default","ledger_mode","native_ntm_probe"],
    commands:{
      doctor:{command:"peer-orch-blocker-watch.sh --doctor --json --session flywheel --dry-run",read_only:true},
      validate:{command:"peer-orch-blocker-watch.sh --validate --json --ledger PATH",read_only:true},
      schema:{command:"peer-orch-blocker-watch.sh --schema",read_only:true},
      examples:{command:"peer-orch-blocker-watch.sh --examples",read_only:true}
    },
    exit_codes:{"0":"success","2":"usage error","127":"ntm executable missing"},
    env_vars:{
      PEER_ORCH_BLOCKER_WATCH_NTM_BIN:"override ntm binary",
      PEER_ORCH_BLOCKER_WATCH_SESSION:"default session",
      FLYWHEEL_PEER_ORCH_BLOCKER_THRESHOLD_SECONDS:"stale blocker threshold"
    }
  }'
}

run_ledger_watch() {
  python3 - "$VERSION" "$LEDGER" "$NOW" "$THRESHOLD_SECONDS" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

version, ledger_path, now_raw, threshold_raw = sys.argv[1:5]
threshold = int(threshold_raw)

def parse_ts(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00")).astimezone(timezone.utc)
    except ValueError:
        return None

now = parse_ts(now_raw) or datetime.now(timezone.utc)
rows = []
malformed = 0
try:
    lines = Path(ledger_path).read_text().splitlines()
except FileNotFoundError:
    lines = []

for line_no, line in enumerate(lines, 1):
    if not line.strip():
        continue
    try:
        row = json.loads(line)
    except json.JSONDecodeError:
        malformed += 1
        continue
    if isinstance(row, dict):
        row["__line"] = line_no
        rows.append(row)

ack_pairs = set()
for row in rows:
    sender = row.get("from")
    target = row.get("to")
    event = str(row.get("event") or row.get("type") or row.get("kind") or "")
    if sender == "flywheel:1" or row.get("from_session") == "flywheel":
        if target:
            ack_pairs.add(str(target))
        if row.get("ack_to"):
            ack_pairs.add(str(row.get("ack_to")))
    if event in {"xpane_response", "ack", "caam_substrate_finding_ack", "caam_scope_handshake_ack"} and sender == "flywheel:1" and target:
        ack_pairs.add(str(target))

blockers = []
for row in rows:
    event = str(row.get("event") or row.get("type") or row.get("kind") or "")
    blocker_type = row.get("blocker_type")
    requested_owner = row.get("requested_owner") or row.get("to") or row.get("target")
    legacy_blocker = event.endswith("_blocker_received") or "doctor_error" in row
    is_flywheel = blocker_type == "flywheel_class" or requested_owner == "flywheel:1" or legacy_blocker
    if not is_flywheel:
        continue
    ts = parse_ts(row.get("ts") or row.get("created_at") or row.get("callback_expected_by"))
    if ts is None:
        continue
    sender = row.get("sender") or row.get("from") or row.get("origin_session") or row.get("sister_session") or "unknown"
    acked = str(sender) in ack_pairs
    age = max(0, int((now - ts).total_seconds()))
    blocker = {
        "line": row.get("__line"),
        "ts": row.get("ts"),
        "sender": sender,
        "acked": acked,
        "blocker_type": blocker_type or "flywheel_class",
        "blocker_class": row.get("blocker_class") or row.get("doctor_error") or "unknown",
        "requested_owner": "flywheel:1",
        "age_seconds": age,
        "threshold_seconds": threshold,
        "proposed_action": row.get("proposed_action") or row.get("next_action") or row.get("flywheel_orch_action_required") or "coordinate with flywheel:1",
        "source_event": event,
    }
    blockers.append(blocker)

stale = [b for b in blockers if not b["acked"] and b["age_seconds"] > threshold]
max_age = max((b["age_seconds"] for b in stale), default=0)
status = "fail" if stale else "pass"
if malformed and not stale:
    status = "warn"

print(json.dumps({
    "schema_version": version,
    "status": status,
    "session": "ledger",
    "dry_run": True,
    "threshold_seconds": threshold,
    "ledger": ledger_path,
    "now": now.isoformat().replace("+00:00", "Z"),
    "peer_orch_blocker_age_seconds": max_age,
    "stale_blockers_count": len(stale),
    "malformed_rows_count": malformed,
    "stale_blockers": stale,
    "blockers": blockers,
    "signals": [{
        "name": "peer_orch_blocker_age_seconds",
        "producer": ".flywheel/scripts/peer-orch-blocker-watch.sh --ledger",
        "measurement": "oldest unacked flywheel-class cross-orch blocker age",
        "gate_behavior": "fail when age_seconds exceeds threshold_seconds",
    }],
}, sort_keys=True))
PY
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
    --info|--capabilities|capabilities) MODE="capabilities"; shift ;;
    --json) JSON=1; shift ;;
    --session) SESSION="${2:-}"; shift 2 ;;
    --threshold-seconds) THRESHOLD_SECONDS="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --apply) DRY_RUN=0; shift ;;
    --ledger) LEDGER="${2:-}"; shift 2 ;;
    --now) NOW="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$MODE" in
  schema) schema ;;
  examples) printf 'peer-orch-blocker-watch.sh --doctor --json\npeer-orch-blocker-watch.sh --session flywheel --dry-run --json\n' ;;
  capabilities) capabilities ;;
  doctor|validate)
    if [[ -n "$LEDGER" ]]; then
      result="$(run_ledger_watch)"
    else
      result="$(run_watch)"
    fi
    if [[ "$JSON" -eq 1 ]]; then
      printf '%s\n' "$result"
    else
      jq -r '"status=\(.status) peer_orch_blocker_age_seconds=\(.peer_orch_blocker_age_seconds) stale_blockers_count=\(.stale_blockers_count)"' <<<"$result"
    fi
    [[ "$MODE" == "validate" && -z "$LEDGER" ]] && jq -e '.native.rebalance.json != null' <<<"$result" >/dev/null
    exit 0
    ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
