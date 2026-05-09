#!/usr/bin/env bash
# peer-orch-drift-probe.sh — detect mission-alignment drift in peer orchestrator sessions
# Reads each peer's MISSION.md anchor + recent dispatch-log entries; scores drift %.
# Exit 0 = all sessions <20%, 1 = any 20-40%, 2 = any >=40%
#
# canonical-cli-scoping-allow-large: probe script; Python embedded for portability

set -euo pipefail

python3 - "$@" <<'PY'
import argparse
import json
import os
import re
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

SCHEMA_VERSION = "peer-orch-drift-probe/v1"
DEFAULT_TOPOLOGY = Path.home() / ".local/state/flywheel/session-topology.jsonl"
DEFAULT_ALERT_LOG = Path.home() / ".local/state/flywheel/peer-orch-drift-alerts.jsonl"
DEFAULT_NTM = "/Users/josh/.local/bin/ntm"
DEFAULT_LOOKBACK = 20      # last N dispatch entries to score

REPO_ROOTS = {
    "flywheel":      "/Users/josh/Developer/flywheel",
    "mobile-eats":   "/Users/josh/Developer/mobile-eats",
    "alpsinsurance": "/Users/josh/Developer/alpsinsurance",
    "skillos":       "/Users/josh/Developer/skillos",
    "vrtx":          "/Users/josh/Developer/vrtx",
}

# Simple keyword sets per known mission area; extensible.
# These are intentionally broad — false-positive rate is low because we only
# flag sessions whose dispatches have NO mission keyword at all.
MISSION_KEYWORDS_RE = re.compile(
    r"(mission|anchor|align|M\d+|R\d+|B\d+|goal|deploy|ship|test|fix|refactor|"
    r"doctor|bead|skill|learn|audit|infra|api|feature|client|integration|"
    r"onboard|scaffold|lint|ci|spec|prd|data|pipeline|monitor|alert|scale|"
    r"migrate|install|template|probe|watcher|dispatch|callback|close|open)",
    re.IGNORECASE,
)


def iso_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_jsonl(path: Path) -> list[dict]:
    rows = []
    try:
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
                if isinstance(row, dict):
                    rows.append(row)
            except Exception:
                pass
    except Exception:
        pass
    return rows


def latest_row_for_session(rows: list[dict], session: str) -> dict | None:
    """Return most recent topology row for session."""
    matches = [r for r in rows if r.get("session") == session]
    if not matches:
        return None
    return sorted(matches, key=lambda r: r.get("effective_at", ""), reverse=True)[0]


def read_mission_anchor(repo_path: Path) -> str:
    """Read first non-blank, non-comment line from .flywheel/MISSION.md as anchor."""
    mission_file = repo_path / ".flywheel" / "MISSION.md"
    try:
        text = mission_file.read_text(encoding="utf-8", errors="replace")
        # Look for first ## Mission Source or ## Mission Anchor section
        for line in text.splitlines():
            line = line.strip()
            if line and not line.startswith("#") and not line.startswith("schema_version") \
                    and not line.startswith("doc_type") and not line.startswith("status") \
                    and not line.startswith("locked") and not line.startswith("lock") \
                    and not line.startswith("repo") and not line.startswith("template") \
                    and not line.startswith("rendered") and not line.startswith("source") \
                    and not line.startswith("mission_lock") and not line.startswith("sections") \
                    and not line.startswith("---"):
                return line[:200]
        return text[:200].replace("\n", " ").strip()
    except Exception:
        return "(MISSION.md missing)"


def read_recent_dispatches(repo_path: Path, n: int) -> list[dict]:
    log = repo_path / ".flywheel" / "dispatch-log.jsonl"
    rows = read_jsonl(log)
    # Only rows that look like dispatch entries (have task_summary or task_id or dispatch_id)
    dispatch_rows = [
        r for r in rows
        if r.get("task_summary") or r.get("dispatch_id") or r.get("task_id")
    ]
    return dispatch_rows[-n:]


def score_dispatch_drift(dispatches: list[dict], anchor: str) -> tuple[int, int, str | None]:
    """
    Returns (drift_count, total_scored, last_drift_ts).
    A dispatch is 'drifted' if its task_summary has no mission keyword match
    AND the anchor is not '(MISSION.md missing)'.
    If anchor is missing we cannot score — return 0 drift.
    """
    if anchor == "(MISSION.md missing)" or not dispatches:
        return 0, 0, None

    drift_count = 0
    last_drift_ts = None
    for d in dispatches:
        summary = str(d.get("task_summary") or d.get("dispatch_id") or d.get("task_id") or "")
        if not summary:
            continue
        if not MISSION_KEYWORDS_RE.search(summary):
            drift_count += 1
            ts = d.get("ts") or d.get("effective_at")
            if ts:
                last_drift_ts = ts

    return drift_count, len(dispatches), last_drift_ts


def load_topology(topology_path: Path) -> dict[str, dict]:
    """Return {session: latest_row} for all sessions."""
    rows = read_jsonl(topology_path)
    sessions: dict[str, dict] = {}
    for row in rows:
        s = row.get("session")
        if not s:
            continue
        existing = sessions.get(s)
        if not existing or row.get("effective_at", "") > existing.get("effective_at", ""):
            sessions[s] = row
    return sessions


