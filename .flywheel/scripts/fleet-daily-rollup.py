#!/usr/bin/env python3
# canonical-cli-scoping-allow-large: rollup script keeps quality-grading reuse local; per-repo invocation cost dictates a single-file reader rather than a library refactor.
"""
fleet-daily-rollup.py — fleet-wide rollup over per-repo daily-report.py output.

Reads each enabled repo's daily-report.py JSON output (via
`daily-report-enabled-repos.sh --no-notify --json`), aggregates the
quality_grade field across repos, surfaces RED FLAGS, and writes a
top-line markdown to `~/.local/state/flywheel/fleet-daily-<date>.md`.

Source bead: flywheel-u2yc0 (chains on flywheel-lb2gk).

Canonical CLI per `canonical-cli-scoping`:
  run / doctor / health / repair (default: run)
  validate / audit / why
  schema / examples / info / completion
  --json / --dry-run / --apply / --date / --enabled-repos-bin / --output-dir
"""
from __future__ import annotations

import argparse
import json
import os
import statistics
import subprocess
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


VERSION = "fleet-daily-rollup.v1"
DEFAULT_OUTPUT_DIR = Path.home() / ".local/state/flywheel"
DEFAULT_ENABLED_REPOS_BIN = Path("/Users/josh/Developer/flywheel/.flywheel/scripts/daily-report-enabled-repos.sh")


def utc_now() -> datetime:
    raw = os.environ.get("FLYWHEEL_FLEET_ROLLUP_NOW")
    if raw:
        try:
            parsed = datetime.fromisoformat(raw.replace("Z", "+00:00"))
            if parsed.tzinfo is None:
                parsed = parsed.replace(tzinfo=timezone.utc)
            return parsed.astimezone(timezone.utc)
        except ValueError:
            pass
    return datetime.now(timezone.utc)


def schema_dict() -> dict[str, Any]:
    return {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "title": "fleet-daily-rollup output",
        "type": "object",
        "required": ["schema_version", "date", "fleet_summary", "red_flags", "per_repo", "report_path"],
        "properties": {
            "schema_version": {"const": VERSION},
            "date": {"type": "string"},
            "fleet_summary": {"type": "object"},
            "red_flags": {"type": "array"},
            "per_repo": {"type": "array"},
            "report_path": {"type": ["string", "null"]},
        },
    }


def info_dict() -> dict[str, Any]:
    return {
        "command": "fleet-daily-rollup",
        "version": VERSION,
        "default_output_dir": str(DEFAULT_OUTPUT_DIR),
        "consumes": [
            "daily-report-enabled-repos.sh --no-notify --json",
            "per-repo .quality_grade field from daily-report.py",
        ],
        "red_flags_taxonomy": [
            "fleet_median_compliance_below_850",
            "repo_median_compliance_below_850",
            "worker_avg_compliance_below_800_window7d",
            "repo_blocked_escalate_rate_above_20pct",
            "fleet_mission_fitness_drift_above_5",
        ],
    }


def examples_text() -> str:
    return (
        "EXAMPLES:\n"
        "  fleet-daily-rollup.py run --json\n"
        "  fleet-daily-rollup.py run --date 2026-05-10 --json\n"
        "  fleet-daily-rollup.py doctor --json\n"
        "  fleet-daily-rollup.py audit --limit 5 --json\n"
    )


def run_enabled_repos(bin_path: Path, date_text: str | None, dry_run: bool) -> dict[str, Any]:
    args: list[str] = [str(bin_path), "--no-notify", "--json"]
    if date_text:
        args.extend(["--date", date_text])
    if dry_run:
        args.append("--dry-run")
    proc = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=False)
    if proc.returncode not in (0, 1):
        raise RuntimeError(f"daily-report-enabled-repos.sh failed rc={proc.returncode}: {proc.stderr.strip()}")
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"daily-report-enabled-repos.sh emitted non-JSON: {exc}; stdout[:500]={proc.stdout[:500]}")


