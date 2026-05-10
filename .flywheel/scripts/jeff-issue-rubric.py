#!/usr/bin/env python3
"""Deterministic 7-axis quality gate for Jeff issue drafts."""

from __future__ import annotations

import argparse
import glob
import hashlib
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "jeff-issue-rubric/v1"
DEFAULT_RUBRIC = ".flywheel/jeff-issue-rubric/v1/rubric.json"
DEFAULT_RECEIPTS = ".flywheel/jeff-issue-rubric/v1/receipts"
DEFAULT_DRAFT_GLOB = "/tmp/jeff-issue-*.md"
AXES = [
    "bug_reality",
    "dedup",
    "source_trace",
    "signal_not_prescription",
    "tone_match",
    "jeff_thank_test_hostile",
    "no_derail",
    "corpus_aware",
]
LEVEL_SCORE = {"low": 0, "medium": 1, "high": 2}
HIGH_COUNT_FOR_AUTO_POST = len(AXES)        # all axes high
HIGH_COUNT_FOR_REVISE = len(AXES) - 1       # exactly one off-high

# Corpus-scan citation categories — bead flywheel-wbnb AG1.
# The rubric inspects the DRAFT for textual citation evidence; the
# orchestrator-side cross-collection-fanout producer is what actually
# runs `mcp__socraticode__codebase_search`. Architecture rationale:
# socraticode is MCP-only and not directly callable from a Python CLI;
# the producer/consumer split keeps the rubric a deterministic checker
# while still surfacing whether the draft author cited the corpus.
CORPUS_CATEGORIES = [
    "same_issue_already_filed",
    "prior_art",
    "shape_precedent",
    "anti_pattern",
]


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def resolve_path(repo: Path, value: str) -> Path:
    expanded = os.path.expanduser(value)
    path = Path(expanded)
    if not path.is_absolute():
        path = repo / path
    return path


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def has_any(text: str, patterns: list[str]) -> bool:
    lowered = text.lower()
    return any(pattern.lower() in lowered for pattern in patterns)


def re_count(pattern: str, text: str) -> int:
    return len(re.findall(pattern, text, flags=re.IGNORECASE | re.MULTILINE))


def axis(level: str, findings: list[str], suggestions: list[str], evidence: list[str]) -> dict[str, Any]:
    return {
        "level": level,
        "score": LEVEL_SCORE[level],
        "threshold": "high",
        "passed": level == "high",
        "findings": findings,
        "suggestions": suggestions,
        "evidence": evidence,
    }


def score_bug_reality(text: str) -> dict[str, Any]:
    checks = {
        "observed": has_any(text, ["observed:", "**observed", "what happened"]),
        "expected": has_any(text, ["expected:", "**expected", "expected vs observed"]),
        "repro": has_any(text, ["repro:", "**repro", "```bash", "```sh"]),
        "version": bool(re.search(r"(@|commit|version|v\d+\.\d+|HEAD|pushedAt)", text, re.I)),
        "cost": has_any(text, ["cost citation", "why this matters", "breaks downstream", "leakage_count", "silent", "cross-project"]),
    }
    count = sum(checks.values())
    if count == 5:
        return axis("high", ["all bug-reality proof elements present"], [], [key for key, ok in checks.items() if ok])
    if count >= 3:
        missing = [key for key, ok in checks.items() if not ok]
        return axis("medium", [f"missing {', '.join(missing)}"], ["Add the missing bug-reality proof element(s)."], [key for key, ok in checks.items() if ok])
    return axis("low", ["draft lacks enough reproducible bug proof"], ["Add observed, expected, repro, version, and cost citation."], [key for key, ok in checks.items() if ok])


def score_dedup(text: str) -> dict[str, Any]:
    normalized = re.sub(r"\s+", " ", text.lower())
    has_command = "gh issue list" in normalized and "--search" in normalized
    has_result = any(phrase in normalized for phrase in ["no visible duplicate", "returned no visible duplicates", "no duplicate"])
    if has_command and has_result:
        return axis("high", ["duplicate-search command and result present"], [], ["gh issue list", "no duplicate"])
    if has_command or has_any(text, ["duplicate", "dedup"]):
        return axis("medium", ["duplicate search is incomplete"], ["Record exact `gh issue list --search` command and result."], ["duplicate mentioned"])
    return axis("low", ["no duplicate-search evidence"], ["Run and cite targeted `gh issue list --repo Dicklesworthstone/<repo> --search ...`."], [])


