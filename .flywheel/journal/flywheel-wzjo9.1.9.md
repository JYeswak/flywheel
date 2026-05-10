# Journey entry — flywheel-wzjo9.1.9

**Bead**: P2 wave-2.0a-i (parent: flywheel-wzjo9.1, lane: flywheel-wzjo9)
**Surface**: `~/.claude/skills/.flywheel/bin/flywheel-codex-orient` (Codex SessionStart parity reader)
**Sister exemplars (5 closed)**: 1.1 (970), 1.2 (980), 1.3 (980), 1.4 (1000), 1.6 (980); avg 982/1000
**Result**: 25/25 in-bead PASS + 128 sister assertions clean; 1000/1000

## Arc

1. **Inspect** — read 95-line surface; non-mutating snapshot reader with 5 module vars (FLYWHEEL_HOME, FW, SNAPSHOT_BIN, OUT, STALE_SECONDS), 7 helper fns (epoch parsers, is_fresh, refresh_snapshot, print_snapshot), 3-branch terminal logic (fresh → refresh → live-fallback). Zero canonical verbs → **no-collision case** (substantive-duplicate fillin, NOT delegate).
2. **Scaffold dry-run** — verified scaffolder receipt, no verb collision detected.
3. **Scaffold apply** — `--apply --idempotency-key=flywheel-wzjo9.1.9-pilot` → 95 → 341 lines, 18 TODOs, test scaffold generated.
4. **Module-state lift** — moved 5 module vars (FLYWHEEL_HOME/FW/SNAPSHOT_BIN/OUT/STALE_SECONDS) ABOVE the scaffold init so doctor/health/validate can read them without function-resolution-order issues.
5. **Strict-mode upgrade** — switched `set -u; set -o pipefail` → `set -euo pipefail` to satisfy L5 lint.
6. **Substantive fillin** — substantive-duplicate per sister 1.6 (anchor):
   - 8 per-surface schemas
   - Single-printf topic_help (gl7om SIGPIPE/pipefail safe)
   - 8-probe doctor with pass/warn/fail aggregate
   - Audit-log-tail health with snapshot_age_seconds + recent_runs + last_run_ts + audit_log_stale
   - 3 repair scopes (snapshot/audit-log/none) + canonical refusal contract
   - 3 validate subjects (snapshot/binaries/config) + info-shape when no subject (matches sister 1.6 pattern)
   - Audit via cli_emit_audit_tail (path-then-schema positional)
   - 3 why ids (stale/snapshot/refresh) with multi-resolution (found/not_found/unavailable)
7. **cli_audit_append wires** — 6 terminal envelopes: doctor, health, repair, validate, why, + 4 outcomes on the original run path (fresh, refreshed, live_fallback, no_binary)
8. **Test extension** — 13 → 25 assertions (12 new fillin-specific): doctor probes, health structured fields, repair scope-specific apply, 3 validate subjects, schema audit-row variant, why 3-id coverage, why not_found, cli_audit_append wired (doctor + run path).
9. **Sister-pattern bug** — initial cut had `[[ -w "$OUT" 2>/dev/null ]]` syntax error; rewrote with explicit `out_writable=0/1` flag.
10. **Test pipefail** — initial cut had validate `return 1` on fail, but test pipeline `validate | jq -e` with `pipefail` propagated validate's exit-1 into the `if`. Fix: emit envelope but return 0 (status field carries verdict, exit code stays 0 for pipeline composability). Matches sister 1.6 anchor pattern.
11. **Validate default subject** — when no subject, emit `status:"info"` envelope listing valid subjects (sister 1.6 anchor pattern verbatim).
12. **Repair scope `none`** — accept as no-op (empty planned/actual_actions). Test scaffold uses `--scope none` as the generic placeholder.

## Discoveries

None this bead. The no-collision substantive-fillin pattern was already documented across 4 closed sisters (1.1/1.2/1.3/1.6). The 11-step shape held. Legal no-discovery reason: task stayed inside the existing canonical-cli-scoping + scaffold-canonical-cli skills with no convergent_evolution / meta_rule / trauma_class signal.

## Wave-2.0a status update

After this bead: **6/9 closed** (1.1, 1.2, 1.3, 1.4, 1.6, 1.9). Remaining:
- **1.5** — deferred legacy backup
- **1.7** — in flight
- **1.8** — in flight

## Pattern reinforcement

| Pattern | Variant | Bead |
|---|---|---|
| Substantive-duplicate fillin | no-collision case | 1.1, 1.2, 1.3, 1.6, **1.9** |
| Delegate fillin | verb-collision case | 1.4 |
| State-lift before scaffold | when scaffold cmd_* needs target's module state | 1.9 (this), 1.4 |
| Pipefail-safe validate | always return 0; status field carries verdict | 1.6, **1.9** |
| `cli_emit_audit_tail` positional | path-then-schema (b9dfv) | all |
| Single-printf topic_help | gl7om SIGPIPE/pipefail discipline | all |
