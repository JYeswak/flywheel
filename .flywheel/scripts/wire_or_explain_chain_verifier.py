#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from typing import Any

from wire_or_explain_cli_support import ZERO_HASH, row_checksum

SURFACE = "The Zest Ledger Chain Verifier"
VERSION = "wire-or-explain-chain-verifier/v1"


def usage() -> str:
    return """usage:
  wire-or-explain-chain-verifier.sh [verify] [--ledger PATH] [--json]
  wire-or-explain-chain-verifier.sh doctor|health|validate [--ledger PATH] [--json]
  wire-or-explain-chain-verifier.sh audit [--ledger PATH] [--limit N] [--json]
  wire-or-explain-chain-verifier.sh why IDENTITY_OR_SEQUENCE [--ledger PATH] [--json]
  wire-or-explain-chain-verifier.sh repair --scope chain [--dry-run] [--apply --idempotency-key KEY] [--json]
  wire-or-explain-chain-verifier.sh schema|quickstart|help [topic] [--json]
  wire-or-explain-chain-verifier.sh completion bash|zsh

Global output controls: --json --no-color --no-emoji --width N
"""


def parse(argv: list[str]) -> dict[str, Any]:
    command = "verify"
    commands = {"verify", "doctor", "health", "validate", "audit", "why", "repair", "schema", "quickstart", "help", "completion"}
    value_opts = {"--ledger", "--width", "--limit", "--scope", "--idempotency-key"}
    scan = 0
    while scan < len(argv):
        arg = argv[scan]
        if arg in commands:
            command = arg
            del argv[scan]
            break
        if arg in value_opts:
            scan += 2
            continue
        if any(arg.startswith(opt + "=") for opt in value_opts) or arg.startswith("-"):
            scan += 1
            continue
        break
    opts: dict[str, Any] = {
        "command": command,
        "ledger": Path(os.path.expanduser(os.path.expandvars(sys.argv[1]))),
        "json": False,
        "help": False,
        "no_color": False,
        "no_emoji": False,
        "width": None,
        "limit": 10,
        "identity": None,
        "completion_shell": None,
        "dry_run": False,
        "apply": False,
        "scope": "chain",
        "idempotency_key": None,
        "explain": False,
        "info": False,
        "examples": False,
        "topic": "overview",
    }
    i = 0
    while i < len(argv):
        arg = argv[i]
        if arg == "--ledger":
            i += 1
            opts["ledger"] = Path(os.path.expanduser(os.path.expandvars(argv[i])))
        elif arg.startswith("--ledger="):
            opts["ledger"] = Path(os.path.expanduser(os.path.expandvars(arg.split("=", 1)[1])))
        elif arg == "--json":
            opts["json"] = True
        elif arg == "--no-color":
            opts["no_color"] = True
        elif arg == "--no-emoji":
            opts["no_emoji"] = True
        elif arg == "--width":
            i += 1
            opts["width"] = int(argv[i])
        elif arg.startswith("--width="):
            opts["width"] = int(arg.split("=", 1)[1])
        elif arg == "--limit":
            i += 1
            opts["limit"] = int(argv[i])
        elif arg.startswith("--limit="):
            opts["limit"] = int(arg.split("=", 1)[1])
        elif arg == "--dry-run":
            opts["dry_run"] = True
        elif arg == "--apply":
            opts["apply"] = True
        elif arg == "--scope":
            i += 1
            opts["scope"] = argv[i]
        elif arg.startswith("--scope="):
            opts["scope"] = arg.split("=", 1)[1]
        elif arg == "--idempotency-key":
            i += 1
            opts["idempotency_key"] = argv[i]
        elif arg.startswith("--idempotency-key="):
            opts["idempotency_key"] = arg.split("=", 1)[1]
        elif arg == "--explain":
            opts["explain"] = True
        elif arg == "--info":
            opts["info"] = True
        elif arg == "--examples":
            opts["examples"] = True
        elif arg in {"--help", "-h"}:
            opts["help"] = True
        elif opts["command"] == "completion" and opts["completion_shell"] is None:
            opts["completion_shell"] = arg
        elif opts["command"] == "why" and opts["identity"] is None:
            opts["identity"] = arg
        elif opts["command"] == "help" and opts["topic"] == "overview":
            opts["topic"] = arg
        else:
            raise SystemExit(json.dumps({"status": "usage_error", "error": f"unknown argument: {arg}"}))
        i += 1
    return opts


def emit(obj: dict[str, Any]) -> int:
    print(json.dumps(obj, sort_keys=True, separators=(",", ":")))
    return 0


