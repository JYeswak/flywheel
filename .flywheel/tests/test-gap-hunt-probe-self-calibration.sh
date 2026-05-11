#!/usr/bin/env bash
# test-gap-hunt-probe-self-calibration.sh
#
# Regression test for flywheel-faqj2: gap-hunt-probe-self-calibration.sh
# emits structured JSON proposals for 5 finding types.
#
# Tests:
#   - Canonical CLI surfaces (--info, --schema, --doctor, --examples)
#   - Default --json mode emits finding objects with required fields
#   - --apply mode appends to ledger
#   - Each finding has finding_type + severity + details + proposal

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/scripts/gap-hunt-probe-self-calibration.sh"

PASS=0; FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1" >&2; }

TMP="$(mktemp -d -t ghpsc.XXXXXX)" || { echo "ERR: mktemp failed" >&2; exit 1; }
LEDGER="$TMP/test-runs.jsonl"
SNAPSHOT="$TMP/test-snapshot.json"

# AG1: --info emits introspection envelope with expected fields
info_out="$("$PROBE" --info --json 2>/dev/null)"
if jq -e '.schema_version == "gap-hunt-probe-self-calibration/v1" and (.finding_types | length == 5) and .read_only == true' <<<"$info_out" >/dev/null; then
  pass "01 --info envelope has schema_version + 5 finding_types + read_only=true"
else
  fail "01 --info envelope: $(jq -c '{schema_version,finding_types_len:(.finding_types|length),read_only}' <<<"$info_out")"
fi

# AG2: --schema emits schema envelope
schema_out="$("$PROBE" --schema --json 2>/dev/null)"
if jq -e '.command == "schema" and (.severity_levels | length == 3)' <<<"$schema_out" >/dev/null; then
  pass "02 --schema envelope has command=schema and 3 severity levels"
else
  fail "02 --schema envelope: $(jq -c '{command,severity_levels}' <<<"$schema_out")"
fi

# AG3: --doctor emits pass when probe exists
doctor_out="$("$PROBE" --doctor --json 2>/dev/null)"
if jq -e '.command == "doctor" and .status == "pass"' <<<"$doctor_out" >/dev/null; then
  pass "03 --doctor returns status=pass"
else
  fail "03 --doctor: $(jq -c '{command,status}' <<<"$doctor_out")"
fi

# AG4: --examples emits 3 example invocations
examples_out="$("$PROBE" --examples --json 2>/dev/null)"
if jq -e '.examples | length >= 3' <<<"$examples_out" >/dev/null; then
  pass "04 --examples emits >=3 example invocations"
else
  fail "04 --examples: $(jq -c '{examples}' <<<"$examples_out")"
fi

# AG5: default --json mode emits well-formed findings
default_out="$("$PROBE" --json 2>/dev/null)"
if jq -e '.schema_version == "gap-hunt-probe-self-calibration/v1" and (.findings | type) == "array" and (.summary.by_severity | type) == "object"' <<<"$default_out" >/dev/null; then
  pass "05 default --json mode emits well-formed top-level envelope"
else
  fail "05 default: $(jq -c '{schema_version,findings_type:(.findings|type),summary_type:(.summary|type)}' <<<"$default_out")"
fi

# AG6: each finding has finding_type + severity + details + proposal
all_findings_well_formed="$(jq -r '.findings | all(has("finding_type") and has("severity") and has("details") and has("proposal"))' <<<"$default_out")"
if [[ "$all_findings_well_formed" == "true" ]]; then
  pass "06 every finding has finding_type + severity + details + proposal"
else
  fail "06 finding shape: at least one finding missing required field; $(jq -c '.findings[0] | keys' <<<"$default_out")"
fi

# AG7: --apply appends to ledger + writes snapshot
GAP_HUNT_SELF_CALIB_LEDGER="$LEDGER" \
GAP_HUNT_SELF_CALIB_SNAPSHOT="$SNAPSHOT" \
"$PROBE" --apply --json 2>/dev/null > /dev/null
if [[ -s "$LEDGER" ]]; then
  pass "07 --apply appends row to ledger ($LEDGER)"
else
  fail "07 --apply did not write to ledger"
fi
if [[ -s "$SNAPSHOT" ]]; then
  pass "08 --apply writes snapshot ($SNAPSHOT)"
else
  fail "08 --apply did not write snapshot"
fi

# AG9: severity values are info / warn / alert
all_severities_valid="$(jq -r '.findings | all(.severity == "info" or .severity == "warn" or .severity == "alert")' <<<"$default_out")"
if [[ "$all_severities_valid" == "true" ]]; then
  pass "09 all finding severities are info|warn|alert"
else
  fail "09 invalid severity value found: $(jq -c '[.findings[].severity]' <<<"$default_out")"
fi

if [[ "$FAIL" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$PASS" "$FAIL" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$PASS"
