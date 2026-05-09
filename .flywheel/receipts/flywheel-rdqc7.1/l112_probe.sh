#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d -t doctrine-allowlist-l112.XXXXXX)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/source" "$tmp/repo/.flywheel"
cat >"$tmp/source/AGENTS.md" <<'CANONICAL'
# Canonical

## L1 -- One
---
id: L1
shipped: 2026-05-01
---
L1 body

## L2 -- Two
---
id: L2
shipped: 2026-05-02
---
L2 body

## L3 -- Three
---
id: L3
shipped: 2026-05-03
---
L3 body
CANONICAL

cat >"$tmp/repo/AGENTS.md" <<'LOCAL'
# Local

## L1 -- One
---
id: L1
shipped: 2026-05-01
---
L1 body
LOCAL
cp "$tmp/repo/AGENTS.md" "$tmp/repo/.flywheel/AGENTS-CANONICAL.md"
printf '{}\n' >"$tmp/repo/.flywheel/STATE.json"

FLYWHEEL_DOCTRINE_CANONICAL_SOURCE="$tmp/source/AGENTS.md" \
  /Users/josh/.local/bin/flywheel-doctrine-sync \
  --target-repo "$tmp/repo" \
  --dry-run \
  --l-rules L2 \
  --json \
  | jq -e '.l_rules_allowlist==["L2"] and .missing_l_rules==["L2"] and .missing_l_rules_all==["L2","L3"] and .unselected_missing_l_rules==["L3"] and .state_json.will_update==false'
