#!/usr/bin/env bash
set -euo pipefail

VERSION="canonical-root-drift-fleet-check.v1.0.0"
SCHEMA_VERSION="canonical-root-drift-fleet-check/v1"
SYNC="${CANONICAL_ROOT_DRIFT_SYNC:-/Users/josh/Developer/flywheel/.flywheel/scripts/sync-canonical-doctrine.sh}"
SOURCE="${CANONICAL_ROOT_DRIFT_SOURCE:-/Users/josh/Developer/flywheel/AGENTS.md}"
TIMEOUT_SECONDS="${CANONICAL_ROOT_DRIFT_TIMEOUT_SECONDS:-20}"
JSON_OUT=0
ROOTS=()
MODE="check"

usage() {
  cat <<'EOF'
usage: canonical-root-drift-fleet-check.sh [--json] [--sync PATH] [--source PATH] [--root PATH ...] [--timeout SECONDS]
       canonical-root-drift-fleet-check.sh --info|--examples|--help

Runs a bounded canonical-root-drift verification across flywheel-installed repos.
This intentionally checks the close-relevant canonical-root signal without
running the full flywheel-loop doctor monolith.
EOF
}

examples() {
  cat <<'EOF'
canonical-root-drift-fleet-check.sh --json
canonical-root-drift-fleet-check.sh --root /Users/josh/Developer --timeout 20 --json
CANONICAL_ROOT_DRIFT_SYNC=/tmp/fake-sync.sh canonical-root-drift-fleet-check.sh --timeout 1 --json
EOF
}

info_json() {
  jq -nc \
    --arg version "$VERSION" \
    --arg schema "$SCHEMA_VERSION" \
    --arg sync "$SYNC" \
    --arg source "$SOURCE" \
    '{
      name:"canonical-root-drift-fleet-check.sh",
      version:$version,
      schema_version:$schema,
      sync_helper:$sync,
      canonical_source:$source,
      bounded:true,
      close_relevant_signal:"canonical_root_drift",
      exit_codes:{"0":"no canonical root drift","1":"canonical root drift or helper-reported errors","2":"usage/config error","124":"bounded helper timeout"}
    }'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --sync) SYNC="${2:?}"; shift 2 ;;
    --sync=*) SYNC="${1#*=}"; shift ;;
    --source) SOURCE="${2:?}"; shift 2 ;;
    --source=*) SOURCE="${1#*=}"; shift ;;
    --root) ROOTS+=("${2:?}"); shift 2 ;;
    --root=*) ROOTS+=("${1#*=}"); shift ;;
    --timeout) TIMEOUT_SECONDS="${2:?}"; shift 2 ;;
    --timeout=*) TIMEOUT_SECONDS="${1#*=}"; shift ;;
    --info) MODE="info"; shift ;;
    --examples) MODE="examples"; shift ;;
    -h|--help) MODE="help"; shift ;;
    *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$MODE" in
  info) info_json; exit 0 ;;
  examples) examples; exit 0 ;;
  help) usage; exit 0 ;;
esac

[[ "$TIMEOUT_SECONDS" =~ ^[1-9][0-9]*$ ]] || { printf 'ERR: --timeout must be positive integer\n' >&2; exit 2; }
if [[ ! -x "$SYNC" ]]; then
  payload="$(jq -nc --arg schema "$SCHEMA_VERSION" --arg sync "$SYNC" '{schema_version:$schema,status:"error",classification:"sync_helper_missing",sync_helper:$sync,timed_out:false}')"
  [[ "$JSON_OUT" -eq 1 ]] && printf '%s\n' "$payload" || jq -r '"status=\(.status) classification=\(.classification)"' <<<"$payload"
  exit 2
fi

OUT="$(mktemp "${TMPDIR:-/tmp}/canonical-root-drift-fleet-check.XXXXXX.out")"
ERR="$(mktemp "${TMPDIR:-/tmp}/canonical-root-drift-fleet-check.XXXXXX.err")"
META="$(mktemp "${TMPDIR:-/tmp}/canonical-root-drift-fleet-check.XXXXXX.meta")"
trap 'rm -f "$OUT" "$ERR" "$META"' EXIT

cmd=("$SYNC" --check --json --source "$SOURCE")
for root in "${ROOTS[@]}"; do
  cmd+=(--root "$root")
done

python3 - "$TIMEOUT_SECONDS" "$OUT" "$ERR" "$META" "${cmd[@]}" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

timeout = int(sys.argv[1])
out_path, err_path, meta_path = map(Path, sys.argv[2:5])
cmd = sys.argv[5:]
try:
    proc = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout)
    out_path.write_text(proc.stdout, encoding="utf-8")
    err_path.write_text(proc.stderr, encoding="utf-8")
    meta = {"timed_out": False, "rc": proc.returncode}
except subprocess.TimeoutExpired as exc:
    out_path.write_text(exc.stdout or "", encoding="utf-8")
    err_path.write_text(exc.stderr or "", encoding="utf-8")
    meta = {"timed_out": True, "rc": 124}
meta_path.write_text(json.dumps(meta, separators=(",", ":")), encoding="utf-8")
PY

meta="$(cat "$META")"
timed_out="$(jq -r '.timed_out' <<<"$meta")"
sync_rc="$(jq -r '.rc' <<<"$meta")"
stderr_short="$(tr '\n' ' ' <"$ERR" | cut -c1-500)"

if [[ "$timed_out" == "true" ]]; then
  payload="$(jq -nc \
    --arg schema "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg sync "$SYNC" \
    --arg source "$SOURCE" \
    --arg stderr "$stderr_short" \
    --argjson timeout "$TIMEOUT_SECONDS" \
    '{
      schema_version:$schema,
      version:$version,
      status:"error",
      classification:"sync_helper_timeout",
      timed_out:true,
      timeout_seconds:$timeout,
      sync_helper:$sync,
      canonical_source:$source,
      stderr:$stderr
    }')"
  [[ "$JSON_OUT" -eq 1 ]] && printf '%s\n' "$payload" || jq -r '"status=\(.status) classification=\(.classification) timeout_seconds=\(.timeout_seconds)"' <<<"$payload"
  exit 124
fi

if ! jq -e . "$OUT" >/dev/null 2>&1; then
  payload="$(jq -nc \
    --arg schema "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg sync "$SYNC" \
    --arg source "$SOURCE" \
    --arg stderr "$stderr_short" \
    --argjson rc "$sync_rc" \
    '{
      schema_version:$schema,
      version:$version,
      status:"error",
      classification:"sync_helper_invalid_json",
      timed_out:false,
      sync_rc:$rc,
      sync_helper:$sync,
      canonical_source:$source,
      stderr:$stderr
    }')"
  [[ "$JSON_OUT" -eq 1 ]] && printf '%s\n' "$payload" || jq -r '"status=\(.status) classification=\(.classification)"' <<<"$payload"
  exit 2
fi

payload="$(jq -c \
  --arg schema "$SCHEMA_VERSION" \
  --arg version "$VERSION" \
  --arg sync "$SYNC" \
  --arg source "$SOURCE" \
  --argjson timeout "$TIMEOUT_SECONDS" \
  --argjson sync_rc "$sync_rc" \
  '{
    schema_version:$schema,
    version:$version,
    status:(if ((.root_drifted_count // 0) == 0 and (.errors_count // 0) == 0) then "pass" else "fail" end),
    timed_out:false,
    timeout_seconds:$timeout,
    sync_rc:$sync_rc,
    sync_helper:$sync,
    canonical_source:$source,
    target_count:(.target_count // 0),
    root_target_count:(.root_target_count // 0),
    canonical_root_drift_count:(.root_drifted_count // 0),
    canonical_snapshot_drift_count:(.canonical_drifted_count // 0),
    errors_count:(.errors_count // 0),
    source_hash:(.source_hash // null),
    checked_repos:[(.root_details // [])[] | {repo,target,status,drift,block_present,missing_rules}],
    drifted_repos:[(.root_details // [])[] | select((.drift // false) == true) | {repo,target,status,missing_rules}],
    errors:(.errors // []),
    evidence_source:"sync-canonical-doctrine.sh --check --json"
  }' "$OUT")"

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$payload"
else
  jq -r '"status=\(.status) canonical_root_drift_count=\(.canonical_root_drift_count) root_target_count=\(.root_target_count) timed_out=\(.timed_out)"' <<<"$payload"
fi

[[ "$(jq -r '.status' <<<"$payload")" == "pass" ]]
