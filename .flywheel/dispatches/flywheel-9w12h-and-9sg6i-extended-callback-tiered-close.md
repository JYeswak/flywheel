# flywheel-9w12h + flywheel-9sg6i — Extended callback envelope schema + tiered close-bar

## Context

PAIRED P1 → P0 bundle: today's worker-discipline traumas (auto-push-blocked-abandonment, false-idle-after-silent-artifact-write, missed callbacks) all trace to insufficient callback envelope + close-bar discipline. CFS:1 just shipped a clean tiered-close-bar pattern in their iOS-app mission (2026-05-20T04:00Z lock): substrate-class beads close on code-path evidence, runtime-class beads require receipt JSON with concrete artifacts. mobile-eats's joint deep-dive identified extended callback envelope as P1 (worktree_removed, branch_local_deleted, stash_dropped, main_ff_status).

These are paired primitives — extended envelope provides the FIELDS, tiered close-bar provides the SEMANTICS of which fields gate which close type.

## Deliverables

### A. Extend dispatch-log.jsonl schema (v3)
Add fields to callback rows:
- post_callback_worktree_removed: bool|null
- post_callback_branch_local_deleted: bool|null
- post_callback_stash_dropped: bool|null
- post_callback_main_ff_status: ok|behind|diverged|unknown
- post_callback_auto_push_status: ok|blocked|swept|skipped
- close_class: substrate_class|runtime_class (NEW per CFS tiered pattern)
- runtime_receipt_path: string|null (required if close_class=runtime_class)
- runtime_artifacts: {} (required if close_class=runtime_class; e.g., TestFlight build #, device model, iOS version, timestamp, OR API endpoint + status + latency + payload-hash, OR whatever the runtime class demands per bead's acceptance)

Doc: .flywheel/doctrine/dispatch-log-schema-v3.md citing the v2 → v3 diff + CFS tiered pattern attribution.

### B. .flywheel/scripts/callback-envelope-validator.sh
Read a dispatch-log row. Validate:
- If close_class=runtime_class, require runtime_receipt_path + runtime_artifacts populated
- If close_class=substrate_class, code-path evidence (commit_sha + tests=PASS) sufficient
- Emit pass/fail + reason
- --json output
- Per-row validation in tests/

### C. .flywheel/scripts/worker-tick-contract-postcallback-verify.sh
Pre-callback verification primitive that workers/orchs invoke before sending callback. Checks:
- post-merge cleanup: worktree-removed if applicable + branch-deleted if applicable
- auto-push status: ok|swept (not blocked)
- close_class declared
- If runtime_class, receipt path exists + populated

Exit codes: 0=ok, 1=callback-blocked (worker must complete cleanup first), 2=close-class-undeclared

### D. tests/extended-callback-envelope-smoke.sh
- 8+ assertions:
  1. v2 row passes (back-compat)
  2. v3 row with substrate_class + all v3 fields passes
  3. v3 row with runtime_class but missing receipt FAILS
  4. v3 row with runtime_class + populated receipt passes
  5. validator script flags missing close_class
  6. worker-tick-contract verifier detects unfinished cleanup
  7. mixed close_class fleet replay parses without errors
  8. Idempotent re-validation produces identical envelope

### E. Doctrine
.flywheel/doctrine/extended-callback-envelope-and-tiered-close-bar.md citing:
- mobile-eats joint deep-dive (2026-05-20T04:05Z) — extended envelope P1
- CFS:1 iOS-app mission lock (2026-05-20T04:00Z) — tiered close-bar pattern
- false-idle-after-silent-artifact-write trauma class (flywheel-ozfou) — what this prevents
- Cross-link to flywheel-ge03h (hygiene tick) + flywheel-8ont6 (runtime/doctrine sep) for the broader hygiene cluster

## Acceptance

- Schema doc v3 ships
- 2 scripts + smoke + doctrine ship
- shellcheck PASS
- Smoke 8+ assertions PASS
- Beads flywheel-9w12h + flywheel-9sg6i both close (paired)
- Back-compat preserved (v2 rows continue parsing)

## Loop contract

- Track 3 only
- mcp-agent-mail file_reservation_paths before edits
- socraticode K>=10 with 2 phrasings on existing dispatch-log shape + CFS tiered-close-bar reference
- Bridge daemon LIVE
- SCR event: C6_trauma_outflow + C7_verification_density
- STOP on Track 1/2 breach, BLOCKED, >3h hard cap

## FIRST ACTION

1. br show flywheel-9w12h + flywheel-9sg6i.
2. Read .flywheel/handoffs/2026-05-20T0623Z-from-clutterfreespaces-to-flywheel-mission-pivot-ios-app-chanel-zero.md.
3. Read mobile-eats deep-dive memo at .flywheel/audits/git-workflow-fleet-analysis-20260520.md.
4. ACK row.
5. Implement schema doc + 2 scripts + smoke + doctrine.
6. Self-validate.
7. Commit + close BOTH beads + DIRECT pane-1 ntm send.
