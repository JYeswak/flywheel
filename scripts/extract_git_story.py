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
DOSSIER_SCHEMA_VERSION = "zeststream.repo_story_dossier.v0"
FRONTEND_SCHEMA_VERSION = "zeststream.repo_frontend_story.v0"

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

PUBLIC_HISTORY_REPHRASES = (
    ("private review bundle", "staging review bundle"),
    ("private review checks", "staging review checks"),
    ("private review packet", "staging review packet"),
    ("private-review", "staging-review"),
    ("private site", "staging site"),
    ("Private site", "Staging site"),
    ("Keep GitHub private", "Hold GitHub release"),
)


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
        "owner_takeaway": "We begin with the actual path work takes today, including the handoffs people have stopped noticing.",
        "visual_scene": "A first-room operating map with existing tools, owner memory, and one highlighted manual route.",
        "copy_block": "Before we automate anything, we make the work visible enough to inspect.",
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
        "owner_takeaway": "The value is not that an AI agent did work. The value is that the work left behind proof a business owner can question.",
        "visual_scene": "A proof rail beside the workflow with proven, blocked, skipped-with-reason, and private states.",
        "copy_block": "Claims earn their place on the page by surviving checks, not by sounding impressive.",
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
        "owner_takeaway": "Blocked evidence is a control surface. It shows the operator is willing to stop before chaos reaches the business.",
        "visual_scene": "A visible friction band where unsupported claims are held in amber until the proof catches up.",
        "copy_block": "If the proof is not ready, the claim stays blocked.",
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
        "owner_takeaway": "The operator does not sell a fresh start every time. Each project improves the next project.",
        "visual_scene": "A lesson ledger showing which checks, words, components, or runbooks were created from the last hard-earned lesson.",
        "copy_block": "A useful lesson becomes a reusable method, not a memory in one chat window.",
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
        "owner_takeaway": "The public page should feel like a guided visit through a working shop, not a generic AI pitch.",
        "visual_scene": "A cinematic but calm buyer journey: workflow room, slice workbench, proof theater, trajectory rail, contact room.",
        "copy_block": "The story lands when a buyer can see the workflow pain, the safe first slice, and the proof path without decoding the stack.",
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
    {
        "name": "LessonLedger",
        "job": "Show how hard-earned lessons become reusable checks, copy, components, or runbooks.",
    },
    {
        "name": "SafeContactPanel",
        "job": "Ask for a redacted workflow example while keeping secrets and raw customer data out.",
    },
]

AUDIENCE_TRUTHS = [
    "The owner is usually buying back time, not buying AI.",
    "The pain lives between systems: email, CRM, scheduling, invoices, documents, reports, and staff memory.",
    "Trust comes from human approval, narrow scope, privacy clarity, and visible stop conditions.",
    "A beautiful public surface must still behave like proof: every claim either has evidence or stays blocked.",
    "Commit history is not the pitch. The pitch is the trajectory those commits prove.",
]

OWNER_LANGUAGE_BANK = {
    "lead_with": [
        "buy back the time hiding between your tools",
        "one workflow slice",
        "mapped before motion",
        "human-approved",
        "proof state",
        "blocked until proven",
        "lessons that carry into the next build",
        "the work your team already does by hand",
    ],
    "replace": [
        {
            "weak": "AI transformation",
            "strong": "one inspected workflow improvement",
        },
        {
            "weak": "autonomous agents",
            "strong": "human-approved workflow slices",
        },
        {
            "weak": "seamless integration",
            "strong": "one route between the tools you already use",
        },
        {
            "weak": "powerful automation",
            "strong": "less copying, chasing, checking, and remembering",
        },
        {
            "weak": "we built a lot",
            "strong": "the repo history shows what changed and what stayed blocked",
        },
    ],
    "proof_phrases": [
        "The map comes before automation.",
        "Blocked is better than bluffing.",
        "The owner approves the slice.",
        "Private work stays private.",
        "A lesson is only valuable when the next project inherits it.",
    ],
}

