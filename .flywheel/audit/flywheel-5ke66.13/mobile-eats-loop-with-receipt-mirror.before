#!/usr/bin/env bash
set -euo pipefail

PRODUCT_TICK="${MOBILE_EATS_PRODUCT_TICK:-/Users/josh/.local/bin/mobile-eats-flywheel-loop-tick}"
BRIDGE="${MOBILE_EATS_RECEIPT_BRIDGE:-/Users/josh/Developer/flywheel/.flywheel/scripts/mobile-eats-receipt-bridge.sh}"
OUT_DIR="${MOBILE_EATS_LOOP_OUT_DIR:-/Users/josh/.local/state/flywheel-loop}"
OUT="$OUT_DIR/last_tick_mobile-eats.json"
LOG="${MOBILE_EATS_RECEIPT_MIRROR_LOG:-/Users/josh/.local/logs/mobile-eats-receipt-mirror.jsonl}"
JSONL_APPEND_LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"
JSONL_APPEND_AVAILABLE=0

ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }

if [[ -f "$JSONL_APPEND_LIB" ]]; then
  # shellcheck disable=SC1090,SC1091
  if source "$JSONL_APPEND_LIB" && declare -F fw_jsonl_append_validated >/dev/null; then
    JSONL_APPEND_AVAILABLE=1
  fi
fi

append_jsonl_best_effort() {
  local path="$1" row="$2" label="$3" rc
  if [[ "$JSONL_APPEND_AVAILABLE" -ne 1 ]] || ! declare -F fw_jsonl_append_validated >/dev/null; then
    printf 'WARN: %s append skipped; JSONL primitive unavailable: %s\n' "$label" "$JSONL_APPEND_LIB" >&2
    return 0
  fi
  if fw_jsonl_append_validated "$path" "$row"; then
    return 0
  else
    rc=$?
    printf 'WARN: %s append failed rc=%s path=%s\n' "$label" "$rc" "$path" >&2
    return 0
  fi
}

mkdir -p "$OUT_DIR" "$(dirname "$LOG")"

tick_rc=0
"$PRODUCT_TICK" || tick_rc=$?

tmp="$(mktemp "$OUT.tmp.XXXXXX")"
if "$BRIDGE" --json > "$tmp"; then
  mv "$tmp" "$OUT"
  row="$(jq -nc --arg ts "$(ts)" --arg out "$OUT" --argjson tick_rc "$tick_rc" \
    '{ts:$ts,event:"receipt_mirrored",path:$out,tick_exit:$tick_rc}')"
  append_jsonl_best_effort "$LOG" "$row" "mobile-eats receipt mirror"
else
  bridge_rc=$?
  rm -f "$tmp"
  row="$(jq -nc --arg ts "$(ts)" --arg out "$OUT" --argjson tick_rc "$tick_rc" --argjson bridge_rc "$bridge_rc" \
    '{ts:$ts,event:"receipt_mirror_failed",path:$out,tick_exit:$tick_rc,bridge_exit:$bridge_rc}')"
  append_jsonl_best_effort "$LOG" "$row" "mobile-eats receipt mirror"
  exit "$bridge_rc"
fi

exit "$tick_rc"
