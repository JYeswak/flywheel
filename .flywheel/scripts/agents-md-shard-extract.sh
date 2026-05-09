#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path


BEGIN = "<!-- BEGIN-CANONICAL-FLYWHEEL-DOCTRINE -->"
END = "<!-- END-CANONICAL-FLYWHEEL-DOCTRINE -->"
INDEX_BEGIN = "<!-- BEGIN-RULES-INDEX -->"
INDEX_END = "<!-- END-RULES-INDEX -->"
RULE_RE = re.compile(r"(?m)^## (L\d+)(?:\s+—\s+|\s+)(.+)$")
REQUIRED_FRONTMATTER = {"id", "title", "status", "shipped", "trauma_class"}
FRONTMATTER_BACKFILL = {
    "L60": ("Loop integrity 5 signal contract", "2026-05-03", "loop-integrity-liveness"),
    "L61": ("Doctrine landing wires into AGENTS and README", "2026-05-03", "doctrine-orphaning"),
    "L62": ("STATE.md is latent opportunity substrate", "2026-05-03", "latent-state-amnesia"),
    "L63": ("Jeff intel network is canonical substrate dependency", "2026-05-03", "jeff-intel-substrate-drift"),
    "L64": ("Jeff is mentor not just dependency", "2026-05-03", "jeff-mentor-bypass"),
    "L65": ("CLI identity beats command name", "2026-05-03", "cli-identity-drift"),
    "L66": ("Outbound Jeff issues use phased command gate", "2026-05-03", "jeff-issue-gate-bypass"),
    "L67": ("Truth source must be live not cached", "2026-05-03", "cached-truth-drift"),
    "L125": ("Env file is sealed substrate", "2026-05-07", "read-tool-secret-leak"),
}


@dataclass(frozen=True)
class Rule:
    order: int
    rule_id: str
    title: str
    body: str
    filename: str
    status: str | None
    shipped: str | None
    trauma_class: str | None


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode()).hexdigest()


def slug(value: str) -> str:
    lowered = value.lower()
    lowered = re.sub(r"[^a-z0-9]+", "-", lowered).strip("-")
    return lowered[:70] or "untitled"


def split_frontmatter(body: str) -> dict[str, str]:
    lines = body.splitlines()
    try:
        first = lines.index("---")
        second = lines.index("---", first + 1)
    except ValueError:
        return {}
    parsed: dict[str, str] = {}
    for line in lines[first + 1 : second]:
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        parsed[key.strip()] = value.strip()
    return parsed


def ensure_frontmatter(rule_id: str, title: str, body: str) -> str:
    frontmatter = split_frontmatter(body)
    if REQUIRED_FRONTMATTER <= set(frontmatter) and frontmatter.get("id") == rule_id:
        return body
    fallback_title, shipped, trauma_class = FRONTMATTER_BACKFILL.get(
        rule_id, (title.title(), "2026-05-09", slug(title))
    )
    lines = body.splitlines(keepends=True)
    if not lines:
        return body
    block = [
        "\n",
        "---\n",
        f"id: {rule_id}\n",
        f"title: {fallback_title}\n",
        "status: long_term\n",
        f"shipped: {shipped}\n",
        "review_due: 2026-11-09\n",
        f"trauma_class: {trauma_class}\n",
        "---\n",
        "\n",
    ]
    return "".join([lines[0], *block, *lines[1:]])


def parse_rules(text: str) -> tuple[str, list[Rule], str]:
    matches = list(RULE_RE.finditer(text))
    if not matches:
        return leading_text(text), [], ""
    rules: list[Rule] = []
    for idx, match in enumerate(matches):
        start = match.start()
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(text)
        body = text[start:end]
        rule_id = match.group(1)
        title = match.group(2).strip()
        body = ensure_frontmatter(rule_id, title, body)
        frontmatter = split_frontmatter(body)
        filename = f"L{idx + 1:03d}-{rule_id}-{slug(title)}.md"
        rules.append(
            Rule(
                order=idx + 1,
                rule_id=rule_id,
                title=title,
                body=body,
                filename=filename,
                status=frontmatter.get("status"),
                shipped=frontmatter.get("shipped"),
                trauma_class=frontmatter.get("trauma_class"),
            )
        )
    return text[: matches[0].start()], rules, text[matches[0].start() :]


def leading_text(text: str) -> str:
    if BEGIN in text:
        return text.split(BEGIN, 1)[0]
    return text


def load_existing_rules(rules_dir: Path) -> list[Rule]:
    paths = sorted(rules_dir.glob("L*.md"))
    rules: list[Rule] = []
    for idx, path in enumerate(paths, 1):
        body = path.read_text()
        match = RULE_RE.search(body)
        if not match:
            raise SystemExit(f"ERR: shard missing L-rule heading: {path}")
        frontmatter = split_frontmatter(body)
        rules.append(
            Rule(
                order=idx,
                rule_id=match.group(1),
                title=match.group(2).strip(),
                body=body,
                filename=path.name,
                status=frontmatter.get("status"),
                shipped=frontmatter.get("shipped"),
                trauma_class=frontmatter.get("trauma_class"),
            )
        )
    return rules