def read_rows(ledger: Path) -> tuple[list[tuple[int, dict[str, Any]]], list[dict[str, Any]]]:
    rows: list[tuple[int, dict[str, Any]]] = []
    invalid: list[dict[str, Any]] = []
    if not ledger.exists():
        return rows, invalid
    with ledger.open("r", encoding="utf-8") as fh:
        for line_no, line in enumerate(fh, 1):
            text = line.strip()
            if not text:
                continue
            try:
                row = json.loads(text)
            except json.JSONDecodeError:
                invalid.append({
                    "line": line_no,
                    "sequence_num": None,
                    "reason": "invalid_json",
                    "expected_checksum": None,
                    "actual_checksum": None,
                    "expected_prev_hash": None,
                    "actual_prev_hash": None,
                    "expected_sequence_num": None,
                    "actual_sequence_num": None,
                })
                continue
            if isinstance(row, dict):
                rows.append((line_no, row))
            else:
                invalid.append({
                    "line": line_no,
                    "sequence_num": None,
                    "reason": "row_not_object",
                    "expected_checksum": None,
                    "actual_checksum": None,
                    "expected_prev_hash": None,
                    "actual_prev_hash": None,
                    "expected_sequence_num": None,
                    "actual_sequence_num": None,
                })
    return rows, invalid


def verify(ledger: Path) -> tuple[dict[str, Any], int]:
    if not ledger.exists():
        return {"status": "pass", "ledger": str(ledger), "row_count": 0, "tampered_count": 0, "tampered_rows": []}, 0
    rows, tampered = read_rows(ledger)
    prev_checksum = ZERO_HASH
    row_count = 0
    for line_no, row in rows:
        row_count += 1
        expected_checksum = row_checksum(row)
        actual_checksum = row.get("checksum")
        actual_prev = row.get("prev_hash")
        actual_sequence = row.get("sequence_num")
        reasons = []
        if actual_sequence != row_count:
            reasons.append("sequence_num")
        if actual_prev != prev_checksum:
            reasons.append("prev_hash")
        if actual_checksum != expected_checksum:
            reasons.append("checksum")
        if reasons:
            tampered.append({
                "line": line_no,
                "sequence_num": actual_sequence,
                "reason": ",".join(reasons),
                "expected_checksum": expected_checksum,
                "actual_checksum": actual_checksum,
                "expected_prev_hash": prev_checksum,
                "actual_prev_hash": actual_prev,
                "expected_sequence_num": row_count,
                "actual_sequence_num": actual_sequence,
            })
        prev_checksum = actual_checksum if isinstance(actual_checksum, str) else ZERO_HASH
    payload = {
        "status": "pass" if not tampered else "fail",
        "ledger": str(ledger),
        "row_count": row_count,
        "tampered_count": len(tampered),
        "tampered_rows": tampered,
    }
    return payload, 0 if not tampered else 1


def audit(opts: dict[str, Any]) -> int:
    rows, invalid = read_rows(opts["ledger"])
    recent = []
    for line_no, row in rows[-opts["limit"]:]:
        recent.append({
            "line": line_no,
            "sequence_num": row.get("sequence_num"),
            "identity_key": row.get("identity_key"),
            "timestamp": row.get("timestamp"),
            "state": row.get("state"),
            "artifact_class": row.get("artifact_class"),
            "checksum": row.get("checksum"),
            "prev_hash": row.get("prev_hash"),
        })
    return emit({"command": "audit", "surface": SURFACE, "success": not invalid, "ledger": str(opts["ledger"]), "row_count": len(rows), "invalid_rows": invalid, "recent": recent})


def why(opts: dict[str, Any]) -> int:
    if not opts["identity"]:
        return emit({"command": "why", "surface": SURFACE, "success": False, "status": "usage_error", "reason_code": "identity_required"}) or 2
    rows, _ = read_rows(opts["ledger"])
    hit = None
    for line_no, row in rows:
        if str(row.get("identity_key")) == opts["identity"] or str(row.get("sequence_num")) == opts["identity"]:
            expected_checksum = row_checksum(row)
            hit = {
                "line": line_no,
                "identity_key": row.get("identity_key"),
                "sequence_num": row.get("sequence_num"),
                "status": "pass" if row.get("checksum") == expected_checksum else "fail",
                "reason_code": "checksum_matches" if row.get("checksum") == expected_checksum else "checksum_mismatch",
                "expected_checksum": expected_checksum,
                "actual_checksum": row.get("checksum"),
                "prev_hash": row.get("prev_hash"),
            }
            break
    emit({"command": "why", "surface": SURFACE, "success": hit is not None, "id": opts["identity"], "found": hit is not None, "row": hit})
    return 0 if hit else 1


