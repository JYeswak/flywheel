#!/usr/bin/env python3
import argparse
import json
import re
import subprocess
from pathlib import Path


SCHEMA_VERSION = "doctrine-mechanism-coverage/v1"


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", default="/Users/josh/Developer/flywheel")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--json", action="store_true")
    return parser.parse_args()


def schema():
    return {
        "schema_version": SCHEMA_VERSION,
        "fields": {
            "l_rules_total": "number",
            "coverage_full": "number",
            "coverage_partial": "number",
            "coverage_missing": "number",
            "doctrine_mechanism_coverage_pct": "number",
            "doctrine_memory_gap_count": "number",
            "doctrine_mechanism_gap_count": "number",
            "doctrine_dashboard_gap_count": "number",
            "doctrine_coverage_top_gaps": "array",
        },
    }


def read_text(path):
    try:
        return path.read_text()
    except FileNotFoundError:
        return ""


def l_rule_blocks(text):
    matches = list(re.finditer(r"^## (L\d+) — (.+)$", text, flags=re.MULTILINE))
    blocks = []
    for idx, match in enumerate(matches):
        start = match.start()
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(text)
        blocks.append(
            {
                "id": match.group(1),
                "title": match.group(2).strip(),
                "body": text[start:end],
            }
        )
    return blocks


def script_names(repo):
    scripts_dir = repo / ".flywheel" / "scripts"
    if not scripts_dir.is_dir():
        return []
    return [p.name for p in scripts_dir.iterdir() if p.is_file()]


def status_text():
    return read_text(Path.home() / ".claude" / "commands" / "flywheel" / "status.md")


def doctor_json(repo):
    loop = Path.home() / ".claude" / "skills" / ".flywheel" / "bin" / "flywheel-loop"
    if not loop.exists():
        return {}
    try:
        out = subprocess.run(
            [str(loop), "doctor", "--repo", str(repo), "--json"],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=20,
            env={"FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED": "1"},
        )
    except Exception:
        return {}
    try:
        return json.loads(out.stdout)
    except json.JSONDecodeError:
        return {}


def has_any(text, needles):
    lower = text.lower()
    return any(needle in lower for needle in needles)


def rule_row(rule, scripts, status, doctor):
    body = rule["body"]
    body_lower = body.lower()
    title_words = re.findall(r"[a-z0-9]+", rule["title"].lower())
    key_words = [w for w in title_words if len(w) >= 5][:4]

    memory = has_any(body, ["feedback_", "memory/", "fuckup-log", "INCIDENTS.md", "Evidence:"])
    mechanism = has_any(body, ["probe", "validator", "hook", "script", "doctor should expose", "jq -e"])
    if key_words:
        mechanism = mechanism or any(all(word in script.lower() for word in key_words[:1]) for script in scripts)

    doctor_fields = re.findall(r"`([a-zA-Z0-9_]+(?:\.[a-zA-Z0-9_\[\]]+)?)`", body)
    doctor_field_visible = any(field.split(".")[0] in doctor for field in doctor_fields)
    dashboard = has_any(body, ["/flywheel:status", "dashboard", "status line"]) or any(
        field.split(".")[0] in status for field in doctor_fields
    )

    if mechanism and doctor_field_visible:
        mechanism = True

    gaps = []
    if not memory:
        gaps.append("memory")
    if not mechanism:
        gaps.append("mechanism")
    if not dashboard:
        gaps.append("dashboard")

    if not gaps:
        coverage = "full"
    elif mechanism:
        coverage = "partial"
    else:
        coverage = "missing"

    return {
        "id": rule["id"],
        "title": rule["title"],
        "coverage": coverage,
        "memory_evidence": memory,
        "mechanism_evidence": mechanism,
        "dashboard_evidence": dashboard,
        "gaps": gaps,
    }


def main():
    args = parse_args()
    if args.schema:
        print(json.dumps(schema(), sort_keys=True))
        return

    repo = Path(args.repo).expanduser().resolve()
    rules = l_rule_blocks(read_text(repo / "AGENTS.md"))
    scripts = script_names(repo)
    status = status_text()
    doctor = doctor_json(repo)
    rows = [rule_row(rule, scripts, status, doctor) for rule in rules]

    total = len(rows)
    full = sum(1 for row in rows if row["coverage"] == "full")
    partial = sum(1 for row in rows if row["coverage"] == "partial")
    missing = total - full - partial
    memory_gap = sum(1 for row in rows if "memory" in row["gaps"])
    mechanism_gap = sum(1 for row in rows if "mechanism" in row["gaps"])
    dashboard_gap = sum(1 for row in rows if "dashboard" in row["gaps"])
    pct = round((full / total) * 100) if total else 0

    top_gaps = [
        {
            "id": row["id"],
            "title": row["title"],
            "coverage": row["coverage"],
            "gaps": row["gaps"],
        }
        for row in rows
        if row["gaps"]
    ][:10]

    print(
        json.dumps(
            {
                "schema_version": SCHEMA_VERSION,
                "status": "ok",
                "repo": str(repo),
                "l_rules_total": total,
                "coverage_full": full,
                "coverage_partial": partial,
                "coverage_missing": missing,
                "doctrine_mechanism_coverage_pct": pct,
                "doctrine_memory_gap_count": memory_gap,
                "doctrine_mechanism_gap_count": mechanism_gap,
                "doctrine_dashboard_gap_count": dashboard_gap,
                "doctrine_coverage_top_gaps": top_gaps,
            },
            sort_keys=True,
        )
    )


if __name__ == "__main__":
    main()
