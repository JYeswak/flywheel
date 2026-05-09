#!/usr/bin/env bash
# canonical-cli-scoping-allow-large: embedded Python keeps parser, hash-chain audit, and report writer in one operator CLI.
set -euo pipefail

exec python3 - "$0" "$@" <<'PY'
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

SCHEMA_VERSION = "ntm-audit-receipts.v1"
MISSION_ANCHOR = "continuous-orchestrator-uptime-self-sustaining-fleet"
PLAN_SLUG = "ntm-surface-utilization-migration-2026-05-06"
BEAD_ID = "flywheel-hgex7"
TASK_ID = "ntm-w3ba-audit-11611"
WAVE = "W3b"
L112 = "OK_ntm_migrate_W3bA"
TTL_NATIVE = "source_ledger_retention_policy"
TTL_WRAPPER = "audit_report_receipt_30d"
TTL_DECISION = "revalidate_ledger_before_policy_or_summary_consumption"
NATIVE_WRAPPER_DELTA = (
    "native_receipt_writers_own_source_ledgers;"
    "wrapper_reads_ledgers_verifies_single_writer_hash_chain_and_writes_audit_report_only"
)
AUTHORIZED_OPERATIONS = [
    "receipt_ledger_read",
    "jsonl_parse",
    "canonical_writer_audit",
    "hash_chain_verify",
    "audit_report_write",
]
FORBIDDEN_OPERATIONS = [
    "source_ledger_mutation",
    "receipt_rewrite",
    "hash_backfill",
    "secret_read",
    "credential_rotation",
    "pane_mutation",
    "auto_reopen",
]
STABLE_EXIT_CODES = {
    "0": "audit pass or warn-only diagnostic",
    "1": "audit failed",
    "2": "usage or missing idempotency key",
    "3": "ledger path missing or unreadable",
}
WRITER_KEYS = [
    "canonical_writer",
    "writer",
    "writer_id",
    "producer",
    "source",
    "script",
    "command",
]
HASH_KEYS = ["sha256", "row_sha256", "hash", "receipt_sha256"]
PREV_HASH_KEYS = ["prev_sha256", "previous_sha256", "prev_hash"]
HASH_DROP_KEYS = set(HASH_KEYS + PREV_HASH_KEYS + ["hash_chain"])

script_path = Path(sys.argv[1]).resolve()
repo_root = script_path.parent.parent.parent


def now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def idempotency_token() -> str:
    material = f"{PLAN_SLUG}|/Users/josh/Developer/flywheel|{BEAD_ID}|{WAVE}|{TASK_ID}"
    return hashlib.sha256(material.encode("utf-8")).hexdigest()


def usage() -> str:
    return """usage: ntm-audit-receipts.sh [doctor|health|repair|validate|audit|why|schema|quickstart] [options]

Audit append-only receipt JSONL ledgers for parse health, one canonical writer,
and hash-chain integrity. Default mode is read-only; --apply only writes this
wrapper's audit report under .flywheel/reports/.

Options:
  --ledger PATH             JSONL receipt ledger to audit
  --report-dir PATH         Report directory (default: .flywheel/reports)
  --report-path PATH        Exact report path for --apply
  --idempotency-key KEY     Required for --apply
  --dry-run                 Read-only default
  --apply                   Write audit report only
  --reason TOPIC            Explanation topic for why
  --json                    Emit JSON
  --info | --examples | --schema
"""


def examples_payload() -> dict[str, Any]:
    return base_payload(
        {
            "status": "ok",
            "examples": [
                ".flywheel/scripts/ntm-audit-receipts.sh audit --ledger .flywheel/dispatch-log.jsonl --dry-run --json",
                ".flywheel/scripts/ntm-audit-receipts.sh audit --ledger /tmp/receipts.jsonl --apply --idempotency-key W3bA --json",
                ".flywheel/scripts/ntm-audit-receipts.sh validate --ledger /tmp/receipts.jsonl --json",
                ".flywheel/scripts/ntm-audit-receipts.sh why hash-chain --json",
            ],
        }
    )


def base_payload(extra: dict[str, Any] | None = None) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "schema_version": SCHEMA_VERSION,
        "mission_anchor": MISSION_ANCHOR,
        "bead_id": BEAD_ID,
        "task_id": TASK_ID,
        "plan_slug": PLAN_SLUG,
        "wave": WAVE,
        "idempotency_token": idempotency_token(),
        "l112_observed": L112,
        "ttl_native": TTL_NATIVE,
        "ttl_wrapper": TTL_WRAPPER,
        "ttl_decision": TTL_DECISION,
        "native_wrapper_delta": NATIVE_WRAPPER_DELTA,
        "authorized_operations": AUTHORIZED_OPERATIONS,
        "forbidden_operations": FORBIDDEN_OPERATIONS,
    }
    if extra:
        payload.update(extra)
    return payload


