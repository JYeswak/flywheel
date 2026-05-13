#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/true-publication-registry-validate.py"
REGISTRY="$ROOT/.flywheel/PLANS/public-share-readiness-2026-05-12/19-TRUE-PUBLICATION-RELEASE-BLOCKER-REGISTRY.md"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/true-publication-registry.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if python3 -m py_compile "$SCRIPT"; then pass "syntax"; else fail "syntax"; fi

if python3 "$SCRIPT" --registry "$REGISTRY" --json >"$TMP/default.json"; then
  if jq -e '.status == "pass" and .row_count == 20 and .open_count == 20 and (.warnings | length) == 20' "$TMP/default.json" >/dev/null; then
    pass "default registry shape passes with open warnings"
  else
    fail "default registry envelope"
  fi
else
  fail "default registry command"
fi

if python3 "$SCRIPT" --registry "$REGISTRY" --release --json >"$TMP/release.json"; then
  fail "release mode must fail while rows remain open"
else
  if jq -e '.status == "fail" and (.errors[]?.code == "release_blocked_open_row")' "$TMP/release.json" >/dev/null; then
    pass "release mode blocks open rows"
  else
    fail "release mode failure shape"
  fi
fi

cat >"$TMP/duplicate.md" <<'EOF'
# Fixture

| ID | Class | Severity | Status | Owner | Source evidence | Required closure |
|---|---|---:|---|---|---|---|
| TP-001 | one | P0 | open | Flywheel | fixture | close it |
| TP-001 | two | P0 | open | Flywheel | fixture | close it |
EOF

if python3 "$SCRIPT" --registry "$TMP/duplicate.md" --json >"$TMP/duplicate.json"; then
  fail "duplicate id fixture must fail"
else
  if jq -e '.status == "fail" and (.errors[]?.code == "duplicate_id")' "$TMP/duplicate.json" >/dev/null; then
    pass "duplicate ids fail"
  else
    fail "duplicate id failure shape"
  fi
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
