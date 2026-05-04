#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
import argparse
import json
import os
import re
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from pathlib import Path

VERSION = "peer-orch-productivity-watch/v1"
MEMORY_PATH = "/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_flywheel_owns_continuous_productivity_no_downtime_unless_josh_blocker.md"
DEFAULT_LOOPS_DIR = Path.home() / ".flywheel" / "loops"
DEFAULT_TOPOLOGY = Path.home() / ".local/state/flywheel/session-topology.jsonl"
DEFAULT_LEDGER = Path.home() / ".local/state/flywheel/productivity-escalations.jsonl"
DEFAULT_LAST_TICK_DIR = Path.home() / ".local/state/flywheel-loop"
DEFAULT_NTM = "/Users/josh/.local/bin/ntm"
WORK_THRESHOLD_SECONDS = int(os.environ.get("FLYWHEEL_PRODUCTIVITY_THRESHOLD_SECONDS", "300"))

WORK_HIERARCHY = [
    "Doctor errors[] -> fix-bead per error",
    "fuckup_triage candidates -> promotion-bead",
    "closed_bead_audit_pending -> reopen-or-close evaluation bead",
    "canonical_drift / fleet_repo_l_rule_lag -> backfill-bead",
    "Recent commits without README/AGENTS.md update (L61) -> ecosystem-touch bead",
    "INCIDENTS.md unprocessed events -> promotion bead",
    "Skill citation graph gaps -> audit bead",
    "Gap-hunt-probe findings -> structural-fix bead",
    "Mission-anchor doctrine drift -> mission-lock refresh bead",
]

TRUE_JOSH_RE = re.compile(
    r"(true[_ -]?josh[_ -]?blocker|owner[=: ]joshua|requires? joshua|joshua action|required.*josh|security decision|phi decision|destructive op)",
    re.I,
)
SUBSTRATE_RE = re.compile(
    r"(substrate|corrupt|beads_db|agent.?mail|identity|canonical|doctor|storage|driver|token|credential|sqlite|db health|launchd)",
    re.I,
)


def iso_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def load_json(path: Path, default):
    try:
        with path.open() as f:
            return json.load(f)
    except Exception:
        return default


def load_jsonl(path: Path):
    rows = []
    if not path.exists():
        return rows
    with path.open() as f:
        for line_no, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
                row["__line"] = line_no
                rows.append(row)
            except Exception:
                continue
    return rows


def latest_topology(rows, session):
    matches = [r for r in rows if r.get("session") == session]
    if not matches:
        return {}
    return sorted(matches, key=lambda r: str(r.get("effective_at", "")))[-1]


def run_json(cmd, default, timeout=8):
    try:
        out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, text=True, timeout=timeout)
        return json.loads(out)
    except Exception:
        return default


def run_text(cmd, timeout=5):
    try:
        return subprocess.check_output(cmd, stderr=subprocess.DEVNULL, text=True, timeout=timeout)
    except Exception:
        return ""


def fixture_json(dir_path, session, default):
    if not dir_path:
        return None
    path = Path(dir_path) / f"{session}.json"
    if path.exists():
        return load_json(path, default)
    return None


def fixture_text(dir_path, session):
    if not dir_path:
        return None
    path = Path(dir_path) / f"{session}.txt"
    if path.exists():
        try:
            return path.read_text()
        except Exception:
            return ""
    return None


def loop_sessions(loops_dir: Path, wanted_session: str | None, fleet: bool):
    sessions = []
    for path in sorted(loops_dir.glob("*.json")):
        data = load_json(path, {})
        if data.get("active") is False:
            continue
        session = data.get("session") or path.stem
        if wanted_session and session != wanted_session:
            continue
        if not fleet and wanted_session is None and session != "flywheel":
            continue
        sessions.append((session, data, path))
    return sessions


def ready_rows(repo: str, session: str, ready_dir: str | None, timeout: int):
    fixture = fixture_json(ready_dir, session, [])
    if fixture is not None:
        return fixture if isinstance(fixture, list) else fixture.get("ready", [])
    if not repo or not Path(repo).is_dir():
        return []
    return run_json(["bash", "-lc", f"cd {json.dumps(repo)} && br ready --json"], [], timeout=timeout)


