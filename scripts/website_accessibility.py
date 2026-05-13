#!/usr/bin/env python3
"""Static accessibility checks for the public Flywheel site."""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter, defaultdict
from html.parser import HTMLParser
from pathlib import Path
from typing import Any


TEXT_TAGS = {"a", "button", "h1", "h2", "h3", "h4", "h5", "h6", "label", "option", "title"}
CONTROL_TAGS = {"input", "select", "textarea"}
HEADING_TAGS = {"h1", "h2", "h3", "h4", "h5", "h6"}


class PageParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.tags: list[tuple[str, dict[str, str]]] = []
        self.text: dict[int, list[str]] = defaultdict(list)
        self.stack: list[tuple[str, int]] = []
        self.heading_levels: list[int] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attr_map = {key: value or "" for key, value in attrs}
        index = len(self.tags)
        self.tags.append((tag, attr_map))
        self.stack.append((tag, index))
        if tag in HEADING_TAGS:
            self.heading_levels.append(int(tag[1]))

    def handle_endtag(self, tag: str) -> None:
        for idx in range(len(self.stack) - 1, -1, -1):
            if self.stack[idx][0] == tag:
                del self.stack[idx:]
                return

    def handle_data(self, data: str) -> None:
        if not data.strip():
            return
        for tag, index in reversed(self.stack):
            if tag in TEXT_TAGS:
                self.text[index].append(data.strip())


def visible_text(parser: PageParser, index: int) -> str:
    return " ".join(parser.text.get(index, [])).strip()


def check_page(path: Path) -> list[str]:
    parser = PageParser()
    parser.feed(path.read_text(encoding="utf-8"))
    failures: list[str] = []

    html_tags = [attrs for tag, attrs in parser.tags if tag == "html"]
    if not html_tags or html_tags[0].get("lang") != "en":
        failures.append("html lang must be en")

    titles = [visible_text(parser, index) for index, (tag, _attrs) in enumerate(parser.tags) if tag == "title"]
    if not any(titles):
        failures.append("title must be present and non-empty")

    if not any(tag == "meta" and attrs.get("name") == "viewport" for tag, attrs in parser.tags):
        failures.append("viewport meta tag must be present")

    h1_count = sum(1 for index, (tag, _attrs) in enumerate(parser.tags) if tag == "h1" and visible_text(parser, index))
    if h1_count != 1:
        failures.append(f"exactly one non-empty h1 required, found {h1_count}")

    for previous, current in zip(parser.heading_levels, parser.heading_levels[1:]):
        if current - previous > 1:
            failures.append(f"heading level jumps from h{previous} to h{current}")

    ids = [attrs["id"] for _tag, attrs in parser.tags if attrs.get("id")]
    duplicate_ids = sorted(item for item, count in Counter(ids).items() if count > 1)
    if duplicate_ids:
        failures.append(f"duplicate ids: {', '.join(duplicate_ids)}")

    label_targets = {attrs["for"] for tag, attrs in parser.tags if tag == "label" and attrs.get("for")}
    for index, (tag, attrs) in enumerate(parser.tags):
        if tag == "img" and not attrs.get("alt", "").strip():
            failures.append("image alt text must be present and non-empty")
        if tag == "a":
            href = attrs.get("href", "").strip()
            if href and not visible_text(parser, index) and not attrs.get("aria-label", "").strip():
                failures.append(f"link with href {href} needs text or aria-label")
        if tag == "button":
            if not visible_text(parser, index) and not attrs.get("aria-label", "").strip():
                failures.append("button needs text or aria-label")
        if tag in CONTROL_TAGS:
            control_id = attrs.get("id", "")
            if tag == "input" and attrs.get("type") == "hidden":
                continue
            if not attrs.get("aria-label", "").strip() and (not control_id or control_id not in label_targets):
                failures.append(f"{tag} control needs a label or aria-label")
        if attrs.get("tabindex", "") and attrs["tabindex"].isdigit() and int(attrs["tabindex"]) > 0:
            failures.append("positive tabindex is not allowed")

    return sorted(set(failures))


def run(site: Path) -> dict[str, Any]:
    pages = sorted(site.rglob("*.html"))
    results = []
    for page in pages:
        failures = check_page(page)
        results.append(
            {
                "path": str(page.relative_to(site)),
                "status": "pass" if not failures else "fail",
                "failures": failures,
            }
        )
    fail_count = sum(1 for result in results if result["status"] == "fail")
    return {
        "status": "pass" if fail_count == 0 and pages else "fail",
        "page_count": len(pages),
        "fail_count": fail_count,
        "pages": results,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--site", default="site", help="site directory")
    parser.add_argument("--json", action="store_true", help="emit JSON")
    args = parser.parse_args()

    result = run(Path(args.site))
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(f"status={result['status']} page_count={result['page_count']} fail_count={result['fail_count']}")
        for page in result["pages"]:
            for failure in page["failures"]:
                print(f"FAIL {page['path']}: {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