def score_source_trace(text: str) -> dict[str, Any]:
    refs = re.findall(r"\b[\w./-]+\.(?:go|sql|rs|py|md|sh|ts|tsx|json):\d+\b", text)
    has_version = bool(re.search(r"Dicklesworthstone/[\w.-]+@[\da-f]{7,}|commit|HEAD|pushedAt", text, re.I))
    if len(refs) >= 4 and has_version:
        return axis("high", [f"{len(refs)} file:line citations plus version context"], [], refs[:8])
    if len(refs) >= 2:
        return axis("medium", [f"{len(refs)} file:line citations; version context present={has_version}"], ["Add enough file:line citations and commit/version context to trace the contract."], refs[:8])
    return axis("low", ["insufficient source trace"], ["Cite upstream file:line locations for the failing primitive."], refs[:8])


def score_signal_not_prescription(text: str) -> dict[str, Any]:
    prescriptive = re_count(r"\b(should|must|need to|add|change|recreate|migration|proposed fix|follow-up should|patch|PR)\b", text)
    bounded = has_any(text, ["out of scope", "not asking", "not requesting", "prior art"])
    if prescriptive <= 1 and bounded:
        return axis("high", ["contract gap is bounded without implementation prescription"], [], [f"prescriptive_terms={prescriptive}", "out_of_scope"])
    if bounded:
        return axis("medium", [f"contains {prescriptive} prescriptive terms but has boundary language"], ["Move fix sketches to prior-art language or remove implementation instructions."], [f"prescriptive_terms={prescriptive}", "out_of_scope"])
    return axis("low", [f"contains {prescriptive} prescriptive terms without clear non-prescriptive boundary"], ["Rewrite as observed contract gap plus expected behavior; remove implementation instructions."], [f"prescriptive_terms={prescriptive}"])


def score_tone_match(text: str) -> dict[str, Any]:
    word_count = len(re.findall(r"\w+", text))
    has_tracking = bool(re.search(r"flywheel-[a-z0-9]+", text))
    hedges = re_count(r"\b(maybe|possibly|I think|sorry|apologize|amazing|huge thanks|incredible)\b", text)
    sections = re_count(r"^#{1,3}\s+|\*\*[^*\n]+:\*\*", text)
    if word_count <= 1200 and has_tracking and hedges == 0 and sections >= 6:
        return axis("high", ["direct, structured, tracked, and low-hedge"], [], [f"words={word_count}", f"sections={sections}", "tracking"])
    if word_count <= 1600 and has_tracking and hedges <= 2:
        return axis("medium", ["mostly usable tone with minor structure or hedge issues"], ["Tighten length, remove hedges/praise, or add tracking continuity."], [f"words={word_count}", f"hedges={hedges}", f"sections={sections}"])
    return axis("low", ["tone/structure misses Jeff issue contract"], ["Make it shorter, direct, evidence-led, and include tracking bead."], [f"words={word_count}", f"hedges={hedges}", f"sections={sections}"])


def score_jeff_thank_test_hostile(text: str) -> dict[str, Any]:
    bad = re.findall(r"\b(thanks!?|thank you|amazing|urgent|ASAP|you broke|broken again|why did you|vendor|customer|SLA)\b", text, flags=re.I)
    hostile = re.findall(r"\b(ridiculous|unacceptable|obviously|just fix|should be easy)\b", text, flags=re.I)
    if not bad and not hostile:
        return axis("high", ["no generic thanks, demand, vendor, or hostile wording"], [], [])
    if len(bad) <= 1 and not hostile:
        return axis("medium", ["minor generic/noisy phrasing"], ["Remove generic thanks or pressure; use specific acknowledgement only when replying."], bad)
    return axis("low", ["hostile or noisy wording present"], ["Remove vendor/customer framing, generic praise, urgency pressure, and hostile language."], bad + hostile)