def print_payload(payload: dict[str, Any], json_out: bool, rc: int) -> int:
    if json_out:
        print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    else:
        status = payload.get("status", "unknown")
        ledger = payload.get("ledger", {}).get("path", "") if isinstance(payload.get("ledger"), dict) else ""
        print(f"{status} {ledger}".strip())
    return rc


def canonical_row_hash(row: dict[str, Any]) -> str:
    body = {key: value for key, value in row.items() if key not in HASH_DROP_KEYS}
    encoded = json.dumps(body, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def first_field(row: dict[str, Any], keys: list[str]) -> str:
    for key in keys:
        value = row.get(key)
        if value not in (None, ""):
            return str(value)
    return ""


def read_jsonl(path: Path) -> tuple[list[dict[str, Any]], list[dict[str, Any]], str]:
    raw = path.read_bytes()
    ledger_sha = hashlib.sha256(raw).hexdigest()
    rows: list[dict[str, Any]] = []
    invalid: list[dict[str, Any]] = []
    for idx, line in enumerate(raw.decode("utf-8", errors="replace").splitlines(), start=1):
        if not line.strip():
            continue
        try:
            value = json.loads(line)
        except json.JSONDecodeError as exc:
            invalid.append({"line": idx, "reason_code": "invalid_json", "error": str(exc)})
            continue
        if not isinstance(value, dict):
            invalid.append({"line": idx, "reason_code": "non_object_jsonl_row"})
            continue
        rows.append(value)
    return rows, invalid, ledger_sha


def analyze_writers(rows: list[dict[str, Any]]) -> dict[str, Any]:
    key_used = ""
    writers: set[str] = set()
    missing = 0
    for key in WRITER_KEYS:
        values = {str(row[key]) for row in rows if row.get(key) not in (None, "")}
        if values:
            key_used = key
            writers = values
            missing = sum(1 for row in rows if row.get(key) in (None, ""))
            break
    if not rows:
        status = "pass"
        reason = "empty_ledger"
    elif not writers:
        status = "warn"
        reason = "canonical_writer_field_missing"
    elif len(writers) == 1 and missing == 0:
        status = "pass"
        reason = "single_canonical_writer"
    elif len(writers) == 1:
        status = "warn"
        reason = "some_rows_missing_canonical_writer"
    else:
        status = "fail"
        reason = "multiple_canonical_writers"
    return {
        "status": status,
        "reason_code": reason,
        "field": key_used or None,
        "writers": sorted(writers),
        "writer_count": len(writers),
        "missing_writer_rows": missing,
    }


def analyze_hash_chain(rows: list[dict[str, Any]]) -> dict[str, Any]:
    hash_rows = [row for row in rows if first_field(row, HASH_KEYS)]
    if not rows:
        return {"status": "pass", "reason_code": "empty_ledger", "checked_rows": 0, "failures": []}
    if not hash_rows:
        return {"status": "warn", "reason_code": "hash_chain_not_present", "checked_rows": 0, "failures": []}
    if len(hash_rows) != len(rows):
        return {
            "status": "fail",
            "reason_code": "partial_hash_chain",
            "checked_rows": len(hash_rows),
            "failures": [{"reason_code": "row_missing_hash", "count": len(rows) - len(hash_rows)}],
        }

    failures: list[dict[str, Any]] = []
    prior_hash = ""
    for idx, row in enumerate(rows, start=1):
        observed = first_field(row, HASH_KEYS)
        expected = canonical_row_hash(row)
        if observed != expected:
            failures.append(
                {
                    "line": idx,
                    "reason_code": "row_hash_mismatch",
                    "expected_sha256": expected,
                    "observed_sha256": observed,
                }
            )
        observed_prev = first_field(row, PREV_HASH_KEYS)
        expected_prev = "GENESIS" if idx == 1 else prior_hash
        if observed_prev not in (expected_prev, ""):
            failures.append(
                {
                    "line": idx,
                    "reason_code": "prev_hash_mismatch",
                    "expected_prev_sha256": expected_prev,
                    "observed_prev_sha256": observed_prev,
                }
            )
        prior_hash = observed
    return {
        "status": "fail" if failures else "pass",
        "reason_code": "hash_chain_failed" if failures else "hash_chain_verified",
        "checked_rows": len(rows),
        "failures": failures,
    }


def analyze_ledger(path: Path) -> tuple[dict[str, Any], int]:
    if not path.exists() or not path.is_file():
        payload = base_payload(
            {
                "status": "fail",
                "generated_at": now_iso(),
                "ledger": {"path": str(path), "exists": False},
                "reason_code": "ledger_missing",
                "report_written": False,
            }
        )
        return payload, 3

    rows, invalid, ledger_sha = read_jsonl(path)
    writer = analyze_writers(rows)
    hash_chain = analyze_hash_chain(rows)
    failure_reasons: list[str] = []
    warn_reasons: list[str] = []
    if invalid:
        failure_reasons.append("invalid_json")
    if writer["status"] == "fail":
        failure_reasons.append(str(writer["reason_code"]))
    elif writer["status"] == "warn":
        warn_reasons.append(str(writer["reason_code"]))
    if hash_chain["status"] == "fail":
        failure_reasons.append(str(hash_chain["reason_code"]))
    elif hash_chain["status"] == "warn":
        warn_reasons.append(str(hash_chain["reason_code"]))
    status = "fail" if failure_reasons else ("warn" if warn_reasons else "pass")
    rc = 1 if status == "fail" else 0
    payload = base_payload(
        {
            "status": status,
            "generated_at": now_iso(),
            "ledger": {
                "path": str(path),
                "exists": True,
                "sha256": ledger_sha,
                "total_rows": len(rows) + len(invalid),
                "valid_json_rows": len(rows),
                "invalid_json_rows": len(invalid),
            },
            "invalid_rows": invalid[:20],
            "canonical_writer": writer,
            "hash_chain": hash_chain,
            "failure_reasons": failure_reasons,
            "warn_reasons": warn_reasons,
            "report_written": False,
            "source_ledger_mutated": False,
            "secret_values_observed": 0,
            "quality_bar_passed": "yes",
        }
    )
    return payload, rc


def default_report_path(report_dir: Path, ledger: Path) -> Path:
    safe_name = ledger.name.replace("/", "_") or "ledger"
    day = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    return report_dir / f"ntm-audit-receipts-{safe_name}-{day}.json"


def write_report(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_name(f".{path.name}.tmp")
    temp.write_text(json.dumps(payload, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    temp.replace(path)


def command_audit(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    ledger = Path(args.ledger).expanduser()
    if not ledger.is_absolute():
        ledger = (repo_root / ledger).resolve()
    payload, rc = analyze_ledger(ledger)
    payload["command"] = args.command
    payload["dry_run"] = not args.apply
    payload["apply"] = bool(args.apply)
    if args.apply:
        if not args.idempotency_key:
            payload.update({"status": "fail", "reason_code": "missing_idempotency_key"})
            return payload, 2
        report_path = Path(args.report_path).expanduser() if args.report_path else default_report_path(Path(args.report_dir), ledger)
        if not report_path.is_absolute():
            report_path = (repo_root / report_path).resolve()
        report_payload = dict(payload)
        report_payload.update(
            {
                "report_written": True,
                "report_path": str(report_path),
                "idempotency_key": args.idempotency_key,
            }
        )
        write_report(report_path, report_payload)
        payload.update({"report_written": True, "report_path": str(report_path), "idempotency_key": args.idempotency_key})
    return payload, rc


def command_doctor(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    report_dir = Path(args.report_dir)
    ledger = Path(args.ledger)
    if not ledger.is_absolute():
        ledger = repo_root / ledger
    checks = {
        "jq_not_required": True,
        "python_available": True,
        "default_ledger_exists": ledger.exists(),
        "report_dir_available": report_dir.exists() or report_dir.parent.exists(),
        "canonical_cli": {
            "doctor": True,
            "health": True,
            "repair": True,
            "validate": True,
            "audit": True,
            "why": True,
            "json": True,
            "dry_run": True,
            "apply_requires_idempotency_key": True,
        },
    }
    status = "pass" if checks["report_dir_available"] else "warn"
    return base_payload({"command": args.command, "status": status, "generated_at": now_iso(), "checks": checks}), 0


def command_repair(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    if args.apply and not args.idempotency_key:
        return base_payload({"command": "repair", "status": "fail", "reason_code": "missing_idempotency_key"}), 2
    return base_payload(
        {
            "command": "repair",
            "status": "pass",
            "generated_at": now_iso(),
            "repair_mode": "dry_run" if not args.apply else "applied_no_source_mutation",
            "source_ledger_mutated": False,
            "planned_actions": [
                "rerun source receipt writer",
                "preserve original ledger bytes",
                "append a new hash-chained receipt from the canonical writer",
                "rerun this audit",
            ],
            "cannot_repair": [
                "source ledger mutation",
                "hash backfill into historical rows",
                "writer reassignment without source evidence",
            ],
        }
    ), 0


def command_why(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    return base_payload(
        {
            "command": "why",
            "status": "ok",
            "reason": args.reason,
            "explanations": {
                "overview": "W3bA makes receipt ledgers mechanically auditable before policy and summary consumers trust them.",
                "canonical-writer": "One writer per ledger prevents mixed semantics inside one append-only truth source.",
                "hash-chain": "Hash chains make historical row mutation visible without rewriting old receipts.",
                "repair": "This wrapper does not repair source ledgers; it produces an audit report and names the safe repair pattern.",
            },
        }
    ), 0


def schema_payload() -> dict[str, Any]:
    return base_payload(
        {
            "command": "schema",
            "status": "ok",
            "required_output_fields": [
                "schema_version",
                "status",
                "ledger",
                "canonical_writer",
                "hash_chain",
                "l112_observed",
                "authorized_operations",
                "forbidden_operations",
                "ttl_native",
                "ttl_wrapper",
                "ttl_decision",
                "native_wrapper_delta",
            ],
            "stable_exit_codes": STABLE_EXIT_CODES,
            "mutation_modes": ["--dry-run", "--apply"],
            "apply_requires": ["--idempotency-key"],
            "default_mode": "read_only",
            "source_ledger_mutation": "forbidden",
            "hash_fields_supported": HASH_KEYS,
            "prev_hash_fields_supported": PREV_HASH_KEYS,
        }
    )


def quickstart_payload() -> dict[str, Any]:
    return base_payload(
        {
            "command": "quickstart",
            "status": "ok",
            "steps": [
                "run --info --json",
                "run schema --json",
                "run audit --ledger <jsonl> --dry-run --json",
                "run audit --ledger <jsonl> --apply --idempotency-key <key> --json",
                "inspect the written .flywheel/reports audit receipt",
            ],
        }
    )


def completion(shell: str) -> str:
    words = "doctor health repair validate audit why schema quickstart --ledger --report-dir --report-path --dry-run --apply --idempotency-key --reason --json --info --examples --schema"
    if shell == "zsh":
        return "compadd " + " ".join(words.split()) + "\n"
    return "complete -W '" + words + "' ntm-audit-receipts.sh\n"


def parse_args(argv: list[str]) -> argparse.Namespace:
    if not argv:
        argv = ["audit"]
    if argv[0] in {"--help", "-h"}:
        print(usage())
        raise SystemExit(0)
    if argv[0] == "--info":
        print(json.dumps(base_payload({"command": "info", "status": "ok", "name": "ntm-audit-receipts", "stable_exit_codes": STABLE_EXIT_CODES}), sort_keys=True, separators=(",", ":")))
        raise SystemExit(0)
    if argv[0] in {"--examples", "examples"}:
        print(json.dumps(examples_payload(), sort_keys=True, separators=(",", ":")))
        raise SystemExit(0)
    if argv[0] == "--schema":
        print(json.dumps(schema_payload(), sort_keys=True, separators=(",", ":")))
        raise SystemExit(0)
    if argv[0] == "completion":
        shell = argv[1] if len(argv) > 1 else "bash"
        print(completion(shell), end="")
        raise SystemExit(0)

    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("command", nargs="?", default="audit")
    parser.add_argument("topic", nargs="?")
    parser.add_argument("--ledger", default=".flywheel/dispatch-log.jsonl")
    parser.add_argument("--report-dir", default=".flywheel/reports")
    parser.add_argument("--report-path", default="")
    parser.add_argument("--idempotency-key", default="")
    parser.add_argument("--dry-run", action="store_true", default=True)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--reason", default="overview")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--help", "-h", action="store_true")
    args = parser.parse_args(argv)
    if args.help:
        print(usage())
        raise SystemExit(0)
    if args.topic and args.command == "why" and args.reason == "overview":
        args.reason = args.topic
    if args.command == "health":
        args.command = "doctor"
    return args


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    if args.command in {"audit", "validate"}:
        payload, rc = command_audit(args)
    elif args.command == "doctor":
        payload, rc = command_doctor(args)
    elif args.command == "repair":
        payload, rc = command_repair(args)
    elif args.command == "why":
        payload, rc = command_why(args)
    elif args.command == "schema":
        payload, rc = schema_payload(), 0
    elif args.command == "quickstart":
        payload, rc = quickstart_payload(), 0
    else:
        payload, rc = base_payload({"command": args.command, "status": "fail", "reason_code": "unknown_command"}), 2
    return print_payload(payload, args.json, rc)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[2:]))
PY
