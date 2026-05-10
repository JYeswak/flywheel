---
bead_id: flywheel-1fk5f.5
task_id: flywheel-1fk5f.5-4880c4
worker_identity: MistyCliff
ts: 2026-05-10T19:10:00Z
mission_fitness: direct
commit_sha: pending
narrative_tags:
  - wave-2-fillin-third-this-session
  - emit_json-hook-pattern-for-cmd_run-bypass-surfaces
  - wrapper-namespace-assertion-guards-rename-drift
---

Third wave-2 fillin this session (after 1fk5f.2 own + 1fk5f.1 peer).
Surface: `ntm-approve-human-gates.sh` — the human-in-the-loop approval
gate wrapper.

Distinguishing wrinkle for this surface: the legacy main has its own
`parse_args` + `cmd_check` flow that BYPASSES the scaffold's cmd_run
slot entirely (the wrapper isn't a "run by default" surface; it's a
verb-required CLI). Apply-spec point 10 ("cmd_run wiring") still
applies in spirit — the canonical surface needs ledger writes from
the legacy execution path. Solution: hooked `cli_audit_append` INSIDE
`emit_json` (right before its `return $exit_code`), so every wrapper
invocation that emits a JSON envelope also lands a row in
$SCAFFOLD_AUDIT_LOG with gate/subcommand/decision fields. emit_json
is the universal terminal for this wrapper, so the hook is
universally reached without touching parse_args or main.

Doctor adds a load-bearing `wrapper_namespace_assertion` check:
SCAFFOLD_WRAPPER_NS should literally equal "ntm-approve-human-gates".
That guards against script-rename drift where the file gets renamed
but the legacy WRAPPER_SURFACE constant doesn't. Future fillins on
similar wrapper surfaces should consider this same check.

Pattern continuity: 1fk5f.5 sits cleanly with 1fk5f.1 (1000/1000)
and 1fk5f.2 (950/1000). Wave-2 chain now 3+ deep this session.
mission_fitness=DIRECT because the human-approval boundary is the
load-bearing line between bounded-autonomy and unbounded-autonomy.
