#!/usr/bin/env bash
set -euo pipefail
TARGET="/Users/josh/Developer/flywheel/.flywheel/scripts/storage-probe.sh"
"$TARGET" --help >/dev/null
"$TARGET" capabilities --json | jq -e '.schema_version and (.features or .command)' >/dev/null
"$TARGET" --json | jq -e 'type == "object"' >/dev/null
printf 'PASS .flywheel/scripts/storage-probe.sh agent ergonomics regression\n'
