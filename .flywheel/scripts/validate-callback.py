#!/usr/bin/env python3
"""Build and validate flywheel callback validation receipts."""

from __future__ import annotations

import argparse
import fnmatch
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "validation-receipt/v1"
DEFAULT_SCHEMA_DIR = Path(".flywheel/validation-schema/v1")
RECEIPT_DIR = Path(".flywheel/validation-receipts")
L61_TASK_RE = re.compile(r"\b(doctrine|INCIDENTS|canonical|L-rule|skill ship)\b", re.IGNORECASE)
L61_REQUIRED_FIELDS = ("agents_md_updated", "readme_updated")
JOSH_REQUEST_ID_RE = re.compile(r"\bjosh_request_id\s*[:=]\s*`?([^`\s]+)`?")
EVIDENCE_REDACTION_PATH_PATTERNS = (
    "*/evidence/*",
    "*/validation/*",
    "*/secrets/*",
    "*/.flywheel/*-evidence.md",
)
EVIDENCE_REDACTION_REMEDIATION = (
    "Worker owns evidence redaction: run gitleaks --no-git --piped on each "
    "evidence-class file before close, regenerate redacted evidence, and resend "
    "the callback with evidence_redacted=yes."
)

RETRY_POLICIES = {"none", "exponential", "manual", "permanent"}
FAILURE_CLASS_VALUES = {
    "transient",
    "persistent",
    "correctness",
    "missing_artifact",
    "invalid_callback",
    "context_drift",
    "unknown",
}

TAXONOMY_RULES: tuple[tuple[set[str], str, str, str], ...] = (
    (
        {"runtime_unresponsive", "timeout", "test_timeout", "doctor_timeout"},
        "transient",
        "exponential",
        "Rerun the bounded probe once; if it repeats, promote to persistent with the timeout source attached.",
    ),
    (
        {"database_locked", "schema_mismatch", "io_error", "persistent_substrate"},
        "persistent",
        "manual",
        "Repair the persistent substrate condition, then rerun validation from the same receipt.",
    ),
    (
        {"correctness", "test_failed", "assertion_failed", "l112_verify_failed", "dependency_inversion", "cycle_detected"},
        "correctness",
        "permanent",
        "Fix the implementation, dependency graph, or failing assertion before retry; do not classify as a flake.",
    ),
    (
        {"artifact_missing", "missing_artifact", "evidence_missing", "closed_bead_artifact_missing_count"},
        "missing_artifact",
        "manual",
        "Restore or regenerate the referenced evidence artifact, then rerun validation with the same evidence path.",
    ),
    (
        {
            "invalid_callback",
            "callback_malformed",
            "validation_receipt_schema_invalid",
            "orch_callback_missing_l61_fields",
            "remediation_missing",
            "blocked_without_fuckup_log",
            "dispatch_missing_josh_request_id",
            "callback_missing_josh_request_id",
            "callback_josh_request_id_mismatch",
            "callback_validation_failed",
            "reservation_conflict",
            "reservation_expired",
            "reservation_missing_release",
            "evidence_redaction_missing",
            "evidence_redaction_invalid",
            "evidence_redaction_required",
            "evidence_redaction_declared_no",
            "evidence_redaction_na_on_evidence",
        },
        "invalid_callback",
        "manual",
        "Resend or regenerate the callback with required fields, evidence, and durable bead/no-bead routing.",
    ),
    (
        {"context_drift", "agent_context_probe_drift_count"},
        "context_drift",
        "manual",
        "Reprobe from both orchestrator and agent contexts; do not summarize until the contexts agree or the drift is named.",
    ),
)


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def sha256_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def load_json_file(path: Path) -> Any:
    with path.open(encoding="utf-8") as fh:
        return json.load(fh)


def expand_path(repo: Path, raw: str) -> Path:
    value = os.path.expanduser(raw)
    path = Path(value)
    if not path.is_absolute():
        path = repo / path
    return path


def is_path_like(value: str) -> bool:
    if value.startswith("@"):
        return True
    if value.startswith("/") or value.startswith("~"):
        return True
    return Path(value).exists()


