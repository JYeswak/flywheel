# JSM Meta-Lessons Canonical Reference (flywheel mirror)

**Source:** Jeff Emanuel's `jeffreys-skills.md` official skill pack.
**Origin investigation:** `/Users/josh/Developer/skillos/state/jsm-meta-lesson-investigation-20260518T2235Z/REPORT.md`
**Fleet audit:** `/Users/josh/Developer/skillos/state/jsm-fleet-audit-20260518T2305Z/MANIFEST.md`
**Authored:** 2026-05-18 via skillos:1 cross-repo authorized.

> **Cross-repo canonical:** Skillos is the originator. Updates propagate skillos → flywheel via cross-orch handoff. See `/Users/josh/Developer/skillos/.flywheel/doctrine/jsm-meta-lessons-canonical.md` for any divergence.

---

## MP-01 — Sentinel-classified doctor surface

**Source skills:** `world-class-doctor-mode-for-cli-tools`, `canonical-cli-scoping`.

**Rule:** Before trusting `<bin> <verb> --help; exit 0` as evidence that `<verb>` exists, run `<bin> __sentinel_xyz123__ --help` first. If sentinel exits 0, parser has a fallback (cass-bug round 54 class). Switch to awk-parsing `--help` for the `Commands:` section instead.

**Flywheel adoption:**
- ⚠️ `.flywheel/scripts/test-doctor-sentinel-probe-fleet.py` (sister-script to be authored).
- ⚠️ `br` (beads_rust) + `bv` (beads_viewer) sentinel-safety — verify.

## MP-02 — Verification-first conformance harnesses

**Source skills:** `testing-conformance-harnesses`, `testing-golden-artifacts`, `beads-compliance-and-completion-verification`.

**Rule:** Fixtures need PROVENANCE.md. Divergences need DISCREPANCIES.md. Completion claims require independent re-run with stdout+stderr+exit-code capture — never trust self-reported "tests pass."

**Flywheel adoption:**
- ✅ `beads-compliance-and-completion-verification` upstream + applied via `.flywheel/scripts/closed-bead-artifact-scan.py`.
- ⚠️ Multiple `fixtures/` dirs need PROVENANCE.md (this audit ships scaffolds).

## MP-03 — Agent-ergonomics 11-dimension rubric

**Source skills:** `agent-ergonomics-cli`, `world-class-doctor-mode-for-cli-tools`, `canonical-cli-scoping`.

**Rule:** Every CLI surface (subcommand, flag, exit code, JSON envelope field) is independently scorable 0-1000 across 11 dimensions. `capabilities --json` + `robot-docs` mandatory.

**Flywheel adoption:**
- ✅ `.flywheel/doctrine/agent-ergonomics-application-baseline-2026-05-08.md` active.
- ⚠️ Full 11-dim audit pending for `flywheel-loop`, `flywheel-tick`, etc.

## MP-04 — Receipt-and-callback envelope contract

**Source skills:** `flywheel-end-to-end`, `orchestrator-validation-discipline`, `python-best-practices`.

**Rule:** Callbacks make claims; receipts on disk are the only acceptance. `evidence_path` is a contract, not a label. Doctor surfaces producing reports but driving no action are "decorative" anti-pattern.

**Flywheel adoption:**
- ✅ `.flywheel/scripts/validate-callback.py` — canonical source.
- ✅ `.flywheel/scripts/closed-bead-artifact-scan.py` — closed-bead artifact verifier.
- ✅ `.flywheel/scripts/verify-callback-delivery.sh` — delivery verifier.
- ✅ `.flywheel/callback-validation-log.jsonl` — schema-versioned ledger.

Flywheel is the canonical source for MP-04 in our ecosystem.

---

## Cross-references

- Skillos canonical: `/Users/josh/Developer/skillos/.flywheel/doctrine/jsm-meta-lessons-canonical.md`
- Fleet audit MANIFEST: `/Users/josh/Developer/skillos/state/jsm-fleet-audit-20260518T2305Z/MANIFEST.md`
- Investigation: `/Users/josh/Developer/skillos/state/jsm-meta-lesson-investigation-20260518T2235Z/REPORT.md`
- Sister doctrines: `.flywheel/doctrine/agent-ergonomics-application-baseline-2026-05-08.md`, `.flywheel/doctrine/audit-machinery-hygiene-discipline.md`