def activity_json(session: str, activity_dir: str | None, ntm: str, timeout: int):
    fixture = fixture_json(activity_dir, session, {"agents": []})
    if fixture is not None:
        return fixture
    return run_json([ntm, f"--robot-activity={session}", "--activity-type=codex,claude"], {"agents": []}, timeout=timeout)


def capture_tail(session: str, pane: int, capture_dir: str | None, ntm: str, timeout: int):
    fixture = fixture_text(capture_dir, session)
    if fixture is not None:
        return fixture
    return run_text([ntm, "copy", f"{session}:{pane}", "-l", "120"], timeout=timeout)


def doctor_json(session: str, doctor_dir: str | None, last_tick_dir: Path):
    fixture = fixture_json(doctor_dir, session, {})
    if fixture is not None:
        return fixture
    for name in (f"last_tick_{session}.json", f"{session}.json"):
        path = last_tick_dir / name
        if path.exists():
            return load_json(path, {})
    return {}


def flatten_text(value) -> str:
    try:
        return json.dumps(value, sort_keys=True)
    except Exception:
        return str(value)


def source_rows(doc: dict, ready: list):
    sources = []
    errors = doc.get("errors") if isinstance(doc.get("errors"), list) else []
    if errors:
        sources.append({"rank": 1, "source": WORK_HIERARCHY[0], "count": len(errors), "examples": [error_label(e) for e in errors[:3]]})

    triage = doc.get("fuckup_triage") if isinstance(doc.get("fuckup_triage"), dict) else {}
    triage_rows = triage.get("candidates") or triage.get("rows") or triage.get("promotion_ready") or []
    if isinstance(triage_rows, list) and triage_rows:
        sources.append({"rank": 2, "source": WORK_HIERARCHY[1], "count": len(triage_rows), "examples": [row_label(r) for r in triage_rows[:3]]})

    closed_pending = intish(doc.get("closed_bead_audit_pending_count") or nested(doc, "closed_bead_audit", "pending_count") or 0)
    if closed_pending > 0:
        sources.append({"rank": 3, "source": WORK_HIERARCHY[2], "count": closed_pending, "examples": ["closed bead audit queue"]})

    drift_count = 0
    drift_examples = []
    if nested(doc, "canonical_root_drift", "drift") is True or doc.get("canonical_drift") is True:
        drift_count += 1
        drift_examples.append("canonical_drift")
    for key in ("fleet_repo_l_rule_lag_count", "doctrine_3_surface_divergent_count"):
        n = intish(doc.get(key) or 0)
        if n:
            drift_count += n
            drift_examples.append(f"{key}={n}")
    if drift_count:
        sources.append({"rank": 4, "source": WORK_HIERARCHY[3], "count": drift_count, "examples": drift_examples[:3]})

    ecosystem = 0
    ecosystem_examples = []
    for key in ("surfaces_unwired_count", "callback_surfaces_unwired_count", "three_q_surfaces_unwired_count"):
        n = intish(doc.get(key) or 0)
        if n:
            ecosystem += n
            ecosystem_examples.append(f"{key}={n}")
    if ecosystem:
        sources.append({"rank": 5, "source": WORK_HIERARCHY[4], "count": ecosystem, "examples": ecosystem_examples[:3]})

    incidents = intish(doc.get("incidents_unprocessed_count") or nested(doc, "incidents", "unprocessed_count") or 0)
    if incidents:
        sources.append({"rank": 6, "source": WORK_HIERARCHY[5], "count": incidents, "examples": ["INCIDENTS.md unprocessed events"]})

    skill_gaps = intish(doc.get("skill_citation_graph_gap_count") or nested(doc, "skill_citation_graph", "gap_count") or 0)
    if skill_gaps:
        sources.append({"rank": 7, "source": WORK_HIERARCHY[6], "count": skill_gaps, "examples": ["skill citation graph gaps"]})

    gap_hunt = intish(doc.get("gap_hunt_findings_count") or nested(doc, "gap_hunt", "findings_count") or nested(doc, "gap_hunt", "known_count") or 0)
    if gap_hunt:
        sources.append({"rank": 8, "source": WORK_HIERARCHY[7], "count": gap_hunt, "examples": ["gap-hunt-probe findings"]})

    mission_state = str(nested(doc, "mission_anchor", "state") or nested(doc, "mission_anchor", "status") or doc.get("mission_anchor_status") or "")
    if mission_state and mission_state not in {"ready", "locked", "ok", "pass", "green"}:
        sources.append({"rank": 9, "source": WORK_HIERARCHY[8], "count": 1, "examples": [f"mission_anchor={mission_state}"]})

    ready_work = [r for r in ready if not re.search(r"(^|[^a-z])epic[- ]|meta-?epic", str(r.get("title") or r.get("description") or ""), re.I)]
    if ready_work:
        sources.append({"rank": 0, "source": "Ready beads already exist -> dispatch existing bead", "count": len(ready_work), "examples": [str(r.get("id") or r.get("title") or "ready") for r in ready_work[:3]]})

    return sorted(sources, key=lambda r: r["rank"])


