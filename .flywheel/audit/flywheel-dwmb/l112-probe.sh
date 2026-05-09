#!/usr/bin/env bash
set -euo pipefail

cd /Users/josh/Developer/flywheel

test -s .flywheel/audit/flywheel-dwmb/evidence.md
test -s .flywheel/audit/flywheel-dwmb/compliance-pack.md
test -s .flywheel/audit/flywheel-dwmb/validation-receipt.json

test -s /Users/josh/.local/state/flywheel-loop/last_tick_mobile-eats.json
jq -e '
  .version == "mobile-eats-receipt-bridge.v1"
  and .status == "ok"
  and .session == "mobile-eats"
  and .project == "mobile-eats"
  and .exit_code == 0
  and (.mobile_eats.bridge_option == "A")
' /Users/josh/.local/state/flywheel-loop/last_tick_mobile-eats.json >/dev/null

.flywheel/scripts/mobile-eats-receipt-bridge.sh --doctor --json \
  | jq -e '.status == "ok" and .version == "mobile-eats-receipt-bridge.v1"' >/dev/null

rg -q '"canonical_receipt_written": "yes"' .flywheel/dispatch-log.jsonl
rg -q '"doctor_status": "FAIL"' .flywheel/dispatch-log.jsonl

br show flywheel-dwmb.1 --json \
  | jq -e '.[0].status == "open" and .[0].priority == 3 and .[0].source_repo == "/Users/josh/Developer/flywheel"' >/dev/null
br show flywheel-dwmb --json \
  | jq -e '.[0].status == "closed" and (.[0].close_reason | test("validation-surface conflation"))' >/dev/null

bash .flywheel/validation-schema/v1/parse.sh .flywheel/audit/flywheel-dwmb/validation-receipt.json >/dev/null

printf 'flywheel-dwmb-l112-pass\n'
