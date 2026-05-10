#!/usr/bin/env bash
# tests/codex-21869-post-push-ref-drift-guard.sh
# Bead flywheel-ie2en: regression coverage for the dormant post-push
# ref-drift rule documented in
# .flywheel/doctrine/codex-21869-post-push-ref-drift-rule.md.
#
# The rule activates only when a Codex worker lane enables
# `workspace-write + network_access=true`. Until then, the fleet has
# zero exposure to openai/codex#21869.
#
# This test asserts the dormancy invariant: no worker-driven `git push`
# surface exists in .flywheel/scripts/, no codex config sets
# `sandbox = workspace-write`, and the rule document remains the
# canonical reference for any future workspace-write lane.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
RULE_DOC="${POST_PUSH_RULE:-$ROOT/.flywheel/doctrine/codex-21869-post-push-ref-drift-rule.md}"
SCRIPTS_DIR="${FLYWHEEL_SCRIPTS_DIR:-$ROOT/.flywheel/scripts}"
CODEX_CONFIG="${CODEX_CONFIG:-$HOME/.codex/config.toml}"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: rule document exists with required sections + 21869 citation
if [[ -f "$RULE_DOC" ]] \
  && grep -q "openai/codex#21869" "$RULE_DOC" \
  && grep -q "workspace-write" "$RULE_DOC" \
  && grep -q "network_access" "$RULE_DOC" \
  && grep -qE "post-push|reconciliation probe" "$RULE_DOC" \
  && grep -q "git ls-remote" "$RULE_DOC"; then
  pass "rule document exists with required sections + upstream citation"
else
  fail "rule document missing or incomplete at $RULE_DOC"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

# Test 2: no worker-driven `git push` surface in .flywheel/scripts/
# Allow .bak files and audit/receipts/evidence to reference push in
# documentation, but no executable script should invoke `git push`.
PUSH_HITS="$(grep -lE '^[[:space:]]*git[[:space:]]+push\b|"git push"|`git push`' \
  "$SCRIPTS_DIR"/*.sh 2>/dev/null || true)"
if [[ -z "$PUSH_HITS" ]]; then
  pass "no worker-driven git-push surface in .flywheel/scripts/*.sh"
else
  fail "worker push surface(s) found: $PUSH_HITS"
fi

# Test 3: codex config does NOT set sandbox = workspace-write fleet-wide
# (rule activates if it does; current config should NOT have it)
if [[ -f "$CODEX_CONFIG" ]]; then
  if grep -qE '^[[:space:]]*sandbox[[:space:]]*=[[:space:]]*"?workspace-write"?[[:space:]]*$' "$CODEX_CONFIG"; then
    fail "codex config has sandbox=workspace-write at fleet level — post-push rule should now be ACTIVE, see $RULE_DOC for the required reconciliation probe"
  else
    pass "codex config does not set fleet-wide sandbox=workspace-write (rule remains dormant)"
  fi
else
  pass "codex config absent — rule remains dormant"
fi

# Test 4: rule document explicitly names the canonical fleet worker mode
if grep -qE 'dangerously-bypass-approvals-and-sandbox|danger-full-access' "$RULE_DOC"; then
  pass "rule document names the canonical full-access worker mode"
else
  fail "rule document missing canonical worker mode citation"
fi

# Test 5: rule document specifies the 5-step reconciliation probe
required_probe_steps=(
  "git ls-remote"
  "remote_sha"
  "local_head_sha"
  "local_tracking_sha"
  "reconcile_action"
)
missing=()
for step in "${required_probe_steps[@]}"; do
  grep -qF -- "$step" "$RULE_DOC" || missing+=("$step")
done
if [[ "${#missing[@]}" -eq 0 ]]; then
  pass "rule document specifies 5-step reconciliation probe with structured receipt schema"
else
  fail "rule document missing probe steps: ${missing[*]}"
fi

# Test 6: rule document cites the triage source and the canonical worker memory rule
if grep -qE 'flywheel-z6lk3.*triage-receipt|triage-receipt.*flywheel-z6lk3' "$RULE_DOC" \
  && grep -q 'feedback_codex_relaunch_command_canonical' "$RULE_DOC"; then
  pass "rule document cites triage source + canonical worker mode memory"
else
  fail "rule document missing triage/memory citations"
fi

# Test 7: DCG core.git pack still blocks force-push (regression guard for
# the existing safety surface — orthogonal to 21869 but related).
# Write to tempfile first; piping dcg directly into grep -q triggers SIGPIPE
# abort on some hosts (DCG sees the early EPIPE as a fault).
if command -v dcg >/dev/null 2>&1; then
  dcg_tmp="$(mktemp -t dcg-packs.XXXXXX)"
  dcg packs -v --enabled >"$dcg_tmp" 2>&1 || true
  if grep -qE 'push-force-(long|short).*critical' "$dcg_tmp"; then
    pass "DCG core.git pack still blocks force-push at critical severity"
  else
    fail "DCG core.git push-force protection regressed"
  fi
  rm -f "$dcg_tmp"
else
  pass "dcg binary unavailable — DCG regression guard skipped"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
