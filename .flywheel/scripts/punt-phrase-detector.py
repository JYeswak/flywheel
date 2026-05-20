#!/usr/bin/env python3
# canonical-cli-scoping-allow-large: detector CLI keeps scan/report/doctor surfaces together for one portable substrate.
"""Detect L70 punt phrases in flywheel dispatch and handoff surfaces."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import Counter
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any


VERSION = "punt-phrase-detector.v1.0.0"
EVENT_SCHEMA = "flywheel.l70_punt_event.v1"
SCAN_SCHEMA = "flywheel.l70_punt_scan.v1"
REPORT_SCHEMA = "flywheel.l70_punt_report.v1"
HEALTH_SCHEMA = "flywheel.l70_punt_health.v1"
DOCTOR_SCHEMA = "flywheel.l70_punt_doctor.v1"
MISSION_ANCHOR_HASH = "80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a"

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_LEDGER = Path.home() / ".local/state/flywheel/l70-punt-phrase-events.jsonl"
KNOWN_FLEET_REPOS = [
    Path("~/Developer/flywheel").expanduser(),
    Path("~/Developer/alpsinsurance").expanduser(),
    Path("~/Developer/vrtx").expanduser(),
    Path("~/Developer/polymarket-pico-z").expanduser(),
    Path("~/Developer/mobile-eats").expanduser(),
    Path("~/Developer/skillos").expanduser(),
]

FORBIDDEN_PUNT_PHRASES = [
    "should I",
    "should we",
    "want me to",
    "do you want me to",
    "would you like me to",
    "shall I",
    "let me know if",
    "let me know when",
    "if you want me to",
    "if you'd like",
    "when you're ready",
    "say the word",
    "just say",
    "want to proceed",
    "confirm and I'll",
    "the next move is yours",
    "standing by",
]


def now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def parse_ts(value: Any) -> datetime | None:
    if not isinstance(value, str) or not value:
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def resolve_ledger(value: str | None = None) -> Path:
    raw = value or os.environ.get("FLYWHEEL_L70_PUNT_LEDGER")
    return Path(raw).expanduser() if raw else DEFAULT_LEDGER


def emit(payload: dict[str, Any], json_mode: bool) -> None:
    print(json.dumps(payload, indent=2 if json_mode else None, sort_keys=True))


def load_jsonl(path: Path) -> tuple[list[dict[str, Any]], list[str]]:
    rows: list[dict[str, Any]] = []
    warnings: list[str] = []
    if not path.exists():
        return rows, warnings
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError as exc:
        return rows, [f"could not read {path}: {exc}"]
    for lineno, line in enumerate(lines, 1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError as exc:
            warnings.append(f"{path}:{lineno}: skipped malformed JSON: {exc}")
            continue
        if isinstance(row, dict):
            rows.append(row)
        else:
            warnings.append(f"{path}:{lineno}: skipped non-object row")
    return rows, warnings


def append_jsonl(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, sort_keys=True) + "\n")


def read_text_tolerant(path: Path) -> tuple[str | None, str | None]:
    try:
        return path.read_text(encoding="utf-8", errors="replace"), None
    except OSError as exc:
        return None, f"could not read {path}: {exc}"


def source_type(path: Path) -> str:
    parts = set(path.parts)
    if path.name == "dispatch-log.jsonl":
        return "dispatch_log"
    if path.name == "callback-grade-observations.jsonl":
        return "callback_observation"
    if "handoffs" in parts:
        return "handoff"
    if "receipts" in parts:
        return "receipt"
    return "pane_scrollback"


def repo_session_name(repo: Path) -> str:
    if repo.name == "polymarket-pico-z":
        return "picoz:1"
    return f"{repo.name}:1"


def derive_orchestrator_session(path: Path, text: str, repo: Path | None) -> str:
    for haystack in (str(path), text[:4000]):
        match = re.search(r"\b([a-z][a-z0-9_-]{1,64}:\d+)\b", haystack, flags=re.IGNORECASE)
        if match:
            return match.group(1)
    return repo_session_name(repo) if repo is not None else "unknown"


def context_snippet(text: str, start: int, end: int, radius: int = 90) -> str:
    snippet = text[max(0, start - radius) : min(len(text), end + radius)]
    return " ".join(snippet.split())


def scan_text(path: Path, text: str, *, scan_run_ts: str, repo: Path | None) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    source = source_type(path)
    orchestrator = derive_orchestrator_session(path, text, repo)
    for phrase in FORBIDDEN_PUNT_PHRASES:
        pattern = re.compile(re.escape(phrase), flags=re.IGNORECASE)
        for match in pattern.finditer(text):
            rows.append(
                {
                    "schema_version": EVENT_SCHEMA,
                    "ts": now_iso(),
                    "scan_run_ts": scan_run_ts,
                    "source_path": str(path),
                    "source_type": source,
                    "orchestrator_session": orchestrator,
                    "matched_phrase": text[match.start() : match.end()],
                    "matched_phrase_normalized": phrase.lower(),
                    "context_snippet": context_snippet(text, match.start(), match.end()),
                    "severity": "warn",
                    "mission_anchor_hash": MISSION_ANCHOR_HASH,
                }
            )
    return rows


def repo_sources(repo: Path) -> list[Path]:
    flywheel = repo / ".flywheel"
    candidates = [
        flywheel / "dispatch-log.jsonl",
        flywheel / "callback-grade-observations.jsonl",
    ]
    for dirname in ("handoffs", "receipts"):
        root = flywheel / dirname
        if root.exists():
            candidates.extend(sorted(path for path in root.glob("**/*.md") if path.is_file()))
    return [path for path in candidates if path.exists() and path.is_file()]


def pane_sources() -> list[Path]:
    root = Path("~/.cache/ntm-pane-saves").expanduser()
    if not root.exists():
        return []
    return [path for path in sorted(root.glob("**/*")) if path.is_file()]


def selected_repos(args: argparse.Namespace) -> list[Path]:
    repos: list[Path] = []
    if getattr(args, "all_fleet", False):
        repos.extend(path for path in KNOWN_FLEET_REPOS if path.exists())
    repos.extend(Path(raw).expanduser() for raw in (getattr(args, "repo", None) or []))
    if not repos:
        repos.append(Path.cwd())
    unique: list[Path] = []
    seen: set[str] = set()
    for repo in repos:
        key = str(repo.resolve()) if repo.exists() else str(repo)
        if key not in seen:
            unique.append(repo)
            seen.add(key)
    return unique


def scan_paths(repos: list[Path], *, include_panes: bool, scan_run_ts: str) -> tuple[list[dict[str, Any]], list[str], list[str]]:
    rows: list[dict[str, Any]] = []
    warnings: list[str] = []
    scanned: list[str] = []
    for repo in repos:
        if not repo.exists():
            warnings.append(f"repo missing, skipped: {repo}")
            continue
        for path in repo_sources(repo):
            scanned.append(str(path))
            text, warning = read_text_tolerant(path)
            if warning:
                warnings.append(warning)
                continue
            rows.extend(scan_text(path, text or "", scan_run_ts=scan_run_ts, repo=repo))
    if include_panes:
        for path in pane_sources():
            scanned.append(str(path))
            text, warning = read_text_tolerant(path)
            if warning:
                warnings.append(warning)
                continue
            rows.extend(scan_text(path, text or "", scan_run_ts=scan_run_ts, repo=None))
    return rows, warnings, scanned


def cmd_scan(args: argparse.Namespace) -> int:
    scan_run_ts = now_iso()
    repos = selected_repos(args)
    rows, warnings, scanned = scan_paths(repos, include_panes=args.include_panes, scan_run_ts=scan_run_ts)
    if args.apply:
        append_jsonl(args.ledger, rows)
    payload = {
        "schema_version": SCAN_SCHEMA,
        "status": "applied" if args.apply else "dry_run",
        "scan_run_ts": scan_run_ts,
        "ledger": str(args.ledger),
        "repos": [str(repo) for repo in repos],
        "include_panes": args.include_panes,
        "sources_scanned": scanned,
        "sources_scanned_count": len(scanned),
        "matches_found": len(rows),
        "rows_written": len(rows) if args.apply else 0,
        "warnings": warnings,
        "rows": rows,
        "mission_anchor_hash": MISSION_ANCHOR_HASH,
    }
    emit(payload, args.json)
    return 0


def cmd_report(args: argparse.Namespace) -> int:
    rows, warnings = load_jsonl(args.ledger)
    rows = [row for row in rows if row.get("schema_version") == EVENT_SCHEMA]
    if args.orchestrator:
        rows = [row for row in rows if row.get("orchestrator_session") == args.orchestrator]
    if args.since_hours is not None:
        cutoff = datetime.now(timezone.utc) - timedelta(hours=args.since_hours)
        rows = [row for row in rows if (parse_ts(row.get("ts")) or datetime.min.replace(tzinfo=timezone.utc)) >= cutoff]
    phrase_counts = Counter(str(row.get("matched_phrase_normalized", "")) for row in rows)
    orch_counts = Counter(str(row.get("orchestrator_session", "unknown")) for row in rows)
    payload = {
        "schema_version": REPORT_SCHEMA,
        "status": "ok" if not warnings else "warn",
        "ledger": str(args.ledger),
        "event_count": len(rows),
        "orchestrator": args.orchestrator,
        "since_hours": args.since_hours,
        "by_orchestrator": dict(sorted(orch_counts.items())),
        "top_phrases": phrase_counts.most_common() if args.top_phrases else [],
        "warnings": warnings,
        "mission_anchor_hash": MISSION_ANCHOR_HASH,
    }
    emit(payload, args.json)
    return 0


def cmd_health(args: argparse.Namespace) -> int:
    rows, warnings = load_jsonl(args.ledger)
    valid = [row for row in rows if row.get("schema_version") == EVENT_SCHEMA]
    latest = valid[-1] if valid else None
    payload = {
        "schema_version": HEALTH_SCHEMA,
        "status": "ok" if not warnings else "warn",
        "ledger": str(args.ledger),
        "ledger_exists": args.ledger.exists(),
        "valid_rows": len(valid),
        "latest_ts": latest.get("ts") if latest else None,
        "warnings": warnings,
        "mission_anchor_hash": MISSION_ANCHOR_HASH,
    }
    emit(payload, args.json)
    return 0


def cmd_doctor(args: argparse.Namespace) -> int:
    repos = selected_repos(args)
    subsystems = {
        "ledger_parent": {
            "status": "OK" if args.ledger.parent.exists() else "WARN",
            "path": str(args.ledger.parent),
            "exists": args.ledger.parent.exists(),
        },
        "scan_roots": {
            "status": "OK" if any((repo / ".flywheel").exists() for repo in repos) else "WARN",
            "repos": [str(repo) for repo in repos],
        },
        "phrase_catalog": {
            "status": "OK" if len(FORBIDDEN_PUNT_PHRASES) == 17 else "FAIL",
            "count": len(FORBIDDEN_PUNT_PHRASES),
        },
    }
    aggregate = "ok"
    if any(item["status"] == "FAIL" for item in subsystems.values()):
        aggregate = "fail"
    elif any(item["status"] == "WARN" for item in subsystems.values()):
        aggregate = "warn"
    payload = {
        "schema_version": DOCTOR_SCHEMA,
        "status": aggregate,
        "subsystems": subsystems,
        "mission_anchor_hash": MISSION_ANCHOR_HASH,
    }
    emit(payload, args.json)
    return 0 if aggregate != "fail" else 1


def cmd_info(args: argparse.Namespace) -> int:
    payload = {
        "tool": "punt-phrase-detector",
        "version": VERSION,
        "event_schema": EVENT_SCHEMA,
        "scan_schema": SCAN_SCHEMA,
        "ledger": str(args.ledger),
        "ledger_env_override": "FLYWHEEL_L70_PUNT_LEDGER",
        "forbidden_phrase_catalog_count": len(FORBIDDEN_PUNT_PHRASES),
        "subcommands": ["scan", "report", "health", "doctor"],
        "mission_anchor_hash": MISSION_ANCHOR_HASH,
        "python": sys.version,
    }
    emit(payload, args.json)
    return 0


def cmd_examples(args: argparse.Namespace) -> int:
    examples = [
        ".flywheel/scripts/punt-phrase-detector.py scan --repo /Users/josh/Developer/flywheel --json",
        ".flywheel/scripts/punt-phrase-detector.py scan --apply --json",
        ".flywheel/scripts/punt-phrase-detector.py scan --all-fleet --json",
        ".flywheel/scripts/punt-phrase-detector.py report --since-hours 24 --top-phrases --json",
        ".flywheel/scripts/punt-phrase-detector.py doctor --repo /Users/josh/Developer/flywheel --json",
    ]
    emit({"examples": examples, "mission_anchor_hash": MISSION_ANCHOR_HASH}, args.json)
    return 0


def make_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Detect L70 punt phrases in dispatch surfaces.")
    parser.add_argument("--ledger", default=None, help="JSONL ledger path; defaults to ~/.local/state/flywheel/l70-punt-phrase-events.jsonl")
    parser.add_argument("--json", action="store_true", help="Emit JSON")
    parser.add_argument("--dry-run", action="store_true", help="Do not write state; scan is dry-run by default")
    parser.add_argument("--info", action="store_true", help="Print tool information and exit")
    parser.add_argument("--examples", action="store_true", help="Print example invocations and exit")
    parser.add_argument("--version", action="version", version=f"%(prog)s {VERSION}")
    sub = parser.add_subparsers(dest="subcommand")

    scan = sub.add_parser("scan", help="Scan dispatch logs, handoffs, and receipts")
    scan.add_argument("--json", action="store_true", default=argparse.SUPPRESS)
    scan.add_argument("--dry-run", action="store_true", default=argparse.SUPPRESS)
    scan.add_argument("--apply", action="store_true", help="Append detected rows to the ledger")
    scan.add_argument("--repo", action="append", help="Repo root to scan; may be repeated")
    scan.add_argument("--all-fleet", action="store_true", help="Scan known fleet repos")
    scan.add_argument("--include-panes", action="store_true", help="Also scan cached ntm pane saves")

    report = sub.add_parser("report", help="Summarize ledger rows")
    report.add_argument("--json", action="store_true", default=argparse.SUPPRESS)
    report.add_argument("--orchestrator", help="Filter by orchestrator session, e.g. flywheel:1")
    report.add_argument("--since-hours", type=float, default=None)
    report.add_argument("--top-phrases", action="store_true", help="Include phrase frequency ranking")

    health = sub.add_parser("health", help="Show detector ledger health")
    health.add_argument("--json", action="store_true", default=argparse.SUPPRESS)

    doctor = sub.add_parser("doctor", help="Diagnose detector readiness")
    doctor.add_argument("--json", action="store_true", default=argparse.SUPPRESS)
    doctor.add_argument("--repo", action="append", help="Repo root to inspect; may be repeated")
    doctor.add_argument("--all-fleet", action="store_true", help="Inspect known fleet repos")
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = make_parser()
    args = parser.parse_args(argv)
    args.ledger = resolve_ledger(args.ledger)
    args.json = bool(getattr(args, "json", False))
    if args.info:
        return cmd_info(args)
    if args.examples:
        return cmd_examples(args)
    if args.subcommand == "scan":
        return cmd_scan(args)
    if args.subcommand == "report":
        return cmd_report(args)
    if args.subcommand == "health":
        return cmd_health(args)
    if args.subcommand == "doctor":
        return cmd_doctor(args)
    parser.print_help()
    return 2


if __name__ == "__main__":
    raise SystemExit(main())

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
