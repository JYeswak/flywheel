# flywheel-4wmqc — Worker Report

**Task:** [file-length-split] flywheel-hzsro.6 — split phase 6 per `.flywheel/audit/flywheel-hzsro/split-plan.md`
**Identity:** MagentaPond (codex-pane on flywheel:0.3)
**Repo head:** be0e731 (master)
**Status:** BLOCKED — scope-exceeds-worker-tick-budget; decomposition follow-up filed
**Mission fitness:** infrastructure — file-length-discipline split execution; needs sub-bead decomposition before any byte-touch.

## Verdict

**BLOCKED.** Phase 6 = split file 3 (`part-02-portable_doctor.sh`, 1836 lines) per the canonical split-plan ordering at lines 233-238:

| Slot | Action | Status |
|---|---|---|
| .1 | fixture: loop_driver_doctor_json.py | DONE (n5wa5) |
| .2 | split: loop_driver_doctor_json.py | DONE (mcxwl) |
| .3 | fixture: identity.py | DONE (cg1i9) |
| .4 | split: identity.py | OPEN (vzfo5) |
| .5 | fixture: part-02-portable_doctor.sh | DONE (xmd4y; m49r2 same scope, possibly duplicate) |
| **.6** | **split: part-02-portable_doctor.sh** | **THIS DISPATCH — BLOCKED** |

Subject is a 1836-line monolithic shell function (`portable_doctor()`) with 58 `local` declarations, 17+ inline sub-probes, 4 explicit exit calls, and 65 `JSON_OUT` references. The split-plan itself classifies this as risk-tier-3 (line 252: "careful staging + parity verification across multiple test paths") and admits at line 226: "Probably 2 dispatches just for the fixture, before the actual splits can land." The split is even more complex.

**The 120s worker-tick budget cannot safely execute an 8-sub-module shell function-body extraction with `local`-variable scope contract preservation.** Attempting this single-tick courts state-leak regressions that the parity fixture's 8 static-surface assertions cannot catch (the fixture asserts arg-parser surface, scope subcommand matrix, JSON emission point, and exit codes — but NOT `local` scope leakage between extracted sub-files).

## Decomposition follow-up

Filed `flywheel-v1dlm` — `[file-length-split-decompose] flywheel-hzsro Phase 6 needs sub-bead decomposition`.

Body lists the canonical 8-sub-file motion from split-plan lines 119-130:

| # | Sub-file | Lines | Content | Risk |
|---|---|---:|---|---|
| 1 | `01-arg-parse.sh` | ~50 | strict, fix, scope, storage thresholds | LOW (no `local` contract) |
| 2 | `02-scoped-probes-pre.sh` | ~250 | 11 scoped_doctor calls (pre-aggregation) | HIGH (cross-scope `local`) |
| 3 | `03-scoped-probes-mid.sh` | ~200 | 6 more scoped_doctor calls | HIGH (cross-scope `local`) |
| 4 | `04-section-a-l-rule-fields.sh` | ~150 | Section A wire-in | MED |
| 5 | `05-section-b-substrate-primitives.sh` | ~120 | Section B substrate primitive auto-fire | MED |
| 6 | `06-section-c-quality-bar.sh` | ~80 | Section C quality-bar fields | LOW |
| 7 | `07-section-de-propagation-plan-skill.sh` | ~150 | Sections D + E | MED |
| 8 | `08-section-fg-comms-session.sh` | ~80 | Sections F + G | LOW |

Recommended order (lowest risk first to prove pattern):
1. `01-arg-parse.sh` (smallest, no `local` contract)
2. `06-section-c-quality-bar.sh`, `08-section-fg-comms-session.sh` (small Section blocks)
3. `04-section-a-l-rule-fields.sh`, `07-section-de-propagation-plan-skill.sh` (mid Section blocks)
4. `05-section-b-substrate-primitives.sh` (Section B, larger surface)
5. `02-scoped-probes-pre.sh`, `03-scoped-probes-mid.sh` (largest scoped-probe blocks; most `local` cross-scope risk)

Each sub-file = own bead. After all 8 sub-bead splits land, `tests/part-02-portable_doctor_parity_fixture.sh` must still PASS (with assertion 2 reporting "removed (post-split)" instead of "present").

## Acceptance gate coverage

The bead body is empty. Implicit gate from title (`split phase 6 per split-plan.md`):

| Implicit gate | Status | Reason |
|---|---|---|
| Execute the file 3 split per split-plan motion | NOT_DID — out_of_scope | 1836-line shell function with 58 `local` decls + 17 inline sub-probes is risk-tier-3 multi-dispatch work (split-plan line 252); 120s worker-tick budget cannot safely execute this in one tick |
| Verify parity with the m49r2/xmd4y fixture | DID (pre-state only) | `tests/part-02-portable_doctor_parity_fixture.sh` runs green pre-split: 8/8 PASS |
| File decomposition follow-up bead | DID | flywheel-v1dlm filed with canonical 8-sub-file motion + risk-ranked execution order |

did=2/3, didnt=split-execution-deferred-to-flywheel-v1dlm-and-its-8-sub-beads, gaps=none.

## Live verification (pre-state)

```bash
# Subject file: 1836 lines, allow-large 3.7×
wc -l ~/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh
# → 1836

# Local-variable count (scope-discipline surface)
grep -cE "^\s+local\s" ~/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh
# → 58

# Parity fixture passes pre-split
bash /Users/josh/Developer/flywheel/tests/part-02-portable_doctor_parity_fixture.sh
# → PASS PASS PASS PASS PASS PASS PASS PASS
# → "part-02-portable_doctor shape-parity fixture passed (8 assertions)"

# Allow-large receipt still cited (post-split should remove)
grep -c "canonical-cli-scoping-allow-large" ~/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh
# → 1
```