def score_no_derail(text: str) -> dict[str, Any]:
    secretish = re.findall(r"\b(sk-[A-Za-z0-9_-]{10,}|ghp_[A-Za-z0-9_]{10,}|xox[baprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{12,})\b", text)
    asks_pr = has_any(text, ["pull request", "submit pr", "merge this", "please apply this patch"])
    broad_feature = bool(re.search(r"\b(new feature|feature request|would be nice|could you add support for)\b", text, re.I))
    out_scope = has_any(text, ["out of scope", "not asking", "not requesting"])
    tracking = bool(re.search(r"flywheel-[a-z0-9]+", text))
    if not secretish and not asks_pr and not broad_feature and out_scope and tracking:
        return axis("high", ["no derail risks detected"], [], ["out_of_scope", "tracking"])
    issues = []
    if secretish:
        issues.append("secret_like_token")
    if asks_pr:
        issues.append("pr_or_patch_ask")
    if broad_feature:
        issues.append("broad_feature_language")
    if not out_scope:
        issues.append("missing_out_of_scope")
    if not tracking:
        issues.append("missing_tracking_bead")
    level = "medium" if len(issues) == 1 and not secretish and not asks_pr else "low"
    return axis(level, issues, ["Remove derail risks and add explicit out-of-scope plus tracking bead."], issues)


def categorize_corpus_citations(text: str) -> dict[str, list[str]]:
    """Bucket draft-internal corpus citations into 4 canonical categories.
    Returns dict[category] = list of evidence excerpts (first 8 per category).

    Bead flywheel-wbnb AG1.
    """
    buckets: dict[str, list[str]] = {c: [] for c in CORPUS_CATEGORIES}

    # Anchor: any reference to Dicklesworthstone/<repo> or its GitHub URL
    # forms. Each category then matches a contextual cue around the anchor.
    cite_anchor = re.compile(
        r"(Dicklesworthstone/[A-Za-z0-9_.\-]+(?:[#@/][A-Za-z0-9_.\-]+)?|"
        r"github\.com/Dicklesworthstone/[A-Za-z0-9_./#-]+)",
        re.IGNORECASE,
    )

    same_issue_cues = re.compile(
        r"\b(see (?:also )?issue\s*#?\d+|already filed|duplicate of\s*#?\d+|"
        r"existing issue|tracked at\s*#?\d+|comment(?:ed)? on\s*#?\d+)\b",
        re.IGNORECASE,
    )
    prior_art_cues = re.compile(
        r"\b(prior art|Jeff(?:rey)? (?:also|already) (?:did|solved|fixed|implemented)|"
        r"consistent with .*? in (?:repo|the)\s+\S+|"
        r"already solved in [A-Za-z0-9_.\-/]+)\b",
        re.IGNORECASE,
    )
    shape_cues = re.compile(
        r"\b(Jeff(?:rey)?'s? (?:idiom|API convention|pattern|shape)|"
        r"matches the pattern in|same shape as|mirrors? .*? convention|"
        r"API convention[s]? for this primitive)\b",
        re.IGNORECASE,
    )
    anti_pattern_cues = re.compile(
        r"\b(Jeff(?:rey)? (?:explicitly )?rejected|anti-?pattern in|"
        r"avoided pattern|Jeff (?:has )?said no to|removed in upstream)\b",
        re.IGNORECASE,
    )

    # Walk lines so each citation lives near its category cue (5-line window).
    lines = text.splitlines()
    for idx, line in enumerate(lines):
        if not cite_anchor.search(line):
            continue
        # Inspect a small surrounding window for category cue presence.
        lo = max(0, idx - 2)
        hi = min(len(lines), idx + 3)
        window = "\n".join(lines[lo:hi])
        snippet = line.strip()[:200]
        if same_issue_cues.search(window):
            buckets["same_issue_already_filed"].append(snippet)
        elif anti_pattern_cues.search(window):
            buckets["anti_pattern"].append(snippet)
        elif prior_art_cues.search(window):
            buckets["prior_art"].append(snippet)
        elif shape_cues.search(window):
            buckets["shape_precedent"].append(snippet)
        else:
            # Uncategorized citation — count toward prior_art by default
            # so the author still gets credit for citing the corpus.
            buckets["prior_art"].append(snippet)
    # cap each bucket at 8 to keep envelopes readable
    return {k: v[:8] for k, v in buckets.items()}


