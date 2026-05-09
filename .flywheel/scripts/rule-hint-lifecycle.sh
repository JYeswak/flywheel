#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path

SCHEMA = "rule-hint-lifecycle/v1"


@dataclass(frozen=True)
class Rule:
    rule_id: str
    title: str
    path: str


def emit(payload: dict, json_mode: bool) -> None:
    if json_mode:
        print(json.dumps(payload, sort_keys=True))
    else:
        print(f"status={payload.get('status')} action={payload.get('action')} candidates={payload.get('candidate_count', 0)}")


def parse_ts(value: object) -> datetime | None:
    if not isinstance(value, str) or not value:
        return None
    text = value.replace("Z", "+00:00")
    try:
        parsed = datetime.fromisoformat(text)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def load_rules(rules_dir: Path) -> list[Rule]:
    rules: list[Rule] = []
    for path in sorted(rules_dir.glob("L*.md")):
        text = path.read_text(encoding="utf-8", errors="replace")
        match = re.search(r"^##\s+(L[0-9]+)\s+[—-]\s+(.+?)\s*$", text, flags=re.M)
        if not match:
            match = re.search(r"(L[0-9]+)", path.name, flags=re.I)
            if not match:
                continue
            title_match = re.search(r"^title:\s*(.+)$", text, flags=re.M)
            title = title_match.group(1).strip() if title_match else path.stem
            rules.append(Rule(match.group(1).upper(), title, str(path)))
            continue
        rules.append(Rule(match.group(1).upper(), match.group(2).strip(), str(path)))
    return rules


def load_counts(usage_log: Path, cutoff: datetime) -> tuple[dict[str, int], int]:
    counts: dict[str, int] = {}
    rows_seen = 0
    if not usage_log.exists():
        return counts, rows_seen
    for line in usage_log.read_text(encoding="utf-8", errors="replace").splitlines():
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(row, dict):
            continue
        ts = parse_ts(row.get("ts"))
        if ts is None or ts < cutoff:
            continue
        rule_id = str(row.get("rule_id") or "").upper()
        if not re.fullmatch(r"L[0-9]+", rule_id):
            continue
        counts[rule_id] = counts.get(rule_id, 0) + 1
        rows_seen += 1
    return counts, rows_seen