def merge_compliance(samples: list[float]) -> dict[str, Any]:
    if not samples:
        return {"n": 0, "avg": None, "median": None, "p25": None, "p75": None, "min": None, "max": None}
    sorted_vals = sorted(samples)
    n = len(sorted_vals)

    def pick(p: float) -> float:
        idx = max(0, min(n - 1, round(p * (n - 1))))
        return float(sorted_vals[idx])

    return {
        "n": n,
        "avg": round(sum(sorted_vals) / n, 1),
        "median": float(statistics.median(sorted_vals)),
        "p25": pick(0.25),
        "p75": pick(0.75),
        "min": float(sorted_vals[0]),
        "max": float(sorted_vals[-1]),
    }


def fs_rag_for_repo(repo_path: str) -> dict[str, Any]:
    """Read latest fs-rag-baseline-<date>.json from <repo>/.flywheel/audit/.

    Returns {present, baseline_path, violations_total} for a single repo.
    Surfaced into the fleet rollup as the at-rest discipline drift signal
    (per flywheel-hi4e6 leverage point #6 information flow).
    """
    audit_dir = Path(repo_path) / ".flywheel" / "audit"
    if not audit_dir.is_dir():
        return {"present": False, "baseline_path": None, "violations_total": 0}
    baselines = sorted(audit_dir.glob("fs-rag-baseline-*.json"))
    if not baselines:
        return {"present": False, "baseline_path": None, "violations_total": 0}
    latest = baselines[-1]
    payload = read_json_file(latest)
    if not isinstance(payload, dict):
        return {"present": True, "baseline_path": str(latest), "violations_total": 0}
    violations_total = int(
        payload.get("violations_total")
        or len(payload.get("violations") or [])
        or 0
    )
    return {
        "present": True,
        "baseline_path": str(latest),
        "violations_total": violations_total,
    }


def read_json_file(path: Path) -> Any:
    try:
        return json.loads(path.read_text(errors="replace"))
    except Exception:
        return None


