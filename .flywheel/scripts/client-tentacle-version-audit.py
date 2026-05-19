#!/usr/bin/env python3
"""Audit fleet repos for br/bv/ntm version drift without mutating them."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "client-tentacle-version-audit/v1"
DEFAULT_ROSTER = Path("~/.local/state/flywheel/fleet-roster.json").expanduser()
DEFAULT_REPOS = [
    ("alpsinsurance", Path("~/Developer/alpsinsurance").expanduser()),
    ("polymarket-pico-z", Path("~/Developer/polymarket-pico-z").expanduser()),
    ("vrtx", Path("~/Developer/vrtx").expanduser()),
]
DEFAULT_TOOLS = ("br", "bv", "ntm")
VERSION_RE = re.compile(r"(?<!\d)v?(\d+)(?:\.(\d+))?(?:\.(\d+))?")


@dataclass(frozen=True)
class RepoTarget:
    name: str
    path: Path
    tier: str | None = None
    source: str = "explicit"


@dataclass(frozen=True)
class VersionResult:
    binary: str | None
    version: str | None
    raw: str
    status: str
    detail: str


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Audit client repo tentacle versions.")
    parser.add_argument("mode", nargs="?", choices=["audit", "doctor", "health", "validate", "schema", "info", "examples", "why", "repair"], default="audit")
    parser.add_argument("--json", action="store_true", help="Emit JSON. Non-JSON mode prints a compact summary.")
    parser.add_argument("--roster", type=Path, default=DEFAULT_ROSTER, help="Fleet roster JSON path.")
    parser.add_argument("--repo", action="append", default=[], help="Extra repo as NAME=PATH or PATH.")
    parser.add_argument("--tools", default=",".join(DEFAULT_TOOLS), help="Comma-separated required tools. Default: br,bv,ntm.")
    parser.add_argument("--tool-bin", action="append", default=[], help="Override tool binary as TOOL=PATH.")
    parser.add_argument("--drift-minor-threshold", type=int, default=1, help="Warn when minor-version span is greater than this value.")
    parser.add_argument("--timeout-sec", type=float, default=5.0, help="Per-tool version command timeout.")
    parser.add_argument("--include-missing-explicit", action="store_true", default=True, help=argparse.SUPPRESS)
    for flag, mode in [("--doctor", "doctor"), ("--health", "health"), ("--validate", "validate"), ("--schema", "schema"), ("--info", "info"), ("--examples", "examples"), ("--why", "why"), ("--repair", "repair")]:
        parser.add_argument(flag, action="store_const", const=mode, dest="flag_mode", help=f"Run {mode} mode.")
    ns = parser.parse_args(argv)
    if getattr(ns, "flag_mode", None):
        ns.mode = ns.flag_mode
    return ns


def repo_arg(value: str) -> RepoTarget:
    if "=" in value:
        name, raw_path = value.split("=", 1)
        path = Path(raw_path).expanduser()
        return RepoTarget(name=name or path.name, path=path, source="cli")
    path = Path(value).expanduser()
    return RepoTarget(name=path.name, path=path, source="cli")


def load_roster(path: Path) -> tuple[list[RepoTarget], list[dict[str, Any]]]:
    if not path.exists():
        return [], [{"code": "roster_missing", "path": str(path)}]
    try:
        payload = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        return [], [{"code": "roster_unreadable", "path": str(path), "detail": str(exc)}]

    repos: list[RepoTarget] = []
    for member in payload.get("members", []):
        raw_path = member.get("repo_realpath") or member.get("repo")
        if not raw_path:
            continue
        repos.append(
            RepoTarget(
                name=str(member.get("name") or Path(raw_path).name),
                path=Path(raw_path).expanduser(),
                tier=str(member.get("tier")) if member.get("tier") is not None else None,
                source="fleet-roster",
            )
        )
    return repos, []


def collect_repos(ns: argparse.Namespace) -> tuple[list[RepoTarget], list[dict[str, Any]]]:
    repos, warnings = load_roster(ns.roster.expanduser())
    repos.extend(RepoTarget(name=name, path=path, source="default") for name, path in DEFAULT_REPOS)
    repos.extend(repo_arg(item) for item in ns.repo)

    seen: set[str] = set()
    deduped: list[RepoTarget] = []
    for repo in repos:
        key = str(repo.path.resolve(strict=False))
        if key in seen:
            continue
        seen.add(key)
        deduped.append(repo)
    return deduped, warnings


def tool_overrides(items: list[str]) -> dict[str, str]:
    overrides: dict[str, str] = {}
    for item in items:
        if "=" not in item:
            raise SystemExit(f"--tool-bin must be TOOL=PATH, got {item!r}")
        tool, path = item.split("=", 1)
        overrides[tool] = str(Path(path).expanduser())
    return overrides


def candidate_bins(tool: str, overrides: dict[str, str]) -> list[str]:
    if tool in overrides:
        return [overrides[tool]]
    home = Path.home()
    defaults = {
        "br": [home / ".cargo/bin/br", home / ".local/bin/br", "br"],
        "bv": [home / ".cargo/bin/bv", home / ".local/bin/bv", "bv"],
        "ntm": [home / ".local/bin/ntm", home / ".cargo/bin/ntm", "ntm"],
    }
    return [str(item) for item in defaults.get(tool, [tool])]


def resolve_bin(candidate: str) -> str | None:
    if "/" in candidate:
        return candidate if os.access(candidate, os.X_OK) else None
    return shutil.which(candidate)


def version_commands(tool: str) -> list[list[str]]:
    if tool == "ntm":
        return [["version", "--json"], ["version"], ["--version"]]
    return [["--version"], ["version", "--json"], ["version"]]


def extract_version(tool: str, output: str) -> tuple[str | None, str]:
    text = output.strip()
    if not text:
        return None, "empty_version_output"
    if tool == "ntm" and text.startswith("{"):
        try:
            payload = json.loads(text)
        except json.JSONDecodeError:
            pass
        else:
            version = payload.get("version")
            if version:
                return str(version), "json_version"
    match = VERSION_RE.search(text)
    if match:
        return ".".join(part or "0" for part in match.groups()), "semver_text"
    token = text.split()[0] if text.split() else text
    return token, "unversioned_text"


def probe_tool(repo: RepoTarget, tool: str, overrides: dict[str, str], timeout: float) -> VersionResult:
    if not repo.path.exists():
        return VersionResult(None, None, "", "repo_missing", "repo_path_missing")
    if not repo.path.is_dir():
        return VersionResult(None, None, "", "repo_missing", "repo_path_not_directory")

    for candidate in candidate_bins(tool, overrides):
        binary = resolve_bin(candidate)
        if not binary:
            continue
        errors: list[str] = []
        for args in version_commands(tool):
            try:
                completed = subprocess.run(
                    [binary, *args],
                    cwd=repo.path,
                    text=True,
                    capture_output=True,
                    timeout=timeout,
                    check=False,
                )
            except (OSError, subprocess.TimeoutExpired) as exc:
                errors.append(str(exc))
                continue
            output = "\n".join(part for part in [completed.stdout, completed.stderr] if part).strip()
            if completed.returncode != 0:
                errors.append(output or f"exit_{completed.returncode}")
                continue
            version, detail = extract_version(tool, output)
            if version and VERSION_RE.search(version):
                return VersionResult(binary, version, output, "ok", detail)
            if version:
                return VersionResult(binary, version, output, "unversioned", detail)
            errors.append(detail)
        if errors:
            return VersionResult(binary, None, "; ".join(errors), "error", "version_command_failed")
    return VersionResult(None, None, "", "missing", "tool_binary_missing")


def parsed_version(version: str | None) -> dict[str, int] | None:
    if not version:
        return None
    match = VERSION_RE.search(version)
    if not match:
        return None
    major, minor, patch = match.groups()
    return {"major": int(major), "minor": int(minor or 0), "patch": int(patch or 0)}


def build_rows(ns: argparse.Namespace) -> dict[str, Any]:
    repos, warnings = collect_repos(ns)
    tools = [tool.strip() for tool in ns.tools.split(",") if tool.strip()]
    overrides = tool_overrides(ns.tool_bin)
    rows: list[dict[str, Any]] = []

    for repo in repos:
        for tool in tools:
            result = probe_tool(repo, tool, overrides, ns.timeout_sec)
            parsed = parsed_version(result.version)
            rows.append(
                {
                    "repo": repo.name,
                    "repo_path": str(repo.path),
                    "repo_source": repo.source,
                    "tier": repo.tier,
                    "tool": tool,
                    "required": True,
                    "binary": result.binary,
                    "version": result.version,
                    "raw_version": result.raw,
                    "parsed_version": parsed,
                    "status": result.status,
                    "detail": result.detail,
                }
            )

    drift_warnings = version_drift(rows, ns.drift_minor_threshold)
    for warning in drift_warnings:
        tool = warning["tool"]
        drift_status = warning["status"]
        for row in rows:
            if row["tool"] == tool and row["status"] == "ok":
                row["status"] = drift_status
                row["detail"] = warning["code"]

    all_warnings = warnings + drift_warnings + row_warnings(rows)
    status = "pass" if not all_warnings else "warn"
    return {
        "schema_version": SCHEMA_VERSION,
        "mode": ns.mode,
        "status": status,
        "mutation_policy": "read_only; does not write inside audited repos",
        "roster": str(ns.roster.expanduser()),
        "repo_count": len(repos),
        "tool_count": len(tools),
        "row_count": len(rows),
        "drift_minor_threshold": ns.drift_minor_threshold,
        "required_fields": ["repo", "tool", "version", "status"],
        "warnings": all_warnings,
        "summary": summarize(rows, drift_warnings),
        "rows": rows,
    }


def version_drift(rows: list[dict[str, Any]], threshold: int) -> list[dict[str, Any]]:
    warnings: list[dict[str, Any]] = []
    for tool in sorted({row["tool"] for row in rows}):
        parsed = [row["parsed_version"] for row in rows if row["tool"] == tool and row.get("parsed_version")]
        if len(parsed) < 2:
            continue
        majors = {item["major"] for item in parsed}
        minor_span = max(item["minor"] for item in parsed) - min(item["minor"] for item in parsed)
        if len(majors) > 1:
            warnings.append({"code": "major_drift", "tool": tool, "status": "drift", "majors": sorted(majors)})
        elif minor_span > threshold:
            warnings.append({"code": "minor_drift_gt_one", "tool": tool, "status": "drift", "minor_span": minor_span})
    return warnings


def row_warnings(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    warnings: list[dict[str, Any]] = []
    for row in rows:
        if row["status"] in {"missing", "repo_missing", "error", "unversioned"}:
            warnings.append({"code": row["status"], "repo": row["repo"], "tool": row["tool"], "detail": row["detail"]})
    return warnings


def summarize(rows: list[dict[str, Any]], drift_warnings: list[dict[str, Any]]) -> dict[str, Any]:
    counts: dict[str, int] = {}
    for row in rows:
        counts[row["status"]] = counts.get(row["status"], 0) + 1
    return {
        "status_counts": counts,
        "missing_required_count": sum(1 for row in rows if row["status"] == "missing"),
        "repo_missing_count": sum(1 for row in rows if row["status"] == "repo_missing"),
        "unversioned_count": sum(1 for row in rows if row["status"] == "unversioned"),
        "drift_count": len(drift_warnings),
    }


def schema() -> dict[str, Any]:
    return {
        "schema_version": SCHEMA_VERSION,
        "modes": ["audit", "doctor", "health", "validate", "schema", "info", "examples", "why", "repair"],
        "required_row_fields": ["repo", "tool", "version", "status"],
        "default_required_tools": list(DEFAULT_TOOLS),
        "stable_exit_codes": {"0": "success_or_warn", "1": "internal_failure", "2": "usage_error"},
        "mutation_policy": "audit, doctor, health, validate, and repair are read-only for target repos",
    }


def info() -> dict[str, Any]:
    return schema() | {
        "name": "client-tentacle-version-audit.py",
        "owner": "flywheel",
        "default_roster": str(DEFAULT_ROSTER),
        "default_repos": [{"repo": name, "path": str(path)} for name, path in DEFAULT_REPOS],
    }


def examples() -> str:
    return "\n".join(
        [
            "client-tentacle-version-audit.py audit --json",
            "client-tentacle-version-audit.py doctor --json",
            "client-tentacle-version-audit.py validate --repo demo=/tmp/demo --tool-bin br=/tmp/br --json",
        ]
    )


def emit(payload: dict[str, Any], json_out: bool) -> None:
    if json_out:
        print(json.dumps(payload, sort_keys=True))
        return
    print(f"client-tentacle-version-audit status={payload['status']} repos={payload.get('repo_count', 0)} rows={payload.get('row_count', 0)} warnings={len(payload.get('warnings', []))}")


def main(argv: list[str]) -> int:
    try:
        ns = parse_args(argv)
        if ns.mode == "schema":
            emit(schema(), True)
            return 0
        if ns.mode == "info":
            emit(info(), True)
            return 0
        if ns.mode == "examples":
            print(examples())
            return 0
        if ns.mode == "why":
            emit({"schema_version": SCHEMA_VERSION, "mode": "why", "status": "pass", "why": "Cross-repo tentacle work fails when client repos silently drift on br, bv, or ntm versions."}, ns.json)
            return 0
        if ns.mode == "repair":
            payload = build_rows(ns)
            payload["repair"] = {"applied": False, "reason": "read_only_audit_surface"}
            emit(payload, ns.json)
            return 0
        emit(build_rows(ns), ns.json)
        return 0
    except SystemExit:
        raise
    except Exception as exc:  # boundary guard for CLI callers
        print(json.dumps({"schema_version": SCHEMA_VERSION, "status": "fail", "error": str(exc)}), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
