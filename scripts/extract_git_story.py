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
    return {
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
