#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/.flywheel/scripts/quality-bar-close-gate.sh"
TMP="$(mktemp -d)"

cleanup() {
  find "$TMP" -type f -delete 2>/dev/null || true
  find "$TMP" -depth -type d -empty -delete 2>/dev/null || true
}
trap cleanup EXIT

mkdir -p "$TMP/.flywheel/plans/slate-no-third"
cat >"$TMP/.flywheel/plans/slate-no-third/STATE.json" <<'JSON'
{
  "slug": "slate-no-third",
  "current_phase": "refine",
  "schema_version": 5,
  "hypothesis_slate": [
    {"id": "H1", "strategy": "Keep the current wrapper.", "kill_condition": "Native output matches every policy field.", "is_third_alternative": false, "status": "active", "killed_by": null, "adopted_at_phase": null},
    {"id": "H2", "strategy": "Delete the wrapper.", "kill_condition": "A required local invariant is absent from native output.", "is_third_alternative": false, "status": "active", "killed_by": null, "adopted_at_phase": null}
  ]
}
JSON

set +e
out="$("$SCRIPT" validate plan --repo "$TMP" --plan-slug slate-no-third --json)"
rc=$?
set -e

test "$rc" -eq 1
printf '%s\n' "$out" | jq -e '.decision == "fail"' >/dev/null
printf '%s\n' "$out" | jq -e '.reasons | index("hypothesis_slate_invalid")' >/dev/null
printf '%s\n' "$out" | jq -e '.hypothesis_slate_errors | index("third_alternative_not_exactly_one")' >/dev/null

echo "test_hypothesis_slate_third_alternative_required: ok"
