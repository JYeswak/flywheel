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
]
LEVEL_SCORE = {"low": 0, "medium": 1, "high": 2}


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


SCORERS = {
    "bug_reality": score_bug_reality,
    "dedup": score_dedup,
    "source_trace": score_source_trace,
    "signal_not_prescription": score_signal_not_prescription,
    "tone_match": score_tone_match,
    "jeff_thank_test_hostile": score_jeff_thank_test_hostile,
    "no_derail": score_no_derail,
}


def score_draft(path: Path, text: str, *, checked_at: str) -> dict[str, Any]:
    axes = []
    for axis_id in AXES:
        result = SCORERS[axis_id](text)
        result["axis"] = axis_id
        axes.append(result)
    high_count = sum(1 for item in axes if item["level"] == "high")
    if high_count == 7:
        decision = "auto_post"
    elif high_count == 6:
        decision = "revise"
    else:
        decision = "withdraw"
    hard_fail = [item["axis"] for item in axes if item["level"] != "high"]
    suggestions = [
        {"axis": item["axis"], "suggestions": item["suggestions"]}
        for item in axes
        if item["suggestions"]
    ]
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
    return {
        "schema_version": "jeff-issue-rubric-doctor/v1",
        "checked_at": checked_at,
        "draft_glob": draft_glob,
        "receipts_dir": str(receipts_dir),
        "drafts_checked_count": len(rows),
        "jeff_drafts_unrubricd_count": len(unrubricd),
        "top_unrubricd_drafts": unrubricd[:10],
        "rows": rows,
        "status": "fail" if unrubricd else "pass",
        "signals": [
            {
                "name": "jeff_drafts_unrubricd_count",
                "producer": ".flywheel/scripts/jeff-issue-rubric.py --doctor",
                "measurement": "count /tmp/jeff-issue-*.md drafts without a current hash-matched rubric receipt",
                "consumer": "flywheel-loop doctor JSON and Jeff issue posting gate",
                "threshold": ">=1",
                "gate_behavior": "warn in normal doctor; fail in strict",
                "promotion_path": "feedback_jeff_issue_chain -> flywheel-3p1j",
            }
        ],
    }


def schema_payload() -> dict[str, Any]:
    return {
        "schema_version": SCHEMA_VERSION,
        "axes": AXES,
        "levels": ["low", "medium", "high"],
        "required_output_fields": ["draft_path", "draft_sha256", "status", "decision", "high_axes_count", "axes", "hard_fail_axes"],
        "decision_policy": {"7_high": "auto_post", "6_high": "revise", "0_to_5_high": "withdraw"},
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
    payload = score_draft(draft, text, checked_at=checked_at)
    if args.write_receipt:
        payload["receipt_path"] = str(write_receipt(payload, receipts_dir))
    print(json.dumps(payload, indent=2 if args.json else None, sort_keys=True))
    return 0 if payload["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
