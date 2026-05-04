#!/usr/bin/env python3
"""Plan or apply repo-local fix beads for failed validation receipts."""

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


HIGH_CONFIDENCE_CLASSES = {
    "artifact_missing",
    "blocked_without_fuckup_log",
    "callback_malformed",
    "evidence_missing",
    "remediation_missing",
    "validation_receipt_schema_invalid",
    "validator_output_invalid",
}
CRITICAL_NO_NOOP_CLASSES = {
    "artifact_missing",
    "callback_malformed",
    "evidence_missing",
    "validation_receipt_schema_invalid",
}
LOW_CONFIDENCE_CLASSES = {
    "runtime_unresponsive",
    "unknown",
}
DEFAULT_AUDIT_LOG = Path(".flywheel/validation-fix-beads/audit.jsonl")


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def load_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise ValueError(f"{path} did not contain a JSON object")
    return data


def dump(payload: dict[str, Any], as_json: bool) -> None:
    print(json.dumps(payload, indent=None if as_json else 2, sort_keys=True))


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
    where_first_line = where_out.strip().splitlines()[0].strip() if where_rc == 0 and where_out.strip() else ""
    where_path = Path(where_first_line).resolve() if where_first_line else None
    repo_local = beads_dir.exists() and (where_path is None or where_path == beads_dir)
    return {
        "method": "br where plus repo/.beads realpath",
        "repo": str(root),
        "beads_dir": str(beads_dir),
        "br_where": str(where_path) if where_path else None,
        "br_where_stderr": where_err.strip()[:500] if where_rc else None,
        "repo_local": repo_local,
    }


def normalize_receipt(raw: dict[str, Any]) -> tuple[dict[str, Any], dict[str, Any]]:
    wrapper = raw if "validation_receipt" in raw else None
    receipt = wrapper.get("validation_receipt") if wrapper else raw
    if not isinstance(receipt, dict):
        raise ValueError("receipt JSON must contain validation_receipt object or be a receipt object")
    meta = {
        "wrapper_status": wrapper.get("status") if wrapper else None,
        "wrapper_failure_classes": wrapper.get("failure_classes") if wrapper else None,
        "wrapper_receipt_path": wrapper.get("receipt_path") if wrapper else None,
        "schema_valid": wrapper.get("schema_valid") if wrapper else None,
    }
    return receipt, meta


def receipt_status(receipt: dict[str, Any], meta: dict[str, Any]) -> str:
    return str(receipt.get("status") or meta.get("wrapper_status") or "unknown")


def failure_classes(receipt: dict[str, Any], meta: dict[str, Any]) -> list[str]:
    values = receipt.get("failure_classes") or meta.get("wrapper_failure_classes") or []
    if not isinstance(values, list):
        return ["unknown"]
    out = sorted({str(item) for item in values if str(item)})
    return out or ["unknown"]


def default_idempotency_key(receipt: dict[str, Any], receipt_path: Path, explicit: str | None) -> str:
    if explicit:
        return explicit
    source = {
        "dispatch_id": receipt.get("dispatch_id"),
        "callback_ref": receipt.get("callback_ref"),
        "failure_classes": receipt.get("failure_classes"),
        "artifact_checks": receipt.get("artifact_checks"),
        "receipt_path": str(receipt_path),
    }
    return hashlib.sha256(json.dumps(source, sort_keys=True, default=str).encode("utf-8")).hexdigest()[:16]


def trauma_class(classes: list[str]) -> str:
    if "artifact_missing" in classes:
        return "validation-artifact-missing"
    if "evidence_missing" in classes:
        return "callback-evidence-missing"
    if "callback_malformed" in classes or "validation_receipt_schema_invalid" in classes:
        return "callback-validation-malformed"
    if "runtime_unresponsive" in classes:
        return "runtime-validation-unknown"
    if "remediation_missing" in classes:
        return "validation-remediation-missing"
    return "callback-validation-failed"


def priority_for(classes: list[str], status: str) -> str:
    if any(item in CRITICAL_NO_NOOP_CLASSES for item in classes):
        return "P1"
    if status == "unknown":
        return "P2"
    return "P2"


def artifact_lines(receipt: dict[str, Any]) -> list[str]:
    checks = receipt.get("artifact_checks") if isinstance(receipt.get("artifact_checks"), list) else []
    lines: list[str] = []
    for item in checks:
        if not isinstance(item, dict):
            continue
        lines.append(f"- `{item.get('artifact_id', 'artifact')}`: `{item.get('path', '<missing>')}` status={item.get('status', 'unknown')}")
    if lines:
        return lines
    evidence = receipt.get("evidence") if isinstance(receipt.get("evidence"), list) else []
    for item in evidence:
        if isinstance(item, dict):
            lines.append(f"- evidence `{item.get('type', 'unknown')}`: `{item.get('ref', '<missing>')}`")
    return lines or ["- no artifact path recorded in receipt"]


