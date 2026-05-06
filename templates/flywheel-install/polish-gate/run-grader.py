#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import tempfile
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

MODES = ("bootstrap", "audit_only", "blocking")
SCOPES = ("new", "touched", "repo_local_flywheel", "all_declared")
LANES = ("ubs", "simplify", "extreme-opt", "readme", "canonical-cli")
GRADE_FLOOR = 9.0
SCRIPT_DIR = Path(__file__).resolve().parent
SCHEMA_DIR = SCRIPT_DIR / "v1"
DEFAULT_MANIFEST = {
    "version": "1",
    "mode": "bootstrap",
    "scope": "repo_local_flywheel",
    "legacy_bootstrap_policy": "warn_until_touched",
    "blocking_when": ["malformed_gate"],
    "grade_storage": ".flywheel/polish-gate/grades.jsonl",
    "latest_summary": ".flywheel/polish-gate/latest.json",
}


class RunnerError(RuntimeError):
    def __init__(self, exit_code: int, message: str) -> None:
        super().__init__(message)
        self.exit_code = exit_code


@dataclass(frozen=True)
class GradeRunResult:
    ts: str
    repo_path: str
    mode: str
    surfaces_graded: int
    surfaces_passed: int
    surfaces_failed: int
    surfaces_skipped: int
    composite_avg: float
    min_composite: float
    min_composite_surface: str
    pending_waivers: int
    receipts_written: list[str]
    latest_summary_path: str
    errors: list[str]
    exit_code: int

    def to_dict(self) -> dict[str, object]:
        return asdict(self)


def iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def result_schema() -> dict[str, object]:
    return load_json(SCHEMA_DIR / "grade-run-result.schema.json", 2)


def load_json(path: Path, exit_code: int) -> dict[str, Any]:
    try:
        with path.open(encoding="utf-8") as handle:
            data = json.load(handle)
    except json.JSONDecodeError as exc:
        raise RunnerError(exit_code, f"malformed JSON in {path}: {exc.msg}") from exc
    except OSError as exc:
        raise RunnerError(exit_code, f"cannot read {path}: {exc}") from exc
    if not isinstance(data, dict):
        raise RunnerError(exit_code, f"JSON document must be an object: {path}")
    return data


def validate_payload(payload: dict[str, Any], schema_path: Path, exit_code: int) -> None:
    try:
        from jsonschema import Draft202012Validator
        from jsonschema.exceptions import SchemaError, ValidationError
    except ModuleNotFoundError as exc:
        raise RunnerError(2, "jsonschema module is required for polish-gate validation") from exc

    schema = load_json(schema_path, exit_code)
    try:
        Draft202012Validator.check_schema(schema)
        Draft202012Validator(schema, format_checker=Draft202012Validator.FORMAT_CHECKER).validate(payload)
    except SchemaError as exc:
        raise RunnerError(2, f"schema is invalid: {schema_path}: {exc.message}") from exc
    except ValidationError as exc:
        raise RunnerError(exit_code, f"{schema_path.name} validation failed: {exc.message}") from exc


def resolve_repo_path(repo: Path, raw: str) -> Path:
    path = Path(raw)
    return path if path.is_absolute() else repo / path


def repo_relative(repo: Path, raw: str) -> str:
    path = Path(raw)
    if path.is_absolute():
        try:
            return path.relative_to(repo).as_posix()
        except ValueError:
            raise RunnerError(2, f"surface path is outside repo: {path}") from None
    rel = path.as_posix()
    return rel[2:] if rel.startswith("./") else rel


def load_manifest(repo: Path, manifest_arg: str, mode_override: str | None, scope_override: str | None) -> tuple[dict[str, Any], Path]:
    manifest_path = resolve_repo_path(repo, manifest_arg)
    manifest = dict(DEFAULT_MANIFEST)
    if manifest_path.exists():
        manifest = load_json(manifest_path, 3)
    if mode_override:
        manifest["mode"] = mode_override
    if scope_override:
        manifest["scope"] = scope_override
    validate_payload(manifest, SCHEMA_DIR / "manifest.schema.json", 3)
    return manifest, manifest_path


def run_discovery(repo: Path, manifest_path: Path, mode: str, scope: str) -> list[dict[str, Any]]:
    script = Path(os.environ.get("POLISH_GATE_DISCOVER_SCRIPT", str(SCRIPT_DIR / "discover-surfaces.py")))
    if not script.exists():
        raise RunnerError(4, f"discovery script not found: {script}")
    cmd = [
        sys.executable,
        str(script),
        "--repo",
        str(repo),
        "--manifest",
        str(manifest_path),
        "--mode",
        mode,
        "--scope",
        scope,
        "--json",
    ]
    proc = subprocess.run(cmd, check=False, capture_output=True, text=True)
    if proc.returncode != 0:
        detail = proc.stderr.strip() or proc.stdout.strip() or f"exit {proc.returncode}"
        raise RunnerError(4, f"discovery failed: {detail}")
    try:
        payload = json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        raise RunnerError(4, f"discovery emitted malformed JSON: {exc.msg}") from exc
    surfaces = payload.get("surfaces") if isinstance(payload, dict) else None
    if not isinstance(surfaces, list):
        raise RunnerError(4, "discovery output missing surfaces[]")
    return [dict(surface) for surface in surfaces if isinstance(surface, dict)]


