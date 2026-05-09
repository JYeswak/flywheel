#!/usr/bin/env bash
set -euo pipefail

cd /Users/josh/Developer/flywheel

jq -e '
  .project == "mobile-eats"
  and .last_run_status == "ok"
  and .last_run_exit_code == 0
  and .last_tick >= "2026-05-09T08:59:10Z"
' /Users/josh/.flywheel/loops/mobile-eats.json >/dev/null

jq -e '
  .project == "mobile-eats"
  and .task_id == "20260505T152545Z"
  and .ts == "2026-05-05T15:25:49Z"
  and .status == "ok"
' /Users/josh/.local/state/flywheel-loop/last_tick_mobile-eats.json >/dev/null

python3 - <<'PY'
import json
from pathlib import Path

path = Path("/Users/josh/Developer/mobile-eats/.flywheel/dispatch-log.jsonl")
last_dispatch = None
last_callback = None
for line in path.read_text().splitlines():
    try:
        row = json.loads(line)
    except json.JSONDecodeError:
        continue
    if row.get("event") in {"orchestrator_dispatched", "orchestrator_redispatched", "idle_pane_auto_dispatch"} or row.get("dispatch_id"):
        last_dispatch = row
    if row.get("callback_received_at"):
        last_callback = row

assert last_dispatch and last_dispatch.get("ts") == "2026-05-09T06:53:09Z", last_dispatch
assert last_callback and last_callback.get("callback_received_at") == "2026-05-05T15:18:09Z", last_callback
PY

br show flywheel-2xdi.15.1 --json \
  | jq -e '.[0].status == "open"
    and .[0].source_repo == "/Users/josh/Developer/flywheel"
    and (.[0].description | contains("callback_received_at is 2026-05-05T15:18:09Z"))' >/dev/null

test -s .flywheel/audit/flywheel-2xdi.15/evidence.md
test -s .flywheel/audit/flywheel-2xdi.15/compliance-pack.md
test -s .flywheel/audit/flywheel-2xdi.15/validation-receipt.json
br show flywheel-2xdi.15 --json \
  | jq -e '.[0].status == "closed"
    and (.[0].close_reason | contains("flywheel-2xdi.15.1"))' >/dev/null
bash .flywheel/validation-schema/v1/parse.sh \
  .flywheel/audit/flywheel-2xdi.15/validation-receipt.json >/dev/null

printf 'flywheel-2xdi.15-l112-pass\n'
