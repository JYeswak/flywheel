#!/usr/bin/env python3
# canonical-cli-scoping-allow-large: flywheel-35zx keeps close-gate override semantics colocated for one dogfood pass; split if this surface grows again.
from __future__ import annotations

import json
import os
import re
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

SURFACE = "Tick Close Permit Gate"
VERSION = "tick-close-receipt/v1"
OVERRIDE_VERSION = "wire-or-explain-override-receipt/v1"
DEFAULT_REPO = "/Users/josh/Developer/flywheel"
DEFAULT_LEDGER = "$HOME/.local/state/flywheel/wire-or-explain-ledger.jsonl"
DEFAULT_RECEIPTS = "$HOME/.local/state/flywheel/wire-or-explain/closeout-receipts"
DEFAULT_OVERRIDE_RECEIPTS = "$HOME/.local/state/flywheel/wire-or-explain/override-receipts"
UNRESOLVED_STATES = {"unwired", "questionably_wired"}
EXIT_CODES = {
    "0": "close allowed",
    "1": "enforce mode found unresolved local rows",
    "2": "usage or schema error",
    "3": "ledger parse/read error",
    "4": "fleet-scoped row is owned by this orchestrator",
}

class GateError(ValueError):
    def __init__(self, reason_code: str, message: str, exit_code: int = 2) -> None:
        super().__init__(message)
        self.reason_code = reason_code
        self.exit_code = exit_code

@dataclass
class OverrideContext:
    reason: str
    owner: str
    expires_at: str
    affected_rows: list[str]
    source: str
    receipt_path: str | None = None
    bootstrap: bool = False
    bootstrap_proof: str | None = None
    consumed_at: str | None = None

def usage() -> str:
    return """usage:
  wire-or-explain-close-gate.py [--repo PATH] [--ledger PATH] [--mode shadow|enforce|bootstrap] [--override PATH] [--json] [--dry-run]
  wire-or-explain-close-gate.py --schema
  wire-or-explain-close-gate.py doctor|health|validate|audit|repair [--json] [--dry-run]
  wire-or-explain-close-gate.py why [ID] [--json]
  wire-or-explain-close-gate.py --why [ID] [--json]
  wire-or-explain-close-gate.py --info|--examples|quickstart [--json]
  wire-or-explain-close-gate.py completion bash|zsh

Stable exit codes: 0 allowed, 1 enforce unresolved local rows, 2 usage/schema,
3 ledger parse/read failure, 4 fleet-scoped local ownership block.
"""

def schema() -> dict[str, Any]:
    path = Path(__file__).resolve().parents[2] / ".flywheel/validation-schema/v1/tick-close-receipt.schema.json"
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    return {"title": "Tick Close Permit Gate Receipt", "schema_version": VERSION}

def emit(data: Any, as_json: bool = True) -> int:
    if as_json:
        print(json.dumps(data, sort_keys=True, indent=2))
    else:
        print(data if isinstance(data, str) else json.dumps(data, sort_keys=True))
    return int(data.get("exit_code", 0)) if isinstance(data, dict) and data.get("command") == "run" else 0

def expand_path(value: str) -> Path:
    return Path(os.path.expandvars(os.path.expanduser(value)))

def parse_time(value: Any) -> datetime:
    if not isinstance(value, str) or not value:
        return datetime.fromtimestamp(0, tz=timezone.utc)
    try:
        dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return datetime.fromtimestamp(0, tz=timezone.utc)
    return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)

def now_dt(value: str | None) -> datetime:
    return parse_time(value) if value else datetime.now(timezone.utc)

def num(value: Any) -> float:
    if isinstance(value, bool):
        return 0.0
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        try:
            return float(value)
        except ValueError:
            return 0.0
    return 0.0

def scrub_text(value: Any) -> Any:
    if not isinstance(value, str):
        return value
    patterns = [
        (r"gh[pousr]_[A-Za-z0-9_]{16,}", "[SCRUBBED:github_token]"),
        (r"sk-(?:proj-)?[A-Za-z0-9_-]{20,}", "[SCRUBBED:openai_key]"),
        (r"AKIA[0-9A-Z]{16}", "[SCRUBBED:aws_key_id]"),
        (r"(Bearer\s+)[A-Za-z0-9._~+/=-]{16,}", r"\1[SCRUBBED:bearer_token]"),
        (r"eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}", "[SCRUBBED:jwt]"),
    ]
    scrubbed = value
    for pattern, replacement in patterns:
        scrubbed = re.sub(pattern, replacement, scrubbed)
    return scrubbed