def nested(obj, *keys):
    cur = obj
    for key in keys:
        if not isinstance(cur, dict):
            return None
        cur = cur.get(key)
    return cur


def intish(value):
    try:
        return int(value)
    except Exception:
        return 0


def row_label(row):
    if isinstance(row, dict):
        return str(row.get("trauma_class") or row.get("class") or row.get("code") or row.get("id") or row)[:120]
    return str(row)[:120]


def error_label(row):
    if isinstance(row, dict):
        return str(row.get("code") or row.get("message") or row.get("reason") or row)[:120]
    return str(row)[:120]


def classify(session, repo, topology, loop, activity, ready, doc, tail, now_epoch):
    orch_pane = intish(topology.get("orchestrator_pane") or loop.get("orchestrator_pane") or 1) or 1
    topology_workers = topology.get("worker_panes") or loop.get("worker_panes") or [2, 3, 4]
    worker_panes = {intish(p) for p in topology_workers if intish(p) > 0}
    agents = activity.get("agents") if isinstance(activity.get("agents"), list) else []
    workers = []
    for agent in agents:
        pane = intish(agent.get("pane_idx") or agent.get("pane") or 0)
        if pane in worker_panes or (pane >= 2 and pane <= 4 and not worker_panes):
            workers.append(agent)
    waiting = [a for a in workers if str(a.get("state", "")).upper() == "WAITING" and a.get("capture_provenance", "live") == "live"]
    active = [a for a in workers if str(a.get("state", "")).upper() in {"THINKING", "GENERATING", "WORKING"}]
    unknown = [a for a in workers if str(a.get("state", "")).upper() in {"ERROR", "STALLED", "UNKNOWN"}]
    sources = source_rows(doc, ready)
    doctor_text = flatten_text(doc)
    joined_text = f"{doctor_text}\n{tail}"
    true_josh = bool(TRUE_JOSH_RE.search(joined_text))
    substrate = bool(SUBSTRATE_RE.search(joined_text)) and not true_josh
    max_wait_age = max([worker_age(a, now_epoch) for a in waiting] or [0])

    if true_josh:
        state = "true_josh_blocker"
    elif substrate and (doc.get("errors") or "BLOCKED" in tail.upper()):
        state = "substrate_blocked"
    elif waiting and sources and max_wait_age >= WORK_THRESHOLD_SECONDS:
        state = "idle_with_work_available"
    elif waiting and sources:
        state = "productive"
    elif active:
        state = "productive"
    elif unknown and sources:
        state = "substrate_blocked"
    else:
        state = "productive"

    return {
        "session": session,
        "repo": repo,
        "orchestrator_pane": orch_pane,
        "worker_panes": sorted(worker_panes) if worker_panes else sorted({intish(a.get("pane_idx") or a.get("pane") or 0) for a in workers}),
        "productivity_state": state,
        "workers_total": len(workers),
        "workers_waiting": len(waiting),
        "workers_active": len(active),
        "workers_problem": len(unknown),
        "max_wait_age_seconds": max_wait_age,
        "ready_count": len(ready) if isinstance(ready, list) else 0,
        "doctor_errors_count": len(doc.get("errors", [])) if isinstance(doc.get("errors"), list) else 0,
        "work_sources": sources,
        "escalation_packet": escalation_packet(session, orch_pane, sources, state),
    }