JEFF_INSPIRED_PATTERNS = [
    {
        "pattern": "status-rich first viewport",
        "zeststream_translation": "Open with a live-feeling workflow room, not a generic hero or tool diagram.",
    },
    {
        "pattern": "interactive demos and architecture tabs",
        "zeststream_translation": "Use owner, method, proof, and reviewer rooms so the buyer can go shallow or deep.",
    },
    {
        "pattern": "dense proof after a clear claim",
        "zeststream_translation": "Lead with owner consequence, then let reviewers open receipts, tests, and generated artifacts.",
    },
    {
        "pattern": "glossary/tooltips for advanced concepts",
        "zeststream_translation": "Translate slice, proof state, blocker, and lesson ledger into plain language on hover or drawer.",
    },
    {
        "pattern": "visual systems that make invisible runtime behavior visible",
        "zeststream_translation": "Show routes, queues, proof rails, and friction bands as the visual language of the operator brand.",
    },
]

PAGE_BLUEPRINT = [
    {
        "section_id": "operating-room-hero",
        "component": "OperatingRoomHero",
        "job": "Make the owner feel the trapped work between tools before naming AI.",
        "proof_source": "message_pack.story_arc[recognize]",
    },
    {
        "section_id": "owner-tension-room",
        "component": "OwnerTensionRoom",
        "job": "Name the ten reasons SMB owners hesitate and show the control beside each one.",
        "proof_source": "message_pack.trust_objections",
    },
    {
        "section_id": "slice-workbench",
        "component": "SliceWorkbench",
        "job": "Define a slice as the safe unit of work: useful, inspectable, stoppable.",
        "proof_source": "message_pack.story_arc[bound]",
    },
    {
        "section_id": "proof-theater",
        "component": "ProofRail",
        "job": "Show proven, blocked, skipped, and private states without forcing raw receipt reading.",
        "proof_source": "message_pack.proof_translation",
    },
    {
        "section_id": "trajectory-room",
        "component": "TrajectoryRail",
        "job": "Convert git history into origin, friction, proof loop, reuse, and current arc.",
        "proof_source": "chapters",
    },
    {
        "section_id": "lesson-ledger",
        "component": "LessonLedger",
        "job": "Show which lessons became shared checks, copy, tokens, components, or runbooks.",
        "proof_source": "chapters[reuse]",
    },
    {
        "section_id": "decision-room",
        "component": "ProofDrawer",
        "job": "Let technical reviewers inspect artifacts after the owner story lands.",
        "proof_source": "docs/evidence/publication-evidence.md",
    },
    {
        "section_id": "safe-contact-room",
        "component": "SafeContactPanel",
        "job": "Ask for a redacted workflow example, not secrets or broad access.",
        "proof_source": "message_pack.story_arc[act]",
    },
]

NEXTJS_FOUNDATION_TARGETS = {
    "routes": [
        "/",
        "/method",
        "/proof",
        "/story",
        "/contact",
    ],
    "server_components": [
        "RepoStoryData",
        "ProofManifest",
        "TrajectoryRail",
        "LessonLedger",
    ],
    "client_components": [
        "WorkflowMap",
        "SliceWorkbench",
        "ProofDrawer",
        "TrustWorryMatrix",
    ],
    "data_sources": [
        "docs/evidence/repo-trajectory.json",
        "docs/stories/repo-trajectory.md",
        "packages/zeststream-story-system/story-system.json",
    ],
    "quality_gates": [
        "generated story artifact must exist before page build",
        "Playwright desktop and mobile screenshots must render nonblank visual primitives",
        "blocked phrases from the story package cannot appear on public pages",
        "proof drawers must not ship private raw state to the browser",
    ],
}


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
    for old, new in PUBLIC_HISTORY_REPHRASES:
        sanitized = sanitized.replace(old, new)
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
        "owner_takeaway": chapter["owner_takeaway"],
        "visual_scene": chapter["visual_scene"],
        "copy_block": chapter["copy_block"],
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


