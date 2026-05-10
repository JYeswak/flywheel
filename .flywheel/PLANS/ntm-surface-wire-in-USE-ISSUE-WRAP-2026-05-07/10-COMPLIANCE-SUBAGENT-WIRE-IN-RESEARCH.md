---
title: "Compliance Subagent Wire-In Research"
type: plan
created: 2026-05-08
frontmatter_source: scaffold-doc-frontmatter
---

# Compliance Subagent Wire-In Research

Bead: `flywheel-9sqze`
Date: 2026-05-07
Project: `/Users/josh/Developer/flywheel`
Parent audit: `/Users/josh/Developer/flywheel/beads_compliance_audit/passes/2026-05-07T19-03-18Z/REPORT.md`
Parent audit project SHA: `eedc3bb45c8d7da6fc64c0dd40a7b30fa3dd138b`

## Stub-mode trigger conditions

The first audit's banner is accurate: Phase 4 and Phase 6 were not real verification phases in the local shell run. `scripts/run-pass.sh` explicitly says the wrapper is for local/CI use and "most users should drive the phases via subagents" (`run-pass.sh:42-43`). The same script has no `--real-subagents`, `--phase`, `--no-stub`, or environment-variable switch. The only implemented Phase 4/6 behavior is the unconditional stub branch at `run-pass.sh:187-193`:

- For every bead, if `compliance.json` is absent, it writes `{executor: "stub-wrapper", checks: []}`.
- For every bead, if `test_depth.json` is absent, it writes `{auditor: "stub-wrapper", checks: []}`.
- Existing files are left alone because the writes are guarded by `[ -f "$path" ] || ...`.

`scripts/single-bead-audit.sh` repeats the same pattern for focused audits. It documents the intended handoff in comments: "For real Phase 4, the orchestrator should run the compliance-verifier subagent" (`single-bead-audit.sh:152-158`). It writes `single-bead-stub` artifacts when real files are missing.

The scorer and report generator then preserve the upper-bound behavior:

- `score-bead.py` treats `stub-wrapper` and `single-bead-stub` as stub executors (`score-bead.py:241-273`).
- Stub Phase 4 gets full required-tests credit as WAIVED pending a real `compliance-verifier` run (`score-bead.py:302`).
- Stub Phase 6 gets full test-depth credit as WAIVED pending a real `test-depth-auditor` run (`score-bead.py:374`).
- `master-report.py` counts missing files, `stub_reason`, and stub executor/auditor names as deterministic-only signals and prints the banner (`master-report.py:133-210`).

Net: stub mode is not conditional on a hidden flag. In the current runner, it is the default and only shell-run path unless a separate harness has already written real `compliance.json` and `test_depth.json` before the stub branch executes.

## Real-subagent contract

Phase 4 is defined as execution, not inspection: "Actually re-run the proof" (`PHASES.md:157-165`). The `compliance-verifier` contract is:

- Inputs: `<BEAD_ID>`, project root, `<AUDIT_DIR>/passes/<PASS>/beads/<BEAD_ID>/{spec,evidence}.json`, project test config, and `<AUDIT_DIR>/audit-policy.yaml#phase_4_environment` (`subagents/compliance-verifier.md:10-15`).
- Outputs: `<AUDIT_DIR>/passes/<PASS>/beads/<BEAD_ID>/compliance.json` plus raw logs under `raw/*` (`subagents/compliance-verifier.md:17-20`).
- Required executor field: `executor: "subagents/compliance-verifier.md"` per schema (`EVIDENCE-SCHEMAS.md:191-243`).
- Verdict enum: `PASS | FAIL | MISSING | ERROR | TIMEOUT | SKIPPED | UNVERIFIED_INFRA | WAIVED`.
- Raw capture discipline: stdout, stderr, exit code, duration, and coverage logs where available (`subagents/compliance-verifier.md:22-70`).

Phase 6 is the depth audit: tests may exist and pass, but the auditor measures whether they would catch a real regression (`subagents/test-depth-auditor.md:6-18`). The `test-depth-auditor` contract is:

