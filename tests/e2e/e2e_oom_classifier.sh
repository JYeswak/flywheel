#!/usr/bin/env bash
# E2E sweep: classifier across all 4 stuck subclasses (capacity-halt, queued-not-submitted,
# frozen-pane/buffer-stuck, oom-killed-pane). Asserts the new oom_killed_pane subclass is
# wired without regressing the three sibling classes.
#
# Bead: flywheel-codex-oom-killed-subclass-2026-05-06
# Mission anchor: 80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DETECTOR="$ROOT/.flywheel/scripts/codex-template-stuck-detector.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/e2e-oom-classifier.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_subclass() {
  local fixture_arg="$1" expected_subclass="$2" expected_recovery="$3" label="$4"
  local out err rc
  out="$TMP/${label}.out"
  err="$TMP/${label}.err"
  set +e
  $DETECTOR $fixture_arg --dry-run --json >"$out" 2>"$err"
  rc=$?
  set -e
  if jq -e --arg sc "$expected_subclass" --arg rec "$expected_recovery" \
      '.panes[0].subclass == $sc and .panes[0].recommended_recovery == $rec' \
      "$out" >/dev/null; then
    pass "$label (subclass=$expected_subclass recovery=$expected_recovery rc=$rc)"
  else
    fail "$label expected subclass=$expected_subclass recovery=$expected_recovery"
    jq . "$out" >&2 || cat "$out" >&2
    cat "$err" >&2 || true
  fi
}

# 1. capacity-halt sibling fixture (existing, must not regress)
assert_subclass \
  "--fixture $ROOT/.flywheel/tests/fixtures/capacity-halt-live" \
  "model_at_capacity_halt" \
  "auto_continue" \
  "capacity_halt_no_regression"

# 2. queued-not-submitted via JSON fixture with subclass_hint
cat >"$TMP/queued.json" <<'EOF'
{
  "schema_version": "codex-stuck-detector.fixture.v1",
  "session": "flywheel",
  "pane": 2,
  "subclass_hint": "codex_queued_not_submitted",
  "t0": "Working (3m 12s · esc to interrupt)\n›  please continue\n",
  "t1": "Working (3m 18s · esc to interrupt)\n›  please continue\n"
}
EOF
assert_subclass \
  "--fixture $TMP/queued.json" \
  "codex_queued_not_submitted" \
  "bare_enter" \
  "queued_not_submitted_no_regression"

# 3. buffer_stuck via JSON fixture with subclass_hint
cat >"$TMP/buffer.json" <<'EOF'
{
  "schema_version": "codex-stuck-detector.fixture.v1",
  "session": "flywheel",
  "pane": 3,
  "subclass_hint": "buffer_stuck",
  "t0": "› Implement {feature}\n",
  "t1": "› Implement {feature}\n"
}
EOF
assert_subclass \
  "--fixture $TMP/buffer.json" \
  "buffer_stuck" \
  "enter_newline_then_respawn_if_still_stuck" \
  "buffer_stuck_no_regression"

# 4. oom_killed_pane (new) — directory fixture with t0/t1
assert_subclass \
  "--fixture $ROOT/tests/fixtures/oom_killed" \
  "oom_killed_pane" \
  "respawn" \
  "oom_killed_pane_classified"

# 5. oom_killed_pane via subclass_hint (defensive)
cat >"$TMP/oom_hint.json" <<'EOF'
{
  "schema_version": "codex-stuck-detector.fixture.v1",
  "session": "flywheel",
  "pane": 4,
  "subclass_hint": "oom_killed_pane",
  "t0": "Working (1m 0s · esc to interrupt)\nKilled\n",
  "t1": "Working (1m 0s · esc to interrupt)\nKilled\n"
}
EOF
assert_subclass \
  "--fixture $TMP/oom_hint.json" \
  "oom_killed_pane" \
  "respawn" \
  "oom_killed_pane_via_hint"

# 6. oom_killed_pane signature without hint (regex-only path)
cat >"$TMP/oom_signature.json" <<'EOF'
{
  "schema_version": "codex-stuck-detector.fixture.v1",
  "session": "flywheel",
  "pane": 5,
  "t0": "Some output\nOut of memory: Killed process 12345 (codex)\n[Process completed]\n",
  "t1": "Some output\nOut of memory: Killed process 12345 (codex)\n[Process completed]\n"
}
EOF
assert_subclass \
  "--fixture $TMP/oom_signature.json" \
  "oom_killed_pane" \
  "respawn" \
  "oom_killed_pane_via_signature"

printf '\nE2E classifier sweep: %s passed, %s failed\n' "$pass_count" "$fail_count"
if [[ "$fail_count" -eq 0 ]]; then
  echo "PASS: e2e_oom_classifier — all 4 subclasses classified, no regression"
  exit 0
fi
exit 1
