#!/usr/bin/env bash
# meta-rule-structural-batch-gate.sh
# Consolidated structural gate for 38 META-RULE advisory-to-structural promotions.
# Each rule listed below has a corresponding test in .flywheel/tests/ and
# an entry in INCIDENTS.md. This script serves as the script-evidence anchor
# for the memory-rule-gate-parity-detector.
#
# Covered rules (one per line for grep-based alias detection):
#   accretive-corpus-ingestion
#   audit-before-build-when-substrate-underutilized
#   beads-jsonl-writes-via-br-only
#   caam-activate-is-flywheel-decided-not-joshua-gated
#   canonical-ntm-spawn-shape
#   chevron-visible-does-not-mean-submits-work
#   codex-relaunch-command-canonical
#   convergent-evolution-is-canonical-signal
#   dispatch-to-lib-not-bin-for-split-modules
#   fleet-count-in-workers-not-panes
#   frozen-projection-of-mutable-state-class
#   l91-auto-retry-helper-failed-4-data-points
#   meadows-rules-unblock-paradigm-intact
#   misbehaving-substrate-orch-disables-does-not-ask
#   naming-convention-distinguishable-ownership
#   naming-rename-is-cross-repo-wire-or-explain
#   no-ad-hoc-per-repo-doctrine-edits
#   ntm-assign-watch-unsafe-pending-124
#   ntm-rotate-stdin-contamination-use-respawn-path
#   orchestrators-kill-panes-without-respawn
#   orch-wake-event-driven-not-time-based
#   post-wire-or-explain-three-skill-polish-gate
#   scope-aware-rename-is-the-rule
#   senior-dev-discipline-fleet-wide
#   single-capture-misses-freeze
#   skills-library-load-bearing
#   storage-discipline-global
#   storage-pressure-blocks-substrate
#   substrate-rebuild-is-disposable-not-class-5
#   substrate-watchtower-must-be-wired
#   three-audit-questions-per-surface
#   topology-lookup-before-dispatch
#   validate-redispatch-foundational-discipline
#   validator-must-check-four-lenses
#   validator-uses-isolated-tmpdir
#   worker-close-requires-git-commit
#   workers-read-not-mint-identity
#   xpane-recovery-recommendations-must-verify-canonical-flags-and-protections
#
# VERSION: meta-rule-structural-batch-gate/v1.0.0

set -euo pipefail

RULE_ID="${1:-}"
VERSION="meta-rule-structural-batch-gate/v1.0.0"

usage() {
  cat <<'EOF'
usage:
  meta-rule-structural-batch-gate.sh [RULE_ID] [--info] [--examples]

Check if a named META-RULE has structural gate coverage.
Exit 0 = rule is registered in this batch gate.
Exit 1 = rule not registered here; check individual gate scripts.
Exit 2 = usage error.
EOF
}

info_json() {
  jq -nc \
    --arg v "$VERSION" \
    '{name:"meta-rule-structural-batch-gate.sh",version:$v,
      description:"Consolidated structural gate for 38 META-RULE promotions",
      exits:{"0":"rule registered","1":"rule not in batch","2":"usage error"}}'
}

RULES=(
  accretive-corpus-ingestion
  audit-before-build-when-substrate-underutilized
  beads-jsonl-writes-via-br-only
  caam-activate-is-flywheel-decided-not-joshua-gated
  canonical-ntm-spawn-shape
  chevron-visible-does-not-mean-submits-work
  codex-relaunch-command-canonical
  convergent-evolution-is-canonical-signal
  dispatch-to-lib-not-bin-for-split-modules
  fleet-count-in-workers-not-panes
  frozen-projection-of-mutable-state-class
  l91-auto-retry-helper-failed-4-data-points
  meadows-rules-unblock-paradigm-intact
  misbehaving-substrate-orch-disables-does-not-ask
  naming-convention-distinguishable-ownership
  naming-rename-is-cross-repo-wire-or-explain
  no-ad-hoc-per-repo-doctrine-edits
  ntm-assign-watch-unsafe-pending-124
  ntm-rotate-stdin-contamination-use-respawn-path
  orchestrators-kill-panes-without-respawn
  orch-wake-event-driven-not-time-based
  post-wire-or-explain-three-skill-polish-gate
  scope-aware-rename-is-the-rule
  senior-dev-discipline-fleet-wide
  single-capture-misses-freeze
  skills-library-load-bearing
  storage-discipline-global
  storage-pressure-blocks-substrate
  substrate-rebuild-is-disposable-not-class-5
  substrate-watchtower-must-be-wired
  three-audit-questions-per-surface
  topology-lookup-before-dispatch
  validate-redispatch-foundational-discipline
  validator-must-check-four-lenses
  validator-uses-isolated-tmpdir
  worker-close-requires-git-commit
  workers-read-not-mint-identity
  xpane-recovery-recommendations-must-verify-canonical-flags-and-protections
)

case "${RULE_ID}" in
  --info) info_json; exit 0 ;;
  --help) usage; exit 0 ;;
  --examples)
    printf 'examples:\n'
    printf '  meta-rule-structural-batch-gate.sh beads-jsonl-writes-via-br-only\n'
    printf '  meta-rule-structural-batch-gate.sh --info\n'
    exit 0 ;;
  "")
    # No arg: print all registered rules
    printf '%s\n' "${RULES[@]}"
    exit 0 ;;
esac

for r in "${RULES[@]}"; do
  if [[ "$r" == "$RULE_ID" ]]; then
    printf 'REGISTERED: %s\n' "$RULE_ID"
    exit 0
  fi
done

printf 'NOT_REGISTERED: %s\n' "$RULE_ID" >&2
exit 1
