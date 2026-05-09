# flywheel-7nmls Evidence Pack

## Summary

- Patched `.flywheel/scripts/validate-callback.py` so `evidence=<path>` and structured `evidence: [{"type":"path","ref":...}]` entries become artifact checks.
- Missing durable evidence paths now fail validation with `artifact_missing`.
- Added `--allow-missing-tmp-evidence` for intentional `/tmp` or `/private/tmp` evidence paths; those become `unknown`, not `missing`, and durable paths still fail closed.
- Patched `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md` to state that `evidence=<path>` is a filesystem contract and must exist before `br close`.

## AG1 Closed-Bead Audit

Source: `.beads/issues.jsonl` sorted by `closed_at` descending, first 50 closed beads, matched against `/tmp/flywheel-7nmls-history.json`.

Result in `.flywheel/receipts/flywheel-7nmls/closed-evidence-audit.json`:

```json
{
  "closed_beads_checked": 50,
  "callbacks_found": 48,
  "advertised_evidence_paths": 45,
  "missing_evidence_paths": 0
}
```

Two closed beads in the sample did not have an exact callback match under the audit rule:

- `flywheel-ae8aq`
- `flywheel-aduvv.1`

The audited callback sample did not show current drift among advertised evidence paths.

## AG2 Validator Patch

Implemented path-existence validation in `.flywheel/scripts/validate-callback.py`:

- raw callback text: `evidence=<path>`
- structured JSON callback evidence: `{"type":"path","ref":"<path>"}`
- existing artifact paths remain validated
- tmp override is explicit: `--allow-missing-tmp-evidence`

Regression coverage in `tests/validate-callback.sh`:

- `7nmls structured evidence path must exist`
- `7nmls tmp evidence override is explicit`

## AG3 Dispatch Contract Patch

Patched `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md`:

- workers must write the advertised evidence file before `br close`
- missing durable evidence rejects close
- tmp override is only for intentional ephemeral evidence paths

## AG4 kvt8v Audit

The original skillos finding was valid at the time: the callback advertised `.flywheel/receipts/flywheel-kvt8v/evidence.md` before the file existed.

Current state after corrective work:

- evidence file exists: `.flywheel/receipts/flywheel-kvt8v/evidence.md`
- corrective commit exists: `4c7fc89 chore(callback): record evidence_redacted peer adoption`
- generated proof packet exists: `.flywheel/receipts/flywheel-kvt8v/dispatch_flywheel-kvt8v-proof.md`
- adoption probe receipt exists: `.flywheel/receipts/flywheel-kvt8v/adoption-probe-results.json`

Assessment: kvt8v work is now materially done despite the earlier callback evidence discrepancy. The discrepancy class is closed by this validator/template guard.

## AG5 L143 Cross-Link

This is the same close-discipline family as L143 WORKER-CLOSE-REQUIRES-GIT-COMMIT:

- L143: worker cannot claim close completion until commit evidence is real.
- flywheel-7nmls: worker cannot claim callback evidence until evidence path is real.

Both are contract fields that must be backed by filesystem or git state before `br close`.

## Verification

```bash
python3 -m py_compile .flywheel/scripts/validate-callback.py
tests/validate-callback.sh
jq '{closed_beads_checked,callbacks_found,advertised_evidence_paths,missing_evidence_paths}' .flywheel/receipts/flywheel-7nmls/closed-evidence-audit.json
gitleaks detect --no-git --source .flywheel/receipts/flywheel-7nmls --redact --no-banner
```

Observed validator test result:

```text
Summary: 32 passed, 0 failed
```

Gitleaks result: no leaks found.

## Skill Routes

- `canonical-cli-scoping=yes`: CLI flag `--allow-missing-tmp-evidence`, schema text, examples, and stable exit behavior covered.
- `python-best-practices=yes`: typed function signatures added, tests use temp fixtures, module keeps existing CLI shape. `validate-callback.py` is already above the 400-line threshold; this patch keeps the change localized instead of splitting the CLI during a guardrail fix.
- `rust-best-practices=n/a`: no Rust touched.
- `readme-writing=n/a`: no README touched.

## Four-Lens Self-Grade

brand: 8
sniff: 8
jeff: 8
public: 8

Three Judges:

- skeptical operator can rerun the audit JSON and validator suite
- maintainer can inspect a focused validator/test/template diff
- future worker gets an explicit close contract and regression test
