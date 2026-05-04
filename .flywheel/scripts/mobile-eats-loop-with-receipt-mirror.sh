#!/usr/bin/env bash
set -euo pipefail

PRODUCT_TICK="/Users/josh/.local/bin/mobile-eats-flywheel-loop-tick"
BRIDGE="/Users/josh/Developer/flywheel/.flywheel/scripts/mobile-eats-receipt-bridge.sh"
OUT_DIR="/Users/josh/.local/state/flywheel-loop"
OUT="$OUT_DIR/last_tick_mobile-eats.json"
LOG="/Users/josh/.local/logs/mobile-eats-receipt-mirror.jsonl"

ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }

mkdir -p "$OUT_DIR" "$(dirname "$LOG")"

tick_rc=0
"$PRODUCT_TICK" || tick_rc=$?

tmp="$(mktemp "$OUT.tmp.XXXXXX")"
if "$BRIDGE" --json > "$tmp"; then
  mv "$tmp" "$OUT"
  jq -nc --arg ts "$(ts)" --arg out "$OUT" --argjson tick_rc "$tick_rc" \
    '{ts:$ts,event:"receipt_mirrored",path:$out,tick_exit:$tick_rc}' >> "$LOG"
else
  bridge_rc=$?
  rm -f "$tmp"
  jq -nc --arg ts "$(ts)" --arg out "$OUT" --argjson tick_rc "$tick_rc" --argjson bridge_rc "$bridge_rc" \
    '{ts:$ts,event:"receipt_mirror_failed",path:$out,tick_exit:$tick_rc,bridge_exit:$bridge_rc}' >> "$LOG"
  exit "$bridge_rc"
fi

exit "$tick_rc"
