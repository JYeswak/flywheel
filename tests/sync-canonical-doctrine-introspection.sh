#!/usr/bin/env bash
# tests/sync-canonical-doctrine-introspection.sh
# Bead flywheel-4w0a0: regression coverage for the --info / --schema /
# --examples introspection surfaces added per flywheel-62mf9 agent-ergo
# audit recommendation sync-canonical-doctrine-R001.
#
# Pre-existing surfaces (--help, --check, --apply, --json, --source,
# --root) are also gated so future arg-parser refactors can't drop
# them silently.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TARGET="${SYNC_CANONICAL_DOCTRINE_PATH:-$ROOT/.flywheel/scripts/sync-canonical-doctrine.sh}"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: target exists + bash -n syntax-checks
if [[ -x "$TARGET" ]] && bash -n "$TARGET" 2>/dev/null; then
  pass "sync-canonical-doctrine.sh exists + bash -n ok"
else
  fail "sync-canonical-doctrine.sh missing or syntax-broken at $TARGET"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

# Test 2: --info emits a tool-info/v1 envelope with required keys
INFO_JSON="$("$TARGET" --info 2>/dev/null || true)"
if jq -e '
  .schema_version == "tool-info/v1"
  and .name == "sync-canonical-doctrine.sh"
  and (.version | test("^sync-canonical-doctrine/v"))
  and ((.modes | type) == "array" and (.modes | length) >= 2)
  and ((.flags | type) == "array")
  and ((.flags | index("--info")) != null)
  and ((.flags | index("--schema")) != null)
  and ((.flags | index("--examples")) != null)
  and ((.env_vars | type) == "array" and (.env_vars | length) >= 10)
  and .default_mode == "check"
  and (.exit_codes | has("0") and has("1") and has("2"))
  and ((.oversized_receipt.line_count | type) == "number")
  and ((.oversized_receipt.ratio | type) == "number")
' >/dev/null 2>&1 <<<"$INFO_JSON"; then
  pass "--info emits tool-info/v1 envelope with required keys"
else
  fail "--info envelope missing keys; got: ${INFO_JSON:0:200}"
fi

# Test 3: --schema emits a JSON Schema describing the receipt envelope
SCHEMA_JSON="$("$TARGET" --schema 2>/dev/null || true)"
if jq -e '
  .schema_version == "sync-canonical-doctrine-receipt/v1"
  and .type == "object"
  and ((.required | type) == "array")
  and ((.required | index("ts")) != null)
  and ((.required | index("mode")) != null)
  and ((.required | index("status")) != null)
  and .properties.mode.type == "string"
  and (.properties.source_hash.pattern | test("64"))
' >/dev/null 2>&1 <<<"$SCHEMA_JSON"; then
  pass "--schema emits sync-canonical-doctrine-receipt/v1 JSON Schema"
else
  fail "--schema envelope malformed; got: ${SCHEMA_JSON:0:200}"
fi

# Test 4: --examples emits non-empty curated invocations
EX_OUT="$("$TARGET" --examples 2>/dev/null || true)"
if [[ -n "$EX_OUT" ]] \
  && grep -Fq -- "--check --json" <<<"$EX_OUT" \
  && grep -Fq -- "--apply --json" <<<"$EX_OUT" \
  && grep -Fq -- "--source" <<<"$EX_OUT" \
  && grep -Fq -- "--root" <<<"$EX_OUT" \
  && grep -Fq -- "SYNC_CANONICAL_LEDGER_DISABLE" <<<"$EX_OUT"; then
  pass "--examples cites --check/--apply/--source/--root + at least one env var"
else
  fail "--examples missing one of: --check, --apply, --source, --root, env var"
fi

# Test 5: --help still works (regression guard for the existing usage block)
HELP_OUT="$("$TARGET" --help 2>/dev/null || true)"
if grep -Fq "usage: sync-canonical-doctrine.sh" <<<"$HELP_OUT" \
  && grep -Fq "Exit codes:" <<<"$HELP_OUT" \
  && grep -Fq "Environment:" <<<"$HELP_OUT"; then
  pass "--help still emits canonical usage + exit codes + environment"
else
  fail "--help regressed; got: ${HELP_OUT:0:200}"
fi

# Test 6: unknown flag exits 2 (canonical-cli-scoping stable exit code)
set +e
"$TARGET" --bogus-flag-flywheel-4w0a0 >/dev/null 2>&1
unknown_rc=$?
set -e
if [[ "$unknown_rc" -eq 2 ]]; then
  pass "unknown flag exits with rc=2 (usage/configuration error)"
else
  fail "unknown flag rc mismatch (expected 2, got $unknown_rc)"
fi

# Test 7: -h short form still works (matches --help)
SHORT_HELP="$("$TARGET" -h 2>/dev/null || true)"
if [[ "$SHORT_HELP" == "$HELP_OUT" ]] && [[ -n "$SHORT_HELP" ]]; then
  pass "-h short form matches --help"
else
  fail "-h short form regressed"
fi

# Test 8: allow-large receipt comment is present in source
if grep -Fq "canonical-cli-scoping-allow-large:" "$TARGET" \
  && grep -Fq "flywheel-62mf9 audit recommendation sync-canonical-doctrine-R001" "$TARGET" \
  && grep -Fq "fleet-propagation aggregator" "$TARGET"; then
  pass "allow-large receipt comment present at file head"
else
  fail "allow-large receipt missing from file head"
fi

# Test 9: --info reports the same allow-large receipt id (machine-readable)
if jq -e '.oversized_receipt.receipt_id | test("flywheel-62mf9 audit recommendation sync-canonical-doctrine-R001")' >/dev/null 2>&1 <<<"$INFO_JSON"; then
  pass "--info oversized_receipt.receipt_id matches source-comment receipt"
else
  fail "--info oversized_receipt.receipt_id missing or wrong"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
