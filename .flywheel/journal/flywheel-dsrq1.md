---
schema_version: journey-entry/v1
bead_id: flywheel-dsrq1
task_id: flywheel-dsrq1-469746
worker_identity: CloudyMill
ts: 2026-05-10T18:22:30Z
mission_fitness: adjacent
commit_sha: 427a4ef
linked_l_rules:
  - L107
  - L52
  - L70
  - L120
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - substantive-stub-fillin
  - br-close-with-gate-fillin
  - gf2rj-beads-substrate-lane
  - local-var-unset-under-set-u-discovery
---

# flywheel-dsrq1 — journey entry

Beads-substrate lane wave-1 fillin for the close-with-gate wrapper.
Closes the read/write loop on the close-attempt audit log: cmd_run
WRITES on every terminal (schema-fail / gate-fail / close-fail /
close-success), surfaces READ via doctor/health/audit/validate/why.

Most interesting moment: caught a latent `set -u` bug. Initial
`scaffold_cmd_why` used `local row resolution=""`. In Bash this
parses as: declare `row` (no value), then `resolution=""`. So
`row` is declared but never set. Under `set -euo pipefail`, the
subsequent `[[ -z "$row" ]]` raised "unbound variable". The bug
only surfaced when `why` was invoked with a NON-numeric id — the
numeric branch sets `row` first, masking the issue. The fix is one
character: `local row="" resolution=""`. The discipline lesson is
broader: every `local var1 var2=value` declaration in scaffold
helpers should be audited under `set -u`. I have a hunch sister
fillins (39vhm, gl7om) escaped this only because their why-functions
hit jq directly (which initializes everything internally).

Second moment: the four-resolution why-lookup. Dispatch said
"provenance lookup (numeric row index or substring match)". I
extended that to four paths: numeric row index → ts exact → bead
exact → substring (bead/task_id/reason). Each path sets
`resolution` so the operator can see WHICH path matched. This is
exactly the kind of UX detail that distinguishes "the surface is
filled" from "the surface is useful" — same envelope shape, far
better operator ergonomics.

Third: cmd_run audit wiring. Four terminals all needed
`cli_audit_append` calls with the right `failure_class` and
per-gate exit codes. Refactored into a single helper
(`_audit_close_attempt`) to keep the four call sites symmetric.
The audit row carries `schema_rc / gate_rc / close_rc` so the
operator can see at a glance which gate caught the close.

Beads-substrate lane wave-1 advances. Sister beads
qprlj+eqcsa already shipped per dispatch context; dsrq1 closes
the wgitr-extension fork for this surface.
