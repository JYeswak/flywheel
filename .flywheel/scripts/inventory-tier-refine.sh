#!/usr/bin/env bash
# Meta-pattern Adoption stance:
# Embodies MP-76-authority-ranked-retrieval-maintenance.md and MP-70-reviewed-machine-plan-before-apply.md.
# Source: /Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/
set -euo pipefail

usage() {
  cat <<'USAGE'
usage: inventory-tier-refine.sh [--json] [--write-report] [--inventory PATH] [--output-dir DIR] [--dispatch-log PATH] [--now ISO8601]

Refines Phase 1 system inventory tiers using last-30d dispatch-log evidence,
canonical-cli presence, fixture coverage, age, class, and cross-repo reuse.

Defaults:
  --inventory    .flywheel/inventory/2026-05-19/inventory.jsonl
  --output-dir   .flywheel/inventory/2026-05-19
  --dispatch-log .flywheel/dispatch-log.jsonl

Invariant failures print a next_action field so orchestration has a bounded
repair path instead of a prose-only failure.
USAGE
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DATE_STAMP="${SYSTEM_INVENTORY_DATE:-2026-05-19}"
INVENTORY="$ROOT/.flywheel/inventory/$DATE_STAMP/inventory.jsonl"
OUTPUT_DIR="$ROOT/.flywheel/inventory/$DATE_STAMP"
DISPATCH_LOG="$ROOT/.flywheel/dispatch-log.jsonl"
NOW_ARG="${INVENTORY_TIER_REFINE_NOW:-}"
JSON_OUT=0
WRITE_REPORT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --write-report) WRITE_REPORT=1; shift ;;
    --inventory) INVENTORY="${2:?--inventory requires PATH}"; shift 2 ;;
    --inventory=*) INVENTORY="${1#*=}"; shift ;;
    --output-dir) OUTPUT_DIR="${2:?--output-dir requires DIR}"; shift 2 ;;
    --output-dir=*) OUTPUT_DIR="${1#*=}"; shift ;;
    --dispatch-log) DISPATCH_LOG="${2:?--dispatch-log requires PATH}"; shift 2 ;;
    --dispatch-log=*) DISPATCH_LOG="${1#*=}"; shift ;;
    --now) NOW_ARG="${2:?--now requires ISO8601 timestamp}"; shift 2 ;;
    --now=*) NOW_ARG="${1#*=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ "$JSON_OUT" -eq 0 && "$WRITE_REPORT" -eq 0 ]]; then
  WRITE_REPORT=1
fi

python3 - "$INVENTORY" "$OUTPUT_DIR" "$DISPATCH_LOG" "$JSON_OUT" "$WRITE_REPORT" "$NOW_ARG" <<'PY'
from __future__ import annotations

import json
import os
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path

inventory_path = Path(sys.argv[1]).expanduser()
output_dir = Path(sys.argv[2]).expanduser()
extra_dispatch_log = Path(sys.argv[3]).expanduser()
json_out = sys.argv[4] == "1"
write_report = sys.argv[5] == "1"
now_raw = sys.argv[6]

CANONICAL_PATTERNS = re.compile(
    r"(flywheel-cli-surface|canonical-cli-scoping|doctor.+health.+repair|health.+repair.+validate)",
    re.I | re.S,
)
TEST_DIR_PARTS = ("/tests/", "/.flywheel/tests/")
DEPRECATED_PATTERNS = re.compile(r"(^|/)(archive|_archive|old|deprecated)(/|$)|deprecated|\.bak\.", re.I)


def parse_now(raw: str) -> datetime:
    if not raw:
        return datetime.now(timezone.utc)
    normalized = raw[:-1] + "+00:00" if raw.endswith("Z") else raw
    parsed = datetime.fromisoformat(normalized)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


NOW = parse_now(now_raw)
CUTOFF = NOW - timedelta(days=30)


