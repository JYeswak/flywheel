#!/usr/bin/env bash
set -euo pipefail

VERSION="agentmail-identity-canonical-validator.v1.0.0"
SCHEMA_VERSION="agentmail-identity-canonical-validator.v1"
TOPOLOGY="${AICV_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
IDENTITY_TOKENS="${AICV_IDENTITY_TOKENS:-$HOME/.local/state/flywheel/identity-tokens.jsonl}"
TOKEN_DIR="${AICV_TOKEN_DIR:-${FLYWHEEL_FLEET_MAIL_TOKEN_VAULT:-$HOME/.local/state/flywheel/fleet-mail-tokens}}"
JSON_OUT=0
QUIET=0
APPLY=0
STRICT=0
MODE="check"

usage() { printf '%s\n' 'usage: agentmail-identity-canonical-validator.sh [--json] [--quiet] [--apply] [--strict] [--topology PATH] [--identity-tokens PATH] [--token-dir DIR]' 'Exit codes: 0=canonical/advisory, 1=strict drift, 2=malformed-state, 3=read-error.'; }

examples() {
  cat <<'EOF'
agentmail-identity-canonical-validator.sh --json
agentmail-identity-canonical-validator.sh --strict --json
agentmail-identity-canonical-validator.sh --topology /tmp/topology.jsonl --token-dir /tmp/tokens --strict --json
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --apply) APPLY=1; shift ;;
    --strict|--enforce) STRICT=1; shift ;;
    --topology) TOPOLOGY="${2:?--topology requires PATH}"; shift 2 ;;
    --identity-tokens) IDENTITY_TOKENS="${2:?--identity-tokens requires PATH}"; shift 2 ;;
    --token-dir) TOKEN_DIR="${2:?--token-dir requires DIR}"; shift 2 ;;
    --info) MODE="info"; shift ;;
    --examples) MODE="examples"; shift ;;
    --help|-h) MODE="help"; shift ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ "$MODE" == "help" ]]; then usage; exit 0; fi
if [[ "$MODE" == "examples" ]]; then examples; exit 0; fi
if [[ "$MODE" == "info" ]]; then
  jq -nc --arg version "$VERSION" --arg schema "$SCHEMA_VERSION" \
    '{name:"agentmail-identity-canonical-validator",version:$version,schema_version:$schema,read_only:true,canonical_cli:["--info","--help","--examples","--json","--quiet","--apply"],exit_codes:{"0":"canonical or live advisory report","1":"strict drift detected","2":"malformed-state","3":"read-error"},strict_flag:"--strict",identity_primary_key:"session:pane:fleet_mail_project_key"}'
  exit 0
fi

set +e
payload="$(
  python3 - "$TOPOLOGY" "$IDENTITY_TOKENS" "$TOKEN_DIR" "$APPLY" "$STRICT" "$VERSION" "$SCHEMA_VERSION" <<'PY'
import json
import re
import sys
from pathlib import Path

topology_path, identity_path, token_dir_raw, apply_raw, strict_raw, version, schema = sys.argv[1:]
token_dir = Path(token_dir_raw).expanduser()
apply = apply_raw == "1"
strict = strict_raw == "1"

def read_jsonl(path_raw, required=True):
    path = Path(path_raw).expanduser()
    if not path.exists():
        if required:
            raise FileNotFoundError(str(path))
        return [], str(path)
    rows = []
    for idx, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError as exc:
            raise ValueError(f"{path}:{idx}: {exc}") from exc
        if isinstance(row, dict):
            rows.append(row)
    return rows, str(path)

def latest_by_session(rows):
    latest = {}
    for row in rows:
        session = row.get("session")
        if not session:
            continue
        prev = latest.get(session)
        if prev is None or str(row.get("effective_at") or "") >= str(prev.get("effective_at") or ""):
            latest[session] = row
    return latest

def active_topology(row):
    status = str(row.get("session_status") or "")
    if "metadata_only" in status or "out_of_fleet" in status:
        return False
    return row.get("orchestrator_pane") is not None or bool(row.get("worker_panes") or [])

def identity_of(row):
    return row.get("fleet_mail_identity") or row.get("agent_mail_identity") or ""

