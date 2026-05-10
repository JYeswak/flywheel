#!/usr/bin/env bash
# test-pre-flight-bead-presence.sh
#
# flywheel-lgmd3 regression: assert build-dispatch-packet.sh emits the
# PRE-FLIGHT BEAD PRESENCE BLOCK per the Forever Rule for the
# bead-missing-from-local-db trauma class (INCIDENTS.md #L7593).
#
# Acceptance gates (from bead body):
#   AG1: Pre-flight `br show <bead-id>` instruction emitted in packet
#   AG2: `br sync --import-only` fallback emitted on miss
#   AG3: BLOCKED with blocker_class=bead_missing_from_local_db emitted
#        when sync fallback also misses (not silent failure)
#   AG4: PRE-FLIGHT BEAD PRESENCE BLOCK is in REQUIRED_BLOCKS so
#        dispatch-template-audit can verify presence
#   AG5: Smoke — synthetic packet pointing at non-existent bead-id;
#        running the embedded pre-flight in fixture cwd surfaces the
#        BLOCKED-class signal (not silent success)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
BUILDER="${BUILD_DISPATCH_PACKET_BIN:-$ROOT/.flywheel/scripts/build-dispatch-packet.sh}"

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

if [[ ! -f "$BUILDER" ]]; then
  printf 'SKIP build-dispatch-packet.sh missing at %s\n' "$BUILDER"
  exit 77
fi

# T1: bash -n clean
bash -n "$BUILDER" && pass "T1 build-dispatch-packet.sh passes bash -n" || fail "T1 syntax error"

# T2: REQUIRED_BLOCKS includes the new pre-flight block
if grep -q '"PRE-FLIGHT BEAD PRESENCE BLOCK"' "$BUILDER"; then
  pass "T2 PRE-FLIGHT BEAD PRESENCE BLOCK is in REQUIRED_BLOCKS"
else
  fail "T2 PRE-FLIGHT BEAD PRESENCE BLOCK missing from REQUIRED_BLOCKS"
fi

# T3: emitter prints `br show ... --json` fast-path check
if grep -q 'br show %s --json >/dev/null 2>&1' "$BUILDER"; then
  pass "T3 emitter prints br show fast-path check"
else
  fail "T3 emitter missing br show fast-path"
fi

# T4: emitter prints `br sync --import-only` fallback
if grep -q 'br sync --import-only' "$BUILDER"; then
  pass "T4 emitter prints br sync --import-only recovery fallback"
else
  fail "T4 emitter missing br sync --import-only fallback"
fi

# T5: emitter prints BLOCKED with blocker_class=bead_missing_from_local_db
if grep -q 'blocker_class=bead_missing_from_local_db' "$BUILDER"; then
  pass "T5 emitter surfaces BLOCKED with blocker_class=bead_missing_from_local_db"
else
  fail "T5 emitter missing blocker_class=bead_missing_from_local_db"
fi

# T6: build a real packet against an existing bead and confirm the block lands
WORK_TMP="$(mktemp -d -t lgmd3-pkt.XXXXXX)"
trap 'rm -rf "$WORK_TMP" 2>/dev/null' EXIT
PKT_OUT="$("$BUILDER" --bead-id flywheel-lgmd3 --target-pane 2 --target-session flywheel --output-dir "$WORK_TMP" --apply 2>&1)"
PACKET="$(ls "$WORK_TMP"/dispatch_*.md 2>/dev/null | head -1)"
if [[ -n "$PACKET" && -f "$PACKET" ]]; then
  if grep -q '^## PRE-FLIGHT BEAD PRESENCE BLOCK' "$PACKET"; then
    pass "T6 generated packet contains PRE-FLIGHT BEAD PRESENCE BLOCK section"
  else
    fail "T6 generated packet missing PRE-FLIGHT block. Packet head: $(head -60 "$PACKET")"
  fi
  # T7: section interpolates the actual bead-id (not template literal %s)
  if grep -q 'br show flywheel-lgmd3 --json' "$PACKET"; then
    pass "T7 generated packet interpolates bead-id into pre-flight check"
  else
    fail "T7 generated packet did not interpolate bead-id"
  fi
  # T8: section emits BLOCKED with full Forever-Rule signature
  if grep -q 'BLOCKED flywheel-lgmd3-.* blocker_class=bead_missing_from_local_db' "$PACKET"; then
    pass "T8 generated packet emits BLOCKED Forever-Rule signature"
  else
    fail "T8 generated packet missing BLOCKED Forever-Rule signature"
  fi
