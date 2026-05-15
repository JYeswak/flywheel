#!/usr/bin/env python3
"""Lint a /goal-mode goal text against the accretive-watch contract.

Checks (derived from the session-tested regime in
~/Desktop/flywheel-watch-goal.txt):
  - Length ≤4000 chars (the /goal command's hard limit).
  - Names ACT, ACCRETE, and STAND DOWN as the three per-cycle output
    options (per-cycle output rule).
  - Declares wake triggers in priority order (operator input, commits,
    CI, worker state, prior-cycle findings, heartbeat).
  - Has an anti-spin clause (3-identical-cycles → STAND DOWN, or
    equivalent).
  - Names accretion targets across visual/technical/operational angles.
  - Specifies an output format per cycle (ACT/ACCRETE/STAND DOWN line
    shapes).
  - Names a rolling log destination (`.flywheel/evidence/...jsonl`).

This is a STRUCTURAL lint, not a semantic judge. It catches goals that
forget load-bearing mechanics; it does not score quality.

Exit codes:
  0  all checks pass
  1  one or more checks fail
  2  file unreadable
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

SCHEMA_VERSION = "flywheel.goal_text_lint.v0"

MAX_CHARS = 4000

# Each check: (id, label, regex). Case-insensitive on the goal text.
CHECKS: list[tuple[str, str, re.Pattern[str]]] = [
    (
        "cycle_types_named",
        "names ACT, ACCRETE, and STAND DOWN cycle types",
        re.compile(r"\bACT\b.*\bACCRETE\b.*\bSTAND[\s_-]?DOWN\b", re.IGNORECASE | re.DOTALL),
    ),
    (
        "wake_triggers_declared",
        "declares wake triggers (priority list)",
        re.compile(r"WAKE\s+TRIGGER", re.IGNORECASE),
    ),
    (
        "wake_includes_operator_input",
        "wake triggers include operator input",
        re.compile(r"operator\s+input", re.IGNORECASE),
    ),
    (
        "wake_includes_new_commit",
        "wake triggers include new commit / HEAD move",
        re.compile(r"new\s+commit|HEAD\s+move", re.IGNORECASE),
    ),
    (
        "anti_spin_clause",
        "has an anti-spin clause",
        re.compile(r"ANTI[\s_-]?SPIN|identical.{0,80}STAND[\s_-]?DOWN", re.IGNORECASE | re.DOTALL),
    ),
    (
        "accretion_targets",
        "names accretion targets (visual / technical / operational)",
        re.compile(r"ACCRETION\s+TARGETS?", re.IGNORECASE),
    ),
    (
        "accretion_three_angles",
        "accretion targets cover all three angles (visually + technically + operationally)",
        re.compile(r"visual.{0,500}technical.{0,500}operational", re.IGNORECASE | re.DOTALL),
    ),
    (
        "output_format_spec",
        "specifies a per-cycle output format",
        re.compile(r"OUTPUT\s+FORMAT", re.IGNORECASE),
    ),
    (
        "rolling_log_named",
        "names a rolling log path under .flywheel/evidence/",
        re.compile(r"\.flywheel/evidence/.*\.jsonl", re.IGNORECASE),
    ),
    (
        "accretion_classes_named",
        "names the accretion-class menu (doctrine / skill / gate / knowledge / decision)",
        re.compile(
            r"doctrine\s+refinement.*(?:skill\s+candidate|gate\s+hardening|"
            r"knowledge\s+pack|decision\s+record|coverage\s+backfill)",
            re.IGNORECASE | re.DOTALL,
        ),
    ),
]


def lint(text: str) -> dict:
    checks: list[dict] = []
    char_count = len(text)
    checks.append(
        {
            "id": "length_under_4k",
            "label": f"goal text ≤{MAX_CHARS} chars",
            "pass": char_count <= MAX_CHARS,
            "actual": char_count,
            "limit": MAX_CHARS,
        }
    )
    for check_id, label, pattern in CHECKS:
        checks.append(
            {
                "id": check_id,
                "label": label,
                "pass": bool(pattern.search(text)),
            }
        )
    fails = [c for c in checks if not c["pass"]]
    return {
        "schema_version": SCHEMA_VERSION,
        "char_count": char_count,
        "char_limit": MAX_CHARS,
        "check_count": len(checks),
        "pass_count": len(checks) - len(fails),
        "fail_count": len(fails),
        "status": "pass" if not fails else "fail",
        "checks": checks,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--file", help="goal text file (default: stdin)")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    if args.file:
        path = Path(args.file)
        if not path.exists():
            print(f"file not found: {path}", file=sys.stderr)
            return 2
        text = path.read_text()
    else:
        text = sys.stdin.read()

    result = lint(text)

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(
            f"status={result['status']} chars={result['char_count']}/{result['char_limit']} "
            f"pass={result['pass_count']}/{result['check_count']}"
        )
        for c in result["checks"]:
            mark = "PASS" if c["pass"] else "FAIL"
            print(f"  {mark} {c['label']}")

    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
