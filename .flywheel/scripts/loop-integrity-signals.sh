#!/usr/bin/env bash
# loop-integrity-signals.sh — bounded validator for the three loop-integrity
# freshness signals, scoped to one --project at a time.
#
# Signals (all separately computed, never conflated):
#   marker_fresh           ~/.flywheel/loops/<project>.json fleet writeback
#   callback_receipt_fresh <repo>/.flywheel/dispatch-log.jsonl callback_received_at
#   canonical_bridge_fresh ~/.local/state/flywheel-loop/last_tick_<project>.json
#
# This script is the canonical surface owned by bead flywheel-2xdi.15.1.
# flywheel-dwmb.1 owns the narrower receipt-mirror/full-doctor split and is
# preserved unchanged.
#
# Usage:
#   loop-integrity-signals.sh --project mobile-eats [--json]
#   loop-integrity-signals.sh --project mobile-eats --window-seconds 1800 --json
#   loop-integrity-signals.sh --info --json
#   loop-integrity-signals.sh --schema --json
#   loop-integrity-signals.sh --doctor --json     # self-check on this script
#   loop-integrity-signals.sh --help
set -uo pipefail

VERSION="loop-integrity-signals.v1"
SCRIPT_VERSION="2026-05-09.1"

PROJECT=""
REPO_OVERRIDE=""
WINDOW_SECONDS=""
MODE="probe"
JSON=0
TIMEOUT_SEC=5

usage() {
  cat <<'USAGE'
Usage:
  loop-integrity-signals.sh --project <name> [--repo <path>] [--window-seconds N] [--json]
  loop-integrity-signals.sh --doctor [--json]
  loop-integrity-signals.sh --info [--json]
  loop-integrity-signals.sh --schema [--json]
  loop-integrity-signals.sh --help

Bounded validator (<=5s) for the three freshness surfaces of an active flywheel
loop project. Reports marker_fresh, callback_receipt_fresh, and
canonical_bridge_fresh as independent verdicts so a fresh marker cannot mask a
stale callback or stale canonical bridge.

Default --window-seconds is 2x the marker's interval (or 1800s if absent).
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT="${2:-}"; shift 2 ;;
    --project=*) PROJECT="${1#*=}"; shift ;;
    --repo) REPO_OVERRIDE="${2:-}"; shift 2 ;;
    --repo=*) REPO_OVERRIDE="${1#*=}"; shift ;;
    --window-seconds) WINDOW_SECONDS="${2:-}"; shift 2 ;;
    --window-seconds=*) WINDOW_SECONDS="${1#*=}"; shift ;;
    --doctor) MODE="doctor"; shift ;;
    --info) MODE="info"; shift ;;
    --schema) MODE="schema"; shift ;;
    --json) JSON=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "loop-integrity-signals.sh: unknown arg: $1" >&2; usage >&2; exit 64 ;;
  esac
done

