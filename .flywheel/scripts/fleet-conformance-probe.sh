#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

SCHEMA_VERSION = "fleet-conformance-observatory/v1"
DEFAULT_ROOT = Path("/Users/josh/Developer")
DEFAULT_LOOPS_DIR = Path.home() / ".flywheel" / "loops"
DEFAULT_CANONICAL = Path("/Users/josh/Developer/flywheel/.flywheel/AGENTS-CANONICAL.md")
DEFAULT_CACHE_DIR = Path.home() / ".local/state/flywheel/fleet-conformance-cache"
DEFAULT_NTM = "/Users/josh/.local/bin/ntm"
GREEN_MIN = 85
YELLOW_MIN = 60

AXIS_WEIGHTS = {
    "canonical_l_rule_coverage": 25,
    "doctor_status": 20,
    "identity_drift": 15,
    "meta_rule_cache_freshness": 15,
    "mission_lock_age": 15,
    "agents_mtime_age": 10,
}


def emit(obj: dict) -> None:
    print(json.dumps(obj, separators=(",", ":"), sort_keys=True))


def load_json(path: Path, default):
    try:
        with path.open() as f:
            return json.load(f)
    except Exception:
        return default


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + f".tmp.{os.getpid()}")
    tmp.write_text(json.dumps(payload, separators=(",", ":"), sort_keys=True), encoding="utf-8")
    tmp.replace(path)


def stable_key(args: argparse.Namespace) -> str:
    material = {
        "session": args.session,
        "fleet": args.fleet,
        "root": str(args.root),
        "loops_dir": str(args.loops_dir),
        "canonical_agents": str(args.canonical_agents),
        "skip_doctor": bool(os.environ.get("FLYWHEEL_CONFORMANCE_SKIP_DOCTOR")),
    }
    return hashlib.sha256(json.dumps(material, sort_keys=True).encode()).hexdigest()[:16]


def cache_path(args: argparse.Namespace) -> Path:
    return Path(args.cache_dir).expanduser() / f"{stable_key(args)}.json"


def cache_fresh(path: Path, ttl: int, now_epoch: int) -> bool:
    if ttl <= 0 or not path.exists():
        return False
    try:
        return now_epoch - int(path.stat().st_mtime) <= ttl
    except Exception:
        return False


def read_l_rules(path: Path) -> set[str]:
    if not path.exists():
        return set()
    rules: set[str] = set()
    pattern = re.compile(r"^## (L[0-9]+)\b")
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        match = pattern.match(line)
        if match:
            rules.add(match.group(1))
    return rules


def sort_rules(rules: set[str]) -> list[str]:
    return sorted(rules, key=lambda item: int(item[1:]))


def intish(value, default: int = 0) -> int:
    try:
        return int(value)
    except Exception:
        return default


def pct(numer: int, denom: int) -> int:
    if denom <= 0:
        return 100
    return max(0, min(100, round((numer / denom) * 100)))


def status_for_score(score: int) -> str:
    if score >= GREEN_MIN:
        return "green"
    if score >= YELLOW_MIN:
        return "yellow"
    return "red"


def axis(name: str, score: int, status: str | None = None, **details) -> dict:
    score = max(0, min(100, int(score)))
    return {
        "name": name,
        "score": score,
        "status": status or status_for_score(score),
        "weight": AXIS_WEIGHTS[name],
        **details,
    }


def run_json(cmd: list[str], timeout: int = 8):
    try:
        out = subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL, timeout=timeout)
        return json.loads(out)
    except Exception:
        return None


def loop_sessions(args: argparse.Namespace) -> list[dict]:
    loops_dir = Path(args.loops_dir).expanduser()
    sessions: dict[str, dict] = {}
    for path in sorted(loops_dir.glob("*.json")):
        data = load_json(path, {})
        if data.get("active") is False:
            continue
        session = data.get("session") or path.stem
        if args.session and session != args.session:
            continue
        repo = data.get("repo_path") or data.get("repo") or data.get("project_path")
        sessions[session] = {
            "session": session,
            "repo": str(Path(str(repo)).expanduser()) if repo else "",
            "orchestrator_pane": intish(data.get("orchestrator_pane") or 1, 1),
            "loop_file": str(path),
        }

    root = Path(args.root).expanduser()
    if root.exists():
        for candidate in sorted(root.iterdir()):
            if not candidate.is_dir():
                continue
            loop = candidate / ".flywheel" / "loop.json"
            if not loop.exists():
                continue
            data = load_json(loop, {})
            session = data.get("session") or candidate.name
            if args.session and session != args.session:
                continue
            sessions.setdefault(
                session,
                {
                    "session": session,
                    "repo": str(candidate),
                    "orchestrator_pane": intish(data.get("orchestrator_pane") or 1, 1),
                    "loop_file": str(loop),
                },
            )
    return sorted(sessions.values(), key=lambda row: row["session"])


