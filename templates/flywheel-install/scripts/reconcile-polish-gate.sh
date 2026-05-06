#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PYTHON_BIN="${PYTHON_BIN:-python3}"

exec "$PYTHON_BIN" - "$SCRIPT_DIR" "$@" <<'PY'
from __future__ import annotations

import argparse
import difflib
import json
import os
import re
import shutil
import sys
import tempfile
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

MISSION_FIELDS = (
    "polish_gate_mode",
    "polish_gate_scope",
    "polish_gate_legacy_policy",
    "polish_gate_grade_storage",
    "polish_gate_latest_summary",
)
STATE_FIELDS = (
    "polish_gate_mode_active",
    "polish_gate_last_run_ts",
    "polish_gate_surfaces_graded_count",
    "polish_gate_surfaces_passed_count",
    "polish_gate_surfaces_failed_count",
    "polish_gate_pending_waivers",
    "polish_gate_min_composite",
    "polish_gate_min_composite_surface",
)
MODES = ("bootstrap", "audit_only", "blocking")
PRIOR_STATES = ("no_polish_gate", "partial_polish_gate", "reconciled", "malformed")


class ReconcileError(RuntimeError):
    def __init__(self, exit_code: int, message: str) -> None:
        super().__init__(message)
        self.exit_code = exit_code


@dataclass(frozen=True)
class ModifiedFile:
    path: str
    backup_path: str | None


@dataclass(frozen=True)
class ReconcileResult:
    ts: str
    repo_path: str
    action: str
    prior_state: str
    target_state: str | None
    already_reconciled: bool
    files_modified: list[ModifiedFile]
    mode_applied: str | None
    manifest_validates: bool
    errors: list[str]
    diff: list[str]

    def to_dict(self) -> dict[str, Any]:
        data = asdict(self)
        data["files_modified"] = [asdict(item) for item in self.files_modified]
        return data


def iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def backup_stamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H%M%SZ")


def load_json(path: Path, exit_code: int) -> dict[str, Any]:
    try:
        with path.open(encoding="utf-8") as handle:
            data = json.load(handle)
    except json.JSONDecodeError as exc:
        raise ReconcileError(exit_code, f"malformed JSON in {path}: {exc.msg}") from exc
    except OSError as exc:
        raise ReconcileError(exit_code, f"cannot read {path}: {exc}") from exc
    if not isinstance(data, dict):
        raise ReconcileError(exit_code, f"JSON document must be an object: {path}")
    return data


def validate_manifest(payload: dict[str, Any], schema_path: Path) -> None:
    try:
        from jsonschema import Draft202012Validator
        from jsonschema.exceptions import SchemaError, ValidationError
    except ModuleNotFoundError as exc:
        raise ReconcileError(3, "jsonschema module is required for polish-gate validation") from exc

    schema = load_json(schema_path, 3)
    try:
        Draft202012Validator.check_schema(schema)
        Draft202012Validator(schema, format_checker=Draft202012Validator.FORMAT_CHECKER).validate(payload)
    except SchemaError as exc:
        raise ReconcileError(3, f"schema is invalid: {schema_path}: {exc.message}") from exc
    except ValidationError as exc:
        raise ReconcileError(3, f"polish_gate validation failed: {exc.message}") from exc


def field_value(text: str, key: str) -> str | None:
    match = re.search(rf"^{re.escape(key)}:\s*(.*?)\s*(?:#.*)?$", text, re.MULTILINE)
    return match.group(1).strip() if match else None


def field_count(text: str, fields: tuple[str, ...]) -> int:
    return sum(1 for key in fields if re.search(rf"^{re.escape(key)}:", text, re.MULTILINE))


def required_paths(repo: Path) -> dict[str, Path]:
    return {
        "mission": repo / ".flywheel" / "MISSION.md",
        "state": repo / ".flywheel" / "STATE.md",
        "loop": repo / ".flywheel" / "loop.json",
    }


def classify(repo: Path) -> tuple[str, list[str], dict[str, str], dict[str, Any] | None]:
    paths = required_paths(repo)
    errors = [f"missing {path}" for path in paths.values() if not path.exists()]
    if errors:
        return "malformed", errors, {}, None

    mission = paths["mission"].read_text(encoding="utf-8")
    state = paths["state"].read_text(encoding="utf-8")
    if not re.search(r"^## (2[.] )?Mission Anchor\s*$", mission, re.MULTILINE):
        return "malformed", ["MISSION.md missing canonical Mission Anchor section"], {}, None

    try:
        loop = load_json(paths["loop"], 3)
    except ReconcileError as exc:
        return "malformed", [str(exc)], {}, None

    mission_fields = field_count(mission, MISSION_FIELDS)
    state_fields = field_count(state, STATE_FIELDS)
    loop_has_gate = isinstance(loop.get("polish_gate"), dict)
    values = {key: value for key in MISSION_FIELDS if (value := field_value(mission, key)) is not None}

    if mission_fields == len(MISSION_FIELDS) and state_fields == len(STATE_FIELDS) and loop_has_gate:
        return "reconciled", [], values, loop
    if mission_fields or state_fields or loop_has_gate:
        return "partial_polish_gate", [], values, loop
    return "no_polish_gate", [], values, loop