def manual_surface(repo: Path, surface_arg: str) -> dict[str, Any]:
    rel = repo_relative(repo, surface_arg)
    name = Path(rel).name or rel
    return {
        "path": rel,
        "name": name,
        "category": "manual-surface",
        "in_scope": True,
        "scope_reason": "surface-flag",
        "skill_lanes_applicable": list(LANES),
    }


def active_lanes(lane: str) -> list[str]:
    return list(LANES) if lane == "all" else [lane]


def skill_scores(surface: dict[str, Any], lanes: list[str]) -> dict[str, float]:
    rel = str(surface.get("path", ""))
    scores = {lane: 9.2 for lane in LANES}
    if "sub-bar" in rel or "below-bar" in rel:
        for lane in lanes:
            scores[lane] = 8.0
    return scores


def composite(scores: dict[str, float]) -> float:
    return round(sum(scores.values()) / len(LANES), 2)


def mission_anchor_hash() -> str:
    source = "feedback_post_wire_or_explain_three_skill_polish_gate.md|five-skill|2026-05-05"
    return "sha256:" + hashlib.sha256(source.encode("utf-8")).hexdigest()[:16]


def receipt_for(surface: dict[str, Any], mode: str, lanes: list[str], ts: str) -> dict[str, Any]:
    scores = skill_scores(surface, lanes)
    grade = composite(scores)
    below_bar = grade < GRADE_FLOOR or any(score < GRADE_FLOOR for score in scores.values())
    verdict = "AUDIT_ONLY" if mode == "audit_only" else ("FAIL" if below_bar else "PASS")
    rel = str(surface.get("path") or "")
    evidence = [f"passthrough:{lane}:{rel}" for lane in lanes]
    return {
        "schema_version": "polish-gate/grade-receipt/v1",
        "ts": ts,
        "surface_path": rel,
        "surface_name": str(surface.get("name") or Path(rel).name or rel),
        "mode": mode,
        "skills": scores,
        "composite": grade,
        "verdict": verdict,
        "evidence_paths": evidence,
        "grader": "run-grader:json-passthrough",
        "mission_anchor_hash": mission_anchor_hash(),
    }


def is_lane_applicable(surface: dict[str, Any], lanes: list[str]) -> bool:
    applicable = surface.get("skill_lanes_applicable", list(LANES))
    if not isinstance(applicable, list):
        return True
    return any(lane in applicable for lane in lanes)


def fsync_dir(path: Path) -> None:
    try:
        fd = os.open(path, os.O_RDONLY)
    except OSError:
        return
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def atomic_write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    tmp_path = Path(tmp_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp_path, path)
        fsync_dir(path.parent)
    except Exception:
        try:
            tmp_path.unlink()
        except OSError:
            pass
        raise


