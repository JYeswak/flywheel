#!/usr/bin/env python3
"""Validate the public contact form routing contract."""

from __future__ import annotations

import argparse
import json
import sys
from html.parser import HTMLParser
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, unquote, urlsplit


EXPECTED_ADDRESS = "joshua@zeststream.ai"
EXPECTED_SUBJECT = "[Flywheel] Public site inquiry"
REQUIRED_FIELDS = {"topic", "message"}


class ContactParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.forms: list[dict[str, str]] = []
        self.fields: set[str] = set()
        self.labels: set[str] = set()
        self.submit_buttons = 0
        self.direct_mailto_links: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attr = {key: value or "" for key, value in attrs}
        if tag == "form":
            self.forms.append(attr)
        if tag in {"input", "select", "textarea"} and attr.get("name"):
            self.fields.add(attr["name"])
        if tag == "label" and attr.get("for"):
            self.labels.add(attr["for"])
        if tag == "button" and attr.get("type", "submit") == "submit":
            self.submit_buttons += 1
        if tag == "a" and attr.get("href", "").startswith("mailto:"):
            self.direct_mailto_links.append(attr["href"])


def parse_mailto(value: str) -> tuple[str, str]:
    parsed = urlsplit(value)
    address = parsed.path
    subject = parse_qs(parsed.query).get("subject", [""])[0]
    return address, unquote(subject)


def validate(path: Path) -> dict[str, Any]:
    parser = ContactParser()
    parser.feed(path.read_text(encoding="utf-8"))
    failures: list[str] = []

    mailto_forms = [form for form in parser.forms if form.get("action", "").startswith("mailto:")]
    if len(mailto_forms) != 1:
        failures.append(f"expected exactly one mailto form, found {len(mailto_forms)}")
        form_action = ""
    else:
        form_action = mailto_forms[0].get("action", "")
        if mailto_forms[0].get("method", "").lower() != "post":
            failures.append("contact form method must be post")
        if mailto_forms[0].get("enctype", "").lower() != "text/plain":
            failures.append("contact form enctype must be text/plain")

    if form_action:
        address, subject = parse_mailto(form_action)
        if address != EXPECTED_ADDRESS:
            failures.append(f"contact form address mismatch: {address}")
        if subject != EXPECTED_SUBJECT:
            failures.append(f"contact form subject mismatch: {subject}")

    missing_fields = sorted(REQUIRED_FIELDS - parser.fields)
    if missing_fields:
        failures.append(f"missing contact fields: {','.join(missing_fields)}")

    missing_labels = sorted(REQUIRED_FIELDS - parser.labels)
    if missing_labels:
        failures.append(f"missing contact labels: {','.join(missing_labels)}")

    if parser.submit_buttons < 1:
        failures.append("missing submit button")

    direct_ok = False
    for link in parser.direct_mailto_links:
        address, subject = parse_mailto(link)
        if address == EXPECTED_ADDRESS and subject == EXPECTED_SUBJECT:
            direct_ok = True
    if not direct_ok:
        failures.append("missing direct mailto fallback link")

    return {
        "schema_version": "flywheel.contact_route.v0",
        "status": "pass" if not failures else "fail",
        "path": str(path),
        "address": EXPECTED_ADDRESS,
        "subject": EXPECTED_SUBJECT,
        "required_fields": sorted(REQUIRED_FIELDS),
        "submit_button_count": parser.submit_buttons,
        "failures": failures,
        "delivery_claim": "mailto_client_open_only",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--file", default="site/contact/index.html")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    result = validate(Path(args.file))
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(f"status={result['status']} failures={len(result['failures'])}")
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
