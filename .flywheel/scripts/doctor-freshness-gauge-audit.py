#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


SCHEMA_VERSION = "flywheel.doctor_freshness_gauge_audit.v1"


def load_json_fixture(env_name: str) -> dict | None:
    path = os.environ.get(env_name)
    if not path:
        return None
    return json.loads(Path(path).read_text(encoding="utf-8"))


def run_json(cmd: list[str], *, timeout: float = 10.0, env: dict[str, str] | None = None) -> tuple[dict | None, dict | None]:
    try:
        proc = subprocess.run(
            cmd,
            cwd=cmd_env_repo(env),
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return None, {"code": "probe_timeout", "command": cmd, "timeout_seconds": timeout}
    except OSError as exc:
        return None, {"code": "probe_exec_failed", "command": cmd, "message": str(exc)}
    if proc.returncode != 0:
        return None, {
            "code": "probe_nonzero",
            "command": cmd,
            "returncode": proc.returncode,
            "stderr": proc.stderr[-1000:],
        }
    try:
        return json.loads(proc.stdout), None
    except json.JSONDecodeError:
        return None, {"code": "probe_invalid_json", "command": cmd, "stdout": proc.stdout[:1000]}


def cmd_env_repo(env: dict[str, str] | None) -> str | None:
    if not env:
        return None
    return env.get("FLYWHEEL_AUDIT_REPO")


def iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def gauge(name: str, model: str, payload: dict, *, truth_status: str = "unknown", errors: list[dict] | None = None) -> dict:
    return {
        "name": name,
        "model": model,
        "audit_status": "pass" if not errors else "warn",
        "truth_status": truth_status,
        "payload": payload,
        "errors": errors or [],
    }


def classify_truth(status: str | None) -> str:
    if status in {"pass", "ok", "ready", "fresh", "not_applicable", "externalized"}:
        return "pass"
    if status in {"warn", "degraded", "stale-warn"}:
        return "warn"
    if status in {"fail", "blocked", "stale-error", "missing", "unlocked"}:
        return "fail"
    return "unknown"


def josh_requests_gauge(repo: Path, env: dict[str, str]) -> dict:
    fixture = load_json_fixture("FLYWHEEL_AUDIT_JOSH_REQUESTS_FIXTURE")
    if fixture is not None:
        data, error = fixture, None
    else:
        script = repo / ".flywheel/scripts/josh-request-tick-promote.sh"
        data, error = run_json([str(script), "--json"], timeout=10, env=env)
    if error or data is None:
        return gauge("josh_requests", "consumed_vs_queued", {}, truth_status="unknown", errors=[error or {"code": "missing_payload"}])
    has_consumed = "queued_count" in data and "consumed_with_evidence_count" in data and "unread" in data
    errors = [] if has_consumed else [{"code": "CONSUMED_WITH_EVIDENCE_MISSING"}]
    truth = "pass" if int(data.get("unread") or 0) == 0 else "warn"
    return gauge(
        "josh_requests",
        "consumed_vs_queued",
        {
            "queued_count": data.get("queued_count"),
            "unread": data.get("unread"),
            "consumed_with_evidence_count": data.get("consumed_with_evidence_count"),
            "truncated_consumed_requests": data.get("truncated_consumed_requests", False),
        },
        truth_status=truth,
        errors=errors,
    )


def mission_lock_gauge(repo: Path, env: dict[str, str]) -> dict:
    fixture = load_json_fixture("FLYWHEEL_AUDIT_MISSION_LOCK_FIXTURE")
    if fixture is not None:
        data, error = fixture, None
    else:
        script = repo / ".flywheel/scripts/mission-lock-age-probe.sh"
        data, error = run_json([str(script), "--repo", str(repo), "--json"], timeout=10, env=env)
    if error or data is None:
        return gauge("mission_lock_status", "age_plus_content_stability", {}, truth_status="unknown", errors=[error or {"code": "missing_payload"}])
    required = {"mission_lock_age_hours", "lock_hash_matches_body", "lock_hash_matches_lock_log", "mission_lock_status"}
    errors = [] if required.issubset(set(data)) else [{"code": "MISSION_LOCK_CONTENT_STABILITY_FIELDS_MISSING"}]
    return gauge(
        "mission_lock_status",
        "age_plus_content_stability",
        {
            "mission_lock_status": data.get("mission_lock_status") or data.get("state"),
            "mission_lock_age_hours": data.get("mission_lock_age_hours"),
            "lock_hash_matches_body": data.get("lock_hash_matches_body"),
            "lock_hash_matches_lock_log": data.get("lock_hash_matches_lock_log"),
            "warnings": data.get("warnings") or [],
        },
        truth_status=classify_truth(data.get("status") or data.get("mission_lock_status") or data.get("state")),
        errors=errors,
    )


def daily_report_fixture_or_live(repo: Path) -> dict:
    fixture = load_json_fixture("FLYWHEEL_AUDIT_DAILY_REPORT_FIXTURE")
    if fixture is not None:
        return fixture
    reports = sorted((repo / ".flywheel/reports").glob("daily-*.md"))
    if not reports:
        return {
            "status": "fail",
            "daily_report_age_hours": None,
            "latest_report": None,
            "work_since_latest_report_count": None,
            "errors": [{"code": "daily_report_missing"}],
        }
    latest = max(reports, key=lambda path: path.stat().st_mtime)
    mtime = datetime.fromtimestamp(latest.stat().st_mtime, timezone.utc)
    age_hours = round((datetime.now(timezone.utc) - mtime).total_seconds() / 3600, 2)
    proc = subprocess.run(
        ["git", "-C", str(repo), "log", f"--since={mtime.isoformat()}", "--format=%H"],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    work_count = len([line for line in proc.stdout.splitlines() if line.strip()]) if proc.returncode == 0 else None
    status = "fail" if age_hours > 36 else ("warn" if age_hours > 24 else "pass")
    return {
        "status": status,
        "daily_report_age_hours": age_hours,
        "latest_report": str(latest),
        "latest_report_mtime": mtime.isoformat().replace("+00:00", "Z"),
        "work_since_latest_report_count": work_count,
        "errors": [] if status != "fail" else [{"code": "daily_report_age_hours"}],
        "warnings": [] if status == "pass" else [{"code": "daily_report_work_since_report"}],
    }


def daily_report_gauge(repo: Path) -> dict:
    data = daily_report_fixture_or_live(repo)
    has_work_count = "work_since_latest_report_count" in data
    errors = [] if has_work_count else [{"code": "DAILY_REPORT_WORK_SINCE_REPORT_MISSING"}]
    return gauge(
        "daily_report_age_hours",
        "age_plus_work_since_report",
        {
            "status": data.get("status"),
            "daily_report_age_hours": data.get("daily_report_age_hours"),
            "latest_report": data.get("latest_report"),
            "work_since_latest_report_count": data.get("work_since_latest_report_count"),
        },
        truth_status=classify_truth(data.get("status")),
        errors=errors,
    )


def canonical_gauge(repo: Path, env: dict[str, str]) -> dict:
    fixture = load_json_fixture("FLYWHEEL_AUDIT_CANONICAL_ROOT_DRIFT_FIXTURE")
    if fixture is not None:
        root_data, error = fixture, None
    else:
        root_data, error = local_canonical_root_drift(repo), None
    if error or root_data is None:
        return gauge("canonical_doctrine_propagation", "propagation_plus_root_drift", {}, truth_status="unknown", errors=[error or {"code": "missing_payload"}])
    has_root_truth = "canonical_root_drift_count" in root_data and "timed_out" in root_data
    errors = [] if has_root_truth else [{"code": "CANONICAL_ROOT_DRIFT_TRUTH_MISSING"}]
    drift_count = int(root_data.get("canonical_root_drift_count") or 0)
    truth = "pass" if drift_count == 0 and not root_data.get("timed_out") else "fail"
    return gauge(
        "canonical_doctrine_propagation",
        "propagation_plus_root_drift",
        {
            "status": root_data.get("status"),
            "canonical_root_drift_count": root_data.get("canonical_root_drift_count"),
            "root_target_count": root_data.get("root_target_count"),
            "timed_out": root_data.get("timed_out"),
            "classification": root_data.get("classification"),
        },
        truth_status=truth,
        errors=errors,
    )


def extract_canonical_block(text: str) -> str | None:
    begin = "<!-- BEGIN-CANONICAL-FLYWHEEL-DOCTRINE -->"
    end = "<!-- END-CANONICAL-FLYWHEEL-DOCTRINE -->"
    if begin not in text or end not in text:
        return None
    after = text.split(begin, 1)[1]
    return after.split(end, 1)[0].strip()


def local_canonical_root_drift(repo: Path) -> dict:
    source = repo / ".flywheel/AGENTS-CANONICAL.md"
    target = repo / "AGENTS.md"
    if not source.exists() or not target.exists():
        return {
            "status": "not_applicable",
            "canonical_root_drift_count": 0,
            "root_target_count": 0,
            "timed_out": False,
            "classification": "local_root_missing",
        }
    source_text = source.read_text(encoding="utf-8", errors="ignore").strip()
    target_text = target.read_text(encoding="utf-8", errors="ignore")
    block = extract_canonical_block(target_text)
    drift = block is None or block != source_text
    return {
        "status": "fail" if drift else "pass",
        "canonical_root_drift_count": 1 if drift else 0,
        "root_target_count": 1,
        "timed_out": False,
        "classification": "local_root_block_compare",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit doctor freshness gauges for consumed-vs-queued truth.")
    parser.add_argument("--repo", default=os.getcwd())
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    repo = Path(args.repo).expanduser().resolve()
    env = os.environ.copy()
    env["FLYWHEEL_AUDIT_REPO"] = str(repo)
    gauges = [
        josh_requests_gauge(repo, env),
        mission_lock_gauge(repo, env),
        daily_report_gauge(repo),
        canonical_gauge(repo, env),
    ]
    audit_failure_codes = [
        error["code"]
        for item in gauges
        for error in item.get("errors", [])
    ]
    truth_counts = {
        "pass": sum(1 for item in gauges if item["truth_status"] == "pass"),
        "warn": sum(1 for item in gauges if item["truth_status"] == "warn"),
        "fail": sum(1 for item in gauges if item["truth_status"] == "fail"),
        "unknown": sum(1 for item in gauges if item["truth_status"] == "unknown"),
    }
    payload = {
        "schema_version": SCHEMA_VERSION,
        "checked_at": iso_now(),
        "repo": str(repo),
        "status": "pass" if not audit_failure_codes else "fail",
        "required_gauge_count": 4,
        "audited_gauge_count": len(gauges),
        "audit_failure_codes": audit_failure_codes,
        "truth_status_counts": truth_counts,
        "gauges": gauges,
    }
    if args.json:
        print(json.dumps(payload, separators=(",", ":")))
    else:
        print(f"status={payload['status']} gauges={len(gauges)} audit_failures={len(audit_failure_codes)} truth={truth_counts}")
    return 0 if payload["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