def aggregate(per_repo: list[dict[str, Any]]) -> dict[str, Any]:
    """Aggregate quality_grade across per-repo daily-report.py results."""
    fleet_compliance: list[float] = []
    fleet_dispositions: Counter[str] = Counter()
    fleet_fitness: Counter[str] = Counter()
    fleet_callbacks = 0
    fleet_blockers = 0
    worker_compliance: dict[str, list[float]] = defaultdict(list)
    worker_closes: Counter[str] = Counter()
    repo_summaries: list[dict[str, Any]] = []

    for repo_row in per_repo:
        result = repo_row.get("result") or {}
        grade = result.get("quality_grade") or {}
        compliance = grade.get("compliance_distribution") or {}
        comp_avg = compliance.get("avg")
        comp_median = compliance.get("median")
        callback_count = int(grade.get("callback_count") or 0)
        fleet_callbacks += callback_count
        for axis_name, axis_count in (grade.get("mission_fitness_counts") or {}).items():
            fleet_fitness[axis_name] += int(axis_count or 0)
        for disp, count in (grade.get("disposition_counts") or {}).items():
            fleet_dispositions[disp] += int(count or 0)
        # Approximate fleet compliance distribution from per-repo medians weighted by callback count.
        # We don't have raw scores here without re-reading each repo's callback log; the median
        # weighted-by-count is a documented proxy. Surface the proxy explicitly.
        if isinstance(comp_avg, (int, float)) and callback_count > 0:
            fleet_compliance.extend([float(comp_avg)] * callback_count)
        for ident_row in grade.get("identity_attribution") or []:
            ident = str(ident_row.get("identity") or "unknown")
            closes_value = int(ident_row.get("closes") or 0)
            worker_closes[ident] += closes_value
            avg_compliance = ident_row.get("avg_compliance")
            if isinstance(avg_compliance, (int, float)) and closes_value > 0:
                worker_compliance[ident].extend([float(avg_compliance)] * closes_value)
        disp_counts = grade.get("disposition_counts") or {}
        blocked = int(disp_counts.get("BLOCKED") or 0) + int(disp_counts.get("ESCALATE") or 0)
        fleet_blockers += blocked

        fs_rag = fs_rag_for_repo(str(repo_row.get("repo") or ""))

        repo_summaries.append(
            {
                "repo": repo_row.get("repo"),
                "status": repo_row.get("status"),
                "callback_count": callback_count,
                "compliance_avg": comp_avg,
                "compliance_median": comp_median,
                "blocked_escalate_rate": grade.get("blocked_escalate_rate"),
                "mission_fitness_counts": grade.get("mission_fitness_counts") or {},
                "red_flags": grade.get("red_flags") or [],
                "fs_rag": fs_rag,
            }
        )

    fleet_compliance_dist = merge_compliance(fleet_compliance)

    fs_rag_present = [r for r in repo_summaries if r.get("fs_rag", {}).get("present")]
    fs_rag_violations = [int(r["fs_rag"]["violations_total"] or 0) for r in fs_rag_present]
    fs_rag_total = sum(fs_rag_violations)
    fs_rag_avg = round(fs_rag_total / len(fs_rag_violations), 1) if fs_rag_violations else 0.0
    fs_rag_max_repo = None
    fs_rag_max_count = 0
    for r in fs_rag_present:
        v = int(r["fs_rag"]["violations_total"] or 0)
        if v > fs_rag_max_count:
            fs_rag_max_count = v
            fs_rag_max_repo = r.get("repo")

    fleet_summary = {
        "callbacks": fleet_callbacks,
        "blocked_escalate_count": fleet_blockers,
        "blocked_escalate_rate": (
            round(fleet_blockers / fleet_callbacks, 3) if fleet_callbacks else 0.0
        ),
        "compliance_distribution_count_weighted_avg": fleet_compliance_dist,
        "mission_fitness_counts": dict(fleet_fitness),
        "disposition_counts": dict(fleet_dispositions),
        "active_repos": sum(1 for r in repo_summaries if r["status"] == "generated"),
        "skipped_repos": sum(1 for r in repo_summaries if r["status"] == "skipped"),
        "failed_repos": sum(1 for r in repo_summaries if r["status"] == "failed"),
        "fs_rag_discipline": {
            "repos_with_baseline": len(fs_rag_present),
            "violations_total": fs_rag_total,
            "violations_avg_per_repo": fs_rag_avg,
            "violations_max_count": fs_rag_max_count,
            "violations_max_repo": fs_rag_max_repo,
        },
    }
    worker_table = sorted(
        (
            {
                "identity": ident,
                "closes": int(closes),
                "avg_compliance": (
                    round(sum(worker_compliance[ident]) / len(worker_compliance[ident]), 1)
                    if worker_compliance.get(ident)
                    else None
                ),
            }
            for ident, closes in worker_closes.items()
        ),
        key=lambda r: (-int(r.get("closes") or 0), str(r.get("identity") or "")),
    )
    return {
        "fleet_summary": fleet_summary,
        "per_repo": repo_summaries,
        "worker_table": worker_table,
    }


