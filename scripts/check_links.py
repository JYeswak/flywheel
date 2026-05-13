#!/usr/bin/env python3
"""Check local links in public Flywheel markdown and website files."""

from __future__ import annotations

import argparse
import json
import re
import sys
from html.parser import HTMLParser
from pathlib import Path
from typing import Any
from urllib.parse import unquote, urlsplit


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
    "docs/runbooks/public-user-journey-pack.md",
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
    "site/index.html",
    "site/what-is/index.html",
    "site/for-developers/index.html",
    "site/methodology/index.html",
    "site/about/index.html",
    "site/contact/index.html",
]

MARKDOWN_LINK_RE = re.compile(r"(?<!!)\[[^\]]+\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
HTML_LINK_ATTRS = {"href", "src"}
EXTERNAL_SCHEMES = {"http", "https", "mailto", "tel", "sms"}


class HtmlLinkParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.links: list[tuple[str, str]] = []
        self.ids: set[str] = set()

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attr_map = {key: value or "" for key, value in attrs}
        if attr_map.get("id"):
            self.ids.add(attr_map["id"])
        for attr in HTML_LINK_ATTRS:
            if attr_map.get(attr):
                self.links.append((attr, attr_map[attr]))


def github_anchor(text: str) -> str:
    lowered = text.strip().lower()
    lowered = re.sub(r"[^\w\s-]", "", lowered)
    lowered = re.sub(r"\s+", "-", lowered)
    lowered = re.sub(r"-+", "-", lowered)
    return lowered.strip("-")


def markdown_anchors(path: Path) -> set[str]:
    anchors: set[str] = set()
    in_fence = False
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        stripped = raw.strip()
        if stripped.startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        match = re.match(r"^(#{1,6})\s+(.+?)\s*$", raw)
        if match:
            heading = re.sub(r"\s+#+$", "", match.group(2)).strip()
            anchor = github_anchor(heading)
            if anchor:
                anchors.add(anchor)
    return anchors


def html_anchors(path: Path) -> set[str]:
    parser = HtmlLinkParser()
    parser.feed(path.read_text(encoding="utf-8", errors="replace"))
    return parser.ids


def anchors_for(path: Path) -> set[str]:
    if path.suffix.lower() in {".md", ".markdown"}:
        return markdown_anchors(path)
    if path.suffix.lower() in {".html", ".htm"}:
        return html_anchors(path)
    return set()


def split_link(raw: str) -> tuple[str, str]:
    parsed = urlsplit(raw)
    target = unquote(parsed.path)
    fragment = unquote(parsed.fragment)
    return target, fragment


def is_external(raw: str) -> bool:
    parsed = urlsplit(raw)
    return parsed.scheme in EXTERNAL_SCHEMES or raw.startswith("//")


def resolve_target(source: Path, raw: str, repo: Path) -> Path:
    target, _fragment = split_link(raw)
    if not target:
        return source
    path = Path(target)
    if path.is_absolute():
        return (repo / target.lstrip("/")).resolve()
    return (source.parent / path).resolve()


def markdown_links(path: Path) -> list[str]:
    links: list[str] = []
    in_fence = False
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        stripped = raw.strip()
        if stripped.startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        links.extend(match.group(1).strip("<>") for match in MARKDOWN_LINK_RE.finditer(raw))
    return links


def html_links(path: Path) -> list[str]:
    parser = HtmlLinkParser()
    parser.feed(path.read_text(encoding="utf-8", errors="replace"))
    return [value for _attr, value in parser.links]


def links_for(path: Path) -> list[str]:
    if path.suffix.lower() in {".md", ".markdown"}:
        return markdown_links(path)
    if path.suffix.lower() in {".html", ".htm"}:
        return html_links(path)
    return []


def check_link(source: Path, raw: str, repo: Path) -> dict[str, Any]:
    if is_external(raw):
        return {"status": "skipped_external", "target": raw}
    if raw.startswith("#"):
        target_path = source
        fragment = unquote(raw[1:])
    else:
        target_path = resolve_target(source, raw, repo)
        _target, fragment = split_link(raw)

    if not target_path.exists():
        return {"status": "fail", "target": raw, "reason": "missing_target", "resolved": str(target_path)}
    if fragment and fragment not in anchors_for(target_path):
        return {
            "status": "fail",
            "target": raw,
            "reason": "missing_anchor",
            "anchor": fragment,
            "resolved": str(target_path),
        }
    return {"status": "pass", "target": raw, "resolved": str(target_path)}


def check_files(repo: Path, files: list[Path]) -> dict[str, Any]:
    results: list[dict[str, Any]] = []
    missing_sources: list[str] = []
    for source in files:
        if not source.exists():
            missing_sources.append(str(source.relative_to(repo)))
            continue
        rel = source.relative_to(repo).as_posix()
        for raw in links_for(source):
            result = check_link(source, raw, repo)
            result["source"] = rel
            results.append(result)

    failures = [item for item in results if item["status"] == "fail"]
    passed = sum(1 for item in results if item["status"] == "pass")
    skipped = sum(1 for item in results if item["status"] == "skipped_external")
    return {
        "schema_version": "flywheel.links.v0",
        "status": "pass" if not failures and not missing_sources else "fail",
        "source_count": len(files),
        "checked_count": passed,
        "skipped_external_count": skipped,
        "failure_count": len(failures) + len(missing_sources),
        "missing_sources": missing_sources,
        "failures": failures,
    }


def resolve_files(repo: Path, raw_files: list[str]) -> list[Path]:
    resolved = []
    for item in raw_files:
        path = Path(item)
        if not path.is_absolute():
            path = repo / path
        resolved.append(path.resolve())
    return resolved


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", default=".", help="repository root")
    parser.add_argument("--file", action="append", default=[], help="file to check; may be repeated")
    parser.add_argument("--json", action="store_true", help="emit JSON")
    args = parser.parse_args()

    repo = Path(args.repo).resolve()
    files = resolve_files(repo, args.file or DEFAULT_FILES)
    result = check_files(repo, files)
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(
            "status={status} source_count={source_count} checked_count={checked_count} "
            "skipped_external_count={skipped_external_count} failure_count={failure_count}".format(**result)
        )
        for failure in result["failures"]:
            print(f"FAIL {failure['source']} -> {failure['target']}: {failure['reason']}")
        for source in result["missing_sources"]:
            print(f"FAIL missing source: {source}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
