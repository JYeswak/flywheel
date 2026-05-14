#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
AUDIT="$ROOT/docs/evidence/publication-goal-completion-audit.md"
READINESS="$ROOT/scripts/publication_readiness.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-goal-audit.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

require_literal() {
  local literal="$1" label="$2"
  if rg -qF -- "$literal" "$AUDIT"; then
    pass "$label"
  else
    fail "$label"
  fi
}

if [[ -s "$AUDIT" ]]; then
  pass "goal audit exists"
else
  fail "goal audit exists"
fi

require_literal "flywheel.publication_goal_completion_audit.v0" "goal audit names schema"
require_literal "Status: \`not-complete\`" "goal audit is not a completion claim"
require_literal "Current verdict: \`not complete\`." "goal audit states current verdict"
require_literal "Objective Restatement" "goal audit restates objective"
require_literal "Prompt-To-Artifact Checklist" "goal audit has prompt-to-artifact checklist"
require_literal "Live Readiness Truth" "goal audit names live readiness truth"
require_literal "Audit Closeout Rule" "goal audit names closeout rule"

for literal in \
  "Joshua/ZestStream-private naming" \
  "Install, doctor, loop, NTM, and non-NTM workflows" \
  "Claude Code, Codex CLI, Gemini CLI, and OpenClaw" \
  "SkillOS" \
  "proof-product surfaces" \
  "business owner" \
  "external developer" \
  "Every blocker or gap"; do
  require_literal "$literal" "goal audit covers: $literal"
done

for evidence in \
  "README.md" \
  "CHARTER.md" \
  "install.sh" \
  "scripts/preflight.sh" \
  "scripts/journey-smoke.sh" \
  "scripts/agent-lane-probe.sh" \
  "scripts/isolated-agent-lane-smoke.sh" \
  "docs/concepts/skillos-boundary.md" \
  "docs/evidence/publication-evidence.md" \
  "docs/evidence/publication-blocker-coverage.md" \
  "docs/runbooks/public-user-journey-pack.md" \
  "site/" \
  "python3 scripts/publication_readiness.py --json"; do
  require_literal "$evidence" "goal audit maps evidence: $evidence"
done

if python3 "$READINESS" --json >"$TMP/readiness.json"; then
  pass "publication readiness command returns pass-state JSON"
else
  if jq -e '.status == "blocked" and (.blockers | length) > 0' "$TMP/readiness.json" >/dev/null; then
    pass "publication readiness command returns blocked-state JSON"
  else
    fail "publication readiness command returns parseable readiness JSON"
  fi
fi

status="$(jq -r '.status' "$TMP/readiness.json")"
if [[ "$status" == "blocked" ]]; then
  require_literal "Current verdict: \`not complete\`." "blocked readiness keeps goal incomplete"
elif [[ "$status" == "pass" ]]; then
  fail "goal audit must be refreshed before pass-state completion"
else
  fail "publication readiness status is recognized"
fi

while IFS= read -r code; do
  [[ -n "$code" ]] || continue
  require_literal "$code" "goal audit includes live readiness blocker $code"
done < <(jq -r '.blockers[]?.code' "$TMP/readiness.json")

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
