#!/usr/bin/env bash
# tests/peer-orch-respawn-permit-canonical-cli-test.sh
#
# Regression test for flywheel-vsv4i (Phase 4 of agent-ergonomics-cli-max).
# Asserts canonical-CLI flag suite on .flywheel/scripts/peer-orch-respawn-permit.sh:
# --help, -h, --info, --schema, --examples each emit content + exit 0.
# Also verifies the existing subcommand surface (schema, examples, info) still works.

set -euo pipefail

TOOL="${TOOL:-/Users/josh/Developer/flywheel/.flywheel/scripts/peer-orch-respawn-permit.sh}"

[[ -x "$TOOL" ]] || { echo "FAIL tool missing or not executable: $TOOL" >&2; exit 1; }

pass(){ printf 'PASS %s\n' "$1"; }
fail(){ printf 'FAIL %s\n' "$1" >&2; exit 1; }

# 1. bash -n syntax check
bash -n "$TOOL" && pass "bash -n syntax-clean" || fail "bash -n failed on $TOOL"

# 2. each canonical flag exits 0 with content
for flag in --help -h --info --schema --examples; do
  set +e
  out=$("$TOOL" "$flag" 2>&1)
  rc=$?
  set -e
  [[ "$rc" -eq 0 ]] || fail "$flag exited rc=$rc (expected 0)"
  [[ -n "$out" ]] || fail "$flag emitted no content"
done
pass "all 5 canonical flags (--help, -h, --info, --schema, --examples) exit 0 with content"

# 3. --schema emits the canonical schema_version
"$TOOL" --schema | jq -e '.schema_version == "peer-orch-respawn-permit/v1"' >/dev/null \
  || fail "--schema output missing schema_version=peer-orch-respawn-permit/v1"
pass "--schema emits schema_version=peer-orch-respawn-permit/v1"

# 4. --schema flag matches schema subcommand (functional equivalence)
diff <("$TOOL" --schema) <("$TOOL" schema) >/dev/null \
  || fail "--schema flag and schema subcommand emit different output"
pass "--schema flag and schema subcommand are byte-equivalent"

# 5. --examples flag matches examples subcommand
diff <("$TOOL" --examples) <("$TOOL" examples) >/dev/null \
  || fail "--examples flag and examples subcommand emit different output"
pass "--examples flag and examples subcommand are byte-equivalent"

# 6. --info flag still works (was pre-existing)
"$TOOL" --info | jq -e '.name == "peer-orch-respawn-permit"' >/dev/null \
  || fail "--info output missing name=peer-orch-respawn-permit"
pass "--info emits name=peer-orch-respawn-permit (pre-existing surface preserved)"

# 7. unknown flag still rejected with usage
set +e
"$TOOL" --no-such-flag 2>&1 >/dev/null
rc=$?
set -e
[[ "$rc" -eq 2 ]] || fail "unknown flag rejected with rc=$rc (expected 2 = usage error)"
pass "unknown flag rejected with rc=2"

# 8. --help mentions all canonical flags + subcommands
help_out="$("$TOOL" --help)"
for needle in -- "--help" "health" "doctor" "schema" "examples" "--info"; do
  grep -qF -- "$needle" <<<"$help_out" || fail "--help missing required text: $needle"
done
pass "--help names all canonical flags + subcommands"

printf 'peer-orch-respawn-permit canonical-CLI parity test passed (8 assertions)\n'
