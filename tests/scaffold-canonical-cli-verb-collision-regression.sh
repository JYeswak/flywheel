#!/usr/bin/env bash
# tests/scaffold-canonical-cli-verb-collision-regression.sh
#
# Regression test for flywheel-sacan: scaffold-canonical-cli.sh detects when
# the target's own case-statement already handles canonical verbs
# (validate|why|doctor|health|repair|audit) and emits a flag-based bypass
# in the early-dispatch intercept so cmd_run still receives per-target
# invocations (e.g. `<target> validate --bead-id X`).
#
# Surfaced by 1fk5f.3 + 1fk5f.6 hand-edits — this makes the fix automatic
# at scaffold time.
#
# Two paths exercised:
#   1. No-collision target (no canonical verbs in case-statement) →
#      simple intercept (no bypass loop), receipt verb_collision_detected=false
#   2. Collision target (has validate|doctor|repair case arms with --bead-id
#      flag) → bypass-aware intercept with the per-target flag, receipt
#      verb_collision_detected=true + colliding_verbs + bypass_flags lists

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCAFFOLDER="$ROOT/.flywheel/scripts/scaffold-canonical-cli.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if [[ ! -x "$SCAFFOLDER" ]]; then
  fail "scaffolder not executable: $SCAFFOLDER"
  exit 1
fi

WORK_TMP="$(mktemp -d -t scaffold-verb-collision-regression.XXXXXX)" || { fail "mktemp failed"; exit 1; }
trap 'rm -rf "$WORK_TMP" 2>/dev/null || true' EXIT

# ---------- Path 1: no-collision target ----------

NO_COLLIDE="$WORK_TMP/no-collision-fixture.sh"
cat > "$NO_COLLIDE" <<'EOF'
#!/usr/bin/env bash
echo "no-collision fixture; no canonical verbs in case-statement"
exit 0
EOF
chmod +x "$NO_COLLIDE"

set +e
NO_COLLIDE_RESULT="$("$SCAFFOLDER" "$NO_COLLIDE" --json --allow-uninventoried 2>/dev/null)"
nc_rc=$?
set -e

if [[ "$nc_rc" -eq 0 ]]; then
  pass "no-collision: scaffolder rc=0"
else
  fail "no-collision: rc=$nc_rc (expected 0)"
fi

# Verify receipt fields
if echo "$NO_COLLIDE_RESULT" | jq -e '.receipt.verb_collision_detected == false' >/dev/null 2>&1; then
  pass "no-collision: receipt verb_collision_detected=false"
else
  fail "no-collision: verb_collision_detected not false"
fi

if echo "$NO_COLLIDE_RESULT" | jq -e '.receipt.colliding_verbs | length == 0' >/dev/null 2>&1; then
  pass "no-collision: receipt colliding_verbs is empty"
else
  fail "no-collision: colliding_verbs not empty"
fi

# Verify the emitted intercept does NOT contain a bypass loop
NC_DIFF="$(echo "$NO_COLLIDE_RESULT" | jq -r '.unified_diff_path')"
NC_SCAFFOLDED="$(dirname "$NC_DIFF")/$(basename "$NO_COLLIDE").scaffolded"
if grep -q 'VERB COLLISION BYPASS' "$NC_SCAFFOLDED" 2>/dev/null; then
  fail "no-collision: emitted intercept contains bypass loop (should not)"
else
  pass "no-collision: emitted intercept does NOT contain bypass loop"
fi

# ---------- Path 2: collision target with --bead-id flag ----------

COLLIDE="$WORK_TMP/collision-fixture.sh"
cat > "$COLLIDE" <<'EOF'
#!/usr/bin/env bash
# Fixture has its own case-statement handling canonical verbs PLUS uses
# --bead-id as a per-target flag.
case "${1:-}" in
  validate)
    shift
    while [[ $# -gt 0 ]]; do
      case "$1" in --bead-id) BEAD_ID="$2"; shift 2 ;; *) shift ;; esac
    done
    echo "validate $BEAD_ID"
    ;;
  doctor)
    echo "doctor"
    ;;
  repair)
    echo "repair"
    ;;
  audit)
    echo "audit"
    ;;
  *)
    echo "usage"
    ;;
esac
EOF
chmod +x "$COLLIDE"

