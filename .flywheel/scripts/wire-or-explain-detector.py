#!/usr/bin/env python3
"""The Zest Pour: classify Zest Ledger rows by actual consumer wiring."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import re
import shlex
import subprocess
import sys
from pathlib import Path
from typing import Any

# canonical-cli-scoping-allow-large: reviewed single-process detector contract; row loading, probe execution, schema projection, and CLI stay colocated for wave-0 operator parity.

STATES = ["wired", "deferred", "unwired", "questionably_wired", "not_required", "bypassed"]
README_KINDS = {"readme", "readme_reference", "doctrine", "docs", "markdown_reference"}
RELAY_OK = {"sent", "pass", "passed", "ok", "success", "succeeded", "skill_handoff_sent"}
SCHEMA_NAME = "flywheel.wire-or-explain.v1"
SCHEMA_VERSION = "wire-or-explain-ledger/v1"
ZERO_HASH = "0" * 64


def utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def parse_time(value: Any) -> dt.datetime | None:
    if not isinstance(value, str) or not value:
        return None
    if value.startswith("bead:") or value.startswith("condition:"):
        return None
    try:
        return dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def load_json(path: str | None, default: Any) -> Any:
    if not path:
        return default
    p = Path(path).expanduser()
    if not p.exists():
        return default
    with p.open() as fh:
        return json.load(fh)


def load_jsonl(path: str | None) -> list[dict[str, Any]]:
    if not path:
        return []
    p = Path(path).expanduser()
    if not p.exists():
        return []
    rows: list[dict[str, Any]] = []
    with p.open() as fh:
        for line_no, line in enumerate(fh, 1):
            stripped = line.strip()
            if not stripped:
                continue
            try:
                obj = json.loads(stripped)
            except json.JSONDecodeError as exc:
                raise SystemExit(f"{p}:{line_no}: invalid JSONL: {exc}") from exc
            if isinstance(obj, dict):
                rows.append(obj)
    return rows


def stable_hash(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()[:12]


def sha256_hex(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


def strip_line_ref(value: str) -> str:
    return re.sub(r":\d+(?::\d+)?$", "", value)


def slug(value: str) -> str:
    value = strip_line_ref(value)
    value = re.sub(r"[^A-Za-z0-9_.:/-]+", "-", value).strip("-")
    return value or f"unknown-{stable_hash(value)}"


def nested(obj: dict[str, Any], *keys: str) -> Any:
    cur: Any = obj
    for key in keys:
        if not isinstance(cur, dict):
            return None
        cur = cur.get(key)
    return cur


def first_str(row: dict[str, Any], *paths: tuple[str, ...]) -> str | None:
    for path in paths:
        value = nested(row, *path)
        if isinstance(value, str) and value:
            return value
    return None


def row_id(row: dict[str, Any]) -> str:
    return (
        first_str(row, ("ship_event_id",), ("row_id",), ("event_identity",), ("id",), ("target", "id"))
        or f"row-{stable_hash(json.dumps(row, sort_keys=True))}"
    )


def artifact_path(row: dict[str, Any]) -> str | None:
    return first_str(row, ("artifact_path",), ("producer", "path"), ("target", "path"), ("subject", "path"))


def consumer_id(row: dict[str, Any]) -> str:
    explicit = first_str(
        row,
        ("consumer_id",),
        ("consumer", "id"),
        ("consumer", "consumer_id"),
        ("verification_probe", "consumer_id"),
    )
    if explicit:
        return strip_line_ref(explicit)
    consumer = row.get("consumer")
    if isinstance(consumer, str) and consumer and consumer != "NONE":
        return strip_line_ref(consumer)
    if isinstance(consumer, dict):
        kind = consumer.get("kind") or "consumer"
        name = consumer.get("name") or consumer.get("path") or consumer.get("command") or json.dumps(consumer, sort_keys=True)
        return f"{kind}:{slug(str(name))}"
    probe_path = first_str(row, ("verification_probe", "path"), ("consumer_evidence", "path"), ("evidence", "path"))
    if probe_path:
        return f"path:{slug(probe_path)}"
    if row.get("artifact_class") == "skill_candidate":
        return "skillos-relay"
    return "NONE"


def evidence_kind(row: dict[str, Any]) -> str:
    return str(
        first_str(
            row,
            ("consumer_evidence", "kind"),
            ("evidence", "kind"),
            ("verification_probe", "kind"),
            ("consumer", "kind"),
        )
        or ""
    ).lower()


def command_argv(command: Any) -> list[str] | None:
    if isinstance(command, list) and all(isinstance(x, str) for x in command):
        return command
    if isinstance(command, str) and command.strip():
        return shlex.split(command)
    return None


def probe_command(row: dict[str, Any]) -> Any:
    return nested(row, "verification_probe", "command") or nested(row, "consumer_evidence", "command")


def run_probe(row: dict[str, Any], args: argparse.Namespace) -> dict[str, Any]:
    argv = command_argv(probe_command(row))
    if not argv:
        return {"status": "missing", "runnable": False, "reason_code": "missing_runnable_probe"}
    if not args.execute_probes:
        return {"status": "not_executed", "runnable": True, "reason_code": "runnable_probe_not_executed"}
    try:
        proc = subprocess.run(
            argv,
            cwd=args.repo,
            text=True,
            capture_output=True,
            timeout=args.probe_timeout,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        return {"status": "failed", "runnable": True, "reason_code": "probe_exec_failed", "error": str(exc)}
    return {
        "status": "passed" if proc.returncode == 0 else "failed",
        "runnable": True,
        "exit_code": proc.returncode,
        "reason_code": "probe_passed" if proc.returncode == 0 else "probe_nonzero",
    }


def circular_self_proof(row: dict[str, Any]) -> bool:
    producer = artifact_path(row)
    proof_path = first_str(row, ("verification_probe", "path"), ("consumer_evidence", "path"), ("evidence", "path"))
    if not producer or not proof_path:
        return False
    if bool(nested(row, "verification_probe", "independent_consumer_proof")):
        return False
    return strip_line_ref(producer) == strip_line_ref(proof_path)


def relay_index(rows: list[dict[str, Any]], receipts: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    receipt_status: dict[str, str] = {}
    for receipt in receipts:
        rid = first_str(receipt, ("receipt_id",), ("id",), ("send_receipt_id",))
        if rid:
            receipt_status[rid] = str(receipt.get("status", "")).lower()
    out: dict[str, dict[str, Any]] = {}
    for row in rows:
        source = first_str(row, ("source_event_id",), ("ship_event_id",), ("source_row_id",), ("row_id",), ("target", "id"))
        if not source:
            continue
        status = str(row.get("status") or row.get("event_type") or row.get("receipt_type") or "").lower()
        receipt_id = first_str(row, ("send_receipt_id",), ("receipt_id",), ("ntm_send_receipt_id",))
        receipt_ok = not receipt_id or receipt_status.get(receipt_id, "").lower() in RELAY_OK
        if status in RELAY_OK and receipt_ok:
            out[source] = row
    return out


def classify(row: dict[str, Any], relays: dict[str, dict[str, Any]], args: argparse.Namespace) -> dict[str, Any]:
    rid = row_id(row)
    art_class = str(row.get("artifact_class") or row.get("class") or "other")
    cid = consumer_id(row)
    base = {
        "row_id": rid,
        "ship_event_id": row.get("ship_event_id"),
        "artifact_class": art_class,
        "consumer_id": cid,
    }

    if art_class == "no_wire_required" or row.get("state") == "not_required" or row.get("no_wire_required") is True:
        return base | {"wire_state": "not_required", "reason_code": "wire_not_required"}
    if row.get("state") == "bypassed" or row.get("bypass_reason"):
        return base | {"wire_state": "bypassed", "reason_code": "explicit_bypass", "bypass_owner": row.get("bypass_owner") or row.get("owner")}

    now = parse_time(args.now) or dt.datetime.now(dt.timezone.utc)
    deferral_until = first_str(row, ("deferral_until",), ("deferred_until",), ("metadata", "deferral_until"))
    deferral_owner = first_str(row, ("deferral_owner",), ("metadata", "deferral_owner"))
    deferral_dt = parse_time(deferral_until)
    if deferral_dt and deferral_owner:
        if deferral_dt > now:
            return base | {"wire_state": "deferred", "reason_code": "future_deferral", "deferral_owner": deferral_owner, "deferral_until": deferral_until}
        overdue_days = max(0, (now - deferral_dt).days)
        return base | {"wire_state": "unwired", "reason_code": "deferral_overdue", "overdue": {"deferral_owner": deferral_owner, "deferral_until": deferral_until, "overdue_days": overdue_days}}

    if art_class in {"skill_candidate", "skill-candidate"}:
        relay = relays.get(rid) or (relays.get(str(row.get("ship_event_id"))) if row.get("ship_event_id") else None)
        if relay:
            return base | {"wire_state": "wired", "reason_code": "skillos_relay_receipt_found", "consumer_id": "skillos-relay", "relay_receipt": relay.get("receipt_id") or relay.get("send_receipt_id")}
        return base | {
            "wire_state": "unwired",
            "reason_code": "skill_candidate_missing_relay",
            "consumer_id": "skillos-relay",
            "action_metadata": {
                "next_action": "send_to_skillos",
                "target_session": "skillos",
                "required_receipts": ["skillos-relay-ledger.jsonl", "ntm_send_receipt"],
            },
        }

    if circular_self_proof(row):
        return base | {"wire_state": "unwired", "reason_code": "circular_self_proof_refused", "proof_refused": True}

    kind = evidence_kind(row)
    if kind in README_KINDS:
        return base | {"wire_state": "questionably_wired", "reason_code": "readme_or_doctrine_only_reference"}

    probe = run_probe(row, args)
    if probe["status"] == "passed":
        return base | {"wire_state": "wired", "reason_code": "runnable_consumer_probe_passed", "probe": probe}
    if probe.get("runnable"):
        return base | {"wire_state": "questionably_wired", "reason_code": probe["reason_code"], "probe": probe}
    return base | {"wire_state": "unwired", "reason_code": "no_consumer_evidence"}


def schema_artifact_class(source: dict[str, Any], classified: dict[str, Any]) -> str:
    if classified["artifact_class"] in {"skill_candidate", "skill-candidate"}:
        return "skill_candidate"
    event_type = str(source.get("event_type") or "").lower()
    if "dispatch" in event_type:
        return "dispatch_packet"
    if "callback" in event_type:
        return "callback"
    if "bead" in event_type:
        return "bead"
    if str(source.get("artifact_class")) in {"worker_branch", "worker_branch_artifact"}:
        return "worker_branch"
    return "finding"


def schema_event_type(state: str) -> str:
    return {
        "wired": "wire_state_verified",
        "deferred": "wire_state_deferred",
        "unwired": "wire_gap_observed",
        "questionably_wired": "weak_wire_observed",
        "not_required": "artifact_triaged",
        "bypassed": "guard_bypass_observed",
    }[state]


def schema_string(value: Any, fallback: str) -> str:
    if isinstance(value, str) and value:
        return value
    if value not in (None, "", [], {}):
        return json.dumps(value, sort_keys=True, separators=(",", ":"))
    return fallback


def to_schema_ledger_row(source: dict[str, Any], classified: dict[str, Any], sequence_num: int, args: argparse.Namespace) -> dict[str, Any]:
    state = classified["wire_state"]
    rid = classified["row_id"]
    producer = artifact_path(source) or str(source.get("producer") or "wire-or-explain-detector")
    consumer = classified["consumer_id"] or "wire-or-explain-detector"
    deferral_owner = classified.get("deferral_owner") or nested(classified, "overdue", "deferral_owner") or source.get("deferral_owner")
    deferral_until = classified.get("deferral_until") or nested(classified, "overdue", "deferral_until") or source.get("deferral_until")
    if state == "deferred" or consumer == "NONE":
        deferral_owner = deferral_owner or "flywheel:1"
        deferral_until = deferral_until or "condition:consumer-proof-arrives"
    payload = {
        "source_row_id": rid,
        "wire_state": state,
        "reason_code": classified["reason_code"],
        "consumer_id": classified["consumer_id"],
        "evidence_output_hash": sha256_hex(json.dumps(classified, sort_keys=True, separators=(",", ":"))),
    }
    metadata = {
        "detector": "The Zest Pour",
        "detector_version": "wire-or-explain-detector/v1",
        "source_artifact_class": classified["artifact_class"],
    }
    if "action_metadata" in classified:
        metadata["action_metadata"] = classified["action_metadata"]
    if "overdue" in classified:
        metadata["overdue"] = classified["overdue"]
    row: dict[str, Any] = {
        "schema_name": SCHEMA_NAME,
        "schema_version": SCHEMA_VERSION,
        "identity_key": sha256_hex(f"{rid}:{state}:{classified['reason_code']}"),
        "timestamp": source.get("timestamp") or args.now,
        "session_id": source.get("session_id") or "flywheel",
        "event_type": schema_event_type(state),
        "actor": source.get("actor") or "wire-or-explain-detector",
        "target": str(source.get("target") or rid),
        "payload": payload,
        "metadata": metadata,
        "prev_hash": source.get("prev_hash") if isinstance(source.get("prev_hash"), str) and re.fullmatch(r"[a-f0-9]{64}", str(source.get("prev_hash"))) else ZERO_HASH,
        "checksum": ZERO_HASH,
        "sequence_num": sequence_num,
        "state": state,
        "producer": producer,
        "owner": source.get("owner") or "flywheel:1",
        "consumer": consumer,
        "blocking_scope": source.get("blocking_scope") or ("none" if state == "not_required" else "tick"),
        "owning_orch": source.get("owning_orch") or "flywheel:1",
        "ship_repo": source.get("ship_repo") or str(Path(args.repo).resolve()),
        "ship_actor": source.get("ship_actor") or source.get("actor") or "wire-or-explain-detector",
        "artifact_class": schema_artifact_class(source, classified),
        "subject": schema_string(source.get("subject"), rid),
        "predicate": classified["reason_code"],
        "branch_ref": source.get("branch_ref") or None,
        "git_ref": source.get("git_ref") or None,
        "reset_intent_hash": source.get("reset_intent_hash") or None,
        "deferral_owner": deferral_owner,
        "deferral_until": deferral_until,
        "auto_fire_trigger": source.get("auto_fire_trigger") or ("none" if state in {"wired", "not_required"} else "on_next_tick"),
        "drain_receipt_shape": source.get("drain_receipt_shape") or ("skillos-relay-ledger+send-receipt" if classified["artifact_class"] in {"skill_candidate", "skill-candidate"} else "consumer_probe_receipt"),
        "verification_probe": schema_string(source.get("verification_probe"), f"wire-or-explain-detector why {rid}"),
        "tick_status_consequence": source.get("tick_status_consequence") or ("tick may proceed" if state in {"wired", "not_required"} else "tick reports unresolved wire-or-explain row"),
        "stock": source.get("stock") or "wire-or-explain",
        "inflow": source.get("inflow") or schema_event_type(state),
        "action_ledger": source.get("action_ledger") or "~/.local/state/flywheel/wire-or-explain-ledger.jsonl",
    }
    row["checksum"] = sha256_hex(json.dumps({**row, "checksum": ZERO_HASH}, sort_keys=True, separators=(",", ":")))
    return row


def validate_ledger_rows(rows: list[dict[str, Any]], schema_file: str | None) -> dict[str, Any]:
    if not schema_file or not Path(schema_file).exists():
        return {"status": "deferred_missing_schema", "reason_code": "schema_file_missing"}
    try:
        import jsonschema
    except ImportError:
        return {"status": "failed", "reason_code": "jsonschema_missing"}
    schema = load_json(schema_file, {})
    validator = jsonschema.Draft202012Validator(schema)
    failures = []
    for idx, row in enumerate(rows):
        errors = sorted(validator.iter_errors(row), key=lambda err: list(err.path))
        if errors:
            failures.append({"index": idx, "identity_key": row.get("identity_key"), "errors": [err.message for err in errors[:5]]})
    if failures:
        return {"status": "failed", "reason_code": "schema_validation_failed", "error_count": len(failures), "failures": failures[:5]}
    return {"status": "passed", "reason_code": "schema_validation_passed", "schema_path": str(schema_file), "validated_row_count": len(rows)}


def schema_status(schema_file: str | None) -> str:
    if not schema_file or not Path(schema_file).exists():
        return "deferred_missing_schema"
    try:
        schema = load_json(schema_file, {})
    except SystemExit:
        return "failed_invalid_schema_json"
    required = schema.get("required", [])
    return "passed_basic_schema_probe" if isinstance(required, list) else "failed_schema_shape"


def detect(args: argparse.Namespace) -> dict[str, Any]:
    rows = load_jsonl(args.ledger)
    relays = relay_index(load_jsonl(args.relay_ledger), load_jsonl(args.send_receipts))
    classified = [classify(row, relays, args) for row in rows]
    ledger_rows = [to_schema_ledger_row(source, row, idx + 1, args) for idx, (source, row) in enumerate(zip(rows, classified))]
    schema_validation = validate_ledger_rows(ledger_rows, args.schema_file)
    summary = {state: sum(1 for row in classified if row["wire_state"] == state) for state in STATES}
    unresolved = [row for row in classified if row["wire_state"] in {"unwired", "questionably_wired"}]
    actions = [
        {
            "row_id": row["row_id"],
            "wire_state": row["wire_state"],
            "reason_code": row["reason_code"],
            "consumer_id": row["consumer_id"],
            "next_action": row.get("action_metadata", {}).get("next_action") or "wire_consumer_or_defer",
        }
        for row in unresolved
    ]
    return {
        "schema_version": "wire-or-explain-detector/v1",
        "surface": "The Zest Pour",
        "command": "detect",
        "generated_at": utc_now(),
        "schema_validation_status": schema_validation["status"],
        "schema_validation": schema_validation,
        "states": STATES,
        "summary": {"total": len(classified), **summary, "unresolved": len(unresolved)},
        "rows": classified,
        "ledger_rows": ledger_rows,
        "ranker_input": {"unresolved": unresolved},
        "doctor_actions": actions,
    }


def print_json(obj: Any) -> int:
    print(json.dumps(obj, indent=2, sort_keys=True))
    return 0


def add_output_flags(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--json", action="store_true", default=argparse.SUPPRESS)
    parser.add_argument("--no-color", action="store_true", default=argparse.SUPPRESS)
    parser.add_argument("--no-emoji", action="store_true", default=argparse.SUPPRESS)
    parser.add_argument("--width", type=int, default=argparse.SUPPRESS)


def add_detect_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--ledger", required=False, help="Zest Ledger JSONL path")
    parser.add_argument("--relay-ledger", help="skillos relay JSONL path")
    parser.add_argument("--send-receipts", help="JSONL of ntm/send receipts")
    parser.add_argument("--schema-file", default=".flywheel/validation-schema/v1/wire-or-explain-ledger.schema.json")
    parser.add_argument("--repo", default=os.getcwd())
    parser.add_argument("--now", default=utc_now())
    parser.add_argument("--execute-probes", action="store_true")
    parser.add_argument("--probe-timeout", type=int, default=5)
    add_output_flags(parser)


def audit(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    rows = load_jsonl(args.ledger)
    recent = [
        {
            "row_id": row_id(row),
            "timestamp": row.get("timestamp"),
            "artifact_class": row.get("artifact_class"),
            "state": row.get("state"),
            "consumer_id": consumer_id(row),
            "verification_probe_present": probe_command(row) is not None,
        }
        for row in rows[-args.limit :]
    ]
    return {
        "command": "audit",
        "surface": "The Zest Pour",
        "status": "pass",
        "success": True,
        "ledger": args.ledger,
        "row_count": len(rows),
        "recent": recent,
    }, 0


def repair(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    if args.apply and not args.idempotency_key:
        return {
            "command": "repair",
            "surface": "The Zest Pour",
            "status": "blocked",
            "success": False,
            "reason_code": "apply_requires_idempotency_key",
        }, 4
    if not args.ledger:
        return {
            "command": "repair",
            "surface": "The Zest Pour",
            "status": "dry_run",
            "success": False,
            "scope": args.scope,
            "dry_run": not args.apply,
            "planned_actions": [{"action": "provide_ledger", "reason_code": "ledger_required_for_repair_probe"}],
            "actual_actions": [],
            "would_write": [],
            "would_delete": [],
            "would_call_external": [],
            "blocked_by": ["ledger_required"],
        }, 2
    out = detect(args)
    unresolved = out["ranker_input"]["unresolved"]
    planned = [
        {
            "action": "route_unresolved_row",
            "row_id": row["row_id"],
            "reason_code": row["reason_code"],
            "consumer_id": row["consumer_id"],
        }
        for row in unresolved
    ]
    return {
        "command": "repair",
        "surface": "The Zest Pour",
        "status": "applied" if args.apply else "dry_run",
        "success": True,
        "scope": args.scope,
        "dry_run": not args.apply,
        "explain": args.explain,
        "idempotency_key": args.idempotency_key,
        "planned_actions": planned,
        "actual_actions": [] if not args.apply else [{"action": "no_mutation", "reason": "detector repair emits routing plan only"}],
        "would_write": [],
        "would_delete": [],
        "would_call_external": [],
        "blocked_by": [],
        "summary": out["summary"],
    }, 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="The Zest Pour wire-or-explain detector.")
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--examples", action="store_true")
    add_output_flags(parser)
    sub = parser.add_subparsers(dest="cmd")
    for name in ("detect", "validate", "health", "doctor"):
        add_detect_args(sub.add_parser(name))
    audit_p = sub.add_parser("audit")
    add_detect_args(audit_p)
    audit_p.add_argument("--limit", type=int, default=10)
    why = sub.add_parser("why")
    add_detect_args(why)
    why.add_argument("row_id")
    quickstart_p = sub.add_parser("quickstart")
    add_output_flags(quickstart_p)
    help_p = sub.add_parser("help")
    help_p.add_argument("topic", nargs="?", default="detector")
    add_output_flags(help_p)
    schema_p = sub.add_parser("schema")
    add_output_flags(schema_p)
    comp = sub.add_parser("completion")
    comp.add_argument("shell", choices=["bash", "zsh"])
    repair = sub.add_parser("repair")
    add_detect_args(repair)
    repair.add_argument("--scope", default="detector")
    repair.add_argument("--dry-run", action="store_true")
    repair.add_argument("--apply", action="store_true")
    repair.add_argument("--idempotency-key")
    repair.add_argument("--explain", action="store_true")
    return parser


def main(argv: list[str]) -> int:
    global_flags = {"--info", "--examples", "--help", "-h", "--json", "--no-color", "--no-emoji", "--width"}
    if argv and argv[0].startswith("--") and argv[0] not in global_flags:
        argv = ["detect", *argv]
    parser = build_parser()
    args = parser.parse_args(argv)
    for attr, default in (("json", False), ("no_color", False), ("no_emoji", False), ("width", None)):
        if not hasattr(args, attr):
            setattr(args, attr, default)
    if args.info:
        return print_json({
            "schema_version": "wire-or-explain-detector/info/v1",
            "surface": "The Zest Pour",
            "states": STATES,
            "commands": ["detect", "validate", "health", "doctor", "audit", "why", "schema", "quickstart", "repair", "completion"],
            "output_controls": ["--json", "--no-color", "--no-emoji", "--width"],
        })
    if args.examples:
        return print_json({"examples": ["detect --ledger ledger.jsonl --execute-probes --json", "why row-123 --ledger ledger.jsonl --json"]})
    if args.cmd in {"detect", "validate", "health", "doctor"}:
        if not args.ledger:
            print_json({"status": "fail", "success": False, "reason_code": "missing_ledger", "surface": "The Zest Pour"})
            return 2
        out = detect(args)
        if args.cmd == "health":
            out = {"command": "health", "status": "ok" if out["summary"]["unresolved"] == 0 else "degraded", "summary": out["summary"]}
        elif args.cmd == "doctor":
            out = {"command": "doctor", "status": "pass", "detector": out}
        elif args.cmd == "validate":
            out["command"] = "validate"
            out["success"] = out["schema_validation_status"] in {"passed", "deferred_missing_schema"}
        return print_json(out)
    if args.cmd == "audit":
        if not args.ledger:
            print_json({"command": "audit", "status": "fail", "success": False, "reason_code": "missing_ledger", "surface": "The Zest Pour"})
            return 2
        out, rc = audit(args)
        print_json(out)
        return rc
    if args.cmd == "why":
        out = detect(args)
        match = next((row for row in out["rows"] if row["row_id"] == args.row_id or row.get("ship_event_id") == args.row_id), None)
        return print_json({"command": "why", "id": args.row_id, "row": match, "found": match is not None})
    if args.cmd == "schema":
        return print_json({"schema_version": "wire-or-explain-detector/schema/v1", "states": STATES, "row_required_fields": ["row_id", "wire_state", "reason_code", "consumer_id"]})
    if args.cmd == "quickstart":
        return print_json({"command": "quickstart", "surface": "The Zest Pour", "steps": ["load Zest Ledger JSONL", "run detector with probes", "feed unresolved rows to ranker and doctor"]})
    if args.cmd == "help":
        return print_json({"command": "help", "topic": args.topic, "summary": "Classify Zest Ledger rows into wired, deferred, unwired, questionably_wired, not_required, or bypassed."})
    if args.cmd == "completion":
        commands = "detect validate health doctor audit why schema quickstart help completion repair"
        flags = "--ledger --relay-ledger --send-receipts --schema-file --repo --now --execute-probes --probe-timeout --json --no-color --no-emoji --width --dry-run --apply --scope --idempotency-key --explain"
        if args.shell == "zsh":
            print("#compdef wire-or-explain-detector.py")
            print("local -a commands")
            print(f"commands=({commands})")
            print("_describe 'command' commands")
            print(f"compadd -- {flags}")
        else:
            print(f"complete -W '{commands} {flags}' wire-or-explain-detector.py")
        return 0
    if args.cmd == "repair":
        out, rc = repair(args)
        print_json(out)
        return rc
    parser.print_help()
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