def scrub(value: Any) -> Any:
    if isinstance(value, dict):
        return {str(k): scrub(v) for k, v in value.items()}
    if isinstance(value, list):
        return [scrub(item) for item in value]
    return scrub_text(value)

def row_identity(row: dict[str, Any]) -> str:
    return str(row.get("identity_key") or row.get("row_id") or row.get("subject") or "unknown")

def nested(row: dict[str, Any], key: str) -> Any:
    for container in (row, row.get("metadata"), row.get("payload")):
        if isinstance(container, dict) and key in container:
            return container[key]
    return None

def real_text(path_text: Any) -> str:
    if not isinstance(path_text, str) or not path_text:
        return ""
    return os.path.realpath(os.path.expanduser(path_text))

def owns_local(row: dict[str, Any], repo: Path, session: str) -> bool:
    repo_real = os.path.realpath(str(repo))
    owning = str(row.get("owning_orch") or "")
    return (
        real_text(row.get("ship_repo")) == repo_real
        or str(row.get("session_id") or "") == session
        or owning.startswith(f"{session}:")
        or owning.startswith(f"{session}:pane-")
    )

def route(row: dict[str, Any]) -> dict[str, str]:
    artifact = str(row.get("artifact_class") or "other")
    consumer = str(row.get("consumer") or "NONE")
    if artifact == "skill_candidate":
        return {"target": scrub_text("skillos" if consumer in {"", "NONE", "none"} else consumer), "kind": "skill_candidate", "action": "route_to_skillos"}
    if consumer in {"", "NONE", "none"}:
        return {"target": scrub_text(str(row.get("owner") or "flywheel:1")), "kind": "owner_triage", "action": "assign_consumer_or_defer"}
    return {"target": scrub_text(consumer), "kind": scrub_text(artifact), "action": "drain_consumer"}

def safe_action(row: dict[str, Any], repo: Path, session: str, now: datetime) -> dict[str, Any]:
    created = parse_time(row.get("timestamp"))
    downstream = num(nested(row, "downstream_cost")) + num(nested(row, "ship_cost")) + num(nested(row, "dependency_count")) * 4
    local = owns_local(row, repo, session)
    scope = str(row.get("blocking_scope") or "none")
    row_route = route(row)
    next_action = "route_skill_candidate_rows_to_skillos_or_record_deferral" if row_route["action"] == "route_to_skillos" else row_route["action"]
    return {
        "identity_key": scrub_text(row_identity(row)),
        "state": scrub_text(row.get("state") or "unknown"),
        "artifact_class": scrub_text(row.get("artifact_class") or "other"),
        "subject": scrub_text(row.get("subject")),
        "predicate": scrub_text(row.get("predicate")),
        "blocking_scope": scope,
        "owning_orch": scrub_text(row.get("owning_orch")),
        "ship_repo": scrub_text(row.get("ship_repo")),
        "locality": "local" if local else "cross_orch",
        "owner": scrub_text(row.get("owner")),
        "consumer": scrub_text(row.get("consumer")),
        "timestamp": scrub_text(row.get("timestamp")),
        "age_hours": round(max(0.0, (now - created).total_seconds() / 3600), 3),
        "downstream_cost": downstream,
        "route": row_route,
        "next_action": next_action,
        "verification_probe": scrub_text(row.get("verification_probe")),
        "tick_status_consequence": scrub_text(row.get("tick_status_consequence")),
    }

def action_key(action: dict[str, Any]) -> tuple[Any, ...]:
    scope_weight = {"fleet": 0, "tick": 1, "mission": 2, "skill_triage": 3, "local": 4}.get(str(action.get("blocking_scope")), 5)
    locality = 0 if action.get("locality") == "local" else 1
    return (locality, scope_weight, -float(action.get("downstream_cost") or 0), -float(action.get("age_hours") or 0), action["identity_key"])

