#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

SCHEMA_VERSION = "ntm-spawn-templates-versioned/v1"
INVARIANT_ID = "ntm:spawn-templates-versioned"
DEFAULT_TEMPLATE_DIR = Path.home() / ".config/ntm/spawn-templates"
DEFAULT_REGISTRY = Path(__file__).resolve().parents[1] / "ntm-spawn-template-registry.json"
DEFAULT_NTM = Path.home() / ".local/bin/ntm"


def now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def run_ntm_version(ntm_bin: Path) -> dict[str, Any]:
    if not ntm_bin.exists():
        return {
            "status": "missing",
            "version": None,
            "commit": None,
            "built_at": None,
            "path": str(ntm_bin),
            "warnings": ["ntm_binary_missing"],
        }
    proc = subprocess.run(
        [str(ntm_bin), "version", "--json"],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=8,
        check=False,
    )
    if proc.returncode == 0:
        try:
            payload = json.loads(proc.stdout)
            if isinstance(payload, dict):
                return {
                    "status": "ok",
                    "version": payload.get("version"),
                    "commit": payload.get("commit"),
                    "built_at": payload.get("built_at"),
                    "go_version": payload.get("go_version"),
                    "platform": payload.get("platform"),
                    "path": str(ntm_bin),
                    "raw": payload,
                    "warnings": [],
                }
        except json.JSONDecodeError:
            pass
    return {
        "status": "unparseable",
        "version": None,
        "commit": None,
        "built_at": None,
        "path": str(ntm_bin),
        "exit_code": proc.returncode,
        "stderr": proc.stderr.strip()[:500],
        "warnings": ["ntm_version_unparseable"],
    }


def collect_templates(template_dir: Path) -> dict[str, Any]:
    if not template_dir.exists():
        return {
            "template_dir": str(template_dir),
            "template_dir_exists": False,
            "template_count": 0,
            "templates": [],
        }
    templates: list[dict[str, Any]] = []
    for path in sorted(p for p in template_dir.rglob("*") if p.is_file()):
        stat = path.stat()
        templates.append(
            {
                "name": str(path.relative_to(template_dir)),
                "path": str(path),
                "sha256": sha256_file(path),
                "size_bytes": stat.st_size,
                "mtime_epoch": int(stat.st_mtime),
            }
        )
    return {
        "template_dir": str(template_dir),
        "template_dir_exists": True,
        "template_count": len(templates),
        "templates": templates,
    }


def snapshot(template_dir: Path, ntm_bin: Path) -> dict[str, Any]:
    version = run_ntm_version(ntm_bin)
    templates = collect_templates(template_dir)
    return {
        "schema_version": SCHEMA_VERSION,
        "invariant_id": INVARIANT_ID,
        "generated_at": now_iso(),
        "ntm": version,
        "template_dir": templates["template_dir"],
        "template_dir_exists": templates["template_dir_exists"],
        "template_count": templates["template_count"],
        "templates": templates["templates"],
    }


def load_registry(path: Path) -> tuple[dict[str, Any] | None, str | None]:
    if not path.exists():
        return None, "registry_missing"
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None, "registry_invalid_json"
    if not isinstance(payload, dict):
        return None, "registry_not_object"
    return payload, None


