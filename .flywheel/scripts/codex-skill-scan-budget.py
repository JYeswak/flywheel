#!/usr/bin/env python3
"""Classify Codex skill filesystem scan budget pressure.

Codex has an internal directory-walk cap for skill discovery. Flywheel treats
that warning as blocking only when there is no configured skill-search MCP
fallback covering the same library.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any

SCHEMA_VERSION = "flywheel.codex_skill_scan_budget.v1"
DEFAULT_CAP = 2000


def count_dirs(root: Path) -> int:
    total = 0
    for _base, dirs, _files in os.walk(root, followlinks=False):
        total += 1
        dirs[:] = [d for d in dirs if not Path(_base, d).is_symlink()]
    return total


def count_skills(root: Path) -> int:
    return sum(1 for _ in root.rglob("SKILL.md")) if root.exists() else 0


def config_has_skill_search(config: Path) -> bool:
    if not config.exists():
        return False
    text = config.read_text(encoding="utf-8", errors="replace")
    return "[mcp_servers.skill-search]" in text and "skill-search-mcp" in text


def run(args: argparse.Namespace) -> int:
    roots = [Path(p).expanduser().resolve() for p in args.root]
    config = Path(args.config).expanduser().resolve()
    cap = int(args.cap)
    root_rows: list[dict[str, Any]] = []
    warning_codes: list[str] = []
    failure_codes: list[str] = []

    for root in roots:
        dirs = count_dirs(root) if root.exists() else 0
        skills = count_skills(root) if root.exists() else 0
        over_cap = dirs > cap
        if over_cap:
            warning_codes.append("INTERNAL_SCAN_CAP_EXCEEDED")
        if not root.exists():
            failure_codes.append("SKILL_ROOT_MISSING")
        root_rows.append(
            {
                "root": str(root),
                "exists": root.exists(),
                "dir_count": dirs,
                "skill_count": skills,
                "internal_cap": cap,
                "over_internal_cap": over_cap,
            }
        )

    fallback_configured = config_has_skill_search(config)
    if any(row["over_internal_cap"] for row in root_rows) and not fallback_configured:
        failure_codes.append("SKILL_SEARCH_MCP_NOT_CONFIGURED")

    status = "pass" if not failure_codes else "fail"
    if status == "pass" and any(row["over_internal_cap"] for row in root_rows):
        warning_codes.append("INTERNAL_SCAN_CAP_EXCEEDED_BUT_MCP_CONFIGURED")

    envelope = {
        "schema_version": SCHEMA_VERSION,
        "status": status,
        "internal_scan_cap": cap,
        "config": str(config),
        "skill_search_mcp_configured": fallback_configured,
        "roots": root_rows,
        "warning_codes": sorted(set(warning_codes)),
        "failure_codes": sorted(set(failure_codes)),
        "blocker_disposition": "not_blocking" if status == "pass" else "blocking",
        "operator_guidance": (
            "Do not prune dependency trees solely to silence the Codex internal warning; "
            "keep skill-search MCP as the authoritative large-library route."
            if status == "pass"
            else "Configure skill-search MCP or reduce the skill root below the internal scan cap."
        ),
    }
    print(json.dumps(envelope, indent=2 if args.pretty else None, sort_keys=True))
    return 0 if status == "pass" else 1


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", action="append", default=[])
    parser.add_argument("--config", default="/Users/josh/.codex/config.toml")
    parser.add_argument("--cap", type=int, default=DEFAULT_CAP)
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args(argv)
    if not args.root:
        args.root = ["/Users/josh/.codex/skills", "/Users/josh/.claude/skills"]
    return run(args)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
