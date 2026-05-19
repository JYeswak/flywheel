#!/usr/bin/env bash
# canonical-cli-scoping-allow-large: embedded Python keeps checkpoint hashing, rollback stop conditions, and receipt append semantics in one operator CLI.
set -euo pipefail

exec python3 - "$0" "$@" <<'PY'
from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

SCHEMA_VERSION = "ntm-checkpoint-rollback-guard.v1"
CHECKPOINT_SCHEMA = "ntm-checkpoint-metadata.v1"
ROLLBACK_RECEIPT_SCHEMA = "ntm-rollback-receipt.v1"
MISSION_ANCHOR = "continuous-orchestrator-uptime-self-sustaining-fleet"
PLAN_SLUG = "ntm-surface-utilization-migration-2026-05-06"
BEAD_ID = "flywheel-j3if6"
TASK_ID = "ntm-w3br-checkpoint-32573"
WAVE = "W3b"
SHORT_ID = "W3bR"
L112 = "OK_ntm_migrate_W3bR"
TTL_NATIVE = "command_dependent_checkpoint_runtime"
TTL_WRAPPER = "checkpoint_metadata_and_rollback_receipt_indefinite"
TTL_DECISION = "revalidate_checkpoint_hash_dirty_scope_reservations_and_attempt_budget_before_rollback"
NATIVE_WRAPPER_DELTA = (
    "native_ntm_owns_checkpoint_show_list_verify_when_available;"
    "wrapper_retains_metadata_hashes_dirty_scope_checks_and_refuses_rollback_execution"
)
ROLLBACK = "refuse_rollback_execution_and_retain_checkpoint_metadata_only"
AUTHORIZED_OPERATIONS = [
    "checkpoint.preview",
    "checkpoint.show",
    "checkpoint.list",
    "checkpoint.verify",
    "rollback.validate",
    "rollback.receipt_append",
]
FORBIDDEN_OPERATIONS = [
    "rollback_execute",
    "git_reset",
    "git_checkout",
    "git_clean",
    "git_stash",
    "auto_push",
    "force_release",
    "auto_commit",
]
ZERO_HASH = "0" * 64

script_path = Path(sys.argv[1]).resolve()
repo_root = script_path.parent.parent.parent
default_checkpoint_dir = repo_root / ".flywheel" / "checkpoints"
default_ledger = repo_root / ".flywheel" / "rollback-receipts.jsonl"