def compare(current: dict[str, Any], registry: dict[str, Any] | None, registry_error: str | None) -> dict[str, Any]:
    findings: list[dict[str, Any]] = []
    current_templates = {row["name"]: row for row in current.get("templates", [])}
    registry_templates = {row["name"]: row for row in (registry or {}).get("templates", [])}

    if registry_error:
        findings.append(
            {
                "code": registry_error,
                "message": "template registry is missing or unreadable",
                "action": "review current template matrix, then run registry --apply with an idempotency key",
            }
        )

    if not current.get("template_dir_exists"):
        findings.append(
            {
                "code": "template_dir_missing",
                "message": "NTM spawn-template directory is absent",
                "action": "create or regenerate ~/.config/ntm/spawn-templates before relying on baked worker templates",
            }
        )

    if registry:
        current_ntm = current.get("ntm") or {}
        registry_ntm = registry.get("ntm") or {}
        for key in ("version", "commit", "built_at"):
            if (current_ntm.get(key) or None) != (registry_ntm.get(key) or None):
                findings.append(
                    {
                        "code": "ntm_version_drift",
                        "field": key,
                        "expected": registry_ntm.get(key),
                        "actual": current_ntm.get(key),
                        "action": "review template compatibility with the current ntm version, then refresh the registry",
                    }
                )
        for name in sorted(set(current_templates) | set(registry_templates)):
            current_row = current_templates.get(name)
            registry_row = registry_templates.get(name)
            if current_row is None:
                findings.append(
                    {
                        "code": "template_missing",
                        "template": name,
                        "expected_sha256": registry_row.get("sha256") if registry_row else None,
                        "action": "restore/regenerate the missing template or refresh the registry after review",
                    }
                )
            elif registry_row is None:
                findings.append(
                    {
                        "code": "template_unregistered",
                        "template": name,
                        "actual_sha256": current_row.get("sha256"),
                        "action": "review the new template and refresh the registry",
                    }
                )
            elif current_row.get("sha256") != registry_row.get("sha256"):
                findings.append(
                    {
                        "code": "template_sha_drift",
                        "template": name,
                        "expected_sha256": registry_row.get("sha256"),
                        "actual_sha256": current_row.get("sha256"),
                        "action": "diff the template, then intentionally regenerate or refresh the registry",
                    }
                )

    status = "pass" if not findings else "warn"
    return {
        "status": status,
        "ok": status == "pass",
        "warnings": findings,
        "warning_count": len(findings),
    }


def doctor(args: argparse.Namespace) -> dict[str, Any]:
    current = snapshot(args.template_dir, args.ntm_bin)
    registry, registry_error = load_registry(args.registry)
    comparison = compare(current, registry, registry_error)
    return {
        "schema_version": SCHEMA_VERSION,
        "invariant_id": INVARIANT_ID,
        "status": comparison["status"],
        "ok": comparison["ok"],
        "checked_at": now_iso(),
        "registry_path": str(args.registry),
        "template_dir": str(args.template_dir),
        "ntm": current["ntm"],
        "template_sha_version_matrix": {
            "current": {
                "ntm": current["ntm"],
                "template_dir_exists": current["template_dir_exists"],
                "template_count": current["template_count"],
                "templates": current["templates"],
            },
            "registry": registry,
        },
        "warnings": comparison["warnings"],
        "warning_count": comparison["warning_count"],
        "action": "ready" if comparison["ok"] else "inspect_ntm_spawn_template_version_drift",
    }


def write_json_atomic(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=str(path.parent))
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, sort_keys=True, indent=2)
        handle.write("\n")
    os.replace(tmp_name, path)


def registry(args: argparse.Namespace) -> dict[str, Any]:
    payload = snapshot(args.template_dir, args.ntm_bin)
    result = {
        "schema_version": SCHEMA_VERSION,
        "invariant_id": INVARIANT_ID,
        "mode": "registry",
        "registry_path": str(args.registry),
        "dry_run": args.dry_run,
        "apply": args.apply,
        "idempotency_key": args.idempotency_key,
        "snapshot": payload,
        "status": "dry_run",
    }
    if args.apply:
        if not args.idempotency_key:
            raise SystemExit("ERR: registry --apply requires --idempotency-key")
        write_json_atomic(args.registry, payload)
        result["status"] = "written"
    return result


def schema() -> dict[str, Any]:
    return {
        "schema_version": f"{SCHEMA_VERSION}.schema",
        "required": [
            "schema_version",
            "invariant_id",
            "status",
            "ntm",
            "template_sha_version_matrix",
            "warnings",
        ],
        "invariant_id": INVARIANT_ID,
    }


