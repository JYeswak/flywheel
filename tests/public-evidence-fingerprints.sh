#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/public-evidence-fingerprints.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if jq -e . "$ROOT/.flywheel/evidence/flywheel-sadm5/registry-foundation-repair-20260515T1745Z.json" >/dev/null; then
  pass "registry repair receipt parses"
else
  fail "registry repair receipt parses"
fi

violations="$TMP/private-fingerprint-violations.txt"
if rg -n -P '"/Users/josh/(?:\.claude|\.local)[^"]*": "[a-f0-9]{64}"' \
  "$ROOT/.flywheel/evidence" \
  "$ROOT/.flywheel/reports" \
  "$ROOT/.flywheel/audit" \
  --glob '*.json' \
  --glob '*.jsonl' \
  >"$violations" 2>/dev/null; then
  cat "$violations" >&2
  fail "public evidence redacts private local full-hash fingerprints"
else
  pass "public evidence redacts private local full-hash fingerprints"
fi

if jq -e '
  .sha256_prefixes
  and (.sha256 == null)
  and (.sha256_prefixes["/Users/josh/.claude/skills/infisical-secrets/bin/cf-secret-from-project"] | test("^[a-f0-9]{12}$"))
  and (.sha256_prefixes["/Users/josh/.local/bin/cf-secret-from-project"] | test("^[a-f0-9]{12}$"))
' "$ROOT/.flywheel/evidence/flywheel-sadm5/registry-foundation-repair-20260515T1745Z.json" >/dev/null; then
  pass "private local fingerprints use short prefixes"
else
  fail "private local fingerprints use short prefixes"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
