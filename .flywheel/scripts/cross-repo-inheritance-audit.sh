#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
usage: cross-repo-inheritance-audit.sh [--json] [--write-report] [--output-dir DIR] [--repo NAME=PATH ...]

Audits consumer repos for flywheel meta-pattern inheritance.

Checks per repo:
  - .flywheel/doctrine/meta-learnings/MP-01..MP-70 presence
  - content divergence from flywheel canonical MP files
  - root META-PATTERN-ADOPTION.md
  - root DISCREPANCIES.md
  - skipped Track 2 state/legal-house file count

Options:
  --json              print one JSON row per repo
  --write-report      write inheritance.jsonl and INHERITANCE.md
  --output-dir DIR    report directory
  --repo NAME=PATH    repeatable repo override
  --canonical-dir DIR canonical MP directory override
  --expected-count N  expected MP count; default 70

Each row includes next_action: OK, PROPAGATE, or RECONCILE.
USAGE
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DATE_STAMP="${CROSS_REPO_INHERITANCE_DATE:-2026-05-19}"
OUTPUT_DIR="$ROOT/.flywheel/audits/cross-repo-inheritance-$DATE_STAMP"
CANONICAL_DIR="$ROOT/.flywheel/doctrine/meta-learnings"
EXPECTED_COUNT=70
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
    --canonical-dir) CANONICAL_DIR="${2:?--canonical-dir requires DIR}"; shift 2 ;;
    --canonical-dir=*) CANONICAL_DIR="${1#*=}"; shift ;;
    --expected-count) EXPECTED_COUNT="${2:?--expected-count requires N}"; shift 2 ;;
    --expected-count=*) EXPECTED_COUNT="${1#*=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ "$JSON_OUT" -eq 0 && "$WRITE_REPORT" -eq 0 ]]; then
  WRITE_REPORT=1
fi

