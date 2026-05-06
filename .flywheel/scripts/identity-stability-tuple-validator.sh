#!/usr/bin/env bash
set -euo pipefail

VERSION="identity-stability-tuple-validator.v1.0.0"
SCHEMA_VERSION="identity-stability-tuple-validator.v1"
IDENTITY_TOKENS="${ISTV_IDENTITY_TOKENS:-$HOME/.local/state/flywheel/identity-tokens.jsonl}"
TOPOLOGY="${ISTV_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
TOKEN_DIR="${ISTV_TOKEN_DIR:-${FLYWHEEL_AGENT_MAIL_TOKEN_DIR:-$HOME/.local/state/flywheel/agent-mail/tokens}}"
JSON_OUT=0; QUIET=0; STRICT=0; TUPLE=""; MODE="check"

usage() { printf '%s\n' 'usage: identity-stability-tuple-validator.sh [--json] [--quiet] [--strict] [--tuple session:pane:project] [--identity-tokens PATH] [--topology PATH] [--token-dir DIR]' 'Exit codes: 0=stable/advisory, 1=strict drift, 2=malformed, 3=read-error.'; }
examples() {
  cat <<'EOF'
identity-stability-tuple-validator.sh --json
identity-stability-tuple-validator.sh --strict --json
identity-stability-tuple-validator.sh --tuple flywheel:3:/Users/josh/Developer/flywheel --json
identity-stability-tuple-validator.sh --identity-tokens /tmp/ids.jsonl --topology /tmp/topology.jsonl --token-dir /tmp/tokens --strict --json
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --strict|--enforce) STRICT=1; shift ;;
    --tuple) TUPLE="${2:?--tuple requires session:pane:project}"; shift 2 ;;
    --identity-tokens) IDENTITY_TOKENS="${2:?--identity-tokens requires PATH}"; shift 2 ;;
    --topology) TOPOLOGY="${2:?--topology requires PATH}"; shift 2 ;;
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
    '{name:"identity-stability-tuple-validator",version:$version,schema_version:$schema,read_only:true,canonical_cli:["--info","--help","--examples","--json","--quiet","--tuple"],exit_codes:{"0":"stable or live advisory report","1":"strict drift detected","2":"malformed state or tuple input","3":"read-error"},identity_primary_key:"session:pane:fleet_mail_project_key",name_semantics:"current_pointer_not_primary_key"}'
  exit 0
fi

set +e
payload="$(
  python3 - "$IDENTITY_TOKENS" "$TOPOLOGY" "$TOKEN_DIR" "$TUPLE" "$STRICT" "$VERSION" "$SCHEMA_VERSION" <<'PY'
import json, sys
from collections import defaultdict
from pathlib import Path

identity_path, topology_path, token_dir_raw, tuple_arg, strict_raw, version, schema = sys.argv[1:]
strict = strict_raw == "1"
allowed_reasons = {"agent-mail-name-policy","resolver-mcp-generated-identity","compaction-continuity","missing-token-recovery","path-canonicalization","strict-mode-preallocation"}

def read_jsonl(path_raw, required=True):
    path = Path(path_raw).expanduser()
    if not path.exists():
        if required: raise FileNotFoundError(str(path))
        return [], str(path)
    rows = []
    for idx, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip(): continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError as exc:
            raise ValueError(f"{path}:{idx}: {exc}") from exc
        if not isinstance(row, dict): raise ValueError(f"{path}:{idx}: row is not object")
        rows.append(row)
    return rows, str(path)
def row_key(row):
    pk = row.get("identity_primary_key") if isinstance(row.get("identity_primary_key"), dict) else {}
    text = row.get("identity_primary_key_text")
    session = pk.get("session") or row.get("session")
    pane = pk.get("pane") if pk.get("pane") is not None else row.get("pane")
    project = pk.get("fleet_mail_project_key") or row.get("fleet_mail_project_key") or row.get("project")
    if (not session or pane is None or not project) and isinstance(text, str):
        parts = text.split(":", 2)
        if len(parts) == 3:
            session, pane, project = parts
    return (str(session or ""), str(pane if pane is not None else ""), str(project or ""))
def identity_of(row): return row.get("identity_name") or row.get("identity") or row.get("agent_name") or ""
def active_row(row): return str(row.get("status") or "active") not in {"inactive", "archived", "superseded", "retired"}
def latest_by_session(rows):
    latest = {}
    for row in rows:
        session = row.get("session")
        if not session: continue
        old = latest.get(session)
        if old is None or str(row.get("effective_at") or "") >= str(old.get("effective_at") or ""):
            latest[session] = row
    return latest
def topology_active(row):
    status = str(row.get("session_status") or "")
    if "metadata_only" in status or "out_of_fleet" in status: return False
    return row.get("orchestrator_pane") is not None or bool(row.get("worker_panes") or [])
