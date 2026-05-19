#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
usage: inventory-rebuild-diff.sh --baseline FILE --rebuild FILE --output FILE [--json]

Compares two system-inventory JSONL snapshots and writes REBUILD-DIFF.md.

Reports:
  - added surfaces
  - removed surfaces
  - orphaned surfaces by heuristic:
      age_days >= 7, invoke_count_30d = 0, and no inbound references

The orphan check is report-only; it never deletes files.
USAGE
}

BASELINE=""
REBUILD=""
OUTPUT=""
JSON_OUT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --baseline) BASELINE="${2:?--baseline requires FILE}"; shift 2 ;;
    --baseline=*) BASELINE="${1#*=}"; shift ;;
    --rebuild) REBUILD="${2:?--rebuild requires FILE}"; shift 2 ;;
    --rebuild=*) REBUILD="${1#*=}"; shift ;;
    --output) OUTPUT="${2:?--output requires FILE}"; shift 2 ;;
    --output=*) OUTPUT="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$BASELINE" && -n "$REBUILD" && -n "$OUTPUT" ]] || {
  usage >&2
  exit 2
}

python3 - "$BASELINE" "$REBUILD" "$OUTPUT" "$JSON_OUT" <<'PY'
from __future__ import annotations

import json
import os
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

baseline_path = Path(sys.argv[1])
rebuild_path = Path(sys.argv[2])
output_path = Path(sys.argv[3])
json_out = sys.argv[4] == "1"

SCAN_DIRS = {"bin", "scripts", "tests", "test", "docs", "doc", ".github", ".flywheel"}
SCAN_SUFFIXES = {
    ".sh", ".bash", ".zsh", ".py", ".rs", ".js", ".ts", ".mjs", ".cjs",
    ".md", ".json", ".jsonl", ".toml", ".yaml", ".yml", ".txt",
}
SKIP_PARTS = {
    ".git", "node_modules", "target", "dist", "build", ".next", ".venv",
    "venv", "__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache",
    "inventory", "audits",
}


def load_jsonl(path: Path) -> list[dict]:
    rows: list[dict] = []
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            if line.strip():
                rows.append(json.loads(line))
    return rows


def key(row: dict) -> tuple[str, str]:
    return (str(row.get("repo", "")), str(row.get("path", "")))


def is_scan_file(path: Path, repo_root: Path) -> bool:
    try:
        rel = path.relative_to(repo_root)
    except ValueError:
        return False
    parts = set(rel.parts)
    if parts & SKIP_PARTS:
        return False
    if path.suffix not in SCAN_SUFFIXES:
        return False
    if rel.parts and rel.parts[0] in SCAN_DIRS:
        return True
    if rel.name in {"AGENTS.md", "README.md", "CLAUDE.md", "DISCREPANCIES.md", "META-PATTERN-ADOPTION.md"}:
        return True
    if len(rel.parts) >= 2 and rel.parts[0] == ".flywheel" and rel.parts[1] in {"dispatch-log.jsonl", "doctrine", "rules", "scripts", "tests"}:
        return True
    return False


def repo_corpus(repo_root: Path, excluded_rel_paths: set[str]) -> str:
    if not repo_root.exists():
        return ""
    chunks: list[str] = []
    for root, dirs, files in os.walk(repo_root):
        dirs[:] = [d for d in dirs if d not in SKIP_PARTS]
        root_path = Path(root)
        for name in files:
            path = root_path / name
            try:
                rel = path.relative_to(repo_root).as_posix()
            except ValueError:
                continue
            if rel in excluded_rel_paths or not is_scan_file(path, repo_root):
                continue
            try:
                if path.stat().st_size > 2_000_000:
                    continue
                chunks.append(path.read_text(encoding="utf-8", errors="ignore"))
            except OSError:
                continue
    return "\n".join(chunks)


def has_inbound(row: dict, corpus_by_repo: dict[str, str]) -> bool:
    repo = str(row.get("repo", ""))
    path = str(row.get("path", ""))
    corpus = corpus_by_repo.get(repo, "")
    if not corpus:
        return False
    basename = Path(path).name
    return path in corpus or (basename and basename in corpus)


def row_line(row: dict) -> str:
    return f"| {row.get('repo')} | `{row.get('path')}` | {row.get('class')} | {row.get('invoke_count_30d', 0)} | {row.get('age_days', '')} |"


baseline_rows = load_jsonl(baseline_path)
rebuild_rows = load_jsonl(rebuild_path)
baseline = {key(row): row for row in baseline_rows}
rebuild = {key(row): row for row in rebuild_rows}

added_keys = sorted(set(rebuild) - set(baseline))
removed_keys = sorted(set(baseline) - set(rebuild))
added = [rebuild[item] for item in added_keys]
removed = [baseline[item] for item in removed_keys]

repo_paths: dict[str, Path] = {}
excluded_by_repo: dict[str, set[str]] = defaultdict(set)
for row in rebuild_rows:
    repo = str(row.get("repo", ""))
    repo_path = row.get("repo_path")
    if repo and repo_path and repo not in repo_paths:
        repo_paths[repo] = Path(str(repo_path))
    if repo and row.get("path"):
        excluded_by_repo[repo].add(str(row["path"]))

corpus_by_repo = {
    repo: repo_corpus(path, excluded_by_repo.get(repo, set()))
    for repo, path in repo_paths.items()
}

def is_orphan_candidate(row: dict) -> bool:
    return (
        int(row.get("age_days") or 0) >= 7
        and int(row.get("invoke_count_30d") or 0) == 0
        and not has_inbound(row, corpus_by_repo)
    )


