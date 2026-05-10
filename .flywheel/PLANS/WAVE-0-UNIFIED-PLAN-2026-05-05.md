---
title: "WAVE-0 UNIFIED PLAN 2026-05-05"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

## Contents

- [Executive Summary](#executive-summary)
- [Source Read](#source-read)
- [Deduplication Model](#deduplication-model)
- [Unified Wave-0 Work List](#unified-wave-0-work-list)
  - [Foundation Spine](#foundation-spine)
  - [Quick-Fix Packages](#quick-fix-packages)
  - [Close Packages](#close-packages)
  - [Substrate Hygiene Instance Packages](#substrate-hygiene-instance-packages)
  - [Doctrine Promotion Packages](#doctrine-promotion-packages)
- [Sub-Wave Plan](#sub-wave-plan)
  - [wave-0a Parallelizable Foundation Bead Writes](#wave-0a-parallelizable-foundation-bead-writes)
  - [wave-0b Sequential Close Ops](#wave-0b-sequential-close-ops)
  - [wave-0c Substrate Hygiene](#wave-0c-substrate-hygiene)
  - [wave-0d Doctrine Promotions](#wave-0d-doctrine-promotions)
- [Dispatch Packet Drafts For Foundation Beads](#dispatch-packet-drafts-for-foundation-beads)
- [Risk Register](#risk-register)
- [wave.1.readiness Verdict](#wave-1-readiness-verdict)
- [Total Estimated Time-To-Wave-1](#total-estimated-time-to-wave-1)
- [Closeout Metrics](#closeout-metrics)
# WAVE-0 UNIFIED PLAN 2026-05-05

Mode: plan-space only.

Output owner: worker tick parity, no Beads database writes.

Primary sources:

- `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md`
- `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md`
- `.flywheel/PLANS/UNIFIED-DAG-2026-05-05.md`

## Executive Summary

1. Wave-0 has 47 logical work packages and 182 instance-level actions.
2. Instance-level actions are 12 foundation beads, 12 quick fixes, 6 close candidates, 14 doctrine promotions, 47 dirty-file dispositions, 86 stale-dispatch dispositions, and 5 stale-loop-marker repairs.
3. The 12 reconciliation foundation beads are the execution spine; the infra scan becomes hygiene, quick-fix, close, and doctrine lanes around that spine.
4. Deduplication overlap count is 8: the infra scan's 8 Wave-0 candidates are merged into existing foundation and hygiene packages instead of dispatched as duplicate top-level beads.
5. Current portfolio wave-1 readiness is NO-GO because reconciliation says Wave 1 is only plan-local GO and needs foundations first.
6. Wave-1 readiness after Wave-0 is GO if every Wave-0 gate closes or is explicitly deferred with owner, verification probe, and tick-status consequence.
7. Estimated wall time to Wave-1 under 3-4 active workers and serialized Beads updates is 8.0 hours.
8. Estimated serial effort is 17.5 hours, but the plan splits into four sub-waves to preserve parallelism.
9. Beads DB mutation remains reserved for later apply packets; this document only drafts packets and close orders.
10. The first Wave-1 candidate set remains unchanged: `flywheel-njf5c`, `flywheel-2dywy`, `flywheel-3g75v`, `flywheel-181e5`, `flywheel-3ctlx`.

## Source Read

SR-01. Reconciliation is plan-space only and performed no Beads writes.
Citation: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:3-5`.

SR-02. Reconciliation says the portfolio order changes: Wave 1 is only plan-local GO and needs foundations first.
Citation: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:7-15`.

SR-03. Reconciliation counts the top-100 backlog as 56 FOUNDATION, 4 DUPLICATE, 38 ORTHOGONAL, and 2 OBSOLETE.
Citation: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:27-32`.

SR-04. Reconciliation names the 12 Wave-0 foundation candidates.
Citation: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1077-1094`.

SR-05. Reconciliation requires a separate apply dispatch before closing duplicates or obsolete beads.
Citation: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:941-950`.

SR-06. Infra scan is also plan-space only and scanned eight dimensions.
Citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:1-11`.

SR-07. Infra scan says loop-driver truth, dispatch freshness, fuckup triage, bead substrate, Agent Mail, dirty tree, dispatch spool, and secret-output lint must precede Wave-1.
Citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:13-20`.

SR-08. Infra scan reports 36 gaps, 8 Wave-0 candidates, 12 quick fixes, 14 doctrine candidates, 5 stale loop markers, 86 stale dispatches, and 47 dirty tracked files.
Citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:1133-1146`.

SR-09. The prior UNIFIED-DAG Wave-1 plan is still internally coherent and lists five first-wave beads.
Citation: `.flywheel/PLANS/UNIFIED-DAG-2026-05-05.md:246-261`.

SR-10. The Wave-1 control ledger requires serialized Beads mutation, file reservations, Socraticode evidence, and clean callback fields.
Citation: `.flywheel/PLANS/UNIFIED-DAG-2026-05-05.md:603-626`.

SR-11. Late close-apply evidence changed the close lane: all six close candidates were skipped because active dependents were present; zero `br close` commands executed.
Citation: `.flywheel/PLANS/WAVE-0-CLOSE-APPLY-LOG-2026-05-05.md:11-20` and `.flywheel/PLANS/WAVE-0-CLOSE-APPLY-LOG-2026-05-05.md:53-62`.

SR-12. The close lane is therefore dependent-audit-first, not direct close-first.
Citation: `.flywheel/PLANS/WAVE-0-CLOSE-APPLY-LOG-2026-05-05.md:163-172` and `.flywheel/PLANS/WAVE-0-CLOSE-APPLY-LOG-2026-05-05.md:214-222`.

## Deduplication Model

DD-01. Deduplication rule: keep one action owner for each feedback-loop stock. Do not create separate work items for a symptom, a detector, and a dashboard field when one foundation bead can own the invariant.

DD-02. The reconciliation foundation list owns implementation primitives. The infra gap list owns readiness gates and hygiene. Where both name the same stock, Wave-0 uses the foundation bead as the implementation handle and the infra item as acceptance evidence.

DD-03. Overlap O1: Infra W0.1 loop-driver truth repair overlaps `flywheel-2eow`, `flywheel-3mmp`, QF.1, QF.2, and the five stale-loop-marker repairs.
Citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:618-623` and `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:956-963`.

DD-04. Overlap O2: Infra W0.2 dispatch/callback stale reaper overlaps `flywheel-olhg`, QF.3, QF.4, QF.5, and the 86 stale-dispatch dispositions.
Citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:625-629` and `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:967`.

DD-05. Overlap O3: Infra W0.3 fuckup-log triage overlaps the 14 doctrine candidates and the future `/flywheel:learn` promotion queue.
Citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:631-635` and `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:747-820`.

DD-06. Overlap O4: Infra W0.4 Beads substrate repair overlaps the serialized Beads mutation discipline in the Wave-1 control ledger.
Citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:637-641` and `.flywheel/PLANS/UNIFIED-DAG-2026-05-05.md:607-619`.

DD-07. Overlap O5: Infra W0.5 Agent Mail identity correction overlaps `flywheel-uufu`, `flywheel-2ui1`, `flywheel-7ris`, `flywheel-se3h.2`, QF.6, and QF.7.
Citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:643-647` and `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:963-977`.

DD-08. Overlap O6: Infra W0.6 dirty-tree checkpoint plan is not a foundation bead. It remains a substrate hygiene work package with 47 instance-level dispositions.
Citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:649-653` and `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:1142-1145`.

DD-09. Overlap O7: Infra W0.7 dispatch spool retention overlaps QF.8 and the 86 stale-dispatch dispositions.
Citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:655-659` and `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:123-132`.

DD-10. Overlap O8: Infra W0.8 secret-output lint overlaps the dispatch-v2 wrapper and dispatch template L112 generation.
Citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:661-665` and `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:700-701`.

DD-11. Deduplication overlap count: 8.

DD-12. Logical package count after deduplication: 47.

DD-13. Instance-level count after deduplication: 182.

DD-14. Work list count formula: 12 foundation + 12 quick-fix + 6 close + 14 doctrine + 1 dirty-file checkpoint package + 1 stale-dispatch disposition package + 1 stale-loop repair package = 47 packages.

DD-15. Instance formula: 12 foundation + 12 quick-fix + 6 close + 14 doctrine + 47 file dispositions + 86 dispatch dispositions + 5 loop-marker repairs = 182 actions.

## Unified Wave-0 Work List

### Foundation Spine

W0-F01.
item_id: `W0-F01`.
source_lane: reconciliation foundation.
classification: FOUNDATION.
bead: `flywheel-2eow`.
action: ship wire-or-explain doctor fields before Wave-1.
effort_estimate: 45m.
blocks-which-wave-1-bead: all five Wave-1 beads because every callback needs wiredness proof.
evidence: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:956` and `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1085`.
notes: absorbs infra W0.1 acceptance field pressure.

W0-F02.
item_id: `W0-F02`.
source_lane: reconciliation foundation.
classification: FOUNDATION.
bead: `flywheel-y6a1`.
action: ship wire-priority ranker so unresolved wiring gets deterministic order.
effort_estimate: 45m.
blocks-which-wave-1-bead: all five Wave-1 beads by preventing arbitrary artifact wiring order.
evidence: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:957` and `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1084`.
notes: should consume ledger rows produced by W0-F03.

W0-F03.
item_id: `W0-F03`.
source_lane: reconciliation foundation.
classification: FOUNDATION.
bead: `flywheel-4m2a`.
action: ship wire-or-explain ledger schema and append-only writer.
effort_estimate: 60m.
blocks-which-wave-1-bead: all five Wave-1 beads because implementation artifacts need durable wiring records.
evidence: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:958` and `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1081`.
notes: this is the stock; other wire-or-explain components are inflows, detectors, rankers, or drains.

W0-F04.
item_id: `W0-F04`.
source_lane: reconciliation foundation.
classification: FOUNDATION.
bead: `flywheel-333j`.
action: ship ship-event classifier.
effort_estimate: 45m.
blocks-which-wave-1-bead: all five Wave-1 beads because artifact creation must be classified before closeout.
evidence: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:959` and `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1082`.
notes: also informs duplicate and obsolete closure confidence.

W0-F05.
item_id: `W0-F05`.
source_lane: reconciliation foundation.
classification: FOUNDATION.
bead: `flywheel-2ypj`.
action: ship tick-close gate.
effort_estimate: 45m.
blocks-which-wave-1-bead: all five Wave-1 beads because Wave-1 closeout must refuse unwired work.
evidence: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:960` and `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1086`.
notes: gate must report explicit deferral fields, not only pass/fail.

W0-F06.
item_id: `W0-F06`.
source_lane: reconciliation foundation.
classification: FOUNDATION.
bead: `flywheel-12ip`.
action: ship wired detector.
effort_estimate: 45m.
blocks-which-wave-1-bead: all five Wave-1 beads because artifacts need a detector before they can be declared wired.
evidence: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:961` and `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1083`.
notes: detector should operate on the ledger from W0-F03.

W0-F07.
item_id: `W0-F07`.
source_lane: reconciliation foundation and infra loop-driver truth.
classification: FOUNDATION.
bead: `flywheel-3mmp`.
action: define tick receipt schema registry and graduation contract.
effort_estimate: 75m.
blocks-which-wave-1-bead: all five Wave-1 beads because tick receipts are the acceptance surface for worker completion.
evidence: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:962` and `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1087`.
notes: carries loop marker truth pressure from infra W0.1.

W0-F08.
item_id: `W0-F08`.
source_lane: reconciliation foundation and infra Agent Mail/session hygiene.
classification: FOUNDATION.
bead: `flywheel-2ui1`.
action: repair recovery-system B03 session paths.
effort_estimate: 60m.
blocks-which-wave-1-bead: all five Wave-1 beads because stuck-pane recovery must not become a Joshua handoff.
evidence: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:963` and `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1090`.
notes: should cite protected-session recovery receipts in callback.

W0-F09.
item_id: `W0-F09`.
source_lane: reconciliation foundation and infra Agent Mail/session hygiene.
classification: FOUNDATION.
bead: `flywheel-uufu`.
action: ship recovery-system B02 preinstall audit and session path map.
effort_estimate: 60m.
blocks-which-wave-1-bead: all five Wave-1 beads because dispatch and recovery need a truthful session map.
evidence: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:964` and `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1089`.
notes: should verify Agent Mail project keys and topology roles.

W0-F10.
item_id: `W0-F10`.
source_lane: reconciliation foundation and infra recovery hygiene.
classification: FOUNDATION.
bead: `flywheel-7ris`.
action: ship recovery-system B01 recovery skill contract and helper surface.
effort_estimate: 60m.
blocks-which-wave-1-bead: all five Wave-1 beads because recovery procedures must be executable by workers.
evidence: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:965` and `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1088`.
notes: should include a concrete helper invocation in L112.

W0-F11.
item_id: `W0-F11`.
source_lane: reconciliation foundation and infra dispatch freshness.
classification: FOUNDATION.
bead: `flywheel-olhg`.
action: implement schema v2 canonical dispatch wrapper.
effort_estimate: 75m.
blocks-which-wave-1-bead: all five Wave-1 beads because every worker packet must carry reservations, Socraticode, L52/L53, and callback fields.
evidence: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:967` and `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1091`.
notes: absorbs dispatch stale reaper contract and secret-output lint pressure.

W0-F12.
item_id: `W0-F12`.
source_lane: reconciliation foundation and infra topology hygiene.
classification: FOUNDATION.
bead: `flywheel-se3h.2`.
action: harden session-topology register-session writer contract.
effort_estimate: 60m.
blocks-which-wave-1-bead: all five Wave-1 beads because callbacks and file reservations must route through correct pane identities.
evidence: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:977` and `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1092`.
notes: should directly reduce Agent Mail role/key mismatch risk.

### Quick-Fix Packages

W0-QF01.
item_id: `W0-QF01`.
source_lane: infra quick-fix.
classification: QUICK-FIX.
action: add doctor field for active marker with project label not loaded.
effort_estimate: 30m.
blocks-which-wave-1-bead: all five Wave-1 beads through loop-driver truth.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:672-675`.

W0-QF02.
item_id: `W0-QF02`.
source_lane: infra quick-fix.
classification: QUICK-FIX.
action: add doctor field for inactive marker with `last_tick > stopped_at`.
effort_estimate: 30m.
blocks-which-wave-1-bead: all five Wave-1 beads through marker honesty.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:676-678`.

W0-QF03.
item_id: `W0-QF03`.
source_lane: infra quick-fix.
classification: QUICK-FIX.
action: normalize dispatch expected-by into absolute timestamp at append time.
effort_estimate: 30m.
blocks-which-wave-1-bead: all five Wave-1 beads through callback freshness.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:679-680`.

W0-QF04.
item_id: `W0-QF04`.
source_lane: infra quick-fix.
classification: QUICK-FIX.
action: add stale dispatch read-only report grouped by task, event, age, and callback match.
effort_estimate: 30m.
blocks-which-wave-1-bead: all five Wave-1 beads through dispatch capacity truth.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:682-683`.

W0-QF05.
item_id: `W0-QF05`.
source_lane: infra quick-fix.
classification: QUICK-FIX.
action: add `work_started` validation requiring prompt-visible or pane-evidence proof.
effort_estimate: 30m report-only, 60m enforcement.
blocks-which-wave-1-bead: all five Wave-1 beads through dispatch delivery proof.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:685-686`.

W0-QF06.
item_id: `W0-QF06`.
source_lane: infra quick-fix.
classification: QUICK-FIX.
action: correct Agent Mail role labels for flywheel pane 2 and ALPS pane 3 through resolver.
effort_estimate: 30m if token auth is clean.
blocks-which-wave-1-bead: all five Wave-1 beads through identity-stable reservations.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:688-689`.

W0-QF07.
item_id: `W0-QF07`.
source_lane: infra quick-fix.
classification: QUICK-FIX.
action: add health view split for agent panes versus user panes.
effort_estimate: 30m.
blocks-which-wave-1-bead: all five Wave-1 beads through capacity accounting.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:691-692`.

W0-QF08.
item_id: `W0-QF08`.
source_lane: infra quick-fix.
classification: QUICK-FIX.
action: add `/tmp/dispatch_*.md` age report and archive candidate list.
effort_estimate: 30m.
blocks-which-wave-1-bead: all five Wave-1 beads by reducing stale packet reuse.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:694-695`.

W0-QF09.
item_id: `W0-QF09`.
source_lane: infra quick-fix.
classification: QUICK-FIX.
action: add INCIDENTS evidence-link validator for changed files.
effort_estimate: 30m.
blocks-which-wave-1-bead: none hard; protects doctrine promotion quality before Wave-1.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:697-698`.

W0-QF10.
item_id: `W0-QF10`.
source_lane: infra quick-fix.
classification: QUICK-FIX.
action: update dispatch L112 generator to avoid negative grep matching "No dependency cycles detected".
effort_estimate: 30m.
blocks-which-wave-1-bead: all five Wave-1 beads through reliable acceptance checks.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:700-701`.

W0-QF11.
item_id: `W0-QF11`.
source_lane: infra quick-fix.
classification: QUICK-FIX.
action: add `.beads` backup artifact ignore and retention policy draft.
effort_estimate: 30m.
blocks-which-wave-1-bead: all five Wave-1 beads through Beads substrate cleanliness.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:703-704`.

W0-QF12.
item_id: `W0-QF12`.
source_lane: infra quick-fix.
classification: QUICK-FIX.
action: create `bv` baseline plan after dirty-tree checkpoint.
effort_estimate: 30m after checkpoint.
blocks-which-wave-1-bead: all five Wave-1 beads through priority baseline stability.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:706-707`.

### Close Packages

W0-C01.
item_id: `W0-C01`.
source_lane: reconciliation duplicate register.
classification: CLOSE-AS-SUPERSEDED, DEPENDENT-AUDIT-FIRST.
bead: `flywheel-2te`.
action: do not close directly; audit and classify active dependents first, then close last in the old fleet-coherence cascade if every dependent is closed or reclassified.
effort_estimate: 10m.
blocks-which-wave-1-bead: `flywheel-181e5` and `flywheel-3ctlx`; do not close before their frozen fields preserve older obligations.
evidence: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:945`, `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:950`, and `.flywheel/PLANS/WAVE-0-CLOSE-APPLY-LOG-2026-05-05.md:128-146`.

W0-C02.
item_id: `W0-C02`.
source_lane: reconciliation duplicate register.
classification: CLOSE-AS-SUPERSEDED, DEPENDENT-AUDIT-FIRST.
bead: `flywheel-pd9`.
action: do not close directly; classify dependent `flywheel-1hn` and its child first, then retry only if the cascade is safe.
effort_estimate: 10m.
blocks-which-wave-1-bead: none hard; protects Wave-2 fleet selector clarity.
evidence: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:946`, `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:950`, and `.flywheel/PLANS/WAVE-0-CLOSE-APPLY-LOG-2026-05-05.md:81-95`.

W0-C03.
item_id: `W0-C03`.
source_lane: reconciliation duplicate register.
classification: CLOSE-AS-SUPERSEDED, DEPENDENT-AUDIT-FIRST.
bead: `flywheel-1km`.
action: do not close directly; classify dependent `flywheel-dzj` and `flywheel-pd9` first, then retry only if those leaves are closed or reclassified.
effort_estimate: 10m.
blocks-which-wave-1-bead: `flywheel-181e5` and `flywheel-3ctlx`; closure follows field-freeze acceptance text.
evidence: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:947`, `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:950`, and `.flywheel/PLANS/WAVE-0-CLOSE-APPLY-LOG-2026-05-05.md:112-126`.

W0-C04.
item_id: `W0-C04`.
source_lane: reconciliation duplicate register.
classification: CLOSE-AS-SUPERSEDED, DEPENDENT-AUDIT-FIRST.
bead: `flywheel-dzj`.
action: do not close directly; classify active dependents `flywheel-247` and `flywheel-3eo` before retrying.
effort_estimate: 10m.
blocks-which-wave-1-bead: none hard; protects Wave-2 mission/fleet scanner clarity.
evidence: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:948`, `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:950`, and `.flywheel/PLANS/WAVE-0-CLOSE-APPLY-LOG-2026-05-05.md:96-110`.

W0-C05.
item_id: `W0-C05`.
source_lane: reconciliation obsolete register.
classification: CLOSE-AS-OBSOLETE, DEPENDENT-AUDIT-FIRST.
bead: `flywheel-1hn`.
action: do not close directly; classify active dependent `flywheel-hww` before retrying obsolete closure.
effort_estimate: 10m.
blocks-which-wave-1-bead: none hard; protects dashboard clarity.
evidence: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1058-1063` and `.flywheel/PLANS/WAVE-0-CLOSE-APPLY-LOG-2026-05-05.md:66-80`.

W0-C06.
item_id: `W0-C06`.
source_lane: reconciliation obsolete register.
classification: CLOSE-AS-OBSOLETE, DEPENDENT-AUDIT-FIRST.
bead: `flywheel-2y4`.
action: do not close directly; classify active dependent `flywheel-1fh` before retrying obsolete closure.
effort_estimate: 10m.
blocks-which-wave-1-bead: none hard; protects tick-contract clarity.
evidence: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1060-1063` and `.flywheel/PLANS/WAVE-0-CLOSE-APPLY-LOG-2026-05-05.md:148-161`.

### Substrate Hygiene Instance Packages

W0-H01.
item_id: `W0-H01`.
source_lane: infra substrate hygiene.
classification: FILE-CHECKPOINT.
instance_count: 47 dirty tracked files.
action: produce commit, ignore, archive, or defer disposition per dirty group before broad Wave-1 edits.
effort_estimate: 90m.
blocks-which-wave-1-bead: all five Wave-1 beads because mixed dirty trees make worker attribution unsafe.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:649-653` and `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:1142-1145`.

W0-H02.
item_id: `W0-H02`.
source_lane: infra substrate hygiene.
classification: DISPATCH-ABANDON-DISPOSITION.
instance_count: 86 unresolved dispatches older than 24h.
action: classify each stale dispatch as callback-received-elsewhere, abandoned, superseded, needs-redispatch, or needs-handoff.
effort_estimate: 75m with read-only report first and apply queue second.
blocks-which-wave-1-bead: all five Wave-1 beads because capacity truth depends on stale dispatch drain.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:123-132` and `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:1135-1144`.

W0-H03.
item_id: `W0-H03`.
source_lane: infra substrate hygiene.
classification: LOOP-MARKER-REPAIR.
instance_count: 5 stale loop markers.
action: repair, stop, or honestly reclassify stale loop markers so `active=true` never means marker-only.
effort_estimate: 45m.
blocks-which-wave-1-bead: all five Wave-1 beads because loop-driver truth controls dispatch cadence.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:47-59` and `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:1137-1143`.

### Doctrine Promotion Packages

W0-D01.
item_id: `W0-D01`.
source_lane: infra doctrine candidate.
classification: DOCTRINE-PROMOTION.
candidate: `fleet-propagation-failed`.
action: promote or explicitly no-promote after evidence-link check.
effort_estimate: 10m.
blocks-which-wave-1-bead: `flywheel-181e5`, `flywheel-3ctlx`.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:749-753`.

W0-D02.
item_id: `W0-D02`.
source_lane: infra doctrine candidate.
classification: DOCTRINE-PROMOTION.
candidate: `dispatch_callback_overdue`.
action: promote or route to dispatch-log doctor rule.
effort_estimate: 10m.
blocks-which-wave-1-bead: all five Wave-1 beads.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:754-758`.

W0-D03.
item_id: `W0-D03`.
source_lane: infra doctrine candidate.
classification: DOCTRINE-PROMOTION.
candidate: `owner-custody-missing`.
action: promote recovery dispatch rule or explicit no-promote.
effort_estimate: 10m.
blocks-which-wave-1-bead: all five Wave-1 beads through recovery autonomy.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:759-763`.

W0-D04.
item_id: `W0-D04`.
source_lane: infra doctrine candidate.
classification: DOCTRINE-PROMOTION.
candidate: `tick-driver-primitive-failed`.
action: promote loop-driver pause rule or explicit no-promote.
effort_estimate: 10m.
blocks-which-wave-1-bead: all five Wave-1 beads through loop truth.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:764-768`.

W0-D05.
item_id: `W0-D05`.
source_lane: infra doctrine candidate.
classification: DOCTRINE-PROMOTION.
candidate: `storage-headroom-prune-exhausted`.
action: promote storage-health incident or explicit no-promote.
effort_estimate: 10m.
blocks-which-wave-1-bead: none hard; prevents host mutation during low-headroom state.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:769-773`.

W0-D06.
item_id: `W0-D06`.
source_lane: infra doctrine candidate.
classification: DOCTRINE-PROMOTION.
candidate: `skillos-loop-integrity-still-limping`.
action: promote skillos loop-health distinction or explicit no-promote.
effort_estimate: 10m.
blocks-which-wave-1-bead: none hard; protects skill substrate reliability.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:774-778`.

W0-D07.
item_id: `W0-D07`.
source_lane: infra doctrine candidate.
classification: DOCTRINE-PROMOTION.
candidate: `br-sync-stale-db-export-blocked`.
action: promote Beads stale export recovery queue rule or explicit no-promote.
effort_estimate: 10m.
blocks-which-wave-1-bead: all five Wave-1 beads through Beads DB safety.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:779-783`.

W0-D08.
item_id: `W0-D08`.
source_lane: infra doctrine candidate.
classification: DOCTRINE-PROMOTION.
candidate: `parent-bead-dispatched-with-open-children`.
action: promote idle dispatcher refusal rule or explicit no-promote.
effort_estimate: 10m.
blocks-which-wave-1-bead: all five Wave-1 beads through dispatch correctness.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:784-788`.

W0-D09.
item_id: `W0-D09`.
source_lane: infra doctrine candidate.
classification: DOCTRINE-PROMOTION.
candidate: `agent-mail-reservation-token-path-gap`.
action: promote identity primary key resolution rule or explicit no-promote.
effort_estimate: 10m.
blocks-which-wave-1-bead: all five Wave-1 beads through file reservation safety.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:789-793`.

W0-D10.
item_id: `W0-D10`.
source_lane: infra doctrine candidate.
classification: DOCTRINE-PROMOTION.
candidate: `agentmail-beads-db-reservation-conflict`.
action: promote reservation queue rule for Beads mutation or explicit no-promote.
effort_estimate: 10m.
blocks-which-wave-1-bead: all five Wave-1 beads through serialized Beads mutation.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:794-798`.

W0-D11.
item_id: `W0-D11`.
source_lane: infra doctrine candidate.
classification: DOCTRINE-PROMOTION.
candidate: `jeff-dedupe-bead-stale-scope`.
action: promote scope-refresh-before-host-mutation rule or explicit no-promote.
effort_estimate: 10m.
blocks-which-wave-1-bead: none hard; protects future dedupe work.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:799-803`.

<!-- AGENT-ANCHOR: section-1 -->
W0-D12.
item_id: `W0-D12`.
source_lane: infra doctrine candidate.
classification: DOCTRINE-PROMOTION.
candidate: `pane-respawn`.
action: promote respawn receipt rule tying topology and Agent Mail identity repair.
effort_estimate: 10m.
blocks-which-wave-1-bead: all five Wave-1 beads through stable pane recovery.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:804-808`.

W0-D13.
item_id: `W0-D13`.
source_lane: infra doctrine candidate.
classification: DOCTRINE-PROMOTION.
candidate: `parent-redispatched-before-open-child-complete`.
action: promote child-closure and supersession check before redispatch.
effort_estimate: 10m.
blocks-which-wave-1-bead: all five Wave-1 beads through dispatch correctness.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:809-813`.

W0-D14.
item_id: `W0-D14`.
source_lane: infra doctrine candidate.
classification: DOCTRINE-PROMOTION.
candidate: `worker-evidence-file-write-before-reservation`.
action: promote evidence-file reservation or read-only scratch exemption rule.
effort_estimate: 10m.
blocks-which-wave-1-bead: all five Wave-1 beads through L51 discipline.
evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:814-820`.

## Sub-Wave Plan

### wave-0a Parallelizable Foundation Bead Writes

0A-01. Purpose: ship the 12 foundation beads or produce explicit deferrals with owner, verification probe, and tick-status consequence.

0A-02. Beads in scope: `flywheel-2eow`, `flywheel-y6a1`, `flywheel-4m2a`, `flywheel-333j`, `flywheel-2ypj`, `flywheel-12ip`, `flywheel-3mmp`, `flywheel-2ui1`, `flywheel-uufu`, `flywheel-7ris`, `flywheel-olhg`, `flywheel-se3h.2`.

0A-03. Evidence for list: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1077-1094`.

0A-04. Parallel lane A: wire-or-explain core.

0A-05. Lane A beads: `flywheel-4m2a`, `flywheel-333j`, `flywheel-12ip`, `flywheel-y6a1`, `flywheel-2eow`, `flywheel-2ypj`.

0A-06. Lane A sequence: ledger, classifier, detector, ranker, doctor fields, close gate.

0A-07. Lane A reason: reconciliation describes the B1-B6 chain as ledger, classify, detect, rank, expose, gate.

0A-08. Lane A citation: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1071-1075`.

0A-09. Parallel lane B: recovery and session topology.

0A-10. Lane B beads: `flywheel-3mmp`, `flywheel-7ris`, `flywheel-uufu`, `flywheel-2ui1`, `flywheel-se3h.2`.

0A-11. Lane B sequence: receipt schema, recovery skill contract, preinstall audit/session map, session path repair, register-session writer hardening.

0A-12. Lane B reason: stuck-pane recovery and callbacks must not depend on Joshua.

0A-13. Lane B citation: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1087-1094`.

0A-14. Parallel lane C: dispatch wrapper.

0A-15. Lane C bead: `flywheel-olhg`.

0A-16. Lane C reason: all Wave-1 packets require file reservations, Socraticode, callback fields, evidence rules, and secret-output lint.

0A-17. Lane C citation: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1091` and `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:661-665`.

0A-18. Beads DB discipline: implementation workers can edit files, but Beads state updates are integrated by the orchestrator lane only.

0A-19. Wave-1 control citation: `.flywheel/PLANS/UNIFIED-DAG-2026-05-05.md:607-619`.

0A-20. Exit gate: every foundation bead has one of shipped, explicitly deferred with L110 fields, or blocked with recovery ledger and no Joshua-shaped ask.

### wave-0b Sequential Close Ops

0B-01. Purpose: reduce duplicate and obsolete top-100 bead noise without losing acceptance obligations.

0B-02. Scope: 4 close-as-superseded candidates and 2 close-as-obsolete candidates.

0B-03. Close candidates: `flywheel-2te`, `flywheel-pd9`, `flywheel-1km`, `flywheel-dzj`, `flywheel-1hn`, `flywheel-2y4`.

0B-03a. Late correction: these are no longer direct close candidates. Close apply attempted all six and skipped all six because active dependents were present.

0B-03b. Late correction citation: `.flywheel/PLANS/WAVE-0-CLOSE-APPLY-LOG-2026-05-05.md:11-20` and `.flywheel/PLANS/WAVE-0-CLOSE-APPLY-LOG-2026-05-05.md:53-62`.

0B-04. Evidence for duplicate close list: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:941-950`.

0B-05. Evidence for obsolete close list: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1058-1063`.

0B-06. Sequencing rule: close duplicates only after superseding today bead has enough acceptance text to preserve the older test obligation.

0B-07. Sequencing rule citation: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:950`.

0B-08. Obsolete rule: perform quick owner check because top-100 PageRank can mean old dependents still cite the bead.

0B-09. Obsolete rule citation: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1060-1063`.

0B-10. Beads mutation: one apply packet, one writer, sequential dependent-cascade classification first; `br close` may run only after the skip-list is empty or intentionally reclassified.

0B-11. Plan-space guard: this document does not close anything.

0B-12. Exit gate: close receipt lists old bead, dependent audit result, superseding bead, preserved acceptance text, and `br doctor`/`br dep cycles` after mutation.

0B-13. Current close-lane verdict: HOLD for dependent audit, not GO for direct closure.

0B-14. Current close-lane citation: `.flywheel/PLANS/WAVE-0-CLOSE-APPLY-LOG-2026-05-05.md:207-234`.

### wave-0c Substrate Hygiene

0C-01. Purpose: remove coordination false positives before adding Wave-1 load.

0C-02. Hygiene scope: 12 quick fixes, 47 dirty-file dispositions, 86 stale-dispatch dispositions, 5 stale-loop-marker repairs.

0C-03. Evidence for counts: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:1133-1146`.

0C-04. Loop-driver hygiene first: active markers without project labels and inactive markers with fresh ticks create false driver proof.

0C-05. Loop-driver evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:47-59` and `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:73-80`.

0C-06. Dispatch hygiene second: 86 unresolved >24h dispatches need disposition.

0C-07. Dispatch evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:123-132`.

0C-08. Beads substrate hygiene third: broad Beads work should wait on `br dep cycles --json` stability and known failed integrity exclusions.

0C-09. Beads evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:637-641`.

0C-10. Agent Mail hygiene fourth: role and project-key mismatches undermine reservations.

0C-11. Agent Mail evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:643-647`.

0C-12. Dirty-tree hygiene fifth: the 47 tracked dirty files need a disposition plan before broad worker edits.

0C-13. Dirty-tree evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:649-653`.

0C-14. Dispatch-spool hygiene sixth: stale `/tmp` dispatch packets create replay risk.

0C-15. Dispatch-spool evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:655-659`.

0C-16. Secret-output lint seventh: dispatch templates must refuse credential-shaped stdout capture patterns.

0C-17. Secret-output evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:661-665`.

0C-18. Exit gate: all hygiene packages produce read-only report first, then apply receipt or explicit no-apply reason.

### wave-0d Doctrine Promotions

0D-01. Purpose: route recurring substrate failures into doctrine before Wave-1 repeats them.

0D-02. Scope: 14 doctrine candidates from infra scan.

0D-03. Evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:747-820`.

0D-04. Promotion order: dispatch callback overdue, tick-driver primitive failed, agent-mail reservation token path gap, agentmail-beads-db reservation conflict, worker evidence file write before reservation.

0D-05. Reason: those five directly guard Wave-1 callbacks, reservations, and Beads mutation.

0D-06. Second order: fleet propagation failed, owner custody missing, parent bead dispatched with open children, parent redispatched before open child complete, pane respawn.

0D-07. Reason: those five guard autonomous worker routing and fleet work.

0D-08. Third order: br-sync stale DB export blocked, storage headroom prune exhausted, skillos loop integrity still limping, jeff dedupe bead stale scope.

0D-09. Reason: those four are important but lower direct Wave-1 blast radius.

0D-10. Evidence-link rule: every promotion must cite row evidence, existing INCIDENTS entry, bead ID, or commit hash. No freestanding doctrine prose.

0D-11. Quick validator citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:697-698`.

0D-12. Exit gate: all 14 classes have `processed_into` or explicit no-promotion reason.

0D-13. Exit gate citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:631-635`.

## Dispatch Packet Drafts For Foundation Beads

DP-00. Common packet requirements for every foundation bead:

DP-00.1. Dispatch mode: implementation dispatch, not this plan-space worker.

DP-00.2. Required preflight: read bead body, run at least 3 Socraticode K10 searches, reserve exact files, report indexed chunks observed.

DP-00.3. Required callback: `bead_id`, `files_reserved`, `files_released`, `socraticode_queries`, `indexed_chunks_observed`, `l112_observed`, `bead_ids_updated` or `no_bead_reason`, `fuckups_logged` if trauma appears.

DP-00.4. Required Beads discipline: worker may not mutate Beads DB unless the orchestrator grants that lane in the packet.

DP-00.5. Required source citation: Wave-1 control ledger demands reservations, Socraticode, callback fields, and Beads DB discipline.
Citation: `.flywheel/PLANS/UNIFIED-DAG-2026-05-05.md:603-626`.

DP-F01.
foundation_bead: `flywheel-2eow`.
unblocks_today_bead: all Wave-1 candidates.
dispatch_shape: "Implement wire-or-explain doctor fields. Reserve doctor/status surfaces only. Acceptance: doctor reports wired/unwired/deferred fields and fails on missing L110 deferral fields."
source: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:956` and `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1085`.

DP-F02.
foundation_bead: `flywheel-y6a1`.
unblocks_today_bead: all Wave-1 candidates.
dispatch_shape: "Implement wire-priority ranker over unresolved wire-or-explain rows. Reserve ranker and test fixture files only. Acceptance: deterministic ordering exists for unresolved shipped artifacts."
source: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:957` and `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1084`.

DP-F03.
foundation_bead: `flywheel-4m2a`.
unblocks_today_bead: all Wave-1 candidates.
dispatch_shape: "Implement ledger schema and append-only writer. Reserve ledger schema, writer, and tests. Acceptance: append path is idempotent where required and never rewrites historical rows."
source: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:958` and `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1081`.

DP-F04.
foundation_bead: `flywheel-333j`.
unblocks_today_bead: all Wave-1 candidates.
dispatch_shape: "Implement ship-event classifier. Reserve classifier and fixture files only. Acceptance: artifacts can be classified as shipped, planned, deferred, duplicate, obsolete, or orthogonal without string-only title matching."
source: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:959` and `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1082`.

DP-F05.
foundation_bead: `flywheel-2ypj`.
unblocks_today_bead: all Wave-1 candidates.
dispatch_shape: "Implement tick-close gate. Reserve closeout gate and receipt validation files. Acceptance: tick cannot close with unwired shipped artifacts unless explicit owner/probe/consequence deferral exists."
source: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:960` and `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1086`.

DP-F06.
foundation_bead: `flywheel-12ip`.
unblocks_today_bead: all Wave-1 candidates.
dispatch_shape: "Implement wired detector. Reserve detector and tests. Acceptance: detector reads ledger plus artifact evidence and returns wired/unwired/deferred with reason."
source: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:961` and `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1083`.

DP-F07.
foundation_bead: `flywheel-3mmp`.
unblocks_today_bead: all Wave-1 candidates.
dispatch_shape: "Define tick receipt schema registry and graduation. Reserve schema registry and validation tests. Acceptance: loop-driver writeback, prompt dispatch, worker DONE, and no-work receipts are distinct typed rows."
source: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:962` and `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:61-70`.

DP-F08.
foundation_bead: `flywheel-2ui1`.
unblocks_today_bead: all Wave-1 candidates.
dispatch_shape: "Repair session paths for recovery-system B03. Reserve session path repair and tests. Acceptance: recovery command locates canonical session, pane, and project key without human path guessing."
source: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:963` and `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1090`.

DP-F09.
foundation_bead: `flywheel-uufu`.
unblocks_today_bead: all Wave-1 candidates.
dispatch_shape: "Ship preinstall audit and session path map. Reserve audit/map files. Acceptance: active sessions have explicit path, role, pane, Agent Mail identity, and driver labels."
source: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:964` and `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:643-647`.

DP-F10.
foundation_bead: `flywheel-7ris`.
unblocks_today_bead: all Wave-1 candidates.
dispatch_shape: "Implement recovery skill contract and helper surface. Reserve helper and skill references. Acceptance: recovery path has command surface, dry-run mode, and L112 verification."
source: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:965` and `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1088`.

DP-F11.
foundation_bead: `flywheel-olhg`.
unblocks_today_bead: all Wave-1 candidates.
dispatch_shape: "Implement schema v2 canonical dispatch wrapper. Reserve dispatch wrapper, templates, and tests. Acceptance: generated packet contains L50/L51/L52/L53 fields, secret-output lint, and absolute callback deadline."
source: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:967`, `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:625-629`, and `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:661-665`.

DP-F12.
foundation_bead: `flywheel-se3h.2`.
unblocks_today_bead: all Wave-1 candidates.
dispatch_shape: "Harden register-session writer contract. Reserve topology writer and tests. Acceptance: session registration rejects duplicate role ambiguity and records stable identity/project key for callbacks."
source: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:977` and `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:643-647`.

## Risk Register

R-01. Risk: Wave-0 expands into a forever holding pattern.
Severity: high.
Likelihood: medium.
Mitigation: exit gate permits shipped or explicitly deferred foundation items only; do not add orthogonal top-100 beads to Wave-0.
Citation: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1077-1094`.

R-02. Risk: Beads DB writes collide while multiple lanes implement foundations.
Severity: high.
Likelihood: medium.
Mitigation: implementation workers edit files only; orchestrator serializes Beads updates.
Citation: `.flywheel/PLANS/UNIFIED-DAG-2026-05-05.md:607-619`.

R-03. Risk: stale dispatch cleanup abandons still-running worker output.
Severity: medium.
Likelihood: medium.
Mitigation: first produce read-only stale report; apply disposition only after callback matching and pane evidence check.
Citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:123-132`.

R-04. Risk: loop-marker repair mistakes generic writeback for prompt delivery.
Severity: high.
Likelihood: high.
Mitigation: require prompt file and pane evidence before `VERIFIED` status.
Citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:61-70`.

R-05. Risk: duplicate closures erase old acceptance obligations.
Severity: medium.
Likelihood: high.
Mitigation: close only after superseding today bead has enough acceptance text and the active dependent cascade is audited.
Citation: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:941-950` and `.flywheel/PLANS/WAVE-0-CLOSE-APPLY-LOG-2026-05-05.md:163-172`.

R-06. Risk: obsolete closures miss high-PageRank old dependents.
Severity: medium.
Likelihood: high.
Mitigation: owner-check and dependent-cascade classification before closure; migrate any still-useful acceptance text.
Citation: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1058-1063` and `.flywheel/PLANS/WAVE-0-CLOSE-APPLY-LOG-2026-05-05.md:214-222`.

R-07. Risk: doctrine promotions become ungrounded prose.
Severity: medium.
Likelihood: medium.
Mitigation: require evidence-link validator and `processed_into` or no-promotion reason for all 14 classes.
Citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:631-635` and `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:697-698`.

R-08. Risk: dirty-tree checkpoint mixes current user work with worker changes.
Severity: high.
Likelihood: medium.
Mitigation: disposition only; do not commit or revert without explicit apply dispatch and file reservations.
Citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:649-653`.

R-09. Risk: Agent Mail identity cleanup hits token/path ambiguity.
Severity: medium.
Likelihood: medium.
Mitigation: resolve by identity primary key and project key, not mailbox display name.
Citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:789-793`.

R-10. Risk: secret-output lint is skipped because it is "just template work."
Severity: high.
Likelihood: low.
Mitigation: make it an acceptance gate on `flywheel-olhg`.
Citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:661-665`.

R-11. Risk: Wave-1 starts after partial Wave-0 with silent deferrals.
Severity: high.
Likelihood: medium.
Mitigation: no silent deferrals; each deferral needs owner, verification probe, and tick/status consequence.
Citation: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1094`.

R-12. Risk: mission-coverage beads are accidentally pulled into Wave-1 because this plan focuses on foundations.
Severity: medium.
Likelihood: low.
Mitigation: preserve existing Wave-1 set; mission candidates wait until polish status is explicit.
Citation: `.flywheel/PLANS/UNIFIED-DAG-2026-05-05.md:246-256` and `.flywheel/PLANS/UNIFIED-DAG-2026-05-05.md:626`.

## wave.1.readiness Verdict

WR-01. Current portfolio readiness: NO-GO.

WR-02. Reason: reconciliation states Wave 1 is only plan-local GO and should be treated as `needs_foundations_first`.
Citation: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:7-15`.

WR-03. Local UNIFIED-DAG readiness remains internally GO for the five contract-freeze beads.
Citation: `.flywheel/PLANS/UNIFIED-DAG-2026-05-05.md:246-261`.

WR-04. Unified verdict: portfolio Wave-1 becomes GO only after Wave-0 exits.

WR-05. Wave-0 exit condition 1: 12 foundation beads are shipped or explicitly deferred with owner, verification probe, and tick/status consequence.
Citation: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md:1094`.

WR-06. Wave-0 exit condition 2: 86 stale dispatches have disposition or explicit reason to remain open.
Citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:123-132`.

WR-07. Wave-0 exit condition 3: 5 stale loop markers are repaired, stopped, or honestly classified.
Citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:47-59` and `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:1137-1143`.

WR-08. Wave-0 exit condition 4: 47 dirty tracked files have commit, ignore, archive, or defer disposition.
Citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:649-653` and `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:1142-1145`.

WR-09. Wave-0 exit condition 5: all 14 doctrine candidates have `processed_into` or explicit no-promotion reason.
Citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:631-635` and `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:747-820`.

WR-10. Wave-0 exit condition 6: Beads DB health is stable before broad Beads work.
Citation: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md:637-641` and `.flywheel/PLANS/UNIFIED-DAG-2026-05-05.md:607-619`.

WR-11. After all six exit conditions: wave_1_readiness_after_wave_0=GO.

WR-12. If any foundation item is deferred without L110 fields: wave_1_readiness_after_wave_0=NO-GO.

WR-13. If only hygiene items remain but each has explicit owner and non-blocking reason: wave_1_readiness_after_wave_0=CONDITIONAL.

WR-14. Wave-1 candidate set after Wave-0 remains unchanged: `flywheel-njf5c`, `flywheel-2dywy`, `flywheel-3g75v`, `flywheel-181e5`, `flywheel-3ctlx`.
Citation: `.flywheel/PLANS/UNIFIED-DAG-2026-05-05.md:603-626`.

## Total Estimated Time-To-Wave-1

TT-01. Planning and dispatch prep: 30m.

TT-02. Wave-0a foundation implementation: 5.0h wall if split into 3 lanes with serialized integration.

TT-03. Wave-0b dependent audit for close-as-superseded and close-as-obsolete candidates: 1.5h before any retry close apply.

TT-04. Wave-0c substrate hygiene: 2.0h wall if report generation and apply queues run parallel to foundation implementation.

TT-05. Wave-0d doctrine promotions: 1.5h wall, mostly parallel with hygiene but serialized for canonical file edits.

TT-06. Final Wave-1 readiness validation: 30m.

TT-07. Total wall estimate: 8.75h.

TT-08. Total serial effort estimate: 18.25h.

TT-09. Primary reason wall time is lower than serial effort: Wave-0a code edits, Wave-0c reports, and Wave-0d evidence-link review can run in parallel, while Beads DB mutation is serialized.

TT-10. Do not start Wave-1 until Wave-0 closeout receipt reports `wave_1_readiness_after_wave_0=GO` or a human explicitly accepts CONDITIONAL.

## Closeout Metrics

CM-01. wave_0_total_items=182.

CM-02. logical_work_packages=47.

CM-03. deduplication_overlap_count=8.

CM-04. foundation_count=12.

CM-05. quick_fix_count=12.

CM-06. close_count=6.

CM-07. doctrine_promotions_count=14.

CM-08. file_commit_count=47.

CM-09. dispatch_abandon_count=86.

CM-10. loop_marker_repair_count=5.

CM-11. sub_wave_count=4.

CM-12. wave_1_readiness_after_wave_0=GO, assuming all Wave-0 exit gates pass.

CM-13. estimated_total_effort_hours=8.75 wall, 18.25 serial.

CM-14. bead_db_writes=0 for this plan artifact.

CM-15. l112_expected=OK_unified_wave_0_plan.

CM-16. close_lane_current_verdict=HOLD_FOR_DEPENDENT_AUDIT.

CM-17. close_apply_observed_beads_closed=0.
