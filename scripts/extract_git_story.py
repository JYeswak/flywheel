#!/usr/bin/env python3
"""Extract a public, business-readable trajectory from git history."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))
from depersonalize import DEFAULT_TABLE, load_replacement_table, repo_root, transform_text  # noqa: E402


SCHEMA_VERSION = "zeststream.repo_git_story.v0"
MESSAGE_SCHEMA_VERSION = "zeststream.repo_story_message.v0"

NATURAL_PLACEHOLDERS = {
    "{operator}": "the operator",
    "{operator-first-name}": "the operator",
    "{operator-company}": "the operator company",
    "{operator-email}": "the public contact email",
    "{proof-product}": "a proof product",
    "{capability-control-plane}": "the capability control plane",
    "{food-ordering-proof-product}": "a food-ordering proof product",
    "{home-services-proof-product}": "a home-services proof product",
    "{insurance-client}": "an insurance client",
    "{telecom-client}": "a telecom client",
    "{title-client}": "a title client",
    "{bead-id}": "work item",
}


@dataclass(frozen=True)
class Commit:
    sha: str
    short_sha: str
    date: str
    subject: str
    paths: tuple[str, ...]


CHAPTERS = [
    {
        "id": "foundation",
        "title": "Foundation: make the work visible",
        "owner_value": "The first useful proof is not a polished page. It is a workbench where the goal, current state, checks, and next action can be inspected instead of guessed.",
        "sales_translation": "For an SMB owner, this means the project starts by mapping how work really moves before anyone promises automation.",
        "keywords": {
            "loop",
            "doctor",
            "tick",
            "mission",
            "goal",
            "state",
            "autoloop",
            "init",
            "preflight",
        },
    },
    {
        "id": "proof-loop",
        "title": "Proof loop: turn activity into evidence",
        "owner_value": "The system moved from work being described after the fact to work being closed with receipts, tests, blockers, and replayable checks.",
        "sales_translation": "That is the difference between an AI demo and an operating process: the claim does not move forward until the proof can follow it.",
        "keywords": {
            "dispatch",
            "callback",
            "agent",
            "pane",
            "ntm",
            "bead",
            "mail",
            "reservation",
            "receipt",
        },
    },
    {
        "id": "friction",
        "title": "Friction: expose the parts that were not ready",
        "owner_value": "The useful pivots came from red evidence: private residue, unsupported lanes, stale copy, brittle workflows, and claims that needed to be blocked until proven.",
        "sales_translation": "This is where trust is earned. The process treats blocked evidence as useful signal, not as something to hide in a footnote.",
        "keywords": {
            "public",
            "publish",
            "publication",
            "depersonal",
            "redact",
            "private",
            "export",
            "surface",
            "denylist",
            "sanit",
        },
    },
    {
        "id": "reuse",
        "title": "Reuse: keep lessons that survived contact with reality",
        "owner_value": "Once a pattern worked, it moved into runbooks, scripts, tests, docs, shared language, or reusable operating rules instead of staying trapped in one session.",
        "sales_translation": "Every project should make the next project safer and faster. That is the compounding part of the Flywheel.",
        "keywords": {
            "isolated",
            "journey",
            "smoke",
            "receipt",
            "workflow",
            "release",
            "readiness",
            "actions",
            "act",
            "agent-lane",
            "runbook",
            "template",
            "package",
            "config",
        },
    },
    {
        "id": "story",
        "title": "Story: translate the machinery into a buying journey",
        "owner_value": "The current arc is making the proof understandable to a non-technical owner: what changed, why it was safe, where it stopped, and which lesson now carries forward.",
        "sales_translation": "Show the proof, not the dream: one bounded workflow slice, one visible control path, one lesson that compounds into the next build.",
        "keywords": {
            "site",
            "smb",
            "owner",
            "journey",
            "story",
            "brand",
            "yuzu",
            "website",
            "wireframe",
        },
    },
]

OWNER_TRUST_OBJECTIONS = [
    {
        "objection": "AI will make a mess.",
        "visible_answer": "The map comes before automation.",
        "proof_behavior": "The first slice must have a named boundary and stop condition.",
    },
    {
        "objection": "I will not know what changed.",
        "visible_answer": "Every slice has a proof rail.",
        "proof_behavior": "Each claim links to evidence or stays blocked.",
    },
    {
        "objection": "My data will leak.",
        "visible_answer": "Private work stays private.",
        "proof_behavior": "Public proof is redacted, consented, generated, or replaced.",
    },
    {
        "objection": "AI makes things up.",
        "visible_answer": "Blocked is better than bluffing.",
        "proof_behavior": "Unsupported claims show as blocked instead of becoming copy.",
    },
    {
        "objection": "This will replace people before it understands the work.",
        "visible_answer": "The first slice is small on purpose.",
        "proof_behavior": "Human approval remains part of the workflow slice.",
    },
    {
        "objection": "My tools already do not talk to each other.",
        "visible_answer": "The operating map starts with the disconnected tools the owner already uses.",
        "proof_behavior": "Integration starts with one workflow path, not the whole company.",
    },
    {
        "objection": "Every consultant has a framework.",
        "visible_answer": "The method is visible enough to inspect.",
        "proof_behavior": "Runbooks, tests, receipts, and blockers sit behind the story.",
    },
    {
        "objection": "AI changes too fast.",
        "visible_answer": "Fast tools go through a controlled loop.",
        "proof_behavior": "Tool claims require current receipts before promotion.",
    },
    {
        "objection": "If it fails, I will be stuck.",
        "visible_answer": "Stop conditions are named up front.",
        "proof_behavior": "Failed proof does not become a public claim.",
    },
    {
        "objection": "I do not want to become an AI expert.",
        "visible_answer": "The owner approves the slice; the operator manages the machinery.",
        "proof_behavior": "Technical proof is available but not required to understand the offer.",
    },
]

MESSAGE_ARC = [
    {
        "stage": "recognize",
        "owner_question": "Is this about the mess I am actually dealing with?",
        "visible_wording": "Your business already has the data. The work is just hidden between tools.",
        "visual_cue": "A workflow map with disconnected systems and one highlighted manual route.",
    },
    {
        "stage": "bound",
        "owner_question": "How do we keep this from turning into a giant AI project?",
        "visible_wording": "A slice is one bounded workflow improvement: useful enough to feel, small enough to inspect, and clear enough to stop if the proof is not there.",
        "visual_cue": "The selected slice is pulled out of the map and placed on a workbench.",
    },
    {
        "stage": "control",
        "owner_question": "What keeps the system honest?",
        "visible_wording": "If a claim is not proven, it stays blocked.",
        "visual_cue": "A proof rail with proven, blocked, skipped-with-reason, and private states.",
    },
    {
        "stage": "remember",
        "owner_question": "Is this real method or just a nice page?",
        "visible_wording": "The repo history shows the pivots, blockers, and lessons that survived contact with reality.",
        "visual_cue": "A trajectory rail that connects foundation, friction, proof loop, reuse, and current arc.",
    },
    {
        "stage": "act",
        "owner_question": "What is the safe first step?",
        "visible_wording": "Map one workflow before sending secrets, customer data, or system access.",
        "visual_cue": "A safe intake room with redacted examples and a direct operator route.",
    },
]

VISUAL_PRIMITIVES = [
    {
        "name": "OperatingRoomHero",
        "job": "Open inside the owner workflow instead of a generic SaaS hero.",
    },
    {
        "name": "WorkflowMap",
        "job": "Show systems, manual handoffs, and the selected slice boundary.",
    },
    {
        "name": "SliceWorkbench",
        "job": "Show before state, bounded slice, proof state, and stop condition together.",
    },
    {
        "name": "ProofRail",
        "job": "Keep evidence visible without making the SMB owner decode raw receipts.",
    },
    {
        "name": "TrustWorryMatrix",
        "job": "Map owner objections to visible controls and evidence behavior.",
    },
    {
        "name": "YuzuMethodRail",
        "job": "Repeat Peel, Press, Pour as map, prove, and reuse.",
    },
    {
        "name": "TrajectoryRail",
        "job": "Translate git history into origin, friction, proof loop, reuse, and current arc.",
    },
    {
        "name": "ProofDrawer",
        "job": "Let reviewers inspect generated artifacts after the owner story lands.",
    },
]


def run_git(repo: Path, args: list[str]) -> str:
    proc = subprocess.run(
        ["git", *args],
        cwd=repo,
        check=False,
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        raise SystemExit((proc.stderr or proc.stdout).strip())
    return proc.stdout


def parse_commits(raw: str, rows: list[Any]) -> list[Commit]:
    commits: list[Commit] = []
    current: dict[str, Any] | None = None
    paths: list[str] = []
    for line in raw.splitlines():
        if line.startswith("__FW_COMMIT__\x1f"):
            if current is not None:
                commits.append(build_commit(current, paths, rows))
            _marker, sha, date, subject = line.split("\x1f", 3)
            current = {"sha": sha, "date": date, "subject": subject}
            paths = []
            continue
        if current is not None and line.strip():
            paths.append(line.strip())
    if current is not None:
        commits.append(build_commit(current, paths, rows))
    return commits


def sanitize(value: str, rows: list[Any], relpath: str = "git-history") -> str:
    sanitized = transform_text(value, rows, relpath)[0]
    for placeholder, replacement in NATURAL_PLACEHOLDERS.items():
        sanitized = sanitized.replace(placeholder, replacement)
    sanitized = sanitized.replace("—", ";")
    return sanitized


def build_commit(raw: dict[str, Any], paths: list[str], rows: list[Any]) -> Commit:
    subject = sanitize(str(raw["subject"]), rows)
    sanitized_paths = tuple(sanitize(path, rows) for path in paths[:8])
    sha = str(raw["sha"])
    return Commit(
        sha=sha,
        short_sha=sha[:8],
        date=str(raw["date"]),
        subject=subject,
        paths=sanitized_paths,
    )


def score(commit: Commit, keywords: set[str]) -> int:
    haystack = " ".join([commit.subject, *commit.paths]).lower()
    return sum(1 for keyword in keywords if keyword.lower() in haystack)


def chapter_payload(chapter: dict[str, Any], commits: list[Commit]) -> dict[str, Any]:
    matches = [commit for commit in commits if score(commit, chapter["keywords"]) > 0]
    ranked = sorted(matches, key=lambda commit: (score(commit, chapter["keywords"]), commit.date), reverse=True)
    evidence = sorted(ranked[:8], key=lambda commit: commit.date)
    return {
        "id": chapter["id"],
        "title": chapter["title"],
        "owner_value": chapter["owner_value"],
        "sales_translation": chapter["sales_translation"],
        "commit_count": len(matches),
        "first_date": matches[0].date if matches else None,
        "latest_date": matches[-1].date if matches else None,
        "evidence_commits": [
            {
                "sha": commit.short_sha,
                "date": commit.date,
                "subject": commit.subject,
                "paths": list(commit.paths[:4]),
            }
            for commit in evidence
        ],
    }


def build_story(repo: Path, repo_label: str) -> dict[str, Any]:
    rows = load_replacement_table(repo / DEFAULT_TABLE)
    raw = run_git(
        repo,
        [
            "log",
            "--reverse",
            "--date=short",
            "--pretty=format:__FW_COMMIT__%x1f%H%x1f%ad%x1f%s",
            "--name-only",
            "HEAD",
        ],
    )
    commits = parse_commits(raw, rows)
    if not commits:
        raise SystemExit("git history produced no commits")
    chapters = [chapter_payload(chapter, commits) for chapter in CHAPTERS]
    story = {
        "schema_version": SCHEMA_VERSION,
        "generated_date": dt.datetime.now(dt.UTC).date().isoformat(),
        "repo_label": repo_label,
        "source": "git log --reverse --date=short --pretty=format:... --name-only HEAD",
        "commit_span": {
            "first_date": commits[0].date,
            "latest_date": commits[-1].date,
            "total_commits": len(commits),
            "first_commit": {
                "sha": commits[0].short_sha,
                "subject": commits[0].subject,
            },
            "latest_commit": {
                "sha": commits[-1].short_sha,
                "subject": commits[-1].subject,
            },
        },
        "public_claim": "The public story is extracted from repository history, then translated into owner-readable trajectory without treating commit volume as the sales pitch.",
        "positioning_principles": [
            "show proof, do not sell the dream",
            "translate technical movement into owner consequences",
            "name pivots and blockers instead of smoothing them away",
            "keep evidence available without making the SMB owner decode it",
            "turn lessons into reusable method, copy, design, tests, or runbooks",
        ],
        "owner_story": {
            "headline": f"{repo_label} has a history, not just a homepage.",
            "plain_language": (
                "The work started with a problem, hit constraints, changed shape, "
                "and kept the parts that proved useful. That trajectory is the trust signal."
            ),
            "proof_posture": "The evidence is the path through the repo, not a detached claim written after the fact.",
            "cta_copy": "Inspect the trajectory",
        },
        "chapters": chapters,
    }
    story["message_pack"] = build_message_pack(repo_label, story)
    return story


def strongest_chapter(chapters: list[dict[str, Any]], chapter_id: str) -> dict[str, Any]:
    for chapter in chapters:
        if chapter["id"] == chapter_id:
            return chapter
    raise KeyError(chapter_id)


def build_message_pack(repo_label: str, story: dict[str, Any]) -> dict[str, Any]:
    chapters = story["chapters"]
    friction = strongest_chapter(chapters, "friction")
    reuse = strongest_chapter(chapters, "reuse")
    proof_loop = strongest_chapter(chapters, "proof-loop")
    return {
        "schema_version": MESSAGE_SCHEMA_VERSION,
        "source_story_schema": SCHEMA_VERSION,
        "audience": "SMB owner or buyer who wants safer AI adoption without becoming an AI tooling expert.",
        "core_offer": "Map one workflow, improve one bounded slice, prove what changed, and carry the lesson into the next build.",
        "voice_rules": [
            "sell outcomes, not tools",
            "name the owner worry before naming the machinery",
            "show proof without forcing the owner to read raw receipts",
            "prefer human-led control language over autonomous-agent hype",
            "make blockers visible because hidden risk is the trust killer",
            "treat cash flow, time, follow-up, and customer experience as stronger language than AI novelty",
        ],
        "page_headline_options": [
            "Buy back the time hiding between your tools.",
            "Turn one messy workflow into one proven slice.",
            "Make AI useful before you make it big.",
        ],
        "owner_promise": "The operator helps SMB owners buy their time back by finding the manual work between systems, proving one safe slice, and keeping the lesson for the next project.",
        "primary_cta": "Map my workflow",
        "secondary_cta": "Inspect the proof",
        "story_arc": MESSAGE_ARC,
        "trust_objections": OWNER_TRUST_OBJECTIONS,
        "visual_primitives": VISUAL_PRIMITIVES,
        "proof_translation": [
            {
                "technical_signal": "commit history",
                "owner_meaning": "The story comes from the work that actually happened, not a fresh marketing claim.",
                "evidence_ref": "docs/stories/repo-trajectory.md",
            },
            {
                "technical_signal": "friction and blocker evidence",
                "owner_meaning": "The process exposes what is not ready before it can affect the business.",
                "evidence_ref": f"{friction['commit_count']} friction-matched commits",
            },
            {
                "technical_signal": "receipts, tests, and proof-loop commits",
                "owner_meaning": "Claims move forward only when the system can show what changed.",
                "evidence_ref": f"{proof_loop['commit_count']} proof-loop-matched commits",
            },
            {
                "technical_signal": "runbooks, scripts, packages, and shared design grammar",
                "owner_meaning": "Lessons from one repo become reusable operating material for the next repo.",
                "evidence_ref": f"{reuse['commit_count']} reuse-matched commits",
            },
        ],
        "nextjs_storytelling_targets": [
            "App Router rooms for owner, method, developer, operator, and contact journeys",
            "Server Components for proof manifests that should not ship private raw state to the browser",
            "Suspense-backed proof drawers so the owner story renders before reviewer evidence",
            "shared CSS/design tokens for proof states, yuzu method rails, and workflow maps",
            "Playwright screenshot gates for mobile and desktop story quality",
        ],
        "must_not_say": [
            "AI will transform your business",
            "fully autonomous",
            "set it and forget it",
            "we have many commits, so trust us",
            "all systems are supported without receipts",
        ],
    }


def render_markdown(story: dict[str, Any]) -> str:
    span = story["commit_span"]
    lines = [
        "# Flywheel Trajectory",
        "",
        f"Repo: `{story['repo_label']}`",
        f"Schema: `{SCHEMA_VERSION}`",
        "",
        "This is a generated public story surface. It is derived from git history,",
        "then sanitized before publication. It is evidence for trajectory, not a",
        "claim that the public release is complete.",
        "",
        f"Owner headline: {story['owner_story']['headline']}",
        "",
        "The copy rule is simple: show the proof, do not sell the dream. The",
        "commit history should explain where the work started, where it met",
        "friction, what changed, and which lessons became reusable.",
        "",
        "## Git-Derived Span",
        "",
        f"- First commit date: `{span['first_date']}`",
        f"- Latest commit date: `{span['latest_date']}`",
        f"- Commits inspected: `{span['total_commits']}`",
        f"- First commit: `{span['first_commit']['sha']}` {span['first_commit']['subject']}",
        f"- Latest commit: `{span['latest_commit']['sha']}` {span['latest_commit']['subject']}",
        "",
        "## Public Story Arc",
        "",
    ]
    for chapter in story["chapters"]:
        lines.extend(
            [
                f"### {chapter['title']}",
                "",
                chapter["owner_value"],
                "",
                f"Owner translation: {chapter['sales_translation']}",
                "",
                f"Commit evidence: `{chapter['commit_count']}` matching commits from "
                f"`{chapter['first_date']}` to `{chapter['latest_date']}`.",
                "",
                "| Date | Commit | What changed |",
                "|---|---|---|",
            ]
        )
        for commit in chapter["evidence_commits"][:5]:
            lines.append(f"| {commit['date']} | `{commit['sha']}` | {commit['subject']} |")
        lines.append("")
    lines.extend(
        [
            "## Owner-Facing Message Pack",
            "",
            f"Schema: `{MESSAGE_SCHEMA_VERSION}`",
            "",
            f"Core offer: {story['message_pack']['core_offer']}",
            "",
            f"Owner promise: {story['message_pack']['owner_promise']}",
            "",
            "Primary CTA: `Map my workflow`",
            "",
            "The reusable story arc for this repo is:",
            "",
            "| Stage | Visible wording | Visual cue |",
            "|---|---|---|",
        ]
    )
    for row in story["message_pack"]["story_arc"]:
        lines.append(f"| {row['stage']} | {row['visible_wording']} | {row['visual_cue']} |")
    lines.extend(
        [
            "",
            "Required visual primitives:",
            "",
            "| Primitive | Job |",
            "|---|---|",
        ]
    )
    for row in story["message_pack"]["visual_primitives"]:
        lines.append(f"| `{row['name']}` | {row['job']} |")
    lines.extend(
        [
            "",
            "## Use On The Public Site",
            "",
            "The site should summarize this arc for SMB owners:",
            "",
            "- the work started somewhere concrete;",
            "- the process exposed friction instead of hiding it;",
            "- proof became part of the operating loop;",
            "- useful lessons became reusable methods, scripts, runbooks, or design grammar;",
            "- the current page translates that machinery into a buying journey.",
            "",
            "For Flywheel, the detailed receipts remain in",
            "`docs/evidence/publication-evidence.md`.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", default=str(repo_root()))
    parser.add_argument("--repo-label")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--write-json")
    parser.add_argument("--write-md")
    args = parser.parse_args()

    repo = Path(args.repo).resolve()
    story = build_story(repo, args.repo_label or repo.name)
    if args.write_json:
        path = Path(args.write_json)
        if not path.is_absolute():
            path = repo / path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(story, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    if args.write_md:
        path = Path(args.write_md)
        if not path.is_absolute():
            path = repo / path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(render_markdown(story), encoding="utf-8")
    if args.json or not (args.write_json or args.write_md):
        print(json.dumps(story, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
