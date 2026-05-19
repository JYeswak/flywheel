from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

ZERO_HASH = "0" * 64


def canonical_json(obj: dict[str, Any]) -> str:
    return json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=True)


def row_checksum(row: dict[str, Any]) -> str:
    shadow = dict(row)
    shadow.pop("checksum", None)
    return hashlib.sha256(canonical_json(shadow).encode("utf-8")).hexdigest()


def add_output_flags(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--json", action="store_true", default=argparse.SUPPRESS)
    parser.add_argument("--no-color", action="store_true", default=argparse.SUPPRESS)
    parser.add_argument("--no-emoji", action="store_true", default=argparse.SUPPRESS)
    parser.add_argument("--width", type=int, default=argparse.SUPPRESS)


def completion_script(*, prog: str, commands: str, flags: str, shell: str) -> str:
    if shell == "zsh":
        return "\n".join([
            f"#compdef {prog}",
            "local -a commands",
            f"commands=({commands})",
            "_describe 'command' commands",
            f"compadd -- {flags}",
        ])
    return f"complete -W '{commands} {flags}' {prog}"


def read_jsonl(path: Path, *, error_type: type[ValueError] = ValueError) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    rows: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as handle:
        for line_no, line in enumerate(handle, 1):
            text = line.strip()
            if not text:
                continue
            try:
                value = json.loads(text)
            except json.JSONDecodeError as exc:
                raise error_type("ledger_parse_failed", f"{path}:{line_no}: {exc}") from exc
            if isinstance(value, dict):
                rows.append(value)
    return rows


def row_summary(row: dict[str, Any]) -> dict[str, Any]:
    metadata = row.get("metadata") if isinstance(row.get("metadata"), dict) else {}
    return {
        "sequence_num": row.get("sequence_num"),
        "identity_key": row.get("identity_key") or row.get("row_id") or row.get("target"),
        "timestamp": row.get("timestamp"),
        "artifact_class": row.get("artifact_class"),
        "state": row.get("state"),
        "consumer": row.get("consumer"),
        "blocking_scope": row.get("blocking_scope"),
        "verification_probe": row.get("verification_probe"),
        "classification_reason": metadata.get("classification_reason"),
    }


def simple_payload(*, status: str, schema_version: str, surface: str, **extra: Any) -> dict[str, Any]:
    return {"status": status, "schema_version": schema_version, "surface": surface, **extra}


def classifier_schema_probe(*, schema_path: Path, schema_status, required_fields: list[str]) -> dict[str, Any]:
    status = schema_status(schema_path)
    required_present = all(field in required_fields for field in ("artifact_class", "consumer", "verification_probe"))
    return {
        "schema_path": str(schema_path),
        "schema_status": status,
        "required_fields_count": len(required_fields),
        "required_fields_present": required_present,
        "status": "pass" if status == "available" and required_present else "fail",
    }


def classifier_doctor_payload(*, schema_version: str, surface: str, schema_path: Path, schema_status, required_fields: list[str], secret_count: int) -> dict[str, Any]:
    probe = classifier_schema_probe(schema_path=schema_path, schema_status=schema_status, required_fields=required_fields)
    return simple_payload(
        status=probe["status"],
        schema_version=schema_version,
        surface=surface,
        command="doctor",
        success=probe["status"] == "pass",
        required_row_fields=required_fields,
        secret_detector_count=secret_count,
        schema=probe,
        checks=[
            {"name": "schema_available", "status": "pass" if probe["schema_status"] == "available" else "fail"},
            {"name": "required_row_fields", "status": "pass" if probe["required_fields_present"] else "fail"},
            {"name": "secret_refusal_patterns", "status": "pass", "count": secret_count},
        ],
    )


def classifier_health_payload(*, schema_version: str, surface: str, schema_path: Path, schema_status, required_fields: list[str]) -> dict[str, Any]:
    probe = classifier_schema_probe(schema_path=schema_path, schema_status=schema_status, required_fields=required_fields)
    success = probe["status"] == "pass"
    return simple_payload(status="healthy" if success else "degraded", schema_version=schema_version, surface=surface, command="health", success=success, schema_status=probe["schema_status"], required_fields_count=len(required_fields))


def classifier_validate_payload(*, args: argparse.Namespace, schema_version: str, surface: str, schema_status, required_fields: list[str], read_json, build_row, validate_schema, error_type: type[ValueError]) -> tuple[dict[str, Any], int]:
    checks = [classifier_schema_probe(schema_path=Path(args.schema), schema_status=schema_status, required_fields=required_fields)]
    success = checks[0]["status"] == "pass"
    if args.event:
        try:
            row = build_row(read_json(Path(args.event)), schema_path=Path(args.schema))
            validation = validate_schema(row, Path(args.schema))
            checks.append({"name": "event_classifies_to_schema_row", **validation})
            success = success and validation["status"] in {"passed", "deferred_pending_F03"}
        except error_type as exc:
            checks.append({"name": "event_classifies_to_schema_row", "status": "fail", "reason_code": getattr(exc, "reason_code", "validation_failed"), "message": str(exc)})
            success = False
    return simple_payload(status="pass" if success else "fail", schema_version=schema_version, surface=surface, command="validate", success=success, checks=checks), 0 if success else 1


def classifier_audit_payload(*, args: argparse.Namespace, schema_version: str, surface: str, error_type: type[ValueError]) -> tuple[dict[str, Any], int]:
    try:
        rows = read_jsonl(Path(args.ledger), error_type=error_type)
    except error_type as exc:
        return simple_payload(status="fail", schema_version=schema_version, surface=surface, command="audit", success=False, reason_code=getattr(exc, "reason_code", "ledger_parse_failed"), message=str(exc)), 1
    return simple_payload(status="pass", schema_version=schema_version, surface=surface, command="audit", success=True, ledger=str(args.ledger), row_count=len(rows), recent=[row_summary(row) for row in rows[-args.limit:]]), 0


def classifier_why_payload(*, args: argparse.Namespace, schema_version: str, surface: str, error_type: type[ValueError]) -> tuple[dict[str, Any], int]:
    if not args.identity_key:
        return simple_payload(status="usage_error", schema_version=schema_version, surface=surface, command="why", success=False, reason_code="identity_required"), 2
    try:
        rows = read_jsonl(Path(args.ledger), error_type=error_type)
    except error_type as exc:
        return simple_payload(status="fail", schema_version=schema_version, surface=surface, command="why", success=False, reason_code=getattr(exc, "reason_code", "ledger_parse_failed"), message=str(exc)), 1
    hit = next((row_summary(row) for row in rows if str(row.get("identity_key")) == args.identity_key or str(row.get("sequence_num")) == args.identity_key), None)
    return simple_payload(status="pass" if hit else "not_found", schema_version=schema_version, surface=surface, command="why", success=hit is not None, id=args.identity_key, found=hit is not None, row=hit), 0 if hit else 1


def classifier_repair_payload(*, args: argparse.Namespace, schema_version: str, surface: str, schema_status, required_fields: list[str]) -> tuple[dict[str, Any], int]:
    if args.apply and not args.idempotency_key:
        return simple_payload(status="blocked", schema_version=schema_version, surface=surface, command="repair", success=False, reason_code="apply_requires_idempotency_key"), 4
    schema = classifier_schema_probe(schema_path=Path(args.schema), schema_status=schema_status, required_fields=required_fields)
    ledger = Path(args.ledger)
    actual_actions: list[dict[str, Any]] = []
    if args.apply:
        ledger.parent.mkdir(parents=True, exist_ok=True)
        actual_actions.append({"action": "ensure_ledger_parent", "path": str(ledger.parent), "status": "applied"})
    success = schema["status"] == "pass"
    return simple_payload(
        status="applied" if args.apply else "dry_run",
        schema_version=schema_version,
        surface=surface,
        command="repair",
        success=success,
        scope=args.scope,
        dry_run=not args.apply,
        explain=args.explain,
        idempotency_key=args.idempotency_key,
        planned_actions=[{"action": "verify_schema", "path": str(args.schema), "status": schema["status"]}, {"action": "ensure_ledger_parent", "path": str(ledger.parent), "needed": not ledger.parent.exists()}],
        actual_actions=actual_actions,
        would_write=[] if args.apply or ledger.parent.exists() else [str(ledger.parent)],
        would_delete=[],
        would_call_external=[],
        blocked_by=[] if success else ["schema_unavailable"],
    ), 0 if success else 1

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
