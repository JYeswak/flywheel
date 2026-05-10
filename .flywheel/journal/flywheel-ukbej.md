---
schema_version: journey-entry/v1
bead_id: flywheel-ukbej
task_id: flywheel-ukbej-5bb7a3
worker_identity: CloudyMill
ts: 2026-05-10T20:08:42Z
mission_fitness: adjacent
commit_sha: 0bd86ce
linked_l_rules:
  - L107
  - L52
  - L70
  - L120
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - blocker-discipline-fail-escalation
  - 4-bead-arc-closure
  - counter-reset-after-escalation
  - agent-mail-best-effort-vs-audit-mandatory
---

# flywheel-ukbej — journey entry

Last bead in the blocker-discipline 4-bead arc. nbgp6 shipped the
PASS-path hook this morning; ukbej is its mirror for the FAIL path.
Together they close the doctrine's "AC passes → auto-close" +
"AC fails Nth consecutive → escalate to Joshua" mandates end-to-end.

The shape was clear from nbgp6 — most of ukbej is the symmetric
mirror. But three design choices were worth thinking through:

**Counter reset after escalation.** The doctrine says "If AC fails
Nth time consecutively: escalate to Joshua." Read literally, every
fail past N would escalate again. Bad: page-spam Joshua on a stuck
blocker. Better: escalate ONCE per streak, reset counter, let the
next streak start fresh. Test 14-15 verify the reset semantics. The
counter is incidental state; what matters is that Joshua got paged.
If the next 4 fails also rise to threshold, page again — but it's
a NEW streak, not a continuation.

**Agent Mail best-effort vs audit-row mandatory.** First instinct
was "send first, then write the row." Then I caught myself: what
if the send fails? Doctrine says "evidence appended is mandatory"
— that's the audit row. The notification is the secondary signal.
Reordering: write row FIRST (with agent_mail_status placeholder),
then send (best-effort), then... actually the row needs the
agent_mail_status field IN it. So the order is: send (returns
status string), compose row with that status, append row, reset
counter. If send fails or skips, the row still records WHY
(skipped_no_cli, skipped_flag, skipped_dry_run, failed). Future
audit can detect silent escalations. Filed the pattern.

**AC pure MISMATCH is a separate trauma.** replay-verify's
verdict=PASS/MISMATCH is about determinism (h1 == h2), not the
AC's truth value. If the AC is impure (touches $RANDOM, clock,
etc), MISMATCH says "this AC is broken — re-author it" — that's a
WORKER-time trauma, not a consecutive-fail scenario. ukbej returns
rc=1 + status=ac_pure_mismatch and DOES NOT increment the counter.
Counting impure-AC failures toward escalation would page Joshua
about a worker bug, not a real blocker. Test 16 verifies this.

The 4-bead arc is now load-bearing for the blocker-discipline
doctrine. escalations.jsonl is the single audit-trail ledger;
auto-close + fail-escalator share its row schema (event field
differentiates blocker_auto_closed vs blocker_ac_failed_escalated).
Future incident analysis: jq replay against the ledger to derive
every state transition.

substrate-hygiene-doctrine-cluster (git-stash-discipline +
blocker-discipline) now has runtime enforcement primitives for
both members. The remaining gap is author-time worker-side checks
(refuse to file a blocker without a re-runnable verification_path)
— candidate next bead for the cluster.
