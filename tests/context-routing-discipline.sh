#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
DOC="$ROOT/docs/runbooks/context-and-model-routing.md"
README="$ROOT/README.md"
CI="$ROOT/.github/workflows/ci.yml"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

require_literal() {
  local file="$1" literal="$2" label="$3"
  if rg -qF "$literal" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

reject_pattern() {
  local file="$1" pattern="$2" label="$3" hits
  if hits="$(rg -n "$pattern" "$file" 2>/dev/null)"; then
    fail "$label"
    printf '%s\n' "$hits" >&2
  else
    pass "$label"
  fi
}

if [[ -s "$DOC" ]]; then
  pass "context routing runbook exists"
else
  fail "context routing runbook exists"
fi

for literal in \
  "Grep before fetching." \
  "Keep no just-in-case context." \
  "Batch related tool calls." \
  "Preserve prompt-cache-friendly prefixes." \
  "Graduate repeated work into SKILL.md patterns." \
  "Summarize long sessions." \
  "Optimize slow surfaces with receipts." \
  "baseline timing" \
  "golden-output behavior proof" \
  "change one lever" \
  "recheck timing" \
  "behavior proof is not release evidence." \
  "No static model price table belongs in this repo." \
  "NTM can use lower-model workers for bounded routine work"; do
  require_literal "$DOC" "$literal" "runbook includes: $literal"
done

for literal in architecture security-critical concurrency "irreversible release decisions" "destructive operations" "live secrets"; do
  require_literal "$DOC" "$literal" "premium escalation includes: $literal"
done

for literal in "selected routing tier and reason" "maximum context budget" "exact validation command" "expected receipt shape"; do
  require_literal "$DOC" "$literal" "worker packet requires: $literal"
done

for literal in "baseline command, timing, and hotspot" "single optimization lever" "residual hotspot"; do
  require_literal "$DOC" "$literal" "slow-surface receipt requires: $literal"
done

require_literal "$README" "docs/runbooks/context-and-model-routing.md" "README links context routing runbook"
require_literal "$README" "This section is for maintainers running the full local substrate. It is not" \
  "README separates public first run from full substrate"
require_literal "$CI" "tests/context-routing-discipline.sh" "CI runs context routing test"
require_literal "$CI" "docs/runbooks/context-and-model-routing.md" "CI markdownlint includes context routing runbook"

reject_pattern "$DOC" 'Kimi 2\.6|Sonnet 4\.6|Opus 4\.6|\$[0-9]+[[:space:]]*/[[:space:]]*\$[0-9]+' \
  "runbook avoids static model/version pricing claims"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
