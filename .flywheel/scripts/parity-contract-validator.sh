#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

python3 - "$ROOT" "$@" <<'PY'
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
from pathlib import Path

MODE_GROUPS = {
    "dry_run_apply": ("--dry-run", "--apply"),
    "check_commit": ("--check", "--commit"),
    "plan_execute": ("--plan", "--execute"),
}

NAMED_CHECK_PATTERNS = [
    ".flywheel/scripts/branch-protection-apply.sh",
    ".flywheel/scripts/auto-push.sh",
    ".flywheel/scripts/supabase-rls-emergency-fix.sh",
    ".flywheel/scripts/mp-validator-framework.sh",
    ".flywheel/scripts/mp-scaffolders/MP-*-scaffold.sh",
    ".flywheel/scripts/codex-goal-mode-monitor-probe.sh",
]

PARITY_RE = re.compile(
    r"parity_assertion|test_parity_dry_run_apply_envelope|--verify-parity|"
    r"no-mutate-side-effects|\.computation|"
    r"dry-run[^\\n]{0,120}apply[^\\n]{0,120}(match|equal|same)|"
    r"apply[^\\n]{0,120}dry-run[^\\n]{0,120}(match|equal|same)",
    re.IGNORECASE,
)


def utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def stamp_for_path(ts: str) -> str:
    return re.sub(r"[^0-9A-Za-z]", "", ts)


def rel(path: Path, root: Path) -> str:
    try:
        return path.resolve().relative_to(root.resolve()).as_posix()
    except ValueError:
        return path.as_posix()


def read_text(path: Path) -> str:
    try:
        return path.read_text(errors="replace")
    except OSError:
        return ""


def mode_groups(text: str) -> list[str]:
    found: list[str] = []
    for name, (left, right) in MODE_GROUPS.items():
        if left in text and right in text:
            found.append(name)
    if "--apply" in text and "dry-run" in text and "dry_run_apply" not in found:
        found.append("default_dry_run_apply")
    return found


def candidate_sources(scripts_dir: Path, tests_dir: Path) -> list[Path]:
    paths: list[Path] = []
    if scripts_dir.is_dir():
        paths.extend(sorted(scripts_dir.rglob("*.sh")))
    if tests_dir.is_dir():
        paths.extend(sorted(tests_dir.glob("*.sh")))
    return paths


def fixture_candidates(source: Path, tests_dir: Path) -> list[Path]:
    if source.parent.resolve() == tests_dir.resolve():
        return [source]

    stem = source.stem
    candidates = [
        tests_dir / f"{stem}-smoke.sh",
        tests_dir / f"{stem}.sh",
        tests_dir / f"{stem}-canonical-cli.sh",
        tests_dir / f"test-{stem}.sh",
        tests_dir / f"test_{stem}.sh",
    ]
    candidates.extend(sorted(tests_dir.glob(f"{stem}*.sh")))

    seen: set[Path] = set()
    unique: list[Path] = []
    for candidate in candidates:
        key = candidate.resolve() if candidate.exists() else candidate
        if key not in seen:
            seen.add(key)
            unique.append(candidate)
    return unique


def classify(source: Path, root: Path, tests_dir: Path) -> dict[str, object] | None:
    source_text = read_text(source)
    groups = mode_groups(source_text)
    if not groups:
        return None

    fixtures = [p for p in fixture_candidates(source, tests_dir) if p.is_file()]
    fixture_rel = [rel(p, root) for p in fixtures]

    parity_paths = []
    for fixture in fixtures:
        if PARITY_RE.search(read_text(fixture)):
            parity_paths.append(rel(fixture, root))

    if parity_paths:
        status = "PASS"
        reason = "fixture contains parity assertion"
    elif fixtures:
        status = "FAIL"
        reason = "fixture exists but no parity assertion was detected"
    else:
        status = "NO-FIXTURE"
        reason = "no matching smoke fixture found"

    return {
        "path": rel(source, root),
        "source_type": "test" if source.parent.resolve() == tests_dir.resolve() else "script",
        "mode_groups": groups,
        "status": status,
        "reason": reason,
        "fixtures": fixture_rel,
        "parity_fixtures": parity_paths,
    }