def detect_red_flags(aggregated: dict[str, Any]) -> list[dict[str, str]]:
    flags: list[dict[str, str]] = []
    fleet_summary = aggregated["fleet_summary"]
    fleet_median = fleet_summary["compliance_distribution_count_weighted_avg"].get("median")
    if isinstance(fleet_median, (int, float)) and fleet_median < 850:
        flags.append({"code": "fleet_median_compliance_below_850", "detail": f"median={fleet_median}"})
    if fleet_summary["blocked_escalate_rate"] > 0.20 and fleet_summary["callbacks"] >= 5:
        flags.append(
            {"code": "fleet_blocked_escalate_above_20pct", "detail": f"rate={fleet_summary['blocked_escalate_rate']}"}
        )
    if (fleet_summary["mission_fitness_counts"].get("drift") or 0) > 5:
        flags.append(
            {
                "code": "fleet_mission_fitness_drift_above_5",
                "detail": f"drift_count={fleet_summary['mission_fitness_counts']['drift']}",
            }
        )
    for repo_row in aggregated["per_repo"]:
        rate = repo_row.get("blocked_escalate_rate") or 0.0
        if isinstance(rate, (int, float)) and rate > 0.20 and (repo_row.get("callback_count") or 0) >= 5:
            flags.append(
                {
                    "code": "repo_blocked_escalate_rate_above_20pct",
                    "detail": f"repo={repo_row.get('repo')} rate={rate}",
                }
            )
        median = repo_row.get("compliance_median")
        if isinstance(median, (int, float)) and median < 850:
            flags.append(
                {"code": "repo_median_compliance_below_850", "detail": f"repo={repo_row.get('repo')} median={median}"}
            )
    for worker_row in aggregated["worker_table"]:
        avg = worker_row.get("avg_compliance")
        closes_value = int(worker_row.get("closes") or 0)
        if isinstance(avg, (int, float)) and avg < 800 and closes_value >= 3:
            flags.append(
                {
                    "code": "worker_avg_compliance_below_800",
                    "detail": f"identity={worker_row['identity']} avg={avg} closes={closes_value}",
                }
            )
    fs_rag_summary = fleet_summary.get("fs_rag_discipline") or {}
    fs_rag_avg = fs_rag_summary.get("violations_avg_per_repo") or 0
    fs_rag_max = fs_rag_summary.get("violations_max_count") or 0
    fs_rag_max_repo = fs_rag_summary.get("violations_max_repo")
    if fs_rag_avg > 0 and isinstance(fs_rag_max, (int, float)) and fs_rag_max > 2 * fs_rag_avg:
        flags.append(
            {
                "code": "fs_rag_repo_violations_exceeds_2x_fleet_avg",
                "detail": f"repo={fs_rag_max_repo} count={fs_rag_max} fleet_avg={fs_rag_avg}",
            }
        )
    for repo_row in aggregated["per_repo"]:
        rag = repo_row.get("fs_rag") or {}
        if rag.get("present") and int(rag.get("violations_total") or 0) >= 100:
            flags.append(
                {
                    "code": "fs_rag_repo_violations_above_100",
                    "detail": f"repo={repo_row.get('repo')} count={rag.get('violations_total')}",
                }
            )
    return flags


def render_markdown(date_text: str, aggregated: dict[str, Any], red_flags: list[dict[str, str]]) -> str:
    fleet_summary = aggregated["fleet_summary"]
    fleet_dist = fleet_summary["compliance_distribution_count_weighted_avg"]
    lines: list[str] = []
    callbacks = fleet_summary["callbacks"]
    avg = fleet_dist.get("avg")
    median = fleet_dist.get("median")
    blocked = fleet_summary["blocked_escalate_count"]
    flag_count = len(red_flags)
    lines.append(f"# Fleet Daily Rollup — {date_text}")
    lines.append("")
    lines.append(
        f"**Fleet shipped {callbacks} closes** at avg compliance {avg if avg is not None else 'n/a'} "
        f"(median {median if median is not None else 'n/a'}); {blocked} BLOCKED/ESCALATE; "
        f"{flag_count} red flag{'s' if flag_count != 1 else ''}."
    )
    lines.append("")
    lines.append("## Red flags")
    if red_flags:
        for flag in red_flags:
            lines.append(f"- **{flag['code']}**: {flag['detail']}")
    else:
        lines.append("- (none)")
    lines.append("")
    lines.append("## Fleet summary")
    lines.append(f"- active_repos: {fleet_summary['active_repos']}")
    lines.append(f"- skipped_repos: {fleet_summary['skipped_repos']}")
    lines.append(f"- failed_repos: {fleet_summary['failed_repos']}")
    lines.append(f"- callbacks: {callbacks}")
    lines.append(f"- blocked_escalate_count: {blocked}")
    lines.append(f"- blocked_escalate_rate: {fleet_summary['blocked_escalate_rate']}")
    if isinstance(fleet_dist.get("avg"), (int, float)):
        lines.append(
            f"- compliance (count-weighted): avg={fleet_dist['avg']} median={fleet_dist['median']} p25={fleet_dist['p25']} p75={fleet_dist['p75']} (n={fleet_dist['n']})"
        )
    fitness = fleet_summary.get("mission_fitness_counts") or {}
    if fitness:
        lines.append("- mission_fitness: " + ", ".join(f"{k}={v}" for k, v in sorted(fitness.items())))
    dispositions = fleet_summary.get("disposition_counts") or {}
    if dispositions:
        lines.append("- disposition: " + ", ".join(f"{k}={v}" for k, v in sorted(dispositions.items())))
    fs_rag = fleet_summary.get("fs_rag_discipline") or {}
    if fs_rag.get("repos_with_baseline"):
        lines.append(
            f"- fs_rag_discipline: avg={fs_rag.get('violations_avg_per_repo')} "
            f"fleet_max={fs_rag.get('violations_max_count')}@{fs_rag.get('violations_max_repo')} "
            f"baseline_repos={fs_rag.get('repos_with_baseline')}"
        )
    lines.append("")

    lines.append("## Per-repo")
    if aggregated["per_repo"]:
        for repo_row in aggregated["per_repo"]:
            if repo_row.get("status") == "skipped":
                continue
            lines.append(
                f"- {repo_row.get('repo')}: status={repo_row.get('status')} "
                f"callbacks={repo_row.get('callback_count')} "
                f"compliance_avg={repo_row.get('compliance_avg')} "
                f"compliance_median={repo_row.get('compliance_median')} "
                f"blocked_rate={repo_row.get('blocked_escalate_rate')}"
            )
            for repo_flag in repo_row.get("red_flags") or []:
                lines.append(f"    - flag: {repo_flag.get('code')}: {repo_flag.get('detail')}")
    else:
        lines.append("- (no enabled repos)")
    lines.append("")

    lines.append("## Worker attribution")
    if aggregated["worker_table"]:
        for worker_row in aggregated["worker_table"]:
            lines.append(
                f"- {worker_row['identity']}: closes={worker_row['closes']} avg_compliance={worker_row['avg_compliance']}"
            )
    else:
        lines.append("- (no identity-attributed callbacks)")
    lines.append("")
    return "\n".join(lines)


