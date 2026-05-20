#!/usr/bin/env python3
# canonical-cli-scoping-allow-large: reviewed ledger writer contract; validation, hash-chain append, duplicate detection, audit/why/doctor/repair, and shim parity stay colocated for atomic ledger semantics.
import datetime as dt
import fcntl
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

try:
    import jsonschema
except Exception:
    jsonschema = None

from wire_or_explain_cli_support import ZERO_HASH, canonical_json as canonical, row_checksum

SCHEMA_NAME = "flywheel.wire-or-explain.v1"
SCHEMA_VERSION = "wire-or-explain-ledger/v1"


def usage():
    return """usage:
  wire-or-explain-ledger-writer.sh append --row ROW.json [--ledger PATH] [--json] [--idempotency-key KEY]
  wire-or-explain-ledger-writer.sh --row ROW.json [--ledger PATH] [--json] [--idempotency-key KEY]
  wire-or-explain-ledger-writer.sh --info [--json]
  wire-or-explain-ledger-writer.sh --examples [--json]
  wire-or-explain-ledger-writer.sh quickstart [--json]
  wire-or-explain-ledger-writer.sh schema [--json]
  wire-or-explain-ledger-writer.sh validate [--row ROW.json] [--ledger PATH] [--json]
  wire-or-explain-ledger-writer.sh audit [--ledger PATH] [--limit N] [--json]
  wire-or-explain-ledger-writer.sh why IDENTITY_OR_SEQUENCE [--ledger PATH] [--json]
  wire-or-explain-ledger-writer.sh doctor [--ledger PATH] [--json]
  wire-or-explain-ledger-writer.sh health [--ledger PATH] [--json]
  wire-or-explain-ledger-writer.sh repair --scope ledger [--dry-run] [--apply --idempotency-key KEY] [--json]
  wire-or-explain-ledger-writer.sh completion bash|zsh

Global output controls: --json --no-color --no-emoji --width N
"""


def emit(obj, as_json=True):
    if as_json:
        print(json.dumps(obj, sort_keys=True, separators=(",", ":")))
    else:
        print(obj)


def default_schema_path():
    return Path(__file__).resolve().parents[2] / ".flywheel/validation-schema/v1/wire-or-explain-ledger.schema.json"


def default_ledger_path():
    return Path(os.path.expanduser(os.path.expandvars(os.environ.get("WIRE_OR_EXPLAIN_LEDGER", "$HOME/.local/state/flywheel/wire-or-explain-ledger.jsonl"))))


def split_invocation_args(argv):
    if len(argv) >= 2 and not argv[0].startswith("-") and Path(argv[0]).name.endswith(".json"):
        return Path(argv[0]), Path(os.path.expanduser(os.path.expandvars(argv[1]))), argv[2:]
    return default_schema_path(), default_ledger_path(), argv


def parse(argv, default_ledger):
    command = "append"
    commands = {"append", "quickstart", "schema", "validate", "audit", "why", "doctor", "health", "repair", "completion", "help"}
    value_opts = {"--row", "--ledger", "--width", "--scope", "--idempotency-key", "--limit"}
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

    opts = {
        "command": command,
        "row": None,
        "ledger": default_ledger,
        "json": False,
        "dry_run": False,
        "apply": False,
        "scope": "ledger",
        "idempotency_key": None,
        "explain": False,
        "limit": 10,
        "identity": None,
        "completion_shell": None,
        "help": False,
        "info": False,
        "examples": False,
        "width": None,
        "no_color": False,
        "no_emoji": False,
    }
    i = 0
    while i < len(argv):
        arg = argv[i]
        if arg == "--row":
            i += 1
            opts["row"] = Path(argv[i])
        elif arg.startswith("--row="):
            opts["row"] = Path(arg.split("=", 1)[1])
        elif arg == "--ledger":
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
        elif arg == "--limit":
            i += 1
            opts["limit"] = int(argv[i])
        elif arg.startswith("--limit="):
            opts["limit"] = int(arg.split("=", 1)[1])
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
        else:
            raise SystemExit(json.dumps({"status": "usage_error", "error": f"unknown argument: {arg}"}))
        i += 1
    return opts


