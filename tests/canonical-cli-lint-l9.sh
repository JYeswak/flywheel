#!/usr/bin/env bash
# tests/canonical-cli-lint-l9.sh
# Regression for canonical-cli-lint L9 rule (apply-side-effect-before-gate).
#
# Bead: flywheel-ldp0a. Reference: m12ji audit + hoqq8 fix-diff.
# Invariant: a side-effect inside `if [[ "$mode" == "apply" ]]` must be
# preceded by an apply-key gate (cli_refuse_apply_without_idem_key) in
# the SAME function. If gate is in a different function or missing,
# L9 flags the side-effect.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
LINT="$ROOT/.flywheel/scripts/canonical-cli-lint.sh"
FIXTURE_DIR="$ROOT/tests/fixtures/canonical-cli-lint-l9"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

TMPDIR_TEST="$(mktemp -d -t canonical-cli-lint-l9.XXXXXX)"
trap '[[ -n "${TMPDIR_TEST:-}" ]] && rm -rf "$TMPDIR_TEST"' EXIT

# Test 1: bash -n on the lint script itself
if bash -n "$LINT" 2>/dev/null; then pass "lint script syntax"; else fail "lint script syntax"; fi

# Test 2: L9 listed in --info rules
if "$LINT" --info | jq -e '.rules | map(.id) | index("L9") != null' >/dev/null; then
  pass "L9 listed in --info rules"
else fail "L9 not in --info rules"; fi

# Test 3: L9 listed in --schema rule enum
if "$LINT" --schema | jq -e '.properties.violations.items.properties.rule.enum | index("L9") != null' >/dev/null; then
  pass "L9 in schema rule enum"
else fail "L9 not in schema rule enum"; fi

# Test 4: dirty fixture flags L9 (canonical trauma shape)
if [[ ! -e "$FIXTURE_DIR/dirty.sh" ]] || [[ ! -e "$FIXTURE_DIR/clean.sh" ]]; then
  fail "fixture files missing"
  exit 1
fi
out="$("$LINT" "$FIXTURE_DIR/dirty.sh" --rule L9 --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '.status == "violations" and (.violations | length) >= 1' >/dev/null; then
  pass "dirty fixture flags L9 violations"
else fail "dirty fixture did not flag L9: $(printf '%s' "$out" | jq -c '{status, count: (.violations | length)}')"; fi

# Test 5: dirty fixture violations carry rule=L9 + severity=error
if printf '%s' "$out" | jq -e 'all(.violations[]; .rule == "L9" and .severity == "error" and (.line | type == "number"))' >/dev/null; then
  pass "dirty fixture violations carry rule=L9 + severity=error + line:number"
else fail "dirty fixture violation shape: $(printf '%s' "$out" | jq -c '.violations[0]')"; fi

# Test 6: clean fixture stays clean (gate hoisted above side-effects)
if "$LINT" "$FIXTURE_DIR/clean.sh" --rule L9 --json 2>/dev/null | jq -e '.status == "clean" and (.violations | length) == 0' >/dev/null; then
  pass "clean fixture stays clean"
else fail "clean fixture flagged: $("$LINT" "$FIXTURE_DIR/clean.sh" --rule L9 --json | jq -c '.violations')"; fi

# Test 7: --rule filter — L9 alone returns only L9 violations
out="$("$LINT" "$FIXTURE_DIR/dirty.sh" --rule L9 --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '[.violations[].rule] | unique | (. == ["L9"])' >/dev/null; then
  pass "--rule L9 filter returns only L9 violations"
else fail "--rule L9 leaked other rules: $(printf '%s' "$out" | jq -c '[.violations[].rule] | unique')"; fi

# Test 8: rc=1 on violations (canonical exit-code taxonomy)
"$LINT" "$FIXTURE_DIR/dirty.sh" --rule L9 --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 1 ]]; then
  pass "rc=1 on L9 violations"
