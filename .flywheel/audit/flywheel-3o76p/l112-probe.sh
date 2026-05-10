#!/usr/bin/env bash
set -euo pipefail

gh issue view 135 --repo Dicklesworthstone/ntm --json state,closedAt \
  | jq -e '.state == "OPEN" and .closedAt == null'
