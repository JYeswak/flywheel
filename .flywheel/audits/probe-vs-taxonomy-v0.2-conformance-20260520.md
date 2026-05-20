# Probe vs Taxonomy v0.2 Conformance — 2026-05-20

## Scope

Task: `flywheel-kq8go` Type 2 deep-work dispatch.

Audited:
- Flywheel monitor: `.flywheel/scripts/codex-goal-mode-monitor-probe.sh`
- Smoke fixture: `tests/codex-goal-mode-monitor-probe-smoke.sh`
- Canonical taxonomy: `/Users/josh/Developer/skillos/.flywheel/specs/pane-work-signal-taxonomy-v0.2.md`
- SkillOS canonical commit named by dispatch: `fc809a04`

Local note: `.flywheel/specs/pane-work-signal-taxonomy-v0.2.md` is not present in this repo at audit time, so the SkillOS canonical file above was used as the source of truth.

## Type 1 Coverage Map

`bash tests/codex-goal-mode-monitor-probe-smoke.sh` passes with `SUMMARY pass=19 fail=0`.

The five trauma classes are covered:

| Trauma class | Smoke assertions |
|---|---|
| `codex-goal-entry-failed` | ok 3 `Layer 2 idle-chat fires trauma rc=1`; ok 4 `Layer 2 trauma class is codex-goal-entry-failed` |
| `codex-goal-resume-stuck` | ok 5 `Layer 3 goal-paused 120s fires resume-stuck rc=1`; ok 6 `resume-stuck trauma written` |
| `codex-goal-abandoned` | ok 7 `Layer 3 mode regression fires abandoned rc=1`; ok 8 `abandoned trauma written` |
| `codex-goal-mode-flapping` | ok 9 `Layer 3 flap threshold fires rc=1`; ok 10 `flapping trauma written` |
| `codex-goal-mode-bypassed` | ok 11 `Layer 4 callback without goal history fires rc=1`; ok 12 `mode-bypassed trauma written` |

Additional coverage: respawn-residue defer, bypass audit suppression, unknown-state telemetry.

## Divergence Findings

### D1 — Active goal regex is stale

Taxonomy v0.2 canonical active state is:

```text
Pursuing goal \(([0-9]+[ms]|[0-9]+m [0-9]+s)\)
```

Probe implementation classifies active goal from either `Worked for ...` or literal `goal in progress` text:

```text
(worked for [0-9]+[ms] OR goal in progress) AND NOT goal paused
```

Impact: Layer 2 can fail to recognize the ratified `Pursuing goal (...)` state, while the fixture still accepts deprecated pane chrome. This is the highest-priority classifier divergence.

### D2 — `Worked for ...` is classified as active instead of transient completion

Taxonomy v0.2 says `Worked for [0-9]+m [0-9]+s` is `goal-completing`, a suppression state after callback, not active work.

Probe uses `worked for` as `goal-in-progress`. This can hide a post-completion state as active and weaken Layer 3 persistence evidence.

### D3 — `replace-goal-dialog` is missing from monitor-probe classifier

Taxonomy v0.2 includes `Replace current goal` as `replace-goal-dialog`, with dispatcher Enter-to-confirm behavior.

`codex-goal-activate.sh` handles this state, but `codex-goal-mode-monitor-probe.sh` does not classify it. A probe during the dialog window falls through to `unknown` unless other text matches.

### D4 — `goal-completed` regex is stale

Taxonomy v0.2 terminal state:

```text
Goal achieved \([0-9]+[ms]?\) OR Goal complete\.
```

Probe accepts:

```text
goal completed OR completed goal
```

Impact: Layer 4 can miss canonical terminal pane chrome and over-log unknown/error states around callback.

### D5 — `working-non-goal` trauma mapping conflicts with taxonomy

Taxonomy says `working-non-goal` is a red-flag Layer 3 fail that fires `codex-goal-mode-bypassed`.

Probe fires `codex-goal-abandoned` for `working-non-goal` only when prior history contains `goal-in-progress`. That preserves mid-dispatch regression semantics, but it does not match the taxonomy’s named trigger.

### D6 — `error-state` detection is broader and less anchored

Taxonomy lists `Conversation interrupted`, `Application not found`, or codex error text.

Probe detects `traceback|exception|panic|fatal:|error:|rate limit|api error|failed` only when the pane text does not also contain `goal`. This can suppress true codex errors if the stale scrollback includes goal text.

### D7 — respawn-residue is textual rather than state-machine context

Taxonomy defines `respawn-residue` as a <15s post-respawn window state-machine context.

Probe detects textual markers: `respawn-residue|post-respawn|recently respawned`. This is fixtureable but not equivalent to a real pane-respawn clock.

## State Transition Audit

The probe persists per-dispatch state history and uses it for:
- Layer 3 abandonment after prior `goal-in-progress`
- Layer 3 flapping count over the configured window
- Layer 4 bypass check requiring at least one prior `goal-in-progress`

The transition machinery exists, but because `goal-in-progress` is stale, the history can be false-negative for canonical `Pursuing goal (...)` panes and false-positive for `Worked for ...` completion panes.

## Recommendation

File back to SkillOS/flywheel canonical detector lane:

1. Replace monitor-probe classifier regexes with the v0.2 table.
2. Add fixtures for canonical `Pursuing goal (...)`, `Goal achieved (...)`, `Goal complete.`, `Replace current goal`, `Conversation interrupted`, and early `Goal active Objective:`.
3. Decide whether `working-non-goal` should fire `codex-goal-mode-bypassed` immediately or preserve the current `abandoned` mid-dispatch regression semantics; update taxonomy or probe so both name the same trauma trigger.
4. Replace textual respawn-residue matching with a real respawn timestamp source, leaving text markers as test-only fixtures.

## Verdict

Type 2 audit complete. Divergence observed and filed for SkillOS via `.flywheel/handoffs/20260520T0108Z-from-flywheel-to-skillos-probe-vs-taxonomy-v0-2-divergence.md`.