else fail "dirty fixture rc=$rc (expected 1)"; fi

# Test 9: rc=0 on clean
"$LINT" "$FIXTURE_DIR/clean.sh" --rule L9 --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 0 ]]; then
  pass "rc=0 on clean"
else fail "clean fixture rc=$rc"; fi

# Test 10: text mode emits human-readable violation lines
out="$("$LINT" "$FIXTURE_DIR/dirty.sh" --rule L9 2>/dev/null)"
if printf '%s' "$out" | grep -qE ':[0-9]+: L9 \[apply-side-effect-before-gate'; then
  pass "text mode emits file:line: L9 [...] shape"
else fail "text mode shape: $(printf '%s' "$out" | head -1)"; fi

# Test 11: function-scope discrimination — gate in OTHER function does NOT cover
# the SE in this function. Construct a fixture where a gate exists in helper()
# but the side-effect is in scaffold().
cat > "$TMPDIR_TEST/cross-func.sh" <<'EOF'
#!/usr/bin/env bash
# flywheel-cli-surface: true
set -euo pipefail
mode="${1:-dry-run}"
idem_key="${2:-}"

helper() {
  # Gate in a different function — must NOT cover scaffold's SE
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    cli_refuse_apply_without_idem_key "schema/v1" "helper" ""
  fi
}

scaffold() {
  # Apply-block + SE with NO gate in this function — must flag
  if [[ "$mode" == "apply" ]]; then
    mkdir -p "$HOME/.local/state/cross-func-fixture"
    cp /etc/hosts "$HOME/.local/state/cross-func-fixture/copy"
  fi
}

scaffold
EOF
out="$("$LINT" "$TMPDIR_TEST/cross-func.sh" --rule L9 --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '.status == "violations" and (.violations | length) >= 1 and (.violations[0].message | test("scope=scaffold"))' >/dev/null; then
  pass "cross-function gate does NOT cover other-function SE"
else fail "cross-function test: $(printf '%s' "$out" | jq -c '{status, count: (.violations | length), msg: .violations[0].message}')"; fi

# Test 12: tmp-path side-effects are EXCLUDED (not flagged)
cat > "$TMPDIR_TEST/tmp-only.sh" <<'EOF'
#!/usr/bin/env bash
# flywheel-cli-surface: true
set -euo pipefail
mode="${1:-dry-run}"
idem_key="${2:-}"

scaffold() {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  if [[ "$mode" == "apply" ]]; then
    # Only tmp-path writes; not real side-effects
    mkdir -p "$tmp_dir/staging"
    cp /etc/hosts "$tmp_dir/staging/copy"
    echo "data" > "$tmp_dir/staging/out"
    if [[ -z "$idem_key" ]]; then
      cli_refuse_apply_without_idem_key "schema/v1" "scaffold" ""
    fi
  fi
}
scaffold
EOF
if "$LINT" "$TMPDIR_TEST/tmp-only.sh" --rule L9 --json 2>/dev/null | jq -e '.status == "clean" and (.violations | length) == 0' >/dev/null; then
  pass "tmp-path side-effects excluded (no false positives)"
else fail "tmp-path file flagged: $("$LINT" "$TMPDIR_TEST/tmp-only.sh" --rule L9 --json | jq -c .)"; fi

# Test 13: gate via emitted refusal envelope (not via helper call) — should still
# be recognized as a gate.
cat > "$TMPDIR_TEST/envelope-gate.sh" <<'EOF'
#!/usr/bin/env bash
# flywheel-cli-surface: true
set -euo pipefail
mode="${1:-dry-run}"
idem_key="${2:-}"

