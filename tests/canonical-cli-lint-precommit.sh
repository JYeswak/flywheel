#!/usr/bin/env bash
# tests/canonical-cli-lint-precommit.sh
# Integration regression for canonical-cli-lint pre-commit wire-in.
#
# Bead: flywheel-f0e77. Acceptance:
#   - Dirty fixture commits are blocked
#   - Clean fixture commits pass
#   - --no-verify bypasses
#
# Strategy: isolated tmp git repo + symlink to repo's linter + chain
# script + hook. Drives `git commit` directly (with hooks enabled) and
# observes pass/fail.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
LINTER="$ROOT/.flywheel/scripts/canonical-cli-lint.sh"
CHAIN_SCRIPT="$ROOT/.flywheel/hooks/pre-commit-chain.sh"
PRECOMMIT_HOOK="$ROOT/.flywheel/hooks/canonical-cli-lint-pre-commit.sh"
INSTALLER="$ROOT/.flywheel/scripts/canonical-cli-lint-precommit-installer.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

TMPREPO="$(mktemp -d -t canonical-cli-lint-precommit.XXXXXX)"
trap '[[ -n "${TMPREPO:-}" ]] && find "$TMPREPO" -mindepth 1 -delete 2>/dev/null; rmdir "$TMPREPO" 2>/dev/null' EXIT

# Build an isolated tmp git repo with the linter + hooks symlinked in.
# The hook script reads from a path relative to the repo's --show-toplevel,
# so we mirror the .flywheel/ layout.
build_tmprepo() {
  (
    cd "$TMPREPO"
    git init -q
    git config user.email "test@example.com"
    git config user.name "test"
    git config commit.gpgsign false 2>/dev/null || true
    # Override any global core.hooksPath so the tmprepo's .git/hooks fires.
    # Without this, a global hooksPath setting on the host machine swallows
    # our hook silently and tests pass+fail meaninglessly.
    git config --local core.hooksPath .git/hooks

    mkdir -p .flywheel/scripts .flywheel/hooks tests/fixtures
    cp "$LINTER" .flywheel/scripts/canonical-cli-lint.sh
    cp "$PRECOMMIT_HOOK" .flywheel/hooks/canonical-cli-lint-pre-commit.sh
    cp "$CHAIN_SCRIPT" .flywheel/hooks/pre-commit-chain.sh
    chmod +x .flywheel/scripts/canonical-cli-lint.sh \
             .flywheel/hooks/canonical-cli-lint-pre-commit.sh \
             .flywheel/hooks/pre-commit-chain.sh

    # Wire the chain into .git/hooks/pre-commit directly (simpler than
    # going through security-precommit-installer for this test). This
    # is equivalent to the installer's net effect.
    mkdir -p .git/hooks
    cat > .git/hooks/pre-commit <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"
exec "$REPO_ROOT/.flywheel/hooks/pre-commit-chain.sh"
EOF
    chmod +x .git/hooks/pre-commit

    # Seed a base commit (without staged surface files, so the hook
    # has nothing to lint and the commit succeeds).
    echo "seed" > README.md
    git add README.md
    git commit -q -m "init" 2>&1 | head -3 >/dev/null
  )
}

# Helper: stage a file with content and try to commit. Captures rc.
commit_attempt() {
  local file_rel="$1" content="$2" commit_msg="$3"
  local extra_args="${4:-}"
  (
    cd "$TMPREPO"
    mkdir -p "$(dirname "$file_rel")"
    printf '%s' "$content" > "$file_rel"
    git add "$file_rel"
    if [[ -n "$extra_args" ]]; then
      # shellcheck disable=SC2086
      git commit -q $extra_args -m "$commit_msg" 2>&1
    else
      git commit -q -m "$commit_msg" 2>&1
    fi
  )
}

# Helper: check that HEAD's last commit message is the expected one.
last_commit_msg() {
  (cd "$TMPREPO" && git log -1 --pretty=%s)
}

# Helper: count commits in HEAD.
commit_count() {
  (cd "$TMPREPO" && git rev-list --count HEAD)
}

