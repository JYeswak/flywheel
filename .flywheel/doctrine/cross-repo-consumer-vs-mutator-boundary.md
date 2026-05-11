---
title: "Cross-Repo Consumer vs Mutator Boundary"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
---

# Cross-Repo Consumer vs Mutator Boundary

Version: `cross-repo-consumer-vs-mutator-boundary/v1`
Owner: dispatch-author + workers handling flywheel↔skill-substrate work
Status: canonical, shipped 2026-05-11
Source bead: flywheel-2xdi.93 (memory-without-cross-link wire-in)

## TL;DR

When flywheel-scope work touches `~/.claude/skills/` or `~/.claude/commands/`,
distinguish **CONSUMER** (read/call) from **MUTATOR** (edit/delete). Consumer
is canonical-clean and proceeds normally; mutator requires JSM-status check +
patch-artifact discipline.

## Canonical memory source

This doctrine summarizes
`feedback_cross_repo_consumer_vs_mutator_distinction.md` — the META-RULE
memory (N=2+ session-instances) that codifies the boundary. Read the
memory for full pattern detail, examples, and Joshua-authorized escape
hatch protocol.

## The two patterns

### Consumer (canonical, no deferral)

flywheel script READS or CALLS into skill-substrate. No edits to `.claude/`.

Discipline:
- Absolute or `$HOME`-relative path to `.claude/skills/<x>/`
- Graceful degradation if path missing (safe default, not crash)
- Document the cross-repo call in evidence/notes
- Test all 4 cases: present-valid, present-invalid, missing, malformed

Examples: `flywheel-loop` sourcing skill-substrate libs;
`worker-auto-respawn-watchdog.sh` calling `worker-deep-liveness-probe.sh`;
`file_length_doctor_json` from skill-substrate lib.

### Mutator (requires authorization or deferral)

flywheel-scope task needs to EDIT files under `~/.claude/skills/` or
`~/.claude/commands/`.

Discipline:
1. Check `jsm list <skill>` — is target JSM-managed?
2. **JSM-unmanaged:** direct mutation allowed when paired with
   `jsm-import-ready` patch artifact at
   `.flywheel/audit/<bead>/patches/`
3. **JSM-managed:** direct mutation FORBIDDEN; write
   `*.patch` + `*.proposed` + `apply-instructions.md` patch artifact
   and flag `orch_action_required=jsm_push_<bead>_patch`
4. For DELETIONS in JSM-unmanaged: write
   `deletion-tombstone.md` (sister to additive patch artifact)

Examples this session: flywheel-2xdi.60.1 (jsm-unmanaged direct mutation),
flywheel-xhevf (jsm-managed patch-artifact-only), flywheel-b6p1m
(jsm-managed patch-artifact-only), flywheel-d6zk1.1 (jsm-unmanaged
deletion-tombstone).

## When to consult

- **Bead author:** state the pattern explicitly in the title via
  `[cross-repo-consumer]` or `[cross-repo-mutator]` tag
- **Dispatch builder:** for mutator beads, include `jsm list <skill>`
  evidence in bead body (managed vs unmanaged)
- **Worker:** if bead lacks explicit classification, derive from the
  action (any `Edit`/`Write` under `.claude/` is mutator)
- **Orchestrator:** when worker queue is exhausted AND mutator-class
  default-deferred N≥5 times, surface to Joshua via AskUserQuestion
  for "force cross-repo dispatch" authorization

## Anti-pattern

Flagging a CONSUMER task as "cross-repo deferred" when no edits happen.
Reading from `.claude/skills/` is NOT a boundary violation. Only writing is.

Trauma class: META-EXTRACTION-DRIFT — confusing "cross-repo" (any path
touch) with "cross-repo-mutator" (write).

## Sister doctrine

- `.flywheel/doctrine/dispatch-author-skill-routing-contract.md` — skill
  routing for dispatch authors
- Dispatch template `SKILL-ENHANCE JSM DISCIPLINE BLOCK` — runtime
  enforcement of the mutator pattern
- `project_skillos_separated` (memory) — skill-substrate is its own
  ntm session, not flywheel scope
- `feedback_bead_hypothesis_starting_point_not_conclusion` (memory,
  N≥12) — verify hypothesis (including consumer-vs-mutator
  classification) before acting

## Conformance

A bead's worker callback for cross-repo work proves conformance via
one of:
- `no_direct_skill_mutation_reason=jsm_managed_patch_artifact_written`
- `no_direct_skill_mutation_reason=jsm_unmanaged_with_paired_patch_artifact_written`
- `no_direct_skill_mutation_reason=jsm_unmanaged_with_import_ready_tombstone_artifact_written`
- (consumer-class) explicit graceful-degradation test evidence cited

Missing any of these on a cross-repo bead is a doctrine drift.