def now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def canonical(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def sha256_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def idempotency_token() -> str:
    material = f"{PLAN_SLUG}|/Users/josh/Developer/flywheel|{BEAD_ID}|{WAVE}|{TASK_ID}"
    return sha256_text(material)


def run_git(repo: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["git", "-C", str(repo), *args], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)


def require_git_repo(repo: Path) -> tuple[bool, str]:
    result = run_git(repo, "rev-parse", "--show-toplevel")
    if result.returncode != 0:
        return False, result.stderr.strip() or "not_a_git_repo"
    return True, result.stdout.strip()


def git_head(repo: Path) -> str:
    result = run_git(repo, "rev-parse", "HEAD")
    return result.stdout.strip() if result.returncode == 0 else ""


def git_status(repo: Path) -> list[dict[str, str]]:
    result = run_git(repo, "status", "--porcelain=v1")
    if result.returncode != 0:
        return [{"xy": "!!", "path": "git_status_failed", "raw": result.stderr.strip()}]
    rows: list[dict[str, str]] = []
    for line in result.stdout.splitlines():
        if not line:
            continue
        xy = line[:2]
        raw_path = line[3:] if len(line) > 3 else ""
        path = raw_path.split(" -> ", 1)[-1]
        rows.append({"xy": xy, "path": path, "raw": line})
    return rows


def path_is_scoped(path: str, scopes: list[str]) -> bool:
    clean = path.strip("/")
    for scope in scopes:
        s = scope.strip("/")
        if s and (clean == s or clean.startswith(s + "/")):
            return True
    return False


def dirty_scope(status: list[dict[str, str]], preserve_paths: list[str]) -> dict[str, Any]:
    dirty_paths = [row["path"] for row in status if row.get("path")]
    unscoped = [path for path in dirty_paths if not path_is_scoped(path, preserve_paths)]
    return {
        "dirty_count": len(dirty_paths),
        "dirty_paths": dirty_paths,
        "preserve_paths": preserve_paths,
        "unscoped_dirty_paths": unscoped,
        "all_dirty_paths_preserved": len(unscoped) == 0,
    }


def checkpoint_hash(row: dict[str, Any]) -> str:
    body = {key: value for key, value in row.items() if key != "metadata_sha256"}
    return sha256_text(canonical(body))


def with_checkpoint_hash(row: dict[str, Any]) -> dict[str, Any]:
    out = dict(row)
    out["metadata_sha256"] = checkpoint_hash(out)
    return out


def read_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as fh:
        value = json.load(fh)
    if not isinstance(value, dict):
        raise ValueError("json_not_object")
    return value


def verify_checkpoint(path: Path) -> tuple[bool, str, dict[str, Any] | None]:
    if not path.exists():
        return False, "checkpoint_missing", None
    try:
        row = read_json(path)
    except Exception as exc:
        return False, f"checkpoint_unreadable:{exc}", None
    observed = str(row.get("metadata_sha256", ""))
    expected = checkpoint_hash(row)
    if row.get("schema_version") != CHECKPOINT_SCHEMA:
        return False, "checkpoint_schema_mismatch", row
    if observed != expected:
        return False, "checkpoint_hash_mismatch", row
    return True, "checkpoint_hash_verified", row


def read_ledger(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    rows: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as fh:
        for line in fh:
            if not line.strip():
                continue
            try:
                value = json.loads(line)
            except json.JSONDecodeError:
                rows.append({"schema_version": "invalid", "parse_error": True, "raw": line.rstrip("\n")})
                continue
            if isinstance(value, dict):
                rows.append(value)
    return rows


def append_jsonl(path: Path, row: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as fh:
        fh.write(canonical(row) + "\n")


def atomic_write_json(path: Path, row: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + f".tmp.{os.getpid()}")
    tmp.write_text(json.dumps(row, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    tmp.replace(path)


def base_payload(extra: dict[str, Any] | None = None) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "schema_version": SCHEMA_VERSION,
        "mission_anchor": MISSION_ANCHOR,
        "plan_slug": PLAN_SLUG,
        "bead_id": BEAD_ID,
        "task_id": TASK_ID,
        "wave": WAVE,
        "short_id": SHORT_ID,
        "idempotency_token": idempotency_token(),
        "l112_observed": L112,
        "ttl_native": TTL_NATIVE,
        "ttl_wrapper": TTL_WRAPPER,
        "ttl_decision": TTL_DECISION,
        "native_wrapper_delta": NATIVE_WRAPPER_DELTA,
        "authorized_operations": AUTHORIZED_OPERATIONS,
        "forbidden_operations": FORBIDDEN_OPERATIONS,
        "rollback": ROLLBACK,
        "rollback_executed": False,
        "git_mutation_performed": False,
        "secret_values_observed": 0,
    }
    if extra:
        payload.update(extra)
    return payload


def emit(payload: dict[str, Any], json_out: bool, rc: int) -> int:
    if json_out:
        print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    else:
        print(f"{payload.get('status', 'unknown')} {payload.get('reason_code', '')}".strip())
    return rc


def info_payload() -> dict[str, Any]:
    return base_payload(
        {
            "status": "ok",
            "name": "ntm-checkpoint-rollback-guard",
            "canonical_cli": {
                "doctor": True,
                "health": True,
                "repair": True,
                "validate": True,
                "audit": True,
                "why": True,
                "schema": True,
                "examples": True,
                "json": True,
                "dry_run": True,
                "apply_requires_idempotency_key": True,
            },
            "stable_exit_codes": {
                "0": "checkpoint/rollback guard pass or duplicate-safe no-op",
                "1": "rollback refused by guard",
                "2": "usage or missing idempotency key",
                "3": "missing, malformed, or hash-invalid checkpoint",
            },
        }
    )


def schema_payload() -> dict[str, Any]:
    return base_payload(
        {
            "status": "ok",
            "checkpoint_schema": CHECKPOINT_SCHEMA,
            "rollback_receipt_schema": ROLLBACK_RECEIPT_SCHEMA,
            "checkpoint_required": [
                "schema_version",
                "checkpoint_id",
                "repo_path",
                "git_head",
                "created_at",
                "dirty_scope",
                "metadata_sha256",
            ],
            "rollback_stop_conditions": [
                "already_at_checkpoint_with_prior_receipt",
                "max_attempts_exceeded",
                "prior_stash_attempt",
                "checkpoint_missing",
                "checkpoint_superseded",
                "checkpoint_hash_mismatch",
                "reservations_missing_or_expired",
                "dirty_worktree_unscoped",
                "rollback_execution_refused",
            ],
            "mutation_requires": ["--apply", "--idempotency-key"],
            "default_mode": "dry-run",
            "checkpoint_save_dry_run_claim": "forbidden",
            "preview_surfaces": ["show", "list", "verify"],
        }
    )


def examples_payload() -> dict[str, Any]:
    return base_payload(
        {
            "status": "ok",
            "examples": [
                ".flywheel/scripts/ntm-checkpoint-rollback-guard.sh checkpoint --checkpoint-id W3bR --apply --idempotency-key W3bR --json",
                ".flywheel/scripts/ntm-checkpoint-rollback-guard.sh verify --checkpoint-file .flywheel/checkpoints/W3bR.json --json",
                ".flywheel/scripts/ntm-checkpoint-rollback-guard.sh rollback --checkpoint-id W3bR --preserve-path .flywheel/checkpoints --dry-run --json",
                ".flywheel/scripts/ntm-checkpoint-rollback-guard.sh audit --json",
            ],
        }
    )


def why_payload(reason: str) -> dict[str, Any]:
    explanations = {
        "dirty-worktree": "Rollback refuses when git status --porcelain contains paths outside explicit --preserve-path scopes.",
        "metadata-only": "W3bR never executes reset, checkout, clean, stash, push, commit, or force-release; it retains checkpoint metadata and refusal receipts.",
        "checkpoint-hash": "Checkpoint JSON carries metadata_sha256 over canonical content excluding that hash field; verify recomputes before any rollback decision.",
        "attempt-budget": "Worker context allows max_attempts=1 by default; duplicate idempotency keys return duplicate-safe no-op instead of a second attempt.",
        "reservation-state": "Rollback validation refuses missing or expired reservation state because shared surfaces cannot be recovered blindly.",
    }
    return base_payload({"status": "ok", "reason": reason, "explanations": explanations, "selected": explanations.get(reason, explanations["metadata-only"])})


def checkpoint_path(args: argparse.Namespace) -> Path:
    if args.checkpoint_file:
        return Path(args.checkpoint_file).resolve()
    checkpoint_id = args.checkpoint_id or TASK_ID
    return (Path(args.checkpoint_dir).resolve() / f"{checkpoint_id}.json")


def command_doctor(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    repo = Path(args.repo).resolve()
    ok, top = require_git_repo(repo)
    checkpoint_dir = Path(args.checkpoint_dir).resolve()
    ledger = Path(args.ledger).resolve()
    rows = read_ledger(ledger)
    invalid_rows = [row for row in rows if row.get("parse_error")]
    return (
        base_payload(
            {
                "status": "pass" if ok and not invalid_rows else "fail",
                "reason_code": "checkpoint_rollback_guard_healthy" if ok and not invalid_rows else "guard_substrate_unhealthy",
                "repo": {"path": str(repo), "git_root": top if ok else None, "git_repo": ok},
                "paths": {"checkpoint_dir": str(checkpoint_dir), "rollback_ledger": str(ledger)},
                "checks": {
                    "canonical_cli": {"doctor": True, "health": True, "repair": True, "validate": True, "audit": True, "why": True},
                    "rollback_execution_refused": True,
                    "forbidden_git_operations": FORBIDDEN_OPERATIONS[:5],
                    "checkpoint_dir_exists": checkpoint_dir.exists(),
                    "rollback_ledger_rows": len(rows),
                    "rollback_ledger_invalid_rows": len(invalid_rows),
                },
            }
        ),
        0 if ok and not invalid_rows else 1,
    )


def command_checkpoint(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    if args.apply and not args.idempotency_key:
        return base_payload({"status": "fail", "reason_code": "missing_idempotency_key", "checkpoint_written": False}), 2
    repo = Path(args.repo).resolve()
    ok, top = require_git_repo(repo)
    if not ok:
        return base_payload({"status": "fail", "reason_code": "not_a_git_repo", "checkpoint_written": False, "repo": str(repo)}), 3
    checkpoint_id = args.checkpoint_id or TASK_ID
    status_rows = git_status(repo)
    scope = dirty_scope(status_rows, args.preserve_path)
    row = with_checkpoint_hash(
        {
            "schema_version": CHECKPOINT_SCHEMA,
            "checkpoint_id": checkpoint_id,
            "created_at": now_iso(),
            "repo_path": str(Path(top).resolve()),
            "git_head": git_head(repo),
            "dirty_scope": scope,
            "source": "ntm-checkpoint-rollback-guard",
            "task_id": TASK_ID,
            "bead_id": BEAD_ID,
            "l112_observed": L112,
            "idempotency_key": args.idempotency_key,
            "checkpoint_save_dry_run_claim": False,
            "rollback_execution_authorized": False,
        }
    )
    path = checkpoint_path(args)
    if args.apply:
        atomic_write_json(path, row)
    return (
        base_payload(
            {
                "status": "pass",
                "reason_code": "checkpoint_metadata_written" if args.apply else "checkpoint_metadata_preview",
                "checkpoint": row,
                "checkpoint_path": str(path),
                "checkpoint_written": bool(args.apply),
                "dry_run": not args.apply,
                "checkpoint_save_dry_run_claim": False,
            }
        ),
        0,
    )


def command_show(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    path = checkpoint_path(args)
    ok, reason, row = verify_checkpoint(path)
    return (
        base_payload(
            {
                "status": "pass" if ok else "fail",
                "reason_code": reason,
                "checkpoint_path": str(path),
                "checkpoint": row,
                "preview_only": True,
            }
        ),
        0 if ok else 3,
    )


def command_list(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    checkpoint_dir = Path(args.checkpoint_dir).resolve()
    rows: list[dict[str, Any]] = []
    if checkpoint_dir.exists():
        for path in sorted(checkpoint_dir.glob("*.json")):
            ok, reason, row = verify_checkpoint(path)
            rows.append({"path": str(path), "valid": ok, "reason_code": reason, "checkpoint_id": row.get("checkpoint_id") if row else None})
    return base_payload({"status": "pass", "reason_code": "checkpoint_list_preview", "checkpoint_dir": str(checkpoint_dir), "checkpoints": rows, "preview_only": True}), 0


def prior_rows_for_token(rows: list[dict[str, Any]], token: str) -> list[dict[str, Any]]:
    return [row for row in rows if row.get("idempotency_key") == token and row.get("schema_version") == ROLLBACK_RECEIPT_SCHEMA]


def rollback_decision(args: argparse.Namespace) -> tuple[dict[str, Any], int, dict[str, Any] | None]:
    token = args.idempotency_key or idempotency_token()
    path = checkpoint_path(args)
    ok, reason, checkpoint = verify_checkpoint(path)
    ledger = Path(args.ledger).resolve()
    rows = read_ledger(ledger)
    prior = prior_rows_for_token(rows, token)
    repo = Path(args.repo).resolve()
    status_rows = git_status(repo)
    scope = dirty_scope(status_rows, args.preserve_path)
    current_head = git_head(repo)

    decision = "rollback_execution_refused"
    rc = 1
    if prior:
        decision = "duplicate_idempotency_key"
        rc = 0
    elif not ok:
        decision = reason
        rc = 3
    elif checkpoint and checkpoint.get("superseded_by"):
        decision = "checkpoint_superseded"
        rc = 3
    elif args.reservation_state in {"missing", "expired"}:
        decision = "reservations_missing_or_expired"
        rc = 1
    elif len([row for row in rows if row.get("checkpoint_id") == (checkpoint or {}).get("checkpoint_id")]) >= args.max_attempts:
        decision = "max_attempts_exceeded"
        rc = 1
    elif any(row.get("stash_created") is True and row.get("idempotency_key") == token for row in rows):
        decision = "prior_stash_attempt"
        rc = 1
    elif checkpoint and current_head == checkpoint.get("git_head") and prior:
        decision = "already_at_checkpoint_with_prior_receipt"
        rc = 0
    elif not scope["all_dirty_paths_preserved"]:
        decision = "dirty_worktree_unscoped"
        rc = 1

    receipt: dict[str, Any] | None = None
    if args.apply and args.idempotency_key and decision != "duplicate_idempotency_key":
        receipt = {
            "schema_version": ROLLBACK_RECEIPT_SCHEMA,
            "ts": now_iso(),
            "task_id": TASK_ID,
            "bead_id": BEAD_ID,
            "checkpoint_id": checkpoint.get("checkpoint_id") if checkpoint else args.checkpoint_id,
            "checkpoint_path": str(path),
            "idempotency_key": token,
            "decision": decision,
            "status": "refused" if rc != 0 else "stopped",
            "rollback_executed": False,
            "git_mutation_performed": False,
            "stash_created": False,
            "dirty_scope": scope,
            "reservation_state": args.reservation_state,
            "max_attempts": args.max_attempts,
            "l112_observed": L112,
        }
        receipt["receipt_sha256"] = sha256_text(canonical({key: value for key, value in receipt.items() if key != "receipt_sha256"}))

    return (
        base_payload(
            {
                "status": "stopped" if rc == 0 else "refused",
                "reason_code": decision,
                "checkpoint_path": str(path),
                "checkpoint_valid": ok,
                "checkpoint_reason_code": reason,
                "dirty_scope": scope,
                "reservation_state": args.reservation_state,
                "max_attempts": args.max_attempts,
                "prior_attempt_count": len(prior),
                "receipt_written": False,
                "duplicate_suppressed": bool(prior),
                "rollback_executed": False,
                "git_mutation_performed": False,
                "dry_run": not args.apply,
                "apply_requested": bool(args.apply),
                "worker_context_max_attempts": 1,
            }
        ),
        rc,
        receipt,
    )


def command_rollback(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    if args.apply and not args.idempotency_key:
        return base_payload({"status": "fail", "reason_code": "missing_idempotency_key", "receipt_written": False}), 2
    payload, rc, receipt = rollback_decision(args)
    if receipt:
        append_jsonl(Path(args.ledger).resolve(), receipt)
        payload["receipt_written"] = True
        payload["receipt"] = receipt
    return payload, rc


def command_audit(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    checkpoint_dir = Path(args.checkpoint_dir).resolve()
    ledger = Path(args.ledger).resolve()
    checkpoints: list[dict[str, Any]] = []
    if checkpoint_dir.exists():
        for path in sorted(checkpoint_dir.glob("*.json")):
            ok, reason, row = verify_checkpoint(path)
            checkpoints.append({"path": str(path), "valid": ok, "reason_code": reason, "checkpoint_id": row.get("checkpoint_id") if row else None})
    rows = read_ledger(ledger)
    invalid_rows = [row for row in rows if row.get("parse_error")]
    executed = [row for row in rows if row.get("rollback_executed") is True or row.get("git_mutation_performed") is True]
    status = "pass" if not invalid_rows and not executed and all(row["valid"] for row in checkpoints) else "fail"
    return (
        base_payload(
            {
                "status": status,
                "reason_code": "checkpoint_rollback_audit_passed" if status == "pass" else "checkpoint_rollback_audit_failed",
                "checkpoint_count": len(checkpoints),
                "checkpoints": checkpoints,
                "rollback_receipt_count": len(rows),
                "rollback_receipts_invalid": len(invalid_rows),
                "rollback_execution_rows": len(executed),
                "rollback_execution_refused": len(executed) == 0,
                "ledger": str(ledger),
            }
        ),
        0 if status == "pass" else 1,
    )


def command_repair(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    if args.apply and not args.idempotency_key:
        return base_payload({"status": "fail", "reason_code": "missing_idempotency_key", "source_mutated": False}), 2
    return (
        base_payload(
            {
                "status": "pass",
                "reason_code": "repair_refused_unless_reversible",
                "source_mutated": False,
                "planned_actions": [
                    "verify checkpoint metadata hash",
                    "list rollback stop conditions",
                    "append refusal receipt only when --apply and --idempotency-key are supplied",
                ],
                "cannot_repair": [
                    "rollback execution",
                    "git reset",
                    "git checkout",
                    "git clean",
                    "git stash",
                ],
            }
        ),
        0,
    )


def completion(shell: str) -> int:
    words = "doctor health repair validate audit why schema quickstart info examples checkpoint show list verify rollback completion"
    if shell == "bash":
        print(f"complete -W '{words}' ntm-checkpoint-rollback-guard.sh")
    else:
        print(words)
    return 0


def usage() -> str:
    return """usage: ntm-checkpoint-rollback-guard.sh [doctor|health|repair|validate|audit|why|schema|quickstart|checkpoint|show|list|verify|rollback] [options]

Checkpoint/rollback guard for W3bR. Rollback execution is always refused; the
wrapper keeps checkpoint metadata, verifies hashes, checks dirty scopes, and
optionally appends a refusal receipt.

Options:
  --repo PATH                 Git repo (default: current flywheel repo)
  --checkpoint-dir PATH       Checkpoint metadata directory
  --checkpoint-id ID          Checkpoint id (default: dispatch task id)
  --checkpoint-file PATH      Exact checkpoint metadata file
  --ledger PATH               Rollback receipt JSONL
  --preserve-path PATH        Dirty path scope explicitly preserved; repeatable
  --reservation-state STATE   ok|missing|expired (default: ok)
  --max-attempts N            Worker default is 1
  --dry-run                   Preview only
  --apply                     Write metadata or refusal receipt; requires --idempotency-key
  --idempotency-key KEY       Required for --apply
  --json                      Emit JSON
  --info | --examples | --schema
"""


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("command", nargs="?", default="doctor")
    parser.add_argument("reason_arg", nargs="?")
    parser.add_argument("--repo", default=str(repo_root))
    parser.add_argument("--checkpoint-dir", default=str(default_checkpoint_dir))
    parser.add_argument("--checkpoint-id")
    parser.add_argument("--checkpoint-file")
    parser.add_argument("--ledger", default=str(default_ledger))
    parser.add_argument("--preserve-path", action="append", default=[])
    parser.add_argument("--reservation-state", choices=["ok", "missing", "expired"], default="ok")
    parser.add_argument("--max-attempts", type=int, default=1)
    parser.add_argument("--reason", default="metadata-only")
    parser.add_argument("--idempotency-key")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("-h", "--help", action="store_true")
    return parser


def main(argv: list[str]) -> int:
    args, unknown = build_parser().parse_known_args(argv)
    if unknown:
        return emit(base_payload({"status": "fail", "reason_code": "unknown_args", "args": unknown}), True, 2)
    if args.help:
        print(usage())
        return 0
    if args.info or args.command == "info":
        return emit(info_payload(), args.json, 0)
    if args.examples or args.command == "examples" or args.command == "quickstart":
        return emit(examples_payload(), args.json, 0)
    if args.schema or args.command == "schema":
        return emit(schema_payload(), args.json, 0)
    if args.command == "completion":
        return completion(args.reason_arg or "bash")
    if args.command in {"doctor", "health"}:
        payload, rc = command_doctor(args)
        if args.command == "health":
            payload["command"] = "health"
        return emit(payload, args.json, rc)
    if args.command == "repair":
        payload, rc = command_repair(args)
        return emit(payload, args.json, rc)
    if args.command == "checkpoint":
        payload, rc = command_checkpoint(args)
        return emit(payload, args.json, rc)
    if args.command in {"show", "verify", "validate"}:
        payload, rc = command_show(args)
        payload["command"] = args.command
        return emit(payload, args.json, rc)
    if args.command == "list":
        payload, rc = command_list(args)
        return emit(payload, args.json, rc)
    if args.command == "rollback":
        payload, rc = command_rollback(args)
        return emit(payload, args.json, rc)
    if args.command == "audit":
        payload, rc = command_audit(args)
        return emit(payload, args.json, rc)
    if args.command == "why":
        return emit(why_payload(args.reason_arg or args.reason), args.json, 0)
    return emit(base_payload({"status": "fail", "reason_code": "unknown_command", "command": args.command}), args.json, 2)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[2:]))
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