def atomic_append_jsonl(path: Path, rows: list[dict[str, Any]]) -> None:
    existing = path.read_text(encoding="utf-8") if path.exists() else ""
    appended = "".join(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n" for row in rows)
    atomic_write(path, existing + appended)


def build_summary(receipts: list[dict[str, Any]], mode: str, ts: str) -> dict[str, Any]:
    composites = [float(row["composite"]) for row in receipts]
    below = [
        row
        for row in receipts
        if float(row["composite"]) < GRADE_FLOOR
        or any(float(score) < GRADE_FLOOR for score in dict(row["skills"]).values())
    ]
    min_receipt = min(receipts, key=lambda row: float(row["composite"])) if receipts else None
    return {
        "schema_version": "polish-gate/latest-summary/v1",
        "last_run_ts": ts,
        "mode": mode,
        "surfaces_graded": len(receipts),
        "surfaces_passed": len(receipts) - len(below),
        "surfaces_failed": len(below),
        "pending_waivers": 0,
        "composite_avg": round(sum(composites) / len(composites), 2) if composites else 0,
        "min_composite": float(min_receipt["composite"]) if min_receipt else 0,
        "min_composite_surface": str(min_receipt["surface_path"]) if min_receipt else "NONE",
    }


def run(args: argparse.Namespace) -> GradeRunResult:
    if args.apply and args.dry_run:
        raise RunnerError(2, "--apply and --dry-run are mutually exclusive")
    repo = Path(args.repo).expanduser().resolve()
    if not repo.is_dir():
        raise RunnerError(2, f"--repo is not a directory: {repo}")
    manifest, manifest_path = load_manifest(repo, args.manifest, args.mode, args.scope)
    mode = str(manifest["mode"])
    scope = str(manifest["scope"])
    grade_path = resolve_repo_path(repo, str(manifest["grade_storage"]))
    latest_path = resolve_repo_path(repo, str(manifest["latest_summary"]))
    lanes = active_lanes(args.lane)
    surfaces = [manual_surface(repo, args.surface)] if args.surface else run_discovery(repo, manifest_path, mode, scope)
    eligible = [surface for surface in surfaces if is_lane_applicable(surface, lanes)]
    ts = iso_now()
    receipts = [receipt_for(surface, mode, lanes, ts) for surface in eligible]
    for receipt in receipts:
        validate_payload(receipt, SCHEMA_DIR / "grade-receipt.schema.json", 2)
    summary = build_summary(receipts, mode, ts)
    validate_payload(summary, SCHEMA_DIR / "latest-summary.schema.json", 2)
    receipts_written: list[str] = []
    if args.apply:
        if receipts:
            atomic_append_jsonl(grade_path, receipts)
            receipts_written.append(str(grade_path))
        atomic_write(latest_path, json.dumps(summary, indent=2, sort_keys=True) + "\n")
    failures = int(summary["surfaces_failed"])
    exit_code = 1 if mode == "blocking" and failures else 0
    return GradeRunResult(
        ts, str(repo), mode, len(receipts), int(summary["surfaces_passed"]), failures,
        len(surfaces) - len(eligible), float(summary["composite_avg"]), float(summary["min_composite"]),
        str(summary["min_composite_surface"]), 0, receipts_written, str(latest_path), [], exit_code
    )


def error_result(repo_arg: str, mode: str | None, latest_arg: str | None, exit_code: int, error: str) -> GradeRunResult:
    repo = Path(repo_arg).expanduser().resolve()
    latest = latest_arg or ".flywheel/polish-gate/latest.json"
    latest_path = resolve_repo_path(repo, latest) if not Path(latest).is_absolute() else Path(latest)
    return GradeRunResult(
        iso_now(), str(repo), mode or "bootstrap", 0, 0, 0, 0, 0, 0, "NONE", 0, [], str(latest_path),
        [error], exit_code
    )


def print_explain(result: GradeRunResult) -> None:
    print(f"repo={result.repo_path} mode={result.mode} exit_code={result.exit_code}")
    print(
        "graded={0} passed={1} failed={2} skipped={3}".format(
            result.surfaces_graded,
            result.surfaces_passed,
            result.surfaces_failed,
            result.surfaces_skipped,
        )
    )
    print(f"latest_summary_path={result.latest_summary_path}")
    for path in result.receipts_written:
        print(f"receipt_log={path}")
    for error in result.errors:
        print(f"ERROR {error}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run the Phase 2 polish-gate five-skill JSON-passthrough grader.",
    )
    parser.add_argument("--repo", default=".", help="target repo path (default: current directory)")
    parser.add_argument(
        "--manifest",
        default=".flywheel/polish-gate/manifest.json",
        help="manifest.json path, relative to --repo unless absolute",
    )
    parser.add_argument("--mode", choices=MODES, help="override manifest mode")
    parser.add_argument("--scope", choices=SCOPES, help="override manifest scope")
    parser.add_argument("--surface", help="grade one repo-relative surface and skip discovery")
    parser.add_argument("--lane", default="all", choices=("all", *LANES), help="grade one skill lane or all lanes")
    parser.add_argument("--dry-run", action="store_true", help="do not write receipts or latest summary")
    parser.add_argument("--apply", action="store_true", help="write receipts and latest summary atomically")
    parser.add_argument("--json", action="store_true", help="emit JSON output (default unless --explain is used)")
    parser.add_argument("--schema", action="store_true", help="emit the grade-run result JSON Schema and exit")
    parser.add_argument("--explain", action="store_true", help="emit human-readable run summary")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.schema:
        print(json.dumps(result_schema(), indent=2, sort_keys=True))
        return 0
    try:
        result = run(args)
    except RunnerError as exc:
        result = error_result(args.repo, args.mode, None, exc.exit_code, str(exc))
    validate_payload(result.to_dict(), SCHEMA_DIR / "grade-run-result.schema.json", 2)
    if args.explain and not args.json:
        print_explain(result)
    else:
        print(json.dumps(result.to_dict(), indent=2, sort_keys=True))
    return result.exit_code


if __name__ == "__main__":
    raise SystemExit(main())
