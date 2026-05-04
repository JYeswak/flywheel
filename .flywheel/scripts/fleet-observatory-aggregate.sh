#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

SCHEMA_VERSION = "fleet-observatory-aggregate/v1"
DEFAULT_DOCTOR = "/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop"
DEFAULT_CACHE = Path.home() / ".local/state/flywheel/fleet-observatory/doctor-cache.json"
WEIGHTS = {
    "productivity": 10,
    "conformance": 15,
    "comms": 10,
    "process_gaps": 15,
    "architecture": 15,
    "identity_drift": 10,
    "l_rule_lag": 15,
    "watcher_coverage": 10,
}


def clamp(value: float) -> int:
    return max(0, min(100, round(value)))


def status(score: int) -> str:
    if score >= 85:
        return "green"
    if score >= 60:
        return "yellow"
    return "red"


def icon(state: str, no_emoji: bool) -> str:
    if no_emoji:
        return {"green": "GREEN", "yellow": "YELLOW", "red": "RED"}.get(state, "UNKNOWN")
    return {"green": "🟢", "yellow": "🟡", "red": "🔴"}.get(state, "⚪")


def load_json(path: Path):
    try:
        with path.open() as f:
            return json.load(f)
    except Exception:
        return None


def write_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + f".tmp.{os.getpid()}")
    tmp.write_text(json.dumps(data, separators=(",", ":"), sort_keys=True), encoding="utf-8")
    tmp.replace(path)


def run_doctor(args: argparse.Namespace) -> dict:
    if args.doctor_json:
        data = load_json(Path(args.doctor_json).expanduser())
        if isinstance(data, dict):
            return data
        return {"status": "warn", "warnings": [{"code": "doctor_fixture_invalid_json"}]}

    cache = Path(args.cache).expanduser()
    now = int(time.time())
    if not args.no_cache and cache.exists() and now - int(cache.stat().st_mtime) <= args.cache_ttl:
        data = load_json(cache)
        if isinstance(data, dict):
            data["_fleet_observatory_cache_hit"] = True
            return data

    try:
        out = subprocess.check_output(
            [args.doctor_bin, "doctor", "--repo", args.repo, "--json"],
            text=True,
            stderr=subprocess.DEVNULL,
            timeout=args.timeout,
            env={**os.environ, "FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED": "1"},
        )
        data = json.loads(out)
    except Exception as exc:
        cached = load_json(cache)
        if isinstance(cached, dict):
            cached["_fleet_observatory_cache_hit"] = True
            cached["_fleet_observatory_cache_stale"] = True
            cached["_fleet_observatory_doctor_error"] = str(exc)
            return cached
        data = {"status": "warn", "warnings": [{"code": "doctor_unavailable", "message": str(exc)}]}
    if not args.no_cache:
        write_json(cache, data)
    return data


def intish(value, default=0) -> int:
    try:
        if value is None:
            return default
        return int(value)
    except Exception:
        return default


def floatish(value, default=0.0) -> float:
    try:
        if value is None:
            return default
        return float(value)
    except Exception:
        return default


def ratio_score(numer, denom) -> int:
    denom = intish(denom)
    if denom <= 0:
        return 100
    return clamp((intish(numer) / denom) * 100)


def spine(name: str, score: int, summary: str, **detail) -> dict:
    return {"name": name, "score": clamp(score), "status": status(clamp(score)), "summary": summary, **detail}