run_python() {
  python3 - "$VERSION" "$SCRIPT_VERSION" "$MODE" "$PROJECT" "$REPO_OVERRIDE" "$WINDOW_SECONDS" "$JSON" "$TIMEOUT_SEC" <<'PY'
from __future__ import annotations

import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

(
    VERSION,
    SCRIPT_VERSION,
    MODE,
    PROJECT,
    REPO_OVERRIDE,
    WINDOW_RAW,
    JSON_RAW,
    TIMEOUT_RAW,
) = sys.argv[1:]
JSON_OUT = JSON_RAW == "1"
TIMEOUT_SEC = int(TIMEOUT_RAW) if TIMEOUT_RAW.isdigit() else 5

SIGNAL_NAMES = ("marker_fresh", "callback_receipt_fresh", "canonical_bridge_fresh")
HOME = Path.home()
LOOPS_DIR = HOME / ".flywheel/loops"
BRIDGE_DIR = HOME / ".local/state/flywheel-loop"


def emit(payload: dict) -> int:
    if JSON_OUT or MODE in ("info", "schema"):
        sys.stdout.write(json.dumps(payload, sort_keys=True) + "\n")
    else:
        for key in ("project", "window_seconds", "verdict"):
            if key in payload:
                sys.stdout.write(f"{key}={payload[key]}\n")
        for name in SIGNAL_NAMES:
            sig = (payload.get("signals") or {}).get(name) or {}
            sys.stdout.write(
                f"{name} ok={sig.get('ok')} evidence={sig.get('evidence')}\n"
            )
    return 0 if payload.get("status") == "ok" else 1


def parse_iso_epoch(value):
    if value in (None, "", 0):
        return None
    if isinstance(value, (int, float)):
        return float(value)
    text = str(value).strip()
    if not text:
        return None
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    try:
        return datetime.fromisoformat(text).timestamp()
    except Exception:
        return None


def parse_interval_seconds(raw) -> int:
    if raw is None:
        return 0
    if isinstance(raw, (int, float)):
        return int(raw)
    text = str(raw).strip().lower()
    if text.isdigit():
        return int(text)
    units = {"s": 1, "m": 60, "h": 3600, "d": 86400}
    if len(text) >= 2 and text[-1] in units and text[:-1].isdigit():
        return int(text[:-1]) * units[text[-1]]
    return 0


def read_json(path: Path) -> dict:
    try:
        text = path.read_text(errors="replace")
        return json.loads(text)
    except Exception:
        return {}


def repo_for(project: str, override: str) -> Path:
    if override:
        return Path(override)
    marker = read_json(LOOPS_DIR / f"{project}.json") or {}
    repo = str(marker.get("repo") or "").strip()
    if repo:
        return Path(repo)
    return Path("/Users/josh/Developer") / project


def signal_marker_fresh(project: str, window_sec: int) -> dict:
    path = LOOPS_DIR / f"{project}.json"
    name = "marker_fresh"
    if not path.exists():
        return {"name": name, "ok": False, "evidence": f"missing={path}"}
    data = read_json(path) or {}
    last_tick = parse_iso_epoch(data.get("last_tick"))
    writeback = parse_iso_epoch(data.get("writeback_updated_at"))
    candidates = [v for v in (last_tick, writeback) if v is not None]
    try:
        candidates.append(path.stat().st_mtime)
    except Exception:
        pass
    if not candidates:
        return {"name": name, "ok": False, "evidence": "no_timestamps"}
    newest = max(candidates)
    age = int(time.time() - newest)
    return {
        "name": name,
        "ok": age <= window_sec,
        "evidence": f"path={path} age_sec={age} window_sec={window_sec} last_tick={data.get('last_tick')}",
    }


def signal_callback_receipt_fresh(project: str, repo: Path, window_sec: int) -> dict:
    name = "callback_receipt_fresh"
    log_path = repo / ".flywheel/dispatch-log.jsonl"
    if not log_path.exists():
        return {"name": name, "ok": False, "evidence": f"missing={log_path}"}
    deadline = time.time() + TIMEOUT_SEC
    newest_epoch = None
    try:
        with log_path.open("r", errors="replace") as fh:
            for line in fh:
                if time.time() > deadline:
                    return {
                        "name": name,
                        "ok": False,
                        "evidence": f"timeout_after_{TIMEOUT_SEC}s reading={log_path}",
                    }
                line = line.strip()
                if not line or '"callback_received_at"' not in line:
                    continue
                try:
                    row = json.loads(line)
                except Exception:
                    continue
                if not isinstance(row, dict):
                    continue
                epoch = parse_iso_epoch(row.get("callback_received_at"))
                if epoch is None:
                    continue
                if newest_epoch is None or epoch > newest_epoch:
                    newest_epoch = epoch
    except Exception as exc:
        return {"name": name, "ok": False, "evidence": f"read_failed={exc}"}
    if newest_epoch is None:
        return {"name": name, "ok": False, "evidence": f"no_callback_received_at in={log_path}"}
    age = int(time.time() - newest_epoch)
    return {
        "name": name,
        "ok": age <= window_sec,
        "evidence": f"path={log_path} age_sec={age} window_sec={window_sec}",
    }


def signal_canonical_bridge_fresh(project: str, window_sec: int) -> dict:
    name = "canonical_bridge_fresh"
    path = BRIDGE_DIR / f"last_tick_{project}.json"
    if not path.exists():
        return {"name": name, "ok": False, "evidence": f"missing={path}"}
    data = read_json(path) or {}
    ts_field = parse_iso_epoch(data.get("ts"))
    candidates = [ts_field] if ts_field is not None else []
    try:
        candidates.append(path.stat().st_mtime)
    except Exception:
        pass
    if not candidates:
        return {"name": name, "ok": False, "evidence": "no_timestamps"}
    newest = max(candidates)
    age = int(time.time() - newest)
    return {
        "name": name,
        "ok": age <= window_sec,
        "evidence": (
            f"path={path} age_sec={age} window_sec={window_sec} "
            f"ts={data.get('ts')} task_id={data.get('task_id')}"
        ),
    }


def info_payload() -> dict:
    return {
        "version": VERSION,
        "script_version": SCRIPT_VERSION,
        "schema_version": "loop-integrity-signals/v1",
        "signal_names": list(SIGNAL_NAMES),
        "default_window_policy": "2x marker.interval, fallback 1800s",
        "timeout_sec": TIMEOUT_SEC,
        "loops_dir": str(LOOPS_DIR),
        "bridge_dir": str(BRIDGE_DIR),
        "owns_classification": True,
        "preserves_skill": "flywheel-dwmb.1 receipt-mirror/full-doctor split",
        "status": "ok",
        "mode": "info",
    }


def schema_payload() -> dict:
    return {
        "version": VERSION,
        "schema_version": "loop-integrity-signals/v1",
        "signals": {
            name: {
                "type": "object",
                "fields": ["name", "ok", "evidence"],
            }
            for name in SIGNAL_NAMES
        },
        "verdict": {
            "values": ["HEALTHY", "LIMPING", "DEAD"],
            "rule": "0 failed = HEALTHY, 1-2 failed = LIMPING, 3 failed = DEAD",
        },
        "status": "ok",
        "mode": "schema",
    }


def doctor_payload() -> dict:
    issues = []
    if not LOOPS_DIR.exists():
        issues.append(f"missing_loops_dir={LOOPS_DIR}")
    if not BRIDGE_DIR.exists():
        issues.append(f"missing_bridge_dir={BRIDGE_DIR}")
    return {
        "version": VERSION,
        "schema_version": "loop-integrity-signals/v1",
        "mode": "doctor",
        "loops_dir_exists": LOOPS_DIR.exists(),
        "bridge_dir_exists": BRIDGE_DIR.exists(),
        "issues": issues,
        "status": "ok" if not issues else "degraded",
    }


def main() -> int:
    if MODE == "info":
        return emit(info_payload())
    if MODE == "schema":
        return emit(schema_payload())
    if MODE == "doctor":
        return emit(doctor_payload())
    if not PROJECT:
        return emit({
            "version": VERSION,
            "schema_version": "loop-integrity-signals/v1",
            "status": "fail",
            "error": "missing_required=--project",
            "signals": {},
        })
    marker = read_json(LOOPS_DIR / f"{PROJECT}.json") or {}
    interval_seconds = parse_interval_seconds(marker.get("interval"))
    if WINDOW_RAW.isdigit():
        window = int(WINDOW_RAW)
    elif interval_seconds > 0:
        window = interval_seconds * 2
    else:
        window = 1800
    repo = repo_for(PROJECT, REPO_OVERRIDE)
    signals = {
        "marker_fresh": signal_marker_fresh(PROJECT, window),
        "callback_receipt_fresh": signal_callback_receipt_fresh(PROJECT, repo, window),
        "canonical_bridge_fresh": signal_canonical_bridge_fresh(PROJECT, window),
    }
    failed = [name for name in SIGNAL_NAMES if not signals[name].get("ok")]
    if not failed:
        verdict = "HEALTHY"
    elif len(failed) >= 3:
        verdict = "DEAD"
    else:
        verdict = "LIMPING"
    payload = {
        "version": VERSION,
        "schema_version": "loop-integrity-signals/v1",
        "mode": "probe",
        "project": PROJECT,
        "repo": str(repo),
        "interval_seconds": interval_seconds,
        "window_seconds": window,
        "signals": signals,
        "failed_signals": failed,
        "verdict": verdict,
        "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "status": "ok",
    }
    return emit(payload)


sys.exit(main())
PY
}

run_python
exit $?

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