set +e
COLLIDE_RESULT="$("$SCAFFOLDER" "$COLLIDE" --json --allow-uninventoried 2>/dev/null)"
c_rc=$?
set -e

if [[ "$c_rc" -eq 0 ]]; then
  pass "collision: scaffolder rc=0"
else
  fail "collision: rc=$c_rc (expected 0)"
fi

# Verify receipt fields
if echo "$COLLIDE_RESULT" | jq -e '.receipt.verb_collision_detected == true' >/dev/null 2>&1; then
  pass "collision: receipt verb_collision_detected=true"
else
  fail "collision: verb_collision_detected not true"
fi

# colliding_verbs should include validate, doctor, repair, audit (4 of 7 canonical)
N_COLLIDING="$(echo "$COLLIDE_RESULT" | jq '.receipt.colliding_verbs | length')"
if [[ "$N_COLLIDING" -ge 3 ]]; then
  pass "collision: receipt colliding_verbs has $N_COLLIDING entries (>=3)"
else
  fail "collision: colliding_verbs has only $N_COLLIDING entries"
fi

# bypass_flags should include --bead-id
if echo "$COLLIDE_RESULT" | jq -e '.receipt.bypass_flags | any(. == "--bead-id")' >/dev/null 2>&1; then
  pass "collision: receipt bypass_flags includes --bead-id"
else
  fail "collision: bypass_flags missing --bead-id"
fi

# Verify the emitted intercept DOES contain a bypass loop
C_DIFF="$(echo "$COLLIDE_RESULT" | jq -r '.unified_diff_path')"
C_SCAFFOLDED="$(dirname "$C_DIFF")/$(basename "$COLLIDE").scaffolded"
if grep -q 'VERB COLLISION BYPASS' "$C_SCAFFOLDED" 2>/dev/null; then
  pass "collision: emitted intercept contains bypass header"
else
  fail "collision: emitted intercept does NOT contain bypass header"
fi

if grep -q 'for _a in "\$@"' "$C_SCAFFOLDED" 2>/dev/null; then
  pass "collision: emitted intercept contains bypass argv-scan loop"
else
  fail "collision: emitted intercept does NOT contain bypass loop"
fi

if grep -q -- '--bead-id) return 1' "$C_SCAFFOLDED" 2>/dev/null; then
  pass "collision: emitted intercept yields when --bead-id is in argv"
else
  fail "collision: emitted intercept does NOT yield on --bead-id"
fi

# ---------- Behavioral assertion: emitted bypass-aware intercept actually defers to cmd_run ----------

# When we apply the scaffolded version and invoke `validate --bead-id X`,
# the intercept must yield → cmd_run handles it → output is "validate X".
set +e
APPLY_RESULT="$("$SCAFFOLDER" "$COLLIDE" --apply --idempotency-key=sacan-regression --json --allow-uninventoried 2>/dev/null)"
ap_rc=$?
set -e

if [[ "$ap_rc" -eq 0 ]]; then
  pass "collision-apply: scaffolder rc=0 (mutation applied)"
else
  fail "collision-apply: rc=$ap_rc"
fi

# Now invoke the SCAFFOLDED collision fixture with `validate --bead-id Y`
chmod +x "$COLLIDE"
ACTUAL_OUT="$("$COLLIDE" validate --bead-id ZED 2>/dev/null)"
if [[ "$ACTUAL_OUT" == "validate ZED" ]]; then
  pass "collision-apply: scaffolded target's 'validate --bead-id ZED' reaches cmd_run (output: $ACTUAL_OUT)"
else
  fail "collision-apply: 'validate --bead-id ZED' produced '$ACTUAL_OUT' (expected 'validate ZED'; intercept did not yield)"
fi

# And when invoked WITHOUT --bead-id, the canonical intercept SHOULD fire
# (scaffolded surface emits canonical envelope for validate)
SCAFFOLD_OUT="$("$COLLIDE" validate 2>/dev/null)"
if echo "$SCAFFOLD_OUT" | jq -e '.command == "validate"' >/dev/null 2>&1; then
  pass "collision-apply: 'validate' alone (no per-target flag) reaches scaffold canonical surface"
else
  fail "collision-apply: 'validate' alone produced '$SCAFFOLD_OUT' (expected canonical envelope)"
fi

# ---------- Summary ----------

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
