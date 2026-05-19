#!/usr/bin/env bash
set -euo pipefail
TARGET="/Users/josh/Developer/flywheel/.flywheel/scripts/ntm-wave2-native-probes.sh"
"$TARGET" --help >/dev/null
"$TARGET" capabilities --json | jq -e '.schema_version and (.features or .command)' >/dev/null
"$TARGET" agents --json | jq -e 'type == "object"' >/dev/null
printf 'PASS .flywheel/scripts/ntm-wave2-native-probes.sh agent ergonomics regression\n'
