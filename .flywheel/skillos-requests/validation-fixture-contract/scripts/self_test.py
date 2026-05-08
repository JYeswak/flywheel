#!/usr/bin/env python3
"""Validate the draft validation-fixture-contract skill."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


REQUIRED_SECTIONS = [
    "## Trigger Phrases",
    "## Source Evidence",
    "## Hard Rules",
    "## Fixture ID Taxonomy",
    "## Replay Command Template",
    "## Expected Receipt Schema",
    "## Exact Prompt For Skillos",
    "## Anti-Patterns",
    "## Executable Self-Test",
    "## Publication Staging",
]

REQUIRED_TERMS = [
    "schema_version",
    "--json",
    "--dry-run",
    "expected receipt",
    "frontmatter",
    "fixture_id",
    "replay_command",
    "jsm push",
]


def fail(message: str) -> None:
    print(json.dumps({"status": "fail", "reason": message}, sort_keys=True))
    raise SystemExit(1)


def frontmatter(body: str) -> str:
    if not body.startswith("---\n"):
        fail("missing YAML frontmatter")
    end = body.find("\n---\n", 4)
    if end == -1:
        fail("unterminated YAML frontmatter")
    return body[4:end]


def section(body: str, title: str) -> str:
    start = body.find(title)
    if start == -1:
        fail(f"missing section: {title}")
    next_match = re.search(r"^## ", body[start + len(title) :], flags=re.MULTILINE)
    if next_match:
        return body[start : start + len(title) + next_match.start()]
    return body[start:]


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    skill = root / "SKILL.md"
    script = root / "scripts" / "self_test.py"
    if not skill.exists():
        fail("SKILL.md not found")
    if not script.exists():
        fail("scripts/self_test.py not found")

    body = skill.read_text(encoding="utf-8")
    fm = frontmatter(body)
    if "name: validation-fixture-contract" not in fm:
        fail("frontmatter missing skill name")
    if "description:" not in fm:
        fail("frontmatter missing description")

    for title in REQUIRED_SECTIONS:
        if title not in body:
            fail(f"missing required section: {title}")

    trigger_block = section(body, "## Trigger Phrases")
    trigger_count = len(re.findall(r"^- ", trigger_block, flags=re.MULTILINE))
    if trigger_count < 10:
        fail(f"expected at least 10 trigger phrases, found {trigger_count}")

    hard_rules = section(body, "## Hard Rules")
    hard_rule_count = len(re.findall(r"^\d+\. ", hard_rules, flags=re.MULTILINE))
    if hard_rule_count < 8:
        fail(f"expected at least 8 hard rules, found {hard_rule_count}")

    anti_patterns = section(body, "## Anti-Patterns")
    table_rows = len(re.findall(r"^\| ", anti_patterns, flags=re.MULTILINE))
    if table_rows < 5:
        fail("anti-pattern table too small")

    lowered = body.lower()
    for term in REQUIRED_TERMS:
        if term.lower() not in lowered:
            fail(f"missing required term: {term}")

    print(json.dumps({"status": "pass", "checks": 11}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
