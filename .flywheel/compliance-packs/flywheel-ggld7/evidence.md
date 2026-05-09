# flywheel-ggld7 Compliance Pack

task_id: flywheel-ggld7-1a2b3b

## Acceptance Gates

- AG1: PASS. `background_terminal_stuck` added with 5 minute threshold and normalized timer hash comparison.
- AG2: PASS. `.flywheel/scripts/caam-rotate-and-respawn.sh` added with current-profile read, next-profile selection, CAAM activation, ntm interrupt/wait, respawn, and redispatch.
- AG3: PASS. Detector `recover()` invokes CAAM rotation for `model_at_capacity_halt` and `background_terminal_stuck`.
- AG4: PASS. Doctor exposes the requested metrics and applies WARN/FAIL gates.
- AG5: PASS. `.flywheel/tests/test_caam_rotate_and_respawn.sh` covers subclass fixture and e2e rotate-and-respawn behavior.

## Dispatch Contract

- files_reserved=.flywheel/scripts/codex-template-stuck-detector.sh,.flywheel/scripts/caam-rotate-and-respawn.sh,.flywheel/tests/test_caam_rotate_and_respawn.sh,.flywheel/receipts/flywheel-ggld7/evidence.md,.flywheel/compliance-packs/flywheel-ggld7/evidence.md,.flywheel/validation-receipts/flywheel-ggld7-1a2b3b.json
- scope_expansion_requested=0
- socraticode_queries=10
- indexed_chunks_observed=1578
- skill_routes=caam,canonical-cli-scoping,python-best-practices
- skill_discoveries=1
- sd_ids=sd-592c1f3c377132d5
- fuckups_logged=caam-skill-doc-drift
- no_bead_reason=all acceptance work completed in-scope; CAAM skill-doc drift logged via skill-discovery and fuckup-log instead of a repo bead.

## Four Lens

- correctness: focused test validates classifier, primitive, recovery wire-in, doctor metrics, and no-profile failure.
- safety: default mode is dry-run; apply requires explicit `--apply`; live CAAM profile was restored after discovery probe.
- substrate: uses `ntm` verbs for pane operations and appends CAAM rotation ledger rows only on apply.
- operability: doctor now exposes recovery attempt/success and CAAM availability signals.