def build_session_report(
    session: str,
    topo_row: dict | None,
    repo_path: Path | None,
    n: int,
) -> dict:
    if repo_path is None or not repo_path.exists():
        return {
            "session": session,
            "status": "no_repo",
            "anchor": "(no repo found)",
            "recent_closes": 0,
            "drift_count": 0,
            "drift_pct": 0.0,
            "last_drift_ts": None,
        }

    anchor = read_mission_anchor(repo_path)
    dispatches = read_recent_dispatches(repo_path, n)
    drift_count, total, last_drift_ts = score_dispatch_drift(dispatches, anchor)
    drift_pct = round(drift_count / total * 100, 1) if total > 0 else 0.0

    return {
        "session": session,
        "status": "scored",
        "anchor": anchor,
        "recent_closes": total,
        "drift_count": drift_count,
        "drift_pct": drift_pct,
        "last_drift_ts": last_drift_ts,
        "orchestrator_pane": (topo_row or {}).get("orchestrator_pane"),
        "callback_pane": (topo_row or {}).get("callback_pane"),
    }


def classify_exit_code(by_session: dict) -> int:
    max_pct = max((v.get("drift_pct", 0) for v in by_session.values()), default=0)
    if max_pct >= 40:
        return 2
    if max_pct >= 20:
        return 1
    return 0


def emit_alert(session_report: dict, alert_log: Path, dry_run: bool) -> str | None:
    """Write alert to JSONL and return ntm message text."""
    anchor = session_report["anchor"]
    drift_pct = session_report["drift_pct"]
    drift_count = session_report["drift_count"]
    total = session_report["recent_closes"]
    ts = iso_now()
    msg = (
        f"ALIGNMENT WARNING [{ts}]: session={session_report['session']} "
        f"drift_pct={drift_pct}% ({drift_count}/{total} recent dispatches) "
        f"anchor={anchor[:80]!r}. Reorient or pause."
    )
    row = {
        "ts": ts,
        "schema_version": SCHEMA_VERSION,
        "session": session_report["session"],
        "anchor": anchor,
        "drift_pct": drift_pct,
        "drift_count": drift_count,
        "total_scored": total,
        "last_drift_ts": session_report.get("last_drift_ts"),
        "message": msg,
        "dry_run": dry_run,
    }
    if not dry_run:
        alert_log.parent.mkdir(parents=True, exist_ok=True)
        with alert_log.open("a", encoding="utf-8") as fh:
            fh.write(json.dumps(row, separators=(",", ":")) + "\n")
    return msg


def try_send_agent_mail(session: str, orch_pane: int | None, msg: str, dry_run: bool):
    """
    Attempt agent-mail send to orchestrator pane.
    Falls back to JSONL-only (already done by caller) if agent-mail unavailable.
    GAP: mcp-agent-mail MCP not directly accessible from shell; log the gap.
    """
    # agent-mail CLI path (if shipped separately)
    am_bin = Path.home() / ".local" / "bin" / "agent-mail"
    if not am_bin.exists():
        return False
    if dry_run:
        print(f"[dry-run] would send agent-mail to {session}:{orch_pane}: {msg}", file=sys.stderr)
        return True
    try:
        import subprocess
        result = subprocess.run(
            [str(am_bin), "send", "--session", session, "--pane", str(orch_pane or 1),
             "--message", msg],
            capture_output=True, text=True, timeout=10, check=False,
        )
        return result.returncode == 0
    except Exception:
        return False


def emit_info(json_out: bool):
    payload = {
        "schema_version": "canonical-cli-info/v1",
        "name": "peer-orch-drift-probe",
        "version": "1.0.0",
        "description": (
            "Detect mission-alignment drift in peer orchestrator sessions. "
            "Reads MISSION.md anchor + recent dispatch-log; scores drift %."
        ),
        "exit_codes": {"0": "all <20%", "1": "any 20-40%", "2": "any >=40%", "2_usage": "bad args"},
        "flags": ["--json", "--dry-run", "--topology", "--alert-log", "--lookback", "--session",
                  "--info", "--examples", "--schema"],
        "alert_log": str(DEFAULT_ALERT_LOG),
        "agent_mail_gap": "mcp-agent-mail MCP not accessible from shell; alerts written to JSONL only",
    }
    if json_out:
        print(json.dumps(payload, separators=(",", ":")))
    else:
        print(payload["description"])


def emit_examples(json_out: bool):
    examples = [
        "peer-orch-drift-probe.sh --json",
        "peer-orch-drift-probe.sh --dry-run --json",
        "peer-orch-drift-probe.sh --session alpsinsurance --json",
        "peer-orch-drift-probe.sh --lookback 10 --json",
        "peer-orch-drift-probe.sh --json | jq '.by_session'",
    ]
    payload = {"schema_version": SCHEMA_VERSION, "examples": examples}
    if json_out:
        print(json.dumps(payload, separators=(",", ":")))
    else:
        print("\n".join(examples))


