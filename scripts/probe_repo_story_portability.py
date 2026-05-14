#!/usr/bin/env python3
"""Probe whether git-derived story extraction travels across repos."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "zeststream.repo_story_portability_probe.v0"
ROOT = Path(__file__).resolve().parents[1]
EXTRACTOR = ROOT / "scripts/extract_git_story.py"
OWNER_BRIEF_RENDERER = ROOT / "scripts/render_repo_owner_brief.py"

DEFAULT_REPOS = [
    {
        "repo_id": "flywheel",
        "repo_label": "Flywheel",
        "path": ROOT,
        "source_kind": "source-repo",
    },
    {
        "repo_id": "home_services_proof_product",
        "repo_label": "ClutterFreeSpaces",
        "path": Path("/Users/josh/Developer/clutterfreespaces"),
        "source_kind": "sibling-local-proof-product",
    },
    {
        "repo_id": "food_ordering_proof_product",
        "repo_label": "Mobile Eats",
        "path": Path("/Users/josh/Developer/mobile-eats"),
        "source_kind": "sibling-local-proof-product",
    },
]


def run_extractor(repo: Path, repo_label: str) -> tuple[dict[str, Any] | None, str | None]:
    proc = subprocess.run(
        [
            sys.executable,
            str(EXTRACTOR),
            "--repo",
            str(repo),
            "--repo-label",
            repo_label,
            "--json",
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        return None, (proc.stderr or proc.stdout).strip()
    try:
        return json.loads(proc.stdout), None
    except json.JSONDecodeError as exc:
        return None, f"invalid_json:{exc}"


def run_owner_brief(story: dict[str, Any]) -> tuple[dict[str, Any] | None, str | None]:
    with tempfile.TemporaryDirectory(prefix="repo-story-portability.") as tmp:
        story_path = Path(tmp) / "story.json"
        story_path.write_text(json.dumps(story), encoding="utf-8")
        proc = subprocess.run(
            [
                sys.executable,
                str(OWNER_BRIEF_RENDERER),
                "--story-json",
                str(story_path),
                "--json",
            ],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
    if proc.returncode != 0:
        return None, (proc.stderr or proc.stdout).strip()
    try:
        return json.loads(proc.stdout), None
    except json.JSONDecodeError as exc:
        return None, f"invalid_owner_brief_json:{exc}"


def validate_story(data: dict[str, Any], repo_label: str) -> list[str]:
    errors: list[str] = []
    if data.get("schema_version") != "zeststream.repo_git_story.v0":
        errors.append("story_schema_mismatch")
    if data.get("repo_label") != repo_label:
        errors.append("repo_label_mismatch")
    if data.get("message_pack", {}).get("schema_version") != "zeststream.repo_story_message.v0":
        errors.append("message_schema_mismatch")
    if data.get("story_dossier", {}).get("schema_version") != "zeststream.repo_story_dossier.v0":
        errors.append("dossier_schema_mismatch")
    if data.get("frontend_story", {}).get("schema_version") != "zeststream.repo_frontend_story.v0":
        errors.append("frontend_schema_mismatch")
    if data.get("commit_span", {}).get("total_commits", 0) <= 0:
        errors.append("missing_commit_span")
    component_props = data.get("frontend_story", {}).get("component_props", {})
    for component in (
        "OperatingRoomHero",
        "WorkflowMap",
        "SliceWorkbench",
        "ProofRail",
        "TrustWorryMatrix",
        "YuzuMethodRail",
        "ProofDrawer",
        "LessonLedger",
        "SafeContactPanel",
    ):
        if component not in component_props:
            errors.append(f"component_missing:{component}")
    if data.get("message_pack", {}).get("primary_cta") != "Map my workflow":
        errors.append("primary_cta_mismatch")
    return errors


def validate_owner_brief(data: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if data.get("schema_version") != "zeststream.repo_owner_story_brief.v0":
        errors.append("owner_brief_schema_mismatch")
    if data.get("source_story_schema") != "zeststream.repo_git_story.v0":
        errors.append("owner_brief_story_schema_mismatch")
    if data.get("source_frontend_schema") != "zeststream.repo_frontend_story.v0":
        errors.append("owner_brief_frontend_schema_mismatch")
    if data.get("primary_cta") != "Map my workflow":
        errors.append("owner_brief_primary_cta_mismatch")
    if len(data.get("trust_answers", [])) != 10:
        errors.append("owner_brief_trust_answer_count_mismatch")
    if len(data.get("page_rooms", [])) < 8:
        errors.append("owner_brief_page_room_count_mismatch")
    frontend_contract = data.get("frontend_contract", {})
    if frontend_contract.get("component_package") != "@zeststream/ui":
        errors.append("owner_brief_component_package_mismatch")
    if frontend_contract.get("token_package") != "@zeststream/story-system":
        errors.append("owner_brief_token_package_mismatch")
    copy_checks = data.get("public_copy_checks", {})
    if copy_checks.get("hype_phrases_absent") is not True:
        errors.append("owner_brief_hype_check_missing")
    if copy_checks.get("private_paths_absent") is not True:
        errors.append("owner_brief_private_path_check_missing")
    return errors


def probe_repo(row: dict[str, Any]) -> dict[str, Any]:
    repo = Path(row["path"])
    result: dict[str, Any] = {
        "repo_id": row["repo_id"],
        "repo_label": row["repo_label"],
        "source_kind": row["source_kind"],
        "local_repo_present": repo.exists(),
    }
    if not repo.exists():
        result.update(
            {
                "status": "skipped",
                "skip_reason": "local_repo_not_present",
            }
        )
        return result
    story, error = run_extractor(repo, row["repo_label"])
    if error or story is None:
        result.update(
            {
                "status": "fail",
                "failure_codes": ["EXTRACTOR_FAILED"],
                "error": error,
            }
        )
        return result
    errors = validate_story(story, row["repo_label"])
    owner_brief, owner_brief_error = run_owner_brief(story)
    if owner_brief_error or owner_brief is None:
        errors.append("OWNER_BRIEF_RENDER_FAILED")
        owner_brief = {}
    else:
        errors.extend(validate_owner_brief(owner_brief))
    commit_span = story.get("commit_span", {})
    frontend_story = story.get("frontend_story", {})
    result.update(
        {
            "status": "pass" if not errors else "fail",
            "failure_codes": errors,
            "commit_count": commit_span.get("total_commits"),
            "first_commit_date": commit_span.get("first_date"),
            "latest_commit_date": commit_span.get("latest_date"),
            "redaction_table": story.get("redaction_table"),
            "story_schema": story.get("schema_version"),
            "message_schema": story.get("message_pack", {}).get("schema_version"),
            "dossier_schema": story.get("story_dossier", {}).get("schema_version"),
            "frontend_schema": frontend_story.get("schema_version"),
            "frontend_component_count": len(frontend_story.get("component_props", {})),
            "owner_brief_schema": owner_brief.get("schema_version"),
            "owner_brief_trust_answer_count": len(owner_brief.get("trust_answers", [])),
            "owner_brief_page_room_count": len(owner_brief.get("page_rooms", [])),
            "copy_rule": frontend_story.get("copy_rule"),
            "primary_cta": story.get("message_pack", {}).get("primary_cta"),
        }
    )
    if owner_brief_error:
        result["owner_brief_error"] = owner_brief_error
    return result


def build_receipt() -> dict[str, Any]:
    rows = [probe_repo(row) for row in DEFAULT_REPOS]
    failed = [row for row in rows if row.get("status") == "fail"]
    passed = [row for row in rows if row.get("status") == "pass"]
    skipped = [row for row in rows if row.get("status") == "skipped"]
    return {
        "schema_version": SCHEMA_VERSION,
        "generated_date": dt.datetime.now(dt.UTC).date().isoformat(),
        "status": "fail" if failed else "pass",
        "required_story_schema": "zeststream.repo_git_story.v0",
        "required_message_schema": "zeststream.repo_story_message.v0",
        "required_dossier_schema": "zeststream.repo_story_dossier.v0",
        "required_frontend_schema": "zeststream.repo_frontend_story.v0",
        "required_owner_brief_schema": "zeststream.repo_owner_story_brief.v0",
        "row_count": len(rows),
        "pass_count": len(passed),
        "skip_count": len(skipped),
        "fail_count": len(failed),
        "rows": rows,
        "portable_copy_rule": "Show the proof, not the dream; every repo story must come from git history and render through shared proof primitives.",
        "public_safety": {
            "absolute_paths_in_receipt": False,
            "raw_commit_bodies_in_receipt": False,
            "sibling_repos_edited": False,
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write-json")
    args = parser.parse_args()

    receipt = build_receipt()
    payload = json.dumps(receipt, indent=2, sort_keys=True) + "\n"
    if args.write_json:
        Path(args.write_json).parent.mkdir(parents=True, exist_ok=True)
        Path(args.write_json).write_text(payload, encoding="utf-8")
    print(payload, end="")
    return 0 if receipt["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