def worker_age(agent, now_epoch):
    for key in ("state_since_epoch", "waiting_since_epoch"):
        value = agent.get(key)
        if isinstance(value, (int, float)):
            return max(0, int(now_epoch - value))
    return intish(agent.get("wait_seconds") or agent.get("idle_seconds") or 0)


def escalation_packet(session, orch_pane, sources, state):
    top = sources[:3]
    instructions = []
    for idx, source in enumerate(top, 1):
        example = ", ".join(source.get("examples") or []) or "available finding"
        instructions.append(f"{idx}. File or dispatch a bead from: {source['source']} ({example}).")
    if not instructions:
        instructions.append("1. Confirm all nine always-available-work sources are zero, then report zero-backlog state.")
    return "\n".join([
        f"PRODUCTIVITY_ESCALATION session={session} target_pane={orch_pane} state={state}",
        "flywheel:1 owns continuous fleet productivity; no downtime unless TRUE Josh-blocker.",
        "Stop converting findings into reports only; convert findings into beads or dispatches now.",
        *instructions,
        f"evidence_memory={MEMORY_PATH}",
    ])


def append_jsonl(path: Path, row: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a") as f:
        f.write(json.dumps(row, sort_keys=True) + "\n")


def apply_actions(rows, args, checked_at):
    actions = []
    for row in rows:
        state = row["productivity_state"]
        if state == "idle_with_work_available":
            cmd = [args.ntm, "send", row["session"], f"--pane={row['orchestrator_pane']}", row["escalation_packet"]]
            ok = subprocess.call(cmd) == 0
            action = {"type": "xpane_productivity_escalation", "session": row["session"], "ok": ok}
            append_jsonl(Path(args.ledger), {"ts": checked_at, "event": "productivity_escalation_sent", **action, "state": state})
            actions.append(action)
        elif state == "true_josh_blocker":
            title = f"TRUE Josh-blocker: {row['session']}"
            body = f"{row['session']} needs Joshua action; see productivity escalation ledger."
            notify_ok = False
            if subprocess.call(["bash", "-lc", f"command -v notify >/dev/null && notify {json.dumps(title)} {json.dumps(body)}"], stderr=subprocess.DEVNULL) == 0:
                notify_ok = True
            subprocess.call(["osascript", "-e", f'display notification {json.dumps(body)} with title {json.dumps(title)}'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            action = {"type": "josh_notify_true_blocker", "session": row["session"], "notify_ok": notify_ok}
            append_jsonl(Path(args.ledger), {"ts": checked_at, "event": "true_josh_blocker_notify", **action, "state": state})
            actions.append(action)
    return actions


def make_report(args):
    loops_dir = Path(args.loops_dir)
    topology_rows = load_jsonl(Path(args.topology))
    sessions = loop_sessions(loops_dir, args.session, args.fleet)
    now_epoch = int(float(args.now_epoch or time.time()))
    checked_at = args.now or iso_now()
    def build_row(item):
        session, loop, loop_path = item
        topo = latest_topology(topology_rows, session)
        repo = loop.get("repo") or loop.get("repo_path") or loop.get("project_path") or topo.get("repo") or topo.get("project_path") or ""
        activity = activity_json(session, args.activity_dir, args.ntm, args.activity_timeout)
        ready = ready_rows(repo, session, args.ready_dir, args.ready_timeout)
        doc = doctor_json(session, args.doctor_dir, Path(args.last_tick_dir))
        orch_pane = intish(topo.get("orchestrator_pane") or loop.get("orchestrator_pane") or 1) or 1
        tail = capture_tail(session, orch_pane, args.capture_dir, args.ntm, args.capture_timeout)
        row = classify(session, repo, topo, loop, activity, ready, doc, tail, now_epoch)
        row["loop_path"] = str(loop_path)
        row["topology_line"] = topo.get("__line")
        return row

    if sessions:
        max_workers = max(1, min(int(args.max_workers), len(sessions)))
        with ThreadPoolExecutor(max_workers=max_workers) as pool:
            rows = list(pool.map(build_row, sessions))
    else:
        rows = []

    counts = {
        "productive": sum(1 for r in rows if r["productivity_state"] == "productive"),
        "idle_with_work_available": sum(1 for r in rows if r["productivity_state"] == "idle_with_work_available"),
        "true_josh_blocker": sum(1 for r in rows if r["productivity_state"] == "true_josh_blocker"),
        "substrate_blocked": sum(1 for r in rows if r["productivity_state"] == "substrate_blocked"),
    }
    actions = []
    if args.apply:
        actions = apply_actions(rows, args, checked_at)
    return {
        "schema_version": VERSION,
        "checked_at": checked_at,
        "threshold_seconds": WORK_THRESHOLD_SECONDS,
        "evidence_memory": MEMORY_PATH,
        "always_available_work_hierarchy": WORK_HIERARCHY,
        "status": "fail" if counts["idle_with_work_available"] or counts["true_josh_blocker"] else ("warn" if counts["substrate_blocked"] else "pass"),
        "productive_count": counts["productive"],
        "total_count": len(rows),
        "peer_orch_idle_with_work_available_count": counts["idle_with_work_available"],
        "peer_orch_substrate_blocked_count": counts["substrate_blocked"],
        "true_josh_blocker_count": counts["true_josh_blocker"],
        "sessions": rows,
        "planned_actions": planned_actions(rows),
        "actual_actions": actions,
        "signals": [
            {
                "name": "peer_orch_idle_with_work_available_count",
                "producer": ".flywheel/scripts/peer-orch-productivity-watch.sh",
                "measurement": "peer sessions with waiting workers plus any always-available work source beyond threshold",
                "threshold": ">0 after 300s",
                "gate_behavior": "doctor fail; flywheel:1 sends productivity escalation packet",
            },
            {
                "name": "peer_orch_substrate_blocked_count",
                "producer": ".flywheel/scripts/peer-orch-productivity-watch.sh",
                "measurement": "peer sessions blocked on flywheel-owned substrate repair rather than Joshua action",
                "threshold": ">0",
                "gate_behavior": "status dashboard warning and flywheel-owned repair path",
            },
        ],
    }


def planned_actions(rows):
    actions = []
    for row in rows:
        if row["productivity_state"] == "idle_with_work_available":
            actions.append({"type": "xpane_productivity_escalation", "session": row["session"], "target_pane": row["orchestrator_pane"]})
        elif row["productivity_state"] == "true_josh_blocker":
            actions.append({"type": "josh_notify_true_blocker", "session": row["session"]})
    return actions


def info_json():
    return {
        "schema_version": VERSION,
        "command": "peer-orch-productivity-watch.sh",
        "purpose": "Classify peer orchestrator productivity and compose same-tick escalation packets when work exists.",
        "mutates_only_with": "--apply",
        "dry_run_default": True,
        "donella_leverage_points": [4, 6],
        "memory_evidence": MEMORY_PATH,
        "states": ["productive", "idle_with_work_available", "true_josh_blocker", "substrate_blocked"],
    }


def schema_json():
    return {
        "schema_version": VERSION,
        "output_fields": [
            "productive_count",
            "total_count",
            "peer_orch_idle_with_work_available_count",
            "peer_orch_substrate_blocked_count",
            "true_josh_blocker_count",
            "sessions[].productivity_state",
            "sessions[].escalation_packet",
        ],
        "state_enum": ["productive", "idle_with_work_available", "true_josh_blocker", "substrate_blocked"],
        "canonical_cli_flags": ["--info", "--examples", "--schema", "--json", "--dry-run", "--apply", "--session=<name>", "--fleet"],
        "always_available_work_hierarchy": WORK_HIERARCHY,
    }


def examples_text():
    return "\n".join([
        "peer-orch-productivity-watch.sh --fleet --json",
        "peer-orch-productivity-watch.sh --session=skillos --dry-run --json",
        "peer-orch-productivity-watch.sh --fleet --apply --json",
        "peer-orch-productivity-watch.sh --schema --json",
    ])


def print_text(report):
    print(f"Fleet productivity: {report['productive_count']}/{report['total_count']} productive | idle-with-work={report['peer_orch_idle_with_work_available_count']} | substrate-blocked={report['peer_orch_substrate_blocked_count']}")
    for row in report["sessions"]:
        print(f"- {row['session']}: {row['productivity_state']} waiting={row['workers_waiting']} active={row['workers_active']} sources={len(row['work_sources'])}")


def parse_args():
    p = argparse.ArgumentParser(description="Peer orchestrator productivity watcher")
    p.add_argument("--info", action="store_true")
    p.add_argument("--examples", action="store_true")
    p.add_argument("--schema", action="store_true")
    p.add_argument("--doctor", action="store_true")
    p.add_argument("--json", action="store_true")
    p.add_argument("--dry-run", action="store_true", default=True)
    p.add_argument("--apply", action="store_true")
    p.add_argument("--fleet", action="store_true")
    p.add_argument("--session")
    p.add_argument("--loops-dir", default=os.environ.get("FLYWHEEL_PRODUCTIVITY_LOOPS_DIR", str(DEFAULT_LOOPS_DIR)))
    p.add_argument("--topology", default=os.environ.get("FLYWHEEL_PRODUCTIVITY_TOPOLOGY", str(DEFAULT_TOPOLOGY)))
    p.add_argument("--activity-dir", default=os.environ.get("FLYWHEEL_PRODUCTIVITY_ACTIVITY_DIR"))
    p.add_argument("--ready-dir", default=os.environ.get("FLYWHEEL_PRODUCTIVITY_READY_DIR"))
    p.add_argument("--doctor-dir", default=os.environ.get("FLYWHEEL_PRODUCTIVITY_DOCTOR_DIR"))
    p.add_argument("--capture-dir", default=os.environ.get("FLYWHEEL_PRODUCTIVITY_CAPTURE_DIR"))
    p.add_argument("--last-tick-dir", default=os.environ.get("FLYWHEEL_PRODUCTIVITY_LAST_TICK_DIR", str(DEFAULT_LAST_TICK_DIR)))
    p.add_argument("--ledger", default=os.environ.get("FLYWHEEL_PRODUCTIVITY_LEDGER", str(DEFAULT_LEDGER)))
    p.add_argument("--ntm", default=os.environ.get("FLYWHEEL_PRODUCTIVITY_NTM", DEFAULT_NTM))
    p.add_argument("--activity-timeout", type=int, default=int(os.environ.get("FLYWHEEL_PRODUCTIVITY_ACTIVITY_TIMEOUT", "5")))
    p.add_argument("--ready-timeout", type=int, default=int(os.environ.get("FLYWHEEL_PRODUCTIVITY_READY_TIMEOUT", "5")))
    p.add_argument("--capture-timeout", type=int, default=int(os.environ.get("FLYWHEEL_PRODUCTIVITY_CAPTURE_TIMEOUT", "2")))
    p.add_argument("--max-workers", type=int, default=int(os.environ.get("FLYWHEEL_PRODUCTIVITY_MAX_WORKERS", "6")))
    p.add_argument("--now")
    p.add_argument("--now-epoch", default=os.environ.get("FLYWHEEL_PRODUCTIVITY_NOW_EPOCH"))
    return p.parse_args()


def main():
    args = parse_args()
    if args.info:
        print(json.dumps(info_json(), sort_keys=True) if args.json else "\n".join(f"{k}: {v}" for k, v in info_json().items()))
        return 0
    if args.schema:
        print(json.dumps(schema_json(), sort_keys=True) if args.json else json.dumps(schema_json(), indent=2))
        return 0
    if args.examples:
        print(json.dumps({"examples": examples_text().splitlines()}, sort_keys=True) if args.json else examples_text())
        return 0
    report = make_report(args)
    if args.json or args.doctor:
        print(json.dumps(report, sort_keys=True))
    else:
        print_text(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
