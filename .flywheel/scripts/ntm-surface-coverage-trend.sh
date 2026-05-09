#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MATRIX_DEFAULT="$ROOT/.flywheel/plans/ntm-surface-wire-in-USE-ISSUE-WRAP-2026-05-07/07-VALIDATION-MATRIX.yaml"
LEDGER_DEFAULT="$HOME/.local/state/flywheel/ntm-surface-coverage-trend.jsonl"

python3 - "$ROOT" "$MATRIX_DEFAULT" "$LEDGER_DEFAULT" "$@" <<'PY'
import argparse
import json
import os
import sys
from collections import defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path

try:
    import yaml
except Exception as exc:
    print(json.dumps({"schema_version": "ntm-surface-coverage-trend.v1", "status": "fail", "reason": "pyyaml_missing", "detail": str(exc)}))
    raise SystemExit(2)

ROOT = Path(sys.argv[1])
MATRIX_DEFAULT = Path(sys.argv[2])
LEDGER_DEFAULT = Path(sys.argv[3])
THRESHOLD = 7.0
TARGET = 10.0


def now_iso():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def date_key(ts):
    return str(ts or now_iso())[:10]


def emit(obj, json_out=False, jsonl=False):
    if jsonl:
        rows = obj if isinstance(obj, list) else [obj]
        for row in rows:
            print(json.dumps(row, sort_keys=True, separators=(",", ":")))
    elif json_out:
        print(json.dumps(obj, sort_keys=True, separators=(",", ":")))
    else:
        line = obj.get("dashboard_line") if isinstance(obj, dict) else None
        print(line or json.dumps(obj, sort_keys=True))


def matrix_path(path):
    if path.exists():
        return path
    alt = Path(str(path).replace("/.flywheel/plans/", "/.flywheel/PLANS/"))
    if alt.exists():
        return alt
    return path


def load_matrix(path):
    path = matrix_path(path)
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or not isinstance(data.get("surfaces"), list):
        raise ValueError("matrix_missing_surfaces")
    return path, data


def ntm_version():
    try:
        return os.popen("/Users/josh/.local/bin/ntm --version 2>/dev/null").read().strip() or None
    except Exception:
        return None


def avg(vals):
    vals = [float(v) for v in vals if isinstance(v, (int, float))]
    return round(sum(vals) / len(vals), 2) if vals else None


def compute(matrix):
    surfaces = matrix.get("surfaces") or []
    by_decision = defaultdict(list)
    counts = defaultdict(int)
    below = []
    measured = 0
    for row in surfaces:
        decision = str(row.get("decision") or "UNKNOWN").upper()
        score = row.get("coverage_score")
        counts[decision] += 1
        if isinstance(score, (int, float)):
            by_decision[decision].append(score)
            if score >= THRESHOLD:
                measured += 1
            else:
                below.append({"name": row.get("name"), "decision": decision, "coverage_score": score, "gap": row.get("gap")})
    total = len(surfaces)
    all_scores = [score for vals in by_decision.values() for score in vals]
    return {
        "surfaces_total": total,
        "decision_counts": dict(sorted(counts.items())),
        "coverage_avg": avg(all_scores),
        "coverage_by_decision": {key: avg(vals) for key, vals in sorted(by_decision.items())},
        "measured_count": measured,
        "measured_pct": round((measured / total) * 100, 1) if total else 0,
        "below_threshold_count": len(below),
        "below_threshold_sample": below[:10],
    }


def make_row(args):
    path, matrix = load_matrix(args.matrix)
    summary = compute(matrix)
    ts = args.now or now_iso()
    row = {
        "schema_version": "ntm-surface-coverage-trend.v1",
        "ts": ts,
        "date": date_key(ts),
        "repo": str(args.repo),
        "matrix": str(path),
        "ntm_version": matrix.get("ntm_version") or ntm_version(),
        "target_coverage_avg": TARGET,
        "minimum_close_gate_coverage_avg": THRESHOLD,
        "status": "pass" if (summary["coverage_avg"] is not None and summary["coverage_avg"] >= THRESHOLD) else "fail",
        **summary,
    }
    return row


