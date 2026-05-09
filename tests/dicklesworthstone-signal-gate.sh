#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/.flywheel/scripts/dicklesworthstone-signal-gate.py"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dicklesworthstone-signal-gate-test.XXXXXX")"
trap 'find "$TMP_DIR" -type f -delete; find "$TMP_DIR" -depth -type d -empty -delete' EXIT

LEDGER="$TMP_DIR/signal-ledger.jsonl"
OUTCOMES="$TMP_DIR/signal-outcomes.jsonl"
QUOTA="$TMP_DIR/quota.jsonl"
BR_LOG="$TMP_DIR/br.log"
BR_STUB="$TMP_DIR/br"
NOW="2026-05-09T12:00:00Z"

cat >"$LEDGER" <<'JSONL'
{"id":"sig-1","source":"digest:friday","title":"old seen 1","ts_seen":"2026-04-28T00:00:00Z","state":"seen","ts_state_changed":"2026-04-28T00:00:00Z"}
{"id":"sig-2","source":"digest:friday","title":"old seen 2","ts_seen":"2026-04-29T00:00:00Z","state":"seen","ts_state_changed":"2026-04-29T00:00:00Z"}
{"id":"sig-3","source":"digest:friday","title":"old seen 3","ts_seen":"2026-05-01T00:00:00Z","state":"seen","ts_state_changed":"2026-05-01T00:00:00Z"}
{"id":"sig-4","source":"digest:friday","title":"old noted","ts_seen":"2026-05-02T00:00:00Z","state":"noted","ts_state_changed":"2026-05-02T00:00:00Z"}
JSONL
: >"$OUTCOMES"

cat >"$BR_STUB" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$BR_LOG"
if [[ "$*" == *"doctrine drift"* ]]; then
  printf '{"id":"flywheel-signal-p1"}\n'
else
  printf '{"id":"flywheel-signal-p2"}\n'
fi
SH
chmod +x "$BR_STUB"
export BR_LOG

DRY_JSON="$TMP_DIR/dry.json"
"$SCRIPT" tick --ledger "$LEDGER" --outcomes "$OUTCOMES" --quota-ledger "$QUOTA" \
  --now "$NOW" --dry-run --json >"$DRY_JSON"

jq -e '
  .counts.active_signal_count == 4 and
  .ranked_promotion_bead.recommended == true and
  .doctrine_drift_bead.recommended == true and
  .daily_quota.would_log_no_advance_reason == true and
  .daily_quota.no_advance_logged == false and
  .beads_filed_count == 0
' "$DRY_JSON" >/dev/null

test ! -s "$QUOTA"

APPLY_JSON="$TMP_DIR/apply.json"
"$SCRIPT" tick --repo "$TMP_DIR" --ledger "$LEDGER" --outcomes "$OUTCOMES" \
  --quota-ledger "$QUOTA" --now "$NOW" --apply --auto-file-beads --br-bin "$BR_STUB" \
  --json >"$APPLY_JSON"

jq -e '
  .daily_quota.no_advance_logged == true and
  .daily_quota.quota_logged_today == true and
  .ranked_promotion_bead.filed_id == "flywheel-signal-p2" and
  .doctrine_drift_bead.filed_id == "flywheel-signal-p1" and
  .beads_filed_count == 2
' "$APPLY_JSON" >/dev/null
jq -e 'select(.event == "daily_no_advance" and .date == "2026-05-09" and (.no_advance_reason | length > 0))' "$QUOTA" >/dev/null
grep -q -- "--priority 2" "$BR_LOG"
grep -q -- "--priority 1" "$BR_LOG"

RECENT_OUTCOMES="$TMP_DIR/recent-outcomes.jsonl"
cat >"$RECENT_OUTCOMES" <<'JSONL'
{"signal_id":"sig-9","ts":"2026-05-09T11:00:00Z","from_state":"noted","to_state":"extracted","extracted_to":"skill","extracted_ref":"ref"}
JSONL
RECENT_JSON="$TMP_DIR/recent.json"
"$SCRIPT" tick --ledger "$LEDGER" --outcomes "$RECENT_OUTCOMES" --quota-ledger "$TMP_DIR/recent-quota.jsonl" \
  --now "$NOW" --dry-run --json >"$RECENT_JSON"

jq -e '
  .daily_quota.advanced_today_count == 1 and
  .daily_quota.no_advance_reason == null and
  .doctrine_drift_bead.recommended == false
' "$RECENT_JSON" >/dev/null

echo "dicklesworthstone signal gate tests passed"
