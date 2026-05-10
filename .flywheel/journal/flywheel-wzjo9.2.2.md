# Journey entry — flywheel-wzjo9.2.2

**Bead**: P2 wave-2.0b-b (parent: flywheel-wzjo9.2, lane: flywheel-wzjo9)
**Surface**: `.flywheel/scripts/recovery-baseline-snapshot.sh` — bash wrapper around inline python3 heredoc that writes a `flywheel-recovery-baseline/v1` manifest + tarball for 8 sessions per recovery-system-2026-05-01 plan
**Sister exemplars (wave-2.0a CLOSED 8/9 avg 984)**: wzjo9.1.1 (970), 1.2 (980), 1.3 (980), 1.4 (1000), 1.6 (980), 1.8, 1.9 (1000); plus 1fk5f.{1..8} (974)
**Result**: 25/25 in-bead PASS + 119 sister assertions clean; 1000/1000

## Arc

1. **Inspect** — read 334-line surface; bash entrypoint is two lines (`#!/usr/bin/env bash; set -euo pipefail`) plus `python3 - "$@" <<'PY' ... PY`. All real logic is the python heredoc.
2. **Scaffold dry-run + apply** — `--apply --idempotency-key=flywheel-wzjo9.2.2-pilot` → 334 → 580 lines, 18 TODOs, baseline 13/13 PASS. No-collision case.
3. **Pattern observation** — the bash-wraps-python idiom is a natural fit for the scaffolder: it appends the canonical-cli block above the python heredoc invocation. Scaffold intercepts canonical args BEFORE the heredoc ever fires; default invocation falls through to python unchanged.
4. **Module-state lift** — added 9 RBS_* vars mirroring the python's argparse defaults (`FLYWHEEL_RECOVERY_SNAPSHOT_DIR`, `FLYWHEEL_RECOVERY_STATE_DIR`, etc.) plus 3 lifted constants (manifest schema `flywheel-recovery-baseline/v1`, retention 14/8, protected sessions, sessions array). Avoids duplicating the python's logic but lets the bash scaffold probe substrate independently.
5. **Substantive fillin** — sister 1.6 anchor / 1.9 codex-orient duplicate pattern:
   - 8 per-surface schemas incl. new `manifest` variant pinning the manifest's actual `schema_version`
   - Single-printf topic_help bodies (gl7om SIGPIPE/pipefail safe) referencing actual substrate paths
   - 8-probe doctor with three-state aggregate (pass / warn / fail); warn class for ntm-config + source-plan unreadable but core deps green
   - Health that `find $RBS_SNAPSHOT_DIR -name 'baseline-*.manifest.json'` → latest + age + count + audit_log_stale
   - 3 repair scopes (snapshot-dir / audit-log / none); apply refusal contract honored
   - 3 validate subjects (manifest / config / snapshot-dir); manifest validate reads latest `baseline-*.manifest.json` + checks `.schema_version == flywheel-recovery-baseline/v1`
   - Audit delegates to cli_emit_audit_tail (path-then-schema)
   - 6 why ids (baseline / retention / protected / trigger / sessions / schema)
6. **Header comment** — 18th TODO match was in a `# This block is APPENDED...` doc comment referencing the pattern; rewrote to "substantive fillin landed flywheel-wzjo9.2.2" so `grep -c` returns 0.
7. **Test extension** — 13 → 25 assertions. New: doctor 8 probes named, health structured fields, 2 repair --apply scopes with live mkdir verification, 3 validate subjects (manifest/config/snapshot-dir-absent), schema manifest variant, why 5-id coverage + not_found, cli_audit_append wired (doctor + repair).

## Discoveries

None this bead. No-collision substantive-fillin shape was already proven. The bash-wraps-python pattern surfaced no new doctrine — the scaffolder's intercept positioning naturally handles it (canonical args intercepted before heredoc invocation; default invocation passes through). Legal no-discovery reason: task stayed inside canonical-cli-scoping + scaffold-canonical-cli skills.

## Wave-2.0b status update

After this bead: **1/9 closed** (2.2). Sister wzjo9.2.1 in flight pane 4, wzjo9.2.3 in flight pane 3. Wave-2.0a CLOSED 8/9 (1.5 data-decided-skipped backup); avg 984/1000.

## Cross-bead-pattern note

| Pattern | Variant | Beads |
|---|---|---|
| Substantive-duplicate fillin | no-collision (target has zero canonical verbs) | 1.1, 1.2, 1.3, 1.6, 1.9, **2.2** |
| Delegate fillin | verb-collision (target has canonical verbs natively) | 1.4 |
| State-lift before scaffold | scaffold cmd_* needs target module state | 1.4, 1.9, **2.2** (RBS_* vars) |
| Bash-wraps-python heredoc | scaffold above python3 - "$@" <<'PY' | **2.2** (first in wave 2.0b) |
| Pipefail-safe validate | return 0; status field carries verdict | 1.6, 1.9, **2.2** |
| `cli_emit_audit_tail` positional | path-then-schema (b9dfv) | all |
| Single-printf topic_help | gl7om SIGPIPE/pipefail discipline | all |
| Header-comment-substring TODO | rewrite without literal substring | **2.2** (first instance noted) |