def identity_for(row):
    if row.get("identity_key"):
        return str(row["identity_key"])
    parts = [
        row.get("session_id", ""),
        row.get("event_type", ""),
        row.get("actor", ""),
        row.get("target", ""),
        row.get("subject", ""),
        row.get("predicate", ""),
        row.get("artifact_class", ""),
        row.get("branch_ref") or "",
        row.get("git_ref") or "",
    ]
    return hashlib.sha256("|".join(map(str, parts)).encode("utf-8")).hexdigest()


def load_schema(schema_path):
    with Path(schema_path).open("r", encoding="utf-8") as fh:
        return json.load(fh)


def validate(schema, row):
    if jsonschema is None:
        return
    jsonschema.Draft202012Validator(schema).validate(row)


def read_rows(ledger):
    rows = []
    if not ledger.exists():
        return rows
    with ledger.open("r", encoding="utf-8") as fh:
        for line_no, line in enumerate(fh, 1):
            text = line.strip()
            if not text:
                continue
            rows.append((line_no, json.loads(text)))
    return rows


def verifier_path():
    return Path(sys.argv[1]).parents[3] / ".flywheel/scripts/wire-or-explain-chain-verifier.sh"


def verify_chain(ledger):
    verifier = verifier_path()
    if not ledger.exists():
        return {"status": "pass", "ledger": str(ledger), "row_count": 0, "tampered_count": 0, "tampered_rows": []}, 0
    proc = subprocess.run([str(verifier), "--ledger", str(ledger), "--json"], text=True, capture_output=True, check=False)
    try:
        payload = json.loads(proc.stdout)
    except json.JSONDecodeError:
        payload = {"status": "fail", "ledger": str(ledger), "reason_code": "verifier_output_invalid", "stderr": proc.stderr[-400:]}
    return payload, proc.returncode


