#!/usr/bin/env bash
set -euo pipefail
TARGET="/Users/josh/Developer/flywheel/.flywheel/scripts/frozen-pane-detector.sh"
"$TARGET" --help >/dev/null
"$TARGET" --info --json | jq -e 'type == "object" and (.schema_version or .features or .capabilities or .canonical_cli_surfaces or .exit_codes or .native_surface or .name or .command)' >/dev/null
"$TARGET" --info --json | jq -e 'type == "object"' >/dev/null
printf 'PASS .flywheel/scripts/frozen-pane-detector.sh agent ergonomics regression\n'
