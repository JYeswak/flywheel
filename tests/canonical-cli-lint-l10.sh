#!/usr/bin/env bash
# Regression test for flywheel-9dace (final 7axmt deliverable): L10 rule on
# canonical-cli-lint.sh — flags surfaces with --apply paired with mutation
# patterns but no --idempotency-key gate. The 7 surfaces fixed by sister
# beads (8sx9w, 1o9fa, j0xpa, j99xb, mfy7u, y0ft6, wdh08) must all PASS L10.
# Pre-fix-shape fixtures must all FAIL L10.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/canonical-cli-lint.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/l10-test.XXXXXX")"
trap 'find "$TMP" -type f -delete 2>/dev/null; find "$TMP" -type d -depth -empty -delete 2>/dev/null; true' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: L10 listed in --info rules
if "$SCRIPT" --info 2>/dev/null | jq -e '.rules[] | select(.id == "L10" and .label == "apply-mutation-needs-key")' >/dev/null 2>&1; then
  pass "AG1: --info lists L10 with label apply-mutation-needs-key"
else fail "AG1: L10 not in --info"; fi

# Test 2: L10 in --schema enum
if "$SCRIPT" --schema 2>/dev/null | jq -e '.properties.violations.items.properties.rule.enum | contains(["L10"])' >/dev/null 2>&1; then
  pass "AG2: --schema rule enum includes L10"
else fail "AG2: L10 missing from schema enum"; fi

# Test 3: pre-fix-shape fixture (git commit + apply, no key) → L10 fires
cat >"$TMP/pre-fix-git-commit.sh" <<'FIX'
#!/usr/bin/env bash
# flywheel-cli-surface: true
set -euo pipefail
APPLY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    *) shift ;;
  esac
done
if [[ "$APPLY" -eq 1 ]]; then
  git commit -m "install hooks"
  git push origin main
fi
FIX
set +e
"$SCRIPT" "$TMP/pre-fix-git-commit.sh" --rule L10 --json >"$TMP/pre-fix-git.json" 2>&1
rc=$?
set +e
if [[ "$rc" -eq 1 ]] && jq -e '.violations[] | select(.rule == "L10")' "$TMP/pre-fix-git.json" >/dev/null 2>&1; then
  pass "AG3: git-commit pre-fix-shape → L10 fires (rc=1)"
else fail "AG3: L10 did not catch git-commit pre-fix-shape (rc=$rc)"; fi

# Test 4: pre-fix-shape fixture (ntm send + apply, no key) → L10 fires
cat >"$TMP/pre-fix-ntm-send.sh" <<'FIX'
#!/usr/bin/env bash
# flywheel-cli-surface: true
set -euo pipefail
APPLY=0
while [[ $# -gt 0 ]]; do
  case "$1" in --apply) APPLY=1; shift ;; *) shift ;; esac
done
if [[ "$APPLY" -eq 1 ]]; then
  ntm send flywheel --pane=2 "ping"
fi
FIX
set +e
"$SCRIPT" "$TMP/pre-fix-ntm-send.sh" --rule L10 --json >"$TMP/pre-fix-ntm.json" 2>&1
rc=$?
set +e
if [[ "$rc" -eq 1 ]] && jq -e '.violations[] | select(.rule == "L10")' "$TMP/pre-fix-ntm.json" >/dev/null 2>&1; then
  pass "AG4: ntm-send pre-fix-shape → L10 fires"
else fail "AG4: L10 did not catch ntm-send pre-fix-shape (rc=$rc)"; fi

# Test 5: pre-fix-shape fixture (br update + apply, no key) → L10 fires
cat >"$TMP/pre-fix-br-update.sh" <<'FIX'
#!/usr/bin/env bash
# flywheel-cli-surface: true
set -euo pipefail
APPLY=0
while [[ $# -gt 0 ]]; do
  case "$1" in --apply) APPLY=1; shift ;; *) shift ;; esac
done
if [[ "$APPLY" -eq 1 ]]; then
  br update bd-test --priority 0
fi
FIX
set +e
"$SCRIPT" "$TMP/pre-fix-br-update.sh" --rule L10 --json >"$TMP/pre-fix-br.json" 2>&1
rc=$?
set +e
if [[ "$rc" -eq 1 ]] && jq -e '.violations[] | select(.rule == "L10")' "$TMP/pre-fix-br.json" >/dev/null 2>&1; then
  pass "AG5: br-update pre-fix-shape → L10 fires"
else fail "AG5: L10 did not catch br-update pre-fix-shape (rc=$rc)"; fi

# Test 6: post-fix-shape (apply + idempotency-key + git commit) → L10 SILENT
cat >"$TMP/post-fix.sh" <<'FIX'
#!/usr/bin/env bash
# flywheel-cli-surface: true
set -euo pipefail
APPLY=0
IDEMPOTENCY_KEY=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --idempotency-key) IDEMPOTENCY_KEY="$2"; shift 2 ;;
    *) shift ;;
  esac
done
if [[ "$APPLY" -eq 1 && -z "$IDEMPOTENCY_KEY" ]]; then exit 3; fi
if [[ "$APPLY" -eq 1 ]]; then
  git commit -m "install"