if [[ "${#REPOS[@]}" -eq 0 ]]; then
  REPOS=(
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

python3 - "$OUTPUT_DIR" "$CANONICAL_DIR" "$EXPECTED_COUNT" "$JSON_OUT" "$WRITE_REPORT" "${REPOS[@]}" <<'PY'
from __future__ import annotations

import hashlib
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

output_dir = Path(sys.argv[1]).expanduser()
canonical_dir = Path(sys.argv[2]).expanduser()
expected_count = int(sys.argv[3])
json_out = sys.argv[4] == "1"
write_report = sys.argv[5] == "1"
repo_args = sys.argv[6:]


def now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def parse_repos(args: list[str]) -> list[tuple[str, Path]]:
    repos: list[tuple[str, Path]] = []
    for item in args:
        if "=" not in item:
            raise SystemExit(f"repo argument must be NAME=PATH: {item}")
        name, raw_path = item.split("=", 1)
        repos.append((name, Path(raw_path).expanduser()))
    return repos


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def mp_id(index: int) -> str:
    return f"MP-{index:02d}"


def find_mp_file(directory: Path, ident: str) -> Path | None:
    if not directory.exists():
        return None
    matches = sorted(directory.glob(f"{ident}-*.md"))
    if not matches:
        exact = directory / f"{ident}.md"
        matches = [exact] if exact.exists() else []
    return matches[0] if matches else None


def count_track2_files(repo_path: Path) -> int:
    legal_house = repo_path / "state" / "legal-house"
    if not legal_house.exists():
        return 0
    count = 0
    for _, _, files in os.walk(legal_house):
        count += len(files)
    return count


def repo_row(name: str, repo_path: Path, canonical: dict[str, dict[str, str]], canonical_missing: list[str], generated_at: str) -> dict:
    expected_ids = [mp_id(i) for i in range(1, expected_count + 1)]
    meta_dir = repo_path / ".flywheel" / "doctrine" / "meta-learnings"
    present: list[str] = []
    missing: list[str] = []
    divergences: list[dict[str, str]] = []
    repo_exists = repo_path.exists()

    for ident in expected_ids:
        target = find_mp_file(meta_dir, ident) if repo_exists else None
        if target is None:
            missing.append(ident)
            continue
        present.append(ident)
        if ident in canonical:
            actual_sha = sha256_file(target)
            expected_sha = canonical[ident]["sha256"]
            if actual_sha != expected_sha:
                divergences.append({
                    "mp_id": ident,
                    "repo_file": str(target),
                    "canonical_file": canonical[ident]["path"],
                    "actual_sha256": actual_sha,
                    "canonical_sha256": expected_sha,
                })

    adoption_path = repo_path / "META-PATTERN-ADOPTION.md"
    discrepancies_path = repo_path / "DISCREPANCIES.md"
    adoption_exists = adoption_path.exists()
    discrepancies_exists = discrepancies_path.exists()
    present_count = len(present)
    coverage_ratio = round(present_count / expected_count, 4) if expected_count else 0.0
    needs_propagation = (not repo_exists) or bool(missing) or not adoption_exists or not discrepancies_exists
    needs_reconcile = bool(divergences)
    if needs_propagation:
        next_action = "PROPAGATE"
    elif needs_reconcile:
        next_action = "RECONCILE"
    else:
        next_action = "OK"

    return {
        "schema_version": "cross-repo-inheritance-audit/v1",
        "generated_at": generated_at,
        "repo": name,
        "repo_path": str(repo_path),
        "repo_exists": repo_exists,
        "expected_mp_count": expected_count,
        "canonical_missing_mps": canonical_missing,
        "present_mp_count": present_count,
        "missing_mp_count": len(missing),
        "inheritance_coverage_ratio": coverage_ratio,
        "present_mps": present,
        "missing_mps": missing,
        "meta_pattern_adoption": {
            "path": str(adoption_path),
            "status": "PRESENT" if adoption_exists else "MISSING",
        },
        "discrepancies": {
            "path": str(discrepancies_path),
            "status": "PRESENT" if discrepancies_exists else "MISSING",
        },
        "divergence_count": len(divergences),
        "divergences": divergences,
        "skipped_track2_count": count_track2_files(repo_path) if repo_exists else 0,
        "next_action": next_action,
        "status": "OK" if next_action == "OK" else "WARN",
    }


def markdown(rows: list[dict], canonical_missing: list[str], generated_at: str) -> str:
    total_track2 = sum(row["skipped_track2_count"] for row in rows)
    ok_count = sum(1 for row in rows if row["next_action"] == "OK")
    propagate_count = sum(1 for row in rows if row["next_action"] == "PROPAGATE")
    reconcile_count = sum(1 for row in rows if row["next_action"] == "RECONCILE")
    lines = [
        "# Cross-Repo Inheritance Audit — 2026-05-19",
        "",
        f"- Generated: {generated_at}",
        f"- Consumer repos audited: {len(rows)}/10",
        f"- Canonical source: `{canonical_dir}`",
        f"- Expected meta-pattern receipts per repo: {expected_count}",
        f"- Canonical missing MP files: {len(canonical_missing)}",
        f"- skipped_track2_count: {total_track2}",
        f"- Next-action distribution: OK={ok_count}, PROPAGATE={propagate_count}, RECONCILE={reconcile_count}",
        "",
        "## Per-Repo Summary",
        "",
        "| Repo | Coverage | Missing MPs | Adoption | Discrepancies | Divergences | skipped_track2_count | Next action |",
        "|---|---:|---:|---|---|---:|---:|---|",
    ]
    for row in rows:
        lines.append(
            f"| {row['repo']} | {row['present_mp_count']}/{row['expected_mp_count']} "
            f"({row['inheritance_coverage_ratio']:.2%}) | {row['missing_mp_count']} | "
            f"{row['meta_pattern_adoption']['status']} | {row['discrepancies']['status']} | "
            f"{row['divergence_count']} | {row['skipped_track2_count']} | {row['next_action']} |"
        )

    lines.extend(["", "## Missing MPs", ""])
    for row in rows:
        if row["missing_mps"]:
            missing = ", ".join(row["missing_mps"])
            lines.append(f"- **{row['repo']}**: {missing}")
        else:
            lines.append(f"- **{row['repo']}**: none")

    lines.extend(["", "## Divergences", ""])
    any_divergence = False
    for row in rows:
        for divergence in row["divergences"]:
            any_divergence = True
            lines.append(
                f"- **{row['repo']} {divergence['mp_id']}**: "
                f"`{divergence['repo_file']}` sha={divergence['actual_sha256'][:12]} "
                f"canonical={divergence['canonical_sha256'][:12]}"
            )
    if not any_divergence:
        lines.append("- none")

    lines.extend(["", "## Next Actions", ""])
    for row in rows:
        reasons: list[str] = []
        if row["missing_mp_count"]:
            reasons.append(f"{row['missing_mp_count']} missing MP receipts")
        if row["meta_pattern_adoption"]["status"] != "PRESENT":
            reasons.append("missing META-PATTERN-ADOPTION.md")
        if row["discrepancies"]["status"] != "PRESENT":
            reasons.append("missing DISCREPANCIES.md")
        if row["divergence_count"]:
            reasons.append(f"{row['divergence_count']} divergent MP files")
        if not reasons:
            reasons.append("all inheritance receipts present and matching")
        lines.append(f"- **{row['repo']}**: {row['next_action']} — {'; '.join(reasons)}.")

    if canonical_missing:
        lines.extend(["", "## Canonical Gaps", "", "- " + ", ".join(canonical_missing)])

    lines.append("")
    return "\n".join(lines)


repos = parse_repos(repo_args)
generated_at = now_iso()
canonical: dict[str, dict[str, str]] = {}
canonical_missing: list[str] = []
for index in range(1, expected_count + 1):
    ident = mp_id(index)
    path = find_mp_file(canonical_dir, ident)
    if path is None:
        canonical_missing.append(ident)
    else:
        canonical[ident] = {"path": str(path), "sha256": sha256_file(path)}

rows = [repo_row(name, path, canonical, canonical_missing, generated_at) for name, path in repos]

if write_report:
    output_dir.mkdir(parents=True, exist_ok=True)
    jsonl_path = output_dir / "inheritance.jsonl"
    with jsonl_path.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, sort_keys=True) + "\n")
    (output_dir / "INHERITANCE.md").write_text(markdown(rows, canonical_missing, generated_at), encoding="utf-8")

if json_out:
    for row in rows:
        print(json.dumps(row, sort_keys=True))

if canonical_missing:
    print(
        json.dumps({
            "schema_version": "cross-repo-inheritance-audit/v1",
            "status": "error",
            "next_action": "repair canonical MP source before auditing consumers",
            "canonical_missing_mps": canonical_missing,
        }),
        file=sys.stderr,
    )
    raise SystemExit(1)
PY