def read_rows(path: Path) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    if not path.exists():
        return [], [{"code": "ledger_missing", "message": f"ledger not found: {path}"}]
    rows: list[dict[str, Any]] = []
    try:
        with path.open("r", encoding="utf-8") as fh:
            for line_no, line in enumerate(fh, start=1):
                text = line.strip()
                if not text:
                    continue
                value = json.loads(text)
                if not isinstance(value, dict):
                    raise GateError("ledger_row_not_object", f"row {line_no} is not an object", 3)
                rows.append(value)
    except json.JSONDecodeError as exc:
        raise GateError("ledger_parse_failed", f"invalid JSONL: {exc}", 3) from exc
    except OSError as exc:
        raise GateError("ledger_read_failed", str(exc), 3) from exc
    return rows, [{"code": "ledger_empty", "message": f"ledger has no rows: {path}"}] if not rows else []

def mode_for(repo: Path, explicit: str | None) -> str:
    candidates = [
        explicit,
        os.environ.get("FLYWHEEL_WIRE_OR_EXPLAIN_CLOSE_MODE"),
        os.environ.get("FLYWHEEL_WIRE_OR_EXPLAIN_MODE"),
    ]
    mode_file = repo / ".flywheel/wire-or-explain/mode"
    if mode_file.exists():
        candidates.append(mode_file.read_text(encoding="utf-8").strip())
    for value in candidates:
        if value in {"bootstrap", "shadow", "enforce"}:
            return value
    return "shadow"

def override_state() -> dict[str, Any]:
    legacy = os.environ.get("FLYWHEEL_WIRE_OR_EXPLAIN_CLOSE_OVERRIDE") or os.environ.get("JOSHUA_OVERRIDE")
    return {
        "active": False,
        "source": "none",
        "valid": False,
        "reason": None,
        "owner": None,
        "expires_at": None,
        "affected_rows": [],
        "receipt_path": None,
        "bootstrap": False,
        "legacy_env_present": bool(legacy),
    }

def override_receipt_dir(opts: dict[str, Any]) -> Path:
    return expand_path(opts.get("override_receipt_dir") or os.environ.get("FLYWHEEL_WIRE_OR_EXPLAIN_OVERRIDE_RECEIPT_DIR", DEFAULT_OVERRIDE_RECEIPTS))

def load_override(opts: dict[str, Any]) -> tuple[OverrideContext | None, list[dict[str, Any]], Path | None]:
    path_text = opts.get("override") or os.environ.get("FLYWHEEL_WIRE_OR_EXPLAIN_CLOSE_OVERRIDE_FILE")
    if not path_text:
        return None, [], None
    path = expand_path(path_text)
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except OSError as exc:
        return None, [{"code": "override_read_failed", "message": str(exc)}], path
    except json.JSONDecodeError as exc:
        return None, [{"code": "override_parse_failed", "message": str(exc)}], path
    if not isinstance(payload, dict):
        return None, [{"code": "override_not_object", "message": "override payload must be a JSON object"}], path

    affected = payload.get("affected_rows")
    if not isinstance(affected, list):
        affected_rows: list[str] = []
    else:
        affected_rows = [str(item) for item in affected if str(item)]
    reason = str(payload.get("reason") or payload.get("rotation_reason") or "")
    owner = str(payload.get("owner") or payload.get("issuer") or "")
    context = OverrideContext(
        reason=reason,
        owner=owner,
        expires_at=str(payload.get("expires_at") or ""),
        affected_rows=affected_rows,
        source=str(path),
        receipt_path=payload.get("receipt_path") if isinstance(payload.get("receipt_path"), str) else None,
        bootstrap=bool(payload.get("bootstrap")),
        bootstrap_proof=payload.get("bootstrap_proof") if isinstance(payload.get("bootstrap_proof"), str) else None,
        consumed_at=payload.get("consumed_at") if isinstance(payload.get("consumed_at"), str) else None,
    )
    if payload.get("bootstrap_consumed") is True and not context.consumed_at:
        context.consumed_at = "true"
    return context, [], path