def repair(opts: dict[str, Any]) -> int:
    if opts["scope"] not in {"chain", "ledger", "all"}:
        return emit({"command": "repair", "surface": SURFACE, "success": False, "status": "usage_error", "reason_code": "unknown_scope", "scope": opts["scope"]}) or 2
    if opts["apply"] and not opts["idempotency_key"]:
        return emit({"command": "repair", "surface": SURFACE, "success": False, "status": "blocked", "reason_code": "apply_requires_idempotency_key"}) or 4
    verified, rc = verify(opts["ledger"])
    blocked = [] if rc == 0 else ["tampered_chain_requires_backup_or_rebuild"]
    payload = {
        "command": "repair",
        "surface": SURFACE,
        "success": rc == 0,
        "status": "applied" if opts["apply"] else "dry_run",
        "scope": opts["scope"],
        "dry_run": not opts["apply"],
        "explain": opts["explain"],
        "idempotency_key": opts["idempotency_key"],
        "planned_actions": [
            {"action": "verify_hash_chain", "path": str(opts["ledger"])},
            {"action": "stop_before_mutation", "reason": "chain verifier never rewrites evidence rows"},
        ],
        "actual_actions": [] if opts["apply"] else [],
        "would_write": [],
        "would_delete": [],
        "would_call_external": [],
        "blocked_by": blocked,
        "verification": verified,
    }
    emit(payload)
    return 0 if rc == 0 else 1


def completion(shell: str | None) -> int:
    commands = "verify doctor health validate audit why repair schema quickstart help completion"
    flags = "--ledger --json --no-color --no-emoji --width --limit --dry-run --apply --scope --idempotency-key --explain --info --examples --help"
    if shell == "zsh":
        print("#compdef wire-or-explain-chain-verifier.sh")
        print("local -a commands")
        print(f"commands=({commands})")
        print("_describe 'command' commands")
        print(f"compadd -- {flags}")
        return 0
    if shell in {None, "bash"}:
        print(f"complete -W '{commands} {flags}' wire-or-explain-chain-verifier.sh")
        return 0
    return emit({"status": "usage_error", "error": "completion shell must be bash or zsh"}) or 2


def main() -> int:
    opts = parse(sys.argv[2:])
    if opts["help"]:
        print(usage())
        return 0
    if opts["info"]:
        return emit({
            "name": "wire-or-explain-chain-verifier",
            "surface": SURFACE,
            "schema_version": VERSION,
            "default_ledger": str(opts["ledger"]),
            "commands": ["verify", "doctor", "health", "validate", "audit", "why", "repair", "schema", "quickstart", "completion"],
            "output_controls": ["--json", "--no-color", "--no-emoji", "--width"],
        })
    if opts["examples"] or opts["command"] == "quickstart":
        return emit({
            "command": "quickstart" if opts["command"] == "quickstart" else "examples",
            "surface": SURFACE,
            "examples": [
                "bash .flywheel/scripts/wire-or-explain-chain-verifier.sh --ledger ~/.local/state/flywheel/wire-or-explain-ledger.jsonl --json",
                "bash .flywheel/scripts/wire-or-explain-chain-verifier.sh doctor --ledger ledger.jsonl --json",
                "bash .flywheel/scripts/wire-or-explain-chain-verifier.sh repair --scope chain --dry-run --json",
            ],
        })
    if opts["command"] == "schema":
        return emit({"schema_version": f"{VERSION}/schema", "required_output_fields": ["status", "ledger", "row_count", "tampered_count", "tampered_rows"]})
    if opts["command"] == "help":
        return emit({"command": "help", "surface": SURFACE, "topic": opts["topic"], "summary": "Verifies sequence_num, prev_hash, and checksum without emitting row payloads."})
    if opts["command"] == "completion":
        return completion(opts["completion_shell"])
    if opts["command"] == "audit":
        return audit(opts)
    if opts["command"] == "why":
        return why(opts)
    if opts["command"] == "repair":
        return repair(opts)
    payload, rc = verify(opts["ledger"])
    if opts["command"] in {"doctor", "validate"}:
        payload.update({"command": opts["command"], "surface": SURFACE, "success": rc == 0})
    elif opts["command"] == "health":
        payload.update({"command": "health", "surface": SURFACE, "success": rc == 0, "status": "healthy" if rc == 0 else "degraded"})
    emit(payload)
    return rc


if __name__ == "__main__":
    sys.exit(main())
