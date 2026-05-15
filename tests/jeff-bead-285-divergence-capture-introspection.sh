#!/usr/bin/env bash
# tests/jeff-bead-285-divergence-capture-introspection.sh
# Bead flywheel-f23ix: regression coverage for the capture-harness shape
# (canonical-cli-scoping triad + Jeffrey's exact RUST_LOG ask + receipt
# schema). The harness fires on a live br_close divergence and bundles
# the artifacts Jeffrey requested in beads_rust#285.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TARGET="${CAPTURE_HARNESS_PATH:-$ROOT/.flywheel/scripts/jeff-bead-285-divergence-capture.sh}"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: substrate exists + bash -n passes
if [[ -x "$TARGET" ]] && bash -n "$TARGET" 2>/dev/null; then
  pass "capture harness exists + bash -n ok"
else
  fail "capture harness missing or syntax-broken at $TARGET"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

# Test 2: --info envelope shape (canonical-cli-scoping --info contract)
INFO_JSON="$("$TARGET" --info 2>/dev/null || true)"
if jq -e '
  .schema_version == "tool-info/v1"
  and .name == "jeff-bead-285-divergence-capture.sh"
  and .upstream_issue == "https://github.com/Dicklesworthstone/beads_rust/issues/285"
  and .tracking_bead == "flywheel-f23ix"
  and .default_mode == "dry-run"
  and .mutates == true
  and (.mutation_requires | index("--apply")) != null
  and (.flags | index("doctor")) != null
  and .doctor_schema == "jeff-bead-285-divergence-capture.doctor.v1"
  and (.rust_log_targets | index("br::storage::sqlite=trace")) != null
  and (.rust_log_targets | index("br::cli::commands::close=trace")) != null
  and (.exit_codes | has("0") and has("1") and has("2") and has("3"))
' >/dev/null 2>&1 <<<"$INFO_JSON"; then
  pass "--info envelope has tool-info/v1 + upstream + RUST_LOG targets + exit codes"
else
  fail "--info envelope shape regressed; got: ${INFO_JSON:0:200}"
fi

# Test 3: --schema emits jeff-bead-285-capture-receipt/v1 JSON Schema
SCHEMA_JSON="$("$TARGET" --schema 2>/dev/null || true)"
if jq -e '
  .schema_version == "jeff-bead-285-capture-receipt/v1"
  and .type == "object"
  and (.required | index("ts")) != null
  and (.required | index("mode")) != null
  and (.required | index("bead_id")) != null
  and (.required | index("capture_dir")) != null
  and (.properties.divergence_observed.type == "boolean")
  and (.properties.mode.enum | index("apply")) != null
  and (.properties.mode.enum | index("dry-run")) != null
' >/dev/null 2>&1 <<<"$SCHEMA_JSON"; then
  pass "--schema emits jeff-bead-285-capture-receipt/v1 JSON Schema"
else
  fail "--schema envelope regressed; got: ${SCHEMA_JSON:0:200}"
fi

# Test 4: doctor emits read-only prerequisite envelope without bead-id
DOCTOR_JSON="$("$TARGET" doctor 2>/dev/null || true)"
if jq -e '
  .schema_version == "jeff-bead-285-divergence-capture.doctor.v1"
  and .command == "doctor"
  and (.status | IN("pass","warn","fail"))
  and .mode == "read_only"
  and .mutates == false
  and (.checks | length == 4)
  and ([.checks[] | select(.name == "lock_timeout_positive_integer").status][0] == "pass")
' >/dev/null 2>&1 <<<"$DOCTOR_JSON"; then
  pass "doctor emits read-only prerequisite envelope without bead-id"
else
  fail "doctor envelope regressed; got: ${DOCTOR_JSON:0:200}"
fi

# Test 5: invalid lock timeout is a doctor fail, not a jq crash
BAD_TIMEOUT_DOCTOR="$(DEFAULT_LOCK_TIMEOUT_MS=not-a-number "$TARGET" --doctor 2>/dev/null || true)"
if jq -e '
  .schema_version == "jeff-bead-285-divergence-capture.doctor.v1"
  and .status == "fail"
  and ([.checks[] | select(.name == "lock_timeout_positive_integer").status][0] == "fail")
' >/dev/null 2>&1 <<<"$BAD_TIMEOUT_DOCTOR"; then
  pass "doctor fails cleanly for invalid lock timeout"
else
  fail "doctor invalid timeout handling regressed; got: ${BAD_TIMEOUT_DOCTOR:0:200}"
fi

# Test 6: --examples cites the canonical Jeffrey ask + sandbox warning
EXAMPLES="$("$TARGET" --examples 2>/dev/null || true)"
if grep -Fq -- "--info" <<<"$EXAMPLES" \
  && grep -Fq -- "doctor" <<<"$EXAMPLES" \
  && grep -Fq -- "--apply" <<<"$EXAMPLES" \
  && grep -Fq -- "--lock-timeout 10000" <<<"$EXAMPLES" \
  && grep -Fq -- "DEFAULT_LOCK_TIMEOUT_MS" <<<"$EXAMPLES"; then
  pass "--examples cites Jeffrey's lock-timeout 10000 ask + env var override"
else
  fail "--examples missing Jeffrey ask or env var override"
fi

# Test 7: missing bead-id exits rc=2 (canonical-cli-scoping usage error)
set +e
"$TARGET" --apply >/dev/null 2>&1
rc=$?
set -e
if [[ "$rc" -eq 2 ]]; then
  pass "missing bead-id exits with rc=2 (canonical-cli-scoping usage error)"
else
  fail "missing bead-id exit code mismatch (expected 2, got $rc)"
fi

# Test 8: dry-run is the default + does NOT mutate state
DRY_BEAD="test-bead-$(date -u +%s)"
DRY_OUTPUT="$("$TARGET" "$DRY_BEAD" --json 2>/dev/null || true)"
if jq -e '
  .mode == "dry-run"
  and (.bead_id | startswith("test-bead-"))
  and .divergence_observed == false
' >/dev/null 2>&1 <<<"$DRY_OUTPUT"; then
  pass "dry-run is default; emits receipt without mutating"
else
  fail "default mode regressed; got: ${DRY_OUTPUT:0:200}"
fi

# Test 9: capture script does NOT contain a push to upstream / no auto-comment
# (Jeffrey-restraint: artifacts are bundled locally; operator decides when/if to upload)
if grep -qE 'gh issue (comment|reopen)|git push|curl.*github.com.*beads_rust' "$TARGET"; then
  fail "capture script contains upstream-push verbs — Jeffrey-restraint violated"
else
  pass "capture script bundles artifacts locally; no auto-push to upstream"
fi

# Test 10: tracking-bead linkage in source (audit trail)
if grep -q "flywheel-f23ix" "$TARGET" \
  && grep -q "Dicklesworthstone/beads_rust/issues/285" "$TARGET"; then
  pass "tracking-bead + upstream issue both cited in source comments"
else
  fail "missing tracking-bead or upstream issue citation"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