def override_validation(
    context: OverrideContext | None,
    local_actions: list[dict[str, Any]],
    mode: str,
    now: datetime,
    read_warnings: list[dict[str, Any]],
) -> tuple[dict[str, Any], list[dict[str, Any]], list[dict[str, Any]]]:
    state = override_state()
    warnings = list(read_warnings)
    synthetic_actions: list[dict[str, Any]] = []
    if context is None:
        if read_warnings:
            synthetic_actions.append(override_action("override_unreadable", "override receipt could not be read", None, now))
        return state, warnings, synthetic_actions

    local_ids = [str(action["identity_key"]) for action in local_actions]
    errors = list(read_warnings)
    if not context.reason.strip():
        errors.append({"code": "override_missing_reason", "message": "override reason is required"})
    if not context.owner.strip():
        errors.append({"code": "override_missing_owner", "message": "override owner is required"})
    if not context.expires_at.strip():
        errors.append({"code": "override_missing_expires_at", "message": "override expires_at is required"})
    if not context.affected_rows:
        errors.append({"code": "override_missing_affected_rows", "message": "override affected_rows is required"})
    expires = parse_time(context.expires_at)
    if context.expires_at and expires <= now:
        errors.append({"code": "override_expired", "message": "override expires_at is not in the future"})
    if local_ids and not set(local_ids).issubset(set(context.affected_rows)):
        errors.append({"code": "override_affected_rows_incomplete", "message": "override affected_rows must cover every local unresolved row"})
    if mode == "bootstrap" or context.bootstrap:
        if not context.bootstrap:
            errors.append({"code": "bootstrap_override_required", "message": "bootstrap mode requires bootstrap=true"})
        if not (context.bootstrap_proof or "").strip():
            errors.append({"code": "bootstrap_proof_missing", "message": "bootstrap override requires B8 dogfood self-test proof"})
        if context.consumed_at:
            errors.append({"code": "bootstrap_override_consumed", "message": "bootstrap override is one-shot and already consumed"})

    active = not errors and bool(local_actions)
    state.update({
        "active": active,
        "source": "file",
        "valid": not errors,
        "reason": scrub_text(context.reason) or None,
        "owner": scrub_text(context.owner) or None,
        "expires_at": context.expires_at or None,
        "affected_rows": scrub(context.affected_rows),
        "receipt_path": context.receipt_path,
        "bootstrap": context.bootstrap,
        "errors": [error["code"] for error in errors],
    })
    warnings.extend(errors)
    for error in errors:
        synthetic_actions.append(override_action(error["code"], error["message"], context, now))
    return state, warnings, synthetic_actions

def override_action(code: str, message: str, context: OverrideContext | None, now: datetime) -> dict[str, Any]:
    owner = context.owner if context and context.owner else "flywheel:1"
    return {
        "identity_key": f"override:{code}",
        "state": "unwired",
        "artifact_class": "override_receipt",
        "subject": code,
        "predicate": scrub_text(message),
        "blocking_scope": "local",
        "owning_orch": "flywheel:pane-1",
        "ship_repo": DEFAULT_REPO,
        "locality": "local",
        "owner": scrub_text(owner),
        "consumer": "flywheel:1",
        "timestamp": now.isoformat().replace("+00:00", "Z"),
        "age_hours": 0,
        "downstream_cost": 0,
        "route": {"target": "flywheel:1", "kind": "override_receipt", "action": "refresh_override_or_drain_rows"},
        "next_action": "refresh_override_or_drain_rows",
        "verification_probe": "wire-or-explain-close-gate.py --why --json",
        "tick_status_consequence": "override rejected; unresolved local rows still block close",
    }

def receipt_dir(opts: dict[str, Any]) -> Path:
    return expand_path(opts.get("receipt_dir") or os.environ.get("FLYWHEEL_WIRE_OR_EXPLAIN_CLOSE_RECEIPT_DIR", DEFAULT_RECEIPTS))