# Helper: unstage everything (used to reset between tests).
unstage_all() {
  (cd "$TMPREPO" && git reset -q HEAD -- .) 2>/dev/null || true
}

# --- TESTS ---

# Test 1: prerequisites exist + executable
if [[ -x "$LINTER" ]] && [[ -x "$CHAIN_SCRIPT" ]] && [[ -x "$PRECOMMIT_HOOK" ]] && [[ -x "$INSTALLER" ]]; then
  pass "all 4 substrate scripts exist + executable"
else
  fail "missing substrate (linter=$([[ -x "$LINTER" ]] && echo y || echo n) chain=$([[ -x "$CHAIN_SCRIPT" ]] && echo y || echo n) hook=$([[ -x "$PRECOMMIT_HOOK" ]] && echo y || echo n) installer=$([[ -x "$INSTALLER" ]] && echo y || echo n))"
  exit 1
fi

# Test 2: installer --info / --examples / --schema all emit canonical envelopes
if "$INSTALLER" --info | jq -e '.schema_version and .modes and .chain_config_key' >/dev/null \
   && "$INSTALLER" --examples | jq -e '.examples | type == "array" and length >= 4' >/dev/null \
   && "$INSTALLER" --schema | jq -e '."$defs".envelope' >/dev/null; then
  pass "installer --info/--examples/--schema canonical"
else fail "installer introspection"; fi

# Test 3: installer doctor reports ok for substrate
out="$("$INSTALLER" doctor --json)"
if printf '%s' "$out" | jq -e '
  ([.checks[] | select(.check == "linter").status] | .[0] == "ok") and
  ([.checks[] | select(.check == "chain_dispatcher").status] | .[0] == "ok") and
  ([.checks[] | select(.check == "canonical_cli_pre_commit").status] | .[0] == "ok")
' >/dev/null; then
  pass "installer doctor: linter+chain+hook all ok"
else fail "doctor: $(printf '%s' "$out" | jq -c '.checks')"; fi

# Test 4: installer install --dry-run shows planned action, no mutation
out="$("$INSTALLER" install --json)"
if printf '%s' "$out" | jq -e '.status == "planned" and .apply == false and (.planned_actions | length) >= 1' >/dev/null; then
  pass "installer install --dry-run plans action without mutating"
else fail "install dry-run: $(printf '%s' "$out" | jq -c .)"; fi

# Test 5: build tmp repo with chain wired
build_tmprepo
if [[ -x "$TMPREPO/.git/hooks/pre-commit" ]] && [[ -x "$TMPREPO/.flywheel/hooks/pre-commit-chain.sh" ]]; then
  pass "tmprepo built with pre-commit chain wired"
else fail "tmprepo build incomplete"; fi

# Test 6: commit a clean .flywheel/scripts/*.sh — should PASS the hook
cat > /tmp/cclp-clean.sh <<'EOF'
#!/usr/bin/env bash
# flywheel-cli-surface: true
set -euo pipefail
mode="${1:-dry-run}"
idem_key="${2:-}"

if [[ "$mode" == "apply" ]]; then
  if [[ -z "$idem_key" ]]; then
    echo '{"status":"refused","reason":"--apply requires --idempotency-key"}' >&2
    exit 3
  fi
  mkdir -p "$HOOME/.local/state/clean-fixture" 2>/dev/null || true
fi
EOF
out="$(commit_attempt ".flywheel/scripts/cclp-clean.sh" "$(cat /tmp/cclp-clean.sh)" "feat: clean surface" 2>&1)"
rc=$?
if [[ "$rc" -eq 0 ]] && [[ "$(last_commit_msg)" == "feat: clean surface" ]]; then
  pass "clean fixture: commit succeeds, hook chain ran cleanly"
else fail "clean commit rc=$rc msg=$(last_commit_msg) out=$out"; fi
rm -f /tmp/cclp-clean.sh

# Test 7: commit a DIRTY .flywheel/scripts/*.sh (L9 violation: side-effect
# inside apply-block before gate) — should be BLOCKED by the hook.
cat > /tmp/cclp-dirty.sh <<'EOF'
#!/usr/bin/env bash
# flywheel-cli-surface: true
set -euo pipefail
mode="${1:-dry-run}"
idem_key="${2:-}"

