#!/usr/bin/env bash
# .flywheel/hooks/pre-commit-chain.sh
#
# Multi-hook pre-commit dispatcher. Runs each enabled lint hook in sequence
# against staged files. Configured via `git config flywheel.securityPrecommit
# Chain` to slot in after security-precommit-installer's scan-staged step.
#
# Currently enabled (in order):
#   1. canonical-cli-lint-pre-commit.sh  — L1-L9 lint on staged .sh
#   2. file-rag-discipline-pre-commit.sh — F1/F4 errors on staged .md
#
# Honors `git commit --no-verify` (git itself bypasses the entire chain).
# Per-hook bypass is git-global; we don't add granular bypass flags here
# because they leak into "I'll fix it later" posture.
#
# Bead: flywheel-f0e77 (ldp0a-followup pre-commit wire-in).
#
# Exit:
#   0  all hooks pass
#   1  first hook to fail (stops chain immediately for fastest feedback)

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
HOOKS_DIR="$REPO_ROOT/.flywheel/hooks"

# Hooks to run, in order. Skipped if missing or non-executable
# (so partially-installed substrate degrades gracefully).
HOOKS=(
  "$HOOKS_DIR/canonical-cli-lint-pre-commit.sh"
  "$HOOKS_DIR/file-rag-discipline-pre-commit.sh"
)

for hook in "${HOOKS[@]}"; do
  if [[ -x "$hook" ]]; then
    if ! "$hook"; then
      # First failure stops the chain — fastest feedback for the operator.
      exit 1
    fi
  fi
done

exit 0