def parse_kv_text(raw: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for match in re.finditer(r"([A-Za-z_][A-Za-z0-9_-]*)=([^ \t\n]+)", raw):
        out[match.group(1)] = match.group(2).strip("`\"'")
    return out


def split_csv_field(value: Any) -> list[str]:
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    if not isinstance(value, str):
        return []
    text = value.strip()
    if not text or text in {"none", "NONE", "null"}:
        return []
    return [part.strip() for part in text.split(",") if part.strip()]


def is_evidence_redaction_path(path: str) -> bool:
    normalized = path.strip().replace("\\", "/")
    if not normalized or normalized in {"NONE_READONLY", "NONE_NO_EDITS"} or normalized.startswith("UNAVAILABLE:"):
        return False
    candidates = [normalized]
    if not normalized.startswith("/"):
        candidates.append(f"/{normalized}")
    return any(
        fnmatch.fnmatchcase(candidate, pattern)
        for candidate in candidates
        for pattern in EVIDENCE_REDACTION_PATH_PATTERNS
    )


def build_evidence_redaction_receipt(
    source: dict[str, Any],
    kv: dict[str, str],
    files_reserved: list[str],
) -> tuple[dict[str, Any], list[str]]:
    raw_value = source_text_value(source, "evidence_redacted") or kv.get("evidence_redacted")
    value = raw_value.strip().lower() if isinstance(raw_value, str) else None
    evidence_paths = [path for path in files_reserved if is_evidence_redaction_path(path)]
    required = bool(evidence_paths)
    failures: list[str] = []

    if value not in {"yes", "no", "n/a"}:
        failures.append("evidence_redaction_missing" if value is None else "evidence_redaction_invalid")
    elif value == "no":
        failures.append("evidence_redaction_declared_no")
    elif required and value != "yes":
        failures.append("evidence_redaction_required")
        if value == "n/a":
            failures.append("evidence_redaction_na_on_evidence")

    return {
        "evidence_redacted": value or "missing",
        "required": required,
        "evidence_paths": evidence_paths,
        "status": "fail" if failures else "pass",
        "owner": "worker",
        "remediation": EVIDENCE_REDACTION_REMEDIATION if failures else "No redaction remediation required.",
    }, failures


def reservation_field(source: dict[str, Any], kv: dict[str, str], key: str) -> Any:
    if key in source:
        return source[key]
    agent_mail = source.get("agent_mail") if isinstance(source.get("agent_mail"), dict) else {}
    if key in agent_mail:
        return agent_mail[key]
    return kv.get(key)


def build_agent_mail_receipt(source: dict[str, Any], kv: dict[str, str]) -> tuple[dict[str, Any], list[str]]:
    fields = {
        "agent_mail_thread": reservation_field(source, kv, "agent_mail_thread"),
        "identity_name": reservation_field(source, kv, "identity_name"),
        "files_reserved": reservation_field(source, kv, "files_reserved"),
        "files_released": reservation_field(source, kv, "files_released"),
        "reservation_conflicts": reservation_field(source, kv, "reservation_conflicts"),
    }

    files_reserved = split_csv_field(fields["files_reserved"])
    files_released = split_csv_field(fields["files_released"])
    reservation_conflicts = split_csv_field(fields["reservation_conflicts"])
    reserved_markers = set(files_reserved)
    released_markers = set(files_released)
    explicit_state = reservation_field(source, kv, "reservation_state")
    if explicit_state is not None:
        explicit_state = str(explicit_state).strip().lower().replace("_", "-")

    state = "no_reservation_required"
    reason = "no edit reservation required"
    failures: list[str] = []

    if explicit_state in {"expired", "force-released", "force_released"}:
        state = "force-released" if explicit_state == "force_released" else explicit_state
        reason = f"explicit reservation_state={state}"
        if state == "expired":
            failures.append("reservation_expired")
    elif reservation_conflicts or any(item.startswith(("CONFLICT", "UNAVAILABLE:conflict")) for item in files_reserved):
        state = "conflict"
        reason = "reservation conflict evidence present"
        failures.append("reservation_conflict")
    elif reserved_markers & {"NONE_READONLY", "NONE_NO_EDITS"}:
        state = "no_reservation_required"
        reason = next(iter(reserved_markers & {"NONE_READONLY", "NONE_NO_EDITS"}))
    elif files_reserved:
        unreleased = sorted(set(files_reserved) - set(files_released))
        if unreleased:
            state = "reservation_succeeded"
            reason = f"reserved files missing release: {','.join(unreleased)}"
            failures.append("reservation_missing_release")
        else:
            state = "released"
            reason = "all reserved files released"

    return {
        "agent_mail_thread": str(fields["agent_mail_thread"]).strip() if fields["agent_mail_thread"] else None,
        "identity_name": str(fields["identity_name"]).strip() if fields["identity_name"] else None,
        "files_reserved": files_reserved,
        "files_released": files_released,
        "reservation_conflicts": reservation_conflicts,
        "reservation_lifecycle": {
            "state": state,
            "reason": reason,
        },
    }, failures


def classify_failure_taxonomy(failure_classes: list[str], status: str) -> dict[str, str | None]:
    if status == "pass" and not failure_classes:
        return {
            "failure_class": None,
            "retry_policy": "none",
            "recovery_hint": "No recovery needed; validation passed.",
        }

    values = {str(item).strip().lower() for item in failure_classes if str(item).strip()}
    for aliases, failure_class, retry_policy, recovery_hint in TAXONOMY_RULES:
        if values & aliases:
            return {
                "failure_class": failure_class,
                "retry_policy": retry_policy,
                "recovery_hint": recovery_hint,
            }

    return {
        "failure_class": "unknown",
        "retry_policy": "manual",
        "recovery_hint": "Preserve the raw failure classes, add a taxonomy alias or migration-tested class, then rerun validation.",
    }


def source_text_value(source: dict[str, Any], key: str) -> str | None:
    value = source.get(key)
    if isinstance(value, str) and value.strip():
        return value.strip()
    return None


def l61_task_requires_fields(source: dict[str, Any], task_description: str | None) -> bool:
    haystacks = [
        task_description or "",
        source_text_value(source, "task_description") or "",
        source_text_value(source, "task_body") or "",
        source_text_value(source, "dispatch_body") or "",
    ]
    return any(L61_TASK_RE.search(value) for value in haystacks)


def l61_missing_fields(source: dict[str, Any], kv: dict[str, str]) -> list[str]:
    missing: list[str] = []
    for field in L61_REQUIRED_FIELDS:
        value = source_text_value(source, field) or kv.get(field)
        if value not in {"yes", "no"}:
            missing.append(field)
    no_touch_reason = source_text_value(source, "no_touch_reason") or kv.get("no_touch_reason")
    for field in L61_REQUIRED_FIELDS:
        value = source_text_value(source, field) or kv.get(field)
        if value == "no" and not no_touch_reason:
            missing.append("no_touch_reason")
            break
    return sorted(set(missing))


def dispatch_josh_request_id(task_description: str | None) -> tuple[bool, str | None]:
    raw = (task_description or "").strip()
    if not raw:
        return False, None
    kv = parse_kv_text(raw)
    if "josh_request_id" in kv:
        return True, kv["josh_request_id"]
    match = JOSH_REQUEST_ID_RE.search(raw)
    if match:
        return True, match.group(1).strip("`\"'")
    return False, None


def callback_josh_request_id(source: dict[str, Any], kv: dict[str, str]) -> str | None:
    return source_text_value(source, "josh_request_id") or kv.get("josh_request_id")


def kind_from_raw(raw: str) -> str:
    if re.search(r"\bDONE\b", raw):
        return "DONE"
    if re.search(r"\bBLOCKED\b", raw):
        return "BLOCKED"
    if re.search(r"\bTIMEOUT\b", raw):
        return "TIMEOUT"
    if "Callback:" in raw:
        return "DONE"
    return "UNKNOWN"


def evidence_from_path(path: str, repo: Path) -> dict[str, str]:
    expanded = expand_path(repo, path)
    item = {"type": "path", "ref": path}
    if expanded.exists() and expanded.is_file():
        item["sha256"] = hashlib.sha256(expanded.read_bytes()).hexdigest()
    return item


def artifact_check(item: Any, repo: Path) -> dict[str, str]:
    return artifact_check_with_options(item, repo, allow_missing_tmp_evidence=False)


def is_tmp_evidence_path(path: str, repo: Path) -> bool:
    if not path:
        return False
    expanded = expand_path(repo, path).resolve(strict=False)
    tmp_roots = {
        Path(tempfile.gettempdir()).resolve(strict=False),
        Path("/tmp").resolve(strict=False),
        Path("/private/tmp").resolve(strict=False),
    }
    return any(expanded == root or root in expanded.parents for root in tmp_roots)


def artifact_check_with_options(item: Any, repo: Path, *, allow_missing_tmp_evidence: bool) -> dict[str, str]:
    if isinstance(item, str):
        artifact_id = Path(item).name or "artifact"
        path = item
        expected = "exists"
    elif isinstance(item, dict):
        artifact_id = str(item.get("artifact_id") or item.get("id") or Path(str(item.get("path", "artifact"))).name)
        path = str(item.get("path") or item.get("ref") or "")
        expected = str(item.get("expected") or "exists")
    else:
        artifact_id = "artifact"
        path = ""
        expected = "exists"
    exists = bool(path) and expand_path(repo, path).exists()
    status = "exists" if exists else "missing"
    if not exists and allow_missing_tmp_evidence and is_tmp_evidence_path(path, repo):
        status = "unknown"
        expected = "missing_tmp_evidence_allowed"
    return {
        "artifact_id": artifact_id,
        "path": path or "<missing-path>",
        "status": status,
        "expected": expected,
    }


def evidence_artifact_items(source: dict[str, Any]) -> list[dict[str, str]]:
    items: list[dict[str, str]] = []
    evidence_items = source.get("evidence") if isinstance(source.get("evidence"), list) else []
    for index, item in enumerate(evidence_items, start=1):
        if isinstance(item, dict):
            path = str(item.get("ref") or item.get("path") or "")
            if item.get("type") == "path" and path:
                artifact_id = str(item.get("artifact_id") or item.get("id") or f"evidence_{index}")
                items.append({"artifact_id": artifact_id, "path": path, "expected": "exists"})
        elif isinstance(item, str) and item.strip():
            items.append({"artifact_id": Path(item).name or f"evidence_{index}", "path": item.strip(), "expected": "exists"})
    return items


def bool_field(source: dict[str, Any], kv: dict[str, str], key: str) -> bool:
    value = source.get(key)
    if value is None:
        value = kv.get(key)
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        return value.strip().lower() in {"1", "true", "yes", "y"}
    return False


def normalize_callback_ref(source: dict[str, Any], raw_ref: str, received_at: str) -> dict[str, Any]:
    callback = source.get("callback_ref") if isinstance(source.get("callback_ref"), dict) else {}
    kind = callback.get("kind") or source.get("kind") or kind_from_raw(raw_ref)
    return {
        "transport": callback.get("transport") or source.get("transport") or "manual_fixture",
        "session": callback.get("session") or source.get("session") or "unknown",
        "pane": callback.get("pane", source.get("pane")),
        "kind": kind if kind in {"DONE", "BLOCKED", "TIMEOUT", "UNKNOWN"} else "UNKNOWN",
        "received_at": callback.get("received_at") or source.get("received_at") or received_at,
        "raw_ref": callback.get("raw_ref") or raw_ref[:500],
    }


def source_from_callback_ref(callback_ref: str, repo: Path) -> tuple[dict[str, Any], str, str | None]:
    raw_ref = callback_ref
    path: Path | None = None
    if callback_ref.startswith("@"):
        path = expand_path(repo, callback_ref[1:])
    elif is_path_like(callback_ref):
        path = expand_path(repo, callback_ref)
    if path is not None:
        try:
            text = path.read_text(encoding="utf-8")
        except Exception as exc:
            return {"kind": "UNKNOWN", "errors": [f"callback_ref_unreadable:{exc}"]}, str(path), "callback_ref_unreadable"
        raw_ref = text.strip()
        try:
            data = json.loads(raw_ref)
            if isinstance(data, dict):
                return data, str(path), None
            return {"kind": "UNKNOWN", "errors": ["callback_ref_json_not_object"]}, str(path), "callback_ref_json_not_object"
        except json.JSONDecodeError:
            if path.suffix == ".json":
                return {"raw": raw_ref, "kind": "UNKNOWN", **parse_kv_text(raw_ref)}, str(path), "validation_receipt_schema_invalid"
            return {"raw": raw_ref, **parse_kv_text(raw_ref)}, str(path), None
    return {"raw": raw_ref, **parse_kv_text(raw_ref)}, raw_ref, None


def build_receipt(
    repo: Path,
    dispatch_id: str,
    callback_ref_arg: str,
    received_at: str,
    task_description: str | None = None,
    allow_missing_tmp_evidence: bool = False,
) -> tuple[dict[str, Any], dict[str, Any]]:
    source, raw_ref, source_error = source_from_callback_ref(callback_ref_arg, repo)
    failure_classes: list[str] = []
    if isinstance(source.get("failure_classes"), list):
        failure_classes.extend(str(item) for item in source["failure_classes"] if str(item).strip())
    if source_error:
        failure_classes.append("validation_receipt_schema_invalid")

    callback_ref = normalize_callback_ref(source, raw_ref, received_at)
    kv = parse_kv_text(raw_ref)
    agent_mail_receipt, agent_mail_failures = build_agent_mail_receipt(source, kv)
    failure_classes.extend(agent_mail_failures)
    evidence_redaction_receipt, evidence_redaction_failures = build_evidence_redaction_receipt(
        source,
        kv,
        agent_mail_receipt["files_reserved"],
    )
    failure_classes.extend(evidence_redaction_failures)
    l61_required = l61_task_requires_fields(source, task_description)
    l61_missing = l61_missing_fields(source, kv) if l61_required else []
    if l61_missing:
        failure_classes.append("orch_callback_missing_l61_fields")

    josh_request_present, dispatch_jr_id = dispatch_josh_request_id(task_description)
    callback_jr_id = callback_josh_request_id(source, kv)
    if task_description and not josh_request_present:
        failure_classes.append("dispatch_missing_josh_request_id")
    elif josh_request_present and not callback_jr_id:
        failure_classes.append("callback_missing_josh_request_id")
    elif josh_request_present and callback_jr_id != dispatch_jr_id:
        failure_classes.append("callback_josh_request_id_mismatch")

    evidence: list[dict[str, Any]] = []
    for item in source.get("evidence", []) if isinstance(source.get("evidence"), list) else []:
        if isinstance(item, dict):
            evidence.append(item)
    for key in ("evidence", "receipt"):
        if key in kv and kv[key] not in {"none", "NONE", "null"}:
            evidence.append(evidence_from_path(kv[key], repo))

    allow_tmp_evidence = allow_missing_tmp_evidence or bool_field(source, kv, "allow_missing_tmp_evidence")
    artifact_items = source.get("artifact_checks") or source.get("artifacts") or source.get("artifact_paths") or []
    artifact_checks = (
        [artifact_check_with_options(item, repo, allow_missing_tmp_evidence=allow_tmp_evidence) for item in artifact_items]
        if isinstance(artifact_items, list)
        else []
    )
    for item in evidence_artifact_items(source):
        if not any(check["path"] == item["path"] for check in artifact_checks):
            artifact_checks.append(artifact_check_with_options(item, repo, allow_missing_tmp_evidence=allow_tmp_evidence))
    if "evidence" in kv and kv["evidence"] not in {"none", "NONE", "null"}:
        artifact_checks.append(
            artifact_check_with_options(
                {"artifact_id": "callback_evidence", "path": kv["evidence"]},
                repo,
                allow_missing_tmp_evidence=allow_tmp_evidence,
            )
        )

    runtime_source = source.get("runtime_context") if isinstance(source.get("runtime_context"), dict) else {}
    agent_context_source = runtime_source.get("agent_context") if isinstance(runtime_source.get("agent_context"), dict) else {}
    orchestrator_context_source = runtime_source.get("orchestrator_shell_context") if isinstance(runtime_source.get("orchestrator_shell_context"), dict) else {}
    timeout = bool(source.get("timeout") or runtime_source.get("timeout") or callback_ref["kind"] == "TIMEOUT")
    agent_status = source.get("agent_status") or agent_context_source.get("status") or "responsive"
    if agent_status not in {"responsive", "unresponsive", "unknown"}:
        agent_status = "unknown"
    context_drift = bool(source.get("context_drift") or runtime_source.get("context_drift"))

    bead_actions = source.get("bead_actions") if isinstance(source.get("bead_actions"), list) else []
    if "no_bead_reason" in kv and kv["no_bead_reason"] not in {"none", "NONE", "null"}:
        bead_actions.append({"action": "no_bead_reason", "reason": kv["no_bead_reason"]})
    if not bead_actions:
        bead_actions = [{"action": "none"}]

    learn_route = source.get("learn_route") if isinstance(source.get("learn_route"), dict) else {
        "route": "review",
        "reason": "callback validation generated by validate-callback",
    }
    chain_blocker = source.get("chain_blocker") if isinstance(source.get("chain_blocker"), dict) else {
        "next_phase": kv.get("next_phase") if kv.get("next_phase") not in {None, "", "none", "NONE"} else None,
        "capacity_available": bool(source.get("capacity_available", False)),
        "chain_blocked_reason": kv.get("chain_blocked_reason") if kv.get("chain_blocked_reason") not in {None, "", "none", "NONE"} else None,
    }

    if timeout or agent_status == "unresponsive":
        status = "unknown"
        failure_classes.append("runtime_unresponsive")
    elif source.get("status") == "unknown":
        status = "unknown"
        if not failure_classes:
            failure_classes.append("runtime_unresponsive")
    elif context_drift:
        status = "fail"
        failure_classes.append("context_drift")
    elif source.get("status") == "fail" or failure_classes:
        status = "fail"
        if not failure_classes:
            failure_classes.append("callback_validation_failed")
    elif any(item["status"] == "missing" for item in artifact_checks):
        status = "fail"
        failure_classes.append("artifact_missing")
    elif callback_ref["kind"] == "UNKNOWN":
        status = "fail"
        failure_classes.append("callback_malformed")
    elif callback_ref["kind"] == "BLOCKED" and not any(item.get("type") == "fuckup_log" for item in evidence):
        status = "fail"
        failure_classes.append("blocked_without_fuckup_log")
    elif callback_ref["kind"] == "DONE" and not evidence:
        status = "fail"
        failure_classes.append("evidence_missing")
    else:
        status = "pass"

    if status == "fail" and not any(
        action.get("action") in {"filed", "updated", "no_bead_reason", "reopen_candidate"} for action in bead_actions
    ):
        failure_classes.append("remediation_missing")

    failure_classes = sorted(set(failure_classes))
    taxonomy = classify_failure_taxonomy(failure_classes, status)
    receipt = {
        "schema_version": SCHEMA_VERSION,
        "dispatch_id": dispatch_id,
        "callback_ref": callback_ref,
        "status": status,
        **taxonomy,
        "failure_classes": failure_classes,
        "evidence": evidence,
        "artifact_checks": artifact_checks,
        "runtime_context": {
            "agent_context": {
                "status": agent_status,
                "probe_ref": str(source.get("agent_probe_ref") or agent_context_source.get("probe_ref") or "callback-ref"),
                **(
                    {"resolved_tools": agent_context_source["resolved_tools"]}
                    if isinstance(agent_context_source.get("resolved_tools"), list)
                    else {}
                ),
            },
            "orchestrator_shell_context": {
                "status": orchestrator_context_source.get("status") or "responsive",
                "probe_ref": str(orchestrator_context_source.get("probe_ref") or "validate-callback-local"),
                **(
                    {"resolved_tools": orchestrator_context_source["resolved_tools"]}
                    if isinstance(orchestrator_context_source.get("resolved_tools"), list)
                    else {}
                ),
            },
            "timeout": timeout,
            "timeout_seconds": int(source.get("timeout_seconds") or 0),
            "context_drift": context_drift,
        },
        "agent_mail": agent_mail_receipt,
        "evidence_redaction": evidence_redaction_receipt,
        "bead_actions": bead_actions,
        "learn_route": learn_route,
        "chain_blocker": chain_blocker,
    }
    meta = {
        "source_ref": raw_ref if raw_ref.startswith("/") else callback_ref_arg,
        "source_error": source_error,
        "l61_required": l61_required,
        "l61_missing_fields": l61_missing,
        "josh_request_id_required": bool(task_description),
        "dispatch_josh_request_id": dispatch_jr_id,
        "callback_josh_request_id": callback_jr_id,
        "evidence_redaction": evidence_redaction_receipt,
        "allow_missing_tmp_evidence": allow_tmp_evidence,
    }
    return receipt, meta


def validate_receipt(repo: Path, receipt: dict[str, Any]) -> tuple[bool, list[dict[str, Any]]]:
    parse = repo / DEFAULT_SCHEMA_DIR / "parse.sh"
    if not parse.exists():
        return False, [{"file": None, "code": "parser_missing", "message": str(parse)}]
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False, encoding="utf-8") as fh:
        json.dump(receipt, fh, sort_keys=True)
        tmp = Path(fh.name)
    try:
        proc = subprocess.run(["bash", str(parse), str(tmp)], cwd=str(repo), check=False, text=True, capture_output=True)
        payload_text = proc.stdout or proc.stderr or "{}"
        try:
            payload = json.loads(payload_text)
        except json.JSONDecodeError:
            payload = {"errors": [{"file": str(tmp), "code": "parser_output_invalid", "message": payload_text[:500]}]}
        return proc.returncode == 0, payload.get("errors") or []
    finally:
        tmp.unlink(missing_ok=True)