fi
FIX
set +e
"$SCRIPT" "$TMP/post-fix.sh" --rule L10 --json >"$TMP/post-fix.json" 2>&1
rc=$?
set +e
if [[ "$rc" -eq 0 ]]; then
  pass "AG6: post-fix-shape (apply + idempotency-key) → L10 silent (rc=0)"
else fail "AG6: L10 false-positive on post-fix-shape (rc=$rc)"; fi

# Test 7: exemption marker apply_not_supported → L10 silent
cat >"$TMP/exempt-apply-not-supported.sh" <<'FIX'
#!/usr/bin/env bash
# flywheel-cli-surface: true
set -euo pipefail
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) fail_json 3 "apply_not_supported_read_only_bridge"; exit 3 ;;
    *) shift ;;
  esac
done
# This surface never actually mutates under --apply (refuses early).
git commit -m "this line exists in comments/docs but apply path refuses"
FIX
set +e
"$SCRIPT" "$TMP/exempt-apply-not-supported.sh" --rule L10 --json >"$TMP/exempt-apply.json" 2>&1
rc=$?
set +e
if [[ "$rc" -eq 0 ]]; then
  pass "AG7: apply_not_supported exemption → L10 silent"
else fail "AG7: L10 false-positive on apply_not_supported exemption (rc=$rc)"; fi

# Test 8: exemption marker IDEMPOTENT-BY-CONSTRUCTION → L10 silent
cat >"$TMP/exempt-idempotent.sh" <<'FIX'
#!/usr/bin/env bash
# flywheel-cli-surface: true
# IDEMPOTENT-BY-CONSTRUCTION: mutation is atomic-replace via os.replace + content-sha dedup
set -euo pipefail
APPLY=0
while [[ $# -gt 0 ]]; do
  case "$1" in --apply) APPLY=1; shift ;; *) shift ;; esac
done
if [[ "$APPLY" -eq 1 ]]; then
  git commit -m "atomic-replace-only"
fi
FIX
set +e
"$SCRIPT" "$TMP/exempt-idempotent.sh" --rule L10 --json >"$TMP/exempt-idem.json" 2>&1
rc=$?
set +e
if [[ "$rc" -eq 0 ]]; then
  pass "AG8: IDEMPOTENT-BY-CONSTRUCTION exemption → L10 silent"
else fail "AG8: L10 false-positive on IDEMPOTENT-BY-CONSTRUCTION exemption (rc=$rc)"; fi

# Test 9: NO --apply at all → L10 silent (rule requires --apply to fire)
cat >"$TMP/no-apply.sh" <<'FIX'
#!/usr/bin/env bash
set -euo pipefail
echo "no apply flag here"
git commit -m "but mutation pattern exists"
FIX
set +e
"$SCRIPT" "$TMP/no-apply.sh" --rule L10 --json >"$TMP/no-apply.json" 2>&1
rc=$?
set +e
if [[ "$rc" -eq 0 ]]; then
  pass "AG9: no --apply present → L10 silent (no-mutation-without-apply)"
else fail "AG9: L10 false-positive when --apply absent (rc=$rc)"; fi

# Test 10: --apply but NO mutation patterns → L10 silent (e.g., read-only flag)
cat >"$TMP/apply-readonly.sh" <<'FIX'
#!/usr/bin/env bash
# flywheel-cli-surface: true
set -euo pipefail
APPLY=0
while [[ $# -gt 0 ]]; do
  case "$1" in --apply) APPLY=1; shift ;; *) shift ;; esac
done
if [[ "$APPLY" -eq 1 ]]; then
  echo "apply mode: emitting a fresh receipt; no real mutation"
fi
FIX
set +e
"$SCRIPT" "$TMP/apply-readonly.sh" --rule L10 --json >"$TMP/apply-readonly.json" 2>&1
rc=$?
set +e
if [[ "$rc" -eq 0 ]]; then
  pass "AG10: --apply without mutation patterns → L10 silent (read-only --apply)"
else fail "AG10: L10 false-positive on read-only --apply (rc=$rc)"; fi

# Test 11: all 7 freshly-fixed sister surfaces PASS L10 (regression guard)
sister_fail=0
for s in sync-canonical-doctrine.sh stale-error-auto-ping.sh security-precommit-installer.sh regenerate-dicklesworthstone-sources.sh hub-blocker-detect.sh bcv-task-harness.sh jeff-bead-285-divergence-capture.sh; do
  if ! "$SCRIPT" "$ROOT/.flywheel/scripts/$s" --rule L10 --json >/dev/null 2>&1; then
    sister_fail=$((sister_fail + 1))
  fi
done
if [[ "$sister_fail" -eq 0 ]]; then
  pass "AG11: all 7 7axmt-followup sister surfaces PASS L10 (regression guard)"
else fail "AG11: $sister_fail/7 sister surfaces failed L10 (regression)"; fi

# Test 12: violation message names the mutation pattern that triggered the catch
if jq -e '.violations[] | select(.rule == "L10") | .message | test("git commit")' "$TMP/pre-fix-git.json" >/dev/null 2>&1; then
  pass "AG12: L10 violation message names the triggering mutation pattern"
else fail "AG12: L10 violation message lacks mutation pattern details"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
