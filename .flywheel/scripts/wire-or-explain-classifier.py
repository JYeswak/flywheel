#!/usr/bin/env python3
# canonical-cli-scoping-allow-large: reviewed compatibility surface; Cluster C owns package split after wave-0 CLI parity.
from __future__ import annotations

import argparse
import fcntl
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any

from wire_or_explain_cli_support import (
    add_output_flags,
    classifier_audit_payload,
    classifier_doctor_payload,
    classifier_health_payload,
    classifier_repair_payload,
    classifier_validate_payload,
    classifier_why_payload,
    completion_script as make_completion_script,
)

VERSION = "wire-or-explain-classifier.v1"
SCHEMA_NAME = "flywheel.wire-or-explain.v1"
SURFACE_NAME = "The Zest Press"
DEFAULT_SCHEMA = Path(".flywheel/validation-schema/v1/wire-or-explain-ledger.schema.json")
DEFAULT_LEDGER = Path.home() / ".local/state/flywheel/wire-or-explain-ledger.jsonl"
ZERO_HASH = "0" * 64
REQUIRED_B1_FIELDS = """
schema_name schema_version identity_key timestamp session_id event_type actor target
payload metadata prev_hash checksum sequence_num state producer owner consumer
trust_domain blocking_scope owning_orch ship_repo ship_actor artifact_class subject predicate
branch_ref git_ref reset_intent_hash deferral_owner deferral_until auto_fire_trigger
drain_receipt_shape verification_probe tick_status_consequence stock inflow
action_ledger
""".split()
SECRET_PATTERNS = [
    ("github_token", re.compile(r"\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9_]{20,}\b")),
    ("github_pat", re.compile(r"\bgithub_pat_[A-Za-z0-9_]{30,}\b")),
    ("openai_key", re.compile(r"\bsk-(?:proj-)?[A-Za-z0-9_-]{20,}\b")),
    ("anthropic_key", re.compile(r"\bsk-ant-[A-Za-z0-9_-]{20,}\b")),
    ("aws_access_key", re.compile(r"\b(?:AKIA|ASIA)[0-9A-Z]{16}\b")),
    ("bearer_token", re.compile(r"\bBearer\s+[A-Za-z0-9._~+/=-]{20,}\b", re.I)),
    ("jwt", re.compile(r"\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b")),
]

class ClassificationError(ValueError):
    def __init__(self, reason_code: str, message: str, *, details: dict[str, Any] | None = None) -> None:
        super().__init__(message)
        self.reason_code = reason_code
        self.details = details or {}

def canonical_json(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True)

def sha256_text(text: str) -> str:
    return "sha256:" + hashlib.sha256(text.encode("utf-8")).hexdigest()