def aggregate(doc: dict) -> dict:
    prod_score = ratio_score(doc.get("peer_orch_productive_count"), doc.get("peer_orch_productivity_total_count"))
    conformance_score = intish(doc.get("fleet_conformance_min_score"), 100)
    comms_score = intish(doc.get("fleet_comms_min_score"), 100)
    process_open = intish(doc.get("fleet_process_open_gap_count"))
    process_score = clamp(100 - process_open * 10)
    rework = floatish((doc.get("fleet_metrics") or {}).get("rework_ratio"))
    architecture_score = clamp(100 - rework * 100)
    identity_count = intish(doc.get("fleet_identity_drift_count"))
    identity_score = clamp(100 - identity_count * 25)
    lag_count = intish(doc.get("fleet_repo_l_rule_lag_count"))
    lag_score = clamp(100 - lag_count * 5)
    watcher_score = ratio_score(doc.get("fleet_watcher_coverage_count"), doc.get("fleet_watcher_coverage_total"))

    spines = [
        spine("productivity", prod_score, f"{intish(doc.get('peer_orch_productive_count'))}/{intish(doc.get('peer_orch_productivity_total_count'))} productive"),
        spine("conformance", conformance_score, f"yellow={intish(doc.get('fleet_conformance_yellow_count'))} worst={doc.get('fleet_conformance_worst_session') or 'none'}:{conformance_score}", worst_session=doc.get("fleet_conformance_worst_session")),
        spine("comms", comms_score, f"silent={intish(doc.get('fleet_comms_silent_session_count'))} stale={intish(doc.get('fleet_comms_token_stale_count'))}", worst_session=doc.get("fleet_comms_worst_session")),
        spine("process_gaps", process_score, f"open={process_open} top={doc.get('fleet_process_top_gap_class') or 'none'}", top_gap=doc.get("fleet_process_top_gap_class")),
        spine("architecture", architecture_score, f"rework={rework:.2f} dispose={floatish((doc.get('fleet_metrics') or {}).get('founder_dispose_pct')):.2f}"),
        spine("identity_drift", identity_score, f"count={identity_count}"),
        spine("l_rule_lag", lag_score, f"{lag_count} repos lagging"),
        spine("watcher_coverage", watcher_score, f"{intish(doc.get('fleet_watcher_coverage_count'))}/{intish(doc.get('fleet_watcher_coverage_total'))} covered"),
    ]
    weighted = round(sum(s["score"] * WEIGHTS[s["name"]] for s in spines) / sum(WEIGHTS.values()))
    worst_spine = min(spines, key=lambda item: item["score"])
    worst_session = (
        doc.get("fleet_conformance_worst_session")
        or doc.get("fleet_comms_worst_session")
        or "none"
    )
    process_gaps = []
    detector = doc.get("fleet_process_gap_detector")
    if isinstance(detector, dict):
        process_gaps = [str(item.get("class")) for item in detector.get("top_gaps", [])[:3] if isinstance(item, dict)]
    if not process_gaps and doc.get("fleet_process_top_gap_class"):
        process_gaps = [str(doc.get("fleet_process_top_gap_class"))]
    recommended = recommendation(worst_spine, worst_session)
    return {
        "schema_version": SCHEMA_VERSION,
        "status": status(weighted),
        "fleet_overall_health_score": weighted,
        "weights": WEIGHTS,
        "spines": spines,
        "spines_aggregated": len(spines),
        "worst_spine": worst_spine["name"],
        "worst_spine_score": worst_spine["score"],
        "worst_session": worst_session,
        "top_process_gaps": process_gaps[:3],
        "recommended_action": recommended,
        "source_doctor_cache_hit": bool(doc.get("_fleet_observatory_cache_hit")),
        "source_doctor_status": doc.get("status"),
    }


def recommendation(worst: dict, worst_session: str) -> str:
    name = worst["name"]
    if name == "productivity":
        return "Dispatch or unblock idle orchestrators with work available."
    if name == "conformance":
        return f"Send CONFORMANCE-DRIFT to {worst_session} and repair red axes."
    if name == "comms":
        return f"Ping or repair fleet comms for {worst_session}."
    if name == "process_gaps":
        return "Route top process gap to a structural fix-bead."
    if name == "architecture":
        return "Inspect rework/dispose drivers before adding new process."
    if name == "identity_drift":
        return "Repair identity registry drift and orphan-token scope."
    if name == "l_rule_lag":
        return "Run canonical doctrine sync/backfill for lagging repos."
    return "Restore watcher coverage for missing sessions."


def bar(score: int, width: int = 10) -> str:
    filled = round((score / 100) * width)
    return "█" * filled + "░" * (width - filled)


