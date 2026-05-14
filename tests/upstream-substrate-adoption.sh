#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
DOC="$ROOT/docs/runbooks/upstream-substrate-adoption.md"
PACKET="$ROOT/docs/evidence/asupersync-gated-adoption.md"
POC_TEMPLATE="$ROOT/docs/evidence/asupersync-poc-receipt.template.json"
POC_LOCAL="$ROOT/docs/evidence/asupersync-poc-receipt.local.json"
CI="$ROOT/.github/workflows/ci.yml"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

require_literal() {
  local file="$1"
  local literal="$2"
  local label="$3"
  if grep -qF "$literal" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

reject_literal() {
  local file="$1"
  local literal="$2"
  local label="$3"
  if grep -qF "$literal" "$file"; then
    fail "$label"
  else
    pass "$label"
  fi
}

if [[ -s "$DOC" ]]; then
  pass "runbook exists"
else
  fail "runbook exists"
fi

if [[ -s "$PACKET" ]]; then
  pass "evidence packet exists"
else
  fail "evidence packet exists"
fi

if [[ -s "$POC_TEMPLATE" ]]; then
  pass "POC receipt template exists"
else
  fail "POC receipt template exists"
fi

if [[ -s "$POC_LOCAL" ]]; then
  pass "local POC receipt exists"
else
  fail "local POC receipt exists"
fi

require_literal "$DOC" "Status: \`gated-evaluation\`." "status is gated evaluation"
require_literal "$DOC" "Latest live probe, 2026-05-13T16:00Z" "latest live probe recorded"
require_literal "$DOC" "\`0.3.1\`, while the public website" "latest version truth recorded"
require_literal "$DOC" "public website still advertises \`V0.2.6\`" "site version mismatch recorded"
require_literal "$DOC" "OpenAI/Anthropic rider" "license rider gate"
require_literal "$DOC" "not a restriction on ordinary" "ordinary-user license distinction"
require_literal "$DOC" "human operators, non-restricted users, and user-directed local Codex/Claude sessions may evaluate" "human evaluation distinction"
require_literal "$DOC" "user-directed local Codex/Claude sessions may evaluate" "agent-tool user-side evaluation distinction"
require_literal "$DOC" "Current \`main\` Actions runs" "upstream actions not green recorded"
require_literal "$DOC" "f29ff7b4c330f14e2748ec05c1a3420199b9cf77" "evaluated upstream commit recorded"
require_literal "$DOC" "issue \`#35\` for a Windows" "open operational issue recorded"
require_literal "$DOC" "docs/evidence/asupersync-gated-adoption.md" "evidence packet linked"
require_literal "$DOC" "docs/evidence/asupersync-poc-receipt.template.json" "POC receipt template linked"
require_literal "$DOC" "docs/evidence/asupersync-poc-receipt.local.json" "local POC receipt linked"
require_literal "$DOC" "not a required" "not required dependency language"
require_literal "$DOC" "prioritize the investigation now" "investigation priority recorded"
require_literal "$DOC" "do not rewrite the shell/Python loop engine for runtime purity" "no runtime-purity rewrite"
require_literal "$DOC" "Repo-local Rust proof receipt" "POC receipt gate"
require_literal "$DOC" "Immediate Investigation Lane" "immediate investigation lane exists"
require_literal "$DOC" "user-directed Codex/Claude session is acceptable" "cleared user-directed executor lane recorded"
require_literal "$DOC" "restricted-company work" "restricted-company clearance retained"
require_literal "$DOC" "Apple Silicon path" "Apple Silicon gate"
require_literal "$DOC" "Known upstream failing-test count" "failing-test disposition gate"
require_literal "$DOC" "Current upstream Actions status is green" "CI posture promotion gate"
require_literal "$DOC" "Active high-impact issues" "operational posture promotion gate"
require_literal "$DOC" "https://api.github.com/repos/Dicklesworthstone/asupersync/releases/latest" "GitHub release probe"
require_literal "$DOC" "https://crates.io/api/v1/crates/asupersync" "crates probe"
require_literal "$DOC" "https://asupersync.com/" "site probe"
require_literal "$DOC" "must not imply" "public copy no-overclaim rule"
reject_literal "$DOC" "required Flywheel runtime dependency" "no required runtime claim"

require_literal "$PACKET" "Status: \`gated-evaluation\`." "packet status is gated evaluation"
require_literal "$PACKET" "Captured: 2026-05-13T16:00Z." "packet capture timestamp"
require_literal "$PACKET" "pushed at \`2026-05-13T15:56:10Z\`" "packet source commit freshness"
require_literal "$PACKET" "\`v0.3.1\`, published \`2026-04-22T00:13:43Z\`" "packet release version"
require_literal "$PACKET" "Newest crate version \`0.3.1\`" "packet crate version"
require_literal "$PACKET" "still advertises \`V0.2.6\`" "packet site mismatch"
require_literal "$PACKET" "OpenAI/Anthropic rider" "packet license rider"
require_literal "$PACKET" "human operators, non-restricted users, and user-directed local Codex/Claude sessions" "packet user-side evaluation distinction"
require_literal "$PACKET" "f29ff7b4c330f14e2748ec05c1a3420199b9cf77" "packet evaluated commit"
require_literal "$PACKET" "No green upstream CI proof" "packet CI gate"
require_literal "$PACKET" "issue \`#35\` Windows HTTPS connect failure remains open" "packet open issue"
require_literal "$PACKET" "prioritize an isolated investigation now" "packet investigation priority"
require_literal "$PACKET" "POC receipt exists at" "packet local POC receipt summary"
require_literal "$PACKET" "must not:" "packet no-overclaim section"
require_literal "$PACKET" "add Asupersync to the public install path" "packet blocks install dependency"
require_literal "$PACKET" "treat the rider as disqualifying ordinary users or adopter-side evaluation" "packet does not block ordinary users"
require_literal "$PACKET" "present user-directed Codex/Claude POC checks as evidence that restricted" "packet keeps restricted-company boundary"

require_literal "$ROOT/docs/concepts/evidence-contracts.md" "asupersync-poc-receipt.template.json" "evidence contract names POC receipt"
require_literal "$ROOT/docs/concepts/evidence-contracts.md" "asupersync-poc-receipt.local.json" "evidence contract names local POC receipt"

if jq -e '
  .schema_version == "flywheel.asupersync_poc_receipt.v0" and
  .status == "blocked" and
  .executor.codex_or_claude_operated == false and
  .poc_semantics.no_flywheel_runtime_dependency == true and
  .promotion_decision.status == "not_promoted"
' "$POC_TEMPLATE" >/dev/null; then
  pass "POC template schema blocks promotion by default"
else
  fail "POC template schema blocks promotion by default"
fi

if jq -e '
  .schema_version == "flywheel.asupersync_poc_receipt.v0" and
  .status == "pass" and
  .support_scope == "isolated_poc_only" and
  .executor.codex_or_claude_operated == true and
  .platform.apple_silicon_path == "source-build" and
  .poc_semantics.explicit_cx == true and
  .poc_semantics.owned_regions == true and
  .poc_semantics.cancellation_tested == true and
  .poc_semantics.deterministic_test_used == true and
  .poc_semantics.no_flywheel_runtime_dependency == true and
  .promotion_decision.status == "not_promoted"
' "$POC_LOCAL" >/dev/null; then
  pass "local POC receipt proves isolated smoke without promotion"
else
  fail "local POC receipt proves isolated smoke without promotion"
fi

require_literal "$CI" "tests/upstream-substrate-adoption.sh" "CI runs adoption contract"
require_literal "$CI" "docs/runbooks/upstream-substrate-adoption.md" "CI markdownlint includes runbook"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
