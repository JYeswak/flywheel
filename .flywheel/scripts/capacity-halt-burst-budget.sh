#!/usr/bin/env bash
set -euo pipefail

VERSION="capacity-halt-burst-budget.v1.0.0"
LEDGER="${CAPACITY_HALT_BUDGET_LEDGER:-$HOME/.local/state/flywheel/auto-respawn-attempts.jsonl}"
NOW_EPOCH="${CAPACITY_HALT_BUDGET_NOW_EPOCH:-}"
PER_PANE_MAX="${CAPACITY_HALT_PER_PANE_MAX:-3}"
PER_PANE_WINDOW="${CAPACITY_HALT_PER_PANE_WINDOW_SEC:-600}"
FLEET_MAX="${CAPACITY_HALT_FLEET_MAX:-5}"
FLEET_WINDOW="${CAPACITY_HALT_FLEET_WINDOW_SEC:-60}"

python3 - "$VERSION" "$LEDGER" "$NOW_EPOCH" "$PER_PANE_MAX" "$PER_PANE_WINDOW" "$FLEET_MAX" "$FLEET_WINDOW" "$@" <<'PY'
import argparse, json, re, sys, time
from datetime import datetime
from pathlib import Path

VERSION, LEDGER, NOW_RAW, PER_MAX_RAW, PER_WIN_RAW, FLEET_MAX_RAW, FLEET_WIN_RAW = sys.argv[1:8]
PANE_RE = re.compile(r"^[0-9]+$")

def parse_args():
    p = argparse.ArgumentParser(description="Read-only capacity-halt burst budget gate.")
    p.add_argument("--info", action="store_true")
    p.add_argument("--examples", action="store_true")
    p.add_argument("--json", action="store_true")
    p.add_argument("--session", default="")
    p.add_argument("--pane", default="")
    p.add_argument("--quiet", action="store_true")
    return p.parse_args(sys.argv[8:])

def now_epoch():
    return int(NOW_RAW or time.time())

def row_epoch(row):
    if row.get("epoch") is not None:
        return int(row.get("epoch"))
    ts = row.get("ts") or row.get("timestamp")
    if not ts:
        return 0
    return int(datetime.fromisoformat(str(ts).replace("Z", "+00:00")).timestamp())

def read_rows(path):
    p = Path(path)
    if not p.exists():
        return []
    rows = []
    for idx, line in enumerate(p.read_text().splitlines(), start=1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError as exc:
            raise ValueError(f"malformed_jsonl_line_{idx}:{exc}") from exc
        if isinstance(row, dict):
            rows.append(row)
    return rows

def auto_continue_row(row):
    if row.get("class") == "capacity-halt-budget-exhausted":
        return False
    return row.get("action") == "auto_continue_attempt" or row.get("recovery_attempted") == "auto_continue"

def emit(args, payload, rc):
    if args.json:
        print(json.dumps(payload, sort_keys=True))
    elif not args.quiet:
        print(f"capacity-halt-burst-budget status={payload.get('status')} session={payload.get('session', '')} pane={payload.get('pane', '')}")
    raise SystemExit(rc)

def base(args):
    return {
        "schema_version": "capacity-halt-burst-budget.result.v1",
        "version": VERSION,
        "session": args.session,
        "pane": args.pane,
        "ledger": LEDGER,
        "budget_window_sec": {"per_pane": int(PER_WIN_RAW), "fleet": int(FLEET_WIN_RAW)},
        "per_pane_max": int(PER_MAX_RAW),
        "fleet_max": int(FLEET_MAX_RAW),
        "read_only": True,
    }

def info(args):
    emit(args, {
        "schema_version": "capacity-halt-burst-budget.info.v1",
        "name": "capacity-halt-burst-budget",
        "version": VERSION,
        "ledger": LEDGER,
        "verbs": ["--info", "--help", "--examples", "--json", "--session", "--pane", "--quiet"],
        "defaults": {"per_pane_max": int(PER_MAX_RAW), "per_pane_window_sec": int(PER_WIN_RAW), "fleet_max": int(FLEET_MAX_RAW), "fleet_window_sec": int(FLEET_WIN_RAW)},
        "exit_codes": {"0": "authorized", "1": "per-pane-exhausted", "2": "fleet-exhausted", "3": "malformed", "4": "ledger-read-error"},
    }, 0)

def examples(args):
    emit(args, {
        "schema_version": "capacity-halt-burst-budget.examples.v1",
        "examples": [
            {"name": "worker", "command": "capacity-halt-burst-budget.sh --session flywheel --pane 3 --json"},
            {"name": "override", "command": "CAPACITY_HALT_PER_PANE_MAX=1 capacity-halt-burst-budget.sh --session flywheel --pane 3 --json"},
        ],
    }, 0)

def main():
    args = parse_args()
    if args.info:
        info(args)
    if args.examples:
        examples(args)
    if not args.session or not PANE_RE.match(args.pane) or min(int(PER_MAX_RAW), int(PER_WIN_RAW), int(FLEET_MAX_RAW), int(FLEET_WIN_RAW)) <= 0:
        emit(args, dict(base(args), status="malformed", per_pane_authorized=False, fleet_authorized=False, budget_outcome="malformed", reason="session_numeric_pane_positive_budgets_required"), 3)
    try:
        rows = read_rows(LEDGER)
        now = now_epoch()
        per_cutoff, fleet_cutoff = now - int(PER_WIN_RAW), now - int(FLEET_WIN_RAW)
        counted = [r for r in rows if auto_continue_row(r)]
        per_count = sum(1 for r in counted if str(r.get("session")) == args.session and str(r.get("pane")) == args.pane and row_epoch(r) >= per_cutoff)
        fleet_count = sum(1 for r in counted if row_epoch(r) >= fleet_cutoff)
    except Exception as exc:
        emit(args, dict(base(args), status="ledger_read_error", per_pane_authorized=False, fleet_authorized=False, budget_outcome="ledger_read_error", reason=str(exc)), 4)
    per_ok, fleet_ok = per_count < int(PER_MAX_RAW), fleet_count < int(FLEET_MAX_RAW)
    payload = dict(base(args), per_pane_count_window=per_count, fleet_count_window=fleet_count, per_pane_authorized=per_ok, fleet_authorized=fleet_ok)
    if not per_ok:
        emit(args, dict(payload, status="per_pane_exhausted", budget_outcome="per_pane_exhausted"), 1)
    if not fleet_ok:
        emit(args, dict(payload, status="fleet_exhausted", budget_outcome="fleet_exhausted"), 2)
    emit(args, dict(payload, status="authorized", budget_outcome="authorized"), 0)

if __name__ == "__main__":
    main()
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-60-measured-performance-budget-loop.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-87-binding-constraint-capacity-score.md`
