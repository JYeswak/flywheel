#!/usr/bin/env bash
set -euo pipefail

repo="/Users/josh/Developer/flywheel"
ledger="/Users/josh/.local/state/flywheel/gap-hunt-false-positives.jsonl"
script="$repo/.flywheel/scripts/gap-hunt-probe.sh"

cd "$repo"

test -s "$ledger"
[[ "$(wc -l <"$ledger" | tr -d ' ')" -ge 4 ]]

grep -Fq 'gap-hunt-false-positives.jsonl' "$script"
bash -n "$script"

GAP_HUNT_AUTO_BEAD_CAP=0 "$script" --dry-run --json \
  | jq -e '([.gaps_by_class["cross-source-silos"][]?.id] | index("cross-source-silos:gap-hunt-false-positives.jsonl") | not)' >/dev/null

printf 'pass\n'
