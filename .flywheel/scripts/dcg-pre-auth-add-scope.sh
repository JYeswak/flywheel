#!/usr/bin/env bash
set -euo pipefail

SCOPES_FILE="${DCG_PRE_AUTH_SCOPES_FILE:-$HOME/.flywheel/dcg-pre-authorized-scopes.json}"
PATTERN=""
RATIONALE=""
AUTO_APPROVE=""
REQUIRES_CONTEXT=""
SCOPE_ID=""
APPLY=0
JSON_OUTPUT=0

usage() {
  cat <<'EOF'
Usage: dcg-pre-auth-add-scope.sh --pattern REGEX --rationale TEXT --auto-approve always|with_orch_attestation [--requires-context TEXT] [--id ID] [--scopes-file PATH] [--apply] [--json]
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --pattern)
      PATTERN="${2:-}"
      shift 2
      ;;
    --rationale)
      RATIONALE="${2:-}"
      shift 2
      ;;
    --auto-approve)
      AUTO_APPROVE="${2:-}"
      shift 2
      ;;
    --requires-context)
      REQUIRES_CONTEXT="${2:-}"
      shift 2
      ;;
    --id)
      SCOPE_ID="${2:-}"
      shift 2
      ;;
    --scopes-file)
      SCOPES_FILE="${2:-}"
      shift 2
      ;;
    --apply)
      APPLY=1
      shift
      ;;
    --json)
      JSON_OUTPUT=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
done

if [ -z "$PATTERN" ] || [ -z "$RATIONALE" ] || [ -z "$AUTO_APPROVE" ]; then
  usage >&2
  exit 2
fi

PATTERN="$PATTERN" \
RATIONALE="$RATIONALE" \
AUTO_APPROVE="$AUTO_APPROVE" \
REQUIRES_CONTEXT="$REQUIRES_CONTEXT" \
SCOPE_ID="$SCOPE_ID" \
SCOPES_FILE="$SCOPES_FILE" \
APPLY="$APPLY" \
JSON_OUTPUT="$JSON_OUTPUT" \
python3 <<'PY'
import hashlib
import json
import os
import re
import sys

SCHEMA = "dcg-pre-authorized-scopes/v1"
ALLOWED_AUTO = {"always", "with_orch_attestation"}


def fail(message, code=2):
    print(message, file=sys.stderr)
    sys.exit(code)


pattern = os.environ["PATTERN"]
rationale = os.environ["RATIONALE"]
auto_approve = os.environ["AUTO_APPROVE"]
requires_context = os.environ["REQUIRES_CONTEXT"]
scope_id = os.environ["SCOPE_ID"]
scopes_file = os.environ["SCOPES_FILE"]
apply_change = os.environ["APPLY"] == "1"
json_output = os.environ["JSON_OUTPUT"] == "1"

if auto_approve not in ALLOWED_AUTO:
    fail("auto-approve must be always or with_orch_attestation")
try:
    re.compile(pattern)
except re.error as exc:
    fail(f"invalid regex: {exc}")

if not scope_id:
    scope_id = "scope-" + hashlib.sha256(pattern.encode("utf-8")).hexdigest()[:12]

new_scope = {
    "id": scope_id,
    "command_pattern": pattern,
    "rationale": rationale,
    "auto_approve": auto_approve,
    "audit_log": True,
}
if requires_context:
    new_scope["requires_context"] = requires_context

if os.path.exists(scopes_file):
    try:
        with open(scopes_file, "r", encoding="utf-8") as handle:
            data = json.load(handle)
    except json.JSONDecodeError as exc:
        fail(f"invalid scopes JSON: {exc}")
else:
    data = {"schema_version": SCHEMA, "scopes": []}

if data.get("schema_version") != SCHEMA or not isinstance(data.get("scopes"), list):
    fail("unsupported scopes schema")

for scope in data["scopes"]:
    if not isinstance(scope, dict):
        fail("malformed scope entry")
    for required in ("id", "command_pattern", "rationale", "auto_approve"):
        if not scope.get(required):
            fail(f"malformed scope entry: missing {required}")
    if scope["auto_approve"] not in ALLOWED_AUTO:
        fail("malformed scope entry: invalid auto_approve")
    try:
        re.compile(scope["command_pattern"])
    except re.error as exc:
        fail(f"malformed scope entry regex: {exc}")

updated = False
for index, scope in enumerate(data["scopes"]):
    if scope.get("id") == scope_id or scope.get("command_pattern") == pattern:
        data["scopes"][index] = new_scope
        updated = True
        break
if not updated:
    data["scopes"].append(new_scope)

if apply_change:
    os.makedirs(os.path.dirname(scopes_file), exist_ok=True)
    tmp_path = scopes_file + ".tmp"
    with open(tmp_path, "w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2)
        handle.write("\n")
    os.replace(tmp_path, scopes_file)

result = {
    "applied": apply_change,
    "scope_id": scope_id,
    "scope_count": len(data["scopes"]),
    "scopes_file": scopes_file,
}
if json_output:
    print(json.dumps(result, separators=(",", ":")))
else:
    print(f"{'applied' if apply_change else 'planned'} {scope_id} scopes={len(data['scopes'])}")
PY
