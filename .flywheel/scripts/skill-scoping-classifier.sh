#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
import argparse
import json
import math
import os
import re
import sqlite3
import sys
from pathlib import Path

SCHEMA = "skill-scoping-classification/v1"
TRIGGER_KEYS = {
    "triggers",
    "trigger_keywords",
    "trigger-keywords",
    "keywords",
    "activation",
    "activation_keywords",
    "use_when",
    "when_to_use",
}
PATH_KEYS = {
    "applies_to",
    "applies-to",
    "path_scope",
    "path-scope",
    "scope_paths",
    "paths",
    "include_paths",
    "file_patterns",
    "globs",
    "repos",
    "repositories",
    "directories",
}


def split_frontmatter(text):
    if not text.startswith("---\n"):
        return "", text
    end = text.find("\n---", 4)
    if end == -1:
        return "", text
    return text[4:end], text[end + 4 :]


def frontmatter_keys(fm):
    keys = set()
    for line in fm.splitlines():
        match = re.match(r"^([A-Za-z0-9_-]+)\s*:", line)
        if match:
            keys.add(match.group(1).strip().lower())
    return keys


def field_value(fm, key):
    lines = fm.splitlines()
    out = []
    capture = False
    indent = None
    for line in lines:
        match = re.match(rf"^({re.escape(key)})\s*:\s*(.*)$", line, flags=re.I)
        if match:
            capture = True
            value = match.group(2).strip().strip("'\"")
            if value and value not in {">", ">-", "|", "|-"}:
                out.append(value)
            indent = None
            continue
        if capture:
            if not line.strip():
                continue
            leading = len(line) - len(line.lstrip(" "))
            if indent is None:
                indent = leading
            if leading == 0 and re.match(r"^[A-Za-z0-9_-]+\s*:", line):
                break
            out.append(line.strip().lstrip("- ").strip("'\""))
    return " ".join(part for part in out if part)


def first_heading(body):
    for line in body.splitlines():
        if line.startswith("# "):
            return line[2:].strip()
    return ""


def has_trigger_signal(keys, fm, body, description):
    haystack = "\n".join([fm, body, description])
    if keys & TRIGGER_KEYS:
        return True
    return bool(re.search(r"(trigger|keywords|when to use|use when|must use|automatically|invoke|activation)", haystack, re.I))


def has_path_signal(keys, fm, body):
    if keys & PATH_KEYS:
        return True
    return bool(
        re.search(
            r"(applies_to|path-scop|file pattern|directories|directory|paths?:|scope.*path|only.*repo|only.*project)",
            fm + "\n" + body,
            re.I,
        )
    )


def usage_maps(db_path):
    outcomes = {}
    loads = {}
    if not db_path or not Path(db_path).exists():
        return outcomes, loads
    con = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
    try:
        for skill, count in con.execute("select skill, count(*) from outcomes group by skill"):
            outcomes[str(skill)] = int(count)
        for skill, count in con.execute(
            "select skill, count(*) from events where skill is not null and kind in ('session_start.inject','yuzu.skill_load') group by skill"
        ):
            loads[str(skill)] = int(count)
    finally:
        con.close()
    return outcomes, loads


def classify(path, root, outcomes, loads):
    text = path.read_text(encoding="utf-8", errors="replace")
    fm, body = split_frontmatter(text)
    keys = frontmatter_keys(fm)
    description = field_value(fm, "description")
    if not description:
        description = ""
    trigger = has_trigger_signal(keys, fm, body, description)
    path_scope = has_path_signal(keys, fm, body)
    description_present = bool(description.strip())
    if trigger and path_scope:
        classification = "TIGHT"
    elif trigger or path_scope:
        classification = "MEDIUM"
    else:
        classification = "BROAD"
    reasons = []
    if description_present:
        reasons.append("description-present")
    else:
        reasons.append("missing-description")
    reasons.append("explicit-trigger-keywords" if trigger else "missing-trigger-keywords")
    reasons.append("path-scope-present" if path_scope else "missing-path-scope")
    rel = path.relative_to(root).as_posix()
    skill = rel[:-len("/SKILL.md")] if rel.endswith("/SKILL.md") else rel
    outcome_count = outcomes.get(skill, 0)
    load_count = loads.get(skill, 0)
    desc_chars = len(description)
    return {
        "schema_version": SCHEMA,
        "skill": skill,
        "path": str(path),
        "relative_path": rel,
        "classification": classification,
        "description_present": description_present,
        "trigger_keywords_present": trigger,
        "path_scope_present": path_scope,
        "frontmatter_keys": sorted(keys),
        "reasons": reasons,
        "description": description,
        "heading": first_heading(body),
        "description_chars": desc_chars,
        "estimated_description_tokens": int(math.ceil(desc_chars / 4)) if desc_chars else 0,
        "usage": {
            "outcome_count": outcome_count,
            "load_count": load_count,
            "traffic_score": outcome_count + (10 * load_count),
        },
    }


def discover(root):
    return sorted(p for p in root.rglob("SKILL.md") if p.is_file())


def main():
    parser = argparse.ArgumentParser(description="Classify Claude skills by trigger and path-scoping precision.")
    parser.add_argument("--skills-root", default=os.environ.get("SKILL_SCOPING_ROOT", "/Users/josh/.claude/skills"))
    parser.add_argument("--flywheel-db", default=os.environ.get("SKILL_SCOPING_DB", "/Users/josh/.claude/skills/.flywheel/state.db"))
    parser.add_argument("--output", help="write JSONL to this path instead of stdout")
    parser.add_argument("--summary", action="store_true", help="emit summary JSON to stderr")
    args = parser.parse_args()

    root = Path(args.skills_root).expanduser().resolve()
    outcomes, loads = usage_maps(args.flywheel_db)
    rows = [classify(path, root, outcomes, loads) for path in discover(root)]
    out = "\n".join(json.dumps(row, sort_keys=True, separators=(",", ":")) for row in rows) + ("\n" if rows else "")
    if args.output:
        output = Path(args.output)
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(out, encoding="utf-8")
    else:
        sys.stdout.write(out)
    if args.summary:
        counts = {"TIGHT": 0, "MEDIUM": 0, "BROAD": 0}
        for row in rows:
            counts[row["classification"]] += 1
        summary = {
            "schema_version": "skill-scoping-classifier-summary/v1",
            "skills_root": str(root),
            "total": len(rows),
            "counts": counts,
            "non_tight": counts["MEDIUM"] + counts["BROAD"],
            "avg_description_chars_non_tight": round(
                sum(row["description_chars"] for row in rows if row["classification"] != "TIGHT")
                / max(1, counts["MEDIUM"] + counts["BROAD"]),
                2,
            ),
            "projected_saved_tokens_per_session_if_non_tight_scoped": sum(
                row["estimated_description_tokens"] for row in rows if row["classification"] != "TIGHT"
            ),
        }
        print(json.dumps(summary, sort_keys=True), file=sys.stderr)


if __name__ == "__main__":
    raise SystemExit(main())
PY