def replace_or_insert_fields(text: str, fields: dict[str, str], replace: set[str], before_heading: str | None = None) -> str:
    present: set[str] = set()
    lines = text.splitlines()
    out: list[str] = []
    for line in lines:
        matched = False
        for key, value in fields.items():
            if re.match(rf"^{re.escape(key)}:", line):
                present.add(key)
                out.append(f"{key}: {value}" if key in replace else line)
                matched = True
                break
        if not matched:
            out.append(line)

    missing = [key for key in fields if key not in present]
    if not missing:
        return "\n".join(out).rstrip() + "\n"

    block = [f"{key}: {fields[key]}" for key in missing]
    insert_at = len(out)
    marker = re.compile(before_heading or r"^## ")
    for idx, line in enumerate(out):
        if marker.match(line):
            insert_at = idx
            break
    if insert_at and out[insert_at - 1].strip():
        block = [""] + block
    if insert_at < len(out) and out[insert_at].strip():
        block = block + [""]
    out[insert_at:insert_at] = block
    return "\n".join(out).rstrip() + "\n"


def ensure_section(text: str, title: str, body: str, before: str | None = None) -> str:
    if re.search(rf"^{re.escape(title)}\s*$", text, re.MULTILINE):
        return text
    section = f"\n{title}\n\n{body.rstrip()}\n"
    lines = text.rstrip().splitlines()
    insert_at = len(lines)
    if before:
        marker = re.compile(before)
        for idx, line in enumerate(lines):
            if marker.match(line):
                insert_at = idx
                break
    lines[insert_at:insert_at] = section.strip("\n").splitlines()
    return "\n".join(lines).rstrip() + "\n"


def reconcile_texts(repo: Path, defaults: dict[str, Any], mode_override: str | None) -> tuple[dict[Path, str], str, bool]:
    paths = required_paths(repo)
    mission = paths["mission"].read_text(encoding="utf-8")
    state = paths["state"].read_text(encoding="utf-8")
    loop = load_json(paths["loop"], 3)

    existing_mode = field_value(mission, "polish_gate_mode")
    mode = mode_override or existing_mode or str(defaults["mode"])
    if mode not in MODES:
        raise ReconcileError(3, f"invalid polish_gate_mode in MISSION.md: {mode}")

    manifest = dict(defaults)
    manifest["mode"] = mode
    mission_fields = {
        "polish_gate_mode": mode,
        "polish_gate_scope": str(manifest["scope"]),
        "polish_gate_legacy_policy": str(manifest["legacy_bootstrap_policy"]),
        "polish_gate_grade_storage": str(manifest["grade_storage"]),
        "polish_gate_latest_summary": str(manifest["latest_summary"]),
    }
    replace = {"polish_gate_mode"} if mode_override else set()
    mission = replace_or_insert_fields(mission, mission_fields, replace)
    mission = ensure_section(
        mission,
        "## Polish Gate",
        "\n".join(f"{key}: {value}" for key, value in mission_fields.items()),
        before=r"^## 12[.] Doctrine Compliance\s*$",
    )

    state_fields = {
        "polish_gate_mode_active": "<inherited from mission unless overridden>",
        "polish_gate_last_run_ts": "<iso or null>",
        "polish_gate_surfaces_graded_count": "0",
        "polish_gate_surfaces_passed_count": "0",
        "polish_gate_surfaces_failed_count": "0",
        "polish_gate_pending_waivers": "0",
        "polish_gate_min_composite": "null",
        "polish_gate_min_composite_surface": "null",
    }
    state = ensure_section(
        state,
        "## Polish Gate runtime",
        "\n".join(f"{key}: {value}" for key, value in state_fields.items()),
        before=r"^## Resume Context\s*$",
    )
    state = replace_or_insert_fields(state, state_fields, set(), before_heading=r"^## Resume Context\s*$")

    current_gate = loop.get("polish_gate") if isinstance(loop.get("polish_gate"), dict) else {}
    merged_gate = dict(manifest)
    merged_gate.update(current_gate)
    if mode_override or "mode" not in current_gate:
        merged_gate["mode"] = mode
    loop["polish_gate"] = merged_gate
    loop_text = json.dumps(loop, indent=2, sort_keys=False) + "\n"
    return {paths["mission"]: mission, paths["state"]: state, paths["loop"]: loop_text}, mode, True


def atomic_write(path: Path, content: str) -> None:
    fd, tmp_name = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=str(path.parent))
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp_name, path)
    finally:
        if os.path.exists(tmp_name):
            os.unlink(tmp_name)


def diff_for(path: Path, new_text: str) -> list[str]:
    old = path.read_text(encoding="utf-8").splitlines()
    new = new_text.splitlines()
    return list(difflib.unified_diff(old, new, fromfile=str(path), tofile=f"{path} (reconciled)", lineterm=""))