def add(drifts, dtype, enforced, **fields):
    item = {"type": dtype, "enforced": bool(enforced)}
    item.update(fields)
    drifts.append(item)
def parse_tuple(raw):
    if not raw: return None
    parts = raw.split(":", 2)
    if len(parts) != 3 or not parts[0] or not parts[1].isdigit() or not parts[2]:
        raise ValueError("--tuple must be session:pane:project")
    return (parts[0], parts[1], parts[2])

try:
    filter_key = parse_tuple(tuple_arg)
    identity_rows, identity_file = read_jsonl(identity_path)
    topology_rows, topology_file = read_jsonl(topology_path, required=False)
    token_dir = Path(token_dir_raw).expanduser()
    if not token_dir.exists() or not token_dir.is_dir():
        raise FileNotFoundError(str(token_dir))
    token_names = {p.name[:-6] for p in token_dir.glob("*.token") if p.is_file()}
except FileNotFoundError as exc:
    print(json.dumps({"success": False, "status": "read_error", "read_error": str(exc), "schema_version": schema}))
    raise SystemExit(3)
except ValueError as exc:
    print(json.dumps({"success": False, "status": "malformed", "error": str(exc), "schema_version": schema}))
    raise SystemExit(2)

rows = [r for r in identity_rows if filter_key is None or row_key(r) == filter_key]
groups = defaultdict(list); drifts = []
for row in rows:
    key = row_key(row)
    if key == ("", "", ""):
        add(drifts, "missing_tuple_key", True, identity=identity_of(row))
    else:
        groups[key].append(row)

current_by_key = {}; rotation_count = 0; max_chain = 0
for key, group in groups.items():
    group.sort(key=lambda r: str(r.get("ts") or r.get("registered_ts") or r.get("effective_at") or ""))
    prev = ""; latest_active = None
    for row in group:
        ident = identity_of(row)
        if ident and prev and ident != prev:
            rotation_count += 1
            chain = row.get("predecessor_identity_chain") if isinstance(row.get("predecessor_identity_chain"), list) else []
            pred = row.get("predecessor_identity") or row.get("previous_identity")
            reason = row.get("rotation_reason")
            if not pred and not chain:
                add(drifts, "missing_predecessor", True, primary_key=":".join(key), identity=ident, previous_identity=prev)
            elif prev not in set([str(pred)] + [str(x) for x in chain]):
                add(drifts, "predecessor_chain_gap", True, primary_key=":".join(key), identity=ident, expected_predecessor=prev)
            if reason and reason not in allowed_reasons:
                add(drifts, "unknown_rotation_reason", strict, primary_key=":".join(key), identity=ident, rotation_reason=reason)
            max_chain = max(max_chain, len(chain))
        if ident: prev = ident
        if active_row(row) and ident: latest_active = row
    if latest_active: current_by_key[key] = identity_of(latest_active)

by_identity = defaultdict(list)
for key, ident in current_by_key.items():
    by_identity[ident].append(":".join(key))
for ident, keys in by_identity.items():
    if len(keys) > 1:
        owners = {":".join(k.split(":", 2)[:2]) for k in keys}
        if len(owners) > 1:
            add(drifts, "duplicate_current_pointer", True, identity=ident, primary_keys=sorted(keys))

topology_current = set()
for row in latest_by_session(topology_rows).values():
    if topology_active(row):
        for field in ("fleet_mail_identity", "agent_mail_identity", "identity_name"):
            if row.get(field): topology_current.add(str(row[field]))

if filter_key is None:
    current_names = set(current_by_key.values()) | topology_current
    for token in sorted(token_names - current_names):
        add(drifts, "orphan_token", strict, identity=token)

enforced = [d for d in drifts if d["enforced"]]; success = not enforced
result = {"schema_version":schema,"version":version,"success":success,"status":"stable" if success and not drifts else ("advisory_drift" if success else "drift"),"strict":strict,"read_only":True,"read_only_verified":True,"identity_tokens_path":identity_file,"topology_path":topology_file,"token_dir":str(token_dir),"tuple_filter":":".join(filter_key) if filter_key else None,"tuples_checked":len(groups),"current_pointer_count":len(current_by_key),"rotation_count":rotation_count,"identity_chain_max_length":max_chain,"drift_count":len(drifts),"enforced_drift_count":len(enforced),"drift_types":sorted({d["type"] for d in drifts}),"drifts":drifts}
print(json.dumps(result, separators=(",", ":")))
raise SystemExit(0 if success else 1)
PY
)"
rc=$?
set -e

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$payload"
elif [[ "$QUIET" -eq 0 ]]; then
  printf '%s\n' "$payload" | jq -r '"identity_tuple status=\(.status) success=\(.success) tuples=\(.tuples_checked // 0) drift_count=\(.drift_count // 0) enforced=\(.enforced_drift_count // 0)"'
fi
exit "$rc"
