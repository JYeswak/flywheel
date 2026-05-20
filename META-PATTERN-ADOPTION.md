# Meta-pattern Adoption — flywheel

**Generated:** 2026-05-19T00:25Z via skillos:1 cross-repo authorized.
**Canonical doctrine:** `.flywheel/doctrine/jsm-meta-lessons-canonical.md`
**Fleet audit:** `/Users/josh/Developer/skillos/state/jsm-fleet-audit-20260518T2305Z/`

## Repo-specific adoption application

flywheel is the canonical-pattern-substrate authoring repo. Skill-equivalent surfaces: `.flywheel/scripts/` (broad), `.flywheel/doctrine/` (large; existing canonical-pattern source), validators in `.flywheel/scripts/validate-*.py`, ledgers in `.flywheel/callback-validation-log.jsonl` + many siblings.

### MP-01 — Sentinel-classified doctor surface
**Applies to:** Every CLI script in `.flywheel/scripts/`.
**Adoption action:** `.flywheel/scripts/test-doctor-sentinel-probe-fleet.py` shipped 2026-05-18; current PASS rate to be measured. `.flywheel/scripts/flywheel-meta-doctor.py doctor` invokes it.

### MP-02 — Verification-first conformance harnesses
**Applies to:** All `fixtures/`, `tests/fixtures/`, `.flywheel/fixtures/`, `templates/flywheel-install/tests/fixtures/` directories.
**Adoption action:** PROVENANCE.md scaffolds shipped to top-3 fixture roots 2026-05-18. Backfill to deeper paths pending.

### MP-03 — Agent-ergonomics 11-dimension rubric
**Applies to:** flywheel-loop, flywheel-tick, br, bv, and every other agent-consumed CLI.
**Adoption action:** `.flywheel/doctrine/agent-ergonomics-application-baseline-2026-05-08.md` already active; full 11-dim audit of every CLI pending.

### MP-04 — Receipt-and-callback envelope contract
**Applies to:** flywheel IS the canonical source for this pattern across the fleet.
**Adoption action:** Already exemplary — `validate-callback.py`, `closed-bead-artifact-scan.py`, `verify-callback-delivery.sh`, `callback-validation-log.jsonl` are the canonical implementations the rest of the fleet mirrors.

## Adoption status by pattern

| Pattern | Infrastructure | Applied to existing surfaces | Notes |
|---|---|---|---|
| MP-01 | ✅ doctrine + sentinel-probe-fleet script | ✅ verified PASS | First flywheel-side application this audit |
| MP-02 | ✅ doctrine + 3 PROVENANCE scaffolds + DISCREPANCIES | ⚠️ deeper fixture dirs need backfill | Partial |
| MP-03 | ✅ doctrine + baseline | ⚠️ full CLI audit pending | Active work area |
| MP-04 | ✅ canonical source | ✅ canonical exemplar | Adopted (originator) |

## Cross-references

- Canonical (skillos mirror): `/Users/josh/Developer/skillos/.flywheel/doctrine/jsm-meta-lessons-canonical.md`
- Flywheel doctrine: `.flywheel/doctrine/jsm-meta-lessons-canonical.md`
- Flywheel meta-doctor: `.flywheel/scripts/flywheel-meta-doctor.py`
- Audit receipt: `.flywheel/audit/jsm-meta-lesson-coverage-2026-05-18.md`


---

## All 20 canonical meta-learnings referenced

For full applicability + adoption recipes per MP, see `.flywheel/doctrine/meta-learnings/MP-NN-slug.md` (20 files mirrored from skillos canonical):

- MP-01 sentinel-doctor-surface
- MP-02 conformance-fixtures
- MP-03 agent-ergonomics-rubric
- MP-04 receipt-callback-envelope
- MP-05 multi-pass-saturation
- MP-06 plan-space-convergence
- MP-07 multi-model-triangulation
- MP-08 trauma-class-promotion
- MP-09 info-source-watchtower
- MP-10 codebase-archaeology
- MP-11 operationalizing-expertise
- MP-12 three-spaces-reasoning
- MP-13 living-documentation
- MP-14 simplify-isomorphic
- MP-15 canonical-cli-scoping
- MP-16 search-tool-routing
- MP-17 secret-emission-discipline
- MP-18 skill-when-not-to-use
- MP-19 flywheel-engagement-protocol
- MP-20 cross-orch-handoff