def axis_l_rules(repo: Path, canonical_rules: set[str]) -> dict:
    target_rules = read_l_rules(repo / "AGENTS.md")
    missing = sort_rules(canonical_rules - target_rules)
    score = pct(len(canonical_rules) - len(missing), len(canonical_rules))
    return axis(
        "canonical_l_rule_coverage",
        score,
        canonical_rule_count=len(canonical_rules),
        target_rule_count=len(target_rules),
        missing_rules=missing,
        missing_count=len(missing),
    )


def axis_agents_mtime(repo: Path, now_epoch: int) -> dict:
    path = repo / "AGENTS.md"
    if not path.exists():
        return axis("agents_mtime_age", 0, "red", path=str(path), age_seconds=None, reason="missing")
    age = max(0, now_epoch - int(path.stat().st_mtime))
    week = 7 * 24 * 3600
    score = 100 if age <= week else max(0, 100 - round(((age - week) / week) * 100))
    return axis("agents_mtime_age", score, path=str(path), age_seconds=age, fresh_threshold_seconds=week)


def axis_meta_rule_cache(repo: Path, now_epoch: int) -> dict:
    path = repo / ".flywheel" / "META-RULE-CACHE.md"
    if not path.exists():
        return axis("meta_rule_cache_freshness", 0, "red", path=str(path), age_seconds=None, reason="missing")
    age = max(0, now_epoch - int(path.stat().st_mtime))
    day = 24 * 3600
    score = 100 if age <= day else max(0, 100 - round(((age - day) / day) * 100))
    return axis("meta_rule_cache_freshness", score, path=str(path), age_seconds=age, fresh_threshold_seconds=day)


def axis_mission_lock(repo: Path) -> dict:
    probe = Path("/Users/josh/Developer/flywheel/.flywheel/scripts/mission-lock-age-probe.sh")
    if not probe.exists():
        return axis("mission_lock_age", 60, "yellow", reason="mission_lock_probe_missing")
    out = run_json([str(probe), "--repo", str(repo), "--doctor", "--json"], timeout=5)
    if not isinstance(out, dict):
        return axis("mission_lock_age", 60, "yellow", reason="mission_lock_probe_invalid")
    status = out.get("mission_lock_status") or out.get("state") or "unknown"
    score = {
        "fresh": 100,
        "stale-warn": 70,
        "stale-error": 25,
        "unlocked": 0,
        "missing": 0,
    }.get(str(status), 60)
    return axis(
        "mission_lock_age",
        score,
        mission_lock_status=status,
        mission_lock_age_hours=out.get("mission_lock_age_hours"),
        lock_hash_matches_lock_log=out.get("lock_hash_matches_lock_log"),
    )


def doctor_fixture(args: argparse.Namespace, session: str):
    if not args.doctor_fixture_dir:
        return None
    path = Path(args.doctor_fixture_dir).expanduser() / f"{session}.json"
    return load_json(path, None) if path.exists() else None


def doctor_doc(args: argparse.Namespace, session: str, repo: Path):
    fixture = doctor_fixture(args, session)
    if fixture is not None:
        return fixture
    if os.environ.get("FLYWHEEL_CONFORMANCE_SKIP_DOCTOR"):
        return {"skipped": True, "reason": "recursive_doctor_guard"}
    loop_bin = "/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop"
    if not Path(loop_bin).exists():
        return {"status": "warn", "errors": [], "warnings": [{"code": "flywheel_loop_missing"}]}
    return run_json([loop_bin, "doctor", "--repo", str(repo), "--json"], timeout=8) or {
        "status": "warn",
        "errors": [],
        "warnings": [{"code": "doctor_probe_failed"}],
    }


