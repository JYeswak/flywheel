#!/usr/bin/env python3
"""Goal-doc grader and residue ledger for goal-build.sh."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

SCHEMA_VERSION = "flywheel.goal_doc_residue.v1"
GOALS_DIR = Path(os.environ.get("GOAL_BUILD_GOALS_DIR") or str(Path.home() / "Desktop/zeststream-goals"))
LEDGER_PATH = GOALS_DIR / "_residue/ledger.jsonl"
LIMIT = 4000

ANCHOR_TOKENS = (
    "continuous-orchestrator-uptime-self-sustaining-fleet",
    "capability control plane",
    "self-improving capability loops",
)

CALENDAR_BOUND_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("24h", re.compile(r"\b24h\b", re.IGNORECASE)),
    (">=24", re.compile(r">=\s*24\b", re.IGNORECASE)),
    (">=7d", re.compile(r">=\s*7d\b", re.IGNORECASE)),
    ("consecutive runs", re.compile(r"\bconsecutive\s+runs\b", re.IGNORECASE)),
    ("7-day clean", re.compile(r"\b7[- ]day\s+clean\b", re.IGNORECASE)),
    ("wall-clock", re.compile(r"\bwall[- ]clock\b", re.IGNORECASE)),
    ("N days since", re.compile(r"\bN\s+days\s+since\b", re.IGNORECASE)),
)


def now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def calendar_override_present(text: str) -> bool:
    lower = text.lower()
    if "event-bound override" not in lower:
        return False
    session_bound = "same-session" in lower or "same session" in lower or "this session" in lower
    executable = re.search(
        r"\b(run|execute|invoke|call|doctor|script|command|probe|validator|receipt)\b",
        lower,
    )
    return bool(session_bound and executable)


def warnings_for_text(text: str) -> list[dict]:
    matched = [name for name, pattern in CALENDAR_BOUND_PATTERNS if pattern.search(text)]
    if not matched or calendar_override_present(text):
        return []
    return [
        {
            "code": "calendar_bound_gate_without_event_bound_override",
            "severity": "warn",
            "message": "Calendar-bound goal gates must name an event-bound override with a same-session executable alternative.",
            "matched_terms": matched,
            "doctrine": ".flywheel/doctrine/goal-contract-no-writable-escape.md",
        }
    ]


def score_specificity(text: str) -> tuple[int, str]:
    paths = len(
        re.findall(
            r"(?:^|\s)(?:\.?/[\w./_-]+|~/[\w./_-]+|\.flywheel/[\w./_-]+|scripts/[\w./_-]+|tests/[\w./_-]+|docs/[\w./_-]+)",
            text,
        )
    )
    hashes = len(re.findall(r"\b[0-9a-f]{7,40}\b", text))
    schemas = len(re.findall(r"\b[a-z][\w.-]*\.v\d+\b", text))
    total = paths + hashes + schemas
    return min(10, total // 2), f"paths={paths} hashes={hashes} schemas={schemas} total={total}"


def score_anti_staleness(text: str) -> tuple[int, str]:
    time_gates = len(
        re.findall(
            r"\b(?:24h|48h|72h|anti[-_ ]?stale|auto[-_ ]?halt|stall(?:s|ed|ing)?|halt(?:s|ed|ing)?)\b",
            text,
            re.IGNORECASE,
        )
    )
    return min(10, time_gates), f"time_gates={time_gates}"


def score_reversibility(text: str) -> tuple[int, str]:
    rev = len(re.findall(r"\b(?:revert(?:ible)?|rollback|env[-_ ]?(?:var|flag)|git[-_ ]revert)\b", text, re.IGNORECASE))
    return min(10, rev * 2), f"reversibility_tokens={rev}"


def score_exit_clarity(text: str) -> tuple[int, str]:
    exits = len(re.findall(r"\b(?:EXIT|exit criter|success criter|SUCCESS(?: WHEN)?)\b", text))
    return min(10, exits), f"exit_markers={exits}"


def score_mission_alignment(text: str) -> tuple[int, str]:
    hits = sum(1 for token in ANCHOR_TOKENS if token in text)
    if hits == len(ANCHOR_TOKENS):
        return 10, f"anchor_hits={hits}/{len(ANCHOR_TOKENS)}"
    if hits:
        return 5, f"anchor_hits={hits}/{len(ANCHOR_TOKENS)}"
    return 0, f"anchor_hits={hits}/{len(ANCHOR_TOKENS)}"


def score_hard_but_achievable(text: str) -> tuple[int, str]:
    hard_tokens = len(re.findall(r"\b(?:hard|non[-_ ]?trivial|may fail|stall|unproven|greenfield|untested)\b", text, re.IGNORECASE))
    exits = len(re.findall(r"\b(?:EXIT|exit criter|success criter)\b", text))
    if hard_tokens >= 1 and exits >= 3:
        score = 10
    elif hard_tokens == 0 and exits == 0:
        score = 0
    else:
        score = max(0, 10 - abs(hard_tokens - exits))
    return score, f"hard={hard_tokens} exits={exits}"


def score_compounding_shape(text: str) -> tuple[int, str]:
    feeds = len(re.findall(r"(?:next phase|feed(?:s|ing) (?:phase|the next)|compound(?:s|ing)?|each phase)", text, re.IGNORECASE))
    return min(10, feeds * 2), f"feeds={feeds}"


def score_cross_session_readable(text: str) -> tuple[int, str]:
    has_baseline = bool(re.search(r"\bBASELINE\b|already shipped|already committed", text, re.IGNORECASE))
    has_anchor_at_top = any(token in text[:1000] for token in ANCHOR_TOKENS)
    has_self_contained = "cold worker" in text.lower() or "self-contained" in text.lower() or "without external context" in text.lower()
    signals = sum([has_baseline, has_anchor_at_top, has_self_contained])
    return min(10, signals * 3 + min(1, signals)), (
        f"baseline={has_baseline} anchor_at_top={has_anchor_at_top} self_contained={has_self_contained}"
    )


def score_substrate_anchoring(text: str) -> tuple[int, str]:
    candidates = re.findall(r"(?:\.flywheel/[\w./_-]+|scripts/[\w./_-]+|tests/[\w./_-]+|docs/[\w./_-]+)", text)
    candidates = [candidate for candidate in set(candidates) if not candidate.endswith("...") and "<" not in candidate]
    if not candidates:
        return 5, "no_candidate_paths"
    repo = Path(os.environ.get("GOAL_BUILD_REPO") or "/Users/josh/Developer/flywheel")
    existing = sum(1 for candidate in candidates if (repo / candidate).exists())
    fraction = existing / len(candidates)
    return round(10 * fraction), f"existing={existing}/{len(candidates)} fraction={fraction:.2f}"


def score_limit_discipline(text: str) -> tuple[int, str]:
    count = len(text)
    if count > LIMIT:
        return 0, f"chars={count} OVER_LIMIT"
    margin = LIMIT - count
    if margin >= 500:
        score = 10
    elif margin >= 100:
        score = 9
    elif margin > 0:
        score = 8
    else:
        score = 7
    return score, f"chars={count}/{LIMIT} margin={margin}"


GRADERS = [
    ("specificity", score_specificity),
    ("substrate_anchoring", score_substrate_anchoring),
    ("anti_staleness", score_anti_staleness),
    ("reversibility", score_reversibility),
    ("exit_clarity", score_exit_clarity),
    ("mission_alignment", score_mission_alignment),
    ("hard_but_achievable", score_hard_but_achievable),
    ("compounding_shape", score_compounding_shape),
    ("cross_session_readable", score_cross_session_readable),
    ("limit_discipline", score_limit_discipline),
]

IMPROVEMENT_HINTS = {
    "specificity": "Name more concrete paths, file refs, schemas, commit hashes.",
    "substrate_anchoring": "Reference paths that actually exist on disk.",
    "anti_staleness": "Use event-bound gates instead of naked calendar duration gates.",
    "reversibility": "Name the reversibility mechanism per move.",
    "exit_clarity": "Add EXIT or success-when clauses with observable evidence.",
    "mission_alignment": "Include mission anchors near the top.",
    "hard_but_achievable": "Name at least one stall point and measurable exits.",
    "compounding_shape": "Show how phases feed each other.",
    "cross_session_readable": "Include baseline and self-contained context.",
    "limit_discipline": "Aim for at least 500 chars margin under 4000.",
}


def improvement_hints(scores: dict[str, int], evidence: dict[str, str]) -> list[str]:
    out: list[str] = []
    for dim, score in sorted(scores.items(), key=lambda item: item[1])[:3]:
        if score >= 9:
            break
        out.append(f"[{dim} {score}/10] {IMPROVEMENT_HINTS[dim]} Observed: {evidence[dim]}")
    return out


def grade_text(text: str) -> dict:
    scores: dict[str, int] = {}
    evidence: dict[str, str] = {}
    for name, grader in GRADERS:
        score, detail = grader(text)
        scores[name] = score
        evidence[name] = detail
    weakest_dim = min(scores, key=lambda key: scores[key])
    return {
        "schema_version": SCHEMA_VERSION,
        "char_count": len(text),
        "composite": sum(scores.values()),
        "composite_max": 100,
        "scores": scores,
        "evidence": evidence,
        "weakest_dim": weakest_dim,
        "weakest_score": scores[weakest_dim],
        "improvements": improvement_hints(scores, evidence),
        "warnings": warnings_for_text(text),
    }


def read_text(path_text: str) -> tuple[Path, str]:
    path = Path(path_text)
    if not path.exists():
        raise FileNotFoundError(path)
    return path, path.read_text()


def cmd_grade(args: argparse.Namespace) -> int:
    try:
        path, text = read_text(args.from_path)
    except FileNotFoundError as exc:
        print(f"file not found: {exc}", file=sys.stderr)
        return 1
    result = grade_text(text)
    result["graded_at"] = now_iso()
    result["goal_path"] = str(path)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(f"goal: {path}")
        print(f"chars: {result['char_count']}/{LIMIT}")
        print(f"composite: {result['composite']}/{result['composite_max']}  weakest: {result['weakest_dim']} ({result['weakest_score']}/10)")
        if result["warnings"]:
            print("warnings:")
            for warning in result["warnings"]:
                print(f"  - {warning['code']}: {warning['message']}")
    return 0


def cmd_write_residue(args: argparse.Namespace) -> int:
    try:
        goal_path, text = read_text(args.goal_path)
    except FileNotFoundError as exc:
        print(f"goal not found: {exc}", file=sys.stderr)
        return 1
    result = grade_text(text)
    result["graded_at"] = now_iso()
    result["goal_path"] = str(goal_path)
    result["repo"] = goal_path.parent.name if goal_path.parent.name != "_residue" else "unknown"
    result["slug"] = re.sub(r"-\d{8}$", "", goal_path.stem)
    LEDGER_PATH.parent.mkdir(parents=True, exist_ok=True)
    with LEDGER_PATH.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(result) + "\n")
    if args.json:
        print(json.dumps({"status": "appended", "ledger": str(LEDGER_PATH), "row": result}))
    else:
        print(f"appended -> {LEDGER_PATH}")
    return 0


def load_rows(repo: str | None = None) -> list[dict]:
    if not LEDGER_PATH.exists():
        return []
    rows: list[dict] = []
    with LEDGER_PATH.open(encoding="utf-8") as handle:
        for line in handle:
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            if repo is None or row.get("repo") == repo:
                rows.append(row)
    return rows


def cmd_review(args: argparse.Namespace) -> int:
    rows = load_rows(args.repo)
    if not rows:
        print(json.dumps({"schema_version": SCHEMA_VERSION, "total_rows": 0, "rows": 0, "repo_filter": args.repo}, indent=2) if args.json else "no residue yet")
        return 0
    dim_avgs = {}
    for dim, _ in GRADERS:
        vals = [row.get("scores", {}).get(dim, 0) for row in rows]
        dim_avgs[dim] = round(sum(vals) / len(vals), 1)
    weakest_counts = Counter(row.get("weakest_dim") for row in rows if row.get("weakest_dim"))
    report = {
        "schema_version": SCHEMA_VERSION,
        "ledger_path": str(LEDGER_PATH),
        "total_rows": len(rows),
        "rows": len(rows),
        "repo_filter": args.repo,
        "composite_avg": round(sum(row.get("composite", 0) for row in rows) / len(rows), 1),
        "dim_avgs": dim_avgs,
        "weakest_dim_frequency": weakest_counts.most_common(3),
    }
    print(json.dumps(report, indent=2) if args.json else f"goal-doc residue ledger - {len(rows)} rows")
    return 0


def cmd_weakest(args: argparse.Namespace) -> int:
    rows = load_rows()
    if not rows:
        out = {"weakest_dim": None, "reason": "no residue yet"}
    else:
        counts = Counter(row.get("weakest_dim") for row in rows if row.get("weakest_dim"))
        weakest = counts.most_common(1)[0][0] if counts else None
        out = {"weakest_dim": weakest, "freq": counts.get(weakest, 0) if weakest else 0, "total_rows": len(rows)}
    print(json.dumps(out) if args.json else str(out.get("weakest_dim")))
    return 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd")
    grade = sub.add_parser("grade")
    grade.add_argument("--from", dest="from_path", required=True)
    grade.add_argument("--json", action="store_true")
    write = sub.add_parser("write-residue")
    write.add_argument("--goal", dest="goal_path", required=True)
    write.add_argument("--json", action="store_true")
    review = sub.add_parser("review")
    review.add_argument("--repo")
    review.add_argument("--json", action="store_true")
    weakest = sub.add_parser("weakest")
    weakest.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)
    if not args.cmd:
        parser.print_help()
        return 2
    return {
        "grade": cmd_grade,
        "write-residue": cmd_write_residue,
        "review": cmd_review,
        "weakest": cmd_weakest,
    }[args.cmd](args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
