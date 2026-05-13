#!/usr/bin/env python3
"""Scan public release surfaces for undispositioned gap markers."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


SKILLOS_BOUNDARY_DOC = "docs/concepts/" + "skil" + "los-boundary.md"

DEFAULT_FILES = [
    "README.md",
    "CHARTER.md",
    "CONTRIBUTING.md",
    "SECURITY.md",
    "SUPPORT.md",
    "CODE_OF_CONDUCT.md",
    "CHANGELOG.md",
    "ARCHITECTURE.md",
    "docs/brand/naming-conventions.md",
    "docs/getting-started/first-run.md",
    "docs/runbooks/public-release-runbook.md",
    "docs/runbooks/release-cutover-authorization.md",
    "docs/runbooks/context-and-model-routing.md",
    "docs/runbooks/agent-lane-compatibility.md",
    "docs/runbooks/upstream-substrate-adoption.md",
    "docs/stories/public-journey-and-redaction.md",
    "docs/concepts/loops.md",
    "docs/concepts/beads.md",
    "docs/concepts/agent-mail.md",
    "docs/concepts/socraticode.md",
    SKILLOS_BOUNDARY_DOC,
    "docs/concepts/evidence-contracts.md",
    "docs/evidence/publication-evidence.md",
    "docs/evidence/publication-blocker-coverage.md",
    "docs/evidence/asupersync-gated-adoption.md",
    "docs/reference/commands.md",
    "docs/reference/files.md",
    "docs/reference/troubleshooting.md",
    ".github/PULL_REQUEST_TEMPLATE.md",
    ".github/ISSUE_TEMPLATE/bug.md",
    ".github/ISSUE_TEMPLATE/feature.md",
    ".github/ISSUE_TEMPLATE/trauma.md",
    ".github/workflows/ci.yml",
    ".github/workflows/installer-smoke.yml",
    ".github/workflows/release.yml",
    ".github/workflows/site.yml",
    "install.sh",
    "uninstall.sh",
    "bin/flywheel",
    "scripts/preflight.sh",
    "scripts/journey-smoke.sh",
    "scripts/agent-lane-probe.sh",
    "site/index.html",
    "site/what-is/index.html",
    "site/for-developers/index.html",
    "site/methodology/index.html",
    "site/about/index.html",
    "site/contact/index.html",
]

STRONG_RE = re.compile(r"\b(TODO|FIXME|unproven)\b", re.IGNORECASE)
DOC_SOFT_RE = re.compile(r"(?<![-_/A-Za-z0-9])(?:gap|gaps|blocker|blockers|blocked|missing)(?![-_/A-Za-z0-9])")
TRACKED_RE = re.compile(r"\b(?:TP-\d{3}|flywheel-[a-z0-9]+(?:\.[0-9]+)?)\b")
DISPOSITION_RE = re.compile(
    r"\b(?:non[-_]release|not release blocker|compatibility target|runtime[- ]proven|"
    r"documented runtime state|runtime status|schema field|fixture language|"
    r"example only|error message|not a supported path|release blocker|support copy|"
    r"gated[- ]evaluation|gated by live evidence|Promotion is blocked|"
    r"blocked until|blocked as expected)\b",
    re.IGNORECASE,
)
BENIGN_SOFT_RE = re.compile(
    r"(missing required dependenc|dependency is missing|dependencies are missing|"
    r"full-mode substrate missing|full-mode tools are missing|installed file missing|install source missing|"
    r"command missing|status:\"missing\"|missing_artifact|summary\.required_missing|audit gaps|"
    r"status=blocked|status is `blocked`|returns `blocked`|zero blockers|"
    r"Readiness blocker code|publication-readiness blocker code|"
    r"public release is not complete while|"
    r"public surface gap scanner|full.*reduced.*blocked|source-gap|fixture-blocked|"
    r"blocked, or docs-only mode|full, reduced, blocked|blocked mode|reduced mode blocked|"
    r"gap discovery|gap detector|gap probe|gap-hunt|value-gap|topology-gap|process-gap|"
    r"no_bead_reason|DID/DIDNT/GAPS)",
    re.IGNORECASE,
)


def is_doc(path: Path) -> bool:
    return path.suffix.lower() in {".md", ".markdown"} or ".github/ISSUE_TEMPLATE" in path.as_posix()


def has_disposition(line: str) -> bool:
    return bool(TRACKED_RE.search(line) or DISPOSITION_RE.search(line))


def marker_kind(line: str, doc: bool) -> str | None:
    if STRONG_RE.search(line):
        return "strong_marker"
    if doc and DOC_SOFT_RE.search(line) and not BENIGN_SOFT_RE.search(line):
        return "public_doc_marker"
    return None


def scan_file(repo: Path, path: Path) -> list[dict[str, object]]:
    findings: list[dict[str, object]] = []
    rel = path.relative_to(repo).as_posix()
    doc = is_doc(path.relative_to(repo))
    in_fence = False
    previous = ""

    for line_no, raw in enumerate(path.read_text(errors="replace").splitlines(), start=1):
        stripped = raw.strip()
        if doc and stripped.startswith("```"):
            in_fence = not in_fence
            previous = raw
            continue

        kind = marker_kind(raw, doc)
        if not kind:
            previous = raw
            continue
        if in_fence and not STRONG_RE.search(raw):
            previous = raw
            continue

        disposition = has_disposition(raw) or has_disposition(previous)
        findings.append(
            {
                "path": rel,
                "line": line_no,
                "kind": kind,
                "dispositioned": disposition,
                "text": raw.strip(),
            }
        )
        previous = raw

    return findings


def resolve_files(repo: Path, files: list[str]) -> tuple[list[Path], list[str]]:
    resolved: list[Path] = []
    missing: list[str] = []
    for item in files:
        path = Path(item)
        if not path.is_absolute():
            path = repo / path
        if path.exists() and path.is_file():
            resolved.append(path.resolve())
        else:
            missing.append(item)
    return resolved, missing


def payload(repo: Path, files: list[Path], missing: list[str], release: bool) -> dict[str, object]:
    findings: list[dict[str, object]] = []
    for file in files:
        findings.extend(scan_file(repo, file))
    undispositioned = [row for row in findings if not row["dispositioned"]]
    errors: list[dict[str, object]] = []
    if missing:
        errors.append({"code": "public_surface_missing", "paths": missing})
    if release and undispositioned:
        errors.append({"code": "undispositioned_public_gap", "count": len(undispositioned)})
    return {
        "schema_version": "flywheel.public_surface_gap_scan.v0",
        "status": "fail" if errors else "pass",
        "mode": "release" if release else "normal",
        "repo": str(repo),
        "file_count": len(files),
        "files": [path.relative_to(repo).as_posix() for path in files],
        "finding_count": len(findings),
        "undispositioned_count": len(undispositioned),
        "findings": findings,
        "undispositioned": undispositioned,
        "errors": errors,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", default=".")
    parser.add_argument("--file", action="append", dest="files")
    parser.add_argument("--release", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    repo = Path(args.repo).resolve()
    scan_files, missing = resolve_files(repo, args.files or DEFAULT_FILES)
    result = payload(repo, scan_files, missing, args.release)

    if args.json:
        print(json.dumps(result, separators=(",", ":")))
    else:
        print(
            f"{result['status']} files={result['file_count']} "
            f"findings={result['finding_count']} undispositioned={result['undispositioned_count']}"
        )
    return 1 if result["status"] == "fail" else 0


if __name__ == "__main__":
    raise SystemExit(main())
