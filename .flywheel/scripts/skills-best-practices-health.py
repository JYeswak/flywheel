#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any

SCHEMA_VERSION = "skills-best-practices-doctor/v1"
DEFAULT_SKILLS_ROOT = Path.home() / ".claude" / "skills"
DEFAULT_LOAD_BEARING_SKILLS = (
    "canonical-cli-scoping",
    "beads-workflow",
    "beads-br",
    "agent-mail",
    "python-best-practices",
    "rust-best-practices",
    "readme-writing",
    "commit",
    "agent-orchestration",
    "agent-security",
)


def read_skill_md(path: Path) -> tuple[str | None, dict[str, Any] | None]:
    try:
        data = path.read_bytes()
    except OSError as exc:
        return None, {"code": "skill_md_unreadable", "path": str(path), "error": str(exc)}
    if not data.strip():
        return None, {"code": "skill_md_empty", "path": str(path)}
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError as exc:
        return None, {"code": "skill_md_decode_error", "path": str(path), "error": str(exc)}
    return text, None


def skill_dirs(root: Path) -> tuple[list[Path], int]:
    candidates = [p for p in root.iterdir() if p.is_dir() and not p.name.startswith(".")]
    return sorted((p for p in candidates if (p / "SKILL.md").is_file()), key=lambda p: p.name), len(candidates)


def first_parse_warning(skill_name: str, path: Path, text: str) -> dict[str, Any] | None:
    head = text[:3000].lower()
    if "description:" not in head:
        return {"code": "skill_md_missing_description", "skill": skill_name, "path": str(path)}
    return None


def bead_recommendation(status: str, errors: list[dict[str, Any]], warnings: list[dict[str, Any]]) -> dict[str, Any] | None:
    if status == "ok":
        return None
    codes = sorted({str(item.get("code")) for item in errors + warnings if item.get("code")})
    return {
        "recommended": True,
        "title": "[skills-best-practices] repair skills library corruption",
        "priority": "P1" if status == "blocked" else "P2",
        "reason": "skills-library corruption or drift detected by read-only doctor",
        "evidence_codes": codes,
        "must_not_mutate_skills_in_doctor": True,
    }