def cmd_run(args: argparse.Namespace) -> int:
    date_text = args.date or utc_now().strftime("%Y-%m-%d")
    output_dir = Path(args.output_dir).expanduser()
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"fleet-daily-{date_text}.md"
    bin_path = Path(args.enabled_repos_bin).expanduser().resolve()

    if args.dry_run and not args.apply:
        if args.json:
            print(json.dumps({"schema_version": VERSION, "mode": "dry-run", "date": date_text, "report_path": str(output_path)}, separators=(",", ":")))
        else:
            print(f"dry-run: would write {output_path}")
        return 0

    enabled = run_enabled_repos(bin_path, date_text, dry_run=False)
    repos = enabled.get("repos") or []
    aggregated = aggregate(repos)
    red_flags = detect_red_flags(aggregated)
    markdown = render_markdown(date_text, aggregated, red_flags)
    output_path.write_text(markdown)
    payload = {
        "schema_version": VERSION,
        "date": date_text,
        "fleet_summary": aggregated["fleet_summary"],
        "red_flags": red_flags,
        "per_repo": aggregated["per_repo"],
        "worker_table": aggregated["worker_table"],
        "report_path": str(output_path),
    }
    if args.json:
        print(json.dumps(payload, separators=(",", ":")))
    else:
        print(str(output_path))
    return 0


def cmd_doctor(args: argparse.Namespace) -> int:
    bin_path = Path(args.enabled_repos_bin).expanduser().resolve()
    output_dir = Path(args.output_dir).expanduser()
    info = {
        "schema_version": VERSION,
        "command": "doctor",
        "enabled_repos_bin": str(bin_path),
        "enabled_repos_bin_executable": bin_path.exists() and os.access(bin_path, os.X_OK),
        "output_dir": str(output_dir),
        "output_dir_exists": output_dir.exists(),
    }
    if args.json:
        print(json.dumps(info, separators=(",", ":")))
    else:
        for k, v in info.items():
            print(f"{k}: {v}")
    return 0


def cmd_health(args: argparse.Namespace) -> int:
    bin_path = Path(args.enabled_repos_bin).expanduser().resolve()
    status = "ok" if (bin_path.exists() and os.access(bin_path, os.X_OK)) else "missing_enabled_repos_bin"
    payload = {"schema_version": VERSION, "status": status}
    if args.json:
        print(json.dumps(payload, separators=(",", ":")))
    else:
        print(f"health={status}")
    return 0 if status == "ok" else 2


