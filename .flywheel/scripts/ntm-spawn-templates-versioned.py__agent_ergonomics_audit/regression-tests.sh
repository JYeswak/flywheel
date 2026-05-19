#!/usr/bin/env bash
set -euo pipefail
TARGET="/Users/josh/Developer/flywheel/.flywheel/scripts/ntm-spawn-templates-versioned.py"
"$TARGET" --help >/dev/null
"$TARGET" capabilities --json | jq -e '.schema_version and (.features or .command)' >/dev/null
"$TARGET" doctor --json | jq -e 'type == "object"' >/dev/null
printf 'PASS .flywheel/scripts/ntm-spawn-templates-versioned.py agent ergonomics regression\n'
