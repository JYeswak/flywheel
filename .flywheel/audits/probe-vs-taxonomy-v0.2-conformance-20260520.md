# Probe vs Taxonomy v0.2.1 Re-Audit — 2026-05-20

## Verdict

0 divergences confirmed post-alignment.

Flywheel monitor-probe is aligned to the Skillos canonical pane-work-signal
classifier regex set named in `flywheel-89fpu`.

## Scope

Task: `flywheel-89fpu` Track 3 re-audit.

Audited:
- Flywheel monitor: `.flywheel/scripts/codex-goal-mode-monitor-probe.sh`
- Flywheel smoke fixture: `tests/codex-goal-mode-monitor-probe-smoke.sh`
- Flywheel canary runner: `tests/codex-goal-mode-monitor-probe-canary.sh`
- Flywheel canary fixtures: `tests/codex-goal-mode-monitor-probe-canary-fixtures/`
- Canonical Skillos classifier: `/Users/josh/Developer/skillos/.flywheel/scripts/pane-work-signal-classify.sh`
- Canonical Skillos spec: `/Users/josh/Developer/skillos/.flywheel/specs/pane-work-signal-taxonomy-v0.2.md`
- Canonical Skillos canary: `/Users/josh/Developer/skillos/tests/unit/test_pane_work_signal_classify.sh`

Canonical file hash:

```text
f84795dca8eaae3463b9d85dc362be53498a43c966522894baf23d28a9ca16a7  /Users/josh/Developer/skillos/.flywheel/scripts/pane-work-signal-classify.sh
```

Dispatch named canonical commit `52df5469`; local Skillos HEAD at re-audit was
`1b5ed652564515ca32b3ce6f4c3d27ad74e1a7d9`, with the canonical classifier
hash still matching the dispatch contract.

## Prompt-To-Artifact Checklist

| Requirement | Evidence | Status |
|---|---|---|
| Read Skillos classifier/spec/canary | Files listed in scope inspected before edits | PASS |
| Align Flywheel active goal regex | Probe uses `Pursuing goal \(([0-9]+[ms]\|[0-9]+m [0-9]+s)\)` | PASS |
| Separate `Worked for` completion transient | Probe maps `Worked for [0-9]+m [0-9]+s` to `goal-completing` with suppression | PASS |
| Add `replace-goal-dialog` | Probe maps literal `Replace current goal` to `replace-goal-dialog` | PASS |
| Add Goal-active-Objective composite | Probe maps `Goal active Objective:` + `Working (Ns...)` to `goal-in-progress` | PASS |
| Add Goal-active-Objective standalone suppression | Probe maps standalone `Goal active Objective:` to `idle-chat` with suppression reason | PASS |
| Correct working-non-goal trauma | Layer 3 fires `codex-goal-mode-bypassed` for `working-non-goal` | PASS |
| Tighten error-state | Probe matches `Conversation interrupted`, `Application not found`, or anchored Codex error text | PASS |
| Copy canary fixtures | `tests/codex-goal-mode-monitor-probe-canary-fixtures/01..09-*.txt` | PASS |
| Run Flywheel canary suite | `bash tests/codex-goal-mode-monitor-probe-canary.sh` -> `SUMMARY pass=9 fail=0` | PASS |
| Extend smoke fixture | `bash tests/codex-goal-mode-monitor-probe-smoke.sh` -> `SUMMARY pass=26 fail=0` | PASS |
| shellcheck | `shellcheck .flywheel/scripts/codex-goal-mode-monitor-probe.sh tests/codex-goal-mode-monitor-probe-smoke.sh tests/codex-goal-mode-monitor-probe-canary.sh` -> rc 0 | PASS |
| Live probe on real pane state | `CODEX_GOAL_MODE_SESSION=flywheel ... --pane 1 --layer 3 --dry-run --json` -> `status=ok`, `state=goal-in-progress` | PASS |

## Regex Alignment Table

| State | Canonical regex / predicate | Flywheel probe result |
|---|---|---|
| `replace-goal-dialog` | `Replace current goal` literal | Exact literal match |
| `goal-in-progress` | `Pursuing goal \(([0-9]+[ms]\|[0-9]+m [0-9]+s)\)` | Exact regex match |
| `goal-in-progress` composite | `Goal active Objective:` + `Working \([0-9]+s` | Implemented as medium-confidence in-progress |
| `idle-chat` subcase | `Goal active Objective:` standalone | Implemented with `Goal-active-Objective ambiguous; awaiting Working or Pursuing-goal transition` |
| `goal-paused` | `Goal paused` | Existing match retained |
| `goal-completed` | `Goal achieved \([0-9]+[ms]?\)` OR `Goal complete\.` | Exact canonical alternatives implemented |
| `goal-completing` | `Worked for [0-9]+m [0-9]+s` | Implemented as suppression/defer state |
| `working-non-goal` | `Working \([0-9]+s • esc to interrupt\)` with no goal marker | Implemented; Layer 3 trauma is `codex-goal-mode-bypassed` |
| `error-state` | `Conversation interrupted` OR `Application not found` OR Codex error text | Implemented with anchored Codex error text |
| `respawn-residue` | State-machine context; text marker remains fixture path | Existing suppression retained; no divergence for this Track 3 regex alignment |

## Verification Output

```text
bash /Users/josh/Developer/skillos/tests/unit/test_pane_work_signal_classify.sh
SUMMARY pass=9 fail=0

bash tests/codex-goal-mode-monitor-probe-canary.sh
SUMMARY pass=9 fail=0

bash tests/codex-goal-mode-monitor-probe-smoke.sh
SUMMARY pass=26 fail=0

shellcheck .flywheel/scripts/codex-goal-mode-monitor-probe.sh tests/codex-goal-mode-monitor-probe-smoke.sh tests/codex-goal-mode-monitor-probe-canary.sh
rc=0

live probe:
{"schema_version":"codex-goal-mode-monitor-probe/v0.1","ts":"2026-05-20T01:31:21Z","status":"ok","session":"flywheel","pane":1,"dispatch_id":"flywheel-89fpu-live","layer":3,"state":"goal-in-progress","persistence_poll_interval_s":60,"respawn_residue_s":15,"completing_window_s":5}
```

## Closeout

Previous Type 2 audit divergences D1-D6 are closed by this patch. D7
(`respawn-residue` as state-machine context) is outside the regex alignment
delta requested by `flywheel-89fpu`; the existing suppression fixture remains
green and no v0.2.1 regex divergence remains.