- Inputs: `<BEAD_ID>`, project root, `<AUDIT_DIR>/passes/<PASS>/beads/<BEAD_ID>/{spec,evidence,compliance,theater}.json`, and the project coverage tool (`subagents/test-depth-auditor.md:10-14`).
- Output: `<AUDIT_DIR>/passes/<PASS>/beads/<BEAD_ID>/test_depth.json` (`subagents/test-depth-auditor.md:16-18`).
- Required auditor field: `auditor: "subagents/test-depth-auditor.md"`.
- Verdict enum: `PASS | PARTIAL | FAIL | WAIVED | INFRA_MISSING` (`subagents/test-depth-auditor.md:55-62`).
- Coverage must be scoped to the bead's cited files, not project-global coverage (`subagents/test-depth-auditor.md:40-53`).

The exact prompt templates for these agents live in `references/EXACT-PROMPTS.md`: Phase 4 at `EXACT-PROMPTS.md:92-120`, Phase 6 at `EXACT-PROMPTS.md:151-166`.

## Integration shape

The intended integration shape is Task-tool/orchestrator subagents, not a Bash subagent script.

Evidence:

- `PHASES.md` repeatedly says to spawn `subagents/*.md` agents; Phase 4 names `subagents/compliance-verifier.md` and Phase 6 names `subagents/test-depth-auditor.md`.
- `MODES-AND-TIERS.md` says Pair tier fans Phase 2-6 across subagents and Squad/Battalion/Swarm use `/agent-mail` and `/ntm` for coordination (`MODES-AND-TIERS.md:73-80`, `111-165`).
- `run-pass.sh` says it is the single-agent local/CI wrapper and does not branch on mode (`run-pass.sh:12-16`, `42-43`).
- There are no `phase-4-*.sh` or `phase-6-*.sh` scripts in the skill. The scripts directory only contains validators/scorers and deterministic wrappers; grep found no real executable harness for `compliance-verifier` or `test-depth-auditor`.

This makes the wire-in pattern only partially implemented. The subagent contracts and prompts are complete; the shell runner has no harness to spawn them, wait for outputs, validate outputs, and resume scoring.

## Wire-in proposal

Do not modify Jeff's skill in flywheel first. Build a flywheel-local pass-2 harness or file the upstream issue asking Jeff to add the equivalent. The minimal real pass shape is:

1. Bootstrap a new pass dir with existing skill scripts.
2. Run Phase 1 inventory, Phase 2 spec extraction, and Phase 3 evidence gathering.
3. Before the runner's stub branch, dispatch Task-tool subagents for Phase 4:
   - One `compliance-verifier` prompt per bead or per small bead slice.
   - The prompt must include project root, pass dir, bead ID list, and a hard requirement to write non-stub `compliance.json` plus `raw/*`.
   - For shared fixtures or DB ports, use Agent Mail reservations or an orchestrator-owned allocation table.
4. Run Phase 5 theater/anomaly scan after Phase 4 so theater findings can invalidate passing test output.
5. Dispatch Task-tool subagents for Phase 6:
   - One `test-depth-auditor` prompt per bead or slice.
   - Require bead-scoped coverage/depth records and non-stub `test_depth.json`.
6. Validate every produced pack with `scripts/validate-evidence.py`.
7. Run Phase 7 synthesis, Phase 8 scoring, Phase 9 remediation in `report-only` for pass-2, and Phase 10 only after the first real Phase 4/6 pass is stable.

Because the existing `run-pass.sh` is monolithic, the implementation should not try to insert work by hand between lines 186 and 187. It should either:

- add a flywheel-local orchestrator wrapper that calls the individual skill scripts in phase order and owns subagent dispatch, or
- ask Jeff to add first-class runner flags: `--real-phases 4,6`, `--no-stub`, `--resume-from`, `--stop-after`, and a machine-readable task queue.

For flywheel pass-2, scope first:

- Recommended first real run: the 40-ish beads in the 2026-05-07 wire-in/follow-up plan, not all 1107 beads.
- Policy: `report-only`.
- Environment: start native with explicit limits, then escalate to docker once the harness is proven.

