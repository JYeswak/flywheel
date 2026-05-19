#!/usr/bin/env bash
# integrate-stall-escalator.sh — flywheel-xp50r
#
# N-strikes-then-escalate detector for the integrate-side
# `worker_capacity_gate_failed` trauma class. When the orchestrator's
# INTEGRATE tick aborts repeatedly because a worker pane is in ERROR
# state (rather than WAITING) AFTER a callback was delivered, the
# stalled pane needs the canonical L95 worker-stall recovery path —
# but the integrate-prelude probe historically just re-fired the same
# fuckup-log row instead of escalating.
#
# Filed by flywheel-ovd29 close (MistyCliff, 2026-05-09) per L52.
# Implementation bead flywheel-xp50r.
#
# Pattern: scan recent fuckup-log rows; for each (session, pane) pair,
# count consecutive `worker_capacity_gate_failed` rows where the prose
# matches the ERROR-after-callback sub-shape (Sub-shape B). When count
# >= THRESHOLD, invoke worker-stall-alert-probe.sh --apply and append
# an idempotent escalation receipt.
#
# Stable exit codes: 0 ok | 1 domain | 64 usage
# Triad: doctor / info / schema; --json default for robot consumers.
# Mutation discipline: --dry-run (default) plans, --apply executes.

set -uo pipefail

VERSION="integrate-stall-escalator.v1"
SCRIPT_VERSION="2026-05-09.1"
SCHEMA_VERSION="integrate-stall-escalator/v1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO="${INTEGRATE_STALL_REPO:-$REPO_DEFAULT}"

FUCKUP_LOG="${INTEGRATE_STALL_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
DISPATCH_LOG="${INTEGRATE_STALL_DISPATCH_LOG:-$REPO/.flywheel/dispatch-log.jsonl}"
LEDGER="${INTEGRATE_STALL_LEDGER:-$HOME/.local/state/flywheel/integrate-stall-escalator-ledger.jsonl}"
STALL_PROBE="${INTEGRATE_STALL_PROBE:-$REPO/.flywheel/scripts/worker-stall-alert-probe.sh}"
TRAUMA_CLASS="worker_capacity_gate_failed"
SUB_SHAPE_B_PATTERN="${INTEGRATE_STALL_SUB_B_PATTERN:-robot-activity was ERROR}"
THRESHOLD="${INTEGRATE_STALL_THRESHOLD:-3}"
LOOKBACK_HOURS="${INTEGRATE_STALL_LOOKBACK_HOURS:-12}"

JSON_OUT=0
APPLY=0
DRY_RUN=1
MODE="check"

usage() {
  cat <<'USAGE'
Usage:
  integrate-stall-escalator.sh [--apply|--dry-run] [--json]
  integrate-stall-escalator.sh --doctor [--json]
  integrate-stall-escalator.sh --info [--json]
  integrate-stall-escalator.sh --schema [--json]
  integrate-stall-escalator.sh --examples
  integrate-stall-escalator.sh --help

Detect N consecutive worker_capacity_gate_failed Sub-shape B (ERROR-
after-callback) emissions per (session, pane) and escalate to L95
worker-stall-alert-probe.sh. Default --dry-run plans the escalation
without invoking the probe. --apply invokes worker-stall-alert-probe.sh
--apply for each (session, pane) at threshold.
USAGE
}

examples() {
  cat <<'EXAMPLES'
integrate-stall-escalator.sh --json
integrate-stall-escalator.sh --apply --json
INTEGRATE_STALL_THRESHOLD=2 integrate-stall-escalator.sh --json
INTEGRATE_STALL_FUCKUP_LOG=/tmp/fixture.jsonl integrate-stall-escalator.sh --json
EXAMPLES
}

info_json() {
  jq -nc \
    --arg version "$VERSION" \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg trauma_class "$TRAUMA_CLASS" \
    --arg fuckup_log "$FUCKUP_LOG" \
    --arg dispatch_log "$DISPATCH_LOG" \
    --arg ledger "$LEDGER" \
    --arg stall_probe "$STALL_PROBE" \
    --argjson threshold "$THRESHOLD" \
    --argjson lookback_hours "$LOOKBACK_HOURS" \
    '{
      schema_version: $schema_version,
      version: $version,
      mode: "info",
      success: true,
      trauma_class: $trauma_class,
      sub_shape_filter: "Sub-shape B (ERROR-after-callback)",
      fuckup_log: $fuckup_log,
      dispatch_log: $dispatch_log,
      ledger: $ledger,
      stall_probe: $stall_probe,
      default_threshold: $threshold,
      lookback_hours: $lookback_hours,
      modes: ["check","doctor","info","schema","examples"],
      mutation_default: "dry-run",
      mutation_apply_action: "invoke worker-stall-alert-probe.sh --apply per stalled pane",
      owns: "flywheel-xp50r",
      filed_by: "flywheel-ovd29",
      l_rule_anchor: "L95"
    }'
}