def existing_open(repo: Path, br_bin: str, marker: str) -> str | None:
    proc = subprocess.run([br_bin, "list", "--json", "--limit", "0"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    if proc.returncode != 0:
        return None
    try:
        data = json.loads(proc.stdout or "[]")
    except json.JSONDecodeError:
        return None
    issues = data if isinstance(data, list) else data.get("issues", [])
    for issue in issues:
        if not isinstance(issue, dict) or issue.get("status") == "closed":
            continue
        title = str(issue.get("title") or "")
        if marker in title:
            return str(issue.get("id") or "")
    return None


def create_bead(repo: Path, br_bin: str, candidate: dict) -> str:
    marker = candidate["marker"]
    existing = existing_open(repo, br_bin, marker)
    if existing:
        return f"matched:{existing}"
    description = (
        "Auto-created by rule-hint-lifecycle.sh. This is a proposal bead only: "
        "Joshua approval is required before changing canonical L-rules, memory rules, "
        "or skill auto-route entries.\n\n"
        f"Rule: {candidate['rule_id']} — {candidate['title']}\n"
        f"Action: {candidate['action']}\n"
        f"Observed 30-day count: {candidate['count']}\n"
        f"Threshold: {candidate['threshold']}\n"
        f"Source shard: {candidate['path']}\n"
    )
    proc = subprocess.run(
        [br_bin, "create", candidate["title_for_bead"], "--type", "task", "--priority", str(candidate["priority"]), "--description", description, "--json"],
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or "br create failed")
    data = json.loads(proc.stdout)
    return str(data.get("id") or data.get("issue", {}).get("id") or "")


def candidates_for(rules: list[Rule], counts: dict[str, int], demote_threshold: int, promote_threshold: int) -> list[dict]:
    candidates: list[dict] = []
    for rule in rules:
        count = counts.get(rule.rule_id, 0)
        if count < demote_threshold:
            marker = f"[rule-hint-lifecycle:demote:{rule.rule_id}]"
            candidates.append({
                "action": "demote",
                "rule_id": rule.rule_id,
                "title": rule.title,
                "count": count,
                "threshold": demote_threshold,
                "path": rule.path,
                "marker": marker,
                "priority": 3,
                "title_for_bead": f"{marker} low hint usage ({count}/30d)",
            })
        elif count > promote_threshold:
            marker = f"[rule-hint-lifecycle:promote:{rule.rule_id}]"
            candidates.append({
                "action": "promote",
                "rule_id": rule.rule_id,
                "title": rule.title,
                "count": count,
                "threshold": promote_threshold,
                "path": rule.path,
                "marker": marker,
                "priority": 2,
                "title_for_bead": f"{marker} high hint usage ({count}/30d)",
            })
    return candidates


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Analyze L-rule hint usage and file Joshua-approved lifecycle proposal beads.")
    parser.add_argument("command", nargs="?", default="analyze", choices=["analyze", "doctor", "health", "schema", "examples"])
    parser.add_argument("--repo", default=os.getcwd())
    parser.add_argument("--rules-dir", default=".flywheel/rules")
    parser.add_argument("--usage-log", default=str(Path.home() / ".local/state/flywheel/rule-hint-usage.jsonl"))
    parser.add_argument("--window-days", type=int, default=30)
    parser.add_argument("--demote-threshold", type=int, default=5)
    parser.add_argument("--promote-threshold", type=int, default=50)
    parser.add_argument("--br-bin", default=os.environ.get("BR_BIN", "br"))
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)

    if args.command == "schema":
        emit({"schema_version": SCHEMA, "fields": ["rule_id", "count", "action", "marker"], "exit_codes": {"0": "ok", "1": "apply failed", "2": "usage"}}, args.json)
        return 0
    if args.command == "examples":
        emit({"schema_version": SCHEMA, "examples": ["rule-hint-lifecycle.sh --json", "rule-hint-lifecycle.sh --apply --json"]}, args.json)
        return 0

    repo = Path(args.repo).expanduser().resolve()
    rules_dir = (repo / args.rules_dir).resolve() if not Path(args.rules_dir).expanduser().is_absolute() else Path(args.rules_dir).expanduser()
    usage_log = Path(args.usage_log).expanduser()
    rules = load_rules(rules_dir)
    cutoff = datetime.now(timezone.utc) - timedelta(days=args.window_days)
    counts, rows_seen = load_counts(usage_log, cutoff)
    candidates = candidates_for(rules, counts, args.demote_threshold, args.promote_threshold)
    payload = {
        "schema_version": SCHEMA,
        "status": "ok",
        "action": "analyzed",
        "mode": "apply" if args.apply else "dry_run",
        "repo": str(repo),
        "rules_dir": str(rules_dir),
        "usage_log": str(usage_log),
        "window_days": args.window_days,
        "cutoff": cutoff.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "usage_rows_seen": rows_seen,
        "rules_count": len(rules),
        "candidate_count": len(candidates),
        "joshua_approval_required_before_lifecycle_apply": True,
        "canonical_l_rule_mutation_performed": False,
        "candidates": candidates,
        "beads": [],
    }
    if args.command in {"doctor", "health"}:
        payload["action"] = args.command
        emit(payload, args.json)
        return 0
    if args.apply:
        try:
            payload["beads"] = [create_bead(repo, args.br_bin, candidate) for candidate in candidates]
            payload["action"] = "proposal_beads_created"
        except Exception as exc:
            payload["status"] = "error"
            payload["error"] = str(exc)
            emit(payload, args.json)
            return 1
    emit(payload, args.json)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY
