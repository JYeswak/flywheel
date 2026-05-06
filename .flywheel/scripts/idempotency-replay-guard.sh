#!/usr/bin/env bash
set -euo pipefail
VERSION="idempotency-replay-guard/v1"
LEDGER="${IDEMPOTENCY_REPLAY_LEDGER:-$HOME/.local/state/flywheel/dispatch-receipts.jsonl}"
LOCK_DIR="${IDEMPOTENCY_REPLAY_LOCK_DIR:-$HOME/.local/state/flywheel/idempotency-replay-locks}"
INPUT_TEXT=""
INPUT_FILE=""
KEY=""
RECEIPT_REF=""
JSON_OUT=0
QUIET=0
NO_LOCK=0
MARK_COMPLETED=0
RELEASE_LOCK=0
usage() {
  cat <<'USAGE'
usage: idempotency-replay-guard.sh [--input TEXT|--input-file PATH] [--ledger PATH] [--lock-dir PATH] [--json] [--quiet]
       idempotency-replay-guard.sh --mark-completed --receipt-ref REF [--input TEXT|--input-file PATH] [--json]
       idempotency-replay-guard.sh --release-lock [--input TEXT|--input-file PATH] [--json]
       idempotency-replay-guard.sh --info|--examples|--help
USAGE
}
info() {
  jq -nc --arg version "$VERSION" --arg ledger "$LEDGER" --arg lock_dir "$LOCK_DIR" '{
    schema_version:"idempotency-replay-guard.info/v1",
    name:"idempotency-replay-guard",
    version:$version,
    ledger:$ledger,
    lock_dir:$lock_dir,
    canonical_cli_flags:["--help","--info","--examples","--json","--quiet"],
    statuses:["already_completed","in_flight","not_seen","completed"],
    output_schema:".flywheel/validation-schema/v1/dispatch-receipt.schema.json"
  }'
}
examples() {
  jq -nc '{schema_version:"idempotency-replay-guard.examples/v1",examples:[
    "idempotency-replay-guard.sh --input-file /tmp/dispatch.md --json",
    "printf %s payload | idempotency-replay-guard.sh --json",
    "idempotency-replay-guard.sh --mark-completed --receipt-ref .beads/issues.jsonl#L1 --input payload --json",
    "idempotency-replay-guard.sh --release-lock --input payload --json"
  ]}'
}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --no-lock) NO_LOCK=1; shift ;;
    --mark-completed) MARK_COMPLETED=1; shift ;;
    --release-lock) RELEASE_LOCK=1; shift ;;
    --receipt-ref) RECEIPT_REF="${2:?--receipt-ref requires REF}"; shift 2 ;;
    --receipt-ref=*) RECEIPT_REF="${1#*=}"; shift ;;
    --ledger) LEDGER="${2:?--ledger requires PATH}"; shift 2 ;;
    --ledger=*) LEDGER="${1#*=}"; shift ;;
    --lock-dir) LOCK_DIR="${2:?--lock-dir requires PATH}"; shift 2 ;;
    --lock-dir=*) LOCK_DIR="${1#*=}"; shift ;;
    --input) INPUT_TEXT="${2:?--input requires TEXT}"; shift 2 ;;
    --input=*) INPUT_TEXT="${1#*=}"; shift ;;
    --input-file) INPUT_FILE="${2:?--input-file requires PATH}"; shift 2 ;;
    --input-file=*) INPUT_FILE="${1#*=}"; shift ;;
    --idempotency-key) KEY="${2:?--idempotency-key requires KEY}"; shift 2 ;;
    --idempotency-key=*) KEY="${1#*=}"; shift ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'ERR unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done
if [[ -n "$INPUT_FILE" ]]; then
  INPUT_TEXT="$(cat "$INPUT_FILE")"
elif [[ -z "$INPUT_TEXT" && ! -t 0 ]]; then
  INPUT_TEXT="$(cat)"
fi
key_json="$(python3 - "$KEY" "$INPUT_TEXT" <<'PY'
import hashlib, json, sys
supplied, raw = sys.argv[1], sys.argv[2]
if supplied:
    key = supplied if supplied.startswith("sha256:") else "sha256:" + supplied
    canonical = raw
else:
    try:
        canonical = json.dumps(json.loads(raw), sort_keys=True, separators=(",", ":"))
    except Exception:
        canonical = raw
    key = "sha256:" + hashlib.sha256(canonical.encode("utf-8")).hexdigest()
print(json.dumps({"key": key, "hash": key, "canonical": canonical}, separators=(",", ":")))
PY
)"
KEY="$(jq -r '.key' <<<"$key_json")"
REPLAY_HASH="$(jq -r '.hash' <<<"$key_json")"
KEY_SAFE="${KEY#sha256:}"
LOCK_PATH="$LOCK_DIR/$KEY_SAFE.lock"
completeness='{"IDEM-001":true,"IDEM-002":true,"IDEM-003":true,"IDEM-004":true,"IDEM-005":true,"IDEM-006":true}'
emit() {
  local status="$1" lock_acquired="$2" receipt_ref="${3:-null}" line="${4:-null}" begin="$5" commit="$6" abort="$7"
  local row
  row="$(jq -nc \
    --arg schema_version "dispatch-receipt/v1" \
    --arg guard_version "$VERSION" \
    --arg status "$status" \
    --arg idempotency_key "$KEY" \
    --arg replay_detection_hash "$REPLAY_HASH" \
    --arg lock_path "$LOCK_PATH" \
    --argjson receipt_ref "$receipt_ref" \
    --argjson previous_close_row "$line" \
    --argjson lock_acquired "$lock_acquired" \
    --argjson completeness "$completeness" \
    --argjson begin "$begin" \
    --argjson commit "$commit" \
    --argjson abort "$abort" \
    '{
      schema_version:$schema_version,
      receipt_type:"replay_guard",
      guard_version:$guard_version,
      status:$status,
      idempotency_key:$idempotency_key,
      replay_detection_hash:$replay_detection_hash,
      dispatch_identity_key:$idempotency_key,
      packet_hash:$replay_detection_hash,
      close_identity_key:$idempotency_key,
      dedupe_policy:"latest-row-by-ref_id-event",
      previous_close_row:$previous_close_row,
      prior_receipt_ref:$receipt_ref,
      lock_path:$lock_path,
      lock_acquired:$lock_acquired,
      transaction_boundary:{begin:$begin,commit:$commit,abort:$abort},
      receipt_completeness:$completeness
    }')"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$row"
  elif [[ "$QUIET" -eq 0 ]]; then
    printf '%s idempotency_key=%s\n' "$status" "$KEY"
  fi
}
lookup_completed() {
  python3 - "$LEDGER" "$KEY" "$REPLAY_HASH" <<'PY'
import json, sys
from pathlib import Path
path = Path(sys.argv[1]).expanduser()
key, replay = sys.argv[2], sys.argv[3]
if not path.exists():
    print(json.dumps({"found": False, "line": None, "receipt_ref": None}))
    raise SystemExit
found = None
with path.open(encoding="utf-8", errors="replace") as handle:
    for line_no, line in enumerate(handle, start=1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        if row.get("idempotency_key") == key or row.get("replay_detection_hash") == replay:
            status = str(row.get("status") or row.get("event") or "")
            if status in {"completed", "closed", "close"} or row.get("completed") is True:
                found = {"found": True, "line": line_no, "receipt_ref": row.get("receipt_ref") or row.get("prior_receipt_ref") or f"{path}#L{line_no}"}
if found is None:
    found = {"found": False, "line": None, "receipt_ref": None}
print(json.dumps(found, separators=(",", ":")))
PY
}
append_completed() {
  mkdir -p "$(dirname "$LEDGER")"
  jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg key "$KEY" --arg hash "$REPLAY_HASH" --arg ref "$RECEIPT_REF" --argjson completeness "$completeness" '{
    schema_version:"dispatch-receipt/v1",receipt_type:"replay_guard",status:"completed",ts:$ts,
    idempotency_key:$key,replay_detection_hash:$hash,dispatch_identity_key:$key,packet_hash:$hash,
    close_identity_key:$key,receipt_ref:$ref,dedupe_policy:"latest-row-by-ref_id-event",
    transaction_boundary:{begin:true,commit:true,abort:false},receipt_completeness:$completeness
  }' >>"$LEDGER"
}
completed="$(lookup_completed)"
if jq -e '.found == true' >/dev/null <<<"$completed"; then
  emit "already_completed" false "$(jq -c '.receipt_ref' <<<"$completed")" "$(jq -c '.line' <<<"$completed")" false true false
  exit 0
fi
if [[ "$RELEASE_LOCK" -eq 1 ]]; then
  rm -rf "$LOCK_PATH"
  emit "not_seen" false null null false false true
  exit 0
fi
if [[ "$MARK_COMPLETED" -eq 1 ]]; then
  append_completed
  rm -rf "$LOCK_PATH"
  emit "completed" false "$(jq -nc --arg ref "$RECEIPT_REF" '$ref')" null true true false
  exit 0
fi
if [[ -d "$LOCK_PATH" ]]; then
  emit "in_flight" false null null false false false
  exit 0
fi
if [[ "$NO_LOCK" -eq 1 ]]; then
  emit "not_seen" false null null true false false
  exit 0
fi
mkdir -p "$LOCK_DIR"
if mkdir "$LOCK_PATH" 2>/dev/null; then
  printf '%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >"$LOCK_PATH/created_at"
  emit "not_seen" true null null true false false
else
  emit "in_flight" false null null false false false
fi
