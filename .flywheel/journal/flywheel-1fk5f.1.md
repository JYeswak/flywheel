---
schema_version: journey-entry/v1
bead_id: flywheel-1fk5f.1
task_id: flywheel-1fk5f.1-0d3ef5
worker_identity: CloudyMill
ts: 2026-05-10T18:46:33Z
mission_fitness: adjacent
commit_sha: 5a436c3
linked_l_rules:
  - L107
  - L52
  - L70
  - L120
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - substantive-stub-fillin
  - dispatch-self-test-delivery-identity-fillin
  - 1fk5f-wave-2-sub-bead-1-of-8
---

# flywheel-1fk5f.1 — journey entry

First of the 8 wave-2 sub-beads I decomposed in the previous tick.
This surface is interesting because cmd_run ALREADY writes to a
delivery ledger natively (via the `mark-delivered` python heredoc).
Sister fillins like dsrq1 had to ADD cli_audit_append wiring to
cmd_run; here it was unnecessary — the cmd_run write path was already
bound. The fillin shape adapts.

The validate cross-field invariant on this surface is unusually
clean: `event=delivery_confirmed` implies
`callback_delivery_verified=true`. Both fields in the same row,
ground-truth coupling. The validate function enforces it explicitly.

Three-resolution why-lookup adapted from dsrq1 (which used row
index / ts / bead / substring). Here the third path is
idempotency_key_exact — the natural identity for this surface.
Substring on bare hex strings is noise; not implemented.

Wave-2 progress: 1 of 8 done. The remaining 7 (1fk5f.2 through .8)
follow the same shape applied to:
  .2 dispatch-surface-conflict-probe
  .3 dispatch-trigger-gated-precheck
  .4 idle-pane-auto-dispatch
  .5 ntm-approve-human-gates
  .6 ntm-coordinator-shadow
  .7 ntm-fleet-health
  .8 ntm-pane-sidecar-respawn

Per the decomposition receipt's pre-warning, all three doctrine
gotchas (SIGPIPE/pipefail, local-var-unset-under-set-u,
cli_emit_audit_tail positional order) are already accounted for in
my fillin pattern. None hit during this surface.