def resolve_redaction_table(repo: Path, explicit_table: str | None = None) -> Path:
    if explicit_table:
        candidate = Path(explicit_table)
        if not candidate.is_absolute():
            candidate = Path.cwd() / candidate
        return candidate.resolve()
    repo_table = repo / DEFAULT_TABLE
    if repo_table.exists():
        return repo_table
    return repo_root() / DEFAULT_TABLE


def redaction_table_ref(repo: Path, table_path: Path) -> str:
    flywheel_root = repo_root()
    for prefix, root in (("repo", repo), ("flywheel", flywheel_root)):
        try:
            rel = table_path.resolve().relative_to(root.resolve())
        except ValueError:
            continue
        return f"{prefix}:{rel.as_posix()}"
    return f"external:{table_path.name}"


def build_story(repo: Path, repo_label: str, redaction_table: Path | None = None) -> dict[str, Any]:
    table_path = redaction_table or resolve_redaction_table(repo)
    rows = load_replacement_table(table_path)
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
        "generated_date": dt.datetime.now(dt.timezone.utc).date().isoformat(),
        "repo_label": repo_label,
        "source": "git log --reverse --date=short --pretty=format:... --name-only HEAD",
        "redaction_table": redaction_table_ref(repo, table_path),
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
    story["story_dossier"] = build_story_dossier(repo_label, story)
    story["frontend_story"] = build_frontend_story(repo_label, story)
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


def build_story_dossier(repo_label: str, story: dict[str, Any]) -> dict[str, Any]:
    span = story["commit_span"]
    return {
        "schema_version": DOSSIER_SCHEMA_VERSION,
        "source_story_schema": SCHEMA_VERSION,
        "source_message_schema": MESSAGE_SCHEMA_VERSION,
        "repo_label": repo_label,
        "job": "Turn repo history into an SMB-facing page brief that proves trajectory without making commit volume the sales claim.",
        "audience_truths": AUDIENCE_TRUTHS,
        "owner_language_bank": OWNER_LANGUAGE_BANK,
        "reference_patterns": JEFF_INSPIRED_PATTERNS,
        "page_blueprint": PAGE_BLUEPRINT,
        "nextjs_foundation_targets": NEXTJS_FOUNDATION_TARGETS,
        "trajectory_summary": {
            "start": f"Work began on {span['first_date']} with {span['first_commit']['subject']}.",
            "current": f"The latest inspected movement is {span['latest_commit']['subject']} on {span['latest_date']}.",
            "owner_meaning": "The repo has a visible path from setup, through friction, into proof, reuse, and public story.",
        },
        "visual_direction": {
            "first_impression": "A working operating room for a real SMB workflow, not a floating SaaS card stack.",
            "motion_rule": "Use motion to show handoff, proof state, and lesson carry-forward; do not use decoration-only motion.",
            "density_rule": "Let the first screen feel alive, then let the buyer choose owner, method, proof, or reviewer depth.",
            "asset_rule": "Use real workflow scenes, generated bitmap assets, or product-state visuals; avoid generic abstract gradients.",
        },
        "signoff_questions": [
            "Can an SMB owner explain the first safe step after reading the page?",
            "Can a reviewer trace every strong claim to a generated story artifact, receipt, or test?",
            "Does the design make the workflow and proof path visible without requiring GitHub literacy?",
            "Does the page feel ownable to the operator brand rather than copied from another builder's aesthetic?",
        ],
    }