def write_receipt(result: dict[str, Any], opts: dict[str, Any]) -> dict[str, Any]:
    if opts["dry_run"]:
        result["receipt_path"] = None
        result["receipt_written"] = False
        return result
    out_dir = receipt_dir(opts)
    out_dir.mkdir(parents=True, exist_ok=True)
    stamp = result["generated_at"].replace("-", "").replace(":", "").replace("+00:00", "Z")
    path = out_dir / f"{stamp}.json"
    result["receipt_path"] = str(path)
    result["receipt_written"] = True
    path.write_text(json.dumps(result, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    return result

def write_override_receipt(result: dict[str, Any], opts: dict[str, Any], context: OverrideContext | None, local_actions: list[dict[str, Any]]) -> None:
    if opts["dry_run"] or context is None or not result["override_state"].get("active"):
        return
    out_dir = override_receipt_dir(opts)
    out_dir.mkdir(parents=True, exist_ok=True)
    stamp = result["generated_at"].replace("-", "").replace(":", "").replace("+00:00", "Z")
    path = out_dir / f"{stamp}-override.json"
    row_decisions = {
        str(action["identity_key"]): {
            "decision": "overridden",
            "route": action.get("route"),
            "next_action": action.get("next_action"),
        }
        for action in local_actions
    }
    receipt = scrub({
        "schema_version": OVERRIDE_VERSION,
        "surface": SURFACE,
        "issued_at": result["generated_at"],
        "mode": result["mode"],
        "owner": context.owner,
        "reason": context.reason,
        "expires_at": context.expires_at,
        "affected_rows": context.affected_rows,
        "row_decisions": row_decisions,
        "bootstrap": context.bootstrap,
        "bootstrap_consumed": context.bootstrap,
        "bootstrap_proof": context.bootstrap_proof if context.bootstrap else None,
        "raw_evidence_included": False,
        "secret_scrubbed": True,
        "source": context.source,
    })
    path.write_text(json.dumps(receipt, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    result["override_state"]["receipt_path"] = str(path)

def evaluate(opts: dict[str, Any]) -> dict[str, Any]:
    repo = expand_path(opts["repo"]).resolve()
    ledger = expand_path(opts["ledger"])
    mode = mode_for(repo, opts.get("mode"))
    now = now_dt(opts.get("now"))
    rows, warnings = read_rows(ledger)
    unresolved = [row for row in rows if row.get("state") in UNRESOLVED_STATES]
    actions = [safe_action(row, repo, opts["session"], now) for row in unresolved]
    actions.sort(key=action_key)
    local_unresolved = [row for row in unresolved if owns_local(row, repo, opts["session"])]
    cross_unresolved = [row for row in unresolved if not owns_local(row, repo, opts["session"])]
    local_actions = [safe_action(row, repo, opts["session"], now) for row in local_unresolved]
    local_actions.sort(key=action_key)
    fleet_owned = [row for row in local_unresolved if str(row.get("blocking_scope") or "") == "fleet"]
    skill_candidates = [row for row in unresolved if str(row.get("artifact_class") or "") == "skill_candidate"]
    would_block = bool(local_unresolved)
    allowed = True
    reason = "green"
    exit_code = 0
    context, override_warnings, _override_path = load_override(opts)
    state, override_warnings, override_actions = override_validation(context, local_actions, mode, now, override_warnings)
    if override_actions:
        actions.extend(override_actions)
        actions.sort(key=action_key)
    if would_block and mode == "shadow":
        reason = "shadow_unresolved_local_rows"
    elif would_block and mode == "enforce":
        allowed = False
        reason = "fleet_owned_unresolved_rows" if fleet_owned else "unresolved_local_rows"
        exit_code = 4 if fleet_owned else 1
    elif would_block:
        reason = "bootstrap_unresolved_local_rows"
    if would_block and state["active"] and mode in {"enforce", "bootstrap"}:
        allowed = True
        exit_code = 0
        reason = "bootstrap_override_active" if mode == "bootstrap" or state.get("bootstrap") else "override_active"
    elif would_block and state.get("errors") and mode in {"enforce", "bootstrap"}:
        allowed = False
        exit_code = 4 if fleet_owned else 1
        reason = str(state["errors"][0])
    if cross_unresolved:
        warnings.append({"code": "cross_orch_unresolved_rows", "count": len(cross_unresolved), "message": "cross-orchestrator rows are visible but outside local ownership"})
    warnings.extend(override_warnings)
    generated = now.isoformat().replace("+00:00", "Z")
    result = {
        "schema_version": VERSION,
        "surface": SURFACE,
        "command": "run",
        "generated_at": generated,
        "repo": str(repo),
        "ledger_path": str(ledger),
        "mode": mode,
        "allowed": allowed,
        "exit_code": exit_code,
        "reason_code": reason,
        "row_count": len(rows),
        "unresolved_count": len(unresolved),
        "local_unresolved_count": len(local_unresolved),
        "cross_orch_unresolved_count": len(cross_unresolved),
        "skill_candidate_count": len(skill_candidates),
        "top_actions": actions[: opts["limit"]],
        "override_state": state,
        "receipt_path": None,
        "would_block": would_block,
        "dry_run": opts["dry_run"],
        "verification_probe_command": opts.get("verification_probe_command"),
        "warnings": warnings,
        "exit_codes": EXIT_CODES,
    }
    write_override_receipt(result, opts, context, local_actions)
    return write_receipt(result, opts)

def parse(argv: list[str]) -> dict[str, Any]:
    opts: dict[str, Any] = {
        "command": "run",
        "repo": DEFAULT_REPO,
        "ledger": os.environ.get("FLYWHEEL_WIRE_OR_EXPLAIN_LEDGER") or os.environ.get("WIRE_OR_EXPLAIN_LEDGER") or DEFAULT_LEDGER,
        "receipt_dir": None,
        "override_receipt_dir": None,
        "override": None,
        "mode": None,
        "json": False,
        "dry_run": False,
        "explain": False,
        "limit": 5,
        "now": None,
        "session": "flywheel",
        "verification_probe_command": None,
        "id": None,
        "completion_shell": "bash",
        "idempotency_key": None,
    }
    commands = {"run", "doctor", "health", "validate", "audit", "repair", "why", "schema", "quickstart", "help", "completion"}
    value_opts = {"--repo", "--ledger", "--receipt-dir", "--override-receipt-dir", "--override", "--mode", "--limit", "--now", "--session", "--verification-probe-command", "--idempotency-key", "--scope", "--width", "--tick-id"}
    i = 0
    while i < len(argv):
        arg = argv[i]
        if arg in commands:
            opts["command"] = "schema" if arg == "schema" else arg
            if arg in {"why", "completion", "help"} and i + 1 < len(argv) and not argv[i + 1].startswith("-"):
                opts["id" if arg in {"why", "help"} else "completion_shell"] = argv[i + 1]
                i += 1
        elif arg == "--schema":
            opts["command"] = "schema"
        elif arg == "--info":
            opts["command"] = "info"
        elif arg == "--examples":
            opts["command"] = "examples"
        elif arg == "--why":
            opts["command"] = "why"
            if i + 1 < len(argv) and not argv[i + 1].startswith("-"):
                opts["id"] = argv[i + 1]
                i += 1
        elif arg in {"--help", "-h"}:
            opts["command"] = "help"
        elif arg == "--json":
            opts["json"] = True
        elif arg == "--dry-run":
            opts["dry_run"] = True
        elif arg == "--explain":
            opts["explain"] = True
        elif arg in {"--apply", "--no-color", "--no-emoji"}:
            pass
        elif arg in value_opts:
            i += 1
            if i >= len(argv):
                raise GateError("usage_error", f"{arg} requires a value")
            key = arg[2:].replace("-", "_")
            if key in opts:
                opts[key] = int(argv[i]) if key == "limit" else argv[i]
        elif any(arg.startswith(opt + "=") for opt in value_opts):
            key, value = arg[2:].split("=", 1)
            key = key.replace("-", "_")
            if key in opts:
                opts[key] = int(value) if key == "limit" else value
        else:
            raise GateError("usage_error", f"unknown argument: {arg}")
        i += 1
    return opts

def info() -> dict[str, Any]:
    return {"command": "info", "surface": SURFACE, "schema_version": VERSION, "override_schema_version": OVERRIDE_VERSION, "exit_codes": EXIT_CODES, "default_mode": "shadow", "mutation_requires": "non-dry-run receipt write only"}

def examples() -> dict[str, Any]:
    items = [("green dry-run", "wire-or-explain-close-gate.py --json --dry-run"), ("shadow", "FLYWHEEL_WIRE_OR_EXPLAIN_CLOSE_MODE=shadow wire-or-explain-close-gate.py --json"), ("enforce", "wire-or-explain-close-gate.py --mode enforce --json"), ("override", "wire-or-explain-close-gate.py --mode enforce --override override.json --json"), ("schema", "wire-or-explain-close-gate.py --schema"), ("why", "wire-or-explain-close-gate.py --why --json")]
    return {"command": "examples", "examples": [{"name": name, "command": command} for name, command in items]}

def quickstart() -> dict[str, Any]:
    steps = ["run --schema", "run --json --dry-run", "inspect top_actions", "switch to --mode enforce", "use --override only with reason/owner/expires_at/affected_rows", "preserve the receipt_path in closeout"]
    return {"command": "quickstart", "surface": SURFACE, "steps": steps}

def completion(shell: str) -> str:
    if shell == "zsh":
        return "compadd run doctor health validate audit repair why schema quickstart completion --json --dry-run --mode --ledger --repo --override --override-receipt-dir --why\n"
    return "complete -W 'run doctor health validate audit repair why schema quickstart completion --json --dry-run --mode --ledger --repo --override --override-receipt-dir --why' wire-or-explain-close-gate.py\n"

def why_payload(result: dict[str, Any], wanted: str | None) -> dict[str, Any]:
    rows = {
        str(action["identity_key"]): {
            "decision": "would_block" if action.get("locality") == "local" else "visible_cross_orch",
            "state": action.get("state"),
            "artifact_class": action.get("artifact_class"),
            "route": action.get("route"),
            "next_action": action.get("next_action"),
            "blocking_scope": action.get("blocking_scope"),
            "locality": action.get("locality"),
        }
        for action in result["top_actions"]
    }
    if result["override_state"].get("active"):
        for row_id in result["override_state"].get("affected_rows", []):
            rows.setdefault(str(row_id), {}).update({"decision": "overridden", "override_owner": result["override_state"].get("owner")})
    found = rows.get(wanted) if wanted else None
    return {
        "schema_version": VERSION,
        "surface": SURFACE,
        "command": "why",
        "generated_at": result["generated_at"],
        "mode": result["mode"],
        "decision": {
            "allowed": result["allowed"],
            "exit_code": result["exit_code"],
            "reason_code": result["reason_code"],
            "would_block": result["would_block"],
        },
        "rows": rows,
        "found": found,
        "override_state": result["override_state"],
        "warnings": result["warnings"],
    }

def main(argv: list[str]) -> int:
    try:
        opts = parse(argv)
        cmd = opts["command"]
        if cmd == "schema":
            return emit(schema(), True)
        if cmd == "help":
            print(usage())
            return 0
        if cmd == "info":
            return emit(info(), opts["json"])
        if cmd == "examples":
            return emit(examples(), opts["json"])
        if cmd == "quickstart":
            return emit(quickstart(), opts["json"])
        if cmd == "completion":
            print(completion(str(opts["completion_shell"])), end="")
            return 0
        if cmd == "why":
            result = evaluate({**opts, "dry_run": True})
            wanted = opts.get("id")
            return emit(why_payload(result, wanted), True)
        if cmd in {"doctor", "health", "validate", "audit", "repair", "run"}:
            result = evaluate(opts)
            result["command"] = "run" if cmd in {"run", "doctor", "validate"} else cmd
            if cmd == "repair":
                result["planned_actions"] = ["drain listed top_actions", "write closeout receipt when not dry-run"]
            return_code = int(result["exit_code"])
            emit(result, opts["json"] or cmd != "run")
            return return_code
        raise GateError("usage_error", f"unsupported command: {cmd}")
    except GateError as exc:
        payload = {"schema_version": VERSION, "surface": SURFACE, "allowed": False, "exit_code": exc.exit_code, "reason_code": exc.reason_code, "message": str(exc), "row_count": 0, "top_actions": [], "override_state": override_state(), "receipt_path": None, "would_block": True}
        print(json.dumps(payload, sort_keys=True, indent=2), file=sys.stdout)
        return exc.exit_code


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
