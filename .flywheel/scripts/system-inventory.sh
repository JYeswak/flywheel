#!/usr/bin/env bash
# Meta-pattern Adoption stance:
# Embodies MP-55-source-of-truth-hierarchy.md and MP-76-authority-ranked-retrieval-maintenance.md.
# Source: /Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/
set -euo pipefail

usage() {
  cat <<'USAGE'
usage: system-inventory.sh [--json] [--write-report] [--output-dir DIR] [--repo NAME=PATH ...]

Inventories executable surfaces across flywheel plus consumer repos.

Defaults:
  --json          prints one JSON row per surface to stdout
  --write-report writes inventory.jsonl and SYSTEM-INVENTORY.md
  --repo         may be repeated; without --repo uses the built-in fleet list

Invariant failures are non-fatal for --json scans but are summarized with
next_action so orchestration can route the next phase.
USAGE
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DATE_STAMP="${SYSTEM_INVENTORY_DATE:-2026-05-19}"
OUTPUT_DIR="$ROOT/.flywheel/inventory/$DATE_STAMP"
JSON_OUT=0
WRITE_REPORT=0
REPOS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --write-report) WRITE_REPORT=1; shift ;;
    --output-dir) OUTPUT_DIR="${2:?--output-dir requires DIR}"; shift 2 ;;
    --output-dir=*) OUTPUT_DIR="${1#*=}"; shift ;;
    --repo) REPOS+=("${2:?--repo requires NAME=PATH}"); shift 2 ;;
    --repo=*) REPOS+=("${1#*=}"); shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ "$JSON_OUT" -eq 0 && "$WRITE_REPORT" -eq 0 ]]; then
  WRITE_REPORT=1
fi

if [[ "${#REPOS[@]}" -eq 0 ]]; then
  REPOS=(
    "flywheel=$ROOT"
    "skillos=/Users/josh/Developer/skillos"
    "alpsinsurance=/Users/josh/Developer/alpsinsurance"
    "mobile-eats=/Users/josh/Developer/mobile-eats"
    "zesttube=/Users/josh/Developer/zesttube"
    "vrtx=/Users/josh/Developer/vrtx"
    "clutterfreespaces=/Users/josh/Developer/clutterfreespaces"
    "picoz=/Users/josh/Developer/polymarket-pico-z"
    "agent-bench=/Users/josh/Developer/agent-bench"
    "frankensqlite=/Users/josh/Developer/frankensqlite"
    "ntm=/Users/josh/Developer/ntm"
  )
fi

python3 - "$OUTPUT_DIR" "$JSON_OUT" "$WRITE_REPORT" "${REPOS[@]}" <<'PY'
from __future__ import annotations

import json
import os
import re
import stat
import sys
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path

output_dir = Path(sys.argv[1]).expanduser()
json_out = sys.argv[2] == "1"
write_report = sys.argv[3] == "1"
repo_args = sys.argv[4:]

SKIP_DIRS = {
    ".git", "node_modules", ".venv", "venv", "__pycache__", ".pytest_cache",
    ".mypy_cache", ".ruff_cache", "target", "dist", "build", ".next",
    ".cache", ".tox", ".cargo", ".npm", ".pnpm-store",
}
TEXT_EXTS = {
    ".sh", ".bash", ".zsh", ".py", ".rs", ".js", ".ts", ".mjs", ".cjs",
    ".rb", ".pl", ".php", ".swift", ".go", ".fish", ".awk", ".command",
}
CLASS_PATTERNS = {
    "doctor": re.compile(r"doctor|health-check|diagnostic|probe", re.I),
    "validator": re.compile(r"validat|gate|lint|audit|check|smoke|test-", re.I),
    "hook": re.compile(r"hook|pre-commit|post-commit|pre-push|post-tool|pretool|posttool", re.I),
    "ledger-writer": re.compile(r"ledger|jsonl|append|dispatch-log|receipt|callback", re.I),
}
ARGV_PATTERNS = re.compile(
    r"(argparse|click\.|case\s+\"\$\{?1|while\s+\[\[\s+\$#|getopts|process\.argv|clap::|structopt)",
    re.I,
)
CANONICAL_PATTERNS = re.compile(r"(flywheel-cli-surface|canonical-cli-scoping|doctor.+health.+repair|health.+repair.+validate)", re.I | re.S)
T1_HINTS = re.compile(r"(dispatch|callback|append-safe|flywheel-loop|worker|ntm|agentmail|bead|br-|validate-callback|doctor|recovery)", re.I)


def now_utc() -> datetime:
    return datetime.now(timezone.utc)


def parse_repos(args: list[str]) -> list[tuple[str, Path]]:
    repos: list[tuple[str, Path]] = []
    for item in args:
        if "=" not in item:
            continue
        name, raw_path = item.split("=", 1)
        path = Path(raw_path).expanduser()
        repos.append((name, path))
    return repos


def is_probably_text(path: Path) -> bool:
    if path.suffix in TEXT_EXTS:
        return True
    try:
        with path.open("rb") as handle:
            chunk = handle.read(256)
    except OSError:
        return False
    return chunk.startswith(b"#!") or b"\0" not in chunk