if [[ "$mode" == "apply" ]]; then
  # SIDE-EFFECT BEFORE GATE — hoqq8 trauma class, L9 must flag
  mkdir -p "$HOME/.local/state/dirty-fixture"
  cp /etc/hosts "$HOME/.local/state/dirty-fixture/copy"
  sed -i '' 's/x/y/' "$HOME/.local/state/dirty-fixture/copy"

  if [[ -z "$idem_key" ]]; then
    echo '{"status":"refused"}' >&2
    exit 3
  fi
fi
EOF
commits_before="$(commit_count)"
out="$(commit_attempt ".flywheel/scripts/cclp-dirty.sh" "$(cat /tmp/cclp-dirty.sh)" "feat: dirty surface (should be blocked)" 2>&1)"
rc=$?
commits_after="$(commit_count)"
if [[ "$rc" -ne 0 ]] && [[ "$commits_after" -eq "$commits_before" ]]; then
  pass "dirty fixture: commit BLOCKED (rc=$rc, commit count unchanged)"
else fail "dirty commit not blocked: rc=$rc, commits=$commits_before -> $commits_after, out=$(printf '%s' "$out" | head -2)"; fi

# Test 8: dirty commit message NOT in HEAD (commit truly didn't happen)
if [[ "$(last_commit_msg)" != "feat: dirty surface (should be blocked)" ]]; then
  pass "dirty fixture: HEAD does not advance to dirty commit"
else fail "dirty commit incorrectly landed in HEAD"; fi

# Test 9: dirty fixture WITH --no-verify bypasses the hook → commit succeeds
commits_before="$(commit_count)"
out="$(commit_attempt ".flywheel/scripts/cclp-dirty.sh" "$(cat /tmp/cclp-dirty.sh)" "feat: dirty surface --no-verify" "--no-verify" 2>&1)"
rc=$?
commits_after="$(commit_count)"
if [[ "$rc" -eq 0 ]] && [[ "$commits_after" -eq $((commits_before + 1)) ]] && [[ "$(last_commit_msg)" == "feat: dirty surface --no-verify" ]]; then
  pass "--no-verify bypasses the hook (commit succeeds despite L9 violation)"
else fail "--no-verify did not bypass: rc=$rc, commits=$commits_before -> $commits_after, msg=$(last_commit_msg)"; fi
rm -f /tmp/cclp-dirty.sh

# Test 10: commit a non-.sh file — hook should not interfere (no .sh staged)
out="$(commit_attempt "doc.md" "# Some doc" "docs: irrelevant md change" 2>&1)"
rc=$?
if [[ "$rc" -eq 0 ]] && [[ "$(last_commit_msg)" == "docs: irrelevant md change" ]]; then
  pass "non-.sh commit: hook stays out of the way"
else fail "non-.sh commit: rc=$rc out=$out"; fi

# Test 11: commit a .sh OUTSIDE .flywheel/scripts/ without magic comment — hook
# should NOT lint it (the existing hook filters to flywheel/scripts/ or magic comment).
cat > /tmp/cclp-unrelated.sh <<'EOF'
#!/usr/bin/env bash
# No magic comment — not a canonical-cli surface
set -euo pipefail
mode="${1:-dry-run}"
idem_key="${2:-}"
if [[ "$mode" == "apply" ]]; then
  mkdir -p "$HOME/.local/state/unrelated"
  cp /etc/hosts "$HOME/.local/state/unrelated/copy"
fi
EOF
out="$(commit_attempt "scripts/cclp-unrelated.sh" "$(cat /tmp/cclp-unrelated.sh)" "feat: unrelated .sh without magic" 2>&1)"
rc=$?
if [[ "$rc" -eq 0 ]] && [[ "$(last_commit_msg)" == "feat: unrelated .sh without magic" ]]; then
  pass "unrelated .sh (no magic comment, outside .flywheel/scripts): hook skips"
else fail "unrelated .sh: rc=$rc out=$out"; fi
rm -f /tmp/cclp-unrelated.sh

