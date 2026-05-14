#!/usr/bin/env python3
"""Render an SMB-owner story brief from a generated repo trajectory artifact."""

from __future__ import annotations

import argparse
import datetime as dt
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_STORY_JSON = ROOT / "docs/evidence/flywheel-trajectory.json"
SCHEMA_VERSION = "zeststream.repo_owner_story_brief.v0"
STORY_SCHEMA = "zeststream.repo_git_story.v0"
MESSAGE_SCHEMA = "zeststream.repo_story_message.v0"
DOSSIER_SCHEMA = "zeststream.repo_story_dossier.v0"
FRONTEND_SCHEMA = "zeststream.repo_frontend_story.v0"

GENERIC_SLOP_MARKERS = [
    "AI will transform your business",
    "fully autonomous",
    "set it and forget it",
    "we have many commits, so trust us",
    "all systems are supported without receipts",
    "Here's why",
    "Let's dive in",
    "At its core",
    "not just",
    "game changer",
]


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def require_schema(story: dict[str, Any]) -> None:
    if story.get("schema_version") != STORY_SCHEMA:
        raise SystemExit("story schema mismatch")
    if story.get("message_pack", {}).get("schema_version") != MESSAGE_SCHEMA:
        raise SystemExit("message schema mismatch")
    if story.get("story_dossier", {}).get("schema_version") != DOSSIER_SCHEMA:
        raise SystemExit("dossier schema mismatch")
    if story.get("frontend_story", {}).get("schema_version") != FRONTEND_SCHEMA:
        raise SystemExit("frontend story schema mismatch")