def read_sample(path: Path, limit: int = 16000) -> str:
    try:
        data = path.read_bytes()[:limit]
    except OSError:
        return ""
    try:
        return data.decode("utf-8", "replace")
    except UnicodeDecodeError:
        return ""


def count_lines(path: Path) -> int:
    try:
        with path.open("rb") as handle:
            return sum(1 for _ in handle)
    except OSError:
        return 0


def language(path: Path, sample: str) -> str:
    first = sample.splitlines()[0] if sample else ""
    if "python" in first or path.suffix == ".py":
        return "python"
    if any(shell in first for shell in ("bash", "zsh", "sh")) or path.suffix in {".sh", ".bash", ".zsh"}:
        return "bash"
    if "rust" in first or path.suffix == ".rs":
        return "rust"
    return "other"


def classify(path: Path, rel: str, sample: str) -> str:
    base = path.name
    rel_l = rel.lower()
    if "/tests/" in f"/{rel_l}" or base.startswith("test_") or base.endswith("_test.py") or base.endswith("-test.sh"):
        return "test"
    if CLASS_PATTERNS["hook"].search(rel) or ".git/hooks/" in rel_l:
        return "hook"
    if CLASS_PATTERNS["doctor"].search(base):
        return "doctor"
    if CLASS_PATTERNS["validator"].search(base):
        return "validator"
    if CLASS_PATTERNS["ledger-writer"].search(base) or re.search(r"(>>|append-safe-write|dispatch-log\.jsonl|jsonl)", sample):
        return "ledger-writer"
    if ARGV_PATTERNS.search(sample):
        return "CLI"
    return "other"


def file_age_days(path: Path) -> int | None:
    try:
        changed = datetime.fromtimestamp(path.stat().st_mtime, timezone.utc)
    except OSError:
        return None
    return max(0, (now_utc() - changed).days)


def dispatch_text(repo: Path) -> str:
    rows: list[str] = []
    path = repo / ".flywheel/dispatch-log.jsonl"
    if not path.exists():
        return ""
    cutoff = now_utc() - timedelta(days=30)
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError:
        return ""
    for line in lines:
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        ts = row.get("ts") or row.get("timestamp") or row.get("created_at")
        if isinstance(ts, str) and ts.endswith("Z"):
            try:
                dt = datetime.fromisoformat(ts[:-1] + "+00:00")
                if dt < cutoff:
                    continue
            except ValueError:
                pass
        rows.append(json.dumps(row, sort_keys=True))
    return "\n".join(rows)


def invoke_count(rel: str, recent_dispatch_text: str) -> int:
    if not recent_dispatch_text:
        return 0
    base = Path(rel).name
    return recent_dispatch_text.count(rel) + (0 if base == rel else recent_dispatch_text.count(base))


def canonical_mentions(repo: Path) -> set[str]:
    mentions: set[str] = set()
    for tests_dir in (repo / "tests", repo / ".flywheel/tests"):
        if not tests_dir.exists():
            continue
        try:
            for p in tests_dir.rglob("*canonical-cli*"):
                if not p.is_file():
                    continue
                sample = read_sample(p, 12000)
                for match in re.finditer(r'([A-Za-z0-9_.-]+\.(?:sh|py|rs|js|ts))', sample):
                    mentions.add(match.group(1))
        except OSError:
            continue
    return mentions


def tier_for(rel: str, klass: str, invocations: int, canonical: bool, age_days: int | None) -> str:
    rel_l = rel.lower()
    if any(part in rel_l for part in ("/archive/", "/_archive/", "deprecated", ".bak.", "/old/")):
        return "T4 deprecated"
    if invocations >= 5 or (canonical and klass in {"CLI", "doctor", "validator", "hook", "ledger-writer"}) or (
        T1_HINTS.search(rel) and klass in {"CLI", "doctor", "validator", "hook", "ledger-writer"}
    ):
        return "T1 fleet-critical"
    if invocations > 0 or canonical or klass in {"CLI", "doctor", "validator"}:
        return "T2 common"
    if age_days is not None and age_days > 365:
        return "T4 deprecated"
    return "T3 internal"


