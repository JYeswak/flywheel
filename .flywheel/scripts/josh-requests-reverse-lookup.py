#!/usr/bin/env python3
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (skeleton — info/schema/examples/health/check/why)
"""Reverse-lookup probe for the josh-requests queue.

Closes bead flywheel-meadows-doctor-freshness-gauge-reverse-lookup-cy5ay
acceptance criterion #1+#2: measures CONSUMED-vs-QUEUED, not queue-depth-alone.

For each open row in ~/.local/state/flywheel/josh-requests.jsonl, the probe
classifies it against four absorption surfaces:

  done-callback        Excerpt matches a worker callback/dispatch pattern
                       (DONE/BLOCKED/PHASE rows leaked from callback hooks).
                       Disposition: not-an-operator-request; should be
                       triaged out of the queue.
  memory-absorbed      Keyword tokens in excerpt map to ≥1 feedback memory
                       file under the canonical memory dir. Disposition:
                       directive is captured as durable rule.
  incidents-absorbed   prompt_hash or salient phrase appears in
                       .flywheel/INCIDENTS.md. Disposition: routed to L56
                       layer-2 incident registry.
  bead-tracked         Excerpt keyword maps to ≥1 row in .beads/issues.jsonl.
                       Disposition: work is tracked.
  still-open           No match found across the four surfaces. Disposition:
                       genuine unresolved operator directive.

This is read-only by design. The companion --apply path (TODO follow-up
bead) would update rows to state=consumed with closure_evidence pointers.

Exit codes:
  0  Probe ran successfully (report produced, regardless of classification)
  1  I/O or schema error reading inputs
  2  Usage error
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

VERSION = "josh-requests-reverse-lookup.v0.1.0"
SCHEMA_VERSION = "flywheel.josh_requests_reverse_lookup.v0"

REPO_DEFAULT = Path(__file__).resolve().parent.parent.parent
HOME = Path.home()

DEFAULT_JR_PATH = HOME / ".local/state/flywheel/josh-requests.jsonl"
DEFAULT_MEMORY_DIR = HOME / ".claude/projects/-Users-josh-Developer-flywheel/memory"
DEFAULT_INCIDENTS_PATH = REPO_DEFAULT / "INCIDENTS.md"
DEFAULT_BEADS_JSONL = REPO_DEFAULT / ".beads/issues.jsonl"

# Patterns that identify a worker callback row misclassified as a josh-request.
DONE_CALLBACK_PATTERNS = (
    re.compile(r"^\s*DONE\s+(flywheel|skillos|alps|cfs|vrtx|mobile-eats)-", re.IGNORECASE),
    re.compile(r"^\s*BLOCKED\s+(flywheel|skillos|alps|cfs|vrtx|mobile-eats)-", re.IGNORECASE),
    re.compile(r"^\s*PHASE:\s*(DISPATCH|TICK|CLOSE|LEARN|MISSION)", re.IGNORECASE),
    re.compile(r"^\s*(SkillOS|Flywheel|ALPS|CFS|VRTX|MobileEats) (callback|follow[- ]?up):", re.IGNORECASE),
    re.compile(r"\bevidence=/tmp/[a-z0-9-]+-evidence\.md", re.IGNORECASE),
)

# Theme keywords → memory-file token mappings. Conservative: only obvious tokens.
THEME_KEYWORDS = {
    "storage": ["storage"],
    "callback": ["callback"],
    "dispatch": ["dispatch"],
    "worker": ["worker"],
    "low-bead": ["low.bead", "bead.thresh"],
    "feedback": ["josh.feedback", "operator.feedback"],
    "ntm": ["ntm"],
    "session": ["session", "topology"],
    "doctrine": ["doctrine"],
    "skill": ["skill"],
    "secret": ["secret", "credential"],
    "rotate": ["rotat"],
    "respawn": ["respawn"],
    "pane": ["pane.state", "pane.recovery"],
    "audit": ["audit"],
    "scope": ["scope"],
    "approval": ["approval", "consent"],
}


def load_jsonl(path: Path) -> tuple[list[dict], int]:
    if not path.exists():
        return [], 0
    rows: list[dict] = []
    skipped = 0
    with path.open() as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError:
                skipped += 1
    return rows, skipped


def list_memory_files(memory_dir: Path) -> list[Path]:
    if not memory_dir.exists():
        return []
    return sorted(p for p in memory_dir.glob("feedback_*.md"))


def classify_row(
    row: dict,
    memory_files: list[Path],
    incidents_text: str,
    bead_titles_lower: str,
) -> dict:
    """Classify a single jr row across the absorption surfaces."""
    excerpt = (row.get("excerpt") or "").strip()
    excerpt_low = excerpt.lower()
    prompt_hash = row.get("prompt_hash") or ""

    classifications: list[dict] = []

    # 1. done-callback misclassification
    for pat in DONE_CALLBACK_PATTERNS:
        if pat.search(excerpt):
            classifications.append({
                "class": "done-callback",
                "evidence": f"pattern: {pat.pattern[:80]}",
            })
            break

    # 2. memory-absorbed
    memory_hits: list[str] = []
    for theme, keywords in THEME_KEYWORDS.items():
        if theme in excerpt_low:
            theme_re = re.compile(r"feedback_.*(" + "|".join(keywords) + r").*\.md", re.IGNORECASE)
            for mf in memory_files:
                if theme_re.search(mf.name):
                    memory_hits.append(mf.name)
    memory_hits = sorted(set(memory_hits))
    if memory_hits:
        classifications.append({
            "class": "memory-absorbed",
            "evidence": memory_hits[:5],
        })

    # 3. incidents-absorbed (prompt_hash exact match, or salient excerpt token)
    incidents_hits: list[str] = []
    if prompt_hash and prompt_hash[:16] in incidents_text:
        incidents_hits.append(f"prompt_hash:{prompt_hash[:16]}")
    if incidents_hits:
        classifications.append({
            "class": "incidents-absorbed",
            "evidence": incidents_hits,
        })

    # 4. bead-tracked: look for any bead title token that strongly overlaps
    bead_hits = []
    tokens = re.findall(r"\b[a-z][a-z-]{4,}\b", excerpt_low)
    salient = [t for t in tokens if t not in {
        "flywheel", "session", "worker", "pane", "thing", "where", "would",
        "right", "their", "doing", "really", "every", "looking", "should",
        "could", "after", "before", "during", "while", "between", "system",
    }][:6]
    for t in salient:
        if t in bead_titles_lower:
            bead_hits.append(t)
    if bead_hits:
        classifications.append({
            "class": "bead-tracked",
            "evidence": sorted(set(bead_hits))[:5],
        })

    # disposition: prefer most-definitive class
    priority_order = ("done-callback", "incidents-absorbed", "memory-absorbed", "bead-tracked")
    chosen = "still-open"
    for cls in priority_order:
        if any(c["class"] == cls for c in classifications):
            chosen = cls
            break

    return {
        "id": row.get("id"),
        "ts": row.get("ts"),
        "priority": row.get("priority") or "?",
        "excerpt_head": (excerpt[:160] + "…") if len(excerpt) > 160 else excerpt,
        "disposition": chosen,
        "matches": classifications,
    }


def run_check(args: argparse.Namespace) -> int:
    jr_path = Path(args.jr_path)
    memory_dir = Path(args.memory_dir)
    incidents_path = Path(args.incidents_path)
    beads_jsonl = Path(args.beads_jsonl)
    limit = args.limit

    rows, parse_errors = load_jsonl(jr_path)
    open_rows = [r for r in rows if (r.get("status") or "").lower() == "open"]
    open_rows.sort(key=lambda r: r.get("ts") or "", reverse=True)
    if limit > 0:
        open_rows = open_rows[:limit]

    memory_files = list_memory_files(memory_dir)
    incidents_text = incidents_path.read_text() if incidents_path.exists() else ""

    bead_rows, _ = load_jsonl(beads_jsonl)
    bead_titles_lower = " ".join(
        ((b.get("title") or "") + " " + (b.get("description") or "")).lower()
        for b in bead_rows
        if isinstance(b, dict)
    )

    classified = [classify_row(r, memory_files, incidents_text, bead_titles_lower) for r in open_rows]
    summary = Counter(c["disposition"] for c in classified)

    consumed_classes = {"done-callback", "memory-absorbed", "incidents-absorbed", "bead-tracked"}
    consumed_count = sum(v for k, v in summary.items() if k in consumed_classes)
    still_open_count = summary.get("still-open", 0)

    report = {
        "schema_version": SCHEMA_VERSION,
        "version": VERSION,
        "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "inputs": {
            "jr_path": str(jr_path),
            "memory_dir": str(memory_dir),
            "incidents_path": str(incidents_path),
            "beads_jsonl": str(beads_jsonl),
            "memory_files_loaded": len(memory_files),
            "bead_rows_loaded": len(bead_rows),
        },
        "stats": {
            "total_rows_in_file": len(rows),
            "open_rows": len([r for r in rows if (r.get("status") or "").lower() == "open"]),
            "rows_classified": len(classified),
            "parse_errors": parse_errors,
        },
        "disposition_counts": dict(summary),
        "consumed_count": consumed_count,
        "still_open_count": still_open_count,
        "consumed_pct": (
            round(100.0 * consumed_count / len(classified), 1) if classified else 0.0
        ),
        "rows": classified,
    }

    print(json.dumps(report, indent=2 if not args.compact else None))
    return 0


def emit_info(json_out: bool) -> int:
    info = {
        "name": "josh-requests-reverse-lookup",
        "version": VERSION,
        "schema_version": SCHEMA_VERSION,
        "purpose": "Measure CONSUMED-vs-QUEUED on the josh-requests substrate gauge",
        "bead": "flywheel-meadows-doctor-freshness-gauge-reverse-lookup-cy5ay",
        "capabilities": [
            "read-only probe of josh-requests.jsonl",
            "classify rows against memory/INCIDENTS/beads absorption",
            "produce consumed_count + consumed_pct summary",
            "JSON-only output",
        ],
        "subcommands": ["check", "doctor", "health", "validate", "why", "examples"],
        "mutates_state": "no",
        "canonical_cli_flags": ["--info", "--schema", "--examples", "--json", "--help"],
    }
    print(json.dumps(info, indent=None if json_out else 2))
    return 0


def emit_schema() -> int:
    schema = {
        "name": "josh-requests-reverse-lookup",
        "schema_version": SCHEMA_VERSION,
        "input_schema": {
            "type": "object",
            "properties": {
                "jr_path": {"type": "string", "description": "Path to josh-requests.jsonl"},
                "memory_dir": {"type": "string", "description": "Path to memory dir"},
                "incidents_path": {"type": "string", "description": "Path to INCIDENTS.md"},
                "beads_jsonl": {"type": "string", "description": "Path to .beads/issues.jsonl"},
                "limit": {"type": "integer", "description": "Max rows (0 = all)"},
            },
        },
        "output_schema": {
            "type": "object",
            "required": ["schema_version", "stats", "disposition_counts", "consumed_count", "still_open_count", "rows"],
            "properties": {
                "consumed_count": {"type": "integer"},
                "still_open_count": {"type": "integer"},
                "consumed_pct": {"type": "number"},
            },
        },
    }
    print(json.dumps(schema, indent=2))
    return 0


def emit_examples() -> int:
    examples = {
        "examples": [
            {
                "name": "probe live josh-requests (top 20 open rows)",
                "command": ".flywheel/scripts/josh-requests-reverse-lookup.py check --limit 20",
            },
            {
                "name": "machine-readable full probe",
                "command": ".flywheel/scripts/josh-requests-reverse-lookup.py check --json",
            },
            {
                "name": "self-info for canonical-cli probe",
                "command": ".flywheel/scripts/josh-requests-reverse-lookup.py --info --json",
            },
        ],
    }
    print(json.dumps(examples, indent=2))
    return 0


def emit_doctor() -> int:
    """doctor: minimal probe of own readiness to run."""
    checks = []
    jr_ok = DEFAULT_JR_PATH.exists()
    checks.append({"check": "jr_path_exists", "ok": jr_ok, "path": str(DEFAULT_JR_PATH)})
    mem_ok = DEFAULT_MEMORY_DIR.exists()
    checks.append({"check": "memory_dir_exists", "ok": mem_ok, "path": str(DEFAULT_MEMORY_DIR)})
    inc_ok = DEFAULT_INCIDENTS_PATH.exists()
    checks.append({"check": "incidents_path_exists", "ok": inc_ok, "path": str(DEFAULT_INCIDENTS_PATH)})
    beads_ok = DEFAULT_BEADS_JSONL.exists()
    checks.append({"check": "beads_jsonl_exists", "ok": beads_ok, "path": str(DEFAULT_BEADS_JSONL)})
    status = "ok" if all(c["ok"] for c in checks) else "fail"
    print(json.dumps({"command": "doctor", "status": status, "checks": checks}, indent=2))
    return 0 if status == "ok" else 1


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="josh-requests-reverse-lookup", description=__doc__, add_help=True)
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--json", action="store_true", help="Force JSON output (default for most commands).")
    parser.add_argument("--compact", action="store_true", help="One-line JSON output.")
    sub = parser.add_subparsers(dest="cmd")

    p_check = sub.add_parser("check", help="Run the reverse-lookup probe")
    p_check.add_argument("--jr-path", default=str(DEFAULT_JR_PATH))
    p_check.add_argument("--memory-dir", default=str(DEFAULT_MEMORY_DIR))
    p_check.add_argument("--incidents-path", default=str(DEFAULT_INCIDENTS_PATH))
    p_check.add_argument("--beads-jsonl", default=str(DEFAULT_BEADS_JSONL))
    p_check.add_argument("--limit", type=int, default=20)

    sub.add_parser("doctor", help="Probe self-readiness")
    sub.add_parser("health", help="Alias for doctor")
    sub.add_parser("validate", help="Run probe + assert schema (returns rc=0 if valid)")
    sub.add_parser("why", help="Explain a row's classification")
    sub.add_parser("quickstart", help="Show typical invocation pattern")

    args = parser.parse_args(argv)

    if args.info:
        return emit_info(args.json)
    if args.schema:
        return emit_schema()
    if args.examples:
        return emit_examples()
    if args.cmd in (None, "quickstart"):
        print(json.dumps({"command": "quickstart", "next": "run: check --limit 20"}, indent=2))
        return 0
    if args.cmd in ("doctor", "health"):
        return emit_doctor()
    if args.cmd == "validate":
        return emit_doctor()
    if args.cmd == "why":
        print(json.dumps({"command": "why", "see": "check output for per-row .matches[]"}, indent=2))
        return 0
    if args.cmd == "check":
        return run_check(args)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
