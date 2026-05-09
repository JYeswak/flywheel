#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
cd "$ROOT"

proof="$(mktemp -d -t flywheel-8lm8-proof.XXXXXX)"
git -C "$proof" init -q
printf '# Probe Repo\n' >"$proof/README.md"
printf '# Fixture AGENTS\n' >"$proof/AGENTS.md"

out="$("$HOME/.claude/skills/.flywheel/bin/flywheel-loop" init \
  --repo "$proof" \
  --mission-source "$proof/README.md" \
  --goal-source "$proof/README.md" \
  --state-source "$proof/README.md" \
  --json)"

test -s "$proof/.flywheel/INCIDENTS.md"
grep -q 'mission-anchor-drift-sub-mission-promotion' "$proof/.flywheel/INCIDENTS.md"
! grep -q 'agent-mail-token-continuity-after-compaction' "$proof/.flywheel/INCIDENTS.md"
printf '%s' "$out" | jq -e '.planned_writes[] | select(endswith("/.flywheel/INCIDENTS.md"))' >/dev/null

"$ROOT/.flywheel/scripts/cleanup-scratch.sh" --apply --json "$proof" >/dev/null

printf 'OK_init_distributes_selected_incidents\n'
