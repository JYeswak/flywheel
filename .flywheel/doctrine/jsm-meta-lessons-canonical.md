# JSM Meta-Lessons Canonical Reference

**Source:** Jeff Emanuel's `jeffreys-skills.md` official skill pack (synced 2026-05-18).
**Origin investigation:** `state/jsm-meta-lesson-investigation-20260518T2235Z/REPORT.md`.
**Status:** Canonical doctrine for flywheel-ecosystem authoring + audit work.
**Maintained by:** skillos canonical-locator lane.

This file names the 4 highest-confidence meta-patterns extracted from Jeff's official skill pack and the flywheel ecosystem's adoption status for each. Refer to this file before authoring any new CLI surface, doctor script, fixture directory, or callback contract. Every new substrate piece should be checked against these patterns.

---

## MP1 — Sentinel-classified doctor surface

**Source skills:** `world-class-doctor-mode-for-cli-tools`, `canonical-cli-scoping`.

**Rule:** Before trusting `<bin> <verb> --help; exit 0` as evidence that `<verb>` exists, run `<bin> __sentinel_xyz123__ --help` first. If sentinel exits 0, the parser has a fallback (like `cass <unknown>` falling through to `cass search`) and exit-code-based verb probing is unreliable — switch to awk-parsing the `Commands:` section of `--help` instead.

**Why:** A round-54 audit on cass found 5 phantom diagnostic verbs because `cass verify --help`, `cass repair --help`, etc. all exited 0 via search-fallback. Agents reading the probe output would write specs for verbs that don't exist.

**Adoption (flywheel ecosystem):**
- ✅ Skillos doctor scripts (`scripts/skillos_*.py`) have proper `if fn is None: return 1` patterns; no silent-fallback.
- ⚠️ No automated sentinel-probe meta-test (now added at `scripts/tests/test_doctor_sentinel_probe.py` 2026-05-18).
- ⚠️ `bin/skillos` top-level shim not yet graded against agent-ergonomics 11-dim rubric.

---

## MP2 — Verification-first conformance harnesses

**Source skills:** `testing-conformance-harnesses`, `testing-golden-artifacts`, `beads-compliance-and-completion-verification`.

**Rule:** Fixtures need PROVENANCE.md (how generated, version, date). Divergences need DISCREPANCIES.md disposition (ACCEPTED / INVESTIGATING / WILL-FIX). Completion claims require independent re-run with stdout+stderr+exit-code capture — never trust self-reported "tests pass."

**Score threshold:** MUST-clauses ≥ 0.95 pass rate; below = NOT conformant.

