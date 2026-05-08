#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

if [[ "$#" -lt 1 ]]; then
  printf '{"valid":false,"errors":[{"file":null,"code":"usage","message":"usage: parse.sh RECEIPT.json [...]"}]}\n' >&2
  exit 2
fi

python3 - "$ROOT/schema.json" "$@" <<'PY'
import json
import re
import sys
from pathlib import Path

schema_path = Path(sys.argv[1])
paths = [Path(p) for p in sys.argv[2:]]

REQUIRED = [
    "schema_version",
    "dispatch_id",
    "callback_ref",
    "status",
    "failure_class",
    "retry_policy",
    "recovery_hint",
    "failure_classes",
    "evidence",
    "artifact_checks",
    "runtime_context",
    "agent_mail",
    "bead_actions",
    "learn_route",
    "chain_blocker",
]

STATUS = {"pass", "fail", "unknown"}
FAILURE_CLASS = {"transient", "persistent", "correctness", "missing_artifact", "invalid_callback", "context_drift", "unknown"}
RETRY_POLICY = {"none", "exponential", "manual", "permanent"}
CALLBACK_KIND = {"DONE", "BLOCKED", "TIMEOUT", "UNKNOWN"}
TRANSPORT = {"ntm", "agent_mail", "manual_fixture"}
EVIDENCE_TYPES = {
    "path",
    "command",
    "dispatch_log",
    "bead_id",
    "commit_sha",
    "transcript_hash",
    "joshua_confirmation_hash",
    "fuckup_log",
}
ARTIFACT_STATUS = {"exists", "missing", "unknown"}
RUNTIME_STATUS = {"responsive", "unresponsive", "unknown"}
RESERVATION_STATES = {"no_reservation_required", "reservation_succeeded", "released", "conflict", "expired", "force-released"}
BEAD_ACTIONS = {"filed", "updated", "no_bead_reason", "reopen_candidate", "none"}
LEARN_ROUTES = {"ignore", "review", "promote", "skill_extend"}
WEAK_NO_BEAD_REASONS = {"", "n/a", "na", "none", "no", "because", "not needed", "skip"}
SECRET_PATTERNS = [
    re.compile(r"mcp_[A-Za-z0-9_-]{20,}"),
    re.compile(r"agent[-_ ]?mail[-_ ]?(token|bearer)", re.I),
    re.compile(r"sk-[A-Za-z0-9]{20,}"),
    re.compile(r"AKIA[0-9A-Z]{16}"),
]


def add(errors, code, message, path):
    errors.append({"file": str(path), "code": code, "message": message})


def is_obj(value):
    return isinstance(value, dict)


def is_nonempty_str(value):
    return isinstance(value, str) and bool(value.strip())


def scan_secret_like(value):
    text = json.dumps(value, sort_keys=True)
    return any(p.search(text) for p in SECRET_PATTERNS)


def validate_evidence(item, errors, path, prefix):
    if not is_obj(item):
        add(errors, "evidence_not_object", f"{prefix} must be an object", path)
        return
    typ = item.get("type")
    ref = item.get("ref")
    if typ not in EVIDENCE_TYPES:
        add(errors, "evidence_type_invalid", f"{prefix}.type must be one of {sorted(EVIDENCE_TYPES)}", path)
    if not is_nonempty_str(ref):
        add(errors, "evidence_ref_missing", f"{prefix}.ref must be a non-empty string", path)


def validate_runtime_probe(obj, errors, path, prefix):
    if not is_obj(obj):
        add(errors, "runtime_probe_not_object", f"{prefix} must be an object", path)
        return
    if obj.get("status") not in RUNTIME_STATUS:
        add(errors, "runtime_probe_status_invalid", f"{prefix}.status must be one of {sorted(RUNTIME_STATUS)}", path)
    if not is_nonempty_str(obj.get("probe_ref")):
        add(errors, "runtime_probe_ref_missing", f"{prefix}.probe_ref must be a non-empty string", path)
    if "resolved_tools" in obj and not isinstance(obj["resolved_tools"], list):
        add(errors, "runtime_probe_tools_not_array", f"{prefix}.resolved_tools must be an array", path)


def validate_receipt(data, path):
    errors = []

    if not is_obj(data):
        add(errors, "receipt_not_object", "receipt must be a JSON object", path)
        return errors

    if scan_secret_like(data):
        add(errors, "secret_like_fixture_value", "fixture contains a token-shaped or secret-like value", path)

    for key in REQUIRED:
        if key not in data:
            add(errors, "required_missing", f"missing required field: {key}", path)

    if data.get("schema_version") != "validation-receipt/v1":
        add(errors, "schema_version_invalid", "schema_version must be validation-receipt/v1", path)

    if not is_nonempty_str(data.get("dispatch_id")):
        add(errors, "dispatch_id_missing", "dispatch_id must be a non-empty string", path)

    callback = data.get("callback_ref")
    if is_obj(callback):
        if callback.get("transport") not in TRANSPORT:
            add(errors, "callback_transport_invalid", f"callback_ref.transport must be one of {sorted(TRANSPORT)}", path)
        if callback.get("kind") not in CALLBACK_KIND:
            add(errors, "callback_kind_invalid", f"callback_ref.kind must be one of {sorted(CALLBACK_KIND)}", path)
        if not is_nonempty_str(callback.get("session")):
            add(errors, "callback_session_missing", "callback_ref.session must be a non-empty string", path)
        if "pane" not in callback or not (callback.get("pane") is None or isinstance(callback.get("pane"), int)):
            add(errors, "callback_pane_invalid", "callback_ref.pane must be an integer or null", path)
        if not is_nonempty_str(callback.get("received_at")):
            add(errors, "callback_received_at_missing", "callback_ref.received_at must be a non-empty timestamp string", path)
    elif "callback_ref" in data:
        add(errors, "callback_ref_not_object", "callback_ref must be an object", path)

    status = data.get("status")
    if status not in STATUS:
        add(errors, "status_invalid", "status must be pass, fail, or unknown", path)

    failure_class = data.get("failure_class")
    if failure_class is not None and failure_class not in FAILURE_CLASS:
        add(errors, "failure_class_enum_invalid", f"failure_class must be null or one of {sorted(FAILURE_CLASS)}", path)

    retry_policy = data.get("retry_policy")
    if retry_policy not in RETRY_POLICY:
        add(errors, "retry_policy_invalid", f"retry_policy must be one of {sorted(RETRY_POLICY)}", path)

    recovery_hint = data.get("recovery_hint")
    if not is_nonempty_str(recovery_hint):
        add(errors, "recovery_hint_missing", "recovery_hint must be a non-empty string", path)

    failure_classes = data.get("failure_classes")
    if not isinstance(failure_classes, list):
        add(errors, "failure_classes_not_array", "failure_classes must be an array", path)
        failure_classes = []
    elif any(not is_nonempty_str(v) for v in failure_classes):
        add(errors, "failure_class_invalid", "failure_classes entries must be non-empty strings", path)
    elif len(set(failure_classes)) != len(failure_classes):
        add(errors, "failure_classes_duplicate", "failure_classes entries must be unique", path)

    evidence = data.get("evidence")
    if not isinstance(evidence, list):
        add(errors, "evidence_not_array", "evidence must be an array", path)
        evidence = []
    else:
        for idx, item in enumerate(evidence):
            validate_evidence(item, errors, path, f"evidence[{idx}]")

    artifact_checks = data.get("artifact_checks")
    if not isinstance(artifact_checks, list):
        add(errors, "artifact_checks_not_array", "artifact_checks must be an array", path)
        artifact_checks = []
    else:
        for idx, item in enumerate(artifact_checks):
            if not is_obj(item):
                add(errors, "artifact_check_not_object", f"artifact_checks[{idx}] must be an object", path)
                continue
            if not is_nonempty_str(item.get("artifact_id")):
                add(errors, "artifact_id_missing", f"artifact_checks[{idx}].artifact_id must be non-empty", path)
            if not is_nonempty_str(item.get("path")):
                add(errors, "artifact_path_missing", f"artifact_checks[{idx}].path must be non-empty", path)
            if item.get("status") not in ARTIFACT_STATUS:
                add(errors, "artifact_status_invalid", f"artifact_checks[{idx}].status must be one of {sorted(ARTIFACT_STATUS)}", path)

    runtime = data.get("runtime_context")
    if is_obj(runtime):
        validate_runtime_probe(runtime.get("agent_context"), errors, path, "runtime_context.agent_context")
        validate_runtime_probe(runtime.get("orchestrator_shell_context"), errors, path, "runtime_context.orchestrator_shell_context")
        if not isinstance(runtime.get("timeout"), bool):
            add(errors, "runtime_timeout_not_bool", "runtime_context.timeout must be boolean", path)
        if not isinstance(runtime.get("context_drift"), bool):
            add(errors, "runtime_context_drift_not_bool", "runtime_context.context_drift must be boolean", path)
    elif "runtime_context" in data:
        add(errors, "runtime_context_not_object", "runtime_context must be an object", path)

    agent_mail = data.get("agent_mail")
    if is_obj(agent_mail):
        for key in ("files_reserved", "files_released", "reservation_conflicts"):
            value = agent_mail.get(key)
            if not isinstance(value, list):
                add(errors, "agent_mail_list_invalid", f"agent_mail.{key} must be an array", path)
            elif any(not is_nonempty_str(item) for item in value):
                add(errors, "agent_mail_list_entry_invalid", f"agent_mail.{key} entries must be non-empty strings", path)
        for key in ("agent_mail_thread", "identity_name"):
            value = agent_mail.get(key)
            if value is not None and not is_nonempty_str(value):
                add(errors, "agent_mail_string_invalid", f"agent_mail.{key} must be null or a non-empty string", path)
        lifecycle = agent_mail.get("reservation_lifecycle")
        if is_obj(lifecycle):
            if lifecycle.get("state") not in RESERVATION_STATES:
                add(errors, "reservation_lifecycle_state_invalid", f"agent_mail.reservation_lifecycle.state must be one of {sorted(RESERVATION_STATES)}", path)
            if not is_nonempty_str(lifecycle.get("reason")):
                add(errors, "reservation_lifecycle_reason_missing", "agent_mail.reservation_lifecycle.reason must be non-empty", path)
        else:
            add(errors, "reservation_lifecycle_not_object", "agent_mail.reservation_lifecycle must be an object", path)
    elif "agent_mail" in data:
        add(errors, "agent_mail_not_object", "agent_mail must be an object", path)

    bead_actions = data.get("bead_actions")
    if not isinstance(bead_actions, list):
        add(errors, "bead_actions_not_array", "bead_actions must be an array", path)
        bead_actions = []
    else:
        for idx, item in enumerate(bead_actions):
            if not is_obj(item):
                add(errors, "bead_action_not_object", f"bead_actions[{idx}] must be an object", path)
                continue
            if item.get("action") not in BEAD_ACTIONS:
                add(errors, "bead_action_invalid", f"bead_actions[{idx}].action must be one of {sorted(BEAD_ACTIONS)}", path)
            if item.get("action") == "no_bead_reason":
                reason = str(item.get("reason", "")).strip().lower()
                if len(reason) < 12 or reason in WEAK_NO_BEAD_REASONS:
                    add(errors, "no_bead_reason_invalid", f"bead_actions[{idx}].reason is too weak for no_bead_reason", path)

    learn = data.get("learn_route")
    if is_obj(learn):
        if learn.get("route") not in LEARN_ROUTES:
            add(errors, "learn_route_invalid", f"learn_route.route must be one of {sorted(LEARN_ROUTES)}", path)
        if not is_nonempty_str(learn.get("reason")):
            add(errors, "learn_route_reason_missing", "learn_route.reason must be non-empty", path)
    elif "learn_route" in data:
        add(errors, "learn_route_not_object", "learn_route must be an object", path)

    chain = data.get("chain_blocker")
    if is_obj(chain):
        if "next_phase" not in chain or not (chain.get("next_phase") is None or isinstance(chain.get("next_phase"), str)):
            add(errors, "chain_next_phase_invalid", "chain_blocker.next_phase must be string or null", path)
        if not isinstance(chain.get("capacity_available"), bool):
            add(errors, "chain_capacity_not_bool", "chain_blocker.capacity_available must be boolean", path)
        if "chain_blocked_reason" not in chain or not (chain.get("chain_blocked_reason") is None or isinstance(chain.get("chain_blocked_reason"), str)):
            add(errors, "chain_blocked_reason_invalid", "chain_blocker.chain_blocked_reason must be string or null", path)
    elif "chain_blocker" in data:
        add(errors, "chain_blocker_not_object", "chain_blocker must be an object", path)

    # Cross-field invariants used by callback validation.
    if status == "pass" and failure_classes:
        add(errors, "pass_with_failure_classes", "status=pass cannot carry failure_classes", path)
    if status == "pass" and failure_class is not None:
        add(errors, "pass_with_failure_class", "status=pass must carry failure_class=null", path)
    if status != "pass" and failure_class is None:
        add(errors, "failure_missing_failure_class", "non-pass receipts require failure_class", path)
    if status == "fail" and not failure_classes:
        add(errors, "fail_missing_failure_classes", "status=fail requires at least one failure_class", path)
    if failure_class == "transient" and retry_policy != "exponential":
        add(errors, "transient_retry_policy_invalid", "failure_class=transient requires retry_policy=exponential", path)
    if failure_class == "correctness" and retry_policy != "permanent":
        add(errors, "correctness_retry_policy_invalid", "failure_class=correctness requires retry_policy=permanent", path)
    if failure_class in {"missing_artifact", "invalid_callback", "context_drift", "persistent", "unknown"} and retry_policy not in {"manual", "permanent"}:
        add(errors, "non_flake_retry_policy_invalid", "non-transient failure classes must not use exponential retry", path)

    if is_obj(runtime):
        agent = runtime.get("agent_context") if is_obj(runtime.get("agent_context")) else {}
        if runtime.get("timeout") is True and status != "unknown":
            add(errors, "runtime_timeout_must_be_unknown", "runtime timeout maps to status=unknown, never pass/fail", path)
        if agent.get("status") == "unresponsive" and status != "unknown":
            add(errors, "runtime_unresponsive_must_be_unknown", "unresponsive agent context maps to status=unknown", path)
        if runtime.get("context_drift") is True and status == "pass":
            add(errors, "context_drift_cannot_pass", "context drift cannot validate as pass", path)

    if status == "pass" and any(is_obj(a) and a.get("status") == "missing" for a in artifact_checks):
        add(errors, "pass_with_missing_artifact", "status=pass cannot include missing artifacts", path)

    if is_obj(agent_mail):
        lifecycle = agent_mail.get("reservation_lifecycle") if is_obj(agent_mail.get("reservation_lifecycle")) else {}
        lifecycle_state = lifecycle.get("state")
        if lifecycle_state in {"conflict", "expired"} and status == "pass":
            add(errors, "pass_with_bad_reservation_lifecycle", "conflict or expired reservation lifecycle cannot validate as pass", path)
        if lifecycle_state == "reservation_succeeded" and status == "pass":
            add(errors, "pass_with_unreleased_reservation", "reserved files without release cannot validate as pass", path)

    evidence_types = {e.get("type") for e in evidence if is_obj(e)}
    if is_obj(callback) and callback.get("kind") == "BLOCKED" and "fuckup_log" not in evidence_types:
        add(errors, "blocked_without_fuckup_log", "BLOCKED callback requires fuckup_log evidence", path)

    if is_obj(chain):
        if chain.get("next_phase") and chain.get("capacity_available") is True and not chain.get("chain_blocked_reason") and status == "pass":
            add(errors, "tick_punted_without_chain_blocker", "next_phase with capacity requires chain_blocked_reason unless chain executed elsewhere", path)

    return errors


all_errors = []
results = []
for path in sorted(paths, key=lambda p: str(p)):
    try:
        data = json.loads(path.read_text())
    except Exception as exc:
        all_errors.append({"file": str(path), "code": "json_parse_error", "message": str(exc)})
        continue
    errors = validate_receipt(data, path)
    results.append({"file": str(path), "valid": not errors})
    all_errors.extend(errors)

valid = not all_errors
payload = {
    "schema": str(schema_path),
    "valid": valid,
    "files_checked": len(paths),
    "results": sorted(results, key=lambda r: r["file"]),
    "errors": sorted(all_errors, key=lambda e: (e["file"] or "", e["code"], e["message"])),
}
print(json.dumps(payload, indent=2, sort_keys=True))
sys.exit(0 if valid else 1)
PY
