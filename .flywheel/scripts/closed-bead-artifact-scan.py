#!/usr/bin/env python3
"""Scan closed beads for shipped-artifact claims that fail mechanical probes."""

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


SCHEMA_VERSION = "closed-bead-artifact-scan/v1"
DEFAULT_AUDIT_LOG = Path(".flywheel/validation-reopen/audit.jsonl")
DEFAULT_RECEIPT_DIR = Path(".flywheel/validation-reopen/receipts")
PATH_KEYS = {
    "artifact",
    "artifact_path",
    "candidates_fixture",
    "dry_run_json",
    "evidence",
    "file",
    "fixture",
    "fixtures",
    "path",
    "receipt",
    "schema",
    "schema_path",
    "validation_receipt",
}
EXECUTABLE_KEYS = {"cmd_path", "command_path", "executable", "script"}
COMMAND_KEYS = {"command", "scanner_cmd", "smoke_cmd", "test_cmd", "tests"}
IGNORE_PREFIXES = ("http://", "https://", "sha256:", "git:", "bead:", "flywheel-", "<")


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def load_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    if not path.exists():
        return rows
    for line in path.read_text(errors="replace").splitlines():
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(row, dict):
            rows.append(row)
    return rows


def repo_root(repo: Path) -> Path:
    proc = subprocess.run(
        ["git", "-C", str(repo), "rev-parse", "--show-toplevel"],
        check=False,
        text=True,
        capture_output=True,
    )
    if proc.returncode == 0 and proc.stdout.strip():
        return Path(proc.stdout.strip()).resolve()
    return repo.resolve()


def run_br(repo: Path, argv: list[str]) -> tuple[int, str, str]:
    proc = subprocess.run(["br", *argv], cwd=str(repo), check=False, text=True, capture_output=True)
    return proc.returncode, proc.stdout, proc.stderr


def repo_local_proof(repo: Path) -> dict[str, Any]:
    root = repo_root(repo)
    beads_dir = (root / ".beads").resolve()
    where_rc, where_out, where_err = run_br(root, ["where"])
    first = where_out.strip().splitlines()[0].strip() if where_rc == 0 and where_out.strip() else ""
    where_path = Path(first).resolve() if first else None
    return {
        "method": "br where plus repo/.beads realpath",
        "repo": str(root),
        "beads_dir": str(beads_dir),
        "br_where": str(where_path) if where_path else None,
        "br_where_stderr": where_err.strip()[:500] if where_rc else None,
        "repo_local": beads_dir.exists() and (where_path is None or where_path == beads_dir),
    }


def closed_text(row: dict[str, Any]) -> str:
    fields = [
        row.get("close_reason"),
        row.get("closed_reason"),
        row.get("resolution"),
        row.get("notes"),
    ]
    return " ".join(str(value) for value in fields if value)


def is_closed(row: dict[str, Any]) -> bool:
    return str(row.get("status") or row.get("state") or "").lower() in {"closed", "done", "resolved"}


def split_claims(text: str) -> list[tuple[str, str]]:
    claims: list[tuple[str, str]] = []
    try:
        parts = shlex.split(text)
    except ValueError:
        parts = text.split()
    for part in parts:
        if "=" not in part:
            continue
        key, raw = part.split("=", 1)
        raw_key = key.strip().strip(":,;")
        if raw_key == "PATH":
            continue
        key = raw_key.lower().replace("-", "_")
        value = raw.strip().strip(",;")
        if not key or not value or value.startswith(IGNORE_PREFIXES):
            continue
        if value.endswith(":PASS") or value.endswith(":FAIL"):
            value = value.rsplit(":", 1)[0]
        claims.append((key, value))
    return claims


def path_for(repo: Path, raw: str) -> Path:
    expanded = os.path.expanduser(raw)
    path = Path(expanded)
    if not path.is_absolute():
        path = repo / path
    return path.resolve()


