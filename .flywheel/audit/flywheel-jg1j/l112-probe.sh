#!/usr/bin/env bash
set -euo pipefail

flywheel_repo="/Users/josh/Developer/flywheel"
skillos_repo="/Users/josh/Developer/skillos"

cd "$skillos_repo"
bash -n .flywheel/run-30m-loop.sh
python3 -m pytest tests/test_run_30m_loop_contract.py -q >/dev/null
rg -q "Ready-zero blocked queue fallback" .flywheel/run-30m-loop.sh
rg -q "ready_zero_fallback_phase=true" .flywheel/run-30m-loop.sh tests/test_run_30m_loop_contract.py
rg -q "bridge_fallback_checked=true" .flywheel/run-30m-loop.sh tests/test_run_30m_loop_contract.py
rg -q "blocked_dag_checked=true" .flywheel/run-30m-loop.sh tests/test_run_30m_loop_contract.py
rg -q "state/no-ready-work-<ts>.json" .flywheel/run-30m-loop.sh tests/test_run_30m_loop_contract.py
rg -q "no-ready receipt proves docs are the next unblocker" .flywheel/run-30m-loop.sh tests/test_run_30m_loop_contract.py

cd "$flywheel_repo"
test -s .flywheel/audit/flywheel-jg1j/evidence.md
test -s .flywheel/audit/flywheel-jg1j/compliance-pack.md
test -s .flywheel/audit/flywheel-jg1j/validation-receipt.json
br show flywheel-jg1j --json | jq -e '.[0].status == "closed" and (.[0].close_reason | test("ready-zero"))' >/dev/null
bash .flywheel/validation-schema/v1/parse.sh .flywheel/audit/flywheel-jg1j/validation-receipt.json >/dev/null
printf 'flywheel-jg1j-l112-pass\n'
