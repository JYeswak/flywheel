#!/usr/bin/env bash
set -euo pipefail

/Users/josh/.local/bin/cass-v2-sustained-validation-probe --doctor --json \
  | jq -e '.command == "doctor" and (.status == "ok" or .status == "warn") and (.count >= 0) and (.warnings | type == "array")'