def doctor(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    root = Path(args.skills_root).expanduser()
    expected = list(dict.fromkeys(args.expected_skill or DEFAULT_LOAD_BEARING_SKILLS))
    warnings: list[dict[str, Any]] = []
    errors: list[dict[str, Any]] = []

    if not root.exists():
        errors.append({"code": "skills_root_missing", "path": str(root)})
        status = "blocked"
        payload = base_payload(args, root, expected) | {
            "status": status,
            "errors": errors,
            "warnings": warnings,
            "bead_recommendation": bead_recommendation(status, errors, warnings),
        }
        return payload, 1
    if not root.is_dir():
        errors.append({"code": "skills_root_not_directory", "path": str(root)})
        status = "blocked"
        payload = base_payload(args, root, expected) | {
            "status": status,
            "errors": errors,
            "warnings": warnings,
            "bead_recommendation": bead_recommendation(status, errors, warnings),
        }
        return payload, 1

    try:
        dirs, candidate_dir_count = skill_dirs(root)
    except OSError as exc:
        errors.append({"code": "skills_root_unreadable", "path": str(root), "error": str(exc)})
        status = "blocked"
        payload = base_payload(args, root, expected) | {
            "status": status,
            "errors": errors,
            "warnings": warnings,
            "bead_recommendation": bead_recommendation(status, errors, warnings),
        }
        return payload, 1

    skill_names = {p.name for p in dirs}
    readable = 0
    sampled_warnings: list[dict[str, Any]] = []
    for directory in dirs:
        skill_md = directory / "SKILL.md"
        text, problem = read_skill_md(skill_md)
        if problem:
            errors.append({"skill": directory.name, **problem})
            continue
        readable += 1
        warning = first_parse_warning(directory.name, skill_md, text or "")
        if warning and len(sampled_warnings) < args.max_warnings:
            sampled_warnings.append(warning)

    warnings.extend(sampled_warnings)
    missing_expected = [name for name in expected if name not in skill_names]
    for name in missing_expected:
        warnings.append({
            "code": "load_bearing_skill_missing",
            "skill": name,
            "path": str(root / name / "SKILL.md"),
        })

    load_bearing_checks = []
    for name in expected:
        path = root / name / "SKILL.md"
        present = name in skill_names
        readable_check = False
        if present:
            _, problem = read_skill_md(path)
            readable_check = problem is None
        load_bearing_checks.append({
            "skill": name,
            "path": str(path),
            "present": present,
            "readable_skill_md": readable_check,
        })

    if not dirs:
        status = "blocked"
        errors.append({"code": "no_skill_dirs_found", "path": str(root)})
        exit_code = 1
    elif errors or warnings:
        status = "degraded"
        exit_code = 0
    else:
        status = "ok"
        exit_code = 0

    payload = base_payload(args, root, expected) | {
        "status": status,
        "candidate_dir_count": candidate_dir_count,
        "skill_dir_count": len(dirs),
        "skill_md_count": len(dirs),
        "readable_skill_md_count": readable,
        "unreadable_skill_md_count": len(errors),
        "skipped_non_skill_dir_count": max(0, candidate_dir_count - len(dirs)),
        "missing_expected_skills": missing_expected,
        "load_bearing_checks": load_bearing_checks,
        "warnings": warnings,
        "errors": errors,
        "bead_recommendation": bead_recommendation(status, errors, warnings),
        "read_only": True,
        "mutated_paths": [],
    }
    return payload, exit_code


def base_payload(args: argparse.Namespace, root: Path, expected: list[str]) -> dict[str, Any]:
    return {
        "schema_version": SCHEMA_VERSION,
        "command": "skills-best-practices-health.py",
        "mode": "doctor",
        "skills_root": str(root),
        "expected_load_bearing_skills": expected,
    }


def schema() -> dict[str, Any]:
    return {
        "schema_version": SCHEMA_VERSION,
        "status_values": ["ok", "degraded", "blocked"],
        "required_fields": [
            "schema_version",
            "status",
            "skills_root",
            "skill_dir_count",
            "readable_skill_md_count",
            "missing_expected_skills",
            "load_bearing_checks",
            "warnings",
            "errors",
            "bead_recommendation",
        ],
        "read_only": True,
    }


def info(args: argparse.Namespace) -> dict[str, Any]:
    return {
        "schema_version": SCHEMA_VERSION,
        "command": "skills-best-practices-health.py",
        "purpose": "Read-only health probe for /flywheel:skills-best-practices --doctor.",
        "skills_root": str(Path(args.skills_root).expanduser()),
        "default_load_bearing_skills": list(DEFAULT_LOAD_BEARING_SKILLS),
        "status_contract": {
            "ok": "root readable, skill SKILL.md files readable, load-bearing spot checks present",
            "degraded": "probe ran but corruption or drift was found; create a follow-up bead",
            "blocked": "skills root unavailable or no skills can be counted",
        },
        "mutates_skills_root": False,
    }


def examples() -> dict[str, Any]:
    return {
        "schema_version": SCHEMA_VERSION,
        "examples": [
            ".flywheel/scripts/skills-best-practices-health.py --doctor --json",
            ".flywheel/scripts/skills-best-practices-health.py --doctor --json --skills-root /tmp/skills-fixture",
            ".flywheel/scripts/skills-best-practices-health.py --schema --json",
        ],
    }


def emit(payload: dict[str, Any], json_mode: bool) -> None:
    if json_mode:
        print(json.dumps(payload, sort_keys=True))
        return
    status = payload.get("status", "ok")
    print(f"{status}: {payload.get('command', 'skills-best-practices-health.py')}")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Read-only health probe for skills-best-practices --doctor")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--doctor", action="store_true")
    mode.add_argument("--health", action="store_true")
    mode.add_argument("--validate", action="store_true")
    mode.add_argument("--schema", action="store_true")
    mode.add_argument("--info", action="store_true")
    mode.add_argument("--examples", action="store_true")
    parser.add_argument("--skills-root", default=os.environ.get("SKILLS_BEST_PRACTICES_ROOT", str(DEFAULT_SKILLS_ROOT)))
    parser.add_argument("--expected-skill", action="append", dest="expected_skill")
    parser.add_argument("--max-warnings", type=int, default=20)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)
    if not any((args.doctor, args.health, args.validate, args.schema, args.info, args.examples)):
        args.doctor = True
    return args


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    if args.schema:
        emit(schema(), True)
        return 0
    if args.info:
        emit(info(args), args.json)
        return 0
    if args.examples:
        emit(examples(), args.json)
        return 0
    payload, exit_code = doctor(args)
    emit(payload, True if args.doctor or args.health or args.validate else args.json)
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