def score_corpus_aware(text: str) -> dict[str, Any]:
    buckets = categorize_corpus_citations(text)
    counts = {k: len(v) for k, v in buckets.items()}
    total = sum(counts.values())
    same_issue = counts["same_issue_already_filed"]
    distinct_categories = sum(1 for c in counts.values() if c > 0)

    # Hard-fail signal — same-issue-already-filed citation in the draft
    # means the orchestrator should amend an existing issue rather than
    # file a new one. Bead AG4 makes this a blocker.
    if same_issue > 0:
        return axis(
            "low",
            [f"draft cites {same_issue} same-issue-already-filed reference(s); amend existing instead of file new"],
            ["Resolve the cited existing issue(s) first; either amend with new evidence or close this draft."],
            [f"same_issue_count={same_issue}", f"total_citations={total}"],
        )
    # No corpus citations at all → low
    if total == 0:
        return axis(
            "low",
            ["draft has zero corpus citations; orchestrator should run cross-collection-fanout against the indexed Jeff corpus before filing"],
            ["Inject prior-art / shape-precedent / anti-pattern citations from the corpus-scan output, or attach the citation block emitted by cross-collection-fanout."],
            [f"total_citations=0"],
        )
    # 1 citation or only one category → medium
    if total < 2 or distinct_categories < 2:
        return axis(
            "medium",
            [f"only {total} citation(s) in {distinct_categories} category/categories; corpus-aware threshold is 2+ across 2+ categories"],
            ["Add at least one more corpus citation in a different category (prior_art / shape_precedent / anti_pattern)."],
            [f"total_citations={total}", f"distinct_categories={distinct_categories}"],
        )
    # 2+ citations across 2+ categories, no same-issue blocker → high
    return axis(
        "high",
        [f"{total} corpus citations across {distinct_categories} categories with no same-issue blocker"],
        [],
        [f"total_citations={total}", f"distinct_categories={distinct_categories}"],
    )


def render_citation_block(buckets: dict[str, list[str]]) -> str:
    """Markdown citation block for issue-body injection (bead AG2)."""
    out = ["## Corpus-aware citations (cross-collection-fanout)"]
    any_section = False
    for cat in CORPUS_CATEGORIES:
        items = buckets.get(cat) or []
        if not items:
            continue
        any_section = True
        title = cat.replace("_", " ").title()
        out.append(f"\n### {title} ({len(items)})")
        for snippet in items:
            out.append(f"- {snippet}")
    if not any_section:
        out.append("\n_No corpus citations present; run cross-collection-fanout before filing._")
    return "\n".join(out) + "\n"


SCORERS = {
    "bug_reality": score_bug_reality,
    "dedup": score_dedup,
    "source_trace": score_source_trace,
    "signal_not_prescription": score_signal_not_prescription,
    "tone_match": score_tone_match,
    "jeff_thank_test_hostile": score_jeff_thank_test_hostile,
    "no_derail": score_no_derail,
    "corpus_aware": score_corpus_aware,
}