**Adoption (flywheel ecosystem):**
- ✅ Skillos `tests/fixtures/capability_*/` use `valid_*` / `invalid_*` naming matching the conformance-harness pattern.
- ✅ `validate_capability_transition.py` doctor command re-runs fixture validation with `expected_status` cross-check.
- ⚠️ Skillos `tests/fixtures/` directories lacked PROVENANCE.md until 2026-05-18 (template now added).
- ⚠️ No top-level DISCREPANCIES.md (low priority — skillos isn't porting from a reference impl).

---

## MP3 — Agent-ergonomics 11-dimension rubric

**Source skills:** `agent-ergonomics-cli`, `world-class-doctor-mode-for-cli-tools` (Phase-6 grader), `canonical-cli-scoping`.

**Rule:** Every CLI surface (subcommand, flag, exit code, JSON envelope field) is independently scorable 0-1000 across 11 dimensions: agent_intuitiveness, agent_ergonomics (stable JSON + exit codes + stderr/stdout discipline), automation_degree, data_safety, idempotence, intent_infer_then_act, safe_alternative_always, self_describing (capabilities --json), in_tool_docs (robot-docs), exit_code_contract, error_teaches.

**Canonical surface for doctor CLIs (verbatim):**
```text
<tool> doctor                              # exit 0 healthy, 1 findings, 4 unsafe-refused
<tool> doctor --fix                        # exit 0/2/3/4
<tool> doctor --dry-run --fix              # print plan, do NOT execute
<tool> doctor --explain <finding-id>       # expand one finding with full evidence
<tool> doctor undo <run-id> | latest       # restore from .doctor/runs/<id>/backups/
<tool> doctor capabilities --json          # version, contract, detectors, fixers, exit codes, schema_version
<tool> doctor health                       # cheap liveness, one line + exit code, for CI
<tool> doctor robot-docs                   # paste-ready agent handbook to stdout
<tool> doctor ls | diff | gc | --quick | --json | --robot | --online | --robot-triage
```

**Adoption (flywheel ecosystem):**
- ✅ `.flywheel/doctrine/agent-ergonomics-application-baseline-2026-05-08.md` active ~10 days; baseline graded.
- ⚠️ Most skillos doctor scripts lack `--explain <finding-id>` flag (Gap-5 in investigation report).
- ⚠️ No skillos CLI provides `robot-docs` paste-ready agent handbook output (Gap-6).

---

## MP4 — Receipt-and-callback envelope contract

**Source skills:** `flywheel-end-to-end`, `orchestrator-validation-discipline`, `python-best-practices`.

**Rule:** Callbacks make claims; receipts on disk are the only acceptance criterion. The `evidence_path` field of a callback is a contract — file MUST exist with the schema-versioned envelope. Doctor surfaces that produce reports but drive no action are "decorative" anti-pattern.

**Canonical callback envelope:**
```text
Callback: task_id=<id> phase=<phase> tick_class=<class> status=<done|warn|blocked> repo=<path> receipt=<path or none> next_phase=<phase> findings=<N>
```

**Anti-patterns to forbid (per `flywheel-end-to-end/references/ANTI-PATTERNS.md`):**
1. `loop-state-without-driver` — state says loop active but no orchestrator receives prompts
2. `callback-without-receipt` — callback says done but no evidence file
3. `dispatch-without-reservation` — workers edit files without reserving them
4. `decorative-doctor` — doctor reports produced but no action driven
5. `beadless-plan` — plan files exist but no actionable beads
6. `driver-hardcodes-pane` — tick script sends to stale pane number
7. `raw-pane-ops` — instructions use terminal multiplexer instead of `ntm send`

**Adoption (flywheel ecosystem):**
- ✅ `.flywheel/last_closeout_receipt.json` uses `schema_version: "flywheel.loop.closeout.v2"`.
- ✅ `state/blocker-escalations.jsonl` uses `schema_version: "skillos.blocker_escalation.v1"`.
- ✅ Receipt-evidence-must-exist-on-disk trauma class hardened (memory `feedback_callback_evidence_must_exist_on_disk`).
- ⚠️ No mechanical check that every `state/*.json` file cites `schema_version` (Gap-7).
- ⚠️ No mechanical check that callback `evidence_path` fields point to extant files (Gap-8; cross-orch verifier exists in flywheel substrate but skillos lacks a sibling).

---

## How to use this file

**Before authoring a new CLI surface:** Check MP1 + MP3. Verify sentinel-probe safety + 11-dim ergonomics alignment.

**Before authoring a new fixture directory:** Check MP2. Add PROVENANCE.md. Use `valid_*` / `invalid_*` naming.

**Before authoring a new state-machine or dispatch:** Check MP4. Define schema_version. Define evidence_path contract. Bind callback to receipt verification.

**During audit work:** Each MP has an explicit anti-pattern list. Audit findings should cite the specific pattern + sub-rule violated.

---

## Cross-references

- Investigation report: `state/jsm-meta-lesson-investigation-20260518T2235Z/REPORT.md`
- Sentinel-probe meta-test: `scripts/tests/test_doctor_sentinel_probe.py`
- Existing agent-ergonomics baseline: `.flywheel/doctrine/agent-ergonomics-application-baseline-2026-05-08.md`
- Existing audit-machinery doctrine: `.flywheel/doctrine/audit-machinery-hygiene-discipline.md`
- Skill sources: `~/.claude/skills/world-class-doctor-mode-for-cli-tools/`, `~/.claude/skills/testing-conformance-harnesses/`, `~/.claude/skills/agent-ergonomics-cli/`, `~/.claude/skills/flywheel-end-to-end/`, `~/.claude/skills/orchestrator-validation-discipline/`, `~/.claude/skills/beads-compliance-and-completion-verification/`.


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
