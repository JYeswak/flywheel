#!/usr/bin/env bash
# tests/fleet-coherence-alert-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/fleet-coherence-alert.sh
# (scaffolded by bead flywheel-ws02m / scaffold-canonical-cli.sh, filled-in by
# bead flywheel-5ke66.9 — wave-2-general-9).
#
# Tests 1-13: baseline AG1 canonical surface envelopes (NEW canonical surface).
# Tests 14-20: fillin-specific assertions + backward-compat with python heredoc.
#
# NOTE: the existing tests/fleet-coherence-alert.sh exercises the python
# heredoc's dash-flag surfaces (--doctor, --health, --validate, --audit, --why,
# --repair) which are unchanged by this scaffold. The bash early-dispatch
# only intercepts the no-dash subcommand forms and --info/--schema/--examples.
# Backward-compat is enforced by Tests 14-15 here.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/fleet-coherence-alert.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info envelope (intercepted by bash scaffold)
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version and .command == "info"' >/dev/null; then
  pass "--info emits canonical envelope"
else fail "--info envelope"; fi

# Test 3: --schema envelope (intercepted by bash scaffold)
if "$SCRIPT" --schema 2>/dev/null | jq -e '.schema_version and .command == "schema"' >/dev/null; then
  pass "--schema emits canonical envelope"
else fail "--schema envelope"; fi

# Test 4: --examples envelope (NEW from scaffold)
if "$SCRIPT" --examples --json 2>/dev/null | jq -e '.command == "examples"' >/dev/null; then
  pass "--examples emits canonical envelope"
else fail "--examples envelope"; fi

# Test 5: doctor (no-dash) envelope
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor"' >/dev/null; then
  pass "doctor emits canonical envelope"
else fail "doctor envelope"; fi

# Test 6: health (no-dash) envelope
if "$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null; then
  pass "health emits canonical envelope"
else fail "health envelope"; fi

# Test 7: repair --dry-run envelope
if "$SCRIPT" repair --scope none --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run"' >/dev/null; then
  pass "repair --dry-run emits canonical envelope"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope none --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate (no-dash) envelope
if "$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate"' >/dev/null; then
  pass "validate emits canonical envelope"
else fail "validate envelope"; fi

# Test 10: audit (no-dash) envelope
if "$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit"' >/dev/null; then
  pass "audit emits canonical envelope"
else fail "audit envelope"; fi

# Test 11: why with id
if "$SCRIPT" why some-id 2>/dev/null | jq -e '.command == "why"' >/dev/null; then
  pass "why <id> emits canonical envelope"
else fail "why envelope"; fi

# Test 12: help <topic>
if "$SCRIPT" help repair 2>/dev/null | grep -q 'topic:'; then
  pass "help repair returns topic header"
else fail "help topic"; fi

# Test 13: quickstart envelope
if "$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null; then
  pass "quickstart emits canonical envelope"
else fail "quickstart envelope"; fi

# ===== fillin-specific assertions (flywheel-5ke66.9 — fleet-coherence-alert) =====

# Test 14: BACKWARD-COMPAT — --info canonical_cli_surfaces still contains "--dry-run"
# (existing tests/fleet-coherence-alert.sh:110 assertion)
if "$SCRIPT" --info --json 2>/dev/null \
  | jq -e '.name == "fleet-coherence-alert.sh" and (.canonical_cli_surfaces | index("--dry-run"))' >/dev/null; then
  pass "--info backward-compat: name + canonical_cli_surfaces includes --dry-run"
else fail "--info backward-compat shape"; fi

# Test 15: BACKWARD-COMPAT — --schema default branch keeps event_schema_version=2 + l61_pairing_status enum
# (existing tests/fleet-coherence-alert.sh:111-112 assertion)
if "$SCRIPT" --schema --json 2>/dev/null \
  | jq -e '.event_schema_version == 2 and (.l61_pairing_status | index("complete"))' >/dev/null; then
  pass "--schema backward-compat: event_schema_version=2 + l61_pairing_status enum"
else fail "--schema backward-compat shape"; fi

# Test 16: doctor 5+ probes (substrate-specific)
if "$SCRIPT" doctor --json 2>/dev/null \
  | jq -e '.checks | length >= 5 and (any(.name == "python3_on_path")) and (any(.name == "ntm_bin_executable")) and (any(.name == "fixtures_present")) and (any(.name == "ledger_writable"))' >/dev/null; then
  pass "doctor: 5+ probes incl. python3 + ntm + fixtures + ledger"
else fail "doctor substrate probes"; fi

# Test 17: repair fixtures-prime emits non-stub envelope
if "$SCRIPT" repair --scope fixtures-prime --dry-run --json 2>/dev/null \
  | jq -e '.command == "repair" and .scope == "fixtures-prime" and (.status != "todo") and has("fixtures") and has("present") and has("fixture_cases")' >/dev/null; then
  pass "repair --scope fixtures-prime emits non-stub envelope"
else fail "repair scope-specific"; fi

# Test 18: validate --row-json with attempt ledger row schema
if "$SCRIPT" validate --row-json='{"schema_version":"fleet-coherence-alert-attempt/v1","event_id":"e1","dedupe_key":"k1","attempt_ts":"2026-05-11T00:00:00Z","l61_pairing_status":"complete"}' 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "row" and .status == "pass" and (.valid == true)' >/dev/null; then
  pass "validate --row-json enforces attempt-ledger row schema"
else fail "validate row schema"; fi

# Test 19: validate --fixtures probes required test cases
if "$SCRIPT" validate --fixtures 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "fixtures" and has("fixtures") and has("present") and has("fixture_cases") and has("required_cases") and has("missing_cases")' >/dev/null; then
  pass "validate --fixtures probes required test cases (surface-specific)"
else fail "validate fixtures subject"; fi

# Test 20: validate --ledger probes l61 distribution
if "$SCRIPT" validate --ledger 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "ledger" and has("ledger") and has("present") and has("row_count") and has("complete_count") and has("degraded_count") and has("failed_count")' >/dev/null; then
  pass "validate --ledger probes l61 distribution (surface-specific)"
else fail "validate ledger subject"; fi


if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