def sha256_hex(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()

def read_json(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ClassificationError("event_not_object", f"event file must contain a JSON object: {path}")
    return data

def list_strings(value: Any) -> list[str]:
    if isinstance(value, list):
        return sorted({str(item) for item in value if str(item)})
    if isinstance(value, str) and value:
        return [value]
    return []

def scan_secret_like(value: Any, path: str = "$") -> list[dict[str, str]]:
    hits: list[dict[str, str]] = []
    if isinstance(value, dict):
        for key, child in value.items():
            hits.extend(scan_secret_like(child, f"{path}.{key}"))
    elif isinstance(value, list):
        for idx, child in enumerate(value):
            hits.extend(scan_secret_like(child, f"{path}[{idx}]"))
    elif isinstance(value, str):
        for secret_class, pattern in SECRET_PATTERNS:
            if pattern.search(value):
                hits.append({"path": path, "class": secret_class})
    return hits

def primary_path(event: dict[str, Any]) -> str:
    paths = list_strings(event.get("changed_paths"))
    target = str(event.get("target") or (paths[0] if paths else "unknown"))
    return target

def path_blob(event: dict[str, Any]) -> str:
    parts = [primary_path(event), *list_strings(event.get("changed_paths"))]
    return " ".join(parts).lower()

def classify(event: dict[str, Any]) -> tuple[str, str]:
    blob = path_blob(event)
    kind = str(event.get("surface_kind") or event.get("event_type") or "").lower()
    finding = canonical_json(event.get("finding") or event.get("memory") or event.get("fuckup") or "").lower()
    if event.get("no_wire_required") is True or event.get("wire_required") is False:
        return "no_wire_required", "explicit no-wire-required proof"
    if event.get("skill_candidate") is True or "should become" in finding or "skill-shaped" in finding:
        return "skill_candidate", "feedback/fuckup/memory row has skill-shaped finding"
    if event.get("reset_intent_hash") or event.get("reset_intent") or event.get("orphan_commits"):
        return "reset_guard_artifact", "reset guard fields present"
    if event.get("branch_ref") or event.get("worker_branch") or "worker-branch" in blob:
        return "worker_branch_artifact", "worker branch/ref fields present"
    if event.get("jeff_corpus_consumer_path") or "jeff-corpus" in blob or "jeff-" in blob:
        return "jeff_corpus_consumer_path", "Jeff corpus consumer path present"
    if "dispatch" in blob and ("template" in blob or "/prompts/" in blob or "/dispatch" in blob):
        return "dispatch_template", "dispatch template path changed"
    if "agents.md" in blob or "agents-canonical" in blob or "paradigm" in blob or "l-rule" in blob or "doctrine" in blob:
        return "l_rule", "doctrine or L-rule path changed"
    if kind in {"doctor", "status", "cli"} or any(token in blob for token in ("doctor", "status", "probe", "validator", "gate")):
        return "cli_surface", "doctor/status/CLI surface changed"
    if "/.flywheel/scripts/" in blob or blob.startswith(".flywheel/scripts/") or blob.endswith((".sh", ".py", ".rs")):
        return "script", "commit script path changed"
    return "no_wire_required", "no classifier rule matched; explicit explanation row required"

def consumer_for(artifact_class: str, event: dict[str, Any]) -> str:
    explicit = event.get("consumer") or event.get("consumer_path")
    if isinstance(explicit, str) and explicit:
        return explicit
    return {
        "script": "wire-or-explain-detector",
        "l_rule": "doctrine-3-surface-divergence-probe",
        "dispatch_template": "dispatch-and-log",
        "cli_surface": "operator-status-doctor-surface",
        "worker_branch_artifact": "worker-branch-enforcement",
        "reset_guard_artifact": "reset-guard-drain",
        "jeff_corpus_consumer_path": str(event.get("jeff_corpus_consumer_path") or "jeff-corpus-consumer"),
        "skill_candidate": "skillos:skill-candidate-relay",
        "no_wire_required": "orchestrator:not-required-receipt",
    }.get(artifact_class, "wire-or-explain-triage")

def schema_artifact_class(artifact_class: str) -> str:
    return {
        "dispatch_template": "dispatch_packet",
        "worker_branch_artifact": "worker_branch",
        "skill_candidate": "skill_candidate",
    }.get(artifact_class, "finding")

def event_evidence(event: dict[str, Any]) -> dict[str, Any]:
    evidence = event.get("evidence")
    base = evidence if isinstance(evidence, dict) else {}
    merged: dict[str, Any] = {
        "changed_paths": list_strings(event.get("changed_paths")),
        "action_ledger_pointer": event.get("action_ledger_pointer") or event.get("action_ledger"),
        "source_refs": list_strings(event.get("source_refs")),
    }
    for key in ("branch_ref", "git_ref", "identity_proof", "orphan_commits", "reset_intent", "jeff_corpus_consumer_path"):
        if key in event:
            merged[key] = event[key]
    merged.update(base)
    return {key: value for key, value in merged.items() if value not in (None, "", [], {})}

def reset_hash(event: dict[str, Any]) -> str:
    if isinstance(event.get("reset_intent_hash"), str) and event["reset_intent_hash"]:
        return event["reset_intent_hash"]
    if event.get("reset_intent") or event.get("orphan_commits"):
        return sha256_text(canonical_json({
            "reset_intent": event.get("reset_intent") or "",
            "orphan_commits": sorted(list_strings(event.get("orphan_commits"))),
        }))
    return ""

def build_row(event: dict[str, Any], *, schema_path: Path = DEFAULT_SCHEMA) -> dict[str, Any]:
    secret_hits = scan_secret_like(event_evidence(event))
    if secret_hits:
        classes = sorted({hit["class"] for hit in secret_hits})
        raise ClassificationError(
            "secret_looking_evidence",
            "refusing to serialize secret-looking evidence",
            details={"redaction_count": len(secret_hits), "redaction_classes": classes, "redaction_paths": [h["path"] for h in secret_hits]},
        )
    artifact_class, reason = classify(event)
    ledger_artifact_class = schema_artifact_class(artifact_class)
    evidence = event_evidence(event)
    evidence_hash = sha256_text(canonical_json(evidence))
    branch_ref = str(event.get("branch_ref") or (event.get("worker_branch") or {}).get("branch_ref") or "")
    identity_proof = event.get("identity_proof") or (event.get("worker_branch") or {}).get("identity_proof") or {}
    if artifact_class == "worker_branch_artifact" and (not branch_ref or not identity_proof):
        raise ClassificationError("worker_branch_identity_proof_missing", "worker branch artifacts require branch_ref and identity_proof")
    orphan_commits = sorted(list_strings(event.get("orphan_commits")))
    identity = {
        "schema_name": SCHEMA_NAME,
        "session_id": event.get("session_id") or "flywheel",
        "event_type": event.get("event_type") or "ship_event",
        "target": primary_path(event),
        "artifact_class": artifact_class,
        "git_ref": event.get("git_ref") or "",
        "branch_ref": branch_ref,
        "reset_intent_hash": reset_hash(event),
        "evidence_root_hash": evidence_hash,
    }
    row_identity = sha256_hex(canonical_json(identity))
    state = "not_required" if artifact_class == "no_wire_required" else "unwired"
    consumer = consumer_for(artifact_class, event)
    row: dict[str, Any] = {
        "schema_name": SCHEMA_NAME,
        "schema_version": "wire-or-explain-ledger/v1",
        "identity_key": row_identity,
        "timestamp": event.get("timestamp") or "1970-01-01T00:00:00Z",
        "session_id": identity["session_id"],
        "event_type": identity["event_type"],
        "actor": event.get("actor") or "unknown",
        "target": identity["target"],
        "payload": {
            "ship_event_id": event.get("ship_event_id") or row_identity,
            "changed_paths": list_strings(event.get("changed_paths")),
            "evidence_root_hash": evidence_hash,
            "evidence_output_hash": evidence_hash,
            "evidence_key_count": len(evidence),
            "evidence_redaction_count": 0,
            "classifier_artifact_class": artifact_class,
            "identity_proof_hash": sha256_text(canonical_json(identity_proof)) if identity_proof else "",
            "orphan_commits": orphan_commits,
        },
        "metadata": {
            "classifier": SURFACE_NAME,
            "classifier_version": VERSION,
            "classification_reason": reason,
            "classifier_artifact_class": artifact_class,
            "row_identity": row_identity,
            "action_ledger_pointer": event.get("action_ledger_pointer") or event.get("action_ledger") or "",
            "schema_validation_status": schema_status(schema_path),
        },
        "prev_hash": event.get("prev_hash") or ZERO_HASH,
        "checksum": ZERO_HASH,
        "sequence_num": int(event.get("sequence_num") or 1),
        "state": state,
        "producer": event.get("producer") or "wire-or-explain-classifier",
        "owner": event.get("owner") or event.get("owning_orch") or "flywheel:1",
        "consumer": consumer,
        "trust_domain": event.get("trust_domain") or "repo:flywheel",
        "blocking_scope": event.get("blocking_scope") or ("none" if state == "not_required" else "tick_status"),
        "owning_orch": event.get("owning_orch") or "flywheel:1",
        "ship_repo": event.get("ship_repo") or "/Users/josh/Developer/flywheel",
        "ship_actor": event.get("ship_actor") or event.get("actor") or "unknown",
        "artifact_class": ledger_artifact_class,
        "subject": event.get("subject") or identity["target"],
        "predicate": event.get("predicate") or ("no_wire_required" if state == "not_required" else "requires_consumer"),
        "branch_ref": branch_ref or None,
        "git_ref": str(event.get("git_ref") or "") or None,
        "reset_intent_hash": identity["reset_intent_hash"] or None,
        "deferral_owner": event.get("deferral_owner") or None,
        "deferral_until": event.get("deferral_until") or None,
        "auto_fire_trigger": event.get("auto_fire_trigger") or auto_fire_for(artifact_class),
        "drain_receipt_shape": event.get("drain_receipt_shape") or drain_receipt_for(artifact_class),
        "verification_probe": event.get("verification_probe") or verification_for(artifact_class),
        "tick_status_consequence": event.get("tick_status_consequence") or tick_status_for(artifact_class),
        "stock": event.get("stock") or "wire-or-explain",
        "inflow": event.get("inflow") or artifact_class,
        "action_ledger": event.get("action_ledger_pointer") or event.get("action_ledger") or "~/.local/state/flywheel/wire-or-explain-ledger.jsonl",
    }
    row["checksum"] = sha256_hex(canonical_json({**row, "checksum": ZERO_HASH}))
    return row

def auto_fire_for(artifact_class: str) -> str:
    return {
        "skill_candidate": "append skillos relay packet when skill_candidate row is active",
        "no_wire_required": "explicit_no_auto_repair_reason:no consumer required",
    }.get(artifact_class, "wire-or-explain detector consumes active unwired row")

def drain_receipt_for(artifact_class: str) -> str:
    return {
        "skill_candidate": "skillos relay receipt with source row identity",
        "no_wire_required": "no-wire-required explanation row",
    }.get(artifact_class, "consumer proof row or callback evidence")

def verification_for(artifact_class: str) -> str:
    return {
        "script": "test executable path and dispatch-log consumer pointer",
        "l_rule": "doctrine three-surface divergence probe",
        "dispatch_template": "dispatch-and-log expected-field test",
        "cli_surface": "CLI doctor/health/repair smoke probe",
        "worker_branch_artifact": "worker branch identity proof and branch_ref present",
        "reset_guard_artifact": "reset_intent_hash plus sorted orphan commit set",
        "jeff_corpus_consumer_path": "Jeff corpus consumer path smoke query",
        "skill_candidate": "skillos relay row exists",
        "no_wire_required": "explicit not_required explanation present",
    }.get(artifact_class, "wire-or-explain detector smoke")

def tick_status_for(artifact_class: str) -> str:
    return {
        "no_wire_required": "no status debt",
        "skill_candidate": "warn until skillos relay receipt exists",
    }.get(artifact_class, "warn until consumer proof exists; fail in enforce mode")

def schema_status(schema_path: Path) -> str:
    return "available" if schema_path.exists() else "deferred_pending_F03"

def validate_schema(row: dict[str, Any], schema_path: Path) -> dict[str, Any]:
    missing = [field for field in REQUIRED_B1_FIELDS if field not in row]
    if missing:
        return {"status": "fail", "reason_code": "required_fields_missing", "missing": missing}
    if not schema_path.exists():
        return {"status": "deferred_pending_F03", "reason_code": "schema_file_missing", "schema_path": str(schema_path)}
    try:
        import jsonschema
    except ImportError:
        return {"status": "fail", "reason_code": "jsonschema_missing"}
    schema = json.loads(schema_path.read_text(encoding="utf-8"))
    validator = jsonschema.Draft202012Validator(schema)
    errors = sorted(validator.iter_errors(row), key=lambda err: list(err.path))
    if errors:
        return {"status": "fail", "reason_code": "schema_validation_failed", "error_count": len(errors), "errors": [err.message for err in errors[:5]]}
    return {"status": "passed", "reason_code": "schema_validation_passed", "schema_path": str(schema_path)}

def append_idempotent(row: dict[str, Any], ledger_path: Path) -> dict[str, Any]:
    row_id = row["identity_key"]
    ledger_path.parent.mkdir(parents=True, exist_ok=True)
    with ledger_path.open("a+", encoding="utf-8") as handle:
        fcntl.flock(handle.fileno(), fcntl.LOCK_EX)
        handle.seek(0)
        rows = [json.loads(line) for line in handle.read().splitlines() if line.strip()]
        for existing in rows:
            if existing.get("identity_key") == row_id and existing.get("state") != "inactive":
                return {"status": "duplicate", "row_identity": row_id, "appended": False, "row": existing}
        row["sequence_num"] = max([int(r.get("sequence_num") or 0) for r in rows] or [0]) + 1
        row["prev_hash"] = rows[-1].get("checksum") if rows else ZERO_HASH
        row["checksum"] = sha256_hex(canonical_json({**row, "checksum": ZERO_HASH}))
        handle.write(canonical_json(row) + "\n")
        return {"status": "appended", "row_identity": row_id, "appended": True, "row": row}

def classify_command(args: argparse.Namespace) -> int:
    event = read_json(Path(args.event))
    try:
        row = build_row(event, schema_path=Path(args.schema))
        if args.idempotency_key:
            row["metadata"]["idempotency_key"] = args.idempotency_key
        validation = validate_schema(row, Path(args.schema))
        if args.apply:
            receipt = append_idempotent(row, Path(args.ledger))
            receipt["schema_validation"] = validation
            emit(receipt, args.json)
        else:
            emit({"status": "pass", "row": row, "schema_validation": validation}, args.json)
        return 0
    except ClassificationError as exc:
        emit({"status": "refused", "reason_code": exc.reason_code, "message": str(exc), **exc.details}, args.json)
        return 1

def emit(payload: dict[str, Any], as_json: bool) -> None:
    if as_json:
        print(canonical_json(payload))
    else:
        print(payload.get("status", "ok"))

def simple_payload(status: str = "pass", **extra: Any) -> dict[str, Any]:
    return {"status": status, "schema_version": f"{VERSION}/cli", "surface": SURFACE_NAME, **extra}

def schema_payload(command: str = "all") -> dict[str, Any]:
    return {
        "schema_version": f"{VERSION}/cli-schema",
        "command": command,
        "required_output_fields": ["status", "schema_version", "surface", "command", "success"],
        "ledger_row_required_fields": REQUIRED_B1_FIELDS,
    }

def quickstart_payload() -> dict[str, Any]:
    return simple_payload(
        command="quickstart",
        success=True,
        steps=[
            "Run doctor to verify schema and classifier invariants.",
            "Run classify --event EVENT.json --json to preview a Zest Ledger row.",
            "Run validate --event EVENT.json --json before append workflows.",
            "Run classify --apply --idempotency-key KEY to append idempotently.",
            "Run audit or why against the Zest Ledger for provenance.",
        ],
    )

def help_payload(topic: str) -> dict[str, Any]:
    return simple_payload(
        command="help",
        success=True,
        topic=topic,
        commands=["classify", "doctor", "health", "repair", "validate", "audit", "why", "schema", "quickstart", "completion"],
    )

def completion_script(shell: str) -> str:
    commands = "classify doctor health repair validate audit why schema quickstart help completion"
    flags = "--info --examples --json --no-color --no-emoji --width --event --schema --ledger --apply --dry-run --scope --idempotency-key --explain --limit"
    return make_completion_script(prog="wire-or-explain-classifier.py", commands=commands, flags=flags, shell=shell)

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="wire-or-explain-classifier.py")
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--examples", action="store_true")
    add_output_flags(parser)
    sub = parser.add_subparsers(dest="command")
    classify_p = sub.add_parser("classify")
    classify_p.add_argument("--event", required=True)
    classify_p.add_argument("--schema", default=str(DEFAULT_SCHEMA))
    classify_p.add_argument("--ledger", default=str(DEFAULT_LEDGER))
    classify_p.add_argument("--apply", action="store_true")
    classify_p.add_argument("--idempotency-key")
    add_output_flags(classify_p)
    for name in ("doctor", "health"):
        p = sub.add_parser(name)
        p.add_argument("--schema", default=str(DEFAULT_SCHEMA))
        add_output_flags(p)
    validate_p = sub.add_parser("validate")
    validate_p.add_argument("--event")
    validate_p.add_argument("--schema", default=str(DEFAULT_SCHEMA))
    add_output_flags(validate_p)
    audit_p = sub.add_parser("audit")
    audit_p.add_argument("--ledger", default=str(DEFAULT_LEDGER))
    audit_p.add_argument("--limit", type=int, default=10)
    add_output_flags(audit_p)
    why_p = sub.add_parser("why")
    why_p.add_argument("identity_key", nargs="?")
    why_p.add_argument("--ledger", default=str(DEFAULT_LEDGER))
    add_output_flags(why_p)
    repair_p = sub.add_parser("repair")
    repair_p.add_argument("--schema", default=str(DEFAULT_SCHEMA))
    repair_p.add_argument("--ledger", default=str(DEFAULT_LEDGER))
    repair_p.add_argument("--scope", default="classifier")
    repair_p.add_argument("--dry-run", action="store_true")
    repair_p.add_argument("--apply", action="store_true")
    repair_p.add_argument("--idempotency-key")
    repair_p.add_argument("--explain", action="store_true")
    add_output_flags(repair_p)
    schema_p = sub.add_parser("schema")
    schema_p.add_argument("schema_command", nargs="?", default="all")
    add_output_flags(schema_p)
    quickstart_p = sub.add_parser("quickstart")
    add_output_flags(quickstart_p)
    help_p = sub.add_parser("help")
    help_p.add_argument("topic", nargs="?", default="overview")
    add_output_flags(help_p)
    completion_p = sub.add_parser("completion")
    completion_p.add_argument("shell", choices=["bash", "zsh"])
    return parser

def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    for attr, default in (("json", False), ("no_color", False), ("no_emoji", False), ("width", None)):
        if not hasattr(args, attr):
            setattr(args, attr, default)
    if args.info:
        emit(simple_payload(
            name="wire-or-explain-classifier",
            version=VERSION,
            commands=["classify", "doctor", "health", "repair", "validate", "audit", "why", "schema", "quickstart", "completion"],
            output_controls=["--json", "--no-color", "--no-emoji", "--width"],
            mutation_flags=["--apply", "--idempotency-key"],
        ), args.json)
        return 0
    if args.examples:
        emit(simple_payload(examples=[
            "wire-or-explain-classifier.py classify --event tests/fixtures/wire-or-explain-classifier/script.json --json",
            "wire-or-explain-classifier.py validate --event tests/fixtures/wire-or-explain-classifier/script.json --json",
            "wire-or-explain-classifier.py audit --ledger ~/.local/state/flywheel/wire-or-explain-ledger.jsonl --json",
        ]), args.json)
        return 0
    if args.command == "classify":
        return classify_command(args)
    if args.command == "completion":
        print(completion_script(args.shell))
        return 0
    if args.command == "doctor":
        payload = classifier_doctor_payload(
            schema_version=f"{VERSION}/cli",
            surface=SURFACE_NAME,
            schema_path=Path(args.schema),
            schema_status=schema_status,
            required_fields=REQUIRED_B1_FIELDS,
            secret_count=len(SECRET_PATTERNS),
        )
        emit(payload, args.json)
        return 0 if payload["success"] else 1
    if args.command == "health":
        payload = classifier_health_payload(
            schema_version=f"{VERSION}/cli",
            surface=SURFACE_NAME,
            schema_path=Path(args.schema),
            schema_status=schema_status,
            required_fields=REQUIRED_B1_FIELDS,
        )
        emit(payload, args.json)
        return 0 if payload["success"] else 1
    if args.command == "validate":
        payload, rc = classifier_validate_payload(
            args=args,
            schema_version=f"{VERSION}/cli",
            surface=SURFACE_NAME,
            schema_status=schema_status,
            required_fields=REQUIRED_B1_FIELDS,
            read_json=read_json,
            build_row=build_row,
            validate_schema=validate_schema,
            error_type=ClassificationError,
        )
        emit(payload, args.json)
        return rc
    if args.command == "audit":
        payload, rc = classifier_audit_payload(args=args, schema_version=f"{VERSION}/cli", surface=SURFACE_NAME, error_type=ClassificationError)
        emit(payload, args.json)
        return rc
    if args.command == "why":
        payload, rc = classifier_why_payload(args=args, schema_version=f"{VERSION}/cli", surface=SURFACE_NAME, error_type=ClassificationError)
        emit(payload, args.json)
        return rc
    if args.command == "repair":
        payload, rc = classifier_repair_payload(args=args, schema_version=f"{VERSION}/cli", surface=SURFACE_NAME, schema_status=schema_status, required_fields=REQUIRED_B1_FIELDS)
        emit(payload, args.json)
        return rc
    if args.command == "schema":
        emit(schema_payload(args.schema_command), args.json)
        return 0
    if args.command == "quickstart":
        emit(quickstart_payload(), args.json)
        return 0
    if args.command == "help":
        emit(help_payload(args.topic), args.json)
        return 0
    parser.print_help()
    return 2

if __name__ == "__main__":
    raise SystemExit(main())

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
