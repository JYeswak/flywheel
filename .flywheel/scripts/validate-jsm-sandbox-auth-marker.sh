#!/usr/bin/env bash
set -euo pipefail

VERSION="jsm-sandbox-auth-marker.v1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
SCHEMA_PATH="$REPO_ROOT/.flywheel/doctrine/jsm-sandbox-auth-marker.v1.json"
MARKER_PATH="${JSM_SANDBOX_AUTH_MARKER_PATH:-/Users/josh/.local/state/jsm/sandbox-auth-ok.json}"
SECRET_PATH="${JSM_SANDBOX_AUTH_SECRET_PATH:-/Users/josh/.local/state/jsm/marker-hmac-secret}"
FRESHNESS_SECONDS="${JSM_SANDBOX_AUTH_FRESHNESS_SECONDS:-86400}"
JSON_OUT=0
DOCTOR=0
SCHEMA=0

usage() {
  cat <<'EOF'
usage:
  validate-jsm-sandbox-auth-marker.sh [--path PATH] [--secret-path PATH] [--json]
  validate-jsm-sandbox-auth-marker.sh --doctor [--json]
  validate-jsm-sandbox-auth-marker.sh --schema [--json]

Exit codes:
  0 valid
  1 invalid schema, proof artifact, or timestamp shape
  2 marker file missing
  3 HMAC secret missing or HMAC mismatch
  4 expired or stale marker
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path)
      [[ -n "${2:-}" ]] || { echo "ERR: --path requires PATH" >&2; exit 2; }
      MARKER_PATH="$2"
      shift 2
      ;;
    --secret-path)
      [[ -n "${2:-}" ]] || { echo "ERR: --secret-path requires PATH" >&2; exit 2; }
      SECRET_PATH="$2"
      shift 2
      ;;
    --json)
      JSON_OUT=1
      shift
      ;;
    --doctor)
      DOCTOR=1
      shift
      ;;
    --schema)
      SCHEMA=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "ERR: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "$SCHEMA" -eq 1 ]]; then
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -c . "$SCHEMA_PATH"
  else
    cat "$SCHEMA_PATH"
  fi
  exit 0
fi

set +e
result="$(
  python3 - "$MARKER_PATH" "$SECRET_PATH" "$SCHEMA_PATH" "$FRESHNESS_SECONDS" "$DOCTOR" <<'PY'
import datetime as dt
import hashlib
import hmac
import json
import re
import sys
from pathlib import Path

marker_path = Path(sys.argv[1]).expanduser()
secret_path = Path(sys.argv[2]).expanduser()
schema_path = Path(sys.argv[3]).expanduser()
freshness_seconds = int(sys.argv[4])
doctor = sys.argv[5] == "1"

required = {
    "ts": str,
    "writer": str,
    "writer_session": str,
    "writer_pane": int,
    "what_was_proven": str,
    "proof_artifact_sha256": str,
    "proof_artifact_path": str,
    "expiry_ts": str,
    "schema_version": str,
    "hmac_sha256": str,
}
hex64 = re.compile(r"^[0-9a-f]{64}$")

def parse_ts(value):
    if not isinstance(value, str):
        raise ValueError("not_string")
    text = value
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    parsed = dt.datetime.fromisoformat(text)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=dt.timezone.utc)
    return parsed.astimezone(dt.timezone.utc)

def emit(payload, rc):
    print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    raise SystemExit(rc)

base = {
    "schema_version": "jsm-sandbox-auth-marker-validator/v1",
    "marker_path": str(marker_path),
    "secret_path": str(secret_path),
    "schema_path": str(schema_path),
    "freshness_seconds": freshness_seconds,
    "marker": None,
}
if doctor:
    base.update({
        "schema_version": "jsm-sandbox-auth-marker-doctor/v1",
        "scope": "jsm-sandbox-auth-marker",
        "reader_contract": "refuse raw live JSM probes unless marker validates",
    })

if not marker_path.is_file():
    payload = {
        **base,
        "valid": False,
        "status": "fail",
        "reasons": ["missing_sandbox_auth_marker"],
        "probe_failure_reasons": {"jsm_sandbox_auth_marker": "missing_sandbox_auth_marker"},
    }
    emit(payload, 1 if doctor else 2)

reasons = []
exit_code = 0
try:
    marker = json.loads(marker_path.read_text(encoding="utf-8"))