L112 probe: `bash /Users/josh/Developer/flywheel/tests/part-02-portable_doctor_parity_fixture.sh 2>&1 | tail -1` expects literal `part-02-portable_doctor shape-parity fixture passed (8 assertions)`.

## Files changed

- `+ /Users/josh/Developer/flywheel/.flywheel/evidence/flywheel-4wmqc/report.md` — this file (BLOCKED report)
- New bead: `flywheel-v1dlm` (decomposition follow-up; `.beads/issues.jsonl` row added by `br create`)

No source-code edits. Subject file untouched.

## Three-Q

- **VALIDATED:** pre-state verified — fixture passes, subject at 1836 lines with 58 `local` decls and `canonical-cli-scoping-allow-large` receipt; doctor failures (`loop_state_without_driver`, tentacle probes) are fleet-side and unrelated to this dispatch's scope.
- **DOCUMENTED:** rationale for BLOCK is grounded in split-plan's own line 252 ("careful staging + parity verification across multiple test paths") and line 226 ("Probably 2 dispatches just for the fixture"); decomposition follow-up names the 8 sub-files with risk ranking + recommended order.
- **SURFACED:** flywheel-v1dlm decomposition bead is the next-actionable; fixture stays green as the apply-gate; `flywheel-4wmqc` resumes after the 8 sub-bead splits land.

## Four-Lens Self-Grade

four_lens=brand:9,sniff:9,jeff:8,public:9 — **4/4 PASS**

- **Brand (9/10):** scope-respecting honest decline — surfaces the worker-tick budget mismatch instead of attempting a reckless one-shot 1836-line refactor; preserves the fixture-as-apply-gate pattern; cites the split-plan's own risk-tier-3 framing.
- **Sniff (9/10):** pre-state metrics captured (1836 lines, 58 locals, fixture green); decomposition is risk-ranked; no source-code mutation pending verification.
- **Jeff (8/10):** cites operational primitives (`wc -l`, `grep -cE`, `bash`); honors the canonical Jeff pattern of "fixture-first → scoped split → parity verification"; the BLOCK is the right call when the unit-of-work doesn't fit the unit-of-dispatch — Jeff's beads_rust philosophy is exactly this kind of explicit unit-sizing.
- **Public (9/10):** **Three Judges check** — skeptical operator can re-run the parity fixture and confirm pre-split state; maintainer reads the 8-sub-file table + risk ranking and understands the deferred work; future worker(s) doing the 8 sub-bead splits have ordered execution + apply-gate.

`evidence_schema_version=worker-evidence/v1`. `block_class=scope_exceeds_worker_tick_budget`. `four_lens_close_validator_version=four-lens-close-validator/v1`.

## Skill auto-routes addressed

- `canonical-cli-scoping=n/a` — no new CLI surface authored; the BLOCK reasoning cites the canonical-cli-scoping `[ ] file-length threshold respected or allowed-large receipt cited` axiom indirectly (the split-plan itself was authored to remove the allow-large receipt).
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — subject is shell.
- `readme-writing=n/a` — no README.

## Skill discoveries

`skill_discoveries=1 sd_ids=worker-tick-scope-mismatch-class`

| Kind | Discovery |
|---|---|
| `pattern-recurrence` | Single-tick dispatch of multi-day refactor work — recurring shape: parent plan defers execution to follow-up beads, but follow-ups get re-dispatched as if scoped for one tick. The right move is to BLOCK + decompose, not attempt. Convergent with `feedback_audit_before_build_when_substrate_underutilized` (substrate decomposition gates new bead authoring); this is its execution-side analogue. |

## L52 / L70 receipt

- L52 (issues-to-beads): **decomposition bead filed = `flywheel-v1dlm`**. Body names 8 sub-files with risk ranking + recommended execution order.
- L70 (no-punt): the next-actionable IS the decomposition. Filing `flywheel-v1dlm` in the same tick satisfies L70 (didn't punt to "Joshua decides") — the data (split-plan lines 119-130 + 252) decided the decomposition shape.

## L61 ecosystem-touch

- `agents_md_updated=no` — no L-rule promotion.
- `readme_updated=not_applicable` — no README touched.
- `no_touch_reason=block-with-decomposition-no-doctrine-change`

## Compliance Pack

Score: 880/1000.

- 2/3 implicit gates DID (pre-state probe + decomposition filing); 1 deferred (split execution → flywheel-v1dlm)
- Pre-split fixture green (8/8 PASS)
- Decomposition follow-up filed with risk ranking + ordered execution recommendation
- 4/4 lenses with 8-9/10 self-grades
- L107 reservations: not acquired — no shared-surface mutation in BLOCKED outcome

Pack path: `.flywheel/evidence/flywheel-4wmqc/`.

## Cross-references

- Parent: `flywheel-hzsro` (closed; produced split-plan)
- Phase 6 fixture (apply-gate): `tests/part-02-portable_doctor_parity_fixture.sh` (`flywheel-xmd4y`)
- Phase 6 decomposition (filed): `flywheel-v1dlm`
- Sibling Phase 4 (file 2 split, identity.py): `flywheel-vzfo5` (open; analogous decomposition expected)
- Sibling Phase 5 (file 3 fixture): `flywheel-m49r2` (open; possibly duplicate of `flywheel-xmd4y` per phase-numbering anomaly)
- Split-plan: `.flywheel/audit/flywheel-hzsro/split-plan.md` File 3 (lines 119-130, 252)
- Subject: `~/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh` (1836 lines, allow-large 3.7×, 58 local declarations)
- L-rules cited: L70 (no-punt — decomposition filed in same tick), L52 (issues-to-beads — flywheel-v1dlm), L48 (worker scope discipline — BLOCKED honors 120s budget)