def axis_doctor(doc: dict) -> dict:
    if doc.get("skipped"):
        return axis("doctor_status", 100, "green", skipped=True, reason=doc.get("reason"))
    errors = doc.get("errors") if isinstance(doc.get("errors"), list) else []
    warnings = doc.get("warnings") if isinstance(doc.get("warnings"), list) else []
    status = str(doc.get("status") or "")
    if errors or status == "fail":
        score = 0
    elif warnings or status in {"warn", "interrupt"}:
        score = 70
    else:
        score = 100
    return axis("doctor_status", score, doctor_status=status or "unknown", error_count=len(errors), warning_count=len(warnings))


def axis_identity(doc: dict) -> dict:
    if doc.get("skipped"):
        return axis("identity_drift", 100, "green", skipped=True, reason=doc.get("reason"))
    fields = {
        "identity_registry_drift": intish(doc.get("identity_registry_drift")),
        "fleet_identity_drift_count": intish(doc.get("fleet_identity_drift_count")),
        "orchestrator_unknown_worker_identity_count": intish(doc.get("orchestrator_unknown_worker_identity_count")),
        "identity_token_orphan_local": intish(doc.get("identity_token_orphan_local")),
        "agentmail_orphan_session_rows_count": intish(doc.get("agentmail_orphan_session_rows_count")),
    }
    total = sum(fields.values())
    score = 100 if total == 0 else max(0, 100 - min(100, total * 25))
    return axis("identity_drift", score, drift_total=total, **fields)


def score_session(args: argparse.Namespace, session: dict, canonical_rules: set[str], now_epoch: int) -> dict:
    repo = Path(session["repo"]).expanduser()
    doc = doctor_doc(args, session["session"], repo)
    axes = [
        axis_l_rules(repo, canonical_rules),
        axis_doctor(doc),
        axis_identity(doc),
        axis_meta_rule_cache(repo, now_epoch),
        axis_mission_lock(repo),
        axis_agents_mtime(repo, now_epoch),
    ]
    weight_total = sum(int(a["weight"]) for a in axes)
    composite = round(sum(int(a["score"]) * int(a["weight"]) for a in axes) / weight_total) if weight_total else 0
    status = status_for_score(composite)
    return {
        **session,
        "repo_exists": repo.exists(),
        "score": composite,
        "status": status,
        "axes": axes,
        "red_axes": [a["name"] for a in axes if a["status"] == "red"],
        "yellow_axes": [a["name"] for a in axes if a["status"] == "yellow"],
    }


def packet_for(row: dict) -> str:
    red_axes = ",".join(row.get("red_axes") or ["none"])
    return (
        "CONFORMANCE-DRIFT "
        f"session={row['session']} score={row['score']} status={row['status']} "
        f"repo={row.get('repo','')} red_axes={red_axes} "
        "action=repair_fleet_conformance_axes"
    )


def send_packets(rows: list[dict], args: argparse.Namespace) -> list[dict]:
    actions = []
    for row in rows:
        if row["status"] != "red":
            continue
        packet = packet_for(row)
        action = {
            "type": "xpane_conformance_drift",
            "session": row["session"],
            "pane": row.get("orchestrator_pane") or 1,
            "packet": packet,
            "dry_run": bool(args.dry_run or not args.apply),
        }
        if args.apply and not args.dry_run:
            try:
                subprocess.check_call(
                    [args.ntm, "send", row["session"], f"--pane={action['pane']}", "--no-cass-check", packet],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    timeout=5,
                )
                action["sent"] = True
            except Exception as exc:
                action["sent"] = False
                action["error"] = str(exc)
        actions.append(action)
    return actions


def build_payload(args: argparse.Namespace) -> dict:
    now_epoch = int(args.now_epoch or time.time())
    canonical_rules = read_l_rules(Path(args.canonical_agents).expanduser())
    sessions = loop_sessions(args)
    rows = [score_session(args, session, canonical_rules, now_epoch) for session in sessions]
    green = sum(1 for row in rows if row["status"] == "green")
    yellow = sum(1 for row in rows if row["status"] == "yellow")
    red = sum(1 for row in rows if row["status"] == "red")
    worst = min(rows, key=lambda row: row["score"], default=None)
    actions = send_packets(rows, args)
    payload = {
        "schema_version": SCHEMA_VERSION,
        "status": "pass" if red == 0 else "fail",
        "mode": "doctor" if args.doctor else "fleet",
        "checked_at_epoch": now_epoch,
        "thresholds": {"green_min_score": GREEN_MIN, "yellow_min_score": YELLOW_MIN},
        "axes_implemented": list(AXIS_WEIGHTS.keys()),
        "axis_weights": AXIS_WEIGHTS,
        "canonical_agents": str(Path(args.canonical_agents).expanduser()),
        "canonical_rule_count": len(canonical_rules),
        "fleet_conformance_green_count": green,
        "fleet_conformance_yellow_count": yellow,
        "fleet_conformance_red_count": red,
        "fleet_conformance_total_count": len(rows),
        "fleet_conformance_min_score": worst["score"] if worst else None,
        "fleet_conformance_worst_session": worst["session"] if worst else None,
        "fleet_conformance": rows,
        "planned_packets": actions,
    }
    return payload


