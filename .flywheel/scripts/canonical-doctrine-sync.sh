#!/usr/bin/env bash
# canonical-doctrine-sync.sh — thin alias for sync-canonical-doctrine.sh
#
# Authored under bead flywheel-rhdcq.2 to satisfy the canonical-doctrine-sync
# naming variant. The actual propagation logic lives in
# `.flywheel/scripts/sync-canonical-doctrine.sh` (item 7 of that script's help
# already handles `.flywheel/doctrine/*.md` propagation to fleet repos with
# backup-before-write + idempotency-key + --dry-run/--apply discipline).
#
# Naming variance rationale (per feedback_naming_rename_is_cross_repo_wire_or_explain):
# the sister script `sync-canonical-doctrine.sh` has 1100+ lines of fleet-
# propagation logic, an active ledger (8000+ rows), wide blast radius across
# AGENTS.md mirrors / validation schemas / doctrine docs / scripts / launchd /
# security settings, and has propagated content to dozens of repos historically.
# Renaming it would be a cross-repo wire-or-explain event (every repo's
# scaffolded canonical-cli reference would need synchronized update). A thin
# alias preserves the existing script's identity while exposing the
# canonical-doctrine-sync.sh name for callers (such as bead bodies and
# downstream doc references) that prefer the inverse word order.
#
# Behavior: exec-replaces this process with sync-canonical-doctrine.sh,
# forwarding all arguments verbatim. Exit codes, stdout/stderr, --dry-run /
# --apply semantics, and idempotency-key contract are all preserved.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET="${CANONICAL_DOCTRINE_SYNC_TARGET:-$SCRIPT_DIR/sync-canonical-doctrine.sh}"

if [[ ! -x "$TARGET" ]]; then
  echo "canonical-doctrine-sync.sh: target not executable: $TARGET" >&2
  exit 2
fi

# Self-introspection passthrough: --info reports the alias relationship in
# addition to delegating, so callers that walk the canonical-cli surface
# discover the alias chain.
if [[ "${1:-}" == "--info-alias" ]]; then
  printf '{"name":"canonical-doctrine-sync.sh","alias_for":"%s","authored_by":"flywheel-rhdcq.2"}\n' "$TARGET"
  exit 0
fi

exec "$TARGET" "$@"
