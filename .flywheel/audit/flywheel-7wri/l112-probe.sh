#!/usr/bin/env bash
set -euo pipefail

flywheel_repo="/Users/josh/Developer/flywheel"
skillos_repo="/Users/josh/Developer/skillos"

cd "$skillos_repo"
bash -n .flywheel/run-30m-loop.sh
python3 -m pytest tests/test_run_30m_loop_contract.py -q >/dev/null
rg -q "CANONICAL_LAST_TICK_FILE" .flywheel/run-30m-loop.sh
rg -q "LAST_RUN_FILE" .flywheel/run-30m-loop.sh
rg -q "skillos.last_tick_receipt.v1" .flywheel/run-30m-loop.sh tests/test_run_30m_loop_contract.py

cd "$flywheel_repo"
test -s .flywheel/audit/flywheel-7wri/evidence.md
test -s .flywheel/audit/flywheel-7wri/compliance-pack.md
test -s .flywheel/audit/flywheel-7wri/validation-receipt.json
br show flywheel-7wri --json | jq -e '.[0].status == "closed" and (.[0].close_reason | test("last_tick"))' >/dev/null
bash .flywheel/validation-schema/v1/parse.sh .flywheel/audit/flywheel-7wri/validation-receipt.json >/dev/null
printf 'flywheel-7wri-l112-pass\n'
