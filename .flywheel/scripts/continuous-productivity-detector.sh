#!/usr/bin/env bash
set -euo pipefail
python3 - "$@" <<'PY'
import argparse
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
SCHEMA = "continuous-productivity-detector/v1"
MEMORY = "/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_flywheel_owns_continuous_productivity_no_downtime_unless_josh_blocker.md"
DEFAULT_TOPOLOGY = Path.home() / ".local/state/flywheel/session-topology.jsonl"
DEFAULT_LOOPS = Path.home() / ".flywheel/loops"
DEFAULT_NTM = "/Users/josh/.local/bin/ntm"
ALLOWLIST = {
    "substrate-corrupt": ("substrate-corrupt", "substrate corruption", "substrate_corrupt", "corrupt-substrate"),
    "security": ("security", "secret exposure", "credential leak", "access token"),
    "phi": ("phi", "hipaa", "protected health"),
    "paradigm": ("paradigm", "mental model", "founder decision"),
    "destructive": ("destructive", "delete production", "drop database", "destroy"),
}
def parse_args():
    p = argparse.ArgumentParser(description="Detect peer orchestrator idle-with-work productivity breaches.")
    p.add_argument("--info", action="store_true")
    p.add_argument("--examples", action="store_true")
    p.add_argument("--json", action="store_true")
    p.add_argument("--quiet", action="store_true")
    p.add_argument("--session")
    p.add_argument("--include-self", action="store_true")
    p.add_argument("--threshold-seconds", type=int, default=int(os.environ.get("CPD_THRESHOLD_SECONDS", "300")))
    p.add_argument("--now-epoch", type=float, default=float(os.environ.get("CPD_NOW_EPOCH", time.time())))
    p.add_argument("--topology", default=os.environ.get("CPD_TOPOLOGY", str(DEFAULT_TOPOLOGY)))
    p.add_argument("--loops-dir", default=os.environ.get("CPD_LOOPS_DIR", str(DEFAULT_LOOPS)))
    p.add_argument("--activity-dir", default=os.environ.get("CPD_ACTIVITY_DIR"))
    p.add_argument("--ready-dir", default=os.environ.get("CPD_READY_DIR"))
    p.add_argument("--doctor-dir", default=os.environ.get("CPD_DOCTOR_DIR"))
    p.add_argument("--ntm", default=os.environ.get("CPD_NTM", DEFAULT_NTM))
    p.add_argument("--activity-timeout", type=int, default=int(os.environ.get("CPD_ACTIVITY_TIMEOUT", "5")))
    return p.parse_args()
def info():
    return {
        "schema_version": SCHEMA,
        "name": "continuous-productivity-detector.sh",
        "purpose": "Detect peer orchestrators idle past threshold while workers wait and findings exist.",
        "canonical_cli": ["--info", "--help", "--examples", "--json", "--quiet"],
        "exit_codes": {"0": "no-escalation-needed", "1": "escalation-emitted", "2": "malformed-state", "3": "probe-error"},
        "read_only": True,
        "peer_repo_writes": False,
        "joshua_notify_allowlist": sorted(ALLOWLIST),
        "memory": MEMORY,
    }
def examples():
    return {
        "examples": [
            "continuous-productivity-detector.sh --json",
            "continuous-productivity-detector.sh --session skillos --json",
            "CPD_ACTIVITY_DIR=/tmp/activity continuous-productivity-detector.sh --topology /tmp/topology.jsonl --json",
        ]
    }
