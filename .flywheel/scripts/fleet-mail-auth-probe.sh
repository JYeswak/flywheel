#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
import argparse
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

VERSION = "fleet-mail-auth-probe/v1"
DEFAULT_PROJECT_KEY = "/Users/josh/.local/state/flywheel/fleet-mail-project"
DEFAULT_STATE_DIR = Path.home() / ".local/state/flywheel"
DEFAULT_AGENT_MAIL_DIR = DEFAULT_STATE_DIR / "agent-mail"
DEFAULT_TOKEN_VAULT = DEFAULT_STATE_DIR / "fleet-mail-tokens"
DEFAULT_TOPOLOGY = DEFAULT_STATE_DIR / "session-topology.jsonl"


def emit(payload, pretty=False):
    if pretty:
        print(json.dumps(payload, indent=2, sort_keys=True))
    else:
        print(json.dumps(payload, separators=(",", ":"), sort_keys=True))


def load_json(path):
    try:
        with Path(path).expanduser().open(encoding="utf-8") as f:
            data = json.load(f)
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def load_jsonl(path):
    rows = []
    path = Path(path).expanduser()
    if not path.exists():
        return rows
    try:
        lines = path.read_text(encoding="utf-8", errors="ignore").splitlines()
    except Exception:
        return rows
    for line_no, line in enumerate(lines, 1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        if isinstance(row, dict):
            row["__line"] = line_no
            rows.append(row)
    return rows


def latest_topology_identity(topology_path, session):
    rows = [r for r in load_jsonl(topology_path) if r.get("session") == session]
    if not rows:
        return None, None
    latest = sorted(rows, key=lambda r: str(r.get("effective_at") or r.get("ts") or ""))[-1]
    return latest.get("fleet_mail_identity") or latest.get("agent_mail_identity"), latest


def registry_rows(agent_mail_dir, session):
    session_dir = Path(agent_mail_dir).expanduser() / "sessions"
    if not session_dir.exists():
        return []
    rows = []
    for path in sorted(session_dir.glob(f"{session}:*.json")):
        row = load_json(path)
        if not row:
            continue
        row["_path"] = str(path)
        rows.append(row)
    return rows


def choose_registry_row(agent_mail_dir, session, pane):
    rows = registry_rows(agent_mail_dir, session)
    if pane is not None:
        for row in rows:
            if str(row.get("pane")) == str(pane):
                return row
        return {}
    active = [r for r in rows if r.get("status") == "active" and r.get("identity_name")]
    if active:
        return active[0]
    return rows[0] if rows else {}


def token_candidates(identity, row, agent_mail_dir, token_vault):
    candidates = []
    if row.get("token_path"):
        candidates.append(Path(str(row["token_path"])).expanduser())
    if identity:
        candidates.append(Path(token_vault).expanduser() / f"{identity}.token")
        candidates.append(Path(agent_mail_dir).expanduser() / "tokens" / f"{identity}.token")
    seen = set()
    unique = []
    for candidate in candidates:
        text = str(candidate)
        if text not in seen:
            seen.add(text)
            unique.append(candidate)
    return unique


def token_sha(path):
    h = hashlib.sha256()
    with Path(path).open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def truthy(value):
    if isinstance(value, bool):
        return value
    if value is None:
        return False
    return str(value).strip().lower() in {"1", "true", "yes", "ok", "pass", "authenticated"}


def base_payload(args, identity=None, identity_source="missing", token_path=None, token_hash=None):
    return {
        "schema_version": VERSION,
        "status": "fail",
        "ready": False,
        "project_key": args.project_key,
        "session": args.session,
        "pane": args.pane,
        "identity_name": identity,
        "identity_source": identity_source,
        "token_path": str(token_path) if token_path else None,
        "token_sha256": token_hash,
        "token_value_redacted": True,
        "fleet_mail_identity_invalid_or_missing": False,
        "failure_classes": [],
        "l61_gate": {
            "would_count_as_success": False,
            "requires_authenticated_agent_mail": True,
        },
        "l61": {
            "agent_mail_attempted": False,
            "agent_mail_from": identity,
            "agent_mail_to": None,
            "agent_mail_message_id": None,
            "agent_mail_sent_at": None,
            "degraded_reason": None,
            "fleet_mail_identity_source": identity_source,
            "l61_pairing_status": "degraded",
            "ntm_attempted": False,
            "ntm_pane": None,
            "ntm_result": None,
            "ntm_sent_at": None,
            "ntm_session": None,
            "project_key": args.project_key,
            "vault_token_validated": False,
        },
    }


def fail_payload(args, code, reason, identity=None, identity_source="missing", token_path=None, token_hash=None, attempted=False):
    payload = base_payload(args, identity, identity_source, token_path, token_hash)
    payload["status"] = "fail"
    payload["code"] = code
    payload["reason"] = reason
    payload["failure_classes"] = [code]
    payload["l61"]["agent_mail_attempted"] = bool(attempted)
    payload["l61"]["degraded_reason"] = code
    if code == "fleet_mail_identity_invalid_or_missing":
        payload["fleet_mail_identity_invalid_or_missing"] = True
    return payload


def run_mcp_probe(command, project_key, identity, token_path, token_hash, timeout):
    if not command:
        return 75, {"code": "agent_mail_mcp_unavailable", "reason": "no_mcp_probe_command"}
    env = os.environ.copy()
    env.update({
        "FLEET_MAIL_AUTH_PROJECT_KEY": project_key,
        "FLEET_MAIL_AUTH_IDENTITY": identity,
        "FLEET_MAIL_AUTH_TOKEN_PATH": str(token_path),
        "FLEET_MAIL_AUTH_TOKEN_SHA256": token_hash,
    })
    try:
        proc = subprocess.run(
            [command],
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=False,
        )
    except FileNotFoundError:
        return 75, {"code": "agent_mail_mcp_unavailable", "reason": "mcp_probe_command_missing"}
    except subprocess.TimeoutExpired:
        return 75, {"code": "agent_mail_mcp_unavailable", "reason": "mcp_probe_timeout"}

    text = (proc.stdout or "").strip()
    data = {}
    if text:
        try:
            parsed = json.loads(text)
            if isinstance(parsed, dict):
                data = parsed
        except Exception:
            data = {"raw_status": "non_json_probe_output"}
    if proc.returncode != 0 and not data.get("code"):
        data["code"] = "agent_mail_mcp_unavailable"
    return proc.returncode, data


def info(args):
    return {
        "schema_version": "fleet-mail-auth-probe/info/v1",
        "name": "fleet-mail-auth-probe.sh",
        "version": VERSION,
        "read_only": True,
        "mutation_default": "none",
        "project_key_default": DEFAULT_PROJECT_KEY,
        "canonical_cli_surfaces": ["--info", "--schema", "--doctor", "--health", "--validate", "--audit", "--why", "--repair", "--json", "--help"],
        "mcp_probe_contract": {
            "env": ["FLEET_MAIL_AUTH_PROJECT_KEY", "FLEET_MAIL_AUTH_IDENTITY", "FLEET_MAIL_AUTH_TOKEN_PATH", "FLEET_MAIL_AUTH_TOKEN_SHA256"],
            "valid_when": "exit 0 and authenticated=true or status=ok",
            "invalid_token_when": "code=invalid_token or exit 2",
        },
    }


def schema(args):
    return {
        "schema_version": "fleet-mail-auth-probe/schema/v1",
        "required": ["schema_version", "status", "ready", "project_key", "identity_name", "l61_gate", "l61", "failure_classes"],
        "failure_classes": [
            "fleet_mail_identity_invalid_or_missing",
            "fleet_mail_token_missing",
            "fleet_mail_token_invalid",
            "agent_mail_mcp_unavailable",
        ],
        "fixed_project_key": DEFAULT_PROJECT_KEY,
        "secret_policy": "token values never emitted; token_path and token_sha256 only",
    }


def check_surface(args, mode):
    fixture_rows = load_jsonl(args.fixtures)
    fixture_cases = sorted({str(r.get("case")) for r in fixture_rows if r.get("case")})
    status = "ok" if {"valid", "invalid_token", "missing_token", "missing_identity", "mcp_unavailable"}.issubset(set(fixture_cases)) else "warn"
    return {
        "schema_version": f"fleet-mail-auth-probe/{mode}/v1",
        "mode": mode,
        "status": status,
        "read_only": True,
        "project_key": args.project_key,
        "fixtures": str(Path(args.fixtures)),
        "fixture_cases": fixture_cases,
        "mutation_default": "none",
    }


def why(args):
    return {
        "schema_version": "fleet-mail-auth-probe/why/v1",
        "status": "ok",
        "reason": "L61 alerting requires authenticated Agent Mail truth, not token-file presence. Failures degrade the L61 gate and cannot count as success.",
        "failure_class": "fleet_mail_identity_invalid_or_missing",
    }


def repair(args):
    return {
        "schema_version": "fleet-mail-auth-probe/repair/v1",
        "status": "refused",
        "read_only": True,
        "reason": "Cannot repair: Agent Mail identity/token registration is credential-shaped and must use identity registration workflows, not this read-only probe.",
        "dry_run": True,
        "apply": False,
    }


def probe(args):
    if not args.session and not args.identity:
        return fail_payload(args, "fleet_mail_identity_invalid_or_missing", "--session or --identity required")

    row = choose_registry_row(args.agent_mail_dir, args.session, args.pane) if args.session else {}
    topo_identity, topo_row = latest_topology_identity(args.topology, args.session) if args.session else (None, None)
    identity = args.identity or row.get("identity_name") or topo_identity
    identity_source = "explicit" if args.identity else ("registry" if row.get("identity_name") else ("topology" if topo_identity else "missing"))

    if not identity or (row and row.get("status") not in (None, "active")):
        return fail_payload(args, "fleet_mail_identity_invalid_or_missing", "missing active fleet_mail_identity", identity, identity_source)

    token_path = None
    for candidate in token_candidates(identity, row, args.agent_mail_dir, args.token_vault):
        if candidate.exists() and candidate.is_file():
            token_path = candidate
            break
    if token_path is None:
        return fail_payload(args, "fleet_mail_token_missing", "missing token file for fleet_mail_identity", identity, identity_source)

    token_hash = token_sha(token_path)
    rc, result = run_mcp_probe(args.mcp_probe, args.project_key, identity, token_path, token_hash, args.timeout)
    code = str(result.get("code") or result.get("status") or "").lower()
    authenticated = truthy(result.get("authenticated")) or str(result.get("status") or "").lower() in {"ok", "pass", "authenticated"}
    if rc == 0 and authenticated:
        payload = base_payload(args, identity, identity_source, token_path, token_hash)
        payload.update({
            "status": "pass",
            "ready": True,
            "code": "ok",
            "reason": "authenticated_identity_valid",
        })
        payload["l61_gate"]["would_count_as_success"] = True
        payload["l61"]["agent_mail_attempted"] = True
        payload["l61"]["l61_pairing_status"] = "authenticated"
        payload["l61"]["degraded_reason"] = None
        payload["l61"]["vault_token_validated"] = True
        payload["agent_mail_probe"] = {
            "authenticated": True,
            "probe_status": result.get("status") or "ok",
            "message_id": result.get("message_id"),
        }
        return payload

    if rc == 2 or code in {"invalid_token", "unauthorized", "auth_failed"}:
        return fail_payload(args, "fleet_mail_token_invalid", "MCP rejected fleet mail token", identity, identity_source, token_path, token_hash, attempted=True)
    return fail_payload(args, "agent_mail_mcp_unavailable", "MCP authenticated probe unavailable", identity, identity_source, token_path, token_hash, attempted=True)


def parse_args(argv):
    p = argparse.ArgumentParser(description="Read-only authenticated Agent Mail gate for fleet-coherence L61.")
    p.add_argument("--session", default=os.environ.get("FLEET_MAIL_AUTH_SESSION"))
    p.add_argument("--pane", type=int, default=os.environ.get("FLEET_MAIL_AUTH_PANE"))
    p.add_argument("--identity", default=os.environ.get("FLEET_MAIL_AUTH_IDENTITY_OVERRIDE"))
    p.add_argument("--project-key", default=os.environ.get("FLEET_MAIL_AUTH_PROJECT_KEY", DEFAULT_PROJECT_KEY))
    p.add_argument("--agent-mail-dir", default=os.environ.get("FLYWHEEL_AGENT_MAIL_STATE_DIR", str(DEFAULT_AGENT_MAIL_DIR)))
    p.add_argument("--token-vault", default=os.environ.get("FLYWHEEL_FLEET_MAIL_TOKEN_VAULT", str(DEFAULT_TOKEN_VAULT)))
    p.add_argument("--topology", default=os.environ.get("FLYWHEEL_SESSION_TOPOLOGY", str(DEFAULT_TOPOLOGY)))
    p.add_argument("--fixtures", default=os.environ.get("FLEET_MAIL_AUTH_PROBE_FIXTURES", ".flywheel/fixtures/fleet-mail-auth-probe.jsonl"))
    p.add_argument("--mcp-probe", default=os.environ.get("FLEET_MAIL_AUTH_MCP_PROBE_COMMAND"))
    p.add_argument("--timeout", type=float, default=float(os.environ.get("FLEET_MAIL_AUTH_TIMEOUT", "5")))
    p.add_argument("--json", action="store_true")
    p.add_argument("--pretty", action="store_true")
    p.add_argument("--info", action="store_true")
    p.add_argument("--schema", action="store_true")
    p.add_argument("--doctor", action="store_true")
    p.add_argument("--health", action="store_true")
    p.add_argument("--validate", action="store_true")
    p.add_argument("--audit", action="store_true")
    p.add_argument("--why", action="store_true")
    p.add_argument("--repair", action="store_true")
    return p.parse_args(argv)


def main(argv):
    args = parse_args(argv)
    if args.info:
        payload, rc = info(args), 0
    elif args.schema:
        payload, rc = schema(args), 0
    elif args.doctor:
        payload = check_surface(args, "doctor"); rc = 0 if payload["status"] == "ok" else 1
    elif args.health:
        payload = check_surface(args, "health"); rc = 0 if payload["status"] == "ok" else 1
    elif args.validate:
        payload = check_surface(args, "validate"); rc = 0 if payload["status"] == "ok" else 1
    elif args.audit:
        payload = check_surface(args, "audit"); rc = 0 if payload["status"] == "ok" else 1
    elif args.why:
        payload, rc = why(args), 0
    elif args.repair:
        payload, rc = repair(args), 1
    else:
        payload = probe(args)
        rc = 0 if payload.get("ready") else 1
    emit(payload, pretty=args.pretty and not args.json)
    return rc


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