def build_frontend_story(repo_label: str, story: dict[str, Any]) -> dict[str, Any]:
    """Translate git story evidence into props for reusable ZestStream UI primitives."""

    message = story["message_pack"]
    chapters = story["chapters"]
    friction = strongest_chapter(chapters, "friction")
    proof_loop = strongest_chapter(chapters, "proof-loop")
    reuse = strongest_chapter(chapters, "reuse")
    proof_items = [
        {
            "label": "Repo trajectory",
            "state": "proven",
            "detail": "Generated from git history, not one session's memory.",
            "receiptUrl": "docs/stories/repo-trajectory.md",
        },
        {
            "label": "Friction visible",
            "state": "proven" if friction["commit_count"] > 0 else "blocked",
            "detail": f"{friction['commit_count']} blocker/friction signals inspected.",
            "receiptUrl": "docs/evidence/repo-trajectory.json",
        },
        {
            "label": "Proof loop",
            "state": "proven" if proof_loop["commit_count"] > 0 else "blocked",
            "detail": f"{proof_loop['commit_count']} proof-loop signals inspected.",
            "receiptUrl": "docs/evidence/repo-trajectory.json",
        },
        {
            "label": "Reusable lessons",
            "state": "proven" if reuse["commit_count"] > 0 else "blocked",
            "detail": f"{reuse['commit_count']} reusable-method signals inspected.",
            "receiptUrl": "docs/evidence/repo-trajectory.json",
        },
    ]
    trust_worries = [
        {
            "ownerWorry": row["objection"],
            "visibleAnswer": row["visible_answer"],
            "proofBehavior": row["proof_behavior"],
            "proofState": "proven",
        }
        for row in message["trust_objections"]
    ]
    yuzu_stages = [
        {
            "id": row["stage"],
            "label": row["stage"].replace("-", " ").title(),
            "detail": row["visible_wording"],
        }
        for row in message["story_arc"]
    ]
    lessons = [
        {
            "date": chapter["latest_date"] or story["generated_date"],
            "lesson": chapter["owner_takeaway"],
            "appliedTo": chapter["visual_scene"],
        }
        for chapter in chapters
    ]
    return {
        "schema_version": FRONTEND_SCHEMA_VERSION,
        "source_story_schema": SCHEMA_VERSION,
        "source_message_schema": MESSAGE_SCHEMA_VERSION,
        "source_dossier_schema": DOSSIER_SCHEMA_VERSION,
        "repo_label": repo_label,
        "package_targets": {
            "tokens": "@zeststream/story-system",
            "components": "@zeststream/ui",
        },
        "copy_rule": "Show the proof, not the dream; every strong line must point to proof, blocked state, or a safe first step.",
        "blocked_language": message["must_not_say"],
        "quality_gate_commands": [
            "python3 scripts/extract_git_story.py --repo <repo> --write-json docs/evidence/repo-trajectory.json --write-md docs/stories/repo-trajectory.md",
            "python3 scripts/validate_story_system_package.py --json",
            "bash scripts/zs-frontend-quality-gate.sh --repo <nextjs-repo> --json --strict",
            "playwright screenshot checks for desktop and mobile proof primitives",
        ],
        "component_props": {
            "OperatingRoomHero": {
                "headline": message["page_headline_options"][0],
                "subhead": message["core_offer"],
                "tools": ["Email", "CRM", "Calendar", "Invoices", "Documents", "Reports"],
                "activeRoute": ["Email", "CRM"],
                "primaryCta": {"label": message["primary_cta"], "href": "/contact"},
                "secondaryCta": {"label": message["secondary_cta"], "href": "/proof"},
            },
            "WorkflowMap": {
                "title": f"{repo_label} first workflow slice",
                "nodes": [
                    {"id": "source", "label": "Owner request", "role": "source", "system": "Inbox"},
                    {"id": "slice", "label": "Bounded slice", "role": "transform", "system": "Yuzu Method"},
                    {"id": "proof", "label": "Proof state", "role": "gate", "system": "Receipt"},
                    {"id": "lesson", "label": "Reusable lesson", "role": "sink", "system": "Flywheel"},
                ],
                "edges": [
                    {"from": "source", "to": "slice", "label": "map", "proofState": "proven"},
                    {"from": "slice", "to": "proof", "label": "verify", "proofState": "proven"},
                    {"from": "proof", "to": "lesson", "label": "carry forward", "proofState": "proven"},
                ],
            },
            "SliceWorkbench": {
                "sliceName": "One bounded workflow improvement",
                "before": {
                    "steps": ["Copy", "Chase", "Check", "Remember"],
                    "cost": "Manual time hidden between tools",
                },
                "after": {
                    "steps": ["Map the route", "Improve one slice", "Verify the proof", "Keep the lesson"],
                    "cost": "One inspected change before any broader rollout",
                },
                "scopeNote": "This is one slice first. Anything unproven stays blocked, private, or skipped with a reason.",
            },
            "ProofRail": {"items": proof_items, "title": "Proof path", "showCount": True},
            "TrustWorryMatrix": {"title": "Owner worries answered by controls", "worries": trust_worries},
            "YuzuMethodRail": {"stages": yuzu_stages, "currentStage": "control", "showMark": True},
            "ProofDrawer": {
                "verdict": "proven",
                "headline": "The page story is generated from repo trajectory evidence.",
                "receipts": [
                    {
                        "label": "Generated story",
                        "detail": "Sanitized Markdown story generated from git history.",
                        "url": "docs/stories/repo-trajectory.md",
                    },
                    {
                        "label": "Generated JSON",
                        "detail": "Machine-readable message pack, dossier, and frontend story.",
                        "url": "docs/evidence/repo-trajectory.json",
                    },
                ],
            },
            "LessonLedger": {"lessons": lessons, "title": "Lessons that became method"},
            "SafeContactPanel": {
                "headline": "Start with one workflow map",
                "cta": {"label": message["primary_cta"], "href": "/contact"},
                "trustAnchors": [
                    {
                        "anchor": "Human approval",
                        "detail": "The owner approves the slice before broader motion.",
                    },
                    {
                        "anchor": "Narrow scope",
                        "detail": "The first engagement is one workflow route, not the whole company.",
                    },
                    {
                        "anchor": "Visible stop conditions",
                        "detail": "Unproven claims stay blocked instead of becoming copy.",
                    },
                    {
                        "anchor": "Privacy clarity",
                        "detail": "Use redacted examples before secrets, customer data, or system access.",
                    },
                ],
                "notFor": ["black-box automation", "set-it-and-forget-it AI", "broad access before a map"],
            },
        },
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
    dossier = story["story_dossier"]
    lines.extend(
        [
            "",
            "## Story Dossier",
            "",
            f"Schema: `{DOSSIER_SCHEMA_VERSION}`",
            "",
            dossier["job"],
            "",
            "Audience truths:",
            "",
        ]
    )
    for truth in dossier["audience_truths"]:
        lines.append(f"- {truth}")
    lines.extend(
        [
            "",
            "Page blueprint:",
            "",
            "| Section | Component | Job |",
            "|---|---|---|",
        ]
    )
    for row in dossier["page_blueprint"]:
        lines.append(f"| `{row['section_id']}` | `{row['component']}` | {row['job']} |")
    lines.extend(
        [
            "",
            "Owner language bank:",
            "",
        ]
    )
    for phrase in dossier["owner_language_bank"]["proof_phrases"]:
        lines.append(f"- {phrase}")
    lines.extend(
        [
            "",
            "## Frontend Story Payload",
            "",
            f"Schema: `{FRONTEND_SCHEMA_VERSION}`",
            "",
            "The generated payload maps the story directly onto shared public",
            "frontend primitives, so a repo can render the arc without rewriting the",
            "message from scratch.",
            "",
            "| Component | Generated purpose |",
            "|---|---|",
        ]
    )
    for name, props in story["frontend_story"]["component_props"].items():
        purpose = props.get("headline") or props.get("title") or props.get("sliceName") or props.get("headline", "")
        if not purpose and name == "ProofRail":
            purpose = "Proof path"
        if not purpose and name == "TrustWorryMatrix":
            purpose = "Owner worries answered by controls"
        if not purpose:
            purpose = "Reusable story primitive"
        lines.append(f"| `{name}` | {purpose} |")
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
    parser.add_argument(
        "--redaction-table",
        help="Optional de-personalization table. Defaults to the target repo table when present, otherwise Flywheel's public table.",
    )
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--write-json")
    parser.add_argument("--write-md")
    args = parser.parse_args()

    repo = Path(args.repo).resolve()
    story = build_story(repo, args.repo_label or repo.name, resolve_redaction_table(repo, args.redaction_table))
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
