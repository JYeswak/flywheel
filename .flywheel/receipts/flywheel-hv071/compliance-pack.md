# flywheel-hv071 Compliance Pack

Task: `[L-rule] PRE-COMMIT-GITLEAKS-MANDATORY + rank-3 secret-handle convention (Phase 1)`
Worker: CloudyMill
Date: 2026-05-09

## Acceptance Gates

| gate | result | evidence |
|---|---|---|
| AG1 | PASS | L149 added to `AGENTS.md`, `.flywheel/AGENTS-CANONICAL.md`, and `templates/flywheel-install/AGENTS.md`. |
| AG2 | PASS | L149 includes vector #6 tainted `/tmp` readback rule with permitted and forbidden operations. |
| AG3 | PASS | L149 records doctor invariants for `pre_commit_secret_scanner_installed` and `pretooluse_bash_diagnostic_hook_installed`. |
| AG4 | PASS | `.flywheel/doctrine/secrets-leak-prevention-stack.md` documents Layers A-D and Phases 1-4. |
| AG5 | PASS | Phase 2, Phase 3, and Phase 4 ownership is recorded in the stack doc; no new phase bead was required because existing owners are named. |

## Validation

Run:

```bash
.flywheel/receipts/flywheel-hv071/l112-probe.sh
```

Expected literal:

```text
L112_PASS_flywheel-hv071_L149_three_surface_and_stack
```

Additional checks run:

- `bash -n .flywheel/receipts/flywheel-hv071/l112-probe.sh` -> PASS
- `.flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-hv071-940953.md` -> PASS
- `git diff --check -- AGENTS.md .flywheel/AGENTS-CANONICAL.md templates/flywheel-install/AGENTS.md README.md .flywheel/doctrine/secrets-leak-prevention-stack.md .flywheel/receipts/flywheel-hv071` -> PASS
- `.flywheel/scripts/doctrine-3-surface-divergence-probe.sh --repo /Users/josh/Developer/flywheel --json` -> PASS, `doctrine_3_surface_divergent_count=0`
- `bash tests/security-precommit-hook.sh` -> PASS, 11 checks
- `bash tests/doctor-security-posture.sh` -> PASS, 6 checks

Commit was skipped because the shared doctrine surfaces and `.beads/issues.jsonl`
had pre-existing unrelated dirty changes in this worker pane. The bead was
closed via `br`; pathspec staging was not used to avoid bundling other workers'
changes.

## Socraticode

Queries: 10
Indexed chunks observed: 100

## Skill Routes

- `agent-security`: used for credential handling, data exfiltration prevention, and zero-trust framing.
- `canonical-cli-scoping`: addressed as n/a for implementation; existing security-precommit installer already exposes doctor, health, repair, validate, audit, why, schema, quickstart, examples, and completion.
- `readme-writing`: addressed through the README security section update.
- Rust/Python routes: n/a, no Rust/Python code changed.

## Four-Lens Self-Grade

four_lens=brand:9,sniff:9,jeff:9,public:8