def iso_z(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_jsonl(path: Path) -> list[dict]:
    rows: list[dict] = []
    if not path.exists():
        return rows
    with path.open("r", encoding="utf-8", errors="replace") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return rows


def row_ts(row: dict) -> datetime | None:
    raw = row.get("ts") or row.get("timestamp") or row.get("created_at")
    if not isinstance(raw, str):
        return None
    try:
        normalized = raw[:-1] + "+00:00" if raw.endswith("Z") else raw
        parsed = datetime.fromisoformat(normalized)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def recent_dispatch_text(path: Path) -> str:
    rows = []
    for row in read_jsonl(path):
        ts = row_ts(row)
        if ts is not None and ts < CUTOFF:
            continue
        rows.append(json.dumps(row, sort_keys=True, separators=(",", ":")))
    return "\n".join(rows)


dispatch_cache: dict[str, tuple[str, str]] = {}
fixture_cache: dict[str, str] = {}
sample_cache: dict[str, str] = {}


def dispatch_texts(repo_path: str) -> tuple[str, str]:
    repo = Path(repo_path).expanduser()
    key = str(repo)
    if key not in dispatch_cache:
        local = repo / ".flywheel/dispatch-log.jsonl"
        local_text = ""
        extra_text = ""
        if local.exists():
            local_text = recent_dispatch_text(local)
        if extra_dispatch_log.exists() and extra_dispatch_log != local and repo == Path.cwd().resolve():
            extra_text = recent_dispatch_text(extra_dispatch_log)
        dispatch_cache[key] = (local_text, extra_text)
    return dispatch_cache[key]


def repo_fixture_corpus(repo_path: str) -> str:
    repo = Path(repo_path).expanduser()
    key = str(repo)
    if key in fixture_cache:
        return fixture_cache[key]
    parts: list[str] = []
    for rel_dir in ("tests", ".flywheel/tests"):
        tests_dir = repo / rel_dir
        if not tests_dir.exists():
            continue
        try:
            files = sorted(p for p in tests_dir.rglob("*") if p.is_file())
        except OSError:
            files = []
        for path in files:
            rel = str(path.relative_to(repo))
            parts.append(rel)
            try:
                parts.append(path.read_text(encoding="utf-8", errors="replace")[:20000])
            except OSError:
                continue
    fixture_cache[key] = "\n".join(parts)
    return fixture_cache[key]


def surface_sample(row: dict) -> str:
    repo_path = str(row.get("repo_path") or "")
    rel = str(row.get("path") or "")
    key = f"{repo_path}\0{rel}"
    if key in sample_cache:
        return sample_cache[key]
    path = Path(repo_path).expanduser() / rel
    try:
        sample_cache[key] = path.read_text(encoding="utf-8", errors="replace")[:20000]
    except OSError:
        sample_cache[key] = ""
    return sample_cache[key]


def invoke_count(row: dict) -> int:
    local_text, extra_text = dispatch_texts(str(row.get("repo_path") or ""))
    rel = str(row.get("path") or "")
    count = local_text.count(rel) + extra_text.count(rel)
    return count


def has_fixture_coverage(row: dict, canonical_cli_present: bool) -> bool:
    if canonical_cli_present or row.get("class") == "test":
        return True
    rel = str(row.get("path") or "")
    base = Path(rel).name
    corpus = repo_fixture_corpus(str(row.get("repo_path") or ""))
    if not corpus:
        return False
    return bool((rel and rel in corpus) or (base and base in corpus))


def canonical_cli_present(row: dict) -> bool:
    if bool(row.get("canonical_cli_present")):
        return True
    sample = surface_sample(row)
    if CANONICAL_PATTERNS.search(sample):
        return True
    rel = str(row.get("path") or "")
    base = Path(rel).name
    corpus = repo_fixture_corpus(str(row.get("repo_path") or ""))
    if "canonical-cli" in corpus and (rel in corpus or base in corpus):
        return True
    return False


def age_days(row: dict) -> int | None:
    raw = row.get("age_days")
    if isinstance(raw, int):
        return max(0, raw)
    repo_path = str(row.get("repo_path") or "")
    rel = str(row.get("path") or "")
    path = Path(repo_path).expanduser() / rel
    try:
        changed = datetime.fromtimestamp(path.stat().st_mtime, timezone.utc)
    except OSError:
        return None
    return max(0, (NOW - changed).days)


def deprecated(row: dict, age: int | None, invocations: int, canonical: bool) -> bool:
    rel = str(row.get("path") or "")
    if DEPRECATED_PATTERNS.search(rel):
        return True
    return bool(age is not None and age >= 30 and invocations == 0 and not canonical)


def tier_for(row: dict, invocations: int, canonical: bool, fixture: bool, age: int | None, cross_repo_consumer_count: int) -> tuple[str, list[str]]:
    klass = str(row.get("class") or "other")
    is_deprecated = deprecated(row, age, invocations, canonical)
    reasons: list[str] = []
    if invocations >= 10:
        reasons.append("invoke_count_30d>=10")
    if canonical:
        reasons.append("canonical_cli_present=true")
    if klass in {"doctor", "validator"} and cross_repo_consumer_count >= 1:
        reasons.append("doctor_or_validator_cross_repo_consumer>=1")
    if reasons:
        return "T1 fleet-critical", reasons

    if 1 <= invocations <= 9:
        reasons.append("invoke_count_30d=1..9")
    if fixture:
        reasons.append("has_fixture_coverage=true")
    if klass == "CLI":
        reasons.append("class=CLI")
    if reasons:
        return "T2 common", reasons

    if is_deprecated:
        return "T4 deprecated", ["age_days>=30 and invoke_count_30d=0 and no canonical-cli scaffold"]

    if invocations == 0 and (age is None or age < 30):
        return "T3 internal", ["invoke_count_30d=0 and age_days<30 and not deprecated"]

    return "T3 internal", ["fallback_internal"]


def markdown_report(rows: list[dict], inventory_source: Path, failures: list[str]) -> str:
    by_tier = Counter(r["tier"] for r in rows if not r.get("missing_repo"))
    by_repo_tier: dict[str, Counter] = defaultdict(Counter)
    for row in rows:
        if row.get("missing_repo"):
            continue
        by_repo_tier[str(row.get("repo"))][str(row.get("tier"))] += 1

    promotions = [
        r for r in rows
        if str(r.get("previous_tier")) == "T2 common" and str(r.get("tier")) == "T1 fleet-critical"
    ]
    demotions = [
        r for r in rows
        if str(r.get("previous_tier")) == "T1 fleet-critical" and str(r.get("tier")) == "T2 common"
    ]
    top_t1 = sorted(
        [r for r in rows if r.get("tier") == "T1 fleet-critical" and not r.get("missing_repo")],
        key=lambda r: (-int(r.get("invoke_count_30d") or 0), str(r.get("repo")), str(r.get("path"))),
    )[:20]

    status = "PASS" if not failures else "FAIL"
    next_action = "PASS: hand the Top 20 T1 queue to Phase 3; do not start Phase 3 from this phase."
    if failures:
        next_action = "FAIL: repair inventory-tier-refine inputs or fixture coverage detection, then rerun inventory-tier-refine.sh --write-report."

    lines = [
        "# Tier Refinement",
        "",
        f"Generated: {iso_z(NOW)}",
        f"Inventory source: `{inventory_source}`",
        "",
        "## Summary",
        "",
        f"- Refined surface rows: {len(rows)}",
        f"- Invariant status: {status}",
        f"- Next action: {next_action}",
        "",
        "## Refined Tier Distribution",
        "",
        "| Tier | Surfaces |",
        "|---|---:|",
    ]
    for tier in ("T1 fleet-critical", "T2 common", "T3 internal", "T4 deprecated"):
        lines.append(f"| {tier} | {by_tier.get(tier, 0)} |")
    lines.append("")

    lines.extend(["## Per-Repo Tier Breakdown", "", "| Repo | T1 | T2 | T3 | T4 |", "|---|---:|---:|---:|---:|"])
    for repo in sorted(by_repo_tier):
        counter = by_repo_tier[repo]
        lines.append(
            f"| {repo} | {counter.get('T1 fleet-critical', 0)} | {counter.get('T2 common', 0)} | "
            f"{counter.get('T3 internal', 0)} | {counter.get('T4 deprecated', 0)} |"
        )
    lines.append("")

    def transition_table(title: str, transition_rows: list[dict]) -> None:
        lines.extend([f"## {title}", "", "| Repo | Path | Class | Invoke count 30d | Reason |", "|---|---|---|---:|---|"])
        if not transition_rows:
            lines.append("| none |  |  |  |  |")
        else:
            for row in sorted(transition_rows, key=lambda r: (str(r.get("repo")), str(r.get("path")))):
                reason = "; ".join(row.get("tier_reason") or [])
                lines.append(f"| {row.get('repo')} | `{row.get('path')}` | {row.get('class')} | {row.get('invoke_count_30d')} | {reason} |")
        lines.append("")

    transition_table("T1 to T2 Demotions", demotions)
    transition_table("T2 to T1 Promotions", promotions)

    lines.extend([
        "## Top 20 T1 Surfaces Queued For Phase 3 Ergonomics Audit",
        "",
        "| Rank | Repo | Path | Class | Invoke count 30d | Reason |",
        "|---:|---|---|---|---:|---|",
    ])
    for idx, row in enumerate(top_t1, start=1):
        reason = "; ".join(row.get("tier_reason") or [])
        lines.append(f"| {idx} | {row.get('repo')} | `{row.get('path')}` | {row.get('class')} | {row.get('invoke_count_30d')} | {reason} |")
    lines.append("")
    return "\n".join(lines)


raw_rows = read_jsonl(inventory_path)
if not raw_rows:
    payload = {
        "schema_version": "system-inventory.tier-refine.error/v1",
        "status": "FAIL",
        "reason": "inventory input missing or empty",
        "inventory": str(inventory_path),
        "next_action": "Run .flywheel/scripts/system-inventory.sh --write-report, then rerun inventory-tier-refine.sh.",
    }
    print(json.dumps(payload, sort_keys=True, separators=(",", ":")), file=sys.stderr)
    sys.exit(1)

basename_repos: dict[str, set[str]] = defaultdict(set)
for row in raw_rows:
    base = Path(str(row.get("path") or "")).name
    if base:
        basename_repos[base].add(str(row.get("repo") or ""))

refined: list[dict] = []
for row in raw_rows:
    new = dict(row)
    previous_tier = str(row.get("tier") or "")
    invocations = invoke_count(row)
    canonical = canonical_cli_present(row)
    fixture = has_fixture_coverage(row, canonical)
    age = age_days(row)
    base = Path(str(row.get("path") or "")).name
    cross_repo_consumer_count = max(0, len(basename_repos.get(base, set())) - 1) if base else 0
    tier, reasons = tier_for(row, invocations, canonical, fixture, age, cross_repo_consumer_count)
    new.update({
        "schema_version": "system-inventory.surface-tier-refined/v1",
        "previous_tier": previous_tier,
        "tier": tier,
        "tier_reason": reasons,
        "tier_refined_by": "inventory-tier-refine.sh",
        "invoke_count_30d": invocations,
        "canonical_cli_present": canonical,
        "has_fixture_coverage": fixture,
        "age_days": age,
        "cross_repo_consumer_count": cross_repo_consumer_count,
        "tier_window_days": 30,
    })
    refined.append(new)

refined.sort(key=lambda r: (str(r.get("repo")), str(r.get("path"))))
failures: list[str] = []
if len(refined) != len(raw_rows):
    failures.append("refined row count differs from input row count")
if not any(r.get("tier") == "T1 fleet-critical" for r in refined):
    failures.append("no T1 surfaces after refinement")

if write_report:
    output_dir.mkdir(parents=True, exist_ok=True)
    with (output_dir / "inventory-tier-refined.jsonl").open("w", encoding="utf-8") as handle:
        for row in refined:
            handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")
    (output_dir / "TIER-REFINEMENT.md").write_text(markdown_report(refined, inventory_path, failures) + "\n", encoding="utf-8")

if json_out:
    for row in refined:
        print(json.dumps(row, sort_keys=True, separators=(",", ":")))
elif not write_report:
    print(markdown_report(refined, inventory_path, failures))

if failures:
    for failure in failures:
        print(f"FAIL: {failure}", file=sys.stderr)
    sys.exit(1)
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
