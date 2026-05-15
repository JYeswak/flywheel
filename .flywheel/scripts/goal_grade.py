#!/usr/bin/env python3
"""Goal-doc grader + residue ledger.

Companion to .flywheel/scripts/goal-build.sh. Scores a goal doc on 10
dimensions (rubric below), writes a residue row to a ledger, and surfaces
prior-goal learnings so every new goal is better than the last.

Rubric inspired by ~/.claude/skills/agent-ergonomics-and-agent-intuitiveness-
maximization-for-cli-tools/ — applied to goal docs instead of CLIs.

Subcommands:
  grade --from <file>             Score a goal doc against the 10-dim rubric
  write-residue --goal <path>     Append a residue row for a goal doc
  review [--repo <name>]          Show aggregate learnings from prior goals
  weakest --json                  Print the dimension to prioritize next

Exit codes:
  0 ok
  1 file unreadable / schema error
  2 usage error
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

SCHEMA_VERSION = "flywheel.goal_doc_residue.v0"
# GOAL_BUILD_GOALS_DIR env override matches goal-build.sh, so tests using a
# scratch GOAL_BUILD_GOALS_DIR don't pollute the production ledger.
GOALS_DIR = Path(os.environ.get("GOAL_BUILD_GOALS_DIR") or str(Path.home() / "Desktop/zeststream-goals"))
LEDGER_PATH = GOALS_DIR / "_residue/ledger.jsonl"
LIMIT = 4000

# Mission anchors that goal docs should reference verbatim.
ANCHOR_TOKENS = (
    "continuous-orchestrator-uptime-self-sustaining-fleet",
    "capability control plane",
    "self-improving capability loops",
)


def score_specificity(text: str) -> tuple[int, str]:
    """Concrete paths/files/schemas/commit hashes mentioned."""
    paths = len(re.findall(r"(?:^|\s)(?:\.?/[\w./_-]+|~/[\w./_-]+|\.flywheel/[\w./_-]+|\.beads/[\w./_-]+|scripts/[\w./_-]+|tests/[\w./_-]+|docs/[\w./_-]+|~/\.claude/[\w./_-]+)", text))
    hashes = len(re.findall(r"\b[0-9a-f]{7,40}\b", text))
    schemas = len(re.findall(r"\b[a-z][\w.-]*\.v\d+\b", text))
    total = paths + hashes + schemas
    score = min(10, total // 2)
    return score, f"paths={paths} hashes={hashes} schemas={schemas} total={total}"


def score_anti_staleness(text: str) -> tuple[int, str]:
    """Time-bound gates + halt clauses."""
    time_gates = len(re.findall(r"\b(?:24h|48h|72h|anti[-_ ]?stale|auto[-_ ]?halt|stall(?:s|ed|ing)?|halt(?:s|ed|ing)?\b)", text, re.IGNORECASE))
    score = min(10, time_gates)
    return score, f"time_gates={time_gates}"


def score_reversibility(text: str) -> tuple[int, str]:
    """Reversible language + env-flag mentions."""
    rev = len(re.findall(r"\b(?:revert(?:ible)?|rollback|env[-_ ]?(?:var|flag)|git[-_ ]revert)\b", text, re.IGNORECASE))
    score = min(10, rev * 2)
    return score, f"reversibility_tokens={rev}"


def score_exit_clarity(text: str) -> tuple[int, str]:
    """Count of EXIT / exit criterion / success-when phrasings."""
    exits = len(re.findall(r"\b(?:EXIT|exit criter|success criter|SUCCESS(?: WHEN)?)\b", text))
    score = min(10, exits)
    return score, f"exit_markers={exits}"


def score_mission_alignment(text: str) -> tuple[int, str]:
    """Anchor tokens present verbatim."""
    hits = sum(1 for tok in ANCHOR_TOKENS if tok in text)
    if hits == len(ANCHOR_TOKENS):
        score = 10
    elif hits >= 1:
        score = 5
    else:
        score = 0
    return score, f"anchor_hits={hits}/{len(ANCHOR_TOKENS)}"


def score_hard_but_achievable(text: str) -> tuple[int, str]:
    """Balance of difficulty acknowledgments vs. exit criteria."""
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
    """Phase-to-phase feed language + compounding mentions."""
    feeds = len(re.findall(r"(?:next phase|feed(?:s|ing) (?:phase|the next)|compound(?:s|ing)?|each phase)", text, re.IGNORECASE))
    score = min(10, feeds * 2)
    return score, f"feeds={feeds}"


def score_cross_session_readable(text: str) -> tuple[int, str]:
    """Cold-worker self-containment signals."""
    has_baseline = bool(re.search(r"\bBASELINE\b|already shipped|already committed", text, re.IGNORECASE))
    has_anchor_at_top = any(tok in text[:1000] for tok in ANCHOR_TOKENS)
    has_self_contained = "cold worker" in text.lower() or "self-contained" in text.lower() or "without external context" in text.lower()
    signals = sum([has_baseline, has_anchor_at_top, has_self_contained])
    score = signals * 3 + min(1, signals)  # 3 signals → 10, 2 → 6, 1 → 3, 0 → 0
    return min(10, score), f"baseline={has_baseline} anchor_at_top={has_anchor_at_top} self_contained={has_self_contained}"


def score_substrate_anchoring(text: str) -> tuple[int, str]:
    """Fraction of referenced flywheel/skillos paths that actually exist."""
    candidates = re.findall(r"(?:\.flywheel/[\w./_-]+|scripts/[\w./_-]+|tests/[\w./_-]+|~/\.claude/[\w./_-]+|docs/[\w./_-]+)", text)
    candidates = [c for c in set(candidates) if not c.endswith("...") and "<" not in c]
    if not candidates:
        return 5, "no_candidate_paths"
    repo = Path("/Users/josh/Developer/flywheel")
    home = Path.home()
    existing = 0
    for c in candidates:
        if c.startswith("~/.claude/"):
            p = home / c[2:]
        elif c.startswith("."):
            p = repo / c
        else:
            p = repo / c
        if p.exists():
            existing += 1
    fraction = existing / len(candidates) if candidates else 0
    score = round(10 * fraction)
    return score, f"existing={existing}/{len(candidates)} fraction={fraction:.2f}"


def score_limit_discipline(text: str) -> tuple[int, str]:
    """Reward leaving margin under 4000 chars."""
    n = len(text)
    if n > LIMIT:
        return 0, f"chars={n} OVER_LIMIT"
    margin = LIMIT - n
    # 0 margin = 8, 100 margin = 9, 500+ margin = 10
    if margin >= 500:
        score = 10
    elif margin >= 100:
        score = 9
    elif margin > 0:
        score = 8
    else:
        score = 7
    return score, f"chars={n}/{LIMIT} margin={margin}"


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


def grade_text(text: str) -> dict:
    scores: dict[str, int] = {}
    evidence: dict[str, str] = {}
    for name, fn in GRADERS:
        s, ev = fn(text)
        scores[name] = s
        evidence[name] = ev
    composite = sum(scores.values())
    weakest_dim = min(scores, key=lambda k: scores[k])
    improvements = improvement_hints(scores, evidence)
    return {
        "schema_version": SCHEMA_VERSION,
        "char_count": len(text),
        "composite": composite,
        "composite_max": 100,
        "scores": scores,
        "evidence": evidence,
        "weakest_dim": weakest_dim,
        "weakest_score": scores[weakest_dim],
        "improvements": improvements,
    }


IMPROVEMENT_HINTS = {
    "specificity": "Name more concrete paths, file refs, schemas, commit hashes. Vague intent loses to specific receipts.",
    "substrate_anchoring": "Reference paths that actually exist on disk; ground in real scripts/schemas/contracts.",
    "anti_staleness": "Add explicit time-bound gates (24h/48h/72h, auto-halt, stall classes). 'Work until done' is the staleness anti-pattern.",
    "reversibility": "Name the reversibility mechanism per move (git revert, env var flip, feature flag).",
    "exit_clarity": "Add EXIT or 'success when' clause to every phase with a measurable observable.",
    "mission_alignment": "Include both mission anchors verbatim near the top (continuous-orchestrator-uptime-self-sustaining-fleet + capability control plane).",
    "hard_but_achievable": "Balance — name at least one stall point AND ≥3 exit criteria. Trivial or impossible both fail.",
    "compounding_shape": "Show how phases feed each other; use 'compounds because' / 'feeds the next' language.",
    "cross_session_readable": "Include BASELINE section, anchors near top, self-contained note. Cold worker must pick up without context.",
    "limit_discipline": "Aim for ≥500 chars margin under 4000 — leaves room for evidence updates without re-trimming.",
}


def improvement_hints(scores: dict[str, int], evidence: dict[str, str]) -> list[str]:
    """Return top-3 weakest dims with hint + observed evidence."""
    sorted_dims = sorted(scores.items(), key=lambda kv: kv[1])
    out = []
    for dim, sc in sorted_dims[:3]:
        if sc >= 9:
            break
        hint = IMPROVEMENT_HINTS.get(dim, "")
        out.append(f"[{dim} {sc}/10] {hint} Observed: {evidence[dim]}")
    return out


def cmd_grade(args) -> int:
    path = Path(args.from_path)
    if not path.exists():
        print(f"file not found: {path}", file=sys.stderr)
        return 1
    text = path.read_text()
    result = grade_text(text)
    result["graded_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    result["goal_path"] = str(path)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(f"goal: {path}")
        print(f"chars: {result['char_count']}/{LIMIT}")
        print(f"composite: {result['composite']}/{result['composite_max']}  weakest: {result['weakest_dim']} ({result['weakest_score']}/10)")
        print("\nrubric:")
        for dim, sc in result["scores"].items():
            mark = "✓" if sc >= 9 else "↑" if sc >= 7 else "!"
            print(f"  {mark} {dim:30} {sc:2}/10   {result['evidence'][dim]}")
        if result["improvements"]:
            print("\nimprovements:")
            for imp in result["improvements"]:
                print(f"  - {imp}")
    return 0


def cmd_write_residue(args) -> int:
    goal_path = Path(args.goal_path)
    if not goal_path.exists():
        print(f"goal not found: {goal_path}", file=sys.stderr)
        return 1
    text = goal_path.read_text()
    result = grade_text(text)
    result["graded_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    result["goal_path"] = str(goal_path)
    # parse repo + slug from path: ~/Desktop/zeststream-goals/<repo>/<slug>-<date>.txt
    try:
        rel = goal_path.relative_to(Path.home() / "Desktop/zeststream-goals")
        result["repo"] = rel.parts[0]
        stem = rel.parts[-1].replace(".txt", "")
        # slug is everything before the trailing -YYYYMMDD
        m = re.match(r"^(.+?)-(\d{8})$", stem)
        result["slug"] = m.group(1) if m else stem
        result["date"] = m.group(2) if m else None
    except ValueError:
        result["repo"] = "unknown"
        result["slug"] = goal_path.stem
        result["date"] = None
    LEDGER_PATH.parent.mkdir(parents=True, exist_ok=True)
    with LEDGER_PATH.open("a") as f:
        f.write(json.dumps(result) + "\n")
    if args.json:
        print(json.dumps({"status": "appended", "ledger": str(LEDGER_PATH), "row": result}))
    else:
        print(f"appended → {LEDGER_PATH}")
        print(f"composite {result['composite']}/100  weakest {result['weakest_dim']} ({result['weakest_score']}/10)")
    return 0


def cmd_review(args) -> int:
    if not LEDGER_PATH.exists():
        out = {"rows": 0, "message": "no residue yet — write a goal to start the ledger"}
        print(json.dumps(out, indent=2) if args.json else out["message"])
        return 0
    rows = []
    with LEDGER_PATH.open() as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    if args.repo:
        rows = [r for r in rows if r.get("repo") == args.repo]
    if not rows:
        msg = f"no residue rows for repo={args.repo}" if args.repo else "ledger is empty"
        print(json.dumps({"rows": 0, "message": msg}, indent=2) if args.json else msg)
        return 0
    dim_avgs = {}
    for dim, _ in GRADERS:
        vals = [r["scores"].get(dim, 0) for r in rows if "scores" in r]
        dim_avgs[dim] = round(sum(vals) / len(vals), 1) if vals else 0.0
    composite_avg = round(sum(r["composite"] for r in rows) / len(rows), 1)
    weakest_counts = Counter(r["weakest_dim"] for r in rows if "weakest_dim" in r)
    sorted_weakest = weakest_counts.most_common(3)
    recent_hints = []
    for r in rows[-5:]:
        for imp in r.get("improvements", []):
            recent_hints.append(imp)
    report = {
        "schema_version": SCHEMA_VERSION,
        "ledger_path": str(LEDGER_PATH),
        "total_rows": len(rows),
        "repo_filter": args.repo,
        "composite_avg": composite_avg,
        "dim_avgs": dim_avgs,
        "weakest_dim_frequency": sorted_weakest,
        "recent_improvement_hints": recent_hints[-10:],
    }
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print(f"goal-doc residue ledger — {len(rows)} rows" + (f" (repo={args.repo})" if args.repo else ""))
        print(f"composite avg: {composite_avg}/100\n")
        print("dim avgs:")
        for dim, avg in sorted(dim_avgs.items(), key=lambda kv: kv[1]):
            mark = "✓" if avg >= 9 else "↑" if avg >= 7 else "!"
            print(f"  {mark} {dim:30} {avg:4}/10")
        if sorted_weakest:
            print("\nrecurring weakest dimensions:")
            for dim, cnt in sorted_weakest:
                print(f"  {dim} ({cnt}x)")
        if recent_hints:
            print("\nrecent improvement hints (last 10):")
            for hint in recent_hints[-10:]:
                print(f"  - {hint}")
    return 0


def cmd_weakest(args) -> int:
    """Print the dimension to prioritize in the NEXT goal."""
    if not LEDGER_PATH.exists():
        out = {"weakest_dim": None, "reason": "no residue yet"}
        print(json.dumps(out) if args.json else "no prior residue — first goal in ledger")
        return 0
    rows = []
    with LEDGER_PATH.open() as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    if not rows:
        out = {"weakest_dim": None, "reason": "ledger empty"}
        print(json.dumps(out) if args.json else "ledger empty")
        return 0
    weakest_counts = Counter(r["weakest_dim"] for r in rows if "weakest_dim" in r)
    top_weak = weakest_counts.most_common(1)[0][0] if weakest_counts else None
    hint = IMPROVEMENT_HINTS.get(top_weak, "") if top_weak else ""
    out = {
        "weakest_dim": top_weak,
        "freq": weakest_counts.get(top_weak, 0) if top_weak else 0,
        "hint": hint,
        "total_rows": len(rows),
    }
    if args.json:
        print(json.dumps(out))
    else:
        print(f"next goal should prioritize: {top_weak} ({weakest_counts.get(top_weak, 0)} prior occurrences)")
        print(f"hint: {hint}")
    return 0


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd")
    g = sub.add_parser("grade")
    g.add_argument("--from", dest="from_path", required=True)
    g.add_argument("--json", action="store_true")
    w = sub.add_parser("write-residue")
    w.add_argument("--goal", dest="goal_path", required=True)
    w.add_argument("--json", action="store_true")
    r = sub.add_parser("review")
    r.add_argument("--repo")
    r.add_argument("--json", action="store_true")
    wk = sub.add_parser("weakest")
    wk.add_argument("--json", action="store_true")
    args = p.parse_args(argv)
    if not args.cmd:
        p.print_help()
        return 2
    return {
        "grade": cmd_grade,
        "write-residue": cmd_write_residue,
        "review": cmd_review,
        "weakest": cmd_weakest,
    }[args.cmd](args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