def read_rows(ledger):
    if not ledger.exists():
        return []
    rows = []
    for line in ledger.read_text(encoding="utf-8", errors="replace").splitlines():
        try:
            row = json.loads(line)
            if isinstance(row, dict):
                rows.append(row)
        except json.JSONDecodeError:
            continue
    return rows


def append_daily(args, row):
    if not args.apply:
        row.update({"dry_run": True, "apply": False, "ledger_written": False, "ledger_path": str(args.ledger)})
        return row
    if not args.idempotency_key:
        row.update({"dry_run": False, "apply": True, "ledger_written": False, "reason": "idempotency_key_required"})
        raise RuntimeError(json.dumps(row, sort_keys=True, separators=(",", ":")))
    args.ledger.parent.mkdir(parents=True, exist_ok=True)
    existing = read_rows(args.ledger)
    if any(r.get("date") == row["date"] for r in existing) and not args.force:
        row.update({"dry_run": False, "apply": True, "ledger_written": False, "duplicate_suppressed": True, "ledger_path": str(args.ledger), "idempotency_key": args.idempotency_key})
        return row
    with args.ledger.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")
    row.update({"dry_run": False, "apply": True, "ledger_written": True, "duplicate_suppressed": False, "ledger_path": str(args.ledger), "idempotency_key": args.idempotency_key})
    return row


def latest_by_date(rows):
    by_date = {}
    for row in rows:
        d = row.get("date") or date_key(row.get("ts"))
        by_date[d] = row
    return by_date


def chart(args):
    by_date = latest_by_date(read_rows(args.ledger))
    today = datetime.strptime(args.date or date_key(args.now), "%Y-%m-%d").date()
    out = []
    for i in range(args.days - 1, -1, -1):
        d = (today - timedelta(days=i)).isoformat()
        row = by_date.get(d)
        out.append({
            "schema_version": "ntm-surface-coverage-trend.chart.v1",
            "date": d,
            "coverage_avg": row.get("coverage_avg") if row else None,
            "measured_pct": row.get("measured_pct") if row else None,
            "target_coverage_avg": TARGET,
            "present": row is not None,
        })
    return out


def status(args):
    rows = read_rows(args.ledger)
    current = make_row(args)
    historical = [r for r in rows if r.get("date") and r.get("date") < current["date"]]
    previous = historical[-1] if historical else None
    yesterday = previous.get("coverage_avg") if previous else None
    delta = None
    if isinstance(current.get("coverage_avg"), (int, float)) and isinstance(yesterday, (int, float)):
        delta = round(current["coverage_avg"] - yesterday, 2)
    ytext = f"{yesterday:.1f}" if isinstance(yesterday, (int, float)) else "n/a"
    ctext = f"{current['coverage_avg']:.1f}" if isinstance(current.get("coverage_avg"), (int, float)) else "n/a"
    line = f"ntm coverage: {ctext}/10 (yesterday {ytext}; target {TARGET:.1f})"
    return {**current, "previous_coverage_avg": yesterday, "coverage_delta": delta, "dashboard_line": line, "ledger_rows": len(rows)}


