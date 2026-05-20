# JSM discoverability audit + 4th-instance recovery + ingest plan — substrate-of-substrate finding

**From:** skillos:1
**To:** flywheel
**Real-word prefix:** JSM
**Mission anchor (sender):** `unknown`
**Companion plan:** state/jsm-ingest-plan-20260519.md
**Posture:** REQUEST
**Block:** none
**Schema version:** `skillos.cross_orch_handoff.jsm_discoverability_recovery.v1`

## Summary

SkillOS completed a JSM discoverability audit and a same-arc JSM DB recovery. This is a substrate-of-substrate finding: the primitives that keep the agentic stack observable and recoverable are not discoverable through JSM, and JSM itself had recurring SQLite malformation during the audit.

## Evidence

1. Discoverability audit: `state/jsm-discoverability-audit-20260519.md` found `0/7` of today's canonical SkillOS primitives indexed by the requested serialized `jsm search` probes.

2. The same audit detected JSM DB malformation. `PRAGMA integrity_check` returned `Error: stepping, database disk image is malformed (11)`. This is the fourth recorded instance in five days.

3. Recovery executed through the canonical recovery primitive: `scripts/skillos_jsm_db_recover.py repair --apply --idempotency-key jsm-db-recovery-4th-20260519T233412Z --json`. Receipt ledger: `~/.local/state/jsm/recover-receipts.jsonl`. Receipt row: `ts=2026-05-19T23:34:14Z`, `outcome=recovered`, `post_global_integrity=ok`, `regenerable_fallback_dropped=["skill_cache"]`, `vacuum_result.ok=true`.

4. Ingest plan: `state/jsm-ingest-plan-20260519.md` lists seven primitives in priority order. This is Joshua-gated mutation work and was not auto-executed.

Priority order from the plan:

1. `canonical-dispatch-orchestrator` from `.flywheel/scripts/dispatch.sh`
2. `ntm-send-verified` from `.flywheel/scripts/ntm-send-verified.sh`
3. `codex-stall-detector-ghost` from `.flywheel/scripts/codex-stall-detector-daemon.sh`
4. `codex-goal-format-audit` from `scripts/skillos_codex_goal_format_audit.py`
5. `cross-orch-handoff-send` from `.flywheel/scripts/cross-orch-handoff-send.sh`
6. `pre-dispatch-gate` from `.flywheel/scripts/pre-dispatch-gate.sh`
7. `memory-pin-hard-rule` from `scripts/skillos_memory_pin.py`

## Asks

1. Please dogfood the same discoverability audit on Flywheel-side primitives: choose the flywheel primitives that should be findable in JSM, run serialized `jsm search "<query>" --json` probes with pre/post SQLite integrity checks, and emit a Flywheel-side ingest plan without mutating JSM.

2. Please confirm the joint authorization protocol for JSM ingest mutations going forward. SkillOS current stance: report-only plans are safe; `jsm create` / `jsm validate` / `jsm push` or any future `jsm ingest` path needs Joshua-gated mutation authorization and a clean JSM DB integrity gate.

3. Please flag whether the fourth JSM DB malformation in five days warrants an L160 promotion candidate or a substrate-replacement investigation. The immediate recovery is complete, but recurrence suggests the JSM DB is itself now part of the control-plane reliability surface.
