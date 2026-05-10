---
bead_id: flywheel-1fk5f.7
task_id: flywheel-1fk5f.7-d9c2a4
worker_identity: MistyCliff
ts: 2026-05-10T19:25:00Z
mission_fitness: direct
commit_sha: pending
narrative_tags:
  - wave-2-fillin-fourth-this-session
  - emit-hook-pattern-for-loop-driven-surface
  - validate-ntm-bin-confirmed-health-subcommand
---

Fourth wave-2 fillin this session (after 1fk5f.2 + 1fk5f.5 own + 1fk5f.1
peer + 1fk5f.3 peer). Doctor probes 12 substrate dims — the surface is
small (309 lines) but heavily depends on file-system substrate
(out file dir, lock file dir, jsonl-append lib, topology file) plus the
ntm binary it wraps.

Distinguishing wrinkle: the legacy main is a session-iterating while-loop
where `emit()` is the universal per-session output point. Same emit-hook
pattern as 1fk5f.5's emit_json hook, applied here to `emit()`. Each
fleet-health probe of each session now lands an audit row in
$SCAFFOLD_AUDIT_LOG with threshold + restart fields.

Useful sanity check: validate ntm-bin self-tested and returned both
exec_ok=true and health_subcommand_ok=true. The wrapper's entire purpose
is to delegate to `ntm health`, so the second check is load-bearing —
if ntm changed its CLI surface to remove `health`, this wrapper would
silently degrade. The validate subject catches that proactively.

Pattern continuity: wave-2 chain quality at 950-1000 across 4 surfaces
this session. Emit-hook pattern (1fk5f.5 + 1fk5f.7) now established as
the cmd_run-bypass mechanism for surfaces with their own main+parser.
mission_fitness=DIRECT because proactive fleet-health probing is the
inverse of reactive callback-storm discovery.
