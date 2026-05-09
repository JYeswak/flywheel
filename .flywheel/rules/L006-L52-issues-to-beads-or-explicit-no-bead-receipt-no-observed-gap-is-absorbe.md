## L52 — ISSUES-TO-BEADS-OR-EXPLICIT-NO-BEAD-RECEIPT (no observed gap is absorbed silently)

---
id: L52
title: Every observed issue becomes a bead or carries an explicit no_bead_reason receipt
status: long_term
shipped: 2026-04-30
review_due: 2026-10-30
trauma_class: silent-finding-loss
---

**Rule:** Every gap, finding, trauma, or unexpected behavior observed during a worker dispatch MUST become one of:
1. A new bead filed in the originating repo's bead DB (or the repo most relevant to the gap), with the bead ID reported in the worker callback
2. An update to an existing bead (referenced by ID in callback)
3. An EXPLICIT `no_bead_reason` field in the callback explaining why this finding is not bead-worthy (e.g. "transient flake, retried clean", "worker-private scratch issue, fixed in same dispatch")

Worker callbacks lacking ALL of bead_ids_filed / bead_ids_updated / no_bead_reason are non-compliant per L52. Orchestrator treats missing field as DRIFT and re-dispatches asking for the missing receipt.

**Why:** picoz Phase A CLI audit (2026-04-19) discovered that pane 4 reported `findings=N beads_filed=0` — observed real defects, didn't bead them, called it done. Without an explicit no_bead_reason, the orchestrator can't distinguish "no findings" from "findings absorbed silently." Silent-finding-loss is the failure mode where every dispatch produces signal but only a fraction makes it into the trackable substrate.

**Mechanism:**
- Pre-flight in dispatch packet: instructions naming the bead DB path (`<repo>/.beads/`) and the `br create` command shape
- Pre-flight: workers MUST use `scripts/br_create_safe.sh` (or local equivalent) per L47-class enforcement, never raw `br create`
- Callback contract: every DONE/BLOCKED includes one of:
  - `beads_filed=bd-XXX,bd-YYY,...`
  - `beads_updated=bd-XXX:status_change,...`
  - `no_bead_reason=<short-text>` (explicit choice, not absence)

**Forbidden worker callback outputs:** any DONE/BLOCKED missing all three fields. Re-dispatch on detection.

**Override:** None. Silent finding loss has no acceptable footprint — even the "trivial" finding gets a single-line no_bead_reason. JOSHUA_OVERRIDE does NOT bypass L52 because the cost of a forgotten finding compounds.

**Cost citation:** Phase A CLI audit (2026-04-19) found 7 launch-relevant defects pane 4 had observed but not beaded. Required orchestrator to manually re-derive findings from worker scrollback and file beads after the fact. ~30 min recovery cost per missed finding. L52 makes the cost zero by mechanically requiring the callback field.

**Companion rules:** L47 (substrate-owner discipline; canonical-substrate claims require enforcement) — L52 enforces the bead-creation substrate across every dispatch, not just commit-time.


