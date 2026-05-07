#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
import argparse
import json
import os
import shutil
import stat
import subprocess
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

SCHEMA_VERSION = "recovery-preinstall-audit/v1"
SOURCE_PLAN = ".flywheel/PLANS/recovery-system-2026-05-01/00-PLAN.md"
NTM_BIN = "/Users/josh/.local/bin/ntm"
NTM_CONFIG = "~/.config/ntm/config.toml"
TOPOLOGY = "~/.local/state/flywheel/session-topology.jsonl"
ROSTER = "~/.local/state/flywheel/team-roster.jsonl"
LOOPS_DIR = "~/.flywheel/loops"
AGENT_MAIL_STATE = "~/.local/state/flywheel/agent-mail"
AGENT_MAIL_CLI = "/Users/josh/.local/bin/agent-mail"
AGENT_MAIL_LIVENESS = "http://127.0.0.1:8765/health/liveness"


def now_iso():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def ep(path):
    return Path(path).expanduser()


def as_abs(path):
    if path is None:
        return None
    try:
        return str(ep(path).resolve(strict=False))
    except OSError:
        return str(ep(path).absolute())


def same_path(left, right):
    return bool(left and right and as_abs(left) == as_abs(right))


def read_jsonl(path):
    rows = []
    p = ep(path)
    if not p.exists():
        return rows
    for line_no, line in enumerate(p.read_text(encoding="utf-8", errors="replace").splitlines(), start=1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            rows.append({"_parse_error": True, "_line": line_no})
            continue
        if isinstance(row, dict):
            row["_line"] = line_no
            rows.append(row)
    return rows


def merge_latest_by_session(rows):
    merged = {}
    for row in rows:
        session = row.get("session")
        if not session:
            continue
        target = merged.setdefault(str(session), {"session": str(session), "_sources": []})
        target["_sources"].append({"line": row.get("_line"), "ts": row.get("effective_at") or row.get("ts")})
        for key, value in row.items():
            if key.startswith("_") or value in (None, "", [], {}):
                continue
            target[key] = value
    return merged


def parse_session_paths(config_path):
    p = ep(config_path)
    if not p.exists():
        return {}, {"exists": False, "path": str(p)}
    lines = p.read_text(encoding="utf-8", errors="replace").splitlines()
    in_table = False
    paths = {}
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            in_table = stripped == "[session_paths]"
            continue
        if not in_table or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip().strip("'\"")
        value = value.split("#", 1)[0].strip().strip("'\"")
        if key and value:
            paths[key] = value
    return paths, {"exists": True, "path": str(p)}


def run_cmd(args, timeout=5, env=None, cwd=None):
    try:
        proc = subprocess.run(args, text=True, capture_output=True, timeout=timeout, env=env, cwd=cwd)
        return {
            "ok": proc.returncode == 0,
            "rc": proc.returncode,
            "stdout": proc.stdout.strip(),
            "stderr": proc.stderr.strip(),
        }
    except FileNotFoundError:
        return {"ok": False, "rc": 127, "stdout": "", "stderr": "command_not_found"}
    except subprocess.TimeoutExpired:
        return {"ok": False, "rc": 124, "stdout": "", "stderr": "timeout"}


def ntm_sessions(ntm_bin):
    result = run_cmd([ntm_bin, "list", "--json"], timeout=8)
    names = []
    parsed = None
    if result["ok"]:
        try:
            parsed = json.loads(result["stdout"] or "{}")
            raw_sessions = parsed if isinstance(parsed, list) else parsed.get("sessions", [])
            for item in raw_sessions:
                if isinstance(item, dict):
                    name = item.get("name") or item.get("session")
                    if name:
                        names.append(str(name))
        except json.JSONDecodeError as exc:
            result["ok"] = False
            result["stderr"] = f"invalid_json: {exc}"
    return names, {"path": ntm_bin, "result": result, "parsed": parsed}


def loop_states(loops_dir):
    states = {}
    base = ep(loops_dir)
    if not base.exists():
        return states
    for path in sorted(base.glob("*.json")):
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            payload = {"parse_error": str(exc)}
        session = payload.get("session") if isinstance(payload, dict) else None
        states[session or path.stem] = {"path": str(path), "payload": payload}
    return states


def candidate_projects(config_paths, topology, roster, loops):
    projects = {}
    for session, path in config_paths.items():
        projects.setdefault(as_abs(path), {"repo_path": as_abs(path), "sessions": set(), "sources": set()})
        projects[as_abs(path)]["sessions"].add(session)
        projects[as_abs(path)]["sources"].add("ntm_config")
    for source_name, rows in (("topology", topology), ("team_roster", roster)):
        for session, row in rows.items():
            path = row.get("repo_path") or row.get("agent_mail_project")
            if not path:
                continue
            key = as_abs(path)
            projects.setdefault(key, {"repo_path": key, "sessions": set(), "sources": set()})
            projects[key]["sessions"].add(session)
            projects[key]["sources"].add(source_name)
    for session, row in loops.items():
        payload = row.get("payload") if isinstance(row, dict) else {}
        path = payload.get("repo") or payload.get("repo_path") or payload.get("project_path")
        if not path:
            continue
        key = as_abs(path)
        projects.setdefault(key, {"repo_path": key, "sessions": set(), "sources": set()})
        projects[key]["sessions"].add(session)
        projects[key]["sources"].add("loop_state")
    clean = []
    for item in projects.values():
        if item["repo_path"]:
            clean.append({
                "repo_path": item["repo_path"],
                "sessions": sorted(item["sessions"]),
                "sources": sorted(item["sources"]),
            })
    return sorted(clean, key=lambda x: x["repo_path"])


def score_session(session, executable_path, live_sessions, topology_row, roster_row, loop_row, dispatch_exists, confidence_min):
    topology_path = topology_row.get("repo_path") or topology_row.get("agent_mail_project") if topology_row else None
    roster_path = roster_row.get("repo_path") or roster_row.get("agent_mail_project") if roster_row else None
    topology_match = same_path(executable_path, topology_path)
    roster_match = same_path(executable_path, roster_path)
    score = 0
    reasons = []
    if session in live_sessions:
        score += 20
        reasons.append("ntm_list")
    if executable_path and ep(executable_path).exists():
        score += 20
        reasons.append("executable_path_exists")
    if topology_match:
        score += 20
        reasons.append("topology_match")
    elif topology_row:
        score += 8
        reasons.append("topology_seen")
    if roster_match:
        score += 20
        reasons.append("roster_match")
    elif roster_row:
        score += 8
        reasons.append("roster_seen")
    if loop_row:
        score += 10
        reasons.append("loop_state")
    if dispatch_exists:
        score += 10
        reasons.append("dispatch_log")
    return {
        "session": session,
        "executable_path": as_abs(executable_path) if executable_path else None,
        "topology_match": topology_match,
        "roster_match": roster_match,
        "confidence": min(score, 100),
        "confidence_min": confidence_min,
        "low_confidence": score < confidence_min,
        "evidence": reasons,
        "topology_path": as_abs(topology_path) if topology_path else None,
        "roster_path": as_abs(roster_path) if roster_path else None,
        "live_in_ntm": session in live_sessions,
    }


def check_beads_db(repo_path):
    db = Path(repo_path) / ".beads" / "beads.db"
    if not db.exists():
        return {"path": str(db), "exists": False, "integrity": "missing"}
    sqlite = shutil.which("sqlite3")
    if not sqlite:
        return {"path": str(db), "exists": True, "integrity": "sqlite3_unavailable"}
    result = run_cmd([sqlite, "-readonly", str(db), "PRAGMA integrity_check;"], timeout=10)
    stdout = result.get("stdout", "")
    return {
        "path": str(db),
        "exists": True,
        "integrity": "ok" if result["ok"] and stdout.splitlines()[:1] == ["ok"] else "failed",
        "sqlite_rc": result["rc"],
        "sqlite_stdout": stdout[:400],
        "sqlite_stderr": result.get("stderr", "")[:400],
    }


def dirty_worktree(repo_path, owners):
    git_dir = Path(repo_path) / ".git"
    if not git_dir.exists():
        return {"is_git_repo": False, "dirty_count": 0, "dirty_paths_sample": [], "owner_map": owners}
    result = run_cmd(["git", "-C", repo_path, "status", "--porcelain=v1"], timeout=10)
    paths = []
    if result["ok"]:
        for line in result["stdout"].splitlines():
            if line:
                paths.append(line[3:] if len(line) > 3 else line)
    return {
        "is_git_repo": True,
        "dirty_count": len(paths),
        "dirty_paths_sample": paths[:25],
        "owner_map": owners,
        "status_rc": result["rc"],
    }


def scan_agent_mail_identities(state_dir):
    sessions_dir = ep(state_dir) / "sessions"
    tokens_dir = ep(state_dir) / "tokens"
    identities = []
    if not sessions_dir.exists():
        return identities
    for path in sorted(sessions_dir.glob("*.json")):
        try:
            row = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            identities.append({"path": str(path), "parse_error": str(exc), "ready": False})
            continue
        identity = row.get("identity_name") or row.get("agent_name") or row.get("name")
        token_path = row.get("token_path")
        if not token_path and identity:
            token_path = str(tokens_dir / f"{identity}.token")
        token = ep(token_path) if token_path else None
        mode = None
        token_exists = bool(token and token.exists())
        if token_exists:
            mode = stat.S_IMODE(token.stat().st_mode)
        ready = bool(identity and token_exists and mode == 0o600 and row.get("status") not in ("inactive", "archived"))
        identities.append({
            "path": str(path),
            "session": row.get("session"),
            "pane": row.get("pane"),
            "identity_name": identity,
            "status": row.get("status"),
            "role": row.get("role"),
            "token_path": str(token) if token else None,
            "token_exists": token_exists,
            "token_mode_octal": format(mode, "04o") if mode is not None else None,
            "ready": ready,
        })
    return identities


def agent_mail_readiness(args):
    health = {"url": args.agent_mail_liveness_url, "ok": False, "status": "unreachable"}
    try:
        with urllib.request.urlopen(args.agent_mail_liveness_url, timeout=3) as resp:
            body = resp.read(4096).decode("utf-8", errors="replace")
            try:
                parsed = json.loads(body)
            except json.JSONDecodeError:
                parsed = {"raw": body}
            health = {"url": args.agent_mail_liveness_url, "ok": 200 <= resp.status < 300, "http_status": resp.status, "payload": parsed}
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        health["error"] = str(exc)
    env = dict(os.environ)
    env.pop("DATABASE_URL", None)
    cli_result = run_cmd([args.agent_mail_cli, "--version"], timeout=5, env=env)
    if not cli_result["ok"]:
        cli_result = run_cmd([args.agent_mail_cli, "--help"], timeout=5, env=env)
    identities = scan_agent_mail_identities(args.agent_mail_state_dir)
    return {
        "service_liveness": health,
        "cli_without_database_url": cli_result,
        "identity_registry_dir": str(ep(args.agent_mail_state_dir) / "sessions"),
        "identities": identities,
        "ready_identity_count": sum(1 for row in identities if row.get("ready")),
        "identity_count": len(identities),
    }


def repo_owners(repo_path, roster, identities):
    owners = []
    for session, row in roster.items():
        if same_path(repo_path, row.get("repo_path") or row.get("agent_mail_project")):
            owners.append({
                "source": "team_roster",
                "session": session,
                "orchestrator": row.get("orchestrator"),
                "workers": row.get("workers") or row.get("worker_panes") or [],
                "agent_mail_identity": row.get("agent_mail_identity") or row.get("fleet_mail_identity"),
            })
    for identity in identities:
        session = identity.get("session")
        if session and session in roster and same_path(repo_path, roster[session].get("repo_path") or roster[session].get("agent_mail_project")):
            owners.append({
                "source": "agent_mail_identity",
                "session": session,
                "pane": identity.get("pane"),
                "identity_name": identity.get("identity_name"),
                "ready": identity.get("ready"),
            })
    return owners


def recent_tick_receipts(projects, limit):
    names = [
        ".flywheel/last_closeout_receipt.json",
        ".flywheel/runtime/flywheel-loop/last_run.json",
        ".flywheel/runtime/tick/last_run.json",
    ]
    receipts = []
    for project in projects:
        repo = project["repo_path"]
        for rel in names:
            path = Path(repo) / rel
            if not path.exists():
                continue
            try:
                stat_row = path.stat()
                payload = json.loads(path.read_text(encoding="utf-8"))
                receipts.append({
                    "repo_path": repo,
                    "path": str(path),
                    "mtime": datetime.fromtimestamp(stat_row.st_mtime, timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
                    "payload_keys": sorted(payload.keys()) if isinstance(payload, dict) else [],
                })
            except Exception as exc:
                receipts.append({"repo_path": repo, "path": str(path), "error": str(exc)})
    return sorted(receipts, key=lambda x: x.get("mtime", ""), reverse=True)[:limit]


def dispatch_context(projects, line_limit):
    contexts = []
    dispatch_events = {"dispatch_sent", "worker_dispatch", "dispatch", "sent"}
    callback_markers = {"callback", "callback_received", "done", "blocked", "closed", "complete"}
    for project in projects:
        path = Path(project["repo_path"]) / ".flywheel" / "dispatch-log.jsonl"
        rows = read_jsonl(path)
        task_state = {}
        for row in rows:
            task_id = row.get("task_id") or row.get("bead_id") or row.get("bead")
            if not task_id:
                continue
            state = task_state.setdefault(str(task_id), {"task_id": str(task_id), "last_line": row.get("_line"), "last_event": row.get("event"), "has_dispatch": False, "has_callback": False})
            event = str(row.get("event") or row.get("callback_status") or row.get("status") or "").lower()
            if event in dispatch_events or row.get("task_file") or row.get("prompt_path"):
                state["has_dispatch"] = True
            if any(marker in event for marker in callback_markers) or row.get("callback_received_at"):
                state["has_callback"] = True
            state["last_line"] = row.get("_line")
            state["last_event"] = event
        inflight = [row for row in task_state.values() if row["has_dispatch"] and not row["has_callback"]]
        contexts.append({
            "repo_path": project["repo_path"],
            "path": str(path),
            "exists": path.exists(),
            "row_count": len(rows),
            "recent_rows": rows[-line_limit:],
            "in_flight": inflight,
            "in_flight_count": len(inflight),
        })
    return contexts


def build_report(args):
    config_paths, config_meta = parse_session_paths(args.ntm_config)
    live_sessions, ntm_meta = ntm_sessions(args.ntm_bin)
    topology_rows = merge_latest_by_session(read_jsonl(args.topology))
    roster_rows = merge_latest_by_session(read_jsonl(args.team_roster))
    loops = loop_states(args.loops_dir)
    projects = candidate_projects(config_paths, topology_rows, roster_rows, loops)
    dispatch_exists = {
        session: Path(as_abs(path) or "").joinpath(".flywheel/dispatch-log.jsonl").exists()
        for session, path in config_paths.items()
    }
    sessions = sorted(set(live_sessions) | set(config_paths) | set(topology_rows) | set(roster_rows) | set(loops))
    session_rows = []
    for session in sessions:
        exe = config_paths.get(session)
        if not exe:
            exe = (topology_rows.get(session) or {}).get("repo_path") or (roster_rows.get(session) or {}).get("repo_path")
        session_rows.append(score_session(
            session,
            exe,
            live_sessions,
            topology_rows.get(session),
            roster_rows.get(session),
            loops.get(session),
            dispatch_exists.get(session, False),
            args.confidence_min,
        ))
    mail = agent_mail_readiness(args)
    project_rows = []
    for project in projects:
        owners = repo_owners(project["repo_path"], roster_rows, mail["identities"])
        row = dict(project)
        row["beads_db"] = check_beads_db(project["repo_path"])
        row["dirty_worktree"] = dirty_worktree(project["repo_path"], owners)
        project_rows.append(row)
    low = [row for row in session_rows if row["low_confidence"]]
    return {
        "schema_version": SCHEMA_VERSION,
        "source_plan": SOURCE_PLAN,
        "generated_at": args.now or now_iso(),
        "repo": as_abs(args.repo),
        "confidence_min": args.confidence_min,
        "apply_blocked": bool(low),
        "low_confidence_sessions": [row["session"] for row in low],
        "sources": {
            "ntm_bin": ntm_meta,
            "ntm_config": config_meta,
            "topology": str(ep(args.topology)),
            "team_roster": str(ep(args.team_roster)),
            "loops_dir": str(ep(args.loops_dir)),
            "agent_mail_state_dir": str(ep(args.agent_mail_state_dir)),
        },
        "sessions": session_rows,
        "projects": project_rows,
        "agent_mail": mail,
        "loop_state": loops,
        "tick_receipts": recent_tick_receipts(projects, args.receipt_limit),
        "dispatch_context": dispatch_context(projects, args.dispatch_log_limit),
    }


def main(argv):
    parser = argparse.ArgumentParser(description="Read-only recovery-system preinstall audit.")
    parser.add_argument("--repo", default="/Users/josh/Developer/flywheel")
    parser.add_argument("--ntm-bin", default=NTM_BIN)
    parser.add_argument("--ntm-config", default=NTM_CONFIG)
    parser.add_argument("--topology", default=TOPOLOGY)
    parser.add_argument("--team-roster", default=ROSTER)
    parser.add_argument("--loops-dir", default=LOOPS_DIR)
    parser.add_argument("--agent-mail-state-dir", default=AGENT_MAIL_STATE)
    parser.add_argument("--agent-mail-cli", default=AGENT_MAIL_CLI)
    parser.add_argument("--agent-mail-liveness-url", default=AGENT_MAIL_LIVENESS)
    parser.add_argument("--confidence-min", type=int, default=70)
    parser.add_argument("--dispatch-log-limit", type=int, default=8)
    parser.add_argument("--receipt-limit", type=int, default=20)
    parser.add_argument("--now")
    parser.add_argument("--output")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args(argv)
    report = build_report(args)
    text = json.dumps(report, indent=2 if args.pretty else None, sort_keys=True) + "\n"
    if args.output:
        out = ep(args.output)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(text, encoding="utf-8")
    sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY
