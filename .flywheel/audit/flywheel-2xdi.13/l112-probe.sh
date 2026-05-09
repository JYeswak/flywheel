#!/usr/bin/env bash
set -euo pipefail

repo="/Users/josh/Developer/flywheel"
skillos="/Users/josh/Developer/skillos"

bash -n "$repo/.flywheel/scripts/gap-hunt-probe.sh"
bash -n "$skillos/.flywheel/run-30m-loop.sh"

grep -q "explicit_owner" "$repo/.flywheel/scripts/gap-hunt-probe.sh"
grep -q 'reap_pane_callbacks "pre_dispatch"' "$skillos/.flywheel/run-30m-loop.sh"

(cd "$skillos" && python3 -m unittest tests.test_run_30m_loop_contract >/dev/null)

printf '{"status":"pass","task_id":"flywheel-2xdi.13-e883bf","ownership_matcher":"explicit_owner_gated","callback_reaper":"pre_dispatch_wired"}\n'