def static_payload(command):
    base = {"schema_version": "ntm-surface-coverage-trend.v1", "command": command, "status": "ok"}
    if command == "info":
        base.update({
            "name": "ntm-surface-coverage-trend",
            "default_matrix": str(MATRIX_DEFAULT),
            "default_ledger": str(LEDGER_DEFAULT),
            "doctor_fields": ["coverage_avg", "coverage_by_decision", "below_threshold_count"],
            "mutation_requires": ["record", "--apply", "--idempotency-key"],
            "exit_codes": {"0": "pass/read ok", "1": "coverage below threshold", "2": "usage/input error", "4": "blocked by mutation gate"},
        })
    elif command == "schema":
        base.update({"required": ["schema_version", "ts", "date", "coverage_avg", "coverage_by_decision", "surfaces_total", "measured_pct"], "threshold": THRESHOLD})
    elif command == "examples":
        base.update({"examples": [
            "ntm-surface-coverage-trend.sh record --dry-run --json",
            "ntm-surface-coverage-trend.sh record --apply --idempotency-key tick-driver --json",
            "ntm-surface-coverage-trend.sh chart --days 7 --jsonl",
            "ntm-surface-coverage-trend.sh status --json",
        ]})
    elif command == "quickstart":
        base.update({"steps": ["validate --json", "record --dry-run --json", "record --apply --idempotency-key <key> --json", "chart --days 7 --jsonl"]})
    elif command == "why":
        base.update({"explanation": "Tracks 07-VALIDATION-MATRIX.yaml coverage so the wire-in migration moves from claimed wiring to measured wiring."})
    elif command == "repair":
        base.update({"dry_run": True, "planned_actions": ["mkdir -p ledger parent", "rerun record --dry-run", "append daily row only with --apply --idempotency-key"], "actual_actions": []})
    return base


def completion(shell):
    words = "record status chart doctor health validate audit repair why schema quickstart completion --json --jsonl --dry-run --apply --idempotency-key --matrix --ledger --days --force"
    if shell == "zsh":
        print("compadd -- " + words)
    else:
        print(f'complete -W "{words}" ntm-surface-coverage-trend.sh')


parser = argparse.ArgumentParser()
parser.add_argument("command", nargs="?", default="record", choices=["record", "status", "chart", "doctor", "health", "validate", "audit", "repair", "why", "schema", "quickstart", "completion", "help", "info", "examples"])
parser.add_argument("topic", nargs="?")
parser.add_argument("--repo", type=Path, default=ROOT)
parser.add_argument("--matrix", type=Path, default=MATRIX_DEFAULT)
parser.add_argument("--ledger", type=Path, default=LEDGER_DEFAULT)
parser.add_argument("--json", action="store_true")
parser.add_argument("--jsonl", action="store_true")
parser.add_argument("--dry-run", action="store_true")
parser.add_argument("--apply", action="store_true")
parser.add_argument("--force", action="store_true")
parser.add_argument("--idempotency-key")
parser.add_argument("--days", type=int, default=7)
parser.add_argument("--date")
parser.add_argument("--now")
parser.add_argument("--info", action="store_true")
parser.add_argument("--schema", action="store_true")
parser.add_argument("--examples", action="store_true")
args = parser.parse_args(sys.argv[4:])

if args.info:
    args.command = "info"
if args.schema:
    args.command = "schema"
if args.examples:
    args.command = "examples"

try:
    if args.command == "record":
        payload = append_daily(args, make_row(args))
        emit(payload, args.json, args.jsonl)
        raise SystemExit(0)
    if args.command in {"doctor", "health", "validate"}:
        payload = make_row(args)
        emit(payload, True)
        raise SystemExit(0 if payload.get("status") == "pass" else 1)
    if args.command == "status":
        emit(status(args), args.json, args.jsonl)
    elif args.command == "chart":
        emit(chart(args), args.json, args.jsonl)
    elif args.command == "audit":
        emit({"schema_version": "ntm-surface-coverage-trend.audit.v1", "status": "ok", "ledger": str(args.ledger), "rows": read_rows(args.ledger)[-20:]}, True)
    elif args.command in {"repair", "why", "schema", "quickstart", "examples", "info"}:
        emit(static_payload(args.command), True)
    elif args.command == "completion":
        completion(args.topic or "bash")
    else:
        print("usage: ntm-surface-coverage-trend.sh [record|status|chart|doctor|health|validate|audit|repair|why|schema|quickstart|completion] [--json]", file=sys.stderr)
        raise SystemExit(0 if args.command == "help" else 2)
except RuntimeError as exc:
    try:
        print(str(exc), file=sys.stderr)
    finally:
        raise SystemExit(4)
except Exception as exc:
    print(json.dumps({"schema_version": "ntm-surface-coverage-trend.v1", "status": "fail", "reason": type(exc).__name__, "detail": str(exc)}), file=sys.stderr)
    raise SystemExit(2)
PY
