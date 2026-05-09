#!/usr/bin/env bash
set -euo pipefail

VERSION="capacity-halt-pane-authorization.v1.0.0"
TOPOLOGY="${CAPACITY_HALT_AUTH_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
NOW_EPOCH="${CAPACITY_HALT_AUTH_NOW_EPOCH:-}"
MAX_AGE_SECONDS="${CAPACITY_HALT_AUTH_MAX_AGE_SECONDS:-3600}"

python3 - "$VERSION" "$TOPOLOGY" "$NOW_EPOCH" "$MAX_AGE_SECONDS" "$@" <<'PY'
import argparse, json, os, re, sys, time
from datetime import datetime, timezone
from pathlib import Path

VERSION, TOPOLOGY, NOW_RAW, MAX_AGE_RAW = sys.argv[1:5]
PANE_RE = re.compile(r"^[0-9]+$")
CREDENTIAL_ROTATION_CLASS = "credential_rotation"
CREDENTIAL_ROTATION_TOOL = "codex"
CREDENTIAL_ROTATION_PRIMITIVE = "caam-auto-rotate-on-usage-limit"
CREDENTIAL_ROTATION_DEFAULT_OPERATION = "caam_activate_existing_profile"
CREDENTIAL_ROTATION_AUTHORIZED_OPS = [
    "caam_activate_existing_profile",
    "caam_status_post_check",
    "append_recovery_ledger",
]
CREDENTIAL_ROTATION_FORBIDDEN_OPS = [
    "pane_mutation",
    "respawn",
    "launchctl",
    "new_credential_creation",
    "token_rotation",
    "oauth_refresh",
    "vault_write",
]

def parse_args():
    p = argparse.ArgumentParser(description="Authorize capacity-halt auto-continue for worker panes only.")
    p.add_argument("--info", action="store_true")
    p.add_argument("--examples", action="store_true")
    p.add_argument("--json", action="store_true")
    p.add_argument("--session", default="")
    p.add_argument("--pane", default="")
    p.add_argument("--tool", default="")
    p.add_argument("--recovery-class", default="")
    p.add_argument("--primitive", default=CREDENTIAL_ROTATION_PRIMITIVE)
    p.add_argument("--operation", default=CREDENTIAL_ROTATION_DEFAULT_OPERATION)
    p.add_argument("--quiet", action="store_true")
    return p.parse_args(sys.argv[5:])

def now_epoch():
    return int(NOW_RAW or time.time())