def render(payload: dict, no_emoji: bool = False) -> str:
    lines = [
        f"🚀 FLEET OBSERVATORY — {time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}" if not no_emoji else f"FLEET OBSERVATORY — {time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}",
        "",
        f"OVERALL HEALTH: {payload['fleet_overall_health_score']}/100  [{bar(payload['fleet_overall_health_score'])}]  status: {payload['status']}",
        "",
        "╔═══ MEASUREMENT SPINES ═══════════════════╗",
    ]
    labels = {
        "productivity": "Productivity",
        "conformance": "Conformance",
        "comms": "Comms",
        "process_gaps": "Process gaps",
        "architecture": "Architecture",
        "identity_drift": "Identity drift",
        "l_rule_lag": "L-rule lag",
        "watcher_coverage": "Watcher coverage",
    }
    for item in payload["spines"]:
        label = labels[item["name"]]
        text = f"{label:<16}{icon(item['status'], no_emoji)} {item['summary']}"
        lines.append(f"║ {text:<39}║")
    lines.extend([
        "╚═══════════════════════════════════════════╝",
        "",
        f"WORST SESSION: {payload['worst_session']} (score={payload['worst_spine_score']}, top issue={payload['worst_spine']})",
        f"TOP 3 PROCESS GAPS: {', '.join(payload['top_process_gaps']) if payload['top_process_gaps'] else 'none'}",
        f"RECOMMENDED ACTION: {payload['recommended_action']}",
    ])
    return "\n".join(lines[:50])


def emit_info() -> None:
    print(json.dumps({
        "schema_version": SCHEMA_VERSION,
        "purpose": "Strategic single-pane fleet health dashboard over eight doctor spines.",
        "canonical_cli_flags": ["--info", "--examples", "--schema", "--json", "--watch=Ns"],
        "doctor_field": "fleet_observatory_health_score",
        "anti_agent_shaming": True,
        "weights": WEIGHTS,
    }, separators=(",", ":"), sort_keys=True))


def emit_schema() -> None:
    print(json.dumps({
        "schema_version": SCHEMA_VERSION,
        "type": "object",
        "required": ["fleet_overall_health_score", "spines", "worst_spine", "worst_session", "recommended_action"],
        "properties": {
            "fleet_overall_health_score": {"type": "integer", "minimum": 0, "maximum": 100},
            "spines": {"type": "array"},
            "worst_spine": {"type": "string"},
            "worst_session": {"type": "string"},
            "recommended_action": {"type": "string"},
        },
    }, separators=(",", ":"), sort_keys=True))


def emit_examples() -> None:
    print("\n".join([
        ".flywheel/scripts/fleet-observatory-aggregate.sh",
        ".flywheel/scripts/fleet-observatory-aggregate.sh --json",
        ".flywheel/scripts/fleet-observatory-aggregate.sh --doctor-json /tmp/doctor.json --json",
        ".flywheel/scripts/fleet-observatory-aggregate.sh --watch=30s",
    ]))


def parse_watch(value: str | None) -> int:
    if not value:
        return 0
    text = value.strip().lower()
    if text.endswith("s"):
        text = text[:-1]
    return max(1, int(text))


def parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--json", action="store_true")
    p.add_argument("--info", action="store_true")
    p.add_argument("--examples", action="store_true")
    p.add_argument("--schema", action="store_true")
    p.add_argument("--repo", default="/Users/josh/Developer/flywheel")
    p.add_argument("--doctor-bin", default=DEFAULT_DOCTOR)
    p.add_argument("--doctor-json")
    p.add_argument("--cache", default=str(DEFAULT_CACHE))
    p.add_argument("--cache-ttl", type=int, default=60)
    p.add_argument("--no-cache", action="store_true")
    p.add_argument("--timeout", type=int, default=45)
    p.add_argument("--watch")
    p.add_argument("--no-emoji", action="store_true")
    return p.parse_args(argv)


def run_once(args: argparse.Namespace) -> int:
    payload = aggregate(run_doctor(args))
    if args.json:
        print(json.dumps(payload, separators=(",", ":"), sort_keys=True))
    else:
        print(render(payload, args.no_emoji))
    return 0 if payload["status"] != "red" else 1


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    if args.info:
        emit_info(); return 0
    if args.schema:
        emit_schema(); return 0
    if args.examples:
        emit_examples(); return 0
    interval = parse_watch(args.watch)
    if interval:
        while True:
            run_once(args)
            sys.stdout.flush()
            time.sleep(interval)
    return run_once(args)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY
