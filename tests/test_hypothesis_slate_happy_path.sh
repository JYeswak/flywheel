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

mkdir -p "$TMP/.flywheel/plans/slate-happy"
cat >"$TMP/.flywheel/plans/slate-happy/STATE.json" <<'JSON'
{
  "slug": "slate-happy",
  "current_phase": "refine",
  "schema_version": 5,
  "hypothesis_slate": [
    {"id": "H1", "strategy": "Keep the current wrapper.", "kill_condition": "Native output matches every policy field.", "is_third_alternative": false, "status": "active", "killed_by": null, "adopted_at_phase": null},
    {"id": "H2", "strategy": "Delete the wrapper.", "kill_condition": "A required local invariant is absent from native output.", "is_third_alternative": false, "status": "active", "killed_by": null, "adopted_at_phase": null},
    {"id": "H3", "strategy": "Use a thin caller plus upstream issue.", "kill_condition": "Either native output fully covers the invariant or local policy is irreducible.", "is_third_alternative": true, "status": "active", "killed_by": null, "adopted_at_phase": null}
  ]
}
JSON

out="$("$SCRIPT" validate plan --repo "$TMP" --plan-slug slate-happy --json)"

printf '%s\n' "$out" | jq -e '.decision == "pass"' >/dev/null
printf '%s\n' "$out" | jq -e '.quality_bar_mode == "phase2_hypothesis_slate"' >/dev/null
printf '%s\n' "$out" | jq -e '.hypothesis_slate_valid == "yes"' >/dev/null

echo "test_hypothesis_slate_happy_path: ok"