def cmd_repair(args: argparse.Namespace) -> int:
    if not args.dry_run and not args.apply:
        print("repair: --dry-run or --apply required", file=sys.stderr)
        return 2
    payload = {
        "schema_version": VERSION,
        "command": "repair",
        "mode": "apply" if args.apply else "dry-run",
        "candidates": [],
        "note": "no auto-mutation; rerun run command after fixing root cause",
    }
    if args.json:
        print(json.dumps(payload, separators=(",", ":")))
    else:
        print("repair: no auto-mutation")
    return 0


def cmd_validate(args: argparse.Namespace) -> int:
    if not args.target:
        print("validate: <fleet-rollup-md-path> required", file=sys.stderr)
        return 2
    target = Path(args.target).expanduser()
    payload = {
        "schema_version": VERSION,
        "command": "validate",
        "target": str(target),
        "exists": target.exists(),
        "size": target.stat().st_size if target.exists() else None,
    }
    if args.json:
        print(json.dumps(payload, separators=(",", ":")))
    else:
        for k, v in payload.items():
            print(f"{k}: {v}")
    return 0 if target.exists() else 2


def cmd_audit(args: argparse.Namespace) -> int:
    output_dir = Path(args.output_dir).expanduser()
    listings = sorted(output_dir.glob("fleet-daily-*.md"))[-int(args.limit or 10) :]
    rows = [{"path": str(p), "size": p.stat().st_size} for p in listings]
    payload = {"schema_version": VERSION, "command": "audit", "count": len(rows), "rows": rows}
    if args.json:
        print(json.dumps(payload, separators=(",", ":")))
    else:
        for r in rows:
            print(f"{r['path']} size={r['size']}")
    return 0


def cmd_why(args: argparse.Namespace) -> int:
    return cmd_validate(args)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=f"{VERSION} — fleet-wide rollup over per-repo daily-report.py output")
    sub = parser.add_subparsers(dest="command")

    common: list[Any] = []

    def add_common(p: argparse.ArgumentParser) -> None:
        p.add_argument("--enabled-repos-bin", default=str(DEFAULT_ENABLED_REPOS_BIN))
        p.add_argument("--output-dir", default=str(DEFAULT_OUTPUT_DIR))
        p.add_argument("--json", action="store_true")
        p.add_argument("--dry-run", action="store_true")
        p.add_argument("--apply", action="store_true")
        p.add_argument("--date")
        p.add_argument("--limit")
        p.add_argument("target", nargs="?")

    for name in ("run", "doctor", "health", "repair", "validate", "audit", "why"):
        sp = sub.add_parser(name)
        add_common(sp)
        common.append(sp)

    sub.add_parser("schema")
    sub.add_parser("examples")
    sub.add_parser("info")
    sub.add_parser("completion")
    sub.add_parser("help")

    args = parser.parse_args(argv)
    cmd = args.command or "run"

    if cmd == "schema":
        print(json.dumps(schema_dict(), separators=(",", ":")))
        return 0
    if cmd == "info":
        print(json.dumps(info_dict(), separators=(",", ":")))
        return 0
    if cmd == "examples":
        print(examples_text())
        return 0
    if cmd == "completion":
        print(
            'complete -W "run doctor health repair validate audit why schema examples info completion help '
            '--enabled-repos-bin --output-dir --date --json --dry-run --apply --limit" fleet-daily-rollup.py'
        )
        return 0
    if cmd == "help":
        parser.print_help()
        return 0

    if not hasattr(args, "enabled_repos_bin"):
        # Default `run` invocation without subcommand
        run_parser = next((c for c in common if c.prog.endswith(" run")), None) or common[0]
        run_args = run_parser.parse_args([])
        for k, v in vars(run_args).items():
            setattr(args, k, getattr(args, k, v))

    handler = {
        "run": cmd_run,
        "doctor": cmd_doctor,
        "health": cmd_health,
        "repair": cmd_repair,
        "validate": cmd_validate,
        "audit": cmd_audit,
        "why": cmd_why,
    }[cmd]
    return handler(args)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