def validate_rules(rules: list[Rule]) -> list[dict[str, str]]:
    errors: list[dict[str, str]] = []
    seen: set[str] = set()
    for rule in rules:
        frontmatter = split_frontmatter(rule.body)
        missing = sorted(REQUIRED_FRONTMATTER - set(frontmatter))
        if missing:
            errors.append(
                {"rule": rule.rule_id, "file": rule.filename, "error": f"missing_frontmatter:{','.join(missing)}"}
            )
        if frontmatter.get("id") != rule.rule_id:
            errors.append({"rule": rule.rule_id, "file": rule.filename, "error": "frontmatter_id_mismatch"})
        if rule.rule_id in seen:
            errors.append({"rule": rule.rule_id, "file": rule.filename, "error": "duplicate_rule_id"})
        seen.add(rule.rule_id)
    return errors


def render_index(leading: str, rules: list[Rule], manifest_name: str) -> str:
    prefix = re.sub(r"(\n## Rules\s*)+\Z", "\n## Rules", leading.rstrip())
    lines = [prefix, ""]
    if not re.search(r"(?m)^## Rules\s*$", prefix):
        lines.extend(["## Rules", ""])
    lines.extend([
        BEGIN,
        "",
        "The full canonical L-rule bodies are sharded under `.flywheel/rules/`.",
        f"`{manifest_name}` records the exact round-trip hash for `cat .flywheel/rules/L*.md`.",
        "",
        INDEX_BEGIN,
        "| Order | Rule | Status | Shard |",
        "|---:|---|---|---|",
    ])
    for rule in rules:
        status = rule.status or ""
        lines.append(f"| {rule.order} | {rule.rule_id} — {rule.title} | {status} | `.flywheel/rules/{rule.filename}` |")
    lines.extend([INDEX_END, "", END, ""])
    return "\n".join(lines)


def render_manifest(rules: list[Rule], source_path: Path, canonical_path: Path, rules_body: str) -> str:
    payload = {
        "schema_version": "agents-canonical-shards/v1",
        "source": str(source_path),
        "canonical_index": str(canonical_path),
        "rule_count": len(rules),
        "round_trip_command": "cat .flywheel/rules/L*.md | shasum -a 256",
        "rules_body_sha256": sha256_text(rules_body),
        "rules": [
            {
                "order": rule.order,
                "id": rule.rule_id,
                "title": rule.title,
                "status": rule.status,
                "shipped": rule.shipped,
                "trauma_class": rule.trauma_class,
                "path": f".flywheel/rules/{rule.filename}",
                "sha256": sha256_text(rule.body),
            }
            for rule in rules
        ],
    }
    return json.dumps(payload, indent=2, sort_keys=True) + "\n"


def write_if_changed(path: Path, content: str, dry_run: bool, writes: list[str], drifts: list[str]) -> None:
    old = path.read_text() if path.exists() else None
    if old == content:
        return
    drifts.append(str(path))
    if dry_run:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
    writes.append(str(path))


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Shard canonical AGENTS L-rules into per-rule files.")
    parser.add_argument("--source", default="AGENTS.md")
    parser.add_argument("--canonical", default=".flywheel/AGENTS-CANONICAL.md")
    parser.add_argument("--root", default="AGENTS.md")
    parser.add_argument("--template", default="templates/flywheel-install/AGENTS.md")
    parser.add_argument("--rules-dir", default=".flywheel/rules")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)

    dry_run = not args.apply
    source_path = Path(args.source)
    canonical_path = Path(args.canonical)
    rules_dir = Path(args.rules_dir)
    source_text = source_path.read_text()
    leading, rules, rules_body = parse_rules(source_text)
    if not rules:
        rules = load_existing_rules(rules_dir)
        rules_body = "".join(rule.body for rule in rules)
    errors = validate_rules(rules)
    if errors:
        payload = {"status": "error", "errors": errors, "rule_count": len(rules)}
        print(json.dumps(payload, sort_keys=True) if args.json else payload)
        return 2

    manifest_name = "MANIFEST.json"
    index = render_index(leading, rules, manifest_name)
    manifest = render_manifest(rules, source_path, canonical_path, rules_body)
    writes: list[str] = []
    drifts: list[str] = []

    if not dry_run:
        rules_dir.mkdir(parents=True, exist_ok=True)
        for old in rules_dir.glob("L*.md"):
            old.unlink()
    for rule in rules:
        write_if_changed(rules_dir / rule.filename, rule.body, dry_run, writes, drifts)
    write_if_changed(rules_dir / manifest_name, manifest, dry_run, writes, drifts)
    for target in [canonical_path, Path(args.root), Path(args.template)]:
        write_if_changed(target, index, dry_run, writes, drifts)

    payload = {
        "status": "drifted" if dry_run and drifts else "in_sync",
        "mode": "dry_run" if dry_run else "apply",
        "rule_count": len(rules),
        "drifted_count": len(drifts),
        "written_count": len(writes),
        "rules_body_sha256": sha256_text(rules_body),
        "targets": [str(canonical_path), args.root, args.template, str(rules_dir)],
        "drifts": drifts,
        "writes": writes,
    }
    print(json.dumps(payload, sort_keys=True) if args.json else f"status={payload['status']} rule_count={len(rules)} drifted={len(drifts)} written={len(writes)}")
    return 1 if dry_run and drifts else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY
