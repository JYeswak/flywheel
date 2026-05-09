#!/usr/bin/env bash
# canonical-cli-scoping-allow-large: embedded Python keeps schema validation, policy decisions, and canonical CLI JSON in one operator surface.
set -euo pipefail

exec python3 - "$0" "$@" <<'PY'
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

SCHEMA_VERSION = "ntm-policy-contracts.v1"
MISSION_ANCHOR = "continuous-orchestrator-uptime-self-sustaining-fleet"
PLAN_SLUG = "ntm-surface-utilization-migration-2026-05-06"
BEAD_ID = "flywheel-imcs2"
TASK_ID = "ntm-w3bp-policy-6040"
WAVE = "W3b"
SHORT_ID = "W3bP"
L112 = "OK_ntm_migrate_W3bP"
TTL_NATIVE = "native_ntm_policy_contract_runtime"
TTL_WRAPPER = "policy_contract_receipt_30d"
TTL_DECISION = "revalidate_policy_before_privileged_or_mutating_ntm_operation"
NATIVE_WRAPPER_DELTA = (
    "native_ntm_policy_controls_runtime_enforcement_when_enabled;"
    "wrapper_validates_contracts_blocks_privilege_escalation_and_keeps_policy_as_warn_only"
)
ROLLBACK = "disable_policy_as_gate_and_run_policy_validate_warn_only"
AUTHORIZED_OPERATIONS = [
    "policy.validate",
    "policy.audit",
    "policy.why",
    "policy.dry_run",
]
FORBIDDEN_OPERATIONS = [
    "auto_push",
    "force_release",
    "auto_commit",
    "credential_rotation",
    "raw_pane_io",
    "source_ledger_mutation",
]
REQUIRED_FORBIDDEN = {"auto_push", "force_release", "auto_commit"}
REQUIRED_MUTATION_FLAGS = {"--apply", "--idempotency-key"}
ALLOWED_TOP_KEYS = {
    "schema_version": "scalar",
    "mission_anchor": "scalar",
    "plan_slug": "scalar",
    "wave": "scalar",
    "short_id": "scalar",
    "mode": "scalar",
    "default_decision": "scalar",
    "policy_as_gate_enabled": "scalar",
    "native_surface": "scalar",
    "wrapper_surface": "scalar",
    "l112_observed": "scalar",
    "ttl_native": "scalar",
    "ttl_wrapper": "scalar",
    "ttl_decision": "scalar",
    "native_wrapper_delta": "scalar",
    "rollback": "scalar",
    "quality_bar_passed": "scalar",
    "allowed_sessions": "list",
    "authorized_operations": "list",
    "forbidden_operations": "list",
    "escalation_blocklist": "list",
    "mutation_requires": "list",
}
REQUIRED_KEYS = {
    "schema_version",
    "mission_anchor",
    "mode",
    "default_decision",
    "policy_as_gate_enabled",
    "l112_observed",
    "ttl_native",
    "ttl_wrapper",
    "ttl_decision",
    "native_wrapper_delta",
    "allowed_sessions",
    "authorized_operations",
    "forbidden_operations",
    "escalation_blocklist",
    "mutation_requires",
}
TOKEN_RE = re.compile(r"^(--[A-Za-z0-9][A-Za-z0-9_-]*|[A-Za-z0-9][A-Za-z0-9_.:-]*)$")

script_path = Path(sys.argv[1]).resolve()
repo_root = script_path.parent.parent.parent
default_policy = repo_root / ".ntm" / "policy.yaml"


class PolicyError(Exception):
    def __init__(self, reason_code: str, findings: list[dict[str, Any]]):
        self.reason_code = reason_code
        self.findings = findings
        super().__init__(reason_code)


def now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def idempotency_token() -> str:
    material = f"{PLAN_SLUG}|/Users/josh/Developer/flywheel|{BEAD_ID}|{WAVE}|{TASK_ID}"
    return hashlib.sha256(material.encode("utf-8")).hexdigest()


def strip_quotes(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]
    return value


def parse_scalar(value: str) -> Any:
    value = strip_quotes(value)
    if value == "true":
        return True
    if value == "false":
        return False
    return value


def parse_policy(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise PolicyError("policy_missing", [{"severity": "error", "reason_code": "policy_missing", "path": str(path)}])
    data: dict[str, Any] = {}
    current_list: str | None = None
    findings: list[dict[str, Any]] = []
    for line_no, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue
        if raw_line.startswith((" ", "\t")):
            if current_list is None or not raw_line.startswith("  - "):
                findings.append({"severity": "error", "line": line_no, "reason_code": "unsupported_yaml_shape"})
                continue
            item = strip_quotes(raw_line[4:].split(" #", 1)[0])
            if not item:
                findings.append({"severity": "error", "line": line_no, "reason_code": "empty_list_item", "key": current_list})
            else:
                data[current_list].append(item)
            continue

        current_list = None
        if ":" not in raw_line:
            findings.append({"severity": "error", "line": line_no, "reason_code": "missing_key_separator"})
            continue
        key, raw_value = raw_line.split(":", 1)
        key = key.strip()
        value = raw_value.split(" #", 1)[0].strip()
        expected = ALLOWED_TOP_KEYS.get(key)
        if expected is None:
            findings.append({"severity": "error", "line": line_no, "reason_code": "unknown_policy_key", "key": key})
            continue
        if key in data:
            findings.append({"severity": "error", "line": line_no, "reason_code": "duplicate_policy_key", "key": key})
            continue
        if expected == "list":
            if value:
                findings.append({"severity": "error", "line": line_no, "reason_code": "inline_lists_not_supported", "key": key})
            data[key] = []
            current_list = key
        else:
            if not value:
                findings.append({"severity": "error", "line": line_no, "reason_code": "empty_scalar", "key": key})
            data[key] = parse_scalar(value)

    if findings:
        raise PolicyError("malformed_policy", findings)
    return data


def validate_policy_contract(policy: dict[str, Any]) -> list[dict[str, Any]]:
    findings: list[dict[str, Any]] = []
    missing = sorted(REQUIRED_KEYS - set(policy))
    if missing:
        findings.append({"severity": "error", "reason_code": "missing_required_keys", "keys": missing})

    scalar_expectations = {
        "schema_version": SCHEMA_VERSION,
        "mission_anchor": MISSION_ANCHOR,
        "mode": {"warn_only", "shadow", "enforce"},
        "default_decision": "deny",
        "l112_observed": L112,
    }
    for key, expected in scalar_expectations.items():
        if key not in policy:
            continue
        value = policy[key]
        if isinstance(expected, set):
            if value not in expected:
                findings.append({"severity": "error", "reason_code": "invalid_scalar_value", "key": key, "value": value})
        elif value != expected:
            findings.append(
                {"severity": "error", "reason_code": "invalid_scalar_value", "key": key, "expected": expected, "value": value}
            )

    if policy.get("policy_as_gate_enabled") is not False:
        findings.append({"severity": "error", "reason_code": "policy_as_gate_must_be_disabled_for_w3bp"})
    if policy.get("quality_bar_passed") is not True:
        findings.append({"severity": "error", "reason_code": "quality_bar_not_declared"})

    for key, expected_type in ALLOWED_TOP_KEYS.items():
        if key not in policy:
            continue
        value = policy[key]
        if expected_type == "list":
            if not isinstance(value, list) or not value:
                findings.append({"severity": "error", "reason_code": "invalid_list", "key": key})
                continue
            bad = [item for item in value if not isinstance(item, str) or TOKEN_RE.match(item) is None]
            if bad:
                findings.append({"severity": "error", "reason_code": "invalid_list_tokens", "key": key, "items": bad})
        elif isinstance(value, (dict, list)):
            findings.append({"severity": "error", "reason_code": "invalid_scalar_type", "key": key})

    authorized = set(policy.get("authorized_operations", []))
    forbidden = set(policy.get("forbidden_operations", []))
    escalation_blocklist = set(policy.get("escalation_blocklist", []))
    mutation_requires = set(policy.get("mutation_requires", []))

    if authorized != set(AUTHORIZED_OPERATIONS):
        findings.append(
            {
                "severity": "error",
                "reason_code": "authorized_operations_drift",
                "expected": AUTHORIZED_OPERATIONS,
                "observed": sorted(authorized),
            }
        )
    if not REQUIRED_FORBIDDEN.issubset(forbidden):
        findings.append({"severity": "error", "reason_code": "required_forbidden_operations_missing", "missing": sorted(REQUIRED_FORBIDDEN - forbidden)})
    if not REQUIRED_FORBIDDEN.issubset(escalation_blocklist):
        findings.append({"severity": "error", "reason_code": "privilege_escalation_blocklist_missing", "missing": sorted(REQUIRED_FORBIDDEN - escalation_blocklist)})
    if not REQUIRED_MUTATION_FLAGS.issubset(mutation_requires):
        findings.append({"severity": "error", "reason_code": "mutation_requirements_missing", "missing": sorted(REQUIRED_MUTATION_FLAGS - mutation_requires)})
    overlap = sorted(authorized & forbidden)
    if overlap:
        findings.append({"severity": "error", "reason_code": "authorized_forbidden_overlap", "operations": overlap})
    if "flywheel" not in set(policy.get("allowed_sessions", [])):
        findings.append({"severity": "error", "reason_code": "flywheel_session_not_authorized"})
    return findings


def load_valid_policy(path: Path) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    policy = parse_policy(path)
    findings = validate_policy_contract(policy)
    if any(item.get("severity") == "error" for item in findings):
        raise PolicyError("malformed_policy", findings)
    return policy, findings


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
        "secret_values_observed": 0,
        "source_policy_mutated": False,
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


def malformed_payload(path: Path, err: PolicyError) -> dict[str, Any]:
    return base_payload(
        {
            "status": "fail",
            "reason_code": err.reason_code,
            "policy": {"path": str(path), "valid": False},
            "findings": err.findings,
            "allowed": False,
            "would_block": True,
            "gate_effective": False,
            "malformed_policy_escalates_privilege": False,
        }
    )


def decision_payload(policy: dict[str, Any], args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    effective_mode = args.mode or str(policy["mode"])
    operation = args.operation
    session = args.session
    allowed_sessions = set(policy["allowed_sessions"])
    authorized = set(policy["authorized_operations"])
    forbidden = set(policy["forbidden_operations"])
    escalation_blocklist = set(policy["escalation_blocklist"])

    reason_code = "authorized_operation"
    allowed = True
    if session not in allowed_sessions:
        allowed = False
        reason_code = "session_not_authorized"
    elif operation in forbidden or operation in escalation_blocklist:
        allowed = False
        reason_code = "forbidden_operation"
    elif operation not in authorized:
        allowed = False
        reason_code = "operation_not_authorized"

    status = "pass" if allowed else "fail"
    rc = 0 if allowed else 1
    return (
        base_payload(
            {
                "status": status,
                "reason_code": reason_code,
                "checked_at": now_iso(),
                "policy": {
                    "path": str(Path(args.policy).resolve()),
                    "valid": True,
                    "mode": policy["mode"],
                    "policy_as_gate_enabled": policy["policy_as_gate_enabled"],
                },
                "scope": {"session": session, "operation": operation, "effective_mode": effective_mode},
                "allowed": allowed,
                "would_block": not allowed,
                "gate_effective": bool(policy["policy_as_gate_enabled"]) and effective_mode == "enforce",
                "live_gate_action": "warn_only_observation" if effective_mode == "warn_only" else "contract_decision",
                "malformed_policy_escalates_privilege": False,
            }
        ),
        rc,
    )


def command_info() -> dict[str, Any]:
    return base_payload(
        {
            "status": "ok",
            "name": "ntm-policy-contracts",
            "canonical_cli": {
                "doctor": True,
                "health": True,
                "repair": True,
                "validate": True,
                "audit": True,
                "why": True,
                "json": True,
                "schema": True,
                "examples": True,
                "dry_run": True,
                "apply_requires_idempotency_key": True,
            },
            "stable_exit_codes": {
                "0": "policy contract pass",
                "1": "operation denied by policy contract",
                "2": "usage or missing idempotency key for apply",
                "3": "missing or malformed policy",
            },
        }
    )


def command_schema() -> dict[str, Any]:
    return base_payload(
        {
            "status": "ok",
            "required_policy_keys": sorted(REQUIRED_KEYS),
            "allowed_top_level_keys": sorted(ALLOWED_TOP_KEYS),
            "status_values": ["pass", "fail", "ok"],
            "mode_values": ["warn_only", "shadow", "enforce"],
            "default_decision": "deny",
            "malformed_policy_behavior": "fail_closed_allowed_false",
            "apply_requires": ["--apply", "--idempotency-key"],
            "dry_run_default": True,
        }
    )


def command_examples() -> dict[str, Any]:
    return base_payload(
        {
            "status": "ok",
            "examples": [
                ".flywheel/scripts/ntm-policy-contracts.sh validate --operation policy.validate --session flywheel --json",
                ".flywheel/scripts/ntm-policy-contracts.sh validate --operation auto_push --session flywheel --json",
                ".flywheel/scripts/ntm-policy-contracts.sh audit --policy .ntm/policy.yaml --json",
                ".flywheel/scripts/ntm-policy-contracts.sh repair --dry-run --json",
            ],
        }
    )


def command_why(reason: str) -> dict[str, Any]:
    explanations = {
        "malformed-policy": "Malformed policy is treated as fail-closed with allowed=false so parse errors cannot grant privilege.",
        "warn-only": "W3bP keeps policy_as_gate_enabled=false; validate/audit are contract checks, not live automatic privilege gates.",
        "forbidden-operations": "auto_push, force_release, and auto_commit are always denied because they can mutate shared substrate without an explicit human or idempotent wrapper gate.",
        "mutation-discipline": "--apply is accepted only with --idempotency-key, and this wrapper never mutates policy source.",
    }
    return base_payload({"status": "ok", "reason": reason, "explanations": explanations, "selected": explanations.get(reason, explanations["malformed-policy"])})


def command_repair(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    if args.apply and not args.idempotency_key:
        return (
            base_payload(
                {
                    "status": "fail",
                    "reason_code": "missing_idempotency_key",
                    "allowed": False,
                    "would_block": True,
                    "repair_action": "none",
                    "source_policy_mutated": False,
                }
            ),
            2,
        )
    return (
        base_payload(
            {
                "status": "pass",
                "reason_code": "repair_is_reversible_noop",
                "repair_action": "validate_warn_only_and_keep_policy_as_gate_disabled",
                "apply_requested": bool(args.apply),
                "idempotency_key": args.idempotency_key,
                "source_policy_mutated": False,
                "cannot_repair": [
                    "automatic privilege grant",
                    "auto push",
                    "force release",
                    "auto commit",
                ],
            }
        ),
        0,
    )


def command_doctor(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    path = Path(args.policy).resolve()
    try:
        policy, findings = load_valid_policy(path)
    except PolicyError as err:
        return malformed_payload(path, err), 3
    checks = {
        "canonical_cli": {"doctor": True, "health": True, "repair": True, "validate": True, "audit": True, "why": True},
        "policy": {
            "schema_valid": True,
            "default_decision_deny": policy["default_decision"] == "deny",
            "policy_as_gate_disabled": policy["policy_as_gate_enabled"] is False,
            "forbidden_privileged_operations": REQUIRED_FORBIDDEN.issubset(set(policy["forbidden_operations"])),
            "mutation_requires_apply_and_idempotency_key": REQUIRED_MUTATION_FLAGS.issubset(set(policy["mutation_requires"])),
        },
    }
    return base_payload({"status": "pass", "reason_code": "policy_contract_healthy", "policy": {"path": str(path), "valid": True}, "checks": checks, "findings": findings}), 0


def command_audit(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    path = Path(args.policy).resolve()
    try:
        policy, findings = load_valid_policy(path)
    except PolicyError as err:
        return malformed_payload(path, err), 3
    forbidden_results: list[dict[str, Any]] = []
    for op in sorted(REQUIRED_FORBIDDEN):
        probe_args = argparse.Namespace(**vars(args))
        probe_args.operation = op
        payload, _ = decision_payload(policy, probe_args)
        forbidden_results.append({"operation": op, "allowed": payload["allowed"], "reason_code": payload["reason_code"]})
    valid_args = argparse.Namespace(**vars(args))
    valid_args.operation = "policy.validate"
    allowed_payload, _ = decision_payload(policy, valid_args)
    pass_audit = (
        all(item["allowed"] is False and item["reason_code"] == "forbidden_operation" for item in forbidden_results)
        and allowed_payload["allowed"] is True
    )
    return (
        base_payload(
            {
                "status": "pass" if pass_audit else "fail",
                "reason_code": "policy_contract_audit_passed" if pass_audit else "policy_contract_audit_failed",
                "policy": {"path": str(path), "valid": True, "mode": policy["mode"], "policy_as_gate_enabled": policy["policy_as_gate_enabled"]},
                "authorized_probe": {"operation": "policy.validate", "allowed": allowed_payload["allowed"], "reason_code": allowed_payload["reason_code"]},
                "forbidden_probe_results": forbidden_results,
                "findings": findings,
                "malformed_policy_escalates_privilege": False,
                "no_auto_push": True,
                "no_force_release": True,
                "no_auto_commit": True,
                "source_policy_mutated": False,
            }
        ),
        0 if pass_audit else 1,
    )


def completion(shell: str) -> int:
    words = "doctor health repair validate audit why schema quickstart info examples completion"
    if shell == "bash":
        print(f"complete -W '{words}' ntm-policy-contracts.sh")
    else:
        print(words)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("command", nargs="?", default="doctor")
    parser.add_argument("reason_arg", nargs="?")
    parser.add_argument("--policy", default=str(default_policy))
    parser.add_argument("--session", default="flywheel")
    parser.add_argument("--operation", default="policy.validate")
    parser.add_argument("--mode", choices=["warn_only", "shadow", "enforce"])
    parser.add_argument("--reason", default="malformed-policy")
    parser.add_argument("--idempotency-key")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("-h", "--help", action="store_true")
    return parser


def usage() -> str:
    return """usage: ntm-policy-contracts.sh [doctor|health|repair|validate|audit|why|schema|quickstart|info|examples|completion] [options]

Validate NTM policy contracts in warn-only mode and fail closed on malformed
policy or privileged operations.

Options:
  --policy PATH             Policy file (default: .ntm/policy.yaml)
  --session NAME            Session to evaluate (default: flywheel)
  --operation NAME          Operation to evaluate (default: policy.validate)
  --mode MODE               warn_only|shadow|enforce override for decision output
  --dry-run                 Default; policy source is never mutated
  --apply                   Requires --idempotency-key; no source mutation occurs
  --idempotency-key KEY     Required for --apply
  --reason TOPIC            Explanation topic for why
  --json                    Emit compact JSON
  --info | --examples | --schema
"""


def main(argv: list[str]) -> int:
    args, unknown = build_parser().parse_known_args(argv)
    if unknown:
        return emit(base_payload({"status": "fail", "reason_code": "unknown_args", "args": unknown}), True, 2)
    if args.help:
        print(usage())
        return 0
    if args.info or args.command == "info":
        return emit(command_info(), args.json, 0)
    if args.examples or args.command == "examples":
        return emit(command_examples(), args.json, 0)
    if args.schema or args.command == "schema":
        return emit(command_schema(), args.json, 0)
    if args.command == "quickstart":
        return emit(command_examples(), args.json, 0)
    if args.command == "completion":
        return completion(args.reason_arg or "bash")
    if args.apply and not args.idempotency_key and args.command != "repair":
        return emit(
            base_payload(
                {
                    "status": "fail",
                    "reason_code": "missing_idempotency_key",
                    "allowed": False,
                    "would_block": True,
                    "source_policy_mutated": False,
                }
            ),
            args.json,
            2,
        )
    if args.command in {"doctor", "health"}:
        payload, rc = command_doctor(args)
        if args.command == "health":
            payload["command"] = "health"
        return emit(payload, args.json, rc)
    if args.command == "repair":
        payload, rc = command_repair(args)
        return emit(payload, args.json, rc)
    if args.command == "audit":
        payload, rc = command_audit(args)
        return emit(payload, args.json, rc)
    if args.command in {"validate", "decision"}:
        path = Path(args.policy).resolve()
        try:
            policy, _ = load_valid_policy(path)
        except PolicyError as err:
            return emit(malformed_payload(path, err), args.json, 3)
        payload, rc = decision_payload(policy, args)
        return emit(payload, args.json, rc)
    if args.command == "why":
        return emit(command_why(args.reason_arg or args.reason), args.json, 0)
    return emit(base_payload({"status": "fail", "reason_code": "unknown_command", "command": args.command}), args.json, 2)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[2:]))
PY
