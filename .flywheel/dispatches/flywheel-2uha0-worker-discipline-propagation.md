# flywheel-2uha0 — Worker discipline training propagation across 8 fleet orchs

## Context

Tonight tonight produced 5+ worker-discipline doctrines that currently exist ONLY in flywheel-side memory + .flywheel/doctrine/. Without propagation, the rest of the fleet (skillos, mobile-eats, picoz, clutterfreespaces, alpsinsurance, vrtx, zesttube) operates without them. Workers in those repos continue to:
- Abandon when auto-push blocks (not auto-sweep / not escalate)
- Freeze on DCG prompts (not check pre-auth-scopes / not escalate)
- Send raw `ntm send` to codex panes (not use the activation primitive)
- Drop callbacks after artifact writes (false-IDLE class)
- Burn cumulative-session-timer text into idle-chat misreads

This bead is the integration step: codify each doctrine into a per-orch absorption package + add a fleet-wide "discipline-conformance" probe + auto-bead-file deviations.

## Doctrines to propagate (all flywheel-side at .flywheel/doctrine/*)

1. `auto-push-blocked-worker-discipline.md` (2026-05-20)
2. `codex-goal-mode-discipline.md` (skillos canonical via czwpu absorption)
3. `dry-run-apply-parity-contract.md` (flywheel-vlodi 2026-05-20)
4. `dcg-worker-freeze-discipline.md` (flywheel-8iook 2026-05-20)
5. `runtime-doctrine-separation-discipline.md` (flywheel-8ont6 2026-05-20)
6. `repo-hygiene-tick-discipline.md` (flywheel-ge03h 2026-05-20)

## Memory pins to propagate

From flywheel-side `~/.claude/projects/-Users-josh-Developer-flywheel/memory/MEMORY.md`:
- feedback_goal_mode_is_codex_usage_limit_workaround
- feedback_codex_goal_mode_runtime_enforcement
- feedback_auto_push_blocked_worker_abandonment
- feedback_dry_run_apply_parity_contract

## Deliverables

### A. .flywheel/scripts/worker-discipline-propagate.sh
Per-orch absorption primitive. Flags: --target-orch NAME --dry-run --apply --json.
Steps per target orch:
1. Probe target orch's .flywheel/doctrine/ for existing per-doctrine docs
2. For each MISSING doctrine: copy from flywheel canonical OR symlink + commit in target repo
3. Propagate memory pins to target orch's MEMORY.md (cross-repo write may need authorization — gated check)
4. Probe target orch's worker tick contract / dispatch-template for absorption hooks (e.g., post-callback verify auto_push_status, NEVER stash other workers' WIP, etc.)
5. If absorption hooks missing → emit per-orch propagation-gap report
6. Idempotent: re-run produces no changes if propagation complete

### B. .flywheel/scripts/discipline-conformance-probe.sh
Fleet-wide probe (similar to repo-hygiene-doctor.sh shape). For each of 8 orchs:
1. Check doctrine docs present at canonical paths
2. Check memory pins present + indexed in MEMORY.md
3. Check dispatch-template references the activation primitive (codex panes)
4. Check post-callback verification step exists in tick contract
5. Emit conformance score per orch + per doctrine
6. Auto-file P2 bead in affected orch repo if conformance < threshold (pairs with ge03h auto-bead-filer)

### C. .flywheel/audits/worker-discipline-propagation-readiness-<ts>.md
Initial dry-run report showing per-orch conformance baseline. Joshua reviews before any apply.

### D. tests/worker-discipline-propagate-smoke.sh
- 6+ assertions:
  1. Synthetic empty target orch → propagate creates all doctrines
  2. Synthetic partial target orch → propagate fills only missing
  3. Idempotent re-run → no changes
  4. Conformance probe detects missing doctrine → flagged
  5. Conformance probe detects missing memory pin → flagged
  6. Auto-bead-file fires only when conformance < threshold

### E. Doctrine
.flywheel/doctrine/worker-discipline-propagation-contract.md citing:
- The 6 doctrines being propagated
- Per-orch absorption checklist
- Conformance score formula
- Cross-link to skillos canonical-locator lane (they own canonical absorption authority — flywheel can ONLY mirror + propose, not canonicalize)
- Joshua-gate for cross-orch writes

## Acceptance

- 2 scripts + 1 doctrine + smoke ship
- shellcheck PASS
- Smoke 6+ assertions PASS
- Initial 8-orch conformance baseline report written
- Dry-run only — no actual cross-orch writes yet (Joshua + skillos canonicalization gate)
- Bead flywheel-2uha0 closed

## Out of scope

- Actually executing the cross-orch writes — Joshua-gate + skillos:1 canonical-locator authority
- Modifying any non-flywheel repo's files
- Forcing absorption — workers/orchs need their own /reload or session-restart cycle to pick up new doctrines

## Loop contract

- Track 3 only
- mcp-agent-mail file_reservation_paths before edits
- socraticode K>=10 with 2 phrasings on existing skillos canonical-locator patterns + cross-repo-write-path-discipline.md
- Bridge daemon LIVE
- SCR event: C6_trauma_outflow + C7_verification_density
- STOP on Track 1/2 breach, BLOCKED, >3h hard cap
- DEEP-WORK validate: shellcheck + smoke + 8-orch conformance baseline dry-run
- DO NOT actually write to any non-flywheel repo — Joshua-gate

## FIRST ACTION

1. br show flywheel-2uha0.
2. Read .flywheel/doctrine/auto-push-blocked-worker-discipline.md (today's most-N example).
3. Read .flywheel/doctrine/cross-repo-write-path-discipline.md (existing canonical for cross-orch writes).
4. ACK row.
5. Implement 2 scripts + smoke + doctrine.
6. Self-validate.
7. Conformance baseline report across 8 orchs (read-only).
8. Commit + close bead + DIRECT pane-1 ntm send.
