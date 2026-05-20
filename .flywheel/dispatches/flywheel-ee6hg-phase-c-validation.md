# flywheel-ee6hg — Phase C fleet-wide validation across 8 orchs post-propagation

## Context

Skillos:1 executed Phase A at 06:18Z (handoff 20260520T061818Z): 6 READY orchs (mobile-eats, picoz, clutterfreespaces, alpsinsurance, vrtx, terratitle) each received 4 codex-goal-mode canonical files. 24 file copies, zero overwrites, locally verified 4/4 on each repo.

Phase C is MY validation: probe ALL 8 fleet orchs (the 6 + skillos + flywheel) for canonical conformance. Measure what propagation actually achieved + file divergence findings back to skillos.

Pairs with flywheel-2uha0 (worker discipline propagation) which reported 0.125 fleet score pre-Phase-A.

## Deliverables

### A. .flywheel/scripts/phase-c-fleet-validation.sh
Probe each of 8 orchs for:
1. 4 codex-goal-mode canonical files present (codex-goal-activate.sh + pane-work-signal-classify.sh + taxonomy-v0.2.md + codex-goal-mode-discipline.md)
2. Shasum match against skillos canonical (allow local-divergence-with-comment per "convergent evolution = canonical signal" memory)
3. Optional: doctrine docs for the other 5 worker-discipline classes (auto-push-blocked, dcg-worker-freeze, dry-run-apply-parity, runtime-doctrine-separation, repo-hygiene-tick) — these are flywheel-only, propagation pending operator-integration
4. Optional: memory pins in MEMORY.md (4 pins from 2uha0)
5. Dispatcher integration via option-3 templated snippet (Phase B operator-paced)

Emit per-orch envelope:
```json
{
  "orch": "...",
  "phase_a_files": {"present": 4, "expected": 4, "shasum_matches": 4},
  "phase_b_dispatcher_integration": "ok|pending|not-applicable",
  "doctrine_propagation": {"present": N, "expected": 5},
  "memory_pins": {"present": N, "expected": 4},
  "overall_conformance_pct": <float>,
  "divergence_findings": [...]
}
```

Fleet rollup envelope: `{fleet_conformance_avg, phase_a_avg, phase_b_avg, doctrine_avg, memory_avg, top_divergence_classes}`

### B. .flywheel/audits/phase-c-fleet-validation-<ts>.md
Markdown report citing per-orch envelopes + rollup. Highlights:
- Which orchs hit 100% conformance (Phase A baseline)
- Which orchs have pending Phase B dispatcher integration
- Doctrine propagation gaps (expected — Phase B operator-paced)
- Memory pin gaps (expected — same reason)
- Shasum divergences (note: flywheel's codex-goal-activate.sh has 4 local bug-patches on top of skillos canonical = expected divergence)

### C. Cross-orch handoff back to skillos
Auto-generated handoff with the rollup envelope. Flags any unexpected divergence findings (file-missing, shasum-mismatch with no comment).

### D. tests/phase-c-fleet-validation-smoke.sh
- 6+ assertions:
  1. Synthetic orch with 4/4 files + shasum-match → conformance=1.0
  2. Synthetic orch with 0/4 files → conformance=0.0
  3. Synthetic orch with shasum-mismatch + attribution comment → flagged-but-allowed
  4. Synthetic orch with shasum-mismatch + no comment → divergence-finding
  5. JSON rollup parseable + complete
  6. Handoff envelope correctly enumerates divergences

## Acceptance

- Validation script ships + shellcheck PASS
- Smoke 6+ assertions PASS
- Initial fleet validation report at .flywheel/audits/phase-c-fleet-validation-<ts>.md
- Auto-generated cross-orch handoff to skillos:1 (file ready to send; flywheel:1 review optional)
- Bead flywheel-ee6hg closed

## Out of scope

- Modifying any non-flywheel repo files (read-only probe)
- Forcing Phase B dispatcher integration (operator-paced per skillos canonical)
- Doctrine + memory propagation (separate from Phase A; pending operator absorption)

## Loop contract

- Track 3 only
- Cross-repo READ allowed via existing authorize paths; NO writes to non-flywheel repos
- Bridge daemon LIVE
- SCR event: C7_verification_density
- STOP on Track 1/2 breach, BLOCKED, >2h hard cap

## FIRST ACTION

1. br show flywheel-ee6hg.
2. Read .flywheel/handoffs/20260520T061818Z-from-skillos-to-flywheel-phase-a-complete-*.md.
3. Read .flywheel/audits/worker-discipline-propagation-readiness-20260520T055431Z.md (2uha0 baseline pre-Phase-A).
4. ACK row.
5. Implement validator + smoke + run on 8 orchs.
6. Self-validate.
7. Commit + close bead + DIRECT pane-1 ntm send.
