## What happened

`scripts/run-pass.sh` and `scripts/single-bead-audit.sh` both unconditionally stub Phase 4 (compliance verification + test depth) when the caller isn't running through the Task-tool subagent path. The script comments are explicit about why:

- `run-pass.sh:42-43` — `# Most users should drive the phases via subagents (see subagents/) for parallelism. # This script is for single-agent local runs and CI tripwire mode.`
- `run-pass.sh:187-193` — `Phase 4: (skipped in wrapper — Phase 4 needs subagents to actually run tests; stubbing compliance.json + test_depth.json)` then writes `executor: "stub-wrapper", checks: []` JSON.
- `single-bead-audit.sh:152-158` — same shape, comment says `# Phase 4 stub — single-bead mode emits the stub compliance.json so the scorer has a deterministic input. For real Phase 4, the orchestrator should run the compliance-verifier subagent (subagents/compliance-verifier.md) here.`

For users who can drive phases via Task-tool subagents, the skill works as designed. For single-agent shell users (CI runners, tmux/codex-style single-process shells, automation harnesses without a subagent dispatcher), the stub mode is the only path — and it produces empty `checks: []` JSON, which means the scorer sees a deterministic-but-empty audit. The skill's stated purpose ("Verify every closed bead was actually implemented") cannot be met in that mode.

## Repro

```bash
# Single-agent shell (no Task-tool subagent dispatcher present):
cd /path/to/project-with-beads/
bash <skill>/scripts/run-pass.sh "$PWD"
# Watch Phase 4 announce itself as stub-mode and write {"checks": []} JSON.
cat passes/<UTC>/beads/*/compliance.json
# {"bead_id": "...", "executor": "stub-wrapper", "checks": []}
```

## Expected vs observed

Expected: a runner mode where single-agent shell users can opt into actually executing Phase 4's compliance verification (and any other subagent-bound phases) without needing a Task-tool dispatcher — possibly serially, with full transparency that the loop is slower without parallelism, and a resumable interface so a long single-agent run can stop/start cleanly.

Observed: stub-mode is unconditional in the wrapper for non-subagent callers. The `executor: "stub-wrapper"` JSON is the explicit signal that real verification was bypassed, but downstream the scorer doesn't distinguish a real-empty-checks audit from a stub-empty-checks audit — both look the same to consumers reading `compliance.json`.

## File:line citations

- `scripts/run-pass.sh:42-43` — header comment establishing the design
- `scripts/run-pass.sh:187-193` — Phase 4 stub block in the multi-bead pass loop
- `scripts/single-bead-audit.sh:152-158` — Phase 4 stub block in single-bead mode
- `references/PHASES.md` Phase 4 section — documents that the `compliance-verifier` subagent is the canonical Phase 4 executor and lists its inputs/outputs/exit criteria

## Why this matters

CI tripwire mode (the README's third tier) is one of the documented use cases. If Phase 4 always stubs in CI, the tripwire's regression-detection promise is partial: only Phase 5 (theater + anomaly scan) and Phase 6+ (synthesis + scoring) actually run, but the compliance verification that backs the score is empty. A single-agent batch runner that wants real verification must currently shell out to its own subagent simulation, which is exactly the orchestration the skill is supposed to encapsulate.

## Proposed shape (for upstream design — no implementation prescribed)

The skill could ship a small set of runner flags that let single-agent callers opt into real-phase execution serially:

- `--real-phases <list>` — comma-separated phase numbers to execute against real producers instead of stubbing. Default: empty (current stub-mode behavior preserved). Example: `--real-phases 4` runs the compliance-verifier inline in single-process shell context.
- `--no-stub` — refuse to write `executor: "stub-wrapper"` JSON; instead exit non-zero on any stub-bound phase, so CI fails loudly rather than silently producing empty audits.
- `--resume-from <phase>` and `--stop-after <phase>` — a phase-window contract for long single-agent runs, letting an external scheduler chunk Phase 1→3 in one process, Phase 4 in another (possibly with parallelism), and Phase 5+ in a third. This composes with `--real-phases` and is what most CI mode users want.
- A JSON task-queue artifact (e.g. `passes/<UTC>/task-queue.json`) listing the work units the wrapper would have dispatched to subagents, so external orchestrators (GitHub Actions matrix, Earthly, Bazel, ad-hoc shell) can pick up and execute them with their own parallelism. Shape suggestion:
  ```json
  {
    "schema_version": "beads-compliance-task-queue.v1",
    "phase": 4,
    "tasks": [
      {"task_id": "...", "subagent": "compliance-verifier",
       "input_dir": "passes/.../beads/<id>",
       "expected_output": "compliance.json",
       "depends_on": []}
    ]
  }
  ```
  The wrapper currently has all the inputs to write this — it's the same data that goes into the subagent prompt today, just exported instead of consumed in-process.

## Out of scope

Not asking for a feature beyond what the skill already documents — `references/PHASES.md` ALREADY says Phase 4 needs a real producer, and `subagents/compliance-verifier.md` ALREADY documents the subagent contract. The runner flags and task-queue artifact would expose that contract to non-Task-tool callers, which closes the gap between the documented design and the single-agent shell user's actual experience. No PR or patch attached; sketching the shape so the design space is visible.
