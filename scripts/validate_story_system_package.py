#!/usr/bin/env python3
"""Validate the reusable ZestStream story-system package."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
PACKAGE_DIR = ROOT / "packages/zeststream-story-system"
STORY_SYSTEM_PATH = PACKAGE_DIR / "story-system.json"
PACKAGE_JSON_PATH = PACKAGE_DIR / "package.json"
PACKAGE_TOKENS_PATH = PACKAGE_DIR / "tokens.css"
SITE_TOKENS_PATH = ROOT / "site/visual-system.css"
TRAJECTORY_PATH = ROOT / "docs/evidence/flywheel-trajectory.json"


TOKEN_RE = re.compile(r"(?P<name>--zs-[a-z0-9-]+)\s*:\s*(?P<value>[^;]+);")


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def css_tokens(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    return {match.group("name"): match.group("value").strip() for match in TOKEN_RE.finditer(text)}


def validate() -> dict[str, Any]:
    errors: list[dict[str, str]] = []
    package_json = read_json(PACKAGE_JSON_PATH)
    story_system = read_json(STORY_SYSTEM_PATH)
    trajectory = read_json(TRAJECTORY_PATH)
    message_pack = trajectory.get("message_pack", {})
    story_dossier = trajectory.get("story_dossier", {})

    if package_json.get("name") != "@zeststream/story-system":
        errors.append({"code": "PACKAGE_NAME_INVALID"})
    if story_system.get("schema_version") != "zeststream.story_system_package.v0":
        errors.append({"code": "STORY_SYSTEM_SCHEMA_INVALID"})
    if story_system.get("source_message_schema") != "zeststream.repo_story_message.v0":
        errors.append({"code": "SOURCE_MESSAGE_SCHEMA_INVALID"})
    if story_system.get("source_dossier_schema") != "zeststream.repo_story_dossier.v0":
        errors.append({"code": "SOURCE_DOSSIER_SCHEMA_INVALID"})
    if message_pack.get("schema_version") != story_system.get("source_message_schema"):
        errors.append({"code": "MESSAGE_PACK_SCHEMA_MISMATCH"})
    if story_dossier.get("schema_version") != story_system.get("source_dossier_schema"):
        errors.append({"code": "STORY_DOSSIER_SCHEMA_MISMATCH"})

    message_stages = [row.get("stage") for row in message_pack.get("story_arc", [])]
    if story_system.get("story_arc_stages") != message_stages:
        errors.append({"code": "STORY_ARC_STAGE_MISMATCH"})

    message_primitives = [row.get("name") for row in message_pack.get("visual_primitives", [])]
    if story_system.get("visual_primitives") != message_primitives:
        errors.append({"code": "VISUAL_PRIMITIVE_MISMATCH"})

    dossier_sections = [row.get("section_id") for row in story_dossier.get("page_blueprint", [])]
    if story_system.get("page_blueprint_sections") != dossier_sections:
        errors.append({"code": "PAGE_BLUEPRINT_MISMATCH"})
    if story_system.get("audience_truths") != story_dossier.get("audience_truths"):
        errors.append({"code": "AUDIENCE_TRUTH_MISMATCH"})
    if story_system.get("owner_language_bank") != story_dossier.get("owner_language_bank"):
        errors.append({"code": "OWNER_LANGUAGE_BANK_MISMATCH"})

    if story_system.get("owner_objection_count") != len(message_pack.get("trust_objections", [])):
        errors.append({"code": "OWNER_OBJECTION_COUNT_MISMATCH"})
    if story_system.get("core_offer") != message_pack.get("core_offer"):
        errors.append({"code": "CORE_OFFER_MISMATCH"})
    if story_system.get("primary_cta") != message_pack.get("primary_cta"):
        errors.append({"code": "PRIMARY_CTA_MISMATCH"})

    package_tokens = css_tokens(PACKAGE_TOKENS_PATH)
    site_tokens = css_tokens(SITE_TOKENS_PATH)
    for token in story_system.get("required_css_tokens", []):
        if token not in package_tokens:
            errors.append({"code": "PACKAGE_TOKEN_MISSING", "token": token})
            continue
        if token not in site_tokens:
            errors.append({"code": "SITE_TOKEN_MISSING", "token": token})
            continue
        if package_tokens[token] != site_tokens[token]:
            errors.append({"code": "TOKEN_VALUE_MISMATCH", "token": token})

    for phrase in story_system.get("blocked_phrases", []):
        if phrase in (ROOT / "site/index.html").read_text(encoding="utf-8"):
            errors.append({"code": "BLOCKED_PHRASE_ON_SITE", "phrase": phrase})

    return {
        "schema_version": "zeststream.story_system_package_validation.v0",
        "status": "fail" if errors else "pass",
        "package": str(PACKAGE_DIR.relative_to(ROOT)),
        "story_arc_stage_count": len(story_system.get("story_arc_stages", [])),
        "visual_primitive_count": len(story_system.get("visual_primitives", [])),
        "page_blueprint_section_count": len(story_system.get("page_blueprint_sections", [])),
        "audience_truth_count": len(story_system.get("audience_truths", [])),
        "owner_objection_count": story_system.get("owner_objection_count"),
        "required_css_token_count": len(story_system.get("required_css_tokens", [])),
        "errors": errors,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    payload = validate()
    if args.json:
        print(json.dumps(payload, indent=2, sort_keys=True))
    else:
        print(f"status={payload['status']}")
        for error in payload["errors"]:
            print(error["code"])
    return 0 if payload["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
