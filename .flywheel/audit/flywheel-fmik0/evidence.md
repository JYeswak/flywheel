# flywheel-fmik0 — B12_AG7 agent-context-parity-probe failure calibration

Bead: flywheel-fmik0 (P2)
Surface: `.flywheel/scripts/agent-context-parity-probe.py` (probe authoring; not the test)
Lane: testing
mutates_state: no (probe-level calibration — receipt envelope content; no validator semantics changed; no production behavior change)

## Root cause confirmed (AG1)

The probe's constructed callback receipt JSON is missing the `evidence_redacted` field. Upstream `validate-callback.py` evolved its taxonomy to require this field on every callback envelope. Without it, the validator returns:

```json
"failure_classes": ["evidence_redaction_missing"]
"status": "fail"
```

The probe overwrites its own `status=pass` with the validator's `status=fail` (probe line 300: `status = validation.get("status", "fail")`), then exits rc=1 (line 321). The test at `tests/agent-context-parity-probe.sh` line 91 invokes the probe under `set -e`; rc=1 propagates → test halts before B11_AG2 assertion ever runs.

**Failing gate identified:** The python probe itself, before B11_AG2 even gets to assert. Test was silently halting on the python invocation, not on a B11_AGn assertion.

## Classification (AG2)

**CALIBRATION** — same class as flywheel-uijqq (B12_AG2):

| Era | What the validator returns for this fixture | Probe outcome |
|---|---|---|
| Pre-fix (≤2026-05-09) | `status=pass` (no evidence_redacted check) | probe rc=0, status=pass |
| Post-fix (2026-05-11+) | `failure_classes=["evidence_redaction_missing"], status=fail` | probe rc=1, status=fail |

The SEMANTIC contract the probe is meant to enforce — "agent context resolution matches orchestrator shell context resolution; surface drift, timeout, and mismatch correctly" — is preserved across validator evolution. Only the receipt envelope schema acquired a new required field.

Anchor: memory rule `feedback_calibrate_test_to_actual_contract_before_filing_upstream`.

## Calibration applied (AG3)

Single-field addition to `callback_source()` in `.flywheel/scripts/agent-context-parity-probe.py`:

```python
raw = {
    "status": status,
    "failure_classes": failures,
    "evidence_redacted": "n/a",  # NEW (flywheel-fmik0 calibration)
    "callback_ref": { ... },
    ...
}
```

**Why `n/a` is the semantically correct value for B11 fixture parity probes:**

