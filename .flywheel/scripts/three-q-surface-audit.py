#!/usr/bin/env python3
"""Audit flywheel surfaces against the three-question validation contract."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shlex
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "three-q-surface-audit/v1"
REGISTRY_VERSION = "three-q-surface-registry/v1"
DEFAULT_REGISTRY = ".flywheel/three-q-surface-registry/v1/registry.json"
DEFAULT_RECEIPT_DIR = ".flywheel/validation-receipts"
Q_FIELDS = ("q1_validated", "q2_documented", "q3_surfaced")
RUNTIME_SPLIT_REQUIRED = {"claude", "codex"}


def utc_now() -> datetime:
    return datetime.now(timezone.utc).replace(microsecond=0)


def parse_ts(value: Any) -> datetime | None:
    if not value:
        return None
    text = str(value)
    try:
        if text.endswith("Z"):
            text = text[:-1] + "+00:00"
        parsed = datetime.fromisoformat(text)
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=timezone.utc)
        return parsed.astimezone(timezone.utc)
    except Exception:
        return None


def ts_text(value: datetime | None) -> str | None:
    if value is None:
        return None
    return value.astimezone(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def read_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        raise SystemExit(f"invalid registry JSON: {path}: {exc}") from exc
    if not isinstance(data, dict):
        raise SystemExit(f"invalid registry root: {path}: expected object")
    return data


def resolve_path(repo: Path, path_text: str) -> Path:
    expanded = os.path.expanduser(path_text)
    path = Path(expanded)
    if not path.is_absolute():
        path = repo / path
    return path


def evidence_exists(repo: Path, ref: Any, *, run_commands: bool) -> tuple[bool, str | None]:
    if isinstance(ref, dict):
        ref_type = str(ref.get("type") or "")
        value = str(ref.get("ref") or "")
        if ref_type:
            ref_text = f"{ref_type}:{value}"
        else:
            ref_text = value
    else:
        ref_text = str(ref)
    if not ref_text:
        return False, "empty_evidence_ref"
    if ref_text.startswith("runtime:"):
        parts = ref_text.split(":", 3)
        if len(parts) == 4:
            return evidence_exists(repo, f"{parts[2]}:{parts[3]}", run_commands=run_commands)
        return False, "invalid_runtime_evidence_ref"
    if ref_text.startswith("path:"):
        path = resolve_path(repo, ref_text.removeprefix("path:"))
        return path.exists(), None if path.exists() else f"missing_path:{path}"
    if ref_text.startswith("memory:"):
        path = resolve_path(repo, ref_text.removeprefix("memory:"))
        return path.exists(), None if path.exists() else f"missing_memory:{path}"
    if ref_text.startswith("command:"):
        command = ref_text.removeprefix("command:").strip()
        if not command:
            return False, "empty_command_ref"
        if not run_commands:
            return True, None
        try:
            proc = subprocess.run(
                shlex.split(command),
                cwd=str(repo),
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=10,
                check=False,
            )
        except Exception as exc:
            return False, f"command_error:{exc}"
        return proc.returncode == 0, None if proc.returncode == 0 else f"command_failed:{command}"
    if ref_text.startswith(("bead:", "dispatch-log:", "mcp:", "agent-mail:", "hook:", "launchd:", "manual:", "url:")):
        return True, None
    path = resolve_path(repo, ref_text)
    return path.exists(), None if path.exists() else f"missing_path:{path}"


def q_obj(surface: dict[str, Any], field: str) -> dict[str, Any]:
    raw = surface.get(field)
    if isinstance(raw, dict):
        return raw
    if raw is True:
        return {"state": "pass", "evidence_refs": []}
    if raw is False:
        return {"state": "fail", "evidence_refs": []}
    if raw is None:
        return {"state": "unknown", "evidence_refs": []}
    return {"state": str(raw), "evidence_refs": []}


def evidence_list(q: dict[str, Any]) -> list[Any]:
    refs = q.get("evidence_refs")
    if isinstance(refs, list):
        return refs
    if refs:
        return [refs]
    return []


def runtime_evidence(q: dict[str, Any], runtime: str) -> list[Any]:
    runtime_map = q.get("runtime_evidence")
    if not isinstance(runtime_map, dict):
        return []
    refs = runtime_map.get(runtime)
    if isinstance(refs, list):
        return refs
    if refs:
        return [refs]
    return []


def has_automation_or_reason(surface: dict[str, Any]) -> bool:
    if str(surface.get("manual_or_external_reason") or "").strip():
        return True
    if str(surface.get("automated_probe") or "").strip():
        return True
    for field in Q_FIELDS:
        q = q_obj(surface, field)
        if str(q.get("probe") or "").strip():
            return True
    return False


def evaluate_surface(repo: Path, surface: dict[str, Any], *, now: datetime, stale_days: int, run_commands: bool) -> dict[str, Any]:
    runtime_scope = surface.get("runtime_scope") or ["all"]
    if isinstance(runtime_scope, str):
        runtime_scope = [runtime_scope]
    runtime_scope = [str(item) for item in runtime_scope]
    required = bool(surface.get("required", True))
    manual_reason = str(surface.get("manual_or_external_reason") or "").strip() or None
    automated_probe = str(surface.get("automated_probe") or "").strip() or None
    last_checked = parse_ts(surface.get("last_checked_ts"))
    stale = False
    if last_checked is None:
        stale = True
    elif stale_days >= 0 and (now - last_checked).days > stale_days:
        stale = True

    q_results: dict[str, dict[str, Any]] = {}
    missing_reasons: list[str] = []
    missing_refs: list[str] = []
    runtime_gaps: list[str] = []

    for field in Q_FIELDS:
        q = q_obj(surface, field)
        state = str(q.get("state") or "unknown").lower()
        refs = evidence_list(q)
        evidence_errors: list[str] = []
        checked_refs = 0
        for ref in refs:
            checked_refs += 1
            ok, reason = evidence_exists(repo, ref, run_commands=run_commands)
            if not ok:
                evidence_errors.append(reason or f"missing_ref:{ref}")
        runtime_checked: dict[str, list[str]] = {}
        if field == "q1_validated" and RUNTIME_SPLIT_REQUIRED.issubset(set(runtime_scope)):
            for runtime in sorted(RUNTIME_SPLIT_REQUIRED):
                runtime_refs = runtime_evidence(q, runtime)
                runtime_checked[runtime] = []
                if not runtime_refs:
                    runtime_gaps.append(runtime)
                    runtime_checked[runtime].append("missing_runtime_evidence")
                    continue
                for ref in runtime_refs:
                    checked_refs += 1
                    ok, reason = evidence_exists(repo, ref, run_commands=run_commands)
                    if not ok:
                        runtime_gaps.append(runtime)
                        runtime_checked[runtime].append(reason or f"missing_runtime_ref:{ref}")
        missing = state != "pass" or bool(evidence_errors)
        if state == "pass" and checked_refs == 0 and not manual_reason and not q.get("probe"):
            missing = True
            evidence_errors.append("no_evidence_or_manual_reason")
        if field == "q1_validated" and runtime_gaps:
            missing = True
        if stale and required:
            missing = True
            evidence_errors.append("stale_last_checked_ts")
        if missing:
            missing_reasons.append(field)
            missing_refs.extend(evidence_errors)
        q_results[field] = {
            "state": state,
            "missing": missing,
            "evidence_refs_count": checked_refs,
            "evidence_errors": evidence_errors,
            "runtime_checked": runtime_checked,
        }

    if not has_automation_or_reason(surface):
        missing_reasons.append("probe_or_manual_reason")
    row_status = "pass"
    if required and missing_reasons:
        row_status = "fail"
    elif missing_reasons:
        row_status = "warn"

    return {
        "surface_id": str(surface.get("surface_id") or ""),
        "category": str(surface.get("category") or ""),
        "owner": str(surface.get("owner") or ""),
        "owner_bead": str(surface.get("owner_bead") or ""),
        "repo": str(surface.get("repo") or ""),
        "runtime_scope": runtime_scope,
        "required": required,
        "manual_or_external_reason": manual_reason,
        "automated_probe": automated_probe,
        "last_checked_ts": ts_text(last_checked),
        "stale": stale,
        "q1_missing": q_results["q1_validated"]["missing"],
        "q2_missing": q_results["q2_documented"]["missing"],
        "q3_missing": q_results["q3_surfaced"]["missing"],
        "q_results": q_results,
        "runtime_specific_gap": sorted(set(runtime_gaps)),
        "missing_evidence_refs": sorted(set(missing_refs)),
        "gap_reason": ",".join(sorted(set(missing_reasons))) if missing_reasons else None,
        "status": row_status,
        "evidence_refs": surface.get("evidence_refs") or [],
    }


def build_payload(args: argparse.Namespace) -> dict[str, Any]:
    repo = Path(args.repo).expanduser().resolve()
    registry_path = resolve_path(repo, args.registry)
    registry = read_json(registry_path)
    surfaces = registry.get("surfaces")
    if not isinstance(surfaces, list):
        raise SystemExit("registry missing surfaces[]")
    now = parse_ts(args.now) if args.now else utc_now()
    assert now is not None
    rows = []
    for surface in surfaces:
        if not isinstance(surface, dict):
            continue
        if args.category and str(surface.get("category")) != args.category:
            continue
        if args.owner and str(surface.get("owner_bead") or surface.get("owner")) != args.owner:
            continue
        rows.append(evaluate_surface(repo, surface, now=now, stale_days=args.stale_days, run_commands=args.run_commands))
    rows.sort(key=lambda row: row["surface_id"])
    failing = [row for row in rows if row["required"] and row["status"] == "fail"]
    categories = sorted({row["category"] for row in rows if row["category"]})
    top_failing = [
        {
            "surface_id": row["surface_id"],
            "category": row["category"],
            "q1_missing": row["q1_missing"],
            "q2_missing": row["q2_missing"],
            "q3_missing": row["q3_missing"],
            "gap_reason": row["gap_reason"],
            "runtime_specific_gap": row["runtime_specific_gap"],
        }
        for row in failing[:10]
    ]
    registry_hash = hashlib.sha256(json.dumps(rows, sort_keys=True).encode("utf-8")).hexdigest()[:16]
    status = "fail" if failing else "pass"
    payload = {
        "schema_version": SCHEMA_VERSION,
        "registry_schema_version": str(registry.get("schema_version") or ""),
        "registry_path": str(registry_path),
        "checked_at": ts_text(now),
        "checked_surfaces_count": len(rows),
        "categories_count": len(categories),
        "categories": categories,
        "surfaces_unwired_count": len(failing),
        "three_q_unaudited_count": len(failing),
        "top_failing_surfaces": top_failing,
        "rows": rows,
        "status": status,
        "bead_promotion_required": len(failing) > 3,
        "learn_route": {
            "route": "review" if failing else "ignore",
            "reason": "three-Q surface audit found unwired surfaces" if failing else "three-Q surface audit passed",
            "dedupe_key": f"three-q:{registry_hash}",
        },
    }
    return payload


def write_receipt(repo: Path, payload: dict[str, Any], receipt_dir: Path) -> Path:
    receipt_dir.mkdir(parents=True, exist_ok=True)
    status = "fail" if payload["three_q_unaudited_count"] else "pass"
    failure_class = "unknown" if status == "fail" else None
    retry_policy = "manual" if status == "fail" else "none"
    recovery_hint = (
        "Wire the unaudited three-Q surfaces or add explicit no-touch reasons."
        if status == "fail"
        else "No recovery needed; validation passed."
    )
    receipt = {
        "schema_version": "validation-receipt/v1",
        "dispatch_id": "three-q-surface-audit",
        "callback_ref": {
            "transport": "manual_fixture",
            "session": "flywheel",
            "pane": None,
            "kind": "DONE",
            "received_at": payload["checked_at"],
            "raw_ref": f"three_q_unaudited_count={payload['three_q_unaudited_count']}",
        },
        "status": status,
        "failure_class": failure_class,
        "retry_policy": retry_policy,
        "recovery_hint": recovery_hint,
        "failure_classes": ["three_q_surface_gap"] if status == "fail" else [],
        "evidence": [{"type": "path", "ref": payload["registry_path"]}],
        "artifact_checks": [
            {
                "artifact_id": "three_q_surface_registry",
                "path": payload["registry_path"],
                "status": "exists" if Path(payload["registry_path"]).exists() else "missing",
            }
        ],
        "runtime_context": {
            "agent_context": {"status": "responsive", "probe_ref": "three-q-surface-audit", "resolved_tools": ["python3"]},
            "orchestrator_shell_context": {"status": "responsive", "probe_ref": "three-q-surface-audit", "resolved_tools": ["python3"]},
            "timeout": False,
            "timeout_seconds": 0,
            "context_drift": False,
        },
        "bead_actions": [{"action": "no_bead_reason", "reason": "three-Q audit receipt; B09 handles learn routing"}],
        "learn_route": payload["learn_route"],
        "chain_blocker": {"next_phase": None, "capacity_available": False, "chain_blocked_reason": None},
    }
    suffix = hashlib.sha256(json.dumps(receipt, sort_keys=True).encode("utf-8")).hexdigest()[:12]
    path = receipt_dir / f"three-q-surface-audit-{suffix}.json"
    path.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return path


def schema_payload() -> dict[str, Any]:
    return {
        "schema_version": REGISTRY_VERSION,
        "required_registry_fields": ["schema_version", "surfaces"],
        "required_surface_fields": [
            "surface_id",
            "category",
            "owner",
            "repo",
            "runtime_scope",
            "q1_validated",
            "q2_documented",
            "q3_surfaced",
            "evidence_refs",
            "last_checked_ts",
            "status",
            "gap_reason",
        ],
        "q_fields": list(Q_FIELDS),
        "states": ["pass", "fail", "unknown"],
        "evidence_ref_prefixes": ["path:", "memory:", "command:", "bead:", "dispatch-log:", "runtime:<runtime>:path:", "manual:"],
        "runtime_rule": "When runtime_scope includes both claude and codex, q1_validated.runtime_evidence must include both runtimes.",
    }


def examples_payload() -> dict[str, Any]:
    return {
        "complete_surface": {
            "surface_id": "example-complete",
            "category": "doctor_signals",
            "owner": "flywheel",
            "owner_bead": "flywheel-m5kg",
            "repo": "/Users/josh/Developer/flywheel",
            "runtime_scope": ["all"],
            "required": True,
            "automated_probe": "command:python3 .flywheel/scripts/three-q-surface-audit.py --json",
            "q1_validated": {"state": "pass", "evidence_refs": ["path:tests/three-q-surface-audit.sh"]},
            "q2_documented": {"state": "pass", "evidence_refs": ["path:.flywheel/three-q-surface-registry/v1/README.md"]},
            "q3_surfaced": {"state": "pass", "evidence_refs": ["path:.flywheel/canonical-paths.txt"]},
            "evidence_refs": ["path:tests/three-q-surface-audit.sh"],
            "last_checked_ts": "2026-05-04T00:00:00Z",
            "status": "active",
            "gap_reason": None,
        }
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="three-q-surface-audit.py")
    parser.add_argument("--repo", default=".")
    parser.add_argument("--registry", default=DEFAULT_REGISTRY)
    parser.add_argument("--category")
    parser.add_argument("--owner")
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--run-commands", action="store_true")
    parser.add_argument("--write-receipt", action="store_true")
    parser.add_argument("--receipt-dir", default=DEFAULT_RECEIPT_DIR)
    parser.add_argument("--stale-days", type=int, default=30)
    parser.add_argument("--now")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.schema:
        print(json.dumps(schema_payload(), indent=2, sort_keys=True))
        return 0
    if args.examples:
        print(json.dumps(examples_payload(), indent=2, sort_keys=True))
        return 0
    payload = build_payload(args)
    if args.write_receipt:
        repo = Path(args.repo).expanduser().resolve()
        receipt_dir = resolve_path(repo, args.receipt_dir)
        receipt_path = write_receipt(repo, payload, receipt_dir)
        payload["validation_receipt_path"] = str(receipt_path)
    print(json.dumps(payload, indent=2 if args.json else None, sort_keys=True))
    if args.strict and payload["three_q_unaudited_count"] > 0:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