def parse_ts(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00")).timestamp()
    except ValueError:
        return None

def emit(args, payload, rc):
    if args.json:
        print(json.dumps(payload, sort_keys=True))
    elif not args.quiet:
        print(f"capacity-halt-pane-authorization status={payload.get('status')} session={payload.get('session', '')} pane={payload.get('pane', '')} role={payload.get('role', '')}")
    raise SystemExit(rc)

def read_rows(path):
    rows = []
    for idx, line in enumerate(Path(path).read_text().splitlines(), start=1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError as exc:
            raise ValueError(f"malformed_jsonl_line_{idx}:{exc}") from exc
        if isinstance(row, dict):
            rows.append(row)
    return rows

def latest_for_session(rows, session):
    candidates = [r for r in rows if str(r.get("session")) == session]
    if not candidates:
        return None
    return max(candidates, key=lambda r: str(r.get("effective_at") or r.get("ts") or ""))

def role_for_pane(row, pane):
    if str(row.get("orchestrator_pane")) == pane:
        return "orchestrator_pane"
    if str(row.get("human_pane")) == pane:
        return "human_pane"
    if str(row.get("callback_pane")) == pane:
        return "callback_pane"
    if pane in {str(p) for p in (row.get("worker_panes") or [])}:
        return "worker_pane"
    return "unknown"

def base(args, row=None, age=None):
    source_ts = (row or {}).get("effective_at") or (row or {}).get("ts")
    return {
        "schema_version": "capacity-halt-pane-authorization.result.v1",
        "version": VERSION,
        "session": args.session,
        "pane": args.pane,
        "topology_file": TOPOLOGY,
        "topology_source_ts": source_ts,
        "topology_age_sec": age,
        "read_only": True,
    }

def with_ledger(payload):
    payload["ledger_row"] = {
        "event": "capacity_halt_authorization",
        "session": payload.get("session"),
        "pane": int(payload["pane"]) if str(payload.get("pane", "")).isdigit() else payload.get("pane"),
        "authorized": payload.get("authorized"),
        "pane_role": payload.get("role"),
        "authorization_outcome": payload.get("authorization_outcome"),
        "topology_source_ts": payload.get("topology_source_ts"),
        "refusal_reason": payload.get("refusal_reason"),
    }
    return payload

def credential_rotation_fields(args, stale_allowed):
    return {
        "tool": args.tool,
        "recovery_class": args.recovery_class,
        "primitive": args.primitive,
        "operation": args.operation,
        "stale_topology_allowed": bool(stale_allowed),
        "authorized_operations": CREDENTIAL_ROTATION_AUTHORIZED_OPS,
        "forbidden_operations": CREDENTIAL_ROTATION_FORBIDDEN_OPS,
        "credential_secret_values_observed": 0,
    }

def credential_rotation_refusal(args, row=None, age=None, role="unknown", status="malformed", rc=3, reason="unsupported_credential_rotation_request", stale_allowed=False):
    return with_ledger(dict(
        base(args, row, age),
        status=status,
        role=role,
        authorized=False,
        authorization_outcome=status,
        refusal_reason=reason,
        **credential_rotation_fields(args, stale_allowed),
    )), rc

def validate_credential_rotation(args, row=None, age=None, role="unknown", stale_allowed=False):
    if args.recovery_class != CREDENTIAL_ROTATION_CLASS:
        return None
    if args.tool != CREDENTIAL_ROTATION_TOOL:
        return credential_rotation_refusal(args, row, age, role, reason="unsupported_tool_for_credential_rotation", stale_allowed=stale_allowed)
    if args.primitive != CREDENTIAL_ROTATION_PRIMITIVE:
        return credential_rotation_refusal(args, row, age, role, reason="unsupported_credential_rotation_primitive", stale_allowed=stale_allowed)
    if args.operation in CREDENTIAL_ROTATION_FORBIDDEN_OPS:
        return credential_rotation_refusal(args, row, age, role, status="protected_refusal", rc=5, reason="forbidden_operation", stale_allowed=stale_allowed)
    if args.operation not in CREDENTIAL_ROTATION_AUTHORIZED_OPS:
        return credential_rotation_refusal(args, row, age, role, reason="unsupported_credential_rotation_operation", stale_allowed=stale_allowed)
    return None

def credential_rotation_authorized(args, row, age, role, stale_allowed):
    return with_ledger(dict(
        base(args, row, age),
        status="authorized",
        role=role,
        authorized=True,
        authorization_outcome="authorized",
        refusal_reason=None,
        **credential_rotation_fields(args, stale_allowed),
    ))

def info(args):
    emit(args, {
        "schema_version": "capacity-halt-pane-authorization.info.v1",
        "name": "capacity-halt-pane-authorization",
        "version": VERSION,
        "topology_file": TOPOLOGY,
        "max_age_seconds": int(MAX_AGE_RAW),
        "verbs": ["--info", "--help", "--examples", "--json", "--session", "--pane", "--tool", "--recovery-class", "--primitive", "--operation", "--quiet"],
        "credential_rotation": {
            "tool": CREDENTIAL_ROTATION_TOOL,
            "recovery_class": CREDENTIAL_ROTATION_CLASS,
            "primitive": CREDENTIAL_ROTATION_PRIMITIVE,
            "authorized_operations": CREDENTIAL_ROTATION_AUTHORIZED_OPS,
            "forbidden_operations": CREDENTIAL_ROTATION_FORBIDDEN_OPS,
        },
        "exit_codes": {"0": "authorized-worker-pane", "3": "malformed", "5": "protected-refusal", "6": "unknown-pane", "7": "topology-stale"},
    }, 0)

def examples(args):
    emit(args, {
        "schema_version": "capacity-halt-pane-authorization.examples.v1",
        "examples": [
            {"name": "worker", "command": "capacity-halt-pane-authorization.sh --session flywheel --pane 3 --json"},
            {"name": "quiet", "command": "capacity-halt-pane-authorization.sh --session flywheel --pane 1 --quiet"},
            {"name": "credential_rotation", "command": "capacity-halt-pane-authorization.sh --session flywheel --pane 2 --tool codex --recovery-class credential_rotation --json"},
        ],
    }, 0)

def main():
    args = parse_args()
    if args.info:
        info(args)
    if args.examples:
        examples(args)
    if not args.session or not PANE_RE.match(args.pane):
        emit(args, dict(base(args), status="malformed", role="unknown", authorized=False, authorization_outcome="malformed", refusal_reason="session_and_numeric_pane_required"), 3)
    try:
        rows = read_rows(TOPOLOGY)
    except (OSError, ValueError) as exc:
        emit(args, dict(base(args), status="malformed", role="unknown", authorized=False, authorization_outcome="malformed", refusal_reason=str(exc)), 3)
    row = latest_for_session(rows, args.session)
    if row is None:
        emit(args, with_ledger(dict(base(args), status="unknown_pane", role="unknown", authorized=False, authorization_outcome="unknown_pane", refusal_reason="unknown_pane")), 6)
    source_ts = row.get("effective_at") or row.get("ts")
    source_epoch = parse_ts(source_ts)
    if source_epoch is None:
        emit(args, with_ledger(dict(base(args, row), status="malformed", role="unknown", authorized=False, authorization_outcome="malformed", refusal_reason="missing_or_invalid_effective_at")), 3)
    age = max(0, now_epoch() - int(source_epoch))
    role = role_for_pane(row, args.pane)
    if age > int(MAX_AGE_RAW):
        if args.recovery_class == CREDENTIAL_ROTATION_CLASS:
            invalid = validate_credential_rotation(args, row, age, role, stale_allowed=True)
            if invalid:
                payload, rc = invalid
                emit(args, payload, rc)
            if role == "worker_pane":
                emit(args, credential_rotation_authorized(args, row, age, role, stale_allowed=True), 0)
            if role == "unknown":
                emit(args, with_ledger(dict(base(args, row, age), status="unknown_pane", role=role, authorized=False, authorization_outcome="unknown_pane", refusal_reason="unknown_pane", **credential_rotation_fields(args, True))), 6)
            emit(args, with_ledger(dict(base(args, row, age), status="protected_refusal", role=role, authorized=False, authorization_outcome="protected_refusal", refusal_reason="protected", **credential_rotation_fields(args, True))), 5)
        emit(args, with_ledger(dict(base(args, row, age), status="topology_stale", role="unknown", authorized=False, authorization_outcome="topology_stale", refusal_reason="topology_stale")), 7)
    if args.recovery_class == CREDENTIAL_ROTATION_CLASS:
        invalid = validate_credential_rotation(args, row, age, role, stale_allowed=False)
        if invalid:
            payload, rc = invalid
            emit(args, payload, rc)
        if role == "worker_pane":
            emit(args, credential_rotation_authorized(args, row, age, role, stale_allowed=False), 0)
        if role == "unknown":
            emit(args, with_ledger(dict(base(args, row, age), status="unknown_pane", role=role, authorized=False, authorization_outcome="unknown_pane", refusal_reason="unknown_pane", **credential_rotation_fields(args, False))), 6)
        emit(args, with_ledger(dict(base(args, row, age), status="protected_refusal", role=role, authorized=False, authorization_outcome="protected_refusal", refusal_reason="protected", **credential_rotation_fields(args, False))), 5)
    if role == "worker_pane":
        emit(args, with_ledger(dict(base(args, row, age), status="authorized", role=role, authorized=True, authorization_outcome="authorized", refusal_reason=None)), 0)
    if role == "unknown":
        emit(args, with_ledger(dict(base(args, row, age), status="unknown_pane", role=role, authorized=False, authorization_outcome="unknown_pane", refusal_reason="unknown_pane")), 6)
    emit(args, with_ledger(dict(base(args, row, age), status="protected_refusal", role=role, authorized=False, authorization_outcome="protected_refusal", refusal_reason="protected")), 5)

if __name__ == "__main__":
    main()
PY