def primary_key(row):
    pk = row.get("identity_primary_key") if isinstance(row.get("identity_primary_key"), dict) else {}
    return (
        str(pk.get("session") or row.get("session") or ""),
        str(pk.get("pane") if pk.get("pane") is not None else row.get("pane") if row.get("pane") is not None else ""),
        str(pk.get("fleet_mail_project_key") or row.get("fleet_mail_project_key") or row.get("project") or ""),
    )

def add(drifts, dtype, enforced, **fields):
    row = {"type": dtype, "enforced": bool(enforced)}
    row.update(fields)
    drifts.append(row)

try:
    topology_rows, topology_file = read_jsonl(topology_path)
    identity_rows, identity_file = read_jsonl(identity_path, required=False)
    if not token_dir.exists() or not token_dir.is_dir():
        raise FileNotFoundError(str(token_dir))
    token_names = {p.name[:-6] for p in token_dir.glob("*.token") if p.is_file()}
except FileNotFoundError as exc:
    print(json.dumps({"success": False, "status": "read_error", "read_error": str(exc), "schema_version": schema}))
    raise SystemExit(3)
except ValueError as exc:
    print(json.dumps({"success": False, "status": "malformed_state", "error": str(exc), "schema_version": schema}))
    raise SystemExit(2)

drifts = []
latest = latest_by_session(topology_rows)
active_rows = [r for r in latest.values() if active_topology(r)]
declared = {}
for row in active_rows:
    session = str(row.get("session") or "")
    identity = identity_of(row)
    if not identity:
        add(drifts, "missing_fleet_mail_identity", strict, session=session)
        continue
    declared.setdefault(identity, []).append(session)
    if identity not in token_names:
        add(drifts, "missing_token", strict, session=session, identity=identity, expected_token=f"{identity}.token")

for identity, sessions in declared.items():
    if len(set(sessions)) > 1:
        add(drifts, "duplicate_identity", True, identity=identity, sessions=sorted(set(sessions)))

for token in sorted(token_names - set(declared)):
    add(drifts, "orphan_token", strict, identity=token)

current_by_key = {}
bad_event = re.compile(r"overwrite|mutation|non_append|status_overwrite", re.I)
for row in identity_rows:
    event_text = " ".join(str(row.get(k) or "") for k in ("event", "action", "status", "update_kind"))
    if bad_event.search(event_text):
        add(drifts, "non_append_only", True, identity=row.get("identity") or row.get("identity_name"), event=event_text.strip())
    status = str(row.get("status") or "active")
    if status in {"inactive", "archived", "superseded", "retired"}:
        continue
    key = primary_key(row)
    identity = row.get("identity") or row.get("identity_name")
    if key != ("", "", "") and identity:
        current_by_key.setdefault(key, set()).add(str(identity))

for key, identities in current_by_key.items():
    if len(identities) > 1:
        add(drifts, "non_append_only", True, primary_key=":".join(key), identities=sorted(identities))

enforced = [d for d in drifts if d["enforced"]]
success = not enforced
result = {
    "schema_version": schema,
    "version": version,
    "success": success,
    "status": "canonical" if success and not drifts else ("advisory_drift" if success else "drift"),
    "strict": strict,
    "apply": apply,
    "read_only": True,
    "read_only_verified": True,
    "topology_path": topology_file,
    "identity_tokens_path": identity_file,
    "token_dir": str(token_dir),
    "sessions_checked": len(active_rows),
    "declared_identity_count": len(declared),
    "token_count": len(token_names),
    "drift_count": len(drifts),
    "enforced_drift_count": len(enforced),
    "drift_types": sorted({d["type"] for d in drifts}),
    "drifts": drifts,
}
print(json.dumps(result, separators=(",", ":")))
raise SystemExit(0 if success else 1)
PY
)"
rc=$?
set -e

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$payload"
elif [[ "$QUIET" -eq 0 ]]; then
  printf '%s\n' "$payload" | jq -r '"agentmail_identity status=\(.status) success=\(.success) drift_count=\(.drift_count // 0) enforced=\(.enforced_drift_count // 0)"'
fi
exit "$rc"