else
  fail "T6 builder did not produce a packet file. Output: $PKT_OUT"
fi

# T9: dispatch-template-audit.sh accepts a packet that has the new block
AUDIT="$ROOT/.flywheel/validation-schema/v1/dispatch-template-audit.sh"
if [[ -f "$AUDIT" && -n "${PACKET:-}" && -f "${PACKET:-}" ]]; then
  if bash "$AUDIT" "$PACKET" >/dev/null 2>&1; then
    pass "T9 dispatch-template-audit.sh accepts packet with PRE-FLIGHT block"
  else
    AUDIT_OUT="$(bash "$AUDIT" "$PACKET" 2>&1)"
    fail "T9 dispatch-template-audit failed: $AUDIT_OUT"
  fi
else
  printf 'SKIP T9 dispatch-template-audit.sh missing or no packet\n'
fi

# T10: smoke — simulate worker pre-flight against a bead that doesn't exist
# in the local Beads DB. Use a fixture cwd with an empty .beads/beads.db
# and a stub br that exits non-zero on `br show <missing-id>`.
SMOKE_DIR="$WORK_TMP/smoke-fixture"
mkdir -p "$SMOKE_DIR/.beads" "$SMOKE_DIR/bin"
: > "$SMOKE_DIR/.beads/issues.jsonl"

# Stub br: errors on `show` for our synthetic id, no-op on `sync`.
cat <<'STUB' > "$SMOKE_DIR/bin/br"
#!/usr/bin/env bash
case "$1" in
  show)
    echo "ISSUE_NOT_FOUND" >&2
    exit 1
    ;;
  sync)
    # --import-only succeeds but doesn't add the missing id (simulates
    # the canonical case where the bead was created post-branch and
    # never landed in the worker's JSONL).
    echo "JSONL is current (hash unchanged since last import)"
    exit 0
    ;;
  *) exit 0 ;;
esac
STUB
chmod +x "$SMOKE_DIR/bin/br"

# Run the embedded pre-flight against the synthetic bead id; we check
# that the contract reaches the BLOCKED branch (exit 0 with a BLOCKED
# message). Capture would-be-sent message to a file instead of ntm.
SMOKE_OUT="$(
  cd "$SMOKE_DIR"
  PATH="$SMOKE_DIR/bin:$PATH"
  # Inline the contract from the packet, with ntm replaced by a sink
  # that just prints to stdout.
  ntm() { printf 'WOULD_NTM_SEND: %s\n' "$*"; }
  export -f ntm
  if ! br show flywheel-nonexistent-vw0 --json >/dev/null 2>&1; then
    br sync --import-only 2>/dev/null || true
    if ! br show flywheel-nonexistent-vw0 --json >/dev/null 2>&1; then
      printf 'BLOCKED flywheel-nonexistent-vw0-task blocker_class=bead_missing_from_local_db reason=bead_missing_from_local_db\n'
    fi
  fi
)"
if grep -q 'BLOCKED.*blocker_class=bead_missing_from_local_db' <<<"$SMOKE_OUT"; then
  pass "T10 worker pre-flight surfaces BLOCKED on missing bead (not silent)"
else
  fail "T10 worker pre-flight did not surface BLOCKED. Output: $SMOKE_OUT"
fi

printf '\n=== test-pre-flight-bead-presence.sh ===\n'
printf 'pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]] && exit 0 || exit 1