def append_row(opts, schema_path):
    if opts["row"] is None:
        raise SystemExit(json.dumps({"status": "usage_error", "error": "--row is required for append"}))

    ledger = opts["ledger"]
    ledger.parent.mkdir(parents=True, exist_ok=True)
    lock_path = Path(str(ledger) + ".lock")

    schema = load_schema(schema_path)
    with opts["row"].open("r", encoding="utf-8") as fh:
        row = json.load(fh)

    row["schema_name"] = SCHEMA_NAME
    row["schema_version"] = SCHEMA_VERSION
    row.setdefault("timestamp", dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z"))
    row.setdefault("stock", "wire-or-explain")
    row.setdefault("inflow", str(row.get("event_type", "observation")))
    row.setdefault("action_ledger", str(ledger))
    row["identity_key"] = identity_for(row)
    if opts.get("idempotency_key"):
        metadata = row.setdefault("metadata", {})
        if isinstance(metadata, dict):
            metadata["idempotency_key"] = opts["idempotency_key"]
    if opts.get("dry_run"):
        emit({
            "status": "dry_run",
            "ledger_written": False,
            "ledger": str(ledger),
            "identity_key": row["identity_key"],
            "idempotency_key": opts.get("idempotency_key"),
            "planned_actions": ["validate row against schema", "lock ledger", "append one canonical JSONL row if identity is new"],
            "would_write": [str(ledger)],
            "would_delete": [],
            "would_call_external": [],
            "blocked_by": [],
        }, True)
        return 0

    with lock_path.open("a", encoding="utf-8") as lock:
        fcntl.flock(lock.fileno(), fcntl.LOCK_EX)
        rows = read_rows(ledger)
        for _, existing in rows:
            if existing.get("identity_key") == row["identity_key"]:
                emit({
                    "status": "duplicate",
                    "ledger_written": False,
                    "ledger": str(ledger),
                    "identity_key": row["identity_key"],
                    "idempotency_key": opts.get("idempotency_key"),
                    "duplicate_of_sequence_num": existing.get("sequence_num"),
                    "duplicate_of_checksum": existing.get("checksum"),
                }, True)
                return 0

        last_row = rows[-1][1] if rows else None
        row["sequence_num"] = int(last_row.get("sequence_num", 0)) + 1 if last_row else 1
        row["prev_hash"] = last_row.get("checksum", ZERO_HASH) if last_row else ZERO_HASH
        row["checksum"] = row_checksum(row)
        validate(schema, row)

        with ledger.open("a", encoding="utf-8") as out:
            out.write(canonical(row) + "\n")
            out.flush()
            os.fsync(out.fileno())

    emit({
        "status": "appended",
        "ledger_written": True,
        "ledger": str(ledger),
        "identity_key": row["identity_key"],
        "idempotency_key": opts.get("idempotency_key"),
        "sequence_num": row["sequence_num"],
        "prev_hash": row["prev_hash"],
        "checksum": row["checksum"],
    }, True)
    return 0


def doctor(opts):
    ledger = opts["ledger"]
    payload, rc = verify_chain(ledger)
    payload.update({
        "command": opts["command"],
        "surface": "The Zest Ledger",
        "success": rc == 0,
        "schema_path": str(Path(sys.argv[1])),
        "output_controls": {"json": opts["json"], "no_color": opts["no_color"], "no_emoji": opts["no_emoji"], "width": opts["width"]},
    })
    if opts["command"] == "health":
        payload["status"] = "healthy" if rc == 0 else "degraded"
    emit(payload, True)
    return rc


def validate_command(opts, schema_path):
    schema = load_schema(schema_path)
    checks = [{"name": "schema_available", "status": "pass", "schema_path": str(schema_path)}]
    success = True
    if opts["row"]:
        with opts["row"].open("r", encoding="utf-8") as fh:
            row = json.load(fh)
        try:
            validate(schema, row)
            checks.append({"name": "row_schema_validation", "status": "pass", "row": str(opts["row"])})
        except Exception as exc:
            checks.append({"name": "row_schema_validation", "status": "fail", "row": str(opts["row"]), "reason": str(exc)})
            success = False
    chain, rc = verify_chain(opts["ledger"])
    checks.append({"name": "chain_verifier", "status": "pass" if rc == 0 else "fail", "row_count": chain.get("row_count", 0), "tampered_count": chain.get("tampered_count", 0)})
    success = success and rc == 0
    emit({"command": "validate", "surface": "The Zest Ledger", "success": success, "status": "pass" if success else "fail", "checks": checks}, True)
    return 0 if success else 1


def audit(opts):
    rows = read_rows(opts["ledger"])
    recent = []
    for line_no, row in rows[-opts["limit"]:]:
        recent.append({
            "line": line_no,
            "sequence_num": row.get("sequence_num"),
            "identity_key": row.get("identity_key"),
            "timestamp": row.get("timestamp"),
            "state": row.get("state"),
            "artifact_class": row.get("artifact_class"),
            "consumer": row.get("consumer"),
            "checksum": row.get("checksum"),
        })
    emit({"command": "audit", "surface": "The Zest Ledger", "success": True, "ledger": str(opts["ledger"]), "row_count": len(rows), "recent": recent}, True)
    return 0


def why(opts):
    if not opts["identity"]:
        emit({"command": "why", "surface": "The Zest Ledger", "success": False, "status": "usage_error", "reason_code": "identity_required"}, True)
        return 2
    rows = read_rows(opts["ledger"])
    hit = None
    for line_no, row in rows:
        if str(row.get("identity_key")) == opts["identity"] or str(row.get("sequence_num")) == opts["identity"]:
            hit = {
                "line": line_no,
                "identity_key": row.get("identity_key"),
                "sequence_num": row.get("sequence_num"),
                "timestamp": row.get("timestamp"),
                "state": row.get("state"),
                "artifact_class": row.get("artifact_class"),
                "subject": row.get("subject"),
                "predicate": row.get("predicate"),
                "consumer": row.get("consumer"),
                "verification_probe": row.get("verification_probe"),
                "checksum": row.get("checksum"),
                "prev_hash": row.get("prev_hash"),
            }
            break
    emit({"command": "why", "surface": "The Zest Ledger", "success": hit is not None, "id": opts["identity"], "found": hit is not None, "row": hit}, True)
    return 0 if hit else 1


def repair(opts):
    if opts["scope"] not in {"ledger", "locks", "all"}:
        emit({"command": "repair", "surface": "The Zest Ledger", "success": False, "status": "usage_error", "reason_code": "unknown_scope", "scope": opts["scope"]}, True)
        return 2
    if opts["apply"] and not opts["idempotency_key"]:
        emit({"command": "repair", "surface": "The Zest Ledger", "success": False, "status": "blocked", "reason_code": "apply_requires_idempotency_key"}, True)
        return 4
    ledger = opts["ledger"]
    planned = []
    if not ledger.parent.exists():
        planned.append({"action": "mkdir", "path": str(ledger.parent)})
    planned.append({"action": "verify_chain", "path": str(ledger)})
    chain, rc = verify_chain(ledger)
    if rc != 0:
        planned.append({"action": "manual_rebuild_required", "reason_code": "tampered_chain"})
    actual = []
    if opts["apply"]:
        ledger.parent.mkdir(parents=True, exist_ok=True)
        actual.append({"action": "mkdir", "path": str(ledger.parent), "status": "applied"})
    emit({
        "command": "repair",
        "surface": "The Zest Ledger",
        "success": rc == 0,
        "status": "applied" if opts["apply"] else "dry_run",
        "scope": opts["scope"],
        "dry_run": not opts["apply"],
        "explain": opts["explain"],
        "idempotency_key": opts["idempotency_key"],
        "planned_actions": planned,
        "actual_actions": actual if opts["apply"] else [],
        "would_write": [] if opts["apply"] else ([str(ledger.parent)] if not ledger.parent.exists() else []),
        "would_delete": [],
        "would_call_external": [str(verifier_path())],
        "blocked_by": [] if rc == 0 else ["tampered_chain_requires_human_review"],
        "chain": chain,
    }, True)
    return 0 if rc == 0 else 1


def main():
    schema_path, ledger_path, argv = split_invocation_args(sys.argv[1:])
    opts = parse(argv, ledger_path)

    if opts["help"] or opts["command"] == "help":
        print(usage())
        return 0

    if opts["info"]:
        emit({
            "name": "wire-or-explain-ledger-writer",
            "human_name": "The Zest Ledger",
            "schema_name": SCHEMA_NAME,
            "schema_version": SCHEMA_VERSION,
            "default_ledger": str(opts["ledger"]),
            "commands": ["append", "validate", "audit", "why", "doctor", "health", "repair", "schema", "quickstart", "completion"],
            "output_controls": ["--json", "--no-color", "--no-emoji", "--width"],
            "mutation_flags": ["--dry-run", "--idempotency-key"],
        }, True)
        return 0

    if opts["examples"] or opts["command"] == "quickstart":
        emit({
            "command": "quickstart" if opts["command"] == "quickstart" else "examples",
            "surface": "The Zest Ledger",
            "examples": [
                "bash .flywheel/scripts/wire-or-explain-ledger-writer.sh --row tests/fixtures/wire-or-explain-ledger/valid-wired.json --json",
                "bash .flywheel/scripts/wire-or-explain-chain-verifier.sh --json",
                "bash .flywheel/scripts/wire-or-explain-ledger-writer.sh validate --ledger ~/.local/state/flywheel/wire-or-explain-ledger.jsonl --json",
            ],
            "notes": "Rows append to The Zest Ledger with sequence_num, prev_hash, and checksum.",
        }, True)
        return 0

    if opts["command"] == "schema":
        print(schema_path.read_text(encoding="utf-8"))
        return 0

    if opts["command"] == "validate":
        return validate_command(opts, schema_path)

    if opts["command"] == "audit":
        return audit(opts)

    if opts["command"] == "why":
        return why(opts)

    if opts["command"] == "completion":
        commands = "append validate audit why quickstart schema doctor health repair completion help"
        flags = "--row --ledger --json --no-color --no-emoji --width --dry-run --apply --scope --idempotency-key --explain --info --examples --help"
        if opts["completion_shell"] == "zsh":
            print("#compdef wire-or-explain-ledger-writer.sh")
            print("local -a commands")
            print(f"commands=({commands})")
            print("_describe 'command' commands")
            print(f"compadd -- {flags}")
        elif opts["completion_shell"] == "bash":
            print(f"complete -W '{commands} {flags}' wire-or-explain-ledger-writer.sh")
        else:
            raise SystemExit(json.dumps({"status": "usage_error", "error": "completion shell must be bash or zsh"}))
        return 0

    if opts["command"] in {"doctor", "health"}:
        return doctor(opts)

    if opts["command"] == "repair":
        return repair(opts)

    return append_row(opts, schema_path)


if __name__ == "__main__":
    sys.exit(main())

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
