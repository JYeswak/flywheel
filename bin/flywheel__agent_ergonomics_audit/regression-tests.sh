#!/usr/bin/env bash
set -euo pipefail
TARGET="/Users/josh/Developer/flywheel/bin/flywheel"
"$TARGET" --help >/dev/null
"$TARGET" capabilities --json | jq -e '.schema_version and (.features or .command)' >/dev/null
"$TARGET" doctor --repo . --json | jq -e 'type == "object"' >/dev/null
printf 'PASS bin/flywheel agent ergonomics regression\n'
