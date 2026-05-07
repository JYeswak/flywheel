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

mkdir -p "$TMP/.flywheel/plans/slate-empty"
cat >"$TMP/.flywheel/plans/slate-empty/STATE.json" <<'JSON'
{
  "slug": "slate-empty",
  "current_phase": "refine",
  "schema_version": 5,
  "hypothesis_slate": []
}
JSON

set +e
out="$("$SCRIPT" validate plan --repo "$TMP" --plan-slug slate-empty --json)"
rc=$?
set -e

test "$rc" -eq 1
printf '%s\n' "$out" | jq -e '.decision == "fail"' >/dev/null
printf '%s\n' "$out" | jq -e '.reasons | index("hypothesis_slate_invalid")' >/dev/null
printf '%s\n' "$out" | jq -e '.hypothesis_slate_errors | index("hypothesis_count_not_2_to_5")' >/dev/null

echo "test_hypothesis_slate_required: ok"