# Test 12: hook output mentions which file(s) failed (operator can see the
# violation). Test by re-staging the dirty file and capturing stderr.
cat > /tmp/cclp-dirty-2.sh <<'EOF'
#!/usr/bin/env bash
# flywheel-cli-surface: true
set -euo pipefail
mode="${1:-dry-run}"
idem_key="${2:-}"

if [[ "$mode" == "apply" ]]; then
  mkdir -p "$HOME/.local/state/dirty-2"
  if [[ -z "$idem_key" ]]; then exit 3; fi
fi
EOF
out="$(commit_attempt ".flywheel/scripts/cclp-dirty-2.sh" "$(cat /tmp/cclp-dirty-2.sh)" "feat: dirty 2" 2>&1)"
# The hook should print the violations (file:line: rule format from canonical-cli-lint.sh)
if printf '%s' "$out" | grep -qE '\.flywheel/scripts/cclp-dirty-2\.sh:[0-9]+:\s+L[0-9]'; then
  pass "hook stderr shows file:line: L# rule citations"
else fail "hook output doesn't cite L9: $(printf '%s' "$out" | head -3)"; fi
rm -f /tmp/cclp-dirty-2.sh

# Test 13: installer install --apply against tmprepo wires correctly
out="$(cd "$TMPREPO" && "$INSTALLER" install --apply --json 2>&1)"
if printf '%s' "$out" | jq -e '.status == "installed" and .apply == true' >/dev/null; then
  chain_cfg_set="$(cd "$TMPREPO" && git config --local --get flywheel.securityPrecommitChain)"
  if [[ -n "$chain_cfg_set" ]]; then
    pass "installer install --apply: chain config set in tmprepo"
  else fail "chain config not set after install --apply"; fi
else fail "install --apply: $(printf '%s' "$out" | jq -c .)"; fi

# Test 14: installer validate confirms wire-in is functional after install
out="$(cd "$TMPREPO" && "$INSTALLER" validate --json 2>&1)"
if printf '%s' "$out" | jq -e '.status == "ok" and .fail == 0 and .pass >= 5' >/dev/null; then
  pass "installer validate: all 5 wire-in checks pass after install --apply"
else fail "validate after install: $(printf '%s' "$out" | jq -c '{status, pass, fail}')"; fi

# Test 15: installer install --apply is idempotent (no-op on second run)
out="$(cd "$TMPREPO" && "$INSTALLER" install --apply --json 2>&1)"
if printf '%s' "$out" | jq -e '.status == "installed" and .idempotent_no_op == true' >/dev/null; then
  pass "installer install --apply: idempotent on re-run"
else fail "idempotency: $(printf '%s' "$out" | jq -c '{status, idempotent_no_op}')"; fi

# Test 16: installer uninstall --apply removes chain config
out="$(cd "$TMPREPO" && "$INSTALLER" uninstall --apply --json 2>&1)"
if printf '%s' "$out" | jq -e '.status == "uninstalled" and .apply == true' >/dev/null \
   && [[ -z "$(cd "$TMPREPO" && git config --local --get flywheel.securityPrecommitChain 2>/dev/null)" ]]; then
  pass "installer uninstall --apply: chain config removed"
else fail "uninstall: $(printf '%s' "$out" | jq -c .)"; fi

# Test 17: audit mode emits current state
out="$(cd "$TMPREPO" && "$INSTALLER" audit --json 2>&1)"
if printf '%s' "$out" | jq -e '.mode == "audit" and has("bypass_doc")' >/dev/null; then
  pass "installer audit: emits config state + bypass doc"
else fail "audit: $(printf '%s' "$out" | jq -c .)"; fi

# Test 18: why mode explains each topic
for id in 1 2 3 4; do
  if ! "$INSTALLER" why "$id" --json 2>&1 | jq -e '.topic | type == "string"' >/dev/null; then
    fail "why $id"
    continue 2 2>/dev/null
  fi
done
pass "installer why 1/2/3/4: each topic explained"

# Test 19: pre-commit-chain.sh is bash -n clean
if bash -n "$CHAIN_SCRIPT" 2>/dev/null; then
  pass "pre-commit-chain.sh syntax"
else fail "pre-commit-chain.sh syntax"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