def callback_ref_text(receipt: dict[str, Any]) -> str:
    callback = receipt.get("callback_ref") if isinstance(receipt.get("callback_ref"), dict) else {}
    raw_ref = str(callback.get("raw_ref") or "")
    if len(raw_ref) > 600:
        raw_ref = raw_ref[:600] + "...<truncated>"
    return raw_ref or "<missing>"


def build_description(
    receipt: dict[str, Any],
    receipt_path: Path,
    classes: list[str],
    key: str,
    parent: str | None,
    source_repo: str,
    no_bead_reason: str | None,
) -> str:
    dispatch_id = str(receipt.get("dispatch_id") or "unknown-dispatch")
    callback = receipt.get("callback_ref") if isinstance(receipt.get("callback_ref"), dict) else {}
    callback_ref = callback_ref_text(receipt)
    artifact_section = "\n".join(artifact_lines(receipt))
    parent_ref = parent or "none"
    no_bead = no_bead_reason or "none"
    return f"""## Auto-fix validation bead

validation_fix_key: {key}
source_repo: {source_repo}
parent_dependency: {parent_ref}
original_dispatch_id: {dispatch_id}
validation_receipt: {receipt_path}
callback_transport: {callback.get('transport', 'unknown')}
callback_session: {callback.get('session', 'unknown')}
callback_pane: {callback.get('pane', 'unknown')}
callback_kind: {callback.get('kind', 'UNKNOWN')}
trauma_class: {trauma_class(classes)}
failure_classes: {", ".join(classes)}
no_bead_reason: {no_bead}

## Failed validation receipt

```text
{callback_ref}
```

## Artifact proof required

{artifact_section}

## Acceptance gates

1. Re-run the original validation command and produce a receipt with `status=pass`.
2. Confirm every artifact path named above exists or record the replacement path in the implementation receipt.
3. Update the originating callback/remediation evidence so `remediation_present=true` or the callback validation no longer fails.
4. Run `br where` from `{source_repo}` and confirm the fix bead is repo-local.
5. Attach the passing receipt path to the worker DONE callback.

## DOD

Close with `close_reason=validation_fix_verified` and commit/tag text containing `[auto-fix-bead]`.

## Out of scope

- Do not bypass `validate-callback.py`.
- Do not close or alter the original implementation bead unless the fix receipt proves the validation gate passes.
"""


def build_title(classes: list[str], key: str) -> str:
    primary = classes[0] if classes else "validation_failed"
    return f"[auto-fix:{key}] repair validation failure: {primary}"


def load_open_issues(repo: Path) -> list[dict[str, Any]]:
    rc, out, err = run_br(repo, ["list", "--json"])
    if rc != 0:
        raise RuntimeError(f"br list --json failed: {err.strip() or out.strip()}")
    data = json.loads(out or "[]")
    if isinstance(data, dict):
        issues = data.get("issues") or data.get("items") or []
    else:
        issues = data
    return [item for item in issues if isinstance(item, dict) and str(item.get("status", "open")) != "closed"]


def find_duplicate(issues: list[dict[str, Any]], key: str) -> dict[str, Any] | None:
    marker = f"validation_fix_key: {key}"
    title_marker = f"[auto-fix:{key}]"
    for issue in issues:
        title = str(issue.get("title") or "")
        body = str(issue.get("description") or "")
        if title_marker in title or marker in body:
            return issue
    return None


def br_argv_for_create(title: str, priority: str, description: str, parent: str | None, dry_run: bool) -> list[str]:
    argv = ["create", title, "--type", "bug", "--priority", priority, "--description", description, "--labels", "validation,auto-fix"]
    if parent:
        argv += ["--deps", f"blocks:{parent}"]
    if dry_run:
        argv.append("--dry-run")
    argv.append("--json")
    return argv


def br_argv_for_update(issue_id: str, title: str, priority: str, description: str) -> list[str]:
    return ["update", issue_id, "--title", title, "--priority", priority, "--description", description, "--add-label", "validation,auto-fix", "--json"]


def atomic_append_jsonl(path: Path, row: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(row, sort_keys=True) + "\n")


