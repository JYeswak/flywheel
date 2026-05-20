# flywheel-vlodi — Dry-run/apply parity contract for all dual-mode flywheel scripts

## Context

Tonight's flywheel-n2228 root cause: `branch-protection-apply.sh` had two divergent code paths — dry-run did per-repo discovery (correct), apply used hardcoded defaults (wrong). Result: wrong CI check names pushed to 4 repos, blocked PR merges, Joshua manually reverted via gh api DELETE. n2228 fixed branch-protection-apply specifically. THIS bead formalizes the GENERAL contract so no other flywheel script can repeat the divergence class.

Trauma class: `dry_run_apply_divergence`. Same shape as `feedback_substrate_contract_shape_mismatch_trauma_family` in memory.

## Deliverables

### A. .flywheel/doctrine/dry-run-apply-parity-contract.md
Document the contract:
- ANY flywheel script that has both `--dry-run` and `--apply` modes MUST share a SINGLE data source / computation path
- The "compute" step runs ONCE, then the script either "renders" (dry-run) or "mutates" (apply) from the same in-memory representation
- Anti-pattern: separate code branches for dry-run vs apply that compute the same data via different paths
- The trauma-corpus row: branch-protection-apply.sh 2026-05-20T02:46Z (4 repos misapplied), and the n2228 fix

### B. .flywheel/scripts/parity-contract-validator.sh
Audit script that scans `.flywheel/scripts/*.sh` + `tests/*.sh` for dual-mode scripts and emits a report:
- Detect scripts with both `--dry-run` and `--apply` (or equivalent: `--check` vs `--commit`, `--plan` vs `--execute`)
- For each: probe whether the smoke fixture has a parity-assertion (dry-run JSON envelope equals apply pre-mutation envelope for same input)
- Emit `.flywheel/audits/parity-contract-conformance-<ts>.md` with PASS/FAIL/NO-FIXTURE per script
- Initial scan should classify existing scripts:
  - branch-protection-apply.sh (n2228 fixed, has --verify-parity flag) → PASS
  - auto-push.sh → check
  - supabase-rls-emergency-fix.sh → check
  - mp-validator-framework.sh → check
  - mp-scaffolders/MP-*-scaffold.sh → check
  - codex-goal-mode-monitor-probe.sh → check
  - Any others discovered

### C. .flywheel/scripts/parity-contract-add-fixture.sh
Helper that scaffolds a `parity_assertion` into an existing smoke fixture for a given dual-mode script. Idempotent.

Example output:
```bash
# In tests/<script>-smoke.sh
test_parity_dry_run_apply_envelope() {
  local dry_envelope apply_envelope
  dry_envelope=$(./<script>.sh --dry-run --json | jq -S 'del(.ts, .outcome) | .computation')
  apply_envelope=$(./<script>.sh --apply --json --no-mutate-side-effects | jq -S 'del(.ts, .outcome) | .computation')
  if ! diff <(echo "$dry_envelope") <(echo "$apply_envelope"); then
    echo "FAIL: dry-run and apply diverge on .computation"; return 1
  fi
  echo "ok parity_dry_run_apply_envelope"
}
```

### D. tests/parity-contract-validator-smoke.sh
- 6+ assertions on the validator script itself:
  1. Detect a synthetic dual-mode script in fixture dir
  2. Identify missing parity assertion in fixture
  3. Identify PRESENT parity assertion in fixture
  4. Emit PASS/FAIL classification correctly
  5. Audit report format valid markdown + valid JSON envelope
  6. Idempotent re-scan produces same report

### E. Memory pin
Add memory at ~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_dry_run_apply_parity_contract.md citing tonight's n2228 incident + the doctrine + the validator script. Cross-link to feedback_substrate_contract_shape_mismatch_trauma_family.

## Acceptance

- 4 artifacts ship (doctrine + validator + fixture-helper + smoke fixture)
- Memory pin written
- shellcheck PASS
- Smoke 6+ assertions PASS
- Initial validator scan against current `.flywheel/scripts/*.sh` produces conformance report
- Bead flywheel-vlodi closed
- MEMORY.md line updated with the new pin

## Out of scope

- Actually ADDING parity assertions to all existing dual-mode scripts — separate bead per script (filed as follow-ups based on validator's PASS/FAIL/NO-FIXTURE report)
- Modifying smoke fixtures of existing scripts beyond branch-protection-apply (which n2228 already covered)

## Loop contract

- Track 3 only
- mcp-agent-mail file_reservation_paths before edits
- socraticode K>=10 with 2 phrasings on existing audit primitives + parity patterns
- Bridge daemon LIVE
- SCR event: C7_verification_density + C6_trauma_outflow (dry_run_apply_divergence class)
- STOP on Track 1/2 breach, BLOCKED, >2h hard cap
- DEEP-WORK validate: shellcheck + smoke + initial validator scan

## FIRST ACTION

1. br show flywheel-vlodi.
2. Read .flywheel/scripts/branch-protection-apply.sh post-fix (e37a1f6c) — see how n2228 implemented --verify-parity.
3. Read .flywheel/audits/branch-protection-fleet-dry-run-20260520.md.
4. ACK row.
5. Implement 4 artifacts + memory pin.
6. Self-validate.
7. Commit + close bead + DIRECT pane-1 ntm send.