def score_draft(path: Path, text: str, *, checked_at: str, corpus_scan_enabled: bool = False) -> dict[str, Any]:
    # Backwards-compat: when --corpus-scan is NOT set, evaluate only the
    # original 7 axes so existing fixtures and tests continue to pass.
    # The corpus_aware axis lights up only when explicitly requested.
    active_axes = AXES if corpus_scan_enabled else [a for a in AXES if a != "corpus_aware"]
    axes = []
    for axis_id in active_axes:
        result = SCORERS[axis_id](text)
        result["axis"] = axis_id
        axes.append(result)
    high_count = sum(1 for item in axes if item["level"] == "high")
    high_for_auto = len(active_axes)
    high_for_revise = len(active_axes) - 1
    if high_count == high_for_auto:
        decision = "auto_post"
    elif high_count == high_for_revise:
        decision = "revise"
    else:
        decision = "withdraw"
    hard_fail = [item["axis"] for item in axes if item["level"] != "high"]
    suggestions = [
        {"axis": item["axis"], "suggestions": item["suggestions"]}
        for item in axes
        if item["suggestions"]
    ]
    corpus_buckets = categorize_corpus_citations(text)
    return {
        "schema_version": SCHEMA_VERSION,
        "checked_at": checked_at,
        "draft_path": str(path),
        "draft_sha256": sha256_text(text),
        "status": "pass" if not hard_fail else "fail",
        "decision": decision,
        "high_axes_count": high_count,
        "axes_count": len(axes),
        "threshold": "high",
        "hard_fail_axes": hard_fail,
        "axes": axes,
        "suggested_revisions": suggestions,
        "corpus_scan": {
            "categories": {k: len(v) for k, v in corpus_buckets.items()},
            "buckets": corpus_buckets,
            "citation_block_md": render_citation_block(corpus_buckets),
            "same_issue_blocker": len(corpus_buckets["same_issue_already_filed"]) > 0,
        },
    }


def receipt_path(receipts_dir: Path, draft_hash: str) -> Path:
    return receipts_dir / f"{draft_hash[:16]}.json"


def write_receipt(payload: dict[str, Any], receipts_dir: Path) -> Path:
    receipts_dir.mkdir(parents=True, exist_ok=True)
    path = receipt_path(receipts_dir, payload["draft_sha256"])
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return path


def load_receipt(path: Path) -> dict[str, Any] | None:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None
    return data if isinstance(data, dict) else None


def doctor_payload(repo: Path, draft_glob: str, receipts_dir: Path, checked_at: str) -> dict[str, Any]:
    rows = []
    for raw in sorted(glob.glob(os.path.expanduser(draft_glob))):
        path = Path(raw)
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        draft_hash = sha256_text(text)
        expected_receipt = receipt_path(receipts_dir, draft_hash)
        receipt = load_receipt(expected_receipt) if expected_receipt.exists() else None
        rubric_current = bool(receipt and receipt.get("draft_sha256") == draft_hash and receipt.get("schema_version") == SCHEMA_VERSION)
        rows.append(
            {
                "draft_path": str(path),
                "draft_sha256": draft_hash,
                "rubric_current": rubric_current,
                "receipt_path": str(expected_receipt),
                "decision": receipt.get("decision") if receipt else None,
                "status": receipt.get("status") if receipt else None,
            }
        )
    unrubricd = [row for row in rows if not row["rubric_current"]]

    # Corpus-scan signal — count drafts whose body has zero corpus
    # citations (any category). Bead flywheel-wbnb AG5.
    unscanned_rows = []
    for raw in sorted(glob.glob(os.path.expanduser(draft_glob))):
        path = Path(raw)
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        buckets = categorize_corpus_citations(text)
        total = sum(len(v) for v in buckets.values())
        if total == 0:
            unscanned_rows.append({"draft_path": str(path), "total_citations": 0})

    return {
        "schema_version": "jeff-issue-rubric-doctor/v1",
        "checked_at": checked_at,
        "draft_glob": draft_glob,
        "receipts_dir": str(receipts_dir),
        "drafts_checked_count": len(rows),
        "jeff_drafts_unrubricd_count": len(unrubricd),
        "jeff_drafts_unscanned_count": len(unscanned_rows),
        "top_unrubricd_drafts": unrubricd[:10],
        "top_unscanned_drafts": unscanned_rows[:10],
        "rows": rows,
        "status": "fail" if (unrubricd or unscanned_rows) else "pass",
        "signals": [
            {
                "name": "jeff_drafts_unrubricd_count",
                "producer": ".flywheel/scripts/jeff-issue-rubric.py --doctor",
                "measurement": "count /tmp/jeff-issue-*.md drafts without a current hash-matched rubric receipt",
                "consumer": "flywheel-loop doctor JSON and Jeff issue posting gate",
                "threshold": ">=1",
                "gate_behavior": "warn in normal doctor; fail in strict",
                "promotion_path": "feedback_jeff_issue_chain -> flywheel-3p1j",
            },
            {
                "name": "jeff_drafts_unscanned_count",
                "producer": ".flywheel/scripts/jeff-issue-rubric.py --doctor",
                "measurement": "count /tmp/jeff-issue-*.md drafts with zero corpus-scan citations across all 4 categories",
                "consumer": "flywheel-loop doctor JSON and Jeff issue posting gate",
                "threshold": ">=1",
                "gate_behavior": "warn in normal doctor; fail in strict",
                "promotion_path": "feedback_jeff_issue_chain -> flywheel-wbnb",
            },
        ],
    }