def render_report(envelope: dict[str, object]) -> str:
    rows = envelope["rows"]
    lines = [
        "# Dry-Run/Apply Parity Contract Conformance",
        "",
        f"Generated: `{envelope['generated_at']}`",
        f"Root: `{envelope['root']}`",
        f"Status: `{envelope['status']}`",
        "",
        "## Summary",
        "",
        "| Metric | Count |",
        "|---|---:|",
    ]
    summary = envelope["summary"]
    for key in ("total", "pass", "fail", "no_fixture"):
        lines.append(f"| {key} | `{summary[key]}` |")

    lines.extend(
        [
            "",
            "## Named Initial Checks",
            "",
            "| Status | Path | Detail |",
            "|---|---|---|",
        ]
    )
    for check in envelope["named_checks"]:
        lines.append(f"| `{check['status']}` | `{check['path']}` | {check['detail']} |")

    lines.extend(
        [
            "",
            "## Scripts",
            "",
            "| Status | Path | Modes | Fixture | Reason |",
            "|---|---|---|---|---|",
        ]
    )
    for row in rows:
        fixtures = ", ".join(f"`{p}`" for p in row["fixtures"]) or "`none`"
        modes = ", ".join(f"`{m}`" for m in row["mode_groups"])
        lines.append(
            f"| `{row['status']}` | `{row['path']}` | {modes} | "
            f"{fixtures} | {row['reason']} |"
        )

    lines.extend(
        [
            "",
            "## JSON Envelope",
            "",
            "```json",
            json.dumps(envelope, indent=2, sort_keys=True),
            "```",
            "",
        ]
    )
    return "\n".join(lines)


def named_checks(root: Path, row_by_path: dict[str, dict[str, object]]) -> list[dict[str, str]]:
    checks: list[dict[str, str]] = []
    for pattern in NAMED_CHECK_PATTERNS:
        matches = sorted(root.glob(pattern))
        if not matches:
            checks.append({"path": pattern, "status": "MISSING", "detail": "named target not present"})
            continue
        for path in matches:
            path_rel = rel(path, root)
            row = row_by_path.get(path_rel)
            if row:
                detail = str(row["reason"])
                checks.append({"path": path_rel, "status": str(row["status"]), "detail": detail})
            else:
                checks.append({"path": path_rel, "status": "NOT-DUAL", "detail": "no dual-mode flag pair detected"})
    return checks


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Audit dual-mode flywheel scripts for dry-run/apply parity fixtures."
    )
    parser.add_argument("--root", default=sys.argv[1])
    parser.add_argument("--scripts-dir")
    parser.add_argument("--tests-dir")
    parser.add_argument("--audit-dir")
    parser.add_argument("--timestamp")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args(sys.argv[2:])

    root = Path(args.root).resolve()
    scripts_dir = Path(args.scripts_dir).resolve() if args.scripts_dir else root / ".flywheel/scripts"
    tests_dir = Path(args.tests_dir).resolve() if args.tests_dir else root / "tests"
    audit_dir = Path(args.audit_dir).resolve() if args.audit_dir else root / ".flywheel/audits"
    generated_at = args.timestamp or utc_now()

    rows: list[dict[str, object]] = []
    for source in candidate_sources(scripts_dir, tests_dir):
        row = classify(source, root, tests_dir)
        if row:
            rows.append(row)
    rows.sort(key=lambda item: (str(item["status"]), str(item["path"])))
    row_by_path = {str(row["path"]): row for row in rows}

    summary = {
        "total": len(rows),
        "pass": sum(1 for row in rows if row["status"] == "PASS"),
        "fail": sum(1 for row in rows if row["status"] == "FAIL"),
        "no_fixture": sum(1 for row in rows if row["status"] == "NO-FIXTURE"),
    }
    status = "pass" if summary["fail"] == 0 and summary["no_fixture"] == 0 else "fail"

    audit_dir.mkdir(parents=True, exist_ok=True)
    report_path = audit_dir / f"parity-contract-conformance-{stamp_for_path(generated_at)}.md"
    envelope = {
        "schema_version": "parity-contract-conformance.v1",
        "generated_at": generated_at,
        "root": str(root),
        "scripts_dir": rel(scripts_dir, root),
        "tests_dir": rel(tests_dir, root),
        "status": status,
        "summary": summary,
        "rows": rows,
        "named_checks": named_checks(root, row_by_path),
        "report_path": rel(report_path, root),
    }
    report_path.write_text(render_report(envelope))

    if args.json:
        print(json.dumps(envelope, sort_keys=True))
    else:
        print(rel(report_path, root))

    return 1 if args.strict and status != "pass" else 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