def check_path(repo: Path, key: str, raw: str) -> dict[str, Any]:
    path = path_for(repo, raw)
    if not path.exists():
        return {"type": "path", "key": key, "ref": raw, "path": str(path), "status": "missing", "reason": "path_missing"}
    if key in EXECUTABLE_KEYS and not os.access(path, os.X_OK):
        return {"type": "executable", "key": key, "ref": raw, "path": str(path), "status": "fail", "reason": "not_executable"}
    if key in {"schema", "schema_path"} or path.suffix == ".json":
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            return {"type": "schema", "key": key, "ref": raw, "path": str(path), "status": "fail", "reason": "invalid_json", "error": str(exc)[:300]}
    kind = "executable" if key in EXECUTABLE_KEYS else ("schema" if key in {"schema", "schema_path"} else "path")
    return {"type": kind, "key": key, "ref": raw, "path": str(path), "status": "pass", "reason": "exists"}


def check_command(repo: Path, key: str, raw: str, timeout: int) -> dict[str, Any]:
    try:
        argv = shlex.split(raw)
    except ValueError as exc:
        return {"type": "command", "key": key, "ref": raw, "status": "fail", "reason": "command_parse_failed", "error": str(exc)}
    if not argv:
        return {"type": "command", "key": key, "ref": raw, "status": "unknown", "reason": "empty_command"}
    try:
        proc = subprocess.run(argv, cwd=str(repo), check=False, text=True, capture_output=True, timeout=timeout)
    except FileNotFoundError:
        return {"type": "command", "key": key, "ref": raw, "argv": argv, "status": "fail", "reason": "command_not_found"}
    except subprocess.TimeoutExpired:
        return {"type": "command", "key": key, "ref": raw, "argv": argv, "status": "fail", "reason": "command_timeout"}
    return {
        "type": "command",
        "key": key,
        "ref": raw,
        "argv": argv,
        "status": "pass" if proc.returncode == 0 else "fail",
        "reason": "exit_zero" if proc.returncode == 0 else "exit_nonzero",
        "exit_code": proc.returncode,
        "stdout": proc.stdout[-500:],
        "stderr": proc.stderr[-500:],
    }


def scan_issue(repo: Path, row: dict[str, Any], command_timeout: int) -> dict[str, Any]:
    text = closed_text(row)
    checks: list[dict[str, Any]] = []
    for key, value in split_claims(text):
        if key in PATH_KEYS or key in EXECUTABLE_KEYS:
            checks.append(check_path(repo, key, value))
        elif key in COMMAND_KEYS:
            checks.append(check_command(repo, key, value, command_timeout))
    if not checks:
        state = "unknown"
        reasons = ["ambiguous_prose_only_close_reason"]
    elif any(check["status"] == "fail" or check["status"] == "missing" for check in checks):
        state = "reopen_candidate"
        reasons = sorted({str(check.get("reason")) for check in checks if check.get("status") in {"fail", "missing"}})
    elif any(check["status"] == "unknown" for check in checks):
        state = "unknown"
        reasons = sorted({str(check.get("reason")) for check in checks if check.get("status") == "unknown"})
    else:
        state = "closed_valid"
        reasons = ["all_artifacts_valid"]
    return {
        "bead_id": row.get("id"),
        "title": row.get("title"),
        "state": state,
        "reasons": reasons,
        "close_reason": text,
        "checks": checks,
    }


def scan(repo: Path, limit: int, command_timeout: int) -> dict[str, Any]:
    issues_path = repo / ".beads/issues.jsonl"
    rows = [row for row in load_jsonl(issues_path) if is_closed(row)]
    if limit > 0:
        rows = rows[-limit:]
    results = [scan_issue(repo, row, command_timeout) for row in rows]
    candidates = [item for item in results if item["state"] == "reopen_candidate"]
    unknown = [item for item in results if item["state"] == "unknown"]
    valid = [item for item in results if item["state"] == "closed_valid"]
    return {
        "schema_version": SCHEMA_VERSION,
        "generated_at": utc_now(),
        "repo": str(repo),
        "issues_path": str(issues_path),
        "closed_checked_count": len(results),
        "reopen_candidates_count": len(candidates),
        "unknown_count": len(unknown),
        "closed_valid_count": len(valid),
        "candidates": candidates,
        "unknown": unknown,
        "valid": valid,
    }


