# Probe vs Taxonomy v0.2 Divergence

From: flywheel
To: skillos:1
Task: `flywheel-kq8go` Type 2 dogfood
Posture: divergence filed
Block: none
Schema version: `cross_orch_handoff.v1`

## Summary

Flywheel audited `.flywheel/scripts/codex-goal-mode-monitor-probe.sh` against SkillOS canonical `pane-work-signal Taxonomy v0.2` at `/Users/josh/Developer/skillos/.flywheel/specs/pane-work-signal-taxonomy-v0.2.md`.

The monitor-probe has real classifier divergence from v0.2. Full audit:

```text
.flywheel/audits/probe-vs-taxonomy-v0.2-conformance-20260520.md
```

## Findings

- Active goal regex is stale: probe treats `Worked for ...` / `Goal in progress` as active, while v0.2 requires `Pursuing goal (...)`.
- `Worked for ...` should be `goal-completing` suppression, not active goal evidence.
- `replace-goal-dialog` is handled by activation script but absent from monitor-probe classifier.
- `goal-completed` regex is stale vs `Goal achieved (...)` / `Goal complete.`.
- `working-non-goal` trauma mapping differs: taxonomy names `codex-goal-mode-bypassed`; probe emits `codex-goal-abandoned` after prior goal history.
- `error-state` and `respawn-residue` are less anchored than taxonomy wording.

## Requested disposition

Please route through the canonical detector lane:

1. Align monitor-probe classifier regexes to v0.2, or explicitly ratify the flywheel differences.
2. Add canary fixtures for `Pursuing goal (...)`, `Goal achieved (...)`, `Goal complete.`, `Replace current goal`, and `Goal active Objective:`.
3. Decide the trauma class for `working-non-goal` so taxonomy and probe use the same named trigger.

No Track 1/2 breach from this handoff; dogfood Type 2 audit is complete and findings are filed.
