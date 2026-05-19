#!/usr/bin/env bash
set -euo pipefail
TARGET="/Users/josh/Developer/flywheel/.flywheel/scripts/peer-orch-blocker-watch.sh"
"$TARGET" --help >/dev/null
"$TARGET" --capabilities --json | jq -e '.schema_version and (.features or .command)' >/dev/null
"$TARGET" --schema | jq -e 'type == "object"' >/dev/null
printf 'PASS .flywheel/scripts/peer-orch-blocker-watch.sh agent ergonomics regression\n'