def output_schema(repo: Path) -> dict[str, Any]:
    return {
        "command": "validation-fix-bead.py",
        "purpose": "plan or apply repo-local fix beads for failed validation receipts",
        "default_mode": "dry-run",
        "mutation_requires": ["--apply", "--idempotency-key"],
        "repo_local_proof": "br where plus repo/.beads realpath",
        "audit_log_default": str(repo / DEFAULT_AUDIT_LOG),
        "exit_codes": {"0": "planned/applied/no-op", "1": "validation failure or blocked no-op", "2": "usage"},
        "json": True,
    }


def examples_json() -> dict[str, Any]:
    return {
        "examples": [
            ".flywheel/scripts/validation-fix-bead.py --repo . --receipt .flywheel/validation-receipts/abc.json --parent flywheel-8xrn --dry-run --json",
            ".flywheel/scripts/validation-fix-bead.py --repo . --receipt /tmp/failed.json --parent flywheel-8xrn --apply --idempotency-key abc123 --json",
            ".flywheel/scripts/validation-fix-bead.py --repo . --receipt /tmp/runtime-unknown.json --no-bead-reason 'runtime probe stale' --json",
        ]
    }


def doctor_json(repo: Path) -> dict[str, Any]:
    proof = repo_local_proof(repo)
    br_rc, br_out, br_err = run_br(repo, ["version"])
    return {
        "command": "validation-fix-bead.py doctor",
        "repo": str(repo),
        "br_available": br_rc == 0,
        "br_version": br_out.strip() if br_rc == 0 else None,
        "br_error": br_err.strip()[:500] if br_rc else None,
        "repo_local_proof": proof,
        "status": "pass" if br_rc == 0 and proof["repo_local"] else "fail",
    }


def why_json(receipt_path: Path, receipt: dict[str, Any], meta: dict[str, Any]) -> dict[str, Any]:
    classes = failure_classes(receipt, meta)
    status = receipt_status(receipt, meta)
    return {
        "receipt": str(receipt_path),
        "status": status,
        "failure_classes": classes,
        "high_confidence": bool(set(classes) & HIGH_CONFIDENCE_CLASSES),
        "low_confidence": bool(set(classes) & LOW_CONFIDENCE_CLASSES),
        "critical_no_noop": bool(set(classes) & CRITICAL_NO_NOOP_CLASSES),
        "repair_route": "fix_bead" if status == "fail" and set(classes) & HIGH_CONFIDENCE_CLASSES else "no_bead_reason_allowed",
    }