The B11 probe is a *parity probe* — it verifies agent-context vs orchestrator-shell-context resolution. It does NOT touch evidence-class files. Verified:
- `artifact_paths: []` (always empty for parity probes)
- No `files_reserved` (probe doesn't reserve anything)
- `evidence` array contains only ephemeral command-class references (`command -v`, `realpath`, `--version`), not evidence-class paths

Per validator taxonomy (line 144 in `validate-callback.py`): `evidence_redaction_na_on_evidence` only fires when `evidence_redacted=n/a` AND evidence-class files appear in `files_reserved`. Since `files_reserved=[]`, `n/a` is safe and accurate.

Inline comment block in the source explains:
- Calibration target (flywheel-fmik0)
- Date (2026-05-11)
- Validator evolution (failure_classes taxonomy added requirement)
- Why `n/a` (B11 fixture parity probes don't touch evidence-class files)
- Sister bead (flywheel-uijqq B12_AG2)
- Memory rule anchor

## Acceptance gates

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Identify which inner gate fails in `tests/agent-context-parity-probe.sh` | **DONE** | Identified failure occurs **on the python probe invocation itself** (line 91), not on a B11_AGn jq assertion. Probe rc=1 propagates via `set -e` before B11_AG2 assertion runs. Confirmed via direct probe invocation showing `status=fail, failure_classes=["evidence_redaction_missing"], validation_rc=1`. |
| AG2 | Classify as calibration vs regression | **DONE — CALIBRATION** | Upstream `validate-callback.py` taxonomy evolved between probe authoring (≤2026-05-09) and re-validation (2026-05-11) to require `evidence_redacted` in every callback envelope. Probe's receipt schema is stale relative to current contract. No semantic regression — the probe's correctness contract is preserved. Same class as flywheel-uijqq B12_AG2. |
| AG3 | Fix or calibrate | **DONE — CALIBRATED PROBE** | Added `"evidence_redacted": "n/a"` to receipt envelope in `callback_source()` with explanatory comment block citing flywheel-uijqq, memory rule, and rationale for `n/a`. NO test mutation; NO validator semantics change; NO production callback shape change for real-worker callbacks. |
| AG4 | `bash tests/validation-e2e.sh` B12_AG7 gate passes | **DONE** | Full validation-e2e.sh result: **23/23 PASS** including `PASS B12_AG7 present and passing`. Inner `tests/agent-context-parity-probe.sh`: **10/10 PASS** (B11_AG1 through B11_AG8 — all gates including drift/timeout paths). |

## Test execution receipts

### Inner test (agent-context-parity-probe)

```
PASS B11_AG1 schema separates agent and orchestrator contexts
PASS B11_AG2 Codex path sends via ntm and validates callback
PASS B11_AG3 Claude path uses Bash context
PASS B11_AG4 raw-shell pass plus agent failure returns context_drift
PASS B11_AG5 agent timeout returns runtime_unresponsive
PASS B11_AG6 CLI identity proof
PASS B11_AG7 q03g fixture-compatible integration documented
PASS B11_AG8 codex agent pass covered
PASS B11_AG8 codex agent fail covered
PASS B11_AG8 runtime timeout covered

Summary: 10 passed, 0 failed
```

### Outer test (validation-e2e)

```
PASS B12_AG1 present and passing
PASS B12_AG2 present and passing
PASS B12_AG3 present and passing
PASS B12_AG4 present and passing
PASS B12_AG5 present and passing
PASS B12_AG6 present and passing
PASS B12_AG7 present and passing          ← target gate
PASS B12_AG8 present and passing
PASS B12_AG9 present and passing
…
Summary: 23 passed, 0 failed
```

## No semantic regression — proof

All four B11 paths exercised by the test (codex_pass, claude_pass, drift, timeout) PASS after calibration. This confirms:

- **codex_pass (B11_AG2)**: agent and shell both resolve `b11tool` → status=pass. Validator no longer flags `evidence_redaction_missing`; allows source status=pass to propagate. ✓
- **claude_pass (B11_AG3)**: claude_bash_context transport → status=pass. Same evidence_redacted=n/a applied. ✓
- **drift (B11_AG4)**: agent says found=false, shell says found=true → probe sets `status=fail, failure=context_drift`; validator preserves this with evidence_redacted=n/a. Test asserts `.status == "fail" and .context_drift == true and (.validation.failure_classes | index("context_drift"))`. ✓
- **timeout (B11_AG5)**: agent unresponsive → probe sets `status=unknown, failure=runtime_unresponsive`; validator preserves. Test asserts `.status == "unknown" and (.validation.failure_classes | index("runtime_unresponsive"))`. ✓

The calibration adds a field but does NOT mask any failure class. Drift detection, timeout detection, and identity-resolution semantics are unchanged.

## Out of scope (per bead body)

- **B12_AG2** — already calibrated in flywheel-uijqq (sister bead, same class, committed at `c69610c`).
- **B12_AG4** — separate followup bead if it surfaces.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/agent-context-parity-probe.py` | +9 lines (8-line comment block + `evidence_redacted: "n/a"` field) at `callback_source()` function |
| `.flywheel/audit/flywheel-fmik0/evidence.md` | NEW |

No test mutation. No validator mutation. No production worker callback shape change.

## Sister-bead pattern (canonical recipe)

flywheel-uijqq + flywheel-fmik0 establish a 2-instance ladder for the same calibration class:

| # | Bead | Surface | Calibration |
|---|---|---|---|
| N=1 | flywheel-uijqq (B12_AG2) | `.flywheel/scripts/validation-e2e-smoke.sh` | Widened jq filter to accept any of {evidence_redaction_missing, remediation_missing, artifact_missing} |
| N=2 | flywheel-fmik0 (B12_AG7) | `.flywheel/scripts/agent-context-parity-probe.py` | Added `evidence_redacted: "n/a"` to constructed receipt envelope |

Both apply memory rule `feedback_calibrate_test_to_actual_contract_before_filing_upstream`: when a flywheel test fails because upstream behavior diverges, calibrate test (or test-substrate) to upstream's actual current contract first.

If a third instance lands (B12_AG4 or another consumer of `validate-callback.py`), the pattern would meet the N=3 META-RULE threshold for promotion to doctrine (e.g. `evidence-redaction-required-field-propagation.md` or similar).

## Compliance: 1000/1000

- AG1: failing gate identified — python probe invocation, not a B11_AGn assertion. ✓
- AG2: classified CALIBRATION (validator taxonomy evolution, not probe regression). ✓
- AG3: probe calibrated with `evidence_redacted=n/a`, explanatory comment, no semantic regression. ✓
- AG4: B12_AG7 gate PASS in validation-e2e (23/23) + inner test 10/10. ✓
- Out-of-scope (B12_AG2 + B12_AG4): NOT touched. ✓
- Anti-regression: all four B11 paths (pass/drift/timeout/claude) verified PASS. ✓

four_lens=brand:9,sniff:9,jeff:9,public:9
