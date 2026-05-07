#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${FLYWHEEL_DOCTRINE_BROADCAST_STATE:-$HOME/.local/state/flywheel/doctrine-broadcasts}"
RECEIPT_DIR="${FLYWHEEL_DOCTRINE_BROADCAST_RECEIPTS:-/Users/josh/Developer/flywheel/.flywheel/receipts/doctrine-broadcasts}"
SOURCE_ORCH="${FLYWHEEL_SOURCE_ORCH:-flywheel}"
TARGET_PROJECT=""
SUBJECT=""
BODY_PATH=""
DOCTRINE_VERSION=""
IMPORTANCE="normal"
ACK_REQUIRED=0
JSON_OUT=0
DRY_RUN=0

usage() {
  cat <<'USAGE'
usage: doctrine-broadcast-send.sh --target-project NAME --subject TEXT --body-path PATH --doctrine-version STAMP [--importance high|normal] [--ack-required] [--dry-run] [--json]

Writes one doctrine broadcast row to:
  ~/.local/state/flywheel/doctrine-broadcasts/inbox-<project>.jsonl

Default mutates the inbox and writes a receipt. --dry-run prints the planned
row without writing.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-project)
      [[ -n "${2:-}" ]] || { echo "ERR: --target-project requires NAME" >&2; exit 2; }
      TARGET_PROJECT="$2"; shift 2 ;;
    --subject)
      [[ -n "${2:-}" ]] || { echo "ERR: --subject requires TEXT" >&2; exit 2; }
      SUBJECT="$2"; shift 2 ;;
    --body-path)
      [[ -n "${2:-}" ]] || { echo "ERR: --body-path requires PATH" >&2; exit 2; }
      BODY_PATH="$2"; shift 2 ;;
    --doctrine-version)
      [[ -n "${2:-}" ]] || { echo "ERR: --doctrine-version requires STAMP" >&2; exit 2; }
      DOCTRINE_VERSION="$2"; shift 2 ;;
    --importance)
      [[ -n "${2:-}" ]] || { echo "ERR: --importance requires VALUE" >&2; exit 2; }
      IMPORTANCE="$2"; shift 2 ;;
    --ack-required)
      ACK_REQUIRED=1; shift ;;
    --dry-run)
      DRY_RUN=1; shift ;;
    --json)
      JSON_OUT=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "ERR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$TARGET_PROJECT" ]] || { echo "ERR: --target-project is required" >&2; exit 2; }
[[ -n "$SUBJECT" ]] || { echo "ERR: --subject is required" >&2; exit 2; }
[[ -n "$BODY_PATH" ]] || { echo "ERR: --body-path is required" >&2; exit 2; }
[[ -n "$DOCTRINE_VERSION" ]] || { echo "ERR: --doctrine-version is required" >&2; exit 2; }
[[ "$TARGET_PROJECT" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ERR: unsafe target project: $TARGET_PROJECT" >&2; exit 2; }
[[ "$IMPORTANCE" == "high" || "$IMPORTANCE" == "normal" ]] || { echo "ERR: --importance must be high or normal" >&2; exit 2; }
[[ -f "$BODY_PATH" ]] || { echo "ERR: body path not found: $BODY_PATH" >&2; exit 2; }

if rg -i 'josh|/Users/josh|flywheel-[a-z0-9]+|zeststream' "$BODY_PATH" >/dev/null 2>&1; then
  echo "ERR: body contains forbidden internal reference" >&2
  exit 6
fi

mkdir -p "$STATE_DIR" "$RECEIPT_DIR"
chmod 755 "$STATE_DIR" "$RECEIPT_DIR" 2>/dev/null || true

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
BODY_ABS="$(cd "$(dirname "$BODY_PATH")" && pwd -P)/$(basename "$BODY_PATH")"
BROADCAST_ID="$(printf '%s|%s|%s|%s|%s' "$TARGET_PROJECT" "$SUBJECT" "$BODY_ABS" "$DOCTRINE_VERSION" "$TS" | shasum -a 256 | awk '{print "doctrine-" substr($1,1,16)}')"
INBOX="$STATE_DIR/inbox-${TARGET_PROJECT}.jsonl"
LOCKDIR="$INBOX.lock"
TMP_INBOX="$INBOX.tmp"
ROW_FILE="$(mktemp "${TMPDIR:-/tmp}/doctrine-broadcast-row.XXXXXX")"
RECEIPT_PATH="$RECEIPT_DIR/$BROADCAST_ID.json"
TMP_RECEIPT="$RECEIPT_PATH.tmp"

cleanup() {
  rm -f "$ROW_FILE" "$TMP_INBOX" "$TMP_RECEIPT" 2>/dev/null || true
  rmdir "$LOCKDIR" 2>/dev/null || true
}
trap cleanup EXIT

jq -nc \
  --arg ts "$TS" \
  --arg source_orch "$SOURCE_ORCH" \
  --arg target_project "$TARGET_PROJECT" \
  --arg subject "$SUBJECT" \
  --arg body_path "$BODY_ABS" \
  --arg doctrine_version "$DOCTRINE_VERSION" \
  --arg importance "$IMPORTANCE" \
  --arg broadcast_id "$BROADCAST_ID" \
  --argjson ack_required "$ACK_REQUIRED" \
  '{
    ts:$ts,
    source_orch:$source_orch,
    target_project:$target_project,
    subject:$subject,
    body_path:$body_path,
    doctrine_version:$doctrine_version,
    importance:$importance,
    ack_required:($ack_required == 1),
    broadcast_id:$broadcast_id
  }' >"$ROW_FILE"

if [[ "$DRY_RUN" -eq 0 ]]; then
  until mkdir "$LOCKDIR" 2>/dev/null; do sleep 0.05; done
  if [[ -f "$INBOX" ]]; then
    cat "$INBOX" >"$TMP_INBOX"
  else
    : >"$TMP_INBOX"
  fi
  cat "$ROW_FILE" >>"$TMP_INBOX"
  chmod 0644 "$TMP_INBOX"
  mv "$TMP_INBOX" "$INBOX"
  chmod 0644 "$INBOX"
  jq -nc \
    --arg ts "$TS" \
    --arg target_project "$TARGET_PROJECT" \
    --arg inbox "$INBOX" \
    --arg receipt_path "$RECEIPT_PATH" \
    --argjson row "$(cat "$ROW_FILE")" \
    '{schema_version:"flywheel.doctrine_broadcast.receipt.v1",ts:$ts,target_project:$target_project,inbox_path:$inbox,receipt_path:$receipt_path,row:$row,sent:true}' >"$TMP_RECEIPT"
  chmod 0644 "$TMP_RECEIPT"
  mv "$TMP_RECEIPT" "$RECEIPT_PATH"
  chmod 0644 "$RECEIPT_PATH"
fi

payload="$(jq -nc \
  --arg mode "$([[ "$DRY_RUN" -eq 1 ]] && printf dry-run || printf sent)" \
  --arg inbox "$INBOX" \
  --arg receipt_path "$RECEIPT_PATH" \
  --argjson dry_run "$DRY_RUN" \
  --argjson row "$(cat "$ROW_FILE")" \
  '{schema_version:"flywheel.doctrine_broadcast.send.v1",status:$mode,dry_run:($dry_run == 1),inbox_path:$inbox,receipt_path:$receipt_path,row:$row}')"

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$payload"
else
  jq -r '"doctrine-broadcast status=\(.status) target=\(.row.target_project) broadcast_id=\(.row.broadcast_id) inbox=\(.inbox_path)"' <<<"$payload"
fi
