#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
POLICY="$ROOT/.flywheel/CI-POLICY.json"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if [[ -s "$POLICY" ]] && jq -e '.schema_version == "flywheel.ci_policy.v1"' "$POLICY" >/dev/null; then
  pass "CI-POLICY schema"
else
  fail "CI-POLICY schema"
fi

if jq -e '.per_push_feature_branch_ci_allowed == false' "$POLICY" >/dev/null; then
  pass "feature branch per-push CI disabled"
else
  fail "feature branch per-push CI disabled"
fi

while IFS= read -r workflow; do
  if jq -e --arg path "$workflow" '.workflows[] | select(.path == $path)' "$POLICY" >/dev/null; then
    pass "policy declares $workflow"
  else
    fail "policy declares $workflow"
  fi
done < <(cd "$ROOT" && find .github/workflows -maxdepth 1 -type f -name '*.yml' | sort)

if grep -q 'pull_request:' "$ROOT/.github/workflows/ci.yml" \
  && grep -q 'branches:' "$ROOT/.github/workflows/ci.yml" \
  && grep -q 'types: \[opened, reopened, ready_for_review\]' "$ROOT/.github/workflows/ci.yml" \
  && ! grep -q 'synchronize' "$ROOT/.github/workflows/ci.yml"; then
  pass "ci pull_request excludes synchronize"
else
  fail "ci pull_request excludes synchronize"
fi

if grep -q 'pull_request:' "$ROOT/.github/workflows/installer-smoke.yml" \
  && grep -q 'branches:' "$ROOT/.github/workflows/installer-smoke.yml" \
  && grep -q 'types: \[opened, reopened, ready_for_review\]' "$ROOT/.github/workflows/installer-smoke.yml" \
  && ! grep -q 'synchronize' "$ROOT/.github/workflows/installer-smoke.yml"; then
  pass "installer pull_request excludes synchronize"
else
  fail "installer pull_request excludes synchronize"
fi

if ! grep -q 'push:' "$ROOT/.github/workflows/v5-w8-public-surface-parity-daily.yml"; then
  pass "daily parity has no push trigger"
else
  fail "daily parity has no push trigger"
fi

if grep -q 'branches:' "$ROOT/.github/workflows/ci.yml" \
  && grep -q 'main' "$ROOT/.github/workflows/ci.yml" \
  && grep -q 'master' "$ROOT/.github/workflows/ci.yml"; then
  pass "ci push limited to default branches"
else
  fail "ci push limited to default branches"
fi

if jq -e '.local_gates.branch_tip[] | contains("flywheel-local-ci")' "$POLICY" >/dev/null \
  && [[ -s "$ROOT/.flywheel/scripts/local-ci/flywheel-local-ci.sh" ]]; then
  pass "branch-tip local CI declared"
else
  fail "branch-tip local CI declared"
fi

if [[ -x "$ROOT/.flywheel/status-hook.sh" ]] \
  && "$ROOT/.flywheel/status-hook.sh" | grep -Eq '^CI spend: \$[0-9]+ est this month, [0-9]+%-on-target'; then
  pass "status hook renders CI spend dashboard line"
else
  fail "status hook renders CI spend dashboard line"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