def main() -> int:
    parser = argparse.ArgumentParser(prog="validation-fix-bead.py")
    parser.add_argument("--repo", default=".")
    parser.add_argument("--receipt")
    parser.add_argument("--dispatch-id")
    parser.add_argument("--parent")
    parser.add_argument("--idempotency-key")
    parser.add_argument("--audit-log", default=str(DEFAULT_AUDIT_LOG))
    parser.add_argument("--no-bead-reason")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--explain", action="store_true")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--doctor", action="store_true")
    args = parser.parse_args()

    repo = repo_root(Path(args.repo).expanduser().resolve())
    if args.schema:
        dump(output_schema(repo), args.json)
        return 0
    if args.examples:
        dump(examples_json(), args.json)
        return 0
    if args.doctor:
        payload = doctor_json(repo)
        dump(payload, args.json)
        return 0 if payload["status"] == "pass" else 1
    if not args.receipt:
        parser.error("--receipt is required unless --schema, --examples, or --doctor is used")
    if args.apply and not args.idempotency_key:
        dump({"status": "fail", "error": "--apply requires --idempotency-key", "mutation_requires": ["--apply", "--idempotency-key"]}, args.json)
        return 1

    receipt_path = Path(args.receipt).expanduser()
    if not receipt_path.is_absolute():
        receipt_path = repo / receipt_path
    raw = load_json(receipt_path)
    receipt, meta = normalize_receipt(raw)
    if args.dispatch_id:
        receipt["dispatch_id"] = args.dispatch_id
    status = receipt_status(receipt, meta)
    classes = failure_classes(receipt, meta)
    key = default_idempotency_key(receipt, receipt_path, args.idempotency_key)
    proof = repo_local_proof(repo)
    if not proof["repo_local"]:
        dump({"status": "fail", "error": "repo_local_beads_not_verified", "repo_local_proof": proof}, args.json)
        return 1

    no_bead_allowed = status in {"unknown", "fail"} and bool(set(classes) & LOW_CONFIDENCE_CLASSES) and not bool(set(classes) & CRITICAL_NO_NOOP_CLASSES)
    if args.no_bead_reason and not no_bead_allowed:
        dump(
            {
                "status": "fail",
                "error": "no_bead_reason_not_allowed_for_high_confidence_failure",
                "failure_classes": classes,
                "critical_no_noop": sorted(set(classes) & CRITICAL_NO_NOOP_CLASSES),
            },
            args.json,
        )
        return 1

    if status == "pass":
        payload = {
            "status": "noop",
            "no_bead_reason": "validation_pass",
            "receipt": str(receipt_path),
            "planned_actions": [],
            "repo_local_proof": proof,
        }
        dump(payload, args.json)
        return 0

    if args.no_bead_reason:
        row = {
            "ts": utc_now(),
            "action": "no_bead_reason",
            "idempotency_key": key,
            "receipt": str(receipt_path),
            "reason": args.no_bead_reason,
            "failure_classes": classes,
        }
        if args.apply:
            audit_path = Path(args.audit_log)
            if not audit_path.is_absolute():
                audit_path = repo / audit_path
            atomic_append_jsonl(audit_path, row)
        payload = {
            "status": "no_bead_reason_recorded" if args.apply else "dry_run",
            "dry_run": not args.apply,
            "no_bead_reason": args.no_bead_reason,
            "audit_receipt": row,
            "would_write": str((repo / args.audit_log).resolve()) if not Path(args.audit_log).is_absolute() else args.audit_log,
            "planned_actions": [],
            "repo_local_proof": proof,
        }
        dump(payload, args.json)
        return 0

    if not bool(set(classes) & HIGH_CONFIDENCE_CLASSES) and status != "fail":
        dump(
            {
                "status": "fail",
                "error": "low_confidence_failure_requires_no_bead_reason_or_human_review",
                "failure_classes": classes,
                "receipt": str(receipt_path),
            },
            args.json,
        )
        return 1

    issues = load_open_issues(repo)
    duplicate = find_duplicate(issues, key)
    title = build_title(classes, key)
    priority = priority_for(classes, status)
    description = build_description(receipt, receipt_path, classes, key, args.parent, str(repo), None)
    action = "update_existing" if duplicate else "create"
    existing_id = str(duplicate.get("id")) if duplicate else None
    br_argv = br_argv_for_update(existing_id, title, priority, description) if existing_id else br_argv_for_create(title, priority, description, args.parent, dry_run=not args.apply)
    payload: dict[str, Any] = {
        "status": "dry_run" if not args.apply else "pending",
        "dry_run": not args.apply,
        "action": action,
        "idempotency_key": key,
        "title": title,
        "priority": priority,
        "type": "bug",
        "evidence": {
            "validation_receipt": str(receipt_path),
            "original_dispatch_id": receipt.get("dispatch_id"),
            "callback_ref": receipt.get("callback_ref"),
            "failure_classes": classes,
            "trauma_class": trauma_class(classes),
        },
        "parent": args.parent,
        "dependency_refs": [f"blocks:{args.parent}"] if args.parent else [],
        "existing_fix_bead": existing_id,
        "planned_actions": [
            {
                "action": action,
                "br_argv": br_argv,
                "would_call_external": ["br", *br_argv],
            }
        ],
        "repo_local_proof": proof,
        "audit_log": str((repo / args.audit_log).resolve()) if not Path(args.audit_log).is_absolute() else args.audit_log,
    }
    if args.explain:
        payload["explain"] = why_json(receipt_path, receipt, meta)
    if not args.apply:
        dump(payload, args.json)
        return 0

    rc, out, err = run_br(repo, br_argv)
    payload["br_exit"] = rc
    payload["br_stdout"] = out.strip()
    payload["br_stderr"] = err.strip()
    if rc != 0:
        payload["status"] = "fail"
        dump(payload, args.json)
        return 1
    created_or_updated_id = existing_id
    try:
        br_payload = json.loads(out or "{}")
        if isinstance(br_payload, dict):
            created_or_updated_id = str(br_payload.get("id") or created_or_updated_id)
            payload["br_payload"] = br_payload
    except json.JSONDecodeError:
        pass
    audit_path = Path(args.audit_log)
    if not audit_path.is_absolute():
        audit_path = repo / audit_path
    audit_row = {
        "ts": utc_now(),
        "action": action,
        "idempotency_key": key,
        "fix_bead_id": created_or_updated_id,
        "receipt": str(receipt_path),
        "parent": args.parent,
        "failure_classes": classes,
        "br_argv": br_argv,
    }
    atomic_append_jsonl(audit_path, audit_row)
    payload["status"] = "applied"
    payload["fix_bead_id"] = created_or_updated_id
    payload["audit_receipt"] = audit_row
    dump(payload, args.json)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except BrokenPipeError:
        raise SystemExit(1)
