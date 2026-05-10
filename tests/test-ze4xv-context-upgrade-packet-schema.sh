#!/usr/bin/env bash
# tests/test-ze4xv-context-upgrade-packet-schema.sh
#
# Regression test for flywheel-ze4xv (cohort precondition AG4: jq schema
# validator for skillos.context_upgrade_packet.session_start.v1).
#
# Asserts every packet under HOME/.local/state/flywheel/sessions/<id>/
# carries the canonical schema_version, an ISO8601 generated_at, and a
# canonical_write_path field whose value matches its actual file path.
# Acts as forward-protection: any future producer regression that drops
# schema_version or emits malformed generated_at will trip this test.
#
# AG2 cohort floor: requires at least 5 distinct sessions to have packets.
set -euo pipefail

SESSIONS_ROOT="${SESSIONS_ROOT:-$HOME/.local/state/flywheel/sessions}"
EXPECTED_SCHEMA_VERSION="${EXPECTED_SCHEMA_VERSION:-skillos.context_upgrade_packet.session_start.v1}"
COHORT_FLOOR="${COHORT_FLOOR:-5}"

pass(){ printf 'PASS %s\n' "$1"; }
fail(){ printf 'FAIL %s\n' "$1" >&2; exit 1; }

[[ -d "$SESSIONS_ROOT" ]] || fail "sessions root absent: $SESSIONS_ROOT"

# 1. Cohort floor: ≥5 distinct context_upgrade_packet.json files
PACKETS=()
while IFS= read -r p; do PACKETS+=("$p"); done < <(find "$SESSIONS_ROOT" -name 'context_upgrade_packet.json' 2>/dev/null | sort)
COUNT="${#PACKETS[@]}"
[[ "$COUNT" -ge "$COHORT_FLOOR" ]] \
  || fail "cohort floor not met: need >=$COHORT_FLOOR packets, found $COUNT"
pass "cohort floor met ($COUNT packets >= floor=$COHORT_FLOOR)"

# 2. Each packet is valid JSON
for p in "${PACKETS[@]}"; do
  jq empty "$p" 2>/dev/null \
    || fail "packet not valid JSON: $p"
done
pass "all $COUNT packets are valid JSON"

# 3. Each packet declares canonical schema_version
for p in "${PACKETS[@]}"; do
  ACTUAL=$(jq -r '.schema_version // "missing"' "$p")
  [[ "$ACTUAL" == "$EXPECTED_SCHEMA_VERSION" ]] \
    || fail "packet $p schema_version=$ACTUAL (expected $EXPECTED_SCHEMA_VERSION)"
done
pass "all $COUNT packets declare schema_version=$EXPECTED_SCHEMA_VERSION"

# 4. Each packet has ISO8601 generated_at (Z-suffix, second-precision)
for p in "${PACKETS[@]}"; do
  jq -e '.generated_at | type == "string" and test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$")' "$p" >/dev/null \
    || fail "packet $p missing or malformed generated_at: $(jq -r '.generated_at // "missing"' "$p")"
done
pass "all $COUNT packets carry ISO8601 generated_at (Z-suffix, second-precision)"

# 5. Each packet's canonical_write_path matches its actual file path
for p in "${PACKETS[@]}"; do
  CANONICAL=$(jq -r '.canonical_write_path // "missing"' "$p")
  [[ "$CANONICAL" == "$p" ]] \
    || fail "packet $p canonical_write_path mismatch: declared=$CANONICAL actual=$p"
done
pass "all $COUNT packets self-identify with matching canonical_write_path"

# 6. Each packet declares hook_version (semver-ish)
for p in "${PACKETS[@]}"; do
  jq -e '.hook_version | type == "string" and test("^[0-9]+\\.[0-9]+\\.[0-9]+$")' "$p" >/dev/null \
    || fail "packet $p hook_version missing or non-semver: $(jq -r '.hook_version // "missing"' "$p")"
done
pass "all $COUNT packets declare semver hook_version"

# 7. Each packet declares candidate_count (non-negative integer)
for p in "${PACKETS[@]}"; do
  jq -e '.candidate_count | type == "number" and . >= 0' "$p" >/dev/null \
    || fail "packet $p candidate_count missing or negative: $(jq -r '.candidate_count // "missing"' "$p")"
done
pass "all $COUNT packets declare non-negative candidate_count"

# 8. Cardinality: distinct sessions cover the live tmux session set (best-effort)
DISTINCT_SESSIONS=$(printf '%s\n' "${PACKETS[@]}" | xargs -n1 dirname | xargs -n1 basename | sort -u | wc -l | tr -d ' ')
[[ "$DISTINCT_SESSIONS" -ge "$COHORT_FLOOR" ]] \
  || fail "distinct sessions ($DISTINCT_SESSIONS) below cohort floor ($COHORT_FLOOR)"
pass "distinct sessions count >=cohort floor ($DISTINCT_SESSIONS sessions: $(printf '%s\n' "${PACKETS[@]}" | xargs -n1 dirname | xargs -n1 basename | sort -u | tr '\n' ',' | sed 's/,$//'))"

printf 'flywheel-ze4xv context-upgrade-packet schema test passed (8 assertions, %d packets validated)\n' "$COUNT"
