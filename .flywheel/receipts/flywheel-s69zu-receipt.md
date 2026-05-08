# flywheel-s69zu ALPS Beads Leakage Investigation

schema_version: flywheel-s69zu-beads-leakage-investigation/v1
source: alps_loop_20260508T013943Z
bead: flywheel-s69zu
executed_at: 2026-05-08T01:52:00Z

## Mission Invariant

ALPS bead views should show ALPS-owned work only. Cross-project coordination can
reference flywheel plans, but it must not mint `flywheel-*` implementation or
structural-gate beads into `/Users/josh/Developer/alpsinsurance/.beads`.

## Truth Sources

- Canonical ALPS root bead store:
  `/Users/josh/Developer/alpsinsurance/.beads/issues.jsonl`.
- ALPS frontend bead store:
  `/Users/josh/Developer/alpsinsurance/frontend/.beads/issues.jsonl`.
- `br list --json` from `/Users/josh/Developer/alpsinsurance`.
- Existing flywheel structural follow-up:
  `flywheel-ejw94` (`[auto-doctor:leakage] bead-isolation leakage_count=17`).

## Count Cross-Validation

ALPS reported `beads-leakage count=36`. Fresh probe did not confirm that exact
number:

| source | count |
|---|---:|
| ALPS reported tick | 36 |
| root `.beads/issues.jsonl` unique non-ALPS IDs | 72 |
| `frontend/.beads/issues.jsonl` non-ALPS IDs | 0 |

The root store is the active contaminated substrate. The frontend bead store is
clean.

## Classification

| category | count | evidence |
|---|---:|---|
| test-sandbox | 0 | no disposable fixture/test IDs found |
| refactor-staging | 0 | no refactor staging rows found |
| peer-orch-mistake | 8 | `flywheel-escalate-*`, `created_by=two-blocker-ticks-escalator`, labels include `flywheel-plan` and `two-blocker-ticks-escalate` |
| basename-keying-collision / repo-scope bleed | 64 | `flywheel-wire-*`, `created_by=memory-rule-gate-parity-detector`, descriptions point at flywheel memory paths while `source_repo=/Users/josh/Developer/alpsinsurance` |
| genuine cross-project dependency | 0 | no row requires living as an ALPS bead; cross-project intent should route through flywheel plan/capsule substrate |

## Decision

Sweep decision: `report_only`.

Rationale: every leaked row is an open planning/structural artifact. Hard-delete
would discard evidence; archive-with-TTL should be done only after the producer
scoping bug is fixed or the rows are reminted in the correct flywheel substrate.
This is a repo/bead bleed, not test-sandbox trash.

## Structural Finding

Canonical source: repo-local ALPS `.beads` should contain `alps-*`/`josh-*`
ALPS work.

Observed source: ALPS root `.beads` contains `flywheel-*` rows emitted by global
flywheel doctrine and escalation producers.

Disagreement: ALPS tick count was 36, fresh direct JSONL probe found 72 unique
non-ALPS IDs. The conservative classification is that the active stock is 72
until the producer and archive policy prove otherwise.

Bleed class: repo/bead bleed, with basename/absolute-path scoping failure for
the `memory-rule-gate-parity-detector` rows and peer-orch routing mistake for
the `two-blocker-ticks-escalator` rows.

Cost: 36-72 cross-project rows are enough to make ALPS bead views misleading and
to hide real ALPS ready work behind fleet-doctrine repair work.

Fix surface: existing structural bead `flywheel-ejw94` covers the active
bead-isolation gap. 0dd7 also redirects future two-blocker-tick escalation to
flywheel plan substrate instead of local ALPS bead rows.

Validation probe: after producer fixes, rerun the direct JSONL probe and require
root ALPS non-ALPS ID count to fall to 0 after approved archive/remint.

## Post-Sweep

No sweep was applied. Post-sweep count is intentionally `null`; active leak
stock remains 72 pending structural fix and remint/archive policy.

## ALPS Cross-Ref

Source tick: `alps_loop_20260508T013943Z`.
Follow-up: `flywheel-ejw94`.
