#!/usr/bin/env bash
set -euo pipefail

repo="/Users/josh/Developer/flywheel"
for file in \
  "$repo/AGENTS.md" \
  "$repo/.flywheel/AGENTS-CANONICAL.md" \
  "$repo/templates/flywheel-install/AGENTS.md"
do
  rg -q '^## L149 — PRE-COMMIT-GITLEAKS-MANDATORY$' "$file"
  rg -Fq 'pre_commit_secret_scanner_installed=yes|no' "$file"
  rg -Fq 'pretooluse_bash_diagnostic_hook_installed=yes|no' "$file"
  rg -q 'Vector #6 readback rule' "$file"
done

test -f "$repo/.flywheel/doctrine/secrets-leak-prevention-stack.md"
rg -q 'Layer A: PreToolUse Bash Hook' "$repo/.flywheel/doctrine/secrets-leak-prevention-stack.md"
rg -q 'Phase 4: `evidence_redacted`' "$repo/.flywheel/doctrine/secrets-leak-prevention-stack.md"
rg -q 'L149 adds the commit-time and diagnostic-readback layer' "$repo/README.md"

printf '%s\n' 'L112_PASS_flywheel-hv071_L149_three_surface_and_stack'