def examples() -> dict[str, Any]:
    return {
        "schema_version": f"{SCHEMA_VERSION}.examples",
        "examples": [
            ".flywheel/scripts/ntm-spawn-templates-versioned.py doctor --json",
            ".flywheel/scripts/ntm-spawn-templates-versioned.py registry --dry-run --json",
            ".flywheel/scripts/ntm-spawn-templates-versioned.py registry --apply --idempotency-key reviewed-YYYYMMDD --json",
        ],
    }


def capabilities() -> dict[str, Any]:
    return {
        "schema_version": f"{SCHEMA_VERSION}.capabilities",
        "command": "capabilities",
        "contract_version": "1",
        "features": ["json_output", "doctor", "registry_dry_run", "idempotent_apply", "robot_docs"],
        "commands": {
            "doctor": {"command": "ntm-spawn-templates-versioned.py doctor --json", "read_only": True},
            "registry_dry_run": {"command": "ntm-spawn-templates-versioned.py registry --dry-run --json", "read_only": True},
            "registry_apply": {"command": "ntm-spawn-templates-versioned.py registry --apply --idempotency-key KEY --json", "read_only": False},
            "robot_docs": {"command": "ntm-spawn-templates-versioned.py robot-docs --json", "read_only": True},
        },
        "exit_codes": {"0": "success", "1": "runtime error", "2": "usage error"},
        "env_vars": {
            "NTM_SPAWN_TEMPLATES_DIR": "override template directory",
            "NTM_SPAWN_TEMPLATE_REGISTRY": "override registry path",
            "NTM_BIN": "override ntm binary",
        },
    }


def robot_docs() -> dict[str, Any]:
    return {
        "schema_version": f"{SCHEMA_VERSION}.robot_docs",
        "command": "robot-docs",
        "guide": [
            "Discover: ntm-spawn-templates-versioned.py capabilities --json",
            "Diagnose drift: ntm-spawn-templates-versioned.py doctor --json",
            "Preview registry refresh: ntm-spawn-templates-versioned.py registry --dry-run --json",
            "Apply only after review: ntm-spawn-templates-versioned.py registry --apply --idempotency-key KEY --json",
        ],
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Version/hash doctor for NTM spawn templates")
    parser.add_argument("command", nargs="?", default="doctor")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--health", action="store_true")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--template-dir", type=Path, default=Path(os.environ.get("NTM_SPAWN_TEMPLATES_DIR", DEFAULT_TEMPLATE_DIR)))
    parser.add_argument("--registry", type=Path, default=Path(os.environ.get("NTM_SPAWN_TEMPLATE_REGISTRY", DEFAULT_REGISTRY)))
    parser.add_argument("--ntm-bin", type=Path, default=Path(os.environ.get("NTM_BIN", DEFAULT_NTM)))
    parser.add_argument("--dry-run", action="store_true", default=True)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--idempotency-key")
    return parser


def emit(payload: dict[str, Any], json_mode: bool) -> None:
    if json_mode:
        print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
        return
    print(f"{payload.get('status', 'ok')}: {payload.get('action', payload.get('mode', 'doctor'))}")


def main(argv: list[str]) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.doctor or args.health:
        args.command = "doctor"
    elif args.schema:
        args.command = "schema"
    elif args.info:
        args.command = "capabilities"
    elif args.examples:
        args.command = "examples"
    if args.apply:
        args.dry_run = False

    if args.command in ("doctor", "health"):
        payload = doctor(args)
    elif args.command == "registry":
        payload = registry(args)
    elif args.command == "schema":
        payload = schema()
    elif args.command in ("capabilities", "capability"):
        payload = capabilities()
    elif args.command in ("robot-docs", "robot-docs-guide"):
        payload = robot_docs()
    elif args.command in ("examples", "info", "quickstart"):
        payload = examples()
    elif args.command in ("audit", "validate", "why"):
        payload = doctor(args)
    else:
        parser.error(f"unknown command: {args.command}")
    emit(payload, args.json)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except SystemExit:
        raise
    except Exception as exc:
        print(json.dumps({"schema_version": SCHEMA_VERSION, "status": "error", "error": str(exc)}), file=sys.stderr)
        raise SystemExit(1)