def key_for(scan_result: dict[str, Any], explicit: str | None) -> str:
    if explicit:
        return explicit
    material = [(item.get("bead_id"), item.get("reasons"), item.get("checks")) for item in scan_result.get("candidates", [])]
    return hashlib.sha256(json.dumps(material, sort_keys=True, default=str).encode("utf-8")).hexdigest()[:16]


def audit_rows(path: Path) -> list[dict[str, Any]]:
    return load_jsonl(path)


def write_json_atomic(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    tmp.replace(path)


def append_jsonl(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(payload, sort_keys=True) + "\n")


def apply_reopens(repo: Path, scan_result: dict[str, Any], key: str, audit_log: Path, receipt_dir: Path) -> dict[str, Any]:
    prior = [row for row in audit_rows(audit_log) if row.get("idempotency_key") == key]
    if prior:
        return {"status": "idempotent_replay", "idempotency_key": key, "audit_receipt": prior[-1], "actual_actions": []}
    receipt_path = receipt_dir / f"{key}.json"
    write_json_atomic(receipt_path, scan_result)
    actions: list[dict[str, Any]] = []
    for candidate in scan_result.get("candidates", []):
        bead_id = str(candidate.get("bead_id") or "")
        if not bead_id:
            continue
        reason = f"auto-reopen validation_receipt={receipt_path} audit={audit_log} reasons={','.join(candidate.get('reasons') or [])}"
        reopen_rc, reopen_out, reopen_err = run_br(repo, ["reopen", bead_id, "--reason", reason, "--json"])
        comment_rc, comment_out, comment_err = run_br(repo, ["comments", "add", bead_id, "--message", reason, "--json"])
        actions.append(
            {
                "bead_id": bead_id,
                "br_reopen": {"exit_code": reopen_rc, "stdout": reopen_out.strip(), "stderr": reopen_err.strip()},
                "br_comment": {"exit_code": comment_rc, "stdout": comment_out.strip(), "stderr": comment_err.strip()},
            }
        )
    audit = {
        "ts": utc_now(),
        "idempotency_key": key,
        "receipt": str(receipt_path),
        "reopened_count": sum(1 for action in actions if action["br_reopen"]["exit_code"] == 0),
        "candidate_count": scan_result.get("reopen_candidates_count", 0),
        "actions": actions,
    }
    append_jsonl(audit_log, audit)
    return {"status": "applied", "idempotency_key": key, "audit_receipt": audit, "actual_actions": actions, "receipt": str(receipt_path)}


def schema_json(repo: Path) -> dict[str, Any]:
    return {
        "command": "closed-bead-artifact-scan.py",
        "schema_version": SCHEMA_VERSION,
        "default_mode": "dry-run",
        "mutation_requires": ["--apply", "--idempotency-key"],
        "audit_log_default": str(repo / DEFAULT_AUDIT_LOG),
        "receipt_dir_default": str(repo / DEFAULT_RECEIPT_DIR),
        "exit_codes": {"0": "success/no candidates/dry-run", "1": "candidate found or apply failed", "2": "usage"},
        "candidate_states": ["closed_valid", "reopen_candidate", "unknown"],
    }


def examples_json() -> dict[str, Any]:
    return {
        "examples": [
            ".flywheel/scripts/closed-bead-artifact-scan.py --repo . --dry-run --json",
            ".flywheel/scripts/closed-bead-artifact-scan.py --repo . --doctor --json",
            ".flywheel/scripts/closed-bead-artifact-scan.py --repo . --apply --idempotency-key b07-20260503 --json",
            ".flywheel/scripts/closed-bead-artifact-scan.py --repo . --why .flywheel/validation-reopen/receipts/<key>.json --json",
        ]
    }


def info_json(repo: Path) -> dict[str, Any]:
    return {"command": "closed-bead-artifact-scan.py", "schema_version": SCHEMA_VERSION, "repo": str(repo), "python": sys.version.split()[0]}


def why_json(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text())
    return {
        "receipt": str(path),
        "schema_version": data.get("schema_version"),
        "reopen_candidates_count": data.get("reopen_candidates_count", 0),
        "unknown_count": data.get("unknown_count", 0),
        "decision": "reopen_candidate" if data.get("reopen_candidates_count", 0) else "no_reopen_candidate",
        "candidates": data.get("candidates", [])[:10],
    }


def main() -> int:
    parser = argparse.ArgumentParser(prog="closed-bead-artifact-scan.py")
    parser.add_argument("--repo", default=".")
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--command-timeout", type=int, default=8)
    parser.add_argument("--audit-log", default=str(DEFAULT_AUDIT_LOG))
    parser.add_argument("--receipt-dir", default=str(DEFAULT_RECEIPT_DIR))
    parser.add_argument("--idempotency-key")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--health", action="store_true")
    parser.add_argument("--repair", action="store_true")
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--audit", action="store_true")
    parser.add_argument("--why")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--info", action="store_true")
    args = parser.parse_args()
    if (args.doctor or args.health) and args.limit == 0:
        args.limit = int(os.environ.get("FLYWHEEL_CLOSED_BEAD_ARTIFACT_SCAN_DOCTOR_LIMIT", "200"))
        args.command_timeout = min(args.command_timeout, int(os.environ.get("FLYWHEEL_CLOSED_BEAD_ARTIFACT_SCAN_DOCTOR_COMMAND_TIMEOUT", "1")))

    repo = repo_root(Path(args.repo).expanduser().resolve())
    if args.schema:
        print(json.dumps(schema_json(repo), indent=None if args.json else 2, sort_keys=True))
        return 0
    if args.examples:
        print(json.dumps(examples_json(), indent=None if args.json else 2, sort_keys=True))
        return 0
    if args.info:
        print(json.dumps(info_json(repo), indent=None if args.json else 2, sort_keys=True))
        return 0
    if args.why:
        path = Path(args.why)
        if not path.is_absolute():
            path = repo / path
        print(json.dumps(why_json(path), indent=None if args.json else 2, sort_keys=True))
        return 0
    audit_log = Path(args.audit_log)
    if not audit_log.is_absolute():
        audit_log = repo / audit_log
    receipt_dir = Path(args.receipt_dir)
    if not receipt_dir.is_absolute():
        receipt_dir = repo / receipt_dir
    if args.audit:
        rows = audit_rows(audit_log)
        print(json.dumps({"audit_log": str(audit_log), "rows": rows[-20:], "row_count": len(rows)}, indent=None if args.json else 2, sort_keys=True))
        return 0

    proof = repo_local_proof(repo)
    result = scan(repo, args.limit, args.command_timeout)
    result["repo_local_proof"] = proof
    result["dry_run"] = not args.apply
    result["planned_actions"] = [
        {
            "action": "br_reopen",
            "bead_id": item.get("bead_id"),
            "would_call_external": ["br", "reopen", str(item.get("bead_id")), "--reason", "<validation receipt>", "--json"],
        }
        for item in result.get("candidates", [])
    ]
    if args.doctor or args.health:
        result["status"] = "warn" if result["reopen_candidates_count"] else "pass"
        print(json.dumps(result, indent=None if args.json else 2, sort_keys=True))
        return 0
    if args.repair:
        result["repair_mode"] = "dry_run"
        print(json.dumps(result, indent=None if args.json else 2, sort_keys=True))
        return 0 if result["reopen_candidates_count"] == 0 else 1
    if args.validate:
        print(json.dumps(result, indent=None if args.json else 2, sort_keys=True))
        return 0 if result["reopen_candidates_count"] == 0 else 1
    if args.apply:
        if not args.idempotency_key:
            print(json.dumps({"status": "fail", "error": "--apply requires --idempotency-key", "mutation_requires": ["--apply", "--idempotency-key"]}, sort_keys=True))
            return 1
        if not proof["repo_local"]:
            print(json.dumps({"status": "fail", "error": "repo_local_beads_not_verified", "repo_local_proof": proof}, sort_keys=True))
            return 1
        key = key_for(result, args.idempotency_key)
        result.update(apply_reopens(repo, result, key, audit_log, receipt_dir))
    print(json.dumps(result, indent=None if args.json else 2, sort_keys=True))
    return 0 if result.get("reopen_candidates_count", 0) == 0 or args.apply else 1


if __name__ == "__main__":
    raise SystemExit(main())
