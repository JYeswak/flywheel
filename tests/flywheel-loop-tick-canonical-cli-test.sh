#!/usr/bin/env bash
# tests/flywheel-loop-tick-canonical-cli-test.sh
#
# Regression test for flywheel-dfe0m (Phase 4 of agent-ergonomics-cli-max).
# Asserts the canonical-CLI introspection surface on .flywheel/flywheel-loop-tick:
# --help, --info, --schema, --examples each emit content + exit 0.

set -euo pipefail

TICK="${TICK:-<flywheel-repo>/.flywheel/flywheel-loop-tick}"

[[ -x "$TICK" ]] || { echo "FAIL tick driver missing or not executable: $TICK" >&2; exit 1; }

pass(){ printf 'PASS %s\n' "$1"; }
fail(){ printf 'FAIL %s\n' "$1" >&2; exit 1; }

# 1. bash -n syntax check
bash -n "$TICK" && pass "bash -n syntax-clean" || fail "bash -n failed on $TICK"

# 2. allow-large receipt cited (tick-driver is intentionally oversized)
grep -q "canonical-cli-scoping-allow-large" "$TICK" \
  && pass "allow-large receipt cited" \
  || fail "allow-large receipt missing"

# 3-6. each introspection flag emits content + exits 0
for flag_pair in "--help:1" "--info:1" "--schema:1" "--examples:1" "-h:1"; do
  flag="${flag_pair%:*}"
  set +e
  out=$("$TICK" "$flag" 2>&1)
  rc=$?
  set -e
  [[ "$rc" -eq 0 ]] || fail "$flag exited rc=$rc (expected 0)"
  [[ -n "$out" ]] || fail "$flag emitted no content"
done
pass "all 5 introspection invocations (--help, -h, --info, --schema, --examples) exit 0 with content"

# 7. --schema emits valid JSON Schema (draft-07)
"$TICK" --schema | jq -e '
  .["$schema"] == "http://json-schema.org/draft-07/schema#"
  and .title == "flywheel-loop-tick.last_run"
  and .type == "object"
  and (.required | type == "array")
  and (.properties.status.enum | index("sent"))
' >/dev/null || fail "--schema output is not a valid draft-07 schema for flywheel-loop-tick.last_run"
pass "--schema emits valid JSON Schema with required title/type/required/status enum"

# 8. --help mentions all 4 introspection flags + key env vars + exit codes
help_out="$("$TICK" --help)"
for needle in -- "--help" "--info" "--schema" "--examples" "REPO" "SESSION" "TARGET_PANE" "Exit codes" "canonical-cli-scoping"; do
  grep -qF -- "$needle" <<<"$help_out" || fail "--help missing required text: $needle"
done
pass "--help mentions all 4 introspection flags + key env vars + exit codes + skill citation"

# 9. --info names the launchd plist label + dispatch-log path
info_out="$("$TICK" --info)"
grep -qF -- "ai.zeststream.flywheel-flywheel-loop" <<<"$info_out" \
  || fail "--info missing launchd plist label"
grep -qF -- "ntm-coordinator-pinned" <<<"$info_out" \
  || fail "--info missing ntm-coordinator-pinned reference"
pass "--info names plist label + ntm-coordinator-pinned"

# 10. --examples gives at least 5 invocation patterns
examples_out="$("$TICK" --examples)"
example_count="$(grep -c '^flywheel-loop-tick\|^FLYWHEEL_\|^jq \|^tail ' <<<"$examples_out")"
[[ "$example_count" -ge 5 ]] || fail "--examples has $example_count invocation patterns (expected >= 5)"
pass "--examples has $example_count invocation patterns"

printf 'flywheel-loop-tick canonical-CLI parity test passed (10 assertions)\n'