legacy_orphan_candidates = [
    row for row in rebuild_rows
    if is_orphan_candidate(row)
]
legacy_orphan_candidates.sort(key=lambda row: (str(row.get("repo", "")), str(row.get("path", ""))))

orphaned = [
    row for row in added
    if int(row.get("age_days") or 0) >= 7
    and int(row.get("invoke_count_30d") or 0) == 0
    and not has_inbound(row, corpus_by_repo)
]
orphaned.sort(key=lambda row: (str(row.get("repo", "")), str(row.get("path", ""))))

repo_counts = Counter(str(row.get("repo", "")) for row in rebuild_rows)
class_counts = Counter(str(row.get("class", "")) for row in rebuild_rows)
generated = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
status = "PASS" if len(orphaned) == 0 else "WARN"
next_action = (
    "PASS: close Substrate Quality Program umbrella; no orphaned surfaces detected."
    if status == "PASS"
    else "WARN: review orphan candidates; false positives expected, no deletes performed."
)

lines = [
    "# Inventory Rebuild Diff",
    "",
    f"Generated: {generated}",
    "",
    "## Summary",
    "",
    f"- Baseline rows: {len(baseline_rows)}",
    f"- Rebuild rows: {len(rebuild_rows)}",
    f"- Repos covered: {len(repo_counts)}",
    f"- new_surfaces_count: {len(added)}",
    f"- removed_surfaces_count: {len(removed)}",
    f"- orphaned_surface_count: {len(orphaned)}",
    f"- legacy_orphan_candidates_count: {len(legacy_orphan_candidates)}",
    f"- Status: {status}",
    f"- Next action: {next_action}",
    "",
    "## Rebuild Per-Repo Breakdown",
    "",
    "| Repo | Surfaces |",
    "|---|---:|",
]
for repo, count in sorted(repo_counts.items()):
    lines.append(f"| {repo} | {count} |")

lines.extend(["", "## Rebuild Per-Class Breakdown", "", "| Class | Surfaces |", "|---|---:|"])
for klass, count in sorted(class_counts.items()):
    lines.append(f"| {klass} | {count} |")

lines.extend(["", "## Added Surfaces", "", "| Repo | Path | Class | Invoke count 30d | Age days |", "|---|---|---|---:|---:|"])
if added:
    lines.extend(row_line(row) for row in added[:200])
    if len(added) > 200:
        lines.append(f"| ... | {len(added) - 200} additional rows omitted from markdown; see inventory-rebuild.jsonl | ... | ... | ... |")
else:
    lines.append("| none | none | none | 0 | 0 |")

lines.extend(["", "## Removed Surfaces", "", "| Repo | Path | Class | Invoke count 30d | Age days |", "|---|---|---|---:|---:|"])
if removed:
    lines.extend(row_line(row) for row in removed[:200])
    if len(removed) > 200:
        lines.append(f"| ... | {len(removed) - 200} additional rows omitted from markdown; see baseline inventory | ... | ... | ... |")
else:
    lines.append("| none | none | none | 0 | 0 |")

lines.extend(["", "## Orphaned Surfaces", "", "Scope: added surfaces in the rebuild diff.", "", "Heuristic: age_days >= 7, invoke_count_30d = 0, and no inbound references in tracked code/docs/tests/dispatch-log scan.", "", "| Repo | Path | Class | Invoke count 30d | Age days |", "|---|---|---|---:|---:|"])
if orphaned:
    lines.extend(row_line(row) for row in orphaned[:200])
    if len(orphaned) > 200:
        lines.append(f"| ... | {len(orphaned) - 200} additional candidates omitted from markdown; inspect JSON summary output | ... | ... | ... |")
else:
    lines.append("| none | none | none | 0 | 0 |")

lines.extend(["", "## Legacy Orphan Candidates", "", "These candidates come from the full rebuild row set, not just surfaces added during the Substrate Quality Program window. They are reported separately because Phase 5 closes the program-window orphan check; cleanup routing belongs to a follow-up hygiene phase.", "", f"- legacy_orphan_candidates_count: {len(legacy_orphan_candidates)}", ""])
if legacy_orphan_candidates:
    lines.extend(f"- {row.get('repo')}: `{row.get('path')}`" for row in legacy_orphan_candidates[:100])
    if len(legacy_orphan_candidates) > 100:
        lines.append(f"- ... {len(legacy_orphan_candidates) - 100} additional legacy candidates omitted from markdown summary")
else:
    lines.append("- none")
lines.append("")

output_path.parent.mkdir(parents=True, exist_ok=True)
output_path.write_text("\n".join(lines), encoding="utf-8")

summary = {
    "schema_version": "inventory-rebuild-diff/v1",
    "status": status,
    "next_action": next_action,
    "baseline_rows": len(baseline_rows),
    "rebuild_rows": len(rebuild_rows),
    "repos_covered": len(repo_counts),
    "new_surfaces_count": len(added),
    "removed_surfaces_count": len(removed),
    "orphaned_surface_count": len(orphaned),
    "legacy_orphan_candidates_count": len(legacy_orphan_candidates),
    "added": [{"repo": row.get("repo"), "path": row.get("path")} for row in added],
    "removed": [{"repo": row.get("repo"), "path": row.get("path")} for row in removed],
    "orphaned": [{"repo": row.get("repo"), "path": row.get("path")} for row in orphaned],
    "output": str(output_path),
}
if json_out:
    print(json.dumps(summary, sort_keys=True))
PY