def emit_schema():
    print(json.dumps({
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "schema_version": SCHEMA_VERSION,
        "type": "object",
        "required": ["schema_version", "checked_at", "by_session",
                     "drift_session_count", "total_session_count", "max_drift_pct"],
        "properties": {
            "schema_version": {"const": SCHEMA_VERSION},
            "checked_at": {"type": "string"},
            "by_session": {"type": "object"},
            "drift_session_count": {"type": "integer"},
            "total_session_count": {"type": "integer"},
            "max_drift_pct": {"type": "number"},
            "alerts_emitted": {"type": "array"},
        },
    }, separators=(",", ":")))


def main():
    parser = argparse.ArgumentParser(prog="peer-orch-drift-probe.sh")
    parser.add_argument("--json", action="store_true", help="Machine-readable JSON output")
    parser.add_argument("--dry-run", action="store_true",
                        help="Read-only: detect drift but write no alerts")
    parser.add_argument("--topology", default=str(DEFAULT_TOPOLOGY),
                        help="Path to session-topology.jsonl")
    parser.add_argument("--alert-log", default=str(DEFAULT_ALERT_LOG),
                        help="Path to peer-orch-drift-alerts.jsonl")
    parser.add_argument("--lookback", type=int, default=DEFAULT_LOOKBACK,
                        help="Number of recent dispatches to score per session")
    parser.add_argument("--session", action="append", default=[],
                        help="Restrict to specific session(s); repeatable")
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--schema", action="store_true")
    # Test-fixture overrides
    parser.add_argument("--fixture-dir", default="",
                        help="Override repo root dir (for tests); sessions map to <dir>/<session>")
    args = parser.parse_args()

    if args.info:
        emit_info(args.json)
        return
    if args.examples:
        emit_examples(args.json)
        return
    if args.schema:
        emit_schema()
        return

    topology_rows = load_topology(Path(args.topology))

    # Determine which sessions to probe
    if args.session:
        target_sessions = args.session
    else:
        # All sessions in topology that are not out-of-fleet
        target_sessions = [
            s for s, row in topology_rows.items()
            if row.get("session_status", "") != "out_of_fleet_human_only_unanchored"
            and row.get("orchestrator_pane") is not None
        ]
        # Also include sessions in REPO_ROOTS even if not in topology
        for s in REPO_ROOTS:
            if s not in target_sessions:
                target_sessions.append(s)

    by_session: dict[str, dict] = {}
    alerts_emitted: list[str] = []
    alert_log = Path(args.alert_log)

    for session in sorted(set(target_sessions)):
        topo_row = topology_rows.get(session)

        # Resolve repo path
        if args.fixture_dir:
            repo_path = Path(args.fixture_dir) / session
        else:
            repo_path = Path(REPO_ROOTS.get(session, f"/Users/josh/Developer/{session}"))

        report = build_session_report(session, topo_row, repo_path, args.lookback)
        by_session[session] = report

        # Alert if drift threshold breached
        drift_pct = report.get("drift_pct", 0)
        if drift_pct >= 20 and report.get("status") == "scored":
            msg = emit_alert(report, alert_log, args.dry_run)
            if msg:
                alerts_emitted.append(msg)
                orch_pane = report.get("orchestrator_pane") or report.get("callback_pane")
                try_send_agent_mail(session, orch_pane, msg, args.dry_run)

    total = len(by_session)
    drifted = sum(1 for v in by_session.values() if v.get("drift_pct", 0) >= 20)
    max_pct = max((v.get("drift_pct", 0) for v in by_session.values()), default=0.0)
    aligned = total - drifted

    payload = {
        "schema_version": SCHEMA_VERSION,
        "checked_at": iso_now(),
        "by_session": by_session,
        "drift_session_count": drifted,
        "aligned_session_count": aligned,
        "total_session_count": total,
        "max_drift_pct": max_pct,
        "alerts_emitted": alerts_emitted,
        "alert_log": str(alert_log),
        "dry_run": args.dry_run,
        "agent_mail_gap": (
            "mcp-agent-mail MCP not accessible from shell; "
            "alerts written to JSONL only; "
            "agent-mail CLI fallback attempted if ~/.local/bin/agent-mail exists"
        ),
        # Dashboard line for /flywheel:status
        "dashboard_line": (
            f"Peers: {aligned}/{total} aligned"
            + (
                " (drift: "
                + ", ".join(
                    f"{s}={v['drift_pct']}%"
                    for s, v in sorted(by_session.items())
                    if v.get("drift_pct", 0) >= 20
                )
                + ")"
                if drifted > 0 else ""
            )
        ),
    }

    if args.json:
        print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    else:
        # Human-readable
        print(f"Peer orch drift: {aligned}/{total} aligned  max_drift={max_pct}%")
        for s, v in sorted(payload["by_session"].items()):
            flag = " DRIFT" if v.get("drift_pct", 0) >= 20 else ""
            print(f"  {s}: drift={v.get('drift_pct', 0)}%  scored={v.get('recent_closes', 0)}{flag}")
        if alerts_emitted:
            print(f"Alerts written: {len(alerts_emitted)}")

    exit_code = classify_exit_code(by_session)
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
PY
