# Fleet Audit Protocol (flywheel mirror)

Mirror of `/Users/josh/Developer/skillos/.flywheel/doctrine/fleet-audit-protocol.md`.

**Purpose:** Standard protocol for fleet-wide audits crossing repos / skill counts >100 / requiring persistent state.

**Origin:** Codified 2026-05-18 during JSM fleet audit (`/Users/josh/Developer/skillos/state/jsm-fleet-audit-20260518T2305Z/`).

## Summary

10 rules (see skillos canonical for full text):

1. Persistent state machine MANDATORY (survives compactions)
2. Clear condition declared upfront
3. Counter-driven progress (mechanical clear-check)
4. Batch dispatch contract with schema-versioned envelopes
5. Pattern discovery: no pre-bounded list; ≥3 exemplars per pattern
6. Surface upgrades: concrete diffs in real files, not prose
7. Repo application: applied=true only when concrete diff committed
8. Parallel work allocation: orchestrator never just dispatches+waits
9. Pause/resume protocol: read MANIFEST → PROGRESS → newest dispatch/callback
10. Anti-patterns: no proposal-only, no re-discovery, no silent skips, no exit-code-only trust, no counter drift

## Cross-references

- Canonical: `/Users/josh/Developer/skillos/.flywheel/doctrine/fleet-audit-protocol.md`
- First application: `/Users/josh/Developer/skillos/state/jsm-fleet-audit-20260518T2305Z/MANIFEST.md`
- Sister: `.flywheel/doctrine/audit-machinery-hygiene-discipline.md`
