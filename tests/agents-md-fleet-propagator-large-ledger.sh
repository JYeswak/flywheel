#!/usr/bin/env bash
# tests/agents-md-fleet-propagator-large-ledger.sh
#
# Regression test for flywheel-94nzk: jq "Argument list too long" when ledger
# exceeds ARG_MAX. Pre-fix, doctor/audit/why/validate-ledger crashed when
# passed `--argjson rows "$rows"` for a ledger >1MB serialized (~5000+ rows).
# Post-fix, rows are routed via mktemp tmpfile + --slurpfile, which has no
# ARG_MAX limit. Tmpfiles cleaned up via EXIT trap inside the script.
#
# Synthetic 5000-row ledger empirically triggers the pre-fix bug (verified
# during 94nzk investigation; jq stderr: "Argument list too long" on macOS).

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/agents-md-fleet-propagator.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

TMP="$(mktemp -d -t agents-md-fleet-propagator-large-ledger.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
LEDGER="$TMP/ledger.jsonl"

# Build a 5000-row synthetic ledger (~1.9MB serialized).
python3 -c "
import json
for i in range(5000):
    row = {
        'ts': f'2026-05-11T07:{i//60:02d}:{i%60:02d}Z',
        'action': 'propagate',
        'repo': f'/Users/josh/Developer/sample-flywheel-fleet-repo-with-longer-path-name-{i:06d}',
        'success': True,
        'status': 'succeeded',
        'schema_version': 'agents-md-fleet-propagation/v1',
        'sha256_at_apply': 'a1b2c3d4e5f6' + ('0' * 52),
        'fuckup_log': None,
        'idempotency_key': f'flywheel-94nzk-regression-{i:06d}',
    }
    print(json.dumps(row))
" > "$LEDGER"

ledger_bytes="$(wc -c <"$LEDGER" | tr -d ' ')"
if (( ledger_bytes > 1500000 )); then
  pass "synthetic ledger >1.5MB ($ledger_bytes bytes) — large enough to overflow argv pre-fix"
else
  fail "synthetic ledger too small ($ledger_bytes bytes)"
fi

# Test 1: doctor --json with large ledger
out="$(AGENTS_MD_FLEET_LEDGER="$LEDGER" "$SCRIPT" doctor --json 2>&1)"
if printf '%s' "$out" | grep -qE '"schema_version".*"agents-md-fleet-propagation/v1.doctor"' \
   && ! printf '%s' "$out" | grep -qE 'jq:.*Argument list too long'; then
  pass "doctor --json envelope under large ledger; no jq-arglist error"
else
  fail "doctor --json under large ledger"
  printf '%s\n' "$out" | head -3 >&2
fi

# Test 2: audit --json with large ledger
out="$(AGENTS_MD_FLEET_LEDGER="$LEDGER" "$SCRIPT" audit --json 2>&1)"
if printf '%s' "$out" | grep -qE '"schema_version".*"agents-md-fleet-propagation/v1.audit"' \
   && ! printf '%s' "$out" | grep -qE 'jq:.*Argument list too long'; then
  pass "audit --json envelope under large ledger; no jq-arglist error"
else
  fail "audit --json under large ledger"
  printf '%s\n' "$out" | head -3 >&2
fi

# Test 3: validate ledger --json with large ledger
out="$(AGENTS_MD_FLEET_LEDGER="$LEDGER" "$SCRIPT" validate ledger --json 2>&1)"
if printf '%s' "$out" | grep -qE '"schema_version".*"agents-md-fleet-propagation/v1.validate"' \
   && ! printf '%s' "$out" | grep -qE 'jq:.*Argument list too long'; then
  pass "validate ledger --json envelope under large ledger; no jq-arglist error"
else
  fail "validate ledger --json under large ledger"
  printf '%s\n' "$out" | head -3 >&2
fi

# Test 4: why <id> --json with large ledger (search for a known ledger repo)
out="$(AGENTS_MD_FLEET_LEDGER="$LEDGER" "$SCRIPT" why "/Users/josh/Developer/sample-flywheel-fleet-repo-with-longer-path-name-002500" --json 2>&1)"
if printf '%s' "$out" | grep -qE '"schema_version".*"agents-md-fleet-propagation/v1.why"' \
   && ! printf '%s' "$out" | grep -qE 'jq:.*Argument list too long'; then
  pass "why <id> --json envelope under large ledger; no jq-arglist error"
else
  fail "why <id> --json under large ledger"
  printf '%s\n' "$out" | head -3 >&2
fi

# Test 5: rows_total in audit envelope matches our synthetic ledger size
rows_total="$(AGENTS_MD_FLEET_LEDGER="$LEDGER" "$SCRIPT" audit --json 2>/dev/null | jq -r '.ledger_rows_total')"
if [[ "$rows_total" == "5000" ]]; then
  pass "audit ledger_rows_total == 5000 (slurpfile reads complete ledger)"
else
  fail "audit ledger_rows_total == 5000 (got: $rows_total)"
fi

# Test 6: no leftover tmpfiles after script exits (trap cleanup verification)
# The script's EXIT trap should clean up its fw_jq_arg_file tmpfiles.
# Count current fleet-prop-rows-named tmpfiles (should be 0 immediately after run).
sleep 0.5
leftover="$(find "$TMPDIR" -maxdepth 2 -name 'fleet-prop-rows.*' -mmin -1 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$leftover" == "0" ]]; then
  pass "no leftover fleet-prop-rows.* tmpfiles after script exits (trap cleanup)"
else
  fail "leftover fleet-prop-rows.* tmpfiles after exit: $leftover"
fi

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