def walk_surfaces(repo_name: str, repo: Path) -> list[dict]:
    recent_dispatch_text = dispatch_text(repo)
    canonical_name_mentions = canonical_mentions(repo)
    surfaces: list[dict] = []
    if not repo.exists():
        return [{
            "schema_version": "system-inventory.surface/v1",
            "repo": repo_name,
            "repo_path": str(repo),
            "path": "",
            "class": "other",
            "language": "other",
            "lines": 0,
            "exec_bit": False,
            "tier": "T4 deprecated",
            "invoke_count_30d": 0,
            "canonical_cli_present": False,
            "age_days": None,
            "missing_repo": True,
        }]
    for dirpath, dirnames, filenames in os.walk(repo):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS and not d.endswith(".egg-info")]
        root = Path(dirpath)
        for filename in filenames:
            path = root / filename
            try:
                st = path.stat()
            except OSError:
                continue
            exec_bit = bool(st.st_mode & (stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH))
            if not exec_bit:
                continue
            if not is_probably_text(path):
                continue
            rel = str(path.relative_to(repo))
            sample = read_sample(path)
            klass = classify(path, rel, sample)
            lang = language(path, sample)
            invocations = invoke_count(rel, recent_dispatch_text)
            canonical = bool(CANONICAL_PATTERNS.search(sample)) or path.name in canonical_name_mentions
            age = file_age_days(path)
            surfaces.append({
                "schema_version": "system-inventory.surface/v1",
                "repo": repo_name,
                "repo_path": str(repo),
                "path": rel,
                "class": klass,
                "language": lang,
                "lines": count_lines(path),
                "exec_bit": exec_bit,
                "tier": tier_for(rel, klass, invocations, canonical, age),
                "invoke_count_30d": invocations,
                "canonical_cli_present": canonical,
                "age_days": age,
                "missing_repo": False,
            })
    return sorted(surfaces, key=lambda r: (r["repo"], r["path"]))


def markdown_report(rows: list[dict], repos: list[tuple[str, Path]]) -> str:
    total = len([r for r in rows if not r.get("missing_repo")])
    by_repo = Counter(r["repo"] for r in rows if not r.get("missing_repo"))
    by_class = Counter(r["class"] for r in rows if not r.get("missing_repo"))
    by_tier = Counter(r["tier"] for r in rows if not r.get("missing_repo"))
    missing = [r for r in rows if r.get("missing_repo")]
    failures = []
    if by_repo.get("flywheel", 0) < 489:
        failures.append("flywheel surface count below 489")
    for name, _ in repos:
        if by_repo.get(name, 0) <= 0:
            failures.append(f"{name} has no surface rows")
    next_action = "PASS: queue Phase 2 tier distribution refinement, then Phase 3 top-T1 ergonomics audit."
    if failures:
        next_action = "FAIL: repair repo path list or scan heuristics, then rerun system-inventory.sh --write-report."
    top = sorted(
        [r for r in rows if r.get("tier") == "T1 fleet-critical" and not r.get("missing_repo")],
        key=lambda r: (-int(r.get("invoke_count_30d") or 0), r["repo"], r["path"]),
    )[:20]

    lines = [
        "# System Surface Inventory",
        "",
        f"Generated: {now_utc().strftime('%Y-%m-%dT%H:%M:%SZ')}",
        "",
        "## Summary",
        "",
        f"- Total executable surfaces: {total}",
        f"- Flywheel executable surfaces: {by_repo.get('flywheel', 0)}",
        f"- Consumer repos covered: {sum(1 for name, _ in repos if name != 'flywheel' and by_repo.get(name, 0) > 0)}/10",
        f"- Invariant status: {'PASS' if not failures else 'FAIL'}",
        f"- Next action: {next_action}",
        "",
    ]
    if failures:
        lines.extend(["## Invariant Failures", ""])
        lines.extend(f"- {failure}" for failure in failures)
        lines.append("")
    if missing:
        lines.extend(["## Missing Repos", ""])
        lines.extend(f"- {r['repo']}: {r['repo_path']}" for r in missing)
        lines.append("")
    def table(counter: Counter, title: str, headers: tuple[str, str]) -> None:
        lines.extend([f"## {title}", "", f"| {headers[0]} | {headers[1]} |", "|---|---:|"])
        for key, value in sorted(counter.items()):
            lines.append(f"| {key} | {value} |")
        lines.append("")
    table(by_repo, "Per-Repo Breakdown", ("Repo", "Surfaces"))
    table(by_class, "Per-Class Breakdown", ("Class", "Surfaces"))
    table(by_tier, "Per-Tier Breakdown", ("Tier", "Surfaces"))
    lines.extend(["## Top 20 T1 Surfaces Queued For Phase 3 Audit", "", "| Rank | Repo | Path | Class | Invoke count 30d | Lines |", "|---:|---|---|---|---:|---:|"])
    for idx, row in enumerate(top, start=1):
        lines.append(f"| {idx} | {row['repo']} | `{row['path']}` | {row['class']} | {row['invoke_count_30d']} | {row['lines']} |")
    lines.append("")
    return "\n".join(lines)


repos = parse_repos(repo_args)
all_rows: list[dict] = []
for repo_name, repo_path in repos:
    all_rows.extend(walk_surfaces(repo_name, repo_path))

if write_report:
    output_dir.mkdir(parents=True, exist_ok=True)
    inv_path = output_dir / "inventory.jsonl"
    with inv_path.open("w", encoding="utf-8") as handle:
        for row in all_rows:
            handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")
    (output_dir / "SYSTEM-INVENTORY.md").write_text(markdown_report(all_rows, repos) + "\n", encoding="utf-8")

if json_out:
    try:
        for row in all_rows:
            print(json.dumps(row, sort_keys=True, separators=(",", ":")))
    except BrokenPipeError:
        try:
            sys.stdout.close()
        except OSError:
            pass
else:
    print(markdown_report(all_rows, repos))
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