def write_receipt(repo: Path, receipt: dict[str, Any], receipt_dir: Path) -> Path:
    target_dir = receipt_dir if receipt_dir.is_absolute() else repo / receipt_dir
    target_dir.mkdir(parents=True, exist_ok=True)
    digest = sha256_text(json.dumps(receipt, sort_keys=True))[:12]
    target = target_dir / f"{receipt['dispatch_id']}-{receipt['callback_ref']['kind'].lower()}-{digest}.json"
    tmp = target.with_suffix(target.suffix + ".tmp")
    tmp.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    tmp.replace(target)
    return target


def output_schema(repo: Path) -> dict[str, Any]:
    return {
        "command": "flywheel-loop validate-callback",
        "schema_version": SCHEMA_VERSION,
        "receipt_schema": str(repo / DEFAULT_SCHEMA_DIR / "schema.json"),
        "default_receipt_dir": str(repo / RECEIPT_DIR),
        "exit_codes": {"0": "pass", "1": "fail", "2": "usage", "3": "unknown"},
        "required_args": ["--repo", "--dispatch-id", "--callback-ref"],
        "optional_args": ["--task-description"],
        "tmp_evidence_override": "--allow-missing-tmp-evidence marks missing /tmp or /private/tmp evidence paths unknown instead of missing; durable evidence paths still fail closed.",
        "failure_class_enum": sorted(FAILURE_CLASS_VALUES),
        "retry_policy_enum": sorted(RETRY_POLICIES),
        "agent_mail_receipt_fields": [
            "agent_mail_thread",
            "identity_name",
            "files_reserved",
            "files_released",
            "reservation_conflicts",
            "reservation_lifecycle",
        ],
        "evidence_redacted_values": ["yes", "no", "n/a"],
        "evidence_redaction_required_when_files_reserved_match": list(EVIDENCE_REDACTION_PATH_PATTERNS),
        "evidence_redaction_remediation": EVIDENCE_REDACTION_REMEDIATION,
        "reservation_lifecycle_states": [
            "no_reservation_required",
            "reservation_succeeded",
            "released",
            "conflict",
            "expired",
            "force-released",
        ],
        "read_only_default": True,
        "write_requires": "--write-receipt",
    }