scaffold() {
  if [[ "$mode" == "apply" ]]; then
    if [[ -z "$idem_key" ]]; then
      # Inline refusal envelope (instead of cli_refuse_apply_without_idem_key)
      printf '{"status":"refused","reason":"--apply requires --idempotency-key"}\n'
      exit 3
    fi
    mkdir -p "$HOME/.local/state/envelope-gate-fixture"
  fi
}
scaffold
EOF
if "$LINT" "$TMPDIR_TEST/envelope-gate.sh" --rule L9 --json 2>/dev/null | jq -e '.status == "clean" and (.violations | length) == 0' >/dev/null; then
  pass "inline refusal envelope recognized as gate"
else fail "inline refusal flagged: $("$LINT" "$TMPDIR_TEST/envelope-gate.sh" --rule L9 --json | jq -c .violations[0])"; fi

# Test 14: file with NO apply logic is clean (L7 handles that case)
cat > "$TMPDIR_TEST/no-apply.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
# Pure read-only surface — no --apply, no mutation
ls "$HOME/.local/state" 2>/dev/null || true
EOF
if "$LINT" "$TMPDIR_TEST/no-apply.sh" --rule L9 --json 2>/dev/null | jq -e '.status == "clean" and (.violations | length) == 0' >/dev/null; then
  pass "no-apply-logic file is clean"
else fail "no-apply file flagged"; fi

# Test 15: hoqq8 canonical pre-fix shape (the trauma class L9 was authored
# to prevent). Reconstruct via `git show 533d45e^`.
if git -C "$ROOT" show 533d45e^:.flywheel/scripts/scaffold-canonical-cli.sh > "$TMPDIR_TEST/scaffold-pre-fix.sh" 2>/dev/null && [[ -s "$TMPDIR_TEST/scaffold-pre-fix.sh" ]]; then
  out="$("$LINT" "$TMPDIR_TEST/scaffold-pre-fix.sh" --rule L9 --json 2>/dev/null)"
  if printf '%s' "$out" | jq -e '.status == "violations" and (.violations | length) >= 1' >/dev/null; then
    pass "hoqq8 pre-fix scaffold-canonical-cli.sh flagged (trauma class caught)"
  else fail "hoqq8 pre-fix shape NOT caught — load-bearing miss: $(printf '%s' "$out" | jq -c '{status, count: (.violations|length)}')"; fi
else
  # If commit hash drifts (e.g., rebased), skip rather than fail
  pass "hoqq8 pre-fix probe skipped (git history shape changed)"
fi

# Test 16: hoqq8 post-fix scaffold-canonical-cli.sh stays clean (gate hoisted)
out="$("$LINT" "$ROOT/.flywheel/scripts/scaffold-canonical-cli.sh" --rule L9 --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '.status == "clean" and (.violations | length) == 0' >/dev/null; then
  pass "hoqq8 post-fix scaffold-canonical-cli.sh stays clean"
else fail "post-fix scaffold flagged: $(printf '%s' "$out" | jq -c '.violations[]' | head -2)"; fi

# Test 17: full repo scan finds 0 L9 violations (m12ji baseline)
out="$("$LINT" --scan-all --rule L9 --json 2>/dev/null)"
n="$(printf '%s' "$out" | jq -r '.violations | length')"
if [[ "$n" -eq 0 ]]; then
  pass "full repo scan: 0 L9 violations (m12ji preventive baseline)"
else
  files="$(printf '%s' "$out" | jq -r '[.violations[].file] | unique | join(", ")')"
  fail "full repo scan: $n L9 violations across files: $files"
fi

# Test 18: --rule L1,L9 selects both rules
out="$("$LINT" "$FIXTURE_DIR/dirty.sh" --rule L1,L9 --json 2>/dev/null)"
rules_seen="$(printf '%s' "$out" | jq -r '[.violations[].rule] | unique | join(",")')"
if [[ "$rules_seen" == "L9" ]] || [[ "$rules_seen" == "L1,L9" ]] || [[ "$rules_seen" == "L9,L1" ]]; then
  pass "--rule L1,L9 selects only L1+L9 (no L2-L8 leak)"
else fail "--rule L1,L9 saw rules: $rules_seen"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