def emit_info() -> None:
    emit(
        {
            "schema_version": SCHEMA_VERSION,
            "purpose": "Compute one bounded fleet conformance score per flywheel session.",
            "donella_leverage_points": [5, 6],
            "anti_agent_shaming": True,
            "mutates_only_with": "--apply without --dry-run",
            "cache_ttl_seconds_default": 60,
            "canonical_cli_flags": [
                "--json",
                "--fleet",
                "--session=<name>",
                "--apply",
                "--dry-run",
                "--doctor",
                "--info",
                "--examples",
                "--schema",
            ],
            "axes": list(AXIS_WEIGHTS.keys()),
        }
    )


def emit_schema() -> None:
    emit(
        {
            "schema_version": SCHEMA_VERSION,
            "type": "object",
            "required": [
                "fleet_conformance",
                "fleet_conformance_red_count",
                "fleet_conformance_yellow_count",
                "fleet_conformance_green_count",
                "fleet_conformance_worst_session",
                "fleet_conformance_min_score",
            ],
            "properties": {
                "fleet_conformance": {"type": "array"},
                "fleet_conformance_red_count": {"type": "integer"},
                "fleet_conformance_yellow_count": {"type": "integer"},
                "fleet_conformance_green_count": {"type": "integer"},
                "fleet_conformance_worst_session": {"type": ["string", "null"]},
                "fleet_conformance_min_score": {"type": ["integer", "null"]},
            },
        }
    )


def emit_examples() -> None:
    print("\n".join(
        [
            ".flywheel/scripts/fleet-conformance-probe.sh --fleet --json",
            ".flywheel/scripts/fleet-conformance-probe.sh --session flywheel --json",
            ".flywheel/scripts/fleet-conformance-probe.sh --fleet --apply --dry-run --json",
            "FLYWHEEL_CONFORMANCE_SKIP_DOCTOR=1 .flywheel/scripts/fleet-conformance-probe.sh --doctor --json",
        ]
    ))


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(add_help=True)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--fleet", action="store_true")
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--session")
    parser.add_argument("--root", default=str(DEFAULT_ROOT))
    parser.add_argument("--loops-dir", default=str(DEFAULT_LOOPS_DIR))
    parser.add_argument("--canonical-agents", default=str(DEFAULT_CANONICAL))
    parser.add_argument("--cache-dir", default=str(DEFAULT_CACHE_DIR))
    parser.add_argument("--cache-ttl", type=int, default=60)
    parser.add_argument("--no-cache", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--ntm", default=DEFAULT_NTM)
    parser.add_argument("--doctor-fixture-dir")
    parser.add_argument("--now-epoch", type=int)
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--schema", action="store_true")
    args = parser.parse_args(argv)
    args.root = Path(args.root)
    args.loops_dir = Path(args.loops_dir)
    args.canonical_agents = Path(args.canonical_agents)
    args.cache_dir = Path(args.cache_dir)
    if args.doctor:
        args.fleet = True
    return args


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    if args.info:
        emit_info()
        return 0
    if args.schema:
        emit_schema()
        return 0
    if args.examples:
        emit_examples()
        return 0

    now_epoch = int(args.now_epoch or time.time())
    path = cache_path(args)
    if not args.no_cache and not args.apply and cache_fresh(path, args.cache_ttl, now_epoch):
        payload = load_json(path, None)
        if isinstance(payload, dict):
            payload["cache_hit"] = True
            emit(payload)
            return 0 if payload.get("status") != "fail" else 1

    payload = build_payload(args)
    payload["cache_hit"] = False
    if not args.no_cache and not args.apply:
        write_json(path, payload)
    emit(payload)
    return 0 if payload.get("status") != "fail" else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY
