# flywheel-ftj0m Compliance Pack

## Summary

Status: PASS  
Compliance score: 930/1000  
Mission fitness: adjacent to `continuous-orchestrator-uptime-self-sustaining-fleet`

## Did

1. Audited `skill-autoresearch` SKILL.md, references, and scripts. Gate 6 is
   explicitly Python-operational: Python files in `scripts/`, dataclasses,
   argparse, `--config`, and JSON output.
2. Added `.flywheel/doctrine/skill-autoresearch-tooling-preference-class.md`
   with failed beads, working pattern beads, root cause, and routing table.
3. Updated `.flywheel/scripts/build-dispatch-packet.sh` to emit
   `SKILL-AUTORESEARCH TOOLING PREFERENCE BLOCK` for skill-enhance packets.
4. Added `tests/skill-autoresearch-tooling-preference-class.sh` to prove a
   `beads-br` skill-enhance packet is classified as shell-first and forbids
   `skill-autoresearch` as the primary route.
5. Updated `AGENTS.md`, `.flywheel/AGENTS-CANONICAL.md`, and
   `templates/flywheel-install/AGENTS.md` with L147.
6. Updated `README.md` with worker-facing skill-enhance routing guidance.
7. Re-routed `flywheel-spdu`, `flywheel-2gvl`, and `flywheel-njzi` with
   `known-pattern-mismatch` notes and no redispatch.
8. Produced doctrine-sync dry-run receipts for alpsinsurance, mobile-eats, and
   skillos:
   - `.flywheel/receipts/flywheel-ftj0m/doctrine-sync-alpsinsurance.json`
   - `.flywheel/receipts/flywheel-ftj0m/doctrine-sync-mobile-eats.json`
   - `.flywheel/receipts/flywheel-ftj0m/doctrine-sync-skillos.json`

## Verification

```bash
bash -n .flywheel/scripts/build-dispatch-packet.sh
bash -n tests/skill-autoresearch-tooling-preference-class.sh
tests/skill-autoresearch-tooling-preference-class.sh
```

Result: PASS.

## L112 Probe

Command:

```bash
tests/skill-autoresearch-tooling-preference-class.sh
```

Expected:

```text
skill-autoresearch tooling preference contract: PASS
```

Timeout: 30 seconds.

## L52 / Skill Discovery

Beads updated: `flywheel-spdu`, `flywheel-2gvl`, `flywheel-njzi`.

Skill discovery row: `sd-b5f89766d294001`

Fuckup log: `dcg-temp-dir-release-command-shape` (low severity; scratch dir
release command was corrected from blocked `rm -rf` to `rmdir`).

## Git Discipline

Commit skipped. The shared worktree already had broad unrelated uncommitted
changes across scripts, tests, doctrine, and Beads state before this dispatch.
Staging the touched files wholesale would have captured other workers' changes.
This dispatch therefore leaves path-local evidence and callback fields rather
than committing unrelated hunks.

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:9,jeff:8,public:9`

Public lens: the artifact names the exact failure class, prevents recurrence in
packet generation, gives peer orchestrators a doctrine-sync path, and leaves a
test future workers can rerun.
