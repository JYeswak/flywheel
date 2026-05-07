#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/evidence-pack-resolve.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/evidence-pack-v2.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() {
  printf 'PASS %s\n' "$1"
  pass_count=$((pass_count + 1))
}

fail() {
  printf 'FAIL %s\n' "$1" >&2
  fail_count=$((fail_count + 1))
}

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || cat "$file" >&2
    exit 1
  fi
}

bash -n "$SCRIPT" && pass "resolver_syntax"

anchor_file="$TMP/source.md"
cat >"$anchor_file" <<'EOF'
line one
line two
line three
line four
EOF

cat >"$TMP/valid.json" <<JSON
{
  "evidence_pack_version": 2,
  "items": [
    {
      "id": "EV-001",
      "description": "valid anchored observation",
      "excerpt_anchor": "$anchor_file:2-3",
      "edges": [
        {"relation": "supports", "claim_id": "C-001", "confidence": "high"}
      ]
    }
  ],
  "claims": [
    {
      "id": "C-001",
      "statement": "resolver accepts valid v2 packs",
      "status": "confirmed",
      "evidence_supporting": ["EV-001"],
      "evidence_refuting": []
    }
  ]
}
JSON

"$SCRIPT" "$TMP/valid.json" --json >"$TMP/valid.out"
assert_jq "$TMP/valid.out" '.status == "pass" and .items == 1 and .claims == 1' "valid_v2_pack_passes"

cat >"$TMP/broken-anchor.json" <<JSON
{
  "evidence_pack_version": 2,
  "items": [
    {
      "id": "EV-001",
      "description": "anchor exceeds file line count",
      "excerpt_anchor": "$anchor_file:2-99",
      "edges": [
        {"relation": "supports", "claim_id": "C-001", "confidence": "high"}
      ]
    }
  ],
  "claims": [
    {
      "id": "C-001",
      "statement": "resolver rejects broken anchors",
      "status": "unverified",
      "evidence_supporting": ["EV-001"],
      "evidence_refuting": []
    }
  ]
}
JSON

set +e
"$SCRIPT" "$TMP/broken-anchor.json" --json >"$TMP/broken-anchor.out"
broken_anchor_rc=$?
set -e
[[ "$broken_anchor_rc" -ne 0 ]] && pass "broken_anchor_exits_nonzero" || fail "broken_anchor_exits_nonzero"
assert_jq "$TMP/broken-anchor.out" '.status == "fail" and (.errors | any(test("excerpt_anchor_unresolved")))' "broken_anchor_fails"

cat >"$TMP/missing-claim.json" <<JSON
{
  "evidence_pack_version": 2,
  "items": [
    {
      "id": "EV-001",
      "description": "edge points at nonexistent claim",
      "excerpt_anchor": "$anchor_file:1-1",
      "edges": [
        {"relation": "supports", "claim_id": "C-999", "confidence": "medium"}
      ]
    }
  ],
  "claims": [
    {
      "id": "C-001",
      "statement": "resolver rejects missing edge claim ids",
      "status": "partial",
      "evidence_supporting": ["EV-001"],
      "evidence_refuting": []
    }
  ]
}
JSON

set +e
"$SCRIPT" "$TMP/missing-claim.json" --json >"$TMP/missing-claim.out"
missing_claim_rc=$?
set -e
[[ "$missing_claim_rc" -ne 0 ]] && pass "missing_claim_exits_nonzero" || fail "missing_claim_exits_nonzero"
assert_jq "$TMP/missing-claim.out" '.status == "fail" and (.errors | any(test("edge_claim_missing")))' "missing_claim_edge_fails"

cat >"$TMP/legacy.json" <<'JSON'
{"evidence_items":[{"path":"legacy","claim":"legacy pack"}]}
JSON

"$SCRIPT" "$TMP/legacy.json" --json >"$TMP/legacy.out"
assert_jq "$TMP/legacy.out" '.status == "skipped" and .reason == "legacy_or_unversioned_pack"' "legacy_pack_skips"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'FAILED evidence-pack-v2 tests pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'OK evidence-pack-v2 tests pass=%s/7\n' "$pass_count"