def load_json(path, default, errors):
    try:
        with Path(path).open(encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return default
    except Exception as exc:
        errors.append(f"json:{path}:{exc}")
        return default
def load_jsonl(path, errors):
    rows = []
    try:
        with Path(path).open(encoding="utf-8") as f:
            for line_no, line in enumerate(f, 1):
                line = line.strip()
                if not line:
                    continue
                try:
                    row = json.loads(line)
                    row["__line"] = line_no
                    rows.append(row)
                except Exception as exc:
                    errors.append(f"jsonl:{path}:{line_no}:{exc}")
    except FileNotFoundError:
        return rows
    return rows
def latest_by_session(rows):
    latest = {}
    for row in rows:
        session = row.get("session")
        if not session:
            continue
        prev = latest.get(session)
        if prev is None or str(row.get("effective_at", "")) >= str(prev.get("effective_at", "")):
            latest[session] = row
    return latest
def loops(loops_dir, errors):
    out = {}
    path = Path(loops_dir)
    if not path.exists():
        return out
    for item in sorted(path.glob("*.json")):
        row = load_json(item, {}, errors)
        if row.get("active") is False:
            continue
        session = row.get("session") or item.stem
        out[session] = row
    return out
def fixture_json(dir_path, session, default, errors):
    if not dir_path:
        return None
    return load_json(Path(dir_path) / f"{session}.json", default, errors)
def run_json(cmd, default, timeout, probe_errors):
    try:
        out = subprocess.check_output(cmd, stderr=subprocess.PIPE, text=True, timeout=timeout)
        return json.loads(out)
    except Exception as exc:
        probe_errors.append(f"probe:{' '.join(cmd)}:{exc}")
        return default
def activity(session, args, probe_errors, parse_errors):
    fixture = fixture_json(args.activity_dir, session, {"agents": []}, parse_errors)
    if fixture is not None:
        return fixture
    return run_json([args.ntm, f"--robot-activity={session}", "--activity-type=codex,claude"], {"agents": []}, args.activity_timeout, probe_errors)
def ready_rows(session, repo, args, parse_errors):
    fixture = fixture_json(args.ready_dir, session, [], parse_errors)
    if fixture is not None:
        return fixture if isinstance(fixture, list) else fixture.get("ready", [])
    if not repo or not Path(repo).is_dir():
        return []
    try:
        out = subprocess.check_output(["bash", "-lc", f"cd {json.dumps(repo)} && br ready --json"], stderr=subprocess.DEVNULL, text=True, timeout=5)
        return json.loads(out)
    except Exception:
        return []
def doctor(session, args, parse_errors):
    fixture = fixture_json(args.doctor_dir, session, {}, parse_errors)
    return fixture if fixture is not None else {}
def intish(value, default=0):
    try:
        return int(value)
    except Exception:
        return default
def age_seconds(agent, now_epoch):
    for key in ("state_since_epoch", "waiting_since_epoch"):
        value = agent.get(key)
        if isinstance(value, (int, float)):
            return max(0, int(now_epoch - value))
    for key in ("state_since", "state_since_iso"):
        raw = agent.get(key)
        if isinstance(raw, str):
            try:
                dt = datetime.fromisoformat(raw.replace("Z", "+00:00"))
                if dt.tzinfo is None:
                    dt = dt.replace(tzinfo=timezone.utc)
                return max(0, int(now_epoch - dt.timestamp()))
            except Exception:
                pass
    return intish(agent.get("idle_seconds") or agent.get("wait_seconds") or 0)
def source_rows(doc, ready):
    sources = []
    if isinstance(ready, list) and ready:
        sources.append({"source": "unprocessed ready beads", "count": len(ready), "examples": labels(ready)})
    errors = doc.get("errors") if isinstance(doc.get("errors"), list) else []
    if errors:
        sources.append({"source": "doctor errors[]", "count": len(errors), "examples": labels(errors)})
    triage = doc.get("fuckup_triage") if isinstance(doc.get("fuckup_triage"), dict) else {}
    candidates = triage.get("candidates") or triage.get("promotion_ready") or []
    if isinstance(candidates, list) and candidates:
        sources.append({"source": "fuckup_triage candidates", "count": len(candidates), "examples": labels(candidates)})
    closed = intish(doc.get("closed_bead_audit_pending_count") or doc.get("audit_findings_count") or 0)
    if closed:
        sources.append({"source": "audit findings pending", "count": closed, "examples": ["closed-bead/audit findings"]})
    incidents = intish(doc.get("incidents_unprocessed_count") or 0)
    if incidents:
        sources.append({"source": "INCIDENTS.md unprocessed events", "count": incidents, "examples": ["incident promotion backlog"]})
    return sources
def labels(rows):
    out = []
    for row in rows[:3]:
        if isinstance(row, dict):
            out.append(str(row.get("id") or row.get("code") or row.get("trauma_class") or row.get("title") or row)[:100])
        else:
            out.append(str(row)[:100])
    return out
def allowlisted_class(doc):
    text = json.dumps(doc, sort_keys=True).lower()
    for klass, needles in ALLOWLIST.items():
        if any(needle in text for needle in needles):
            return klass
    return None
def escalation_message(session, pane, sources):
    instructions = []
    for idx, src in enumerate(sources[:3], 1):
        example = ", ".join(src["examples"]) or src["source"]
        instructions.append(f"{idx}. File or dispatch a bead from {src['source']}: {example}.")
    while len(instructions) < 3:
        instructions.append(f"{len(instructions)+1}. Confirm the next findings source is empty or convert it to a bead.")
    return "\n".join([
        f"PRODUCTIVITY_ESCALATION session={session} target_pane={pane}",
        "peer-orch idle >5m + workers WAITING + findings non-empty",
        "Flywheel owns continuous productivity; this is an xpane escalation, not a Joshua notification.",
        *instructions[:3],
        f"evidence_memory={MEMORY}",
    ])
def classify(session, topo, loop, act, ready, doc, args):
    orch_pane = intish(topo.get("orchestrator_pane") or loop.get("orchestrator_pane") or 1, 1)
    worker_panes = {intish(p) for p in (topo.get("worker_panes") or loop.get("worker_panes") or []) if intish(p)}
    agents = act.get("agents") if isinstance(act.get("agents"), list) else []
    orch = next((a for a in agents if intish(a.get("pane_idx") or a.get("pane")) == orch_pane), {})
    workers = [a for a in agents if intish(a.get("pane_idx") or a.get("pane")) in worker_panes] if worker_panes else [a for a in agents if intish(a.get("pane_idx") or a.get("pane")) >= 2]
    orch_state = str(orch.get("state") or "UNKNOWN").upper()
    orch_age = age_seconds(orch, args.now_epoch) if orch else 0
    waiting_workers = [w for w in workers if str(w.get("state", "")).upper() == "WAITING"]
    active_workers = [w for w in workers if str(w.get("state", "")).upper() in {"THINKING", "WORKING", "GENERATING"}]
    sources = source_rows(doc, ready)
    notify_class = allowlisted_class(doc)
    idle_trip = orch_state == "WAITING" and orch_age >= args.threshold_seconds
    actions = []
    state = "productive"
    if notify_class:
        state = "josh_notify_allowlisted"
        actions.append({"type": "josh_notify", "session": session, "target": "joshua", "allowlist_class": notify_class})
    elif idle_trip and waiting_workers and sources:
        state = "idle_with_work_available"
        actions.append({"type": "xpane_productivity_escalation", "session": session, "target_pane": orch_pane, "message": escalation_message(session, orch_pane, sources)})
    return {
        "session": session,
        "repo": loop.get("repo") or topo.get("repo") or topo.get("project_key") or "",
        "orchestrator_pane": orch_pane,
        "worker_panes": sorted(worker_panes),
        "orchestrator_state": orch_state,
        "orchestrator_idle_age_seconds": orch_age,
        "workers_waiting": len(waiting_workers),
        "workers_active": len(active_workers),
        "findings_count": sum(s["count"] for s in sources),
        "findings_sources": sources,
        "productivity_state": state,
        "planned_actions": actions,
    }
def make_report(args):
    parse_errors = []
    probe_errors = []
    topo_latest = latest_by_session(load_jsonl(args.topology, parse_errors))
    loop_rows = loops(args.loops_dir, parse_errors)
    sessions = sorted(set(topo_latest) | set(loop_rows))
    if args.session:
        sessions = [s for s in sessions if s == args.session]
    if not args.include_self:
        sessions = [s for s in sessions if s != "flywheel"]
    rows = []
    for session in sessions:
        topo = topo_latest.get(session, {})
        loop = loop_rows.get(session, {})
        repo = loop.get("repo") or topo.get("repo") or topo.get("project_key") or ""
        act = activity(session, args, probe_errors, parse_errors)
        ready = ready_rows(session, repo, args, parse_errors)
        doc = doctor(session, args, parse_errors)
        rows.append(classify(session, topo, loop, act, ready, doc, args))
    action_count = sum(len(r["planned_actions"]) for r in rows)
    return {
        "success": not parse_errors and not probe_errors,
        "schema_version": SCHEMA,
        "checked_at": datetime.fromtimestamp(args.now_epoch, timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "threshold_seconds": args.threshold_seconds,
        "memory": MEMORY,
        "sessions_checked": len(rows),
        "idle_with_work_available_count": sum(1 for r in rows if r["productivity_state"] == "idle_with_work_available"),
        "josh_notify_allowlisted_count": sum(1 for r in rows if r["productivity_state"] == "josh_notify_allowlisted"),
        "action_required_count": action_count,
        "sessions": rows,
        "parse_errors": parse_errors,
        "probe_errors": probe_errors,
    }
def main():
    args = parse_args()
    if args.info:
        print(json.dumps(info(), sort_keys=True) if args.json else "\n".join(f"{k}: {v}" for k, v in info().items()))
        return 0
    if args.examples:
        print(json.dumps(examples(), sort_keys=True) if args.json else "\n".join(examples()["examples"]))
        return 0
    report = make_report(args)
    if args.json or not args.quiet:
        print(json.dumps(report, sort_keys=True) if args.json else f"action_required={report['action_required_count']} sessions={report['sessions_checked']}")
    if report["parse_errors"]:
        return 2
    if report["probe_errors"] and report["sessions_checked"] == 0:
        return 3
    return 1 if report["action_required_count"] else 0
if __name__ == "__main__":
    raise SystemExit(main())
PY