def examples_json() -> dict[str, Any]:
    return {
        "examples": [
            "flywheel-loop validate-callback --repo /Users/josh/Developer/flywheel --dispatch-id abc --callback-ref /tmp/callback.json --json",
            "flywheel-loop validate-callback --repo . --dispatch-id abc --task-description 'josh_request_id=null' --callback-ref 'DONE bead=x evidence=/tmp/evidence.md josh_request_id=null evidence_redacted=n/a no_bead_reason=fixture' --json",
            "flywheel-loop validate-callback --repo . --dispatch-id abc --callback-ref 'DONE abc evidence=/tmp/evidence.md josh_request_id=null files_reserved=reports/evidence/proof.md files_released=reports/evidence/proof.md evidence_redacted=yes no_bead_reason=redacted-evidence' --json",
            "flywheel-loop validate-callback --repo . --dispatch-id abc --callback-ref /tmp/callback.json --write-receipt --json",
            "flywheel-loop validate-callback --repo . --why .flywheel/validation-receipts/abc-done.json --json",
            "flywheel-loop validate-callback --repo . --dispatch-id abc --task-description 'ship canonical L-rule josh_request_id=null' --callback-ref 'DONE abc evidence=/tmp/evidence.md josh_request_id=null evidence_redacted=n/a agents_md_updated=yes readme_updated=no no_touch_reason=README-not-user-facing' --json",
            "flywheel-loop validate-callback --repo . --dispatch-id abc --callback-ref 'DONE abc evidence=/tmp/evidence.md josh_request_id=null evidence_redacted=n/a agent_mail_thread=thread-123 identity_name=CloudyMill files_reserved=README.md files_released=README.md reservation_conflicts=none no_bead_reason=fixture' --json",
            "flywheel-loop validate-callback --repo . --dispatch-id abc --callback-ref 'DONE abc evidence=/tmp/ephemeral-proof-dir evidence_redacted=n/a no_bead_reason=tmp-dir-fixture' --allow-missing-tmp-evidence --json",
        ]
    }