Suggested initial `audit-policy.yaml` addition:

```yaml
phase_4_environment:
  kind: native
  network_policy: localhost-only
  allow_real_services: []
  capture_strace: false
  resource_caps:
    memory: 4G
    cpus: 4
    pids: 1024
```

`PHASE-4-ENVIRONMENTS.md` says docker is the Standard-mode default, but native is acceptable for local fast iteration and low-risk projects (`PHASE-4-ENVIRONMENTS.md:13-40`). The first flywheel pass should optimize for proving the harness rather than perfect replay isolation.

## Risk + cost

Primary blocker: there is no current runner flag, env var, or executable harness that turns Phase 4/6 real. The documented integration assumes an orchestrator with Task-tool subagent spawning.

Operational risks:

- Phase 4 executes arbitrary test/build/fuzzer commands on the audit host.
- Some tests may mutate local state, bind fixed ports, or require external services.
- Full-universe execution may overrun the operator's runtime cap before yielding actionable signal.
- If real files are malformed or carry stub executor names, `score-bead.py` and `master-report.py` will keep treating the pass as deterministic-only.

Cost estimate:

- Skill reference cost heuristics say Swarm tier is roughly `$0.03` per bead and 1107 beads would be about `$33` in optimistic amortized mode (`MODES-AND-TIERS.md:218-231`).
- Prompt-cache reference gives a more conservative 1000-bead estimate: about `$1100` without caching and about `$420` with caching (`PROMPT-CACHE-AMORTIZATION.md:63-71`).
- I would budget pass-2 as `scoped40:$10-50` and `full1107:$420-1300`, because real Phase 4/6 generates raw outputs and may require retries/infra triage beyond pure prompt cost.

Runtime estimate:

- Scoped 40-bead pass: `1-2h` if tests are mostly shell/unit paths, `2-4h` if many beads trigger broad suites.
- Full 1107-bead pass: `6-10h+` with 8-9 agents, and longer if test execution or infra failures dominate.

Safety recommendation: first real pass should be sample/scoped, report-only, localhost-only, and should fail unknown external services as `UNVERIFIED_INFRA` rather than silently skipping them.

## Proposed implementation beads

1. Title: `[bcv] build scoped Phase 4/6 Task-tool harness for real compliance packs`
   Priority: P1
   Expected output: flywheel-local harness that bootstraps a pass, stops after Phase 3, emits Task-tool prompts for `compliance-verifier`, waits for non-stub `compliance.json`, runs Phase 5, emits Task-tool prompts for `test-depth-auditor`, validates packs, then scores.
   Acceptance: two-bead fixture pass produces non-stub `executor`/`auditor` fields and `master-report.py` no longer prints the deterministic-only banner for those beads.

2. Title: `[bcv] define flywheel Phase 4 audit environment policy and dry-run safety gate`
   Priority: P1
   Expected output: `audit-policy.yaml` with `phase_4_environment`, resource limits, network policy, service allowlist, and a dry-run command inventory before real execution.
   Acceptance: dry-run lists every command the compliance verifier would run, classifies shared-resource collisions, and refuses external network/service calls not in the allowlist.

3. Title: `[bcv] upstream Jeff issue: run-pass lacks real-subagent phase/resume interface`
   Priority: P2
   Expected output: anonymized issue body asking for `--real-phases 4,6`, `--no-stub`, `--stop-after`, `--resume-from`, and JSON task-queue artifacts for subagent runners.
   Acceptance: issue filed with source citations to `run-pass.sh`, `single-bead-audit.sh`, `PHASES.md`, and the first audit's deterministic-only banner.

## Verdict

`wire_in_pattern_identified=partial`.

The skill already defines the real subagent contracts and schemas. The missing layer is an orchestrator harness that invokes those subagents between Phase 3/4/5/6 and prevents the deterministic wrapper from writing stub artifacts. Treat the current scores as upper bounds until that harness exists and pass-2 produces non-stub Phase 4 and Phase 6 JSON for the target bead set.
