#!/usr/bin/env python3
"""Probe first-party links and assets on the deployed Flywheel site."""

from __future__ import annotations

import argparse
import json
import re
import sys
from html.parser import HTMLParser
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import urldefrag, urljoin, urlsplit, urlunsplit
from urllib.request import Request, urlopen


SCHEMA_VERSION = "flywheel.live_site_probe.v0"
USER_AGENT = "flywheel-live-site-probe/0.1"
EXTERNAL_SCHEMES = {"mailto", "tel", "sms"}


class LinkParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.links: list[str] = []
        self.ids: set[str] = set()

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attr_map = {key: value or "" for key, value in attrs}
        if attr_map.get("id"):
            self.ids.add(attr_map["id"])
        for key in ("href", "src"):
            value = attr_map.get(key, "").strip()
            if value:
                self.links.append(value)


def canonical_base(url: str) -> str:
    parsed = urlsplit(url)
    path = parsed.path or "/"
    if not path.endswith("/"):
        path += "/"
    return urlunsplit((parsed.scheme, parsed.netloc, path, "", ""))


def page_url_for(site: Path, html: Path, base_url: str) -> str:
    rel = html.relative_to(site).as_posix()
    if rel == "index.html":
        return base_url
    if rel.endswith("/index.html"):
        return urljoin(base_url, rel[: -len("index.html")])
    return urljoin(base_url, rel)


def is_first_party(url: str, base_url: str) -> bool:
    parsed = urlsplit(url)
    base = urlsplit(base_url)
    if parsed.scheme in EXTERNAL_SCHEMES or url.startswith("//"):
        return False
    if parsed.scheme in {"http", "https"} and parsed.netloc != base.netloc:
        return False
    return True


def expected_urls(site: Path, base_url: str) -> set[str]:
    urls: set[str] = set()
    for path in sorted(site.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(site).as_posix()
        if rel.endswith("/index.html") or rel == "index.html":
            urls.add(page_url_for(site, path, base_url))
        elif path.suffix.lower() in {".css", ".svg", ".js", ".png", ".jpg", ".jpeg", ".webp", ".ico"}:
            urls.add(urljoin(base_url, rel))
    return urls


def collect_urls(site: Path, base_url: str) -> tuple[set[str], int, int]:
    urls = expected_urls(site, base_url)
    source_count = 0
    skipped_external = 0
    for html in sorted(site.rglob("*.html")):
        source_count += 1
        parser = LinkParser()
        parser.feed(html.read_text(encoding="utf-8", errors="replace"))
        source_url = page_url_for(site, html, base_url)
        for raw in parser.links:
            if not is_first_party(raw, base_url):
                skipped_external += 1
                continue
            absolute = urljoin(source_url, raw)
            urls.add(absolute)
    return urls, source_count, skipped_external


def fetch(url: str, timeout: float) -> tuple[int, str, str]:
    request = Request(url, headers={"User-Agent": USER_AGENT})
    with urlopen(request, timeout=timeout) as response:
        body = response.read(500_000)
        status_code = int(getattr(response, "status", 0) or response.getcode())
        content_type = response.headers.get("Content-Type", "")
    text = body.decode("utf-8", errors="replace")
    return status_code, content_type, text


def fragment_present(fragment: str, body: str) -> bool:
    escaped = re.escape(fragment)
    return bool(re.search(rf'\b(?:id|name)=["\']{escaped}["\']', body))


def probe_url(url: str, timeout: float) -> dict[str, Any]:
    clean_url, fragment = urldefrag(url)
    try:
        status_code, content_type, body = fetch(clean_url, timeout)
    except HTTPError as exc:
        return {"url": url, "status": "fail", "status_code": exc.code, "reason": "http_error"}
    except (TimeoutError, URLError) as exc:
        return {"url": url, "status": "fail", "status_code": 0, "reason": str(exc)}

    if not 200 <= status_code < 400:
        return {"url": url, "status": "fail", "status_code": status_code, "reason": "bad_status"}
    if fragment and not fragment_present(fragment, body):
        return {
            "url": url,
            "status": "fail",
            "status_code": status_code,
            "reason": "missing_fragment",
            "fragment": fragment,
        }
    return {"url": url, "status": "pass", "status_code": status_code, "content_type": content_type}


def run(site: Path, base_url: str, timeout: float) -> dict[str, Any]:
    normalized_base = canonical_base(base_url)
    urls, source_count, skipped_external = collect_urls(site, normalized_base)
    probes = [probe_url(url, timeout) for url in sorted(urls)]
    failures = [probe for probe in probes if probe["status"] != "pass"]
    return {
        "schema_version": SCHEMA_VERSION,
        "status": "pass" if source_count > 0 and not failures else "fail",
        "base_url": normalized_base,
        "source_count": source_count,
        "probe_count": len(probes),
        "pass_count": len(probes) - len(failures),
        "skipped_external_count": skipped_external,
        "failure_count": len(failures),
        "failures": failures,
        "probes": probes,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--site", default="site", help="local site directory used to discover first-party paths")
    parser.add_argument("--base-url", default="https://flywheel.zeststream.ai/", help="deployed site base URL")
    parser.add_argument("--timeout", type=float, default=8.0, help="per-request timeout seconds")
    parser.add_argument("--json", action="store_true", help="emit JSON")
    args = parser.parse_args()

    result = run(Path(args.site).resolve(), args.base_url, args.timeout)
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(
            "status={status} base_url={base_url} probe_count={probe_count} "
            "failure_count={failure_count}".format(**result)
        )
        for failure in result["failures"]:
            print(f"FAIL {failure['url']}: {failure['reason']}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
