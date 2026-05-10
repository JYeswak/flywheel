#!/usr/bin/env bash
# tests/inventory-beads-xargs-portability.sh
# Bead flywheel-9s6df: macOS/BSD xargs portability fixture for the
# beads-compliance-and-completion-verification skill's
# scripts/inventory-beads.sh. Proves the GNU-only `xargs -d` line
# fails on BSD xargs AND the proposed `tr '\n' '\0' | xargs -0`
# replacement works on both BSD and GNU.
#
# This fixture lives in flywheel because the upstream skill is
# JSM-managed; the patched-shape copy is exercised here without
# mutating ~/.claude/skills/beads-compliance-and-completion-verification.
# The `jsm-push-ready` patch artifact lives at
# .flywheel/audit/flywheel-9s6df/inventory-beads.jsm-push-ready.patch.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SKILL_HOOK="${BCV_INVENTORY_BEADS_SH:-$HOME/.claude/skills/beads-compliance-and-completion-verification/scripts/inventory-beads.sh}"
PATCH="${BCV_INVENTORY_BEADS_PATCH:-$ROOT/.flywheel/audit/flywheel-9s6df/inventory-beads.jsm-push-ready.patch}"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/inventory-beads-xargs-portability.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: BSD xargs (system /usr/bin/xargs on macOS) rejects -d.
# This documents the bug class so a future regression on a Linux box that
# loses BSD-compat is caught.
if [[ "$(uname -s)" == "Darwin" ]]; then
  if ! /usr/bin/xargs -d '\n' echo <<<'x' >/dev/null 2>&1; then
    pass "macOS /usr/bin/xargs rejects -d (bug class confirmed)"
  else
    fail "expected /usr/bin/xargs -d to fail on macOS, but it succeeded"
  fi
else
  pass "non-Darwin host; /usr/bin/xargs -d bug class probe skipped (uname=$(uname -s))"
fi

# Test 2: portable shape (tr -> xargs -0) works on this host
PORTABLE_OUT="$(printf 'line1\nline2 with space\nline3\n' | tr '\n' '\0' | xargs -0 -I {} echo "got: {}" | sort)"
EXPECTED='got: line1
got: line2 with space
got: line3'
if [[ "$PORTABLE_OUT" == "$EXPECTED" ]]; then
  pass "tr | xargs -0 preserves newline-record-boundary on this host"
else
  fail "portable xargs -0 output mismatch (got: $(printf '%q' "$PORTABLE_OUT"))"
fi

# Test 3: live skill script still has the bug (until JSM push lands)
if [[ -r "$SKILL_HOOK" ]]; then
  if grep -q "xargs -d '\\\\n'" "$SKILL_HOOK"; then
    pass "live skill copy still carries 'xargs -d (GNU-only)' (waiting on JSM push)"
  else
    if grep -q "xargs -0" "$SKILL_HOOK" && ! grep -q "xargs -d" "$SKILL_HOOK"; then
      pass "live skill copy already migrated to xargs -0 (JSM push landed)"
    else
      fail "live skill copy in unexpected state — neither the GNU bug nor the BSD-portable fix detected"
    fi
  fi
else
  fail "live skill script not readable at $SKILL_HOOK"
fi

# Tests 4-5: patched-shape verification.
# Behavior depends on live skill state (per flywheel-2z7b8 patch landing 2026-05-09):
#   - Pre-patch live (xargs -d): apply patch to a copy + verify canonical post-patch shape
#   - Post-patch live (xargs -0): verify the live skill already carries the canonical
#     post-patch shape (apply-and-compare would reverse the already-applied patch)
if [[ -r "$PATCH" ]]; then
  mkdir -p "$TMP/verify/scripts"
  if grep -q "xargs -d '\\\\n'" "$SKILL_HOOK"; then
    # Pre-patch live state: apply patch to a fresh copy + verify
    cp "$SKILL_HOOK" "$TMP/verify/scripts/inventory-beads.sh"
    if (cd "$TMP/verify" && patch --silent -p1 < "$PATCH" 2>/dev/null) \
      && bash -n "$TMP/verify/scripts/inventory-beads.sh"; then
      pass "patched copy applies cleanly and passes bash -n (live still pre-patch)"
    else
      fail "patched copy failed to apply or bash -n (live still pre-patch)"
    fi
    if [[ -r "$TMP/verify/scripts/inventory-beads.sh" ]]; then
      if grep -q "xargs -0 -P" "$TMP/verify/scripts/inventory-beads.sh" \
        && ! grep -q "xargs -d" "$TMP/verify/scripts/inventory-beads.sh"; then
        pass "patched copy uses xargs -0 and drops xargs -d"
      else
        fail "patched copy did not migrate to xargs -0"
      fi
    else
      fail "patched copy not produced at $TMP/verify/scripts/inventory-beads.sh"
    fi
  else
    # Post-patch live state: verify live carries canonical post-patch shape
    if bash -n "$SKILL_HOOK"; then
      pass "live skill (post-patch) passes bash -n"
    else
      fail "live skill (post-patch) failed bash -n"
    fi
    if grep -q "xargs -0 -P" "$SKILL_HOOK" \
      && ! grep -q "xargs -d" "$SKILL_HOOK"; then
      pass "live skill (post-patch) carries xargs -0 and drops xargs -d (canonical post-patch shape)"
    else
      fail "live skill in unexpected state — neither pre-patch nor canonical post-patch shape"
    fi
  fi
else
  fail "jsm-push-ready patch not readable at $PATCH"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
