---
schema_version: journey-entry/v1
bead_id: flywheel-1fk5f.4
task_id: flywheel-1fk5f.4-d9c641
worker_identity: CloudyMill
ts: 2026-05-10T18:56:46Z
mission_fitness: adjacent
commit_sha: 644cd5b
linked_l_rules:
  - L107
  - L52
  - L70
  - L120
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - substantive-stub-fillin
  - idle-pane-auto-dispatch-fillin
  - 1fk5f-wave-2-sub-bead-4-of-8
  - subshell-state-mutation-discovery
---

# flywheel-1fk5f.4 — journey entry

Sub-bead 4 of 8 in the 1fk5f wave-2 decomposition. This surface is
structurally different from 1fk5f.1 — it's a thin wrapper around
`ntm wait` + `ntm assign`, no native ledger. Had to ADD
cli_audit_append wiring (sister 1fk5f.1 had cmd_run already writing
its own ledger natively).

Most interesting moment: caught a subshell-state-mutation bug.
`run_dispatch` resolves REPO via
`REPO="${REPO:-$(session_repo "$SESSION")}"`. In the parent shell,
that would propagate. But run_dispatch runs INSIDE
`__run_payload="$(run_dispatch)"` — a command-substitution subshell.
Mutations don't escape the subshell. So my first cut wrote
`repo: ""` to the audit log because the parent shell's $REPO was
still empty.

Fix: pull `.repo` from the captured $__run_payload JSON, not from
the parent's $REPO. The payload is the source of truth for what
run_dispatch saw.

This generalizes cleanly. Filed as a skill discovery:
**subshell-state-mutation-doesnt-propagate-pull-from-payload-pattern**.
Any cmd_run-with-cli_audit_append wiring that captures run logic in
`` and tries to read "shared" globals afterwards is a latent bug.
The audit-append envelope should always be derived from the payload,
which is what the run actually computed.

Two of the three known doctrine gotchas DID hit on this surface:
- gl7om SIGPIPE/pipefail multi-printf — applied (single-printf)
- xmafr/dsrq1 cli_emit_audit_tail positional order — applied (path
  first, schema second)
- dsrq1 local-var-unset-under-set-u — used `local row=""
  resolution=""` form

The third (subshell-state) is new. Filed.

Wave-2 progress: 2 of 8 done (1fk5f.1 + 1fk5f.4). Six remaining
(.2, .3, .5, .6, .7, .8). Apply-specs already in place from the
decomposition tick.
