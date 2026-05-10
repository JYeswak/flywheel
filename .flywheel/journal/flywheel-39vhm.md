---
schema_version: journey-entry/v1
bead_id: flywheel-39vhm
task_id: flywheel-39vhm-44fa55
worker_identity: CloudyMill
ts: 2026-05-10T17:38:55Z
mission_fitness: adjacent
commit_sha: 37af601
linked_l_rules:
  - L107
  - L52
  - L70
  - L120
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - substantive-stub-fillin
  - dispatch-canonical-cli-validator-fillin
  - wgitr-decomposition
---

# flywheel-39vhm — journey entry

Substantive fill-in for the dispatch-canonical-cli-validator surface
(18 TODO markers → real impls bound to the live decision ledger).

Most interesting moment: `validate ledger --json` against the real
ledger returned **pass=9 fail=0 across 9 real rows**, including the
cross-field invariant check (refuse-implies-non-empty
missing_elements). That's the doctrine surfacing as code: the
canonical-cli surface now mechanically enforces what the validator
prose has been claiming since flywheel-ws02m scaffolded the stub.

Bug caught en route: my first cut of `audit` delegated to
`cli_emit_audit_tail` with reversed positional args
(schema-then-path instead of path-then-schema, per helpers.sh:427).
Test 10 still passed because the helper's "missing" disposition
emits a valid envelope with `.command == "audit"`. The 9-real-rows
spot-check (audit | jq '{row_count, last_ts}' returning 0/null) was
what surfaced it. Lesson: contract envelope tests prove SHAPE; only
real-data probes prove SUBSTANCE.

Second bug caught: `validate --json` initially treated --json as
the subject because my parser read positional first. Default-to-
`ledger` plus a flag-skipping prelude fixed both checker (13/13)
and surface test 9 in one edit. The lesson here is the same one
from prior fillins: scaffold tests are scaffold-shaped (envelope
exists), not surface-shaped (envelope is correct for the surface
under inspection).

Wgitr decomposition continues. After this, dispatch-canonical-cli-
validator joins agentmail-identity-canonical-validator + storage-
probe + storage-pause-auto-resume + doctrine-sync as filled. Next:
mae86, vc29u, zjm8v, gam2k, j0zuh, 4pwc5 + the remaining unwave-1
surfaces.
