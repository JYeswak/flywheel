# flywheel-dwavb Compliance Pack

## Scope

Bead: `flywheel-dwavb`
Task: `[L-rule Phase 4] evidence_redacted callback contract field + validator gate`
Worker: `CloudyMill`

## Acceptance Gates

- AG1 callback contract: DONE callback docs now include `evidence_redacted=<yes|no|n/a>` in `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md` and `/Users/josh/.claude/commands/flywheel/worker-tick.md`.
- AG2 validator gate: `.flywheel/scripts/validate-callback.py` rejects missing/invalid redaction receipts, rejects `evidence_redacted=no`, and requires `yes` when `files_reserved` matches evidence-class paths.
- AG3 doctrine: `.flywheel/doctrine/secrets-leak-prevention-stack.md` now describes the full prevention stack: precommit scanner, onboarding/doctor, skillos PR #90 linter, callback validation, and rank-3 convention.
- AG4 doctrine-sync: `sync-canonical-doctrine.sh --dry-run` against mobile-eats, alpsinsurance, and skillos reports drift for the new doctrine doc and canonical L-rules, proving the managed sync cadence will see this change.
- AG5 fleet callback verification: not complete in this worker because it requires the next 24h of mobile-eats:1, alpsinsurance:1, and skillos:1 callbacks. Follow-up bead `flywheel-cg0mr` tracks that observation window.

## Evidence

- Validator: `.flywheel/scripts/validate-callback.py`
- Schema: `.flywheel/validation-schema/v1/schema.json`
- Tests: `tests/validate-callback.sh`
- Canonical dispatch template: `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md`
- Worker tick docs: `/Users/josh/.claude/commands/flywheel/worker-tick.md`
- Doctrine: `.flywheel/doctrine/secrets-leak-prevention-stack.md`
- README: `README.md`
- Three doctrine surfaces: `AGENTS.md`, `.flywheel/AGENTS-CANONICAL.md`, `templates/flywheel-install/AGENTS.md`
- Follow-up bead: `flywheel-cg0mr`

## Verification

- `python3 -m py_compile .flywheel/scripts/validate-callback.py`: PASS
- `bash -n tests/validate-callback.sh`: PASS
- `bash tests/validate-callback.sh`: PASS, 30 passed
- `bash tests/test_callback_mission_fitness_required.sh`: PASS, 8 passed
- `.flywheel/scripts/doctrine-3-surface-divergence-probe.sh --repo /Users/josh/Developer/flywheel --json`: PASS, divergent count 0
- `git diff --check -- <touched repo files>`: PASS
- `.flywheel/receipts/flywheel-dwavb/l112-probe.sh`: PASS

## Did / Did Not / Gaps

Did: implemented the callback field, validator/schema enforcement, regression tests, canonical command docs, worker tick docs, doctrine page, README, and three L-rule surfaces.

Did not: broadly apply doctrine-sync into mobile-eats, alpsinsurance, or skillos because the dry run showed unrelated managed drift in those repos and this dispatch reserved only flywheel/global command surfaces.

Gaps: `flywheel-cg0mr` must verify field adoption across the next 24h of target fleet callbacks.

## Skill Routes

- canonical-cli-scoping: yes, canonical callback and worker-tick command surfaces were updated.
- python-best-practices: yes, focused parser/validator changes with regression tests.
- rust-best-practices: n/a, no Rust touched.
- readme-writing: yes, README update is concise and points at operational behavior.

## Four-Lens Self Grade

- Brand: 9/10
- Sniff: 9/10
- Jeff: 9/10
- Public: 8/10