def schema_payload() -> dict[str, Any]:
    return {
        "schema_version": SCHEMA_VERSION,
        "axes": AXES,
        "levels": ["low", "medium", "high"],
        "required_output_fields": [
            "draft_path", "draft_sha256", "status", "decision",
            "high_axes_count", "axes", "hard_fail_axes",
        ],
        "decision_policy": {
            f"{HIGH_COUNT_FOR_AUTO_POST}_high": "auto_post",
            f"{HIGH_COUNT_FOR_REVISE}_high": "revise",
            f"0_to_{HIGH_COUNT_FOR_REVISE - 1}_high": "withdraw",
        },
        "exit_codes": {
            "0": "rubric pass",
            "1": "rubric fail (one or more axes < high)",
            "4": "same-issue-already-filed corpus citation present (--corpus-scan; AG4 blocker)",
        },
        "corpus_categories": CORPUS_CATEGORIES,
    }


def examples_payload() -> dict[str, Any]:
    return {
        "high_quality": "Expected decision auto_post when all seven axes are high.",
        "low_quality": "Expected decision withdraw when most axes are low or medium.",
        "ambiguous": "Expected decision revise when exactly six axes are high.",
        "anti_pattern": "Expected decision withdraw when prescription/derail risks dominate.",
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="jeff-issue-rubric.py")
    parser.add_argument("--repo", default=".")
    parser.add_argument("--draft")
    parser.add_argument("--rubric", default=DEFAULT_RUBRIC)
    parser.add_argument("--receipts-dir", default=DEFAULT_RECEIPTS)
    parser.add_argument("--draft-glob", default=DEFAULT_DRAFT_GLOB)
    parser.add_argument("--write-receipt", action="store_true")
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument(
        "--corpus-scan",
        action="store_true",
        help="(bead flywheel-wbnb AG1) emit corpus-scan citation block + categorize "
             "draft-internal corpus citations. Same-issue-already-filed hits force "
             "exit code 4 (block draft until amend-or-withdraw decision). The actual "
             "live MCP-driven socraticode search is owned by the orchestrator-side "
             "cross-collection-fanout producer and writes its citations into the "
             "draft body BEFORE this rubric runs (produce-then-consume architecture).",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo = Path(args.repo).expanduser().resolve()
    checked_at = utc_now()
    if args.schema:
        print(json.dumps(schema_payload(), indent=2, sort_keys=True))
        return 0
    if args.examples:
        print(json.dumps(examples_payload(), indent=2, sort_keys=True))
        return 0
    receipts_dir = resolve_path(repo, args.receipts_dir)
    if args.doctor:
        payload = doctor_payload(repo, args.draft_glob, receipts_dir, checked_at)
        print(json.dumps(payload, indent=2 if args.json else None, sort_keys=True))
        return 1 if args.strict and payload["jeff_drafts_unrubricd_count"] > 0 else 0
    if not args.draft:
        raise SystemExit("--draft is required unless --doctor/--schema/--examples is used")
    draft = resolve_path(repo, args.draft)
    text = draft.read_text(encoding="utf-8", errors="replace")
    payload = score_draft(draft, text, checked_at=checked_at, corpus_scan_enabled=args.corpus_scan)
    if args.write_receipt:
        payload["receipt_path"] = str(write_receipt(payload, receipts_dir))
    print(json.dumps(payload, indent=2 if args.json else None, sort_keys=True))
    # AG4 — same-issue-already-filed citation is a hard blocker
    # (operator must amend the existing issue rather than file new).
    # Use exit code 4 to make this distinct from generic rubric-fail (1).
    if args.corpus_scan and payload.get("corpus_scan", {}).get("same_issue_blocker"):
        return 4
    return 0 if payload["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