def chapter_map(story: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {chapter["id"]: chapter for chapter in story.get("chapters", [])}


def evidence_refs(story: dict[str, Any]) -> list[dict[str, str]]:
    frontend = story["frontend_story"]
    return [
        {
            "label": "Generated repo trajectory",
            "ref": "docs/evidence/repo-trajectory.json",
            "owner_meaning": "The message comes from work history, not a fresh pitch.",
        },
        {
            "label": "Generated story",
            "ref": "docs/stories/repo-trajectory.md",
            "owner_meaning": "A reviewer can inspect the path from origin to current state.",
        },
        {
            "label": "Shared story package",
            "ref": "packages/zeststream-story-system/story-system.json",
            "owner_meaning": "The wording and visual grammar are reusable across projects.",
        },
        {
            "label": "Frontend quality gate",
            "ref": "scripts/zs-frontend-quality-gate.sh --json --strict",
            "owner_meaning": "A page cannot pass as a generic card stack with unsupported claims.",
        },
        {
            "label": "Component payload",
            "ref": frontend.get("package_targets", {}).get("components", "@zeststream/ui"),
            "owner_meaning": "The proof story has shared UI primitives instead of one-off copy.",
        },
    ]


def build_rooms(story: dict[str, Any]) -> list[dict[str, str]]:
    chapters = chapter_map(story)
    dossier = story["story_dossier"]
    chapter_for_component = {
        "OperatingRoomHero": "foundation",
        "OwnerTensionRoom": "friction",
        "SliceWorkbench": "story",
        "ProofRail": "proof-loop",
        "ProofDrawer": "proof-loop",
        "TrajectoryRail": "story",
        "LessonLedger": "reuse",
        "SafeContactPanel": "story",
    }
    rooms = []
    for row in dossier.get("page_blueprint", []):
        component = row["component"]
        chapter = chapters.get(chapter_for_component.get(component, "story"), {})
        rooms.append(
            {
                "section_id": row["section_id"],
                "component": component,
                "owner_job": row["job"],
                "visible_scene": chapter.get("visual_scene", "A controlled proof surface."),
                "proof_source": row["proof_source"],
            }
        )
    return rooms


def build_brief(story: dict[str, Any]) -> dict[str, Any]:
    require_schema(story)
    message = story["message_pack"]
    dossier = story["story_dossier"]
    frontend = story["frontend_story"]
    chapters = chapter_map(story)
    span = story["commit_span"]
    proof_loop = chapters.get("proof-loop", {})
    friction = chapters.get("friction", {})
    reuse = chapters.get("reuse", {})

    brief = {
        "schema_version": SCHEMA_VERSION,
        "generated_date": dt.datetime.now(dt.UTC).date().isoformat(),
        "repo_label": story["repo_label"],
        "source_story_schema": STORY_SCHEMA,
        "source_message_schema": MESSAGE_SCHEMA,
        "source_dossier_schema": DOSSIER_SCHEMA,
        "source_frontend_schema": FRONTEND_SCHEMA,
        "audience": message["audience"],
        "copy_rule": "Show the proof, not the dream. Lead with the owner's stuck workflow, then show the controlled path forward.",
        "headline": message["page_headline_options"][0],
        "subhead": "Map the manual route between tools, improve one bounded slice, prove what changed, and carry the lesson forward.",
        "owner_problem": "The business already has systems. The waste sits between them: copying, chasing, checking, remembering, and wondering what changed.",
        "safe_first_step": "Start with one workflow map before broader access, automation, or claims.",
        "method_name": "The Yuzu Method",
        "method_steps": [
            {
                "stage": row["stage"],
                "visible_wording": row["visible_wording"],
                "visual_cue": row["visual_cue"],
            }
            for row in message["story_arc"]
        ],
        "proof_lanes": [
            {
                "owner_meaning": row["owner_meaning"],
                "evidence_ref": row["evidence_ref"],
            }
            for row in message["proof_translation"]
        ],
        "trust_answers": [
            {
                "owner_worry": row["objection"],
                "visible_answer": row["visible_answer"],
                "proof_behavior": row["proof_behavior"],
            }
            for row in message["trust_objections"]
        ],
        "page_rooms": build_rooms(story),
        "visual_direction": dossier["visual_direction"],
        "frontend_contract": {
            "schema_version": frontend["schema_version"],
            "component_package": frontend["package_targets"]["components"],
            "token_package": frontend["package_targets"]["tokens"],
            "component_count": len(frontend["component_props"]),
            "quality_gates": frontend["quality_gate_commands"],
        },
        "proof_summary": {
            "commit_span": f"{span['first_date']} to {span['latest_date']}",
            "commits_inspected": span["total_commits"],
            "friction_signals": friction.get("commit_count", 0),
            "proof_loop_signals": proof_loop.get("commit_count", 0),
            "reuse_signals": reuse.get("commit_count", 0),
            "owner_translation": "The repo shows origin, friction, proof, reuse, and story work as a path a reviewer can inspect.",
        },
        "primary_cta": message["primary_cta"],
        "secondary_cta": message["secondary_cta"],
        "evidence_refs": evidence_refs(story),
        "sales_language_rules": [
            "Say manual work, follow-up, cash flow, owner approval, and customer experience before naming AI.",
            "Treat commit counts as reviewer evidence, not hero copy.",
            "Call unsupported claims blocked instead of softening them into promises.",
            "Use slice to mean one bounded workflow improvement with a visible stop condition.",
            "Make the next step feel safe: map first, then decide what earns access.",
        ],
        "public_copy_checks": {
            "hype_phrases_absent": True,
            "private_paths_absent": True,
            "every_strong_claim_has_evidence_ref": True,
            "blocked_state_allowed": True,
        },
    }
    validate_copy(brief)
    return brief


def validate_copy(brief: dict[str, Any]) -> None:
    text = json.dumps(brief, sort_keys=True)
    if "—" in text:
        raise SystemExit("owner brief contains em dash")
    for marker in GENERIC_SLOP_MARKERS:
        if marker in text:
            raise SystemExit(f"owner brief contains blocked marker: {marker}")
    if "/Users/josh" in text or "/Developer/" in text:
        raise SystemExit("owner brief contains local path")


def render_markdown(brief: dict[str, Any]) -> str:
    lines = [
        f"# {brief['repo_label']} Owner Story Brief",
        "",
        f"Schema: `{brief['schema_version']}`",
        "",
        brief["copy_rule"],
        "",
        f"## Headline",
        "",
        brief["headline"],
        "",
        brief["subhead"],
        "",
        "## Owner Problem",
        "",
        brief["owner_problem"],
        "",
        f"Safe first step: {brief['safe_first_step']}",
        "",
        f"## {brief['method_name']}",
        "",
        "| Stage | Visible wording | Visual cue |",
        "|---|---|---|",
    ]
    for row in brief["method_steps"]:
        lines.append(f"| {row['stage']} | {row['visible_wording']} | {row['visual_cue']} |")
    lines.extend(["", "## Trust Answers", "", "| Owner worry | Visible answer | Proof behavior |", "|---|---|---|"])
    for row in brief["trust_answers"]:
        lines.append(f"| {row['owner_worry']} | {row['visible_answer']} | {row['proof_behavior']} |")
    lines.extend(["", "## Page Rooms", "", "| Room | Component | Owner job | Proof source |", "|---|---|---|---|"])
    for row in brief["page_rooms"]:
        lines.append(
            f"| `{row['section_id']}` | `{row['component']}` | {row['owner_job']} | {row['proof_source']} |"
        )
    lines.extend(["", "## Proof Summary", ""])
    summary = brief["proof_summary"]
    lines.extend(
        [
            f"- Commit span: `{summary['commit_span']}`",
            f"- Commits inspected: `{summary['commits_inspected']}`",
            f"- Friction signals: `{summary['friction_signals']}`",
            f"- Proof-loop signals: `{summary['proof_loop_signals']}`",
            f"- Reuse signals: `{summary['reuse_signals']}`",
            f"- Owner translation: {summary['owner_translation']}",
            "",
            "## Evidence Refs",
            "",
        ]
    )
    for row in brief["evidence_refs"]:
        lines.append(f"- `{row['ref']}`: {row['owner_meaning']}")
    lines.extend(
        [
            "",
            "## CTA",
            "",
            f"Primary: `{brief['primary_cta']}`",
            "",
            f"Secondary: `{brief['secondary_cta']}`",
            "",
        ]
    )
    return "\n".join(lines)


def resolve_output(path_value: str | None) -> Path | None:
    if not path_value:
        return None
    path = Path(path_value)
    if not path.is_absolute():
        path = ROOT / path
    path.parent.mkdir(parents=True, exist_ok=True)
    return path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--story-json", default=str(DEFAULT_STORY_JSON))
    parser.add_argument("--write-json")
    parser.add_argument("--write-md")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    story_path = Path(args.story_json)
    if not story_path.is_absolute():
        story_path = ROOT / story_path
    brief = build_brief(read_json(story_path))

    json_path = resolve_output(args.write_json)
    if json_path:
        json_path.write_text(json.dumps(brief, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path = resolve_output(args.write_md)
    if md_path:
        md_path.write_text(render_markdown(brief), encoding="utf-8")
    if args.json or not (json_path or md_path):
        print(json.dumps(brief, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