except Exception as exc:
    payload = {**base, "valid": False, "status": "fail", "reasons": [f"invalid_json:{type(exc).__name__}"]}
    emit(payload, 1)

base["marker"] = marker
if not isinstance(marker, dict):
    payload = {**base, "valid": False, "status": "fail", "reasons": ["marker_not_object"]}
    emit(payload, 1)

for key, expected_type in required.items():
    if key not in marker:
        reasons.append(f"missing_field:{key}")
        continue
    value = marker[key]
    if expected_type is int:
        if not isinstance(value, int) or isinstance(value, bool):
            reasons.append(f"invalid_type:{key}")
    elif not isinstance(value, expected_type):
        reasons.append(f"invalid_type:{key}")
    elif expected_type is str and value == "":
        reasons.append(f"empty_field:{key}")

allowed = set(required)
for key in marker:
    if key not in allowed:
        reasons.append(f"unexpected_field:{key}")

if marker.get("schema_version") != "v1":
    reasons.append("schema_version_invalid")
if isinstance(marker.get("writer_pane"), int) and not isinstance(marker.get("writer_pane"), bool) and marker["writer_pane"] < 0:
    reasons.append("writer_pane_invalid")
for key in ("proof_artifact_sha256", "hmac_sha256"):
    value = marker.get(key)
    if isinstance(value, str) and not hex64.match(value):
        reasons.append(f"invalid_hex64:{key}")
proof_path_text = marker.get("proof_artifact_path")
if isinstance(proof_path_text, str) and not proof_path_text.startswith("/"):
    reasons.append("proof_artifact_path_not_absolute")

now = dt.datetime.now(dt.timezone.utc)
ts = None
expiry = None
try:
    ts = parse_ts(marker.get("ts"))
except Exception:
    reasons.append("ts_invalid")
try:
    expiry = parse_ts(marker.get("expiry_ts"))
except Exception:
    reasons.append("expiry_ts_invalid")
if ts is not None and now - ts > dt.timedelta(seconds=freshness_seconds):
    reasons.append("stale")
if expiry is not None and expiry <= now:
    reasons.append("expired")

if isinstance(proof_path_text, str) and proof_path_text.startswith("/"):
    proof_path = Path(proof_path_text)
    if not proof_path.is_file():
        reasons.append("proof_artifact_missing")
    else:
        digest = hashlib.sha256(proof_path.read_bytes()).hexdigest()
        if digest != marker.get("proof_artifact_sha256"):
            reasons.append("proof_artifact_sha256_mismatch")

hmac_reason = None
if "hmac_sha256" in marker and isinstance(marker.get("hmac_sha256"), str):
    if not secret_path.is_file():
        hmac_reason = "hmac_secret_missing"
    else:
        secret = secret_path.read_bytes().strip()
        canonical = json.dumps({k: v for k, v in marker.items() if k != "hmac_sha256"}, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
        expected_hmac = hmac.new(secret, canonical, hashlib.sha256).hexdigest()
        if expected_hmac != marker.get("hmac_sha256"):
            hmac_reason = "hmac_mismatch"
if hmac_reason:
    reasons.append(hmac_reason)

valid = not reasons
if valid:
    exit_code = 0
elif any(reason in reasons for reason in ("hmac_secret_missing", "hmac_mismatch")):
    exit_code = 3
elif any(reason in reasons for reason in ("expired", "stale")):
    exit_code = 4
else:
    exit_code = 1

payload = {
    **base,
    "valid": valid,
    "status": "pass" if valid else "fail",
    "reasons": reasons,
}
if not valid:
    payload["probe_failure_reasons"] = {"jsm_sandbox_auth_marker": "missing_sandbox_auth_marker"}
if doctor and not valid:
    exit_code = 1
emit(payload, exit_code)
PY
)"
rc=$?
set -e

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$result"
else
  status="$(jq -r '.status' <<<"$result")"
  reasons="$(jq -r '.reasons | join(",")' <<<"$result")"
  if [[ "$status" == "pass" ]]; then
    printf 'PASS scope=jsm-sandbox-auth-marker marker=%s\n' "$MARKER_PATH"
  else
    printf 'FAIL scope=jsm-sandbox-auth-marker marker=%s reasons=%s\n' "$MARKER_PATH" "$reasons"
  fi
fi

exit "$rc"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