def apply_changes(changes: dict[Path, str], stamp: str) -> list[ModifiedFile]:
    modified: list[ModifiedFile] = []
    for path, new_text in changes.items():
        old_text = path.read_text(encoding="utf-8")
        if old_text == new_text:
            continue
        backup = path.with_name(f"{path.name}.bak.{stamp}")
        shutil.copy2(path, backup)
        atomic_write(path, new_text)
        modified.append(ModifiedFile(str(path), str(backup)))
    return modified


def rollback(repo: Path, stamp: str) -> list[ModifiedFile]:
    modified: list[ModifiedFile] = []
    for path in required_paths(repo).values():
        backup = path.with_name(f"{path.name}.bak.{stamp}")
        if not backup.exists():
            continue
        atomic_write(path, backup.read_text(encoding="utf-8"))
        modified.append(ModifiedFile(str(path), str(backup)))
    if not modified:
        raise ReconcileError(3, f"no backups found for timestamp {stamp}")
    return modified


def print_result(result: ReconcileResult, as_json: bool, explain: bool) -> None:
    if as_json:
        print(json.dumps(result.to_dict(), indent=2, sort_keys=True))
        return
    print(f"{result.action}: {result.prior_state} -> {result.target_state or 'none'}")
    if result.mode_applied:
        print(f"mode_applied: {result.mode_applied}")
    if result.files_modified:
        for item in result.files_modified:
            print(f"modified: {item.path} backup={item.backup_path}")
    if explain and result.diff:
        print("\n".join(result.diff))
    if result.errors:
        for error in result.errors:
            print(f"error: {error}", file=sys.stderr)


def main() -> int:
    script_dir = Path(sys.argv[1]).resolve()
    root = script_dir.parent
    schema_path = root / "polish-gate" / "v1" / "reconcile-output.schema.json"
    manifest_schema = root / "polish-gate" / "v1" / "manifest.schema.json"
    defaults_path = root / "polish-gate" / "fixtures" / "audit-only-mode.json"

    parser = argparse.ArgumentParser(
        prog="reconcile-polish-gate.sh",
        description="Reconcile existing flywheel installs to the polish-gate contract.",
    )
    parser.add_argument("--repo", default=".", help="target repo path")
    parser.add_argument("--detect", action="store_true", help="read-only detection")
    parser.add_argument("--dry-run", action="store_true", help="show planned changes without writing")
    parser.add_argument("--apply", action="store_true", help="write reconciled files with backup sidecars")
    parser.add_argument("--rollback", metavar="TS", help="restore MISSION/STATE/loop from .bak.<ts> sidecars")
    parser.add_argument("--mode", choices=MODES, help="override mode for missing or reconciled fields")
    parser.add_argument("--json", action="store_true", help="emit JSON")
    parser.add_argument("--explain", action="store_true", help="emit human-readable trace or diff")
    parser.add_argument("--schema", action="store_true", help="print reconcile output JSON schema")
    args = parser.parse_args(sys.argv[2:])

    if args.schema:
        print(schema_path.read_text(encoding="utf-8"), end="")
        return 0

    repo = Path(args.repo).expanduser().resolve()
    defaults = load_json(defaults_path, 3)
    action = "rollback" if args.rollback else "detect" if args.detect else "apply" if args.apply else "dry-run"
    state, errors, _values, loop = classify(repo)
    if action != "rollback" and state == "malformed":
        result = ReconcileResult(iso_now(), str(repo), action, "malformed", None, False, [], None, False, errors, [])
        print_result(result, args.json, args.explain)
        return 3

    try:
        if action == "rollback":
            modified = rollback(repo, args.rollback)
            result = ReconcileResult(iso_now(), str(repo), action, state, "rolled_back", False, modified, None, False, [], [])
            print_result(result, args.json, args.explain)
            return 0

        changes, mode, _ = reconcile_texts(repo, defaults, args.mode)
        validate_manifest(json.loads(changes[required_paths(repo)["loop"]])["polish_gate"], manifest_schema)
        planned_diff = [line for path, text in changes.items() for line in diff_for(path, text)]

        if action == "detect":
            result = ReconcileResult(iso_now(), str(repo), action, state, "reconciled", state == "reconciled", [], mode, True, [], [])
            print_result(result, args.json, args.explain)
            return 0 if state == "reconciled" else 2
        if action == "apply":
            modified = apply_changes(changes, backup_stamp())
            result = ReconcileResult(iso_now(), str(repo), action, state, "reconciled", state == "reconciled", modified, mode, True, [], [])
            print_result(result, args.json, args.explain)
            return 0

        result = ReconcileResult(iso_now(), str(repo), action, state, "reconciled", state == "reconciled", [], mode, True, [], planned_diff)
        print_result(result, args.json, args.explain)
        return 0
    except ReconcileError as exc:
        result = ReconcileResult(iso_now(), str(repo), action, state if state in PRIOR_STATES else "malformed", None, False, [], None, False, [str(exc)], [])
        print_result(result, args.json, args.explain)
        return exc.exit_code


if __name__ == "__main__":
    raise SystemExit(main())
PY