def why_receipt(path: Path) -> dict[str, Any]:
    receipt = load_json_file(path)
    status = receipt.get("status")
    failures = receipt.get("failure_classes") or []
    gates = [
        {"gate": "schema", "status": "pass" if receipt.get("schema_version") == SCHEMA_VERSION else "fail"},
        {"gate": "artifacts", "status": "fail" if any(a.get("status") == "missing" for a in receipt.get("artifact_checks", [])) else "pass"},
        {"gate": "runtime", "status": "unknown" if receipt.get("runtime_context", {}).get("timeout") else "pass"},
        {"gate": "remediation", "status": "fail" if "remediation_missing" in failures else "pass"},
    ]
    return {
        "receipt": str(path),
        "status": status,
        "failure_class": receipt.get("failure_class"),
        "retry_policy": receipt.get("retry_policy"),
        "recovery_hint": receipt.get("recovery_hint"),
        "failure_classes": failures,
        "summary_allowed": status == "pass",
        "integration_allowed": status == "pass",
        "gates": gates,
    }


def main() -> int:
    parser = argparse.ArgumentParser(prog="validate-callback")
    parser.add_argument("--repo", default=".")
    parser.add_argument("--dispatch-id")
    parser.add_argument("--callback-ref")
    parser.add_argument("--task-description", default="")
    parser.add_argument("--received-at")
    parser.add_argument("--allow-missing-tmp-evidence", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--write-receipt", action="store_true")
    parser.add_argument("--receipt-dir", default=str(RECEIPT_DIR))
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--why")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    repo = Path(args.repo).expanduser().resolve()
    if args.schema:
        print(json.dumps(output_schema(repo), indent=None if args.json else 2, sort_keys=True))
        return 0
    if args.examples:
        payload = examples_json()
        print(json.dumps(payload, indent=None if args.json else 2, sort_keys=True))
        return 0
    if args.why:
        payload = why_receipt(expand_path(repo, args.why))
        print(json.dumps(payload, indent=None if args.json else 2, sort_keys=True))
        return 0 if payload["status"] == "pass" else 1
    if not args.dispatch_id or not args.callback_ref:
        parser.error("--dispatch-id and --callback-ref are required unless --schema, --examples, or --why is used")

    receipt, meta = build_receipt(
        repo,
        args.dispatch_id,
        args.callback_ref,
        args.received_at or utc_now(),
        args.task_description,
        args.allow_missing_tmp_evidence,
    )
    schema_valid, schema_errors = validate_receipt(repo, receipt)
    if not schema_valid and receipt["status"] == "pass":
        receipt["status"] = "fail"
        receipt["failure_classes"] = sorted(set(receipt["failure_classes"] + ["validation_receipt_schema_invalid"]))
        schema_valid, schema_errors = validate_receipt(repo, receipt)

    receipt_path = None
    if args.write_receipt:
        receipt_path = write_receipt(repo, receipt, Path(args.receipt_dir))

    status = receipt["status"]
    payload = {
        "command": "validate-callback",
        "schema_valid": schema_valid,
        "schema_errors": schema_errors,
        "status": status,
        "failure_class": receipt.get("failure_class"),
        "legacy_failure_class": receipt["failure_classes"][0] if receipt["failure_classes"] else None,
        "retry_policy": receipt.get("retry_policy"),
        "recovery_hint": receipt.get("recovery_hint"),
        "failure_classes": receipt["failure_classes"],
        "summary_allowed": status == "pass",
        "integration_allowed": status == "pass",
        "remediation_required": status == "fail",
        "remediation_present": any(
            a.get("action") in {"filed", "updated", "no_bead_reason", "reopen_candidate"} for a in receipt["bead_actions"]
        ),
        "read_only": not args.write_receipt,
        "dry_run": bool(args.dry_run or not args.write_receipt),
        "receipt_path": str(receipt_path) if receipt_path else None,
        "validation_receipt": receipt,
        "dispatch_log_event": {
            "event": "callback_validation",
            "dispatch_id": args.dispatch_id,
            "validation_receipt": str(receipt_path) if receipt_path else None,
            "status": status,
            "failure_class": receipt.get("failure_class"),
            "retry_policy": receipt.get("retry_policy"),
            "recovery_hint": receipt.get("recovery_hint"),
            "failure_classes": receipt["failure_classes"],
            "summary_allowed": status == "pass",
            "integration_allowed": status == "pass",
        },
        "meta": meta,
    }
    print(json.dumps(payload, indent=None if args.json else 2, sort_keys=True))
    if status == "pass" and schema_valid:
        return 0
    if status == "unknown":
        return 3
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
