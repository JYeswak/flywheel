# flywheel-ulha Identity Deferral Evidence

bead: flywheel-ulha
generated_at: 2026-05-08T00:00:00-06:00
schema_version: identity-deferral-evidence/v1

## DID

| AG | status | evidence |
|---|---|---|
| 1 | PASS | Read `AGENTS.md` and `.flywheel/AGENTS-CANONICAL.md`; highest observed L-rule is L137, so this doctrine uses L138. |
| 2 | PASS | Read `.flywheel/doctrine/failure-taxonomy.md`; cited canonical class `file_reservation_conflict`. |
| 3 | PASS | Authored `.flywheel/doctrine/identity-deferral.md` with L138, trigger conditions, required reread behavior, forbidden outputs, doctor fields, and Joshua lens. |
| 4 | PASS | Added L138 to `AGENTS.md` and `.flywheel/AGENTS-CANONICAL.md`. |
| 5 | PASS | Referenced `.flywheel/validation-schema/v1/identity-registration-deferral.schema.json` and `tests/identity-deferral-receipt.sh`. |
| 6 | PASS | Documented doctor fields `deferred_count`, `deferred_rows`, and `receipt_honored`. |
| 7 | PASS | `.flywheel/canonical-paths.txt` updated after the active reservation conflict cleared; added doctrine, schema, doctor surface, and test entries. |

did: 7/7
didnt: did not touch `.flywheel/cli-registry.yml`, `.flywheel/scripts/canary-secret-scan.sh`, or `.flywheel/doctrine/failure-taxonomy.md`.
gaps: none

## Doctrine Summary

L138 says identity decisions are state reads, not dispatch-time memory. If an
AGENTS or Beads ownership surface is reserved, the worker defers identity
decisions. After the reservation clears, the worker re-reads AGENTS, re-reads
the Agent Mail registry row, resolves by `(session, pane,
fleet_mail_project_key)`, honors active `identity-registration-deferral/v1`
receipts, and only then sends Agent Mail or reports identity fields.

## Acceptance Gates Addressed

- AG1 PASS: `AGENTS.md` and `.flywheel/AGENTS-CANONICAL.md` now include L138,
  a sibling rule to the Agent Mail identity doctrine family.
- AG2 PASS: L138 and `.flywheel/doctrine/identity-deferral.md` reference
  `.flywheel/validation-schema/v1/identity-registration-deferral.schema.json`
  and `tests/identity-deferral-receipt.sh`.
- AG3 PASS: L138 documents doctor fields `deferred_count`, `deferred_rows`, and
  `receipt_honored`.
- AG4 PASS: canonical doctrine surfaces were updated only after Agent Mail
  reservation checks completed.
- AG5 PASS: `.flywheel/canonical-paths.txt` now includes the doctrine, schema,
  doctor, and test surfaces.
- AG6 PASS: `sync-canonical-doctrine.sh --dry-run --json` ran and preserved the
  identity deferral schema fields:
  `identity_deferral_schema_source`, `identity_deferral_schema_hash`,
  `identity_deferral_schema_target_count=53`,
  `identity_deferral_schema_drifted_count=1`, and
  `identity_deferral_schema_synced_count=0`.
- AG7 PASS: file reservations were taken before edits; no RoseIsland,
  RusticCrane, pane 2, or pane 4 work was overwritten.

## Failure Taxonomy Integration

The new doctrine cites `.flywheel/doctrine/failure-taxonomy.md`, where the
canonical class for reservation contention is `file_reservation_conflict` with
`retry_policy=manual`. This prevents future callbacks from inventing one-off
strings such as reservation-holder-specific blocker names.

## Joshua Lens

PASS. This is not bare mission fit. Identity is state, not an event. A 25-year
operations manager expects every shift change to leave a runbook for who owns
what; minting identity from memory is the rookie mistake the runbook prevents.
This doctrine creates turnover resilience because a future operator can wait
for the reservation to clear, re-read the source of truth, and recover the
stable session:pane:project owner without knowing yesterday's mailbox name.

## Public Lens - Publishability Bar / Three Judges / Seven Facets

Would-they-fork-and-star evidence quality: PASS.

- F1 README front-door: YES for this doctrine-only bead because the public
  operator entry is the canonical AGENTS doctrine surface plus canonical paths,
  not a README landing page.
- F2 Doctrine clarity: YES. L138 states when the deferral triggers, what to
  re-read after the reservation clears, and which outputs are forbidden.
- F3 Doctor/health/repair triad: YES. The rule names `flywheel-loop identity
  --doctor --json` and the fields `deferred_count`, `deferred_rows`, and
  `receipt_honored`.
- F4 Executable tests: YES. `bash tests/identity-deferral-receipt.sh` passed
  with 6/6 fixture checks.
- F5 Idempotent install + uninstall: YES for the doctrine surface because it is
  append-only L-rule/docs plus canonical-path entries; propagation remains
  dry-run/apply through `sync-canonical-doctrine.sh`.
- F6 Code aesthetic: YES. The rule is split into doctrine, canonical AGENTS
  entry, canonical path index, and receipt evidence instead of pane-scrollback
  lore.
- F7 Demo-ability: YES. A reviewer can inspect L138, run the identity-deferral
  fixture, and see the exact `file_reservation_conflict` integration without
  oral explanation.

## Socraticode

- `socraticode_queries=4`
- `indexed_chunks_observed=40`

## Reservation Note

Agent Mail reservation attempt granted the owned doctrine and AGENTS paths, but
reported an active conflict on `.flywheel/canonical-paths.txt` held by
`RusticCrane` until `2026-05-08T05:22:55Z`. I sent an Agent Mail note asking for
release and did not edit that file while the conflict was active. A later
reservation retry returned no conflicts, after which the canonical path entries
were added.
