#!/usr/bin/env bash
set -euo pipefail

exec python3 - "$@" <<'PY'
import argparse
import json
import os
import re
import subprocess
import sys
from collections import Counter
from datetime import datetime, timedelta, timezone
from pathlib import Path

SCHEMA_VERSION = "stale-in-progress-reaper.v1"
DEFAULT_REASON = "stale-in-progress-reaped (last 7d zero signal)"


def parse_ts(value):
    if not value:
        return None
    text = str(value)
    try:
        if text.endswith("Z"):
            text = text[:-1] + "+00:00"
        return datetime.fromisoformat(text).astimezone(timezone.utc)
    except Exception:
        return None


def iso(dt):
    return dt.astimezone(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def now_utc():
    return parse_ts(os.environ.get("STALE_REAPER_NOW")) or datetime.now(timezone.utc)


def load_jsonl(path):
    rows = []
    try:
        with Path(path).open() as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except Exception:
                    continue
                if isinstance(obj, dict):
                    rows.append(obj)
    except FileNotFoundError:
        pass
    return rows


def load_json(path):
    try:
        with Path(path).open() as fh:
            return json.load(fh)
    except Exception:
        return None


def parse_jsonish(text):
    starts = [i for i in (text.find("["), text.find("{")) if i >= 0]
    if not starts:
        return None
    try:
        return json.loads(text[min(starts):])
    except Exception:
        return None


def run(cmd, repo, timeout=20):
    try:
        return subprocess.run(cmd, cwd=str(repo), text=True, capture_output=True, check=False, timeout=timeout)
    except Exception as exc:
        cp = subprocess.CompletedProcess(cmd, 127, "", str(exc))
        return cp


class Config:
    def __init__(self, args):
        self.repo = Path(args.repo or os.environ.get("STALE_REAPER_REPO", Path.cwd())).resolve()
        self.now = now_utc()
        self.window_days = args.window_days
        self.cutoff = self.now - timedelta(days=args.window_days)
        self.ledger = Path(os.environ.get("STALE_REAPER_LEDGER", Path.home() / ".local/state/flywheel/stale-reaper-ledger.jsonl")).expanduser()
        self.dispatch_log = Path(os.environ.get("STALE_REAPER_DISPATCH_LOG", self.repo / ".flywheel/dispatch-log.jsonl")).expanduser()
        self.br = os.environ.get("STALE_REAPER_BR_BIN", "br")
        self.jsonl_lib = Path(os.environ.get("FLYWHEEL_JSONL_APPEND_LIB", Path.home() / ".local/share/flywheel-watchers/lib/jsonl-append.sh")).expanduser()
        self.apply = args.apply
        self.dry_run = args.dry_run or not args.apply


def issues_from_br(cfg):
    fixture = os.environ.get("STALE_REAPER_BR_LIST_FIXTURE")
    if fixture:
        obj = load_json(fixture)
    else:
        proc = run([cfg.br, "list", "--status", "in_progress", "--json", "--limit", "0"], cfg.repo)
        obj = parse_jsonish(proc.stdout)
    if isinstance(obj, dict):
        items = obj.get("issues") or obj.get("items") or obj.get("rows") or []
    else:
        items = obj if isinstance(obj, list) else []
    return [x for x in items if isinstance(x, dict) and str(x.get("status", "")).lower() == "in_progress"]


def has_assignee(row):
    value = str(row.get("assignee") or "").strip().lower()
    return value not in {"", "unassigned", "none", "null"}


def recent_commit(cfg, bead_id):
    proc = run(["git", "log", "--all", "--format=%H%x00%ct%x00%s", "--grep", bead_id], cfg.repo, timeout=10)
    if proc.returncode != 0:
        return None
    for line in proc.stdout.splitlines():
        parts = line.split("\x00", 2)
        if len(parts) != 3:
            continue
        try:
            ts = datetime.fromtimestamp(int(parts[1]), timezone.utc)
        except Exception:
            continue
        if ts >= cfg.cutoff:
            return {"kind": "commit", "sha": parts[0], "ts": iso(ts), "subject": parts[2][:180]}
    return None


def recent_callback(cfg, bead_id):
    for row in reversed(load_jsonl(cfg.dispatch_log)):
        material = json.dumps(row, sort_keys=True, default=str)
        if bead_id not in material:
            continue
        ts = parse_ts(row.get("ts") or row.get("created_at") or row.get("created_ts"))
        if ts and ts >= cfg.cutoff:
            return {"kind": "callback", "ts": iso(ts), "event": row.get("event")}
    return None


def title_class(title):
    title = str(title or "").strip()
    match = re.match(r"^\[([^\]]+)\]", title)
    if match:
        return match.group(1)[:80]
    words = title.split()
    return " ".join(words[:3])[:80] if words else "untitled"


def classify(cfg, row):
    bead_id = str(row.get("id") or "")
    commit = recent_commit(cfg, bead_id)
    callback = recent_callback(cfg, bead_id)
    updated = parse_ts(row.get("updated_at") or row.get("updated") or row.get("modified_at"))
    if has_assignee(row):
        klass, signal = "ACTIVE", {"kind": "assignee", "value": row.get("assignee")}
    elif commit:
        klass, signal = "ACTIVE", commit
    elif callback:
        klass, signal = "ACTIVE", callback
    elif updated and updated >= cfg.cutoff:
        klass, signal = "RECENTLY_TOUCHED", {"kind": "updated_at", "ts": iso(updated)}
    else:
        klass, signal = "STALE", None
    return {
        "bead_id": bead_id,
        "classification": klass,
        "title": row.get("title") or "",
        "priority": row.get("priority"),
        "assignee": row.get("assignee"),
        "updated_at": row.get("updated_at"),
        "title_class": title_class(row.get("title")),
        "last_signal": signal,
        "recommended_action": "close" if klass == "STALE" else "keep",
    }


def top_classes(stale):
    counts = Counter(item["title_class"] for item in stale)
    return [{"class": key, "count": value} for key, value in counts.most_common(3)]


def scan(cfg):
    issues = issues_from_br(cfg)
    classified = [classify(cfg, row) for row in issues]
    stale = [x for x in classified if x["classification"] == "STALE"]
    active = [x for x in classified if x["classification"] == "ACTIVE"]
    recent = [x for x in classified if x["classification"] == "RECENTLY_TOUCHED"]
    status = "fail" if len(stale) > 5 else "pass"
    return {
        "schema_version": SCHEMA_VERSION,
        "scan_ts": iso(cfg.now),
        "repo": str(cfg.repo),
        "window_days": cfg.window_days,
        "status": status,
        "dry_run": cfg.dry_run,
        "apply": cfg.apply,
        "total_in_progress": len(classified),
        "stale_count": len(stale),
        "active_count": len(active),
        "recently_touched_count": len(recent),
        "stale_in_progress_count_24h": len(stale),
        "stale_in_progress_top_classes": top_classes(stale),
        "candidates": stale,
        "classified": classified,
        "planned_actions": [{"bead_id": item["bead_id"], "action": "br close", "reason": DEFAULT_REASON} for item in stale],
        "ledger": str(cfg.ledger),
    }


def append_ledger(cfg, row):
    payload = json.dumps(row, sort_keys=True, separators=(",", ":"))
    cmd = ['source "$1"; fw_jsonl_append_validated "$2" "$3"']
    proc = subprocess.run(["bash", "-lc", cmd[0], "stale-reaper", str(cfg.jsonl_lib), str(cfg.ledger), payload], text=True, capture_output=True, check=False)
    return proc.returncode, proc.stderr[-500:]


def apply_candidates(cfg, report):
    actions = []
    for item in report["candidates"]:
        bead_id = item["bead_id"]
        proc = run([cfg.br, "close", bead_id, "--reason", DEFAULT_REASON, "--json"], cfg.repo, timeout=20)
        action = {
            "bead_id": bead_id,
            "action": "br close",
            "reason": DEFAULT_REASON,
            "exit_code": proc.returncode,
            "stdout": proc.stdout[-500:],
            "stderr": proc.stderr[-500:],
        }
        row = {"schema_version": SCHEMA_VERSION, "ts": iso(cfg.now), "event": "stale_reaper_apply", "repo": str(cfg.repo), **action}
        rc, err = append_ledger(cfg, row)
        action["ledger_append_exit_code"] = rc
        action["ledger_append_stderr"] = err
        actions.append(action)
    report["actual_actions"] = actions
    report["status"] = "applied" if all(a["exit_code"] == 0 and a["ledger_append_exit_code"] == 0 for a in actions) else "apply_failed"
    return report


def schema():
    return {
        "schema_version": SCHEMA_VERSION,
        "required": ["schema_version", "scan_ts", "total_in_progress", "stale_count", "active_count", "recently_touched_count", "candidates"],
        "doctor_fields": ["stale_in_progress_count_24h", "stale_in_progress_top_classes"],
        "default_mode": "dry-run",
        "mutation_requires": ["--apply"],
    }


def info(cfg):
    return {"name": "stale-in-progress-reaper.sh", "schema_version": SCHEMA_VERSION, "repo": str(cfg.repo), "ledger": str(cfg.ledger), "jsonl_append_lib": str(cfg.jsonl_lib), "br_bin": cfg.br}


def audit(cfg):
    return {"schema_version": SCHEMA_VERSION, "ledger": str(cfg.ledger), "rows": load_jsonl(cfg.ledger)[-20:]}


def parse_args(argv):
    command = "scan"
    if argv and argv[0] in {"doctor", "health", "repair", "validate", "audit", "why", "schema", "quickstart", "help", "completion"}:
        command, argv = argv[0], argv[1:]
    p = argparse.ArgumentParser(add_help=False)
    p.add_argument("--repo")
    p.add_argument("--json", action="store_true")
    p.add_argument("--doctor", action="store_true")
    p.add_argument("--health", action="store_true")
    p.add_argument("--repair", action="store_true")
    p.add_argument("--apply", action="store_true")
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--window-days", type=int, default=int(os.environ.get("STALE_REAPER_WINDOW_DAYS", "7")))
    p.add_argument("--schema", action="store_true")
    p.add_argument("--info", action="store_true")
    p.add_argument("--examples", action="store_true")
    p.add_argument("-h", "--help", action="store_true")
    p.add_argument("rest", nargs="*")
    args = p.parse_args(argv)
    if args.doctor:
        command = "doctor"
    if args.health:
        command = "health"
    if args.repair:
        command = "repair"
    if args.schema:
        command = "schema"
    if args.info:
        command = "info"
    if args.examples:
        command = "examples"
    if args.help:
        command = "help"
    return command, args


def emit(obj, as_json=True):
    if as_json:
        print(json.dumps(obj, sort_keys=True, separators=(",", ":")))
    else:
        if isinstance(obj, dict):
            print(f"status={obj.get('status')} stale_count={obj.get('stale_count', obj.get('stale_in_progress_count_24h', 0))}")
        else:
            print(obj)


def main(argv):
    command, args = parse_args(argv)
    cfg = Config(args)
    if command in {"help", "quickstart"}:
        print("stale-in-progress-reaper.sh --json [--repo PATH]; add --apply only to close stale candidates.")
        return 0
    if command == "examples":
        print("stale-in-progress-reaper.sh --json | jq '.stale_count,.candidates[:3]'")
        print("stale-in-progress-reaper.sh repair --apply --json")
        return 0
    if command == "completion":
        print("--json --repo --doctor --health --repair --dry-run --apply --schema --info --examples quickstart completion")
        return 0
    if command == "schema":
        emit(schema(), True)
        return 0
    if command == "info":
        emit(info(cfg), args.json)
        return 0
    if command == "audit":
        emit(audit(cfg), args.json)
        return 0
    report = scan(cfg)
    if command == "why" and args.rest:
        wanted = args.rest[0]
        report = {"schema_version": SCHEMA_VERSION, "bead_id": wanted, "match": next((x for x in report["classified"] if x["bead_id"] == wanted), None)}
    elif command == "repair" or args.apply:
        if args.apply:
            report = apply_candidates(cfg, report)
    emit(report, args.json or command in {"doctor", "health", "repair", "validate", "why"})
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY
