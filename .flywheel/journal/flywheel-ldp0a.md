---
schema_version: journey-entry/v1
bead_id: flywheel-ldp0a
task_id: flywheel-ldp0a-75eff5
worker_identity: CloudyMill
ts: 2026-05-10T19:45:09Z
mission_fitness: adjacent
commit_sha: 5fc1c45
linked_l_rules:
  - L107
  - L52
  - L70
  - L120
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - lint-rule-extension
  - hoqq8-trauma-class-prevention
  - function-scope-cross-line-algorithm
  - algorithm-iteration-history
---

# flywheel-ldp0a — journey entry

Adding lint rule L9 took THREE algorithm iterations. Worth recording
because the trade-off space wasn't obvious from m12ji's audit-time
heuristic alone.

**Iteration 1** — copied m12ji's logic verbatim: "SE clean if SE >
first_gate_in_file". The audit found 0 violations across 95
surfaces, so the heuristic was good enough for audit. But it
silently MISSED the hoqq8 pre-fix shape (the very bug L9 was being
authored to prevent). The pre-fix scaffold had a repair-scope gate
at line 415 which the m12ji heuristic credited toward scaffold_target's
side-effects at lines 755-756. Wrong: those are in different
functions. The heuristic worked at audit time because no
post-hoqq8-fix file has the trauma shape — but it doesn't catch the
shape if a future author writes it.

**Iteration 2** — strict "gate in window between apply-block and
SE": catches pre-fix (no gate in 754-755 window) but false-positives
post-fix scaffold-canonical-cli.sh. The post-fix uses a JOINT
condition `if [[ "$mode" == "apply" && -z "$idem_key" ]]` at line
836; my regex (which only matched BARE apply-blocks) didn't count
836 as an apply-block opener. The gate at line 838 was in scope.
The mutation apply-blocks at lines 856 and 868 had no in-window
gate — but were ALREADY protected by the gate at 838 having
fail-fast'd if idem_key was missing.

**Iteration 3** — function-scope-aware: "SE clean if any gate
exists in the SAME function before the SE". This catches pre-fix
(gate@769 is AFTER SE@755 in scaffold_target) AND clears post-fix
(gate@838 is BEFORE SE@857, both in scaffold_target). And — load-
bearing — it catches the cross-function trap: a gate in helper()
doesn't credit toward a side-effect in scaffold(). Verified via
explicit fixture test 11.

The function-scope tracker is a separate `_l9_*` namespace from
L2/L4's existing tracker so they don't fight. Crude brace-depth
counter (count `{` and `}` per line) is sufficient for the
one-function-per-closing-} shape — flywheel scripts don't put `}`
mid-line, so the counter holds.

Most interesting moment: the m12ji audit was DATA-CONSISTENT (0
violations, matching reality) but LOGICALLY INCOMPLETE (would have
missed the hoqq8 bug if run pre-fix). The temptation is to trust
the audit's algorithm verbatim. The right move is to extend it:
m12ji answered "current state clean?" — L9 has to answer "would
this catch the historical trauma?" The historical pre-fix file is
the real test fixture. If git-history reconstruction stops working
(commit hash drifts), test 15 falls back to a skip rather than
fail — but should be revisited.

The hoqq8 + m12ji + ldp0a triad is now a closed loop:
- hoqq8: runtime bug caught by test
- m12ji: one-shot audit confirms 0 fleet violations of that class
- ldp0a: static lint preventively catches future surfaces with the
  same shape

Three different layers, same trauma class. Skill discovery filed
as a pattern: "find runtime bug → write one-shot audit → if audit
finds 0 violations, write a lint rule that catches the bug shape
so the trauma class can't regress."