schema_json() {
  jq -nc --arg schema_version "$SCHEMA_VERSION" '{
    "$schema":"https://json-schema.org/draft/2020-12/schema",
    title:"integrate stall escalator decision",
    type:"object",
    required:["schema_version","mode","success","ts","threshold","stalled_panes","escalations_planned","escalations_executed"],
    properties:{
      schema_version:{const:$schema_version},
      mode:{type:"string"},
      success:{type:"boolean"},
      ts:{type:"string"},
      threshold:{type:"integer"},
      lookback_hours:{type:"number"},
      stalled_panes:{type:"array"},
      escalations_planned:{type:"integer"},
      escalations_executed:{type:"integer"},
      apply:{type:"boolean"},
      dry_run:{type:"boolean"}
    }
  }'
}

doctor_json() {
  local issues=()
  command -v jq >/dev/null 2>&1 || issues+=("jq_missing")
  command -v python3 >/dev/null 2>&1 || issues+=("python3_missing")
  [[ -f "$STALL_PROBE" ]] || issues+=("stall_probe_missing=$STALL_PROBE")
  mkdir -p "$(dirname "$LEDGER")" 2>/dev/null
  [[ -w "$(dirname "$LEDGER")" ]] || issues+=("ledger_dir_not_writable=$(dirname "$LEDGER")")
  local issues_json
  if [[ ${#issues[@]} -gt 0 ]]; then
    issues_json=$(printf '%s\n' "${issues[@]}" | jq -R . | jq -s .)
  else
    issues_json='[]'
  fi
  jq -nc \
    --arg schema_version "$SCHEMA_VERSION" \
    --argjson issues "$issues_json" \
    '{
      schema_version: $schema_version,
      mode: "doctor",
      success: (($issues|length) == 0),
      status: (if ($issues|length) == 0 then "ok" else "degraded" end),
      issues: $issues
    }'
}

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

run_check() {
  python3 - "$FUCKUP_LOG" "$LEDGER" "$STALL_PROBE" "$THRESHOLD" "$LOOKBACK_HOURS" "$TRAUMA_CLASS" "$SUB_SHAPE_B_PATTERN" "$APPLY" "$JSON_OUT" "$SCHEMA_VERSION" <<'PY'
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

(fuckup_log, ledger, stall_probe, threshold_str, lookback_str,
 trauma_class, sub_b_pattern, apply_str, json_out_str, schema_version) = sys.argv[1:11]

threshold = int(threshold_str)
lookback_hours = float(lookback_str)
apply = apply_str == "1"
json_out = json_out_str == "1"

now = datetime.now(timezone.utc)
cutoff = now - timedelta(hours=lookback_hours)


def parse_ts(value: str) -> datetime | None:
    if not value:
        return None
    text = value.strip()
    try:
        if text.endswith("Z"):
            text = text[:-1] + "+00:00"
        dt = datetime.fromisoformat(text)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc)
    except ValueError:
        return None


def iso(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def already_escalated(ledger_path: Path, key: str, latest_ts: str) -> bool:
    if not ledger_path.exists():
        return False
    try:
        for line in ledger_path.read_text(errors="replace").splitlines():
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            if row.get("idempotency_key") == key and row.get("latest_event_ts") == latest_ts:
                return True
    except OSError:
        return False
    return False


fuckup_path = Path(fuckup_log)
ledger_path = Path(ledger)
stall_probe_path = Path(stall_probe)

groups: dict[tuple[str, str], list[dict]] = {}
if fuckup_path.exists():
    try:
        text = fuckup_path.read_text(errors="replace")
    except OSError:
        text = ""
    for raw in text.splitlines():
        raw = raw.strip()
        if not raw:
            continue
        try:
            row = json.loads(raw)
        except json.JSONDecodeError:
            continue
        if row.get("trauma_class") != trauma_class:
            continue
        what = row.get("what_happened") or ""
        if sub_b_pattern not in what:
            continue
        ts = parse_ts(row.get("ts") or "")
        if ts is None or ts < cutoff:
            continue
        session = str(row.get("session") or "")
        pane = str(row.get("pane") or "")
        if not session or not pane:
            continue
        groups.setdefault((session, pane), []).append({
            "ts_iso": iso(ts),
            "ts_dt": ts,
            "row": row,
        })

stalled_panes = []
escalations_planned = 0
escalations_executed = 0
new_ledger_rows: list[str] = []

for (session, pane), events in sorted(groups.items()):
    events.sort(key=lambda e: e["ts_dt"])
    count = len(events)
    if count < threshold:
        continue
    latest = events[-1]
    latest_ts = latest["ts_iso"]
    idempotency_key = f"{session}:{pane}:{latest_ts}"

    pane_record = {
        "session": session,
        "pane": pane,
        "consecutive_count": count,
        "first_event_ts": events[0]["ts_iso"],
        "latest_event_ts": latest_ts,
        "idempotency_key": idempotency_key,
        "threshold_met": True,
    }

    if already_escalated(ledger_path, idempotency_key, latest_ts):
        pane_record["already_escalated"] = True
        stalled_panes.append(pane_record)
        continue

    pane_record["already_escalated"] = False
    escalations_planned += 1

    if apply and stall_probe_path.exists():
        try:
            result = subprocess.run(
                [
                    str(stall_probe_path),
                    "--session", session,
                    "--apply",
                    "--json",
                ],
                check=False, capture_output=True, text=True, timeout=60,
            )
            pane_record["stall_probe_exit"] = result.returncode
            pane_record["stall_probe_stdout_head"] = (result.stdout or "")[:500]
            if result.returncode == 0:
                escalations_executed += 1
        except (OSError, subprocess.SubprocessError) as exc:
            pane_record["stall_probe_error"] = str(exc)

    receipt = {
        "schema_version": schema_version,
        "ts": iso(now),
        "mode": "check",
        "session": session,
        "pane": pane,
        "trauma_class": trauma_class,
        "sub_shape_pattern": sub_b_pattern,
        "consecutive_count": count,
        "threshold": threshold,
        "first_event_ts": events[0]["ts_iso"],
        "latest_event_ts": latest_ts,
        "idempotency_key": idempotency_key,
        "applied": apply,
        "executed": pane_record.get("stall_probe_exit") == 0,
    }
    new_ledger_rows.append(json.dumps(receipt))
    stalled_panes.append(pane_record)

if apply and new_ledger_rows:
    try:
        ledger_path.parent.mkdir(parents=True, exist_ok=True)
        with ledger_path.open("a", encoding="utf-8") as fh:
            for line in new_ledger_rows:
                fh.write(line + "\n")
    except OSError as exc:
        print(json.dumps({"warn": f"ledger_write_failed: {exc}"}), file=sys.stderr)

output = {
    "schema_version": schema_version,
    "mode": "check",
    "success": True,
    "ts": iso(now),
    "threshold": threshold,
    "lookback_hours": lookback_hours,
    "stalled_panes": stalled_panes,
    "escalations_planned": escalations_planned,
    "escalations_executed": escalations_executed,
    "apply": apply,
    "dry_run": not apply,
}
print(json.dumps(output))
PY
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --dry-run) DRY_RUN=1; APPLY=0; shift ;;
    --doctor|doctor) MODE="doctor"; shift ;;
    --info|info) MODE="info"; shift ;;
    --schema|schema) MODE="schema"; shift ;;
    --examples|examples) MODE="examples"; shift ;;
    --threshold) THRESHOLD="${2:?--threshold needs value}"; shift 2 ;;
    --threshold=*) THRESHOLD="${1#--threshold=}"; shift ;;
    --lookback-hours) LOOKBACK_HOURS="${2:?--lookback-hours needs value}"; shift 2 ;;
    --lookback-hours=*) LOOKBACK_HOURS="${1#--lookback-hours=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'integrate-stall-escalator.sh: unknown arg: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

case "$MODE" in
  info) info_json ;;
  schema) schema_json ;;
  doctor)
    payload="$(doctor_json)"
    printf '%s\n' "$payload"
    [[ "$(printf '%s' "$payload" | jq -r .status)" == "ok" ]] && exit 0 || exit 1
    ;;
  examples) examples ;;
  check) run_check ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
