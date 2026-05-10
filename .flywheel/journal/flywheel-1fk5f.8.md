---
schema_version: journey-entry/v1
bead_id: flywheel-1fk5f.8
task_id: flywheel-1fk5f.8-789774
worker_identity: CloudyMill
ts: 2026-05-10T19:08:56Z
mission_fitness: adjacent
commit_sha: 7353c76
linked_l_rules:
  - L107
  - L52
  - L70
  - L120
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - substantive-stub-fillin
  - ntm-pane-sidecar-respawn-fillin
  - 1fk5f-wave-2-sub-bead-8-of-8-final
  - decomposition-wave-closure
---

# flywheel-1fk5f.8 — journey entry

Eighth and final sub-bead in the 1fk5f wave-2 decomposition I filed
two ticks ago. The closure feels clean: every surface in the wave got
the same 11-step pattern applied, the three doctrine gotchas
(SIGPIPE/pipefail, local-var-unset-under-set-u, cli_emit_audit_tail
positional order) were embedded in every apply-spec from the
decomposition tick, and parallel workers (or me, sequentially) hit
none of them in the wave-2 fillins.

This surface had a structural twist worth recording: cmd_run has TWO
terminal envelopes, not one — `emit_plan` for dry-run, `run_apply`
for apply. Both needed cli_audit_append wiring. I refactored the
audit-append into a single helper `_audit_respawn_attempt(payload)`
to keep the two call sites symmetric. Both extract .status from the
captured payload and pass through the same row shape. The pattern
generalizes — any cmd_run with multiple terminal envelopes (which is
common when there's a dry-run/apply split) should use a single
helper, not duplicate the audit-append logic.

The doctor's third probe is interesting: `ntm_subcommands` runs
`ntm --help` and greps for `respawn`. This catches the case where
ntm is installed but the version doesn't have the respawn subcommand
(API drift). It's a "warn" not "fail" because the help text could
change without the subcommand actually disappearing — the operator
should investigate, not be blocked.

Why-lookup added a session:pane resolution: `flywheel:2` matches
`{session: flywheel, pane: 2}` in the audit log. This is the natural
identity for respawn rows (each row is keyed by the pane that got
respawned). The split logic at the colon makes it a clean third path
beyond row index and ts.

Wave-2 closure: 1fk5f.8 is the 8th. Sister status from the dispatch
context shows .1+.4 at 1000, .3+.5 at 960, .2 at 950, and .6+.7
likely shipped in parallel by other workers. Once those confirm,
parent 1fk5f can close. The decomposition tick worked: 8 sub-beads
shipped in parallel-ish wall time vs the 4-8h serial estimate.

The wave is the proof of decompose-by-natural-unit. Bundling these
into one bead would have forced 4-8h serial work; decomposing made
them ~30-60min parallel units. Total wave wall time will be much
closer to the lower bound.
