## L56 — FUCKUP-LOG → INCIDENTS → CANONICAL-L-RULE PROMOTION LADDER

---
id: L56
title: Fuckup-log → INCIDENTS → canonical-L-rule promotion ladder
status: long_term
shipped: 2026-04-30
review_due: 2026-10-30
trauma_class: doctrine-orphaning
---

**Rule:** Doctrine accretion follows a 3-layer ladder, each layer referencing the layer below for evidence:

1. **Layer 1 — fuckup-log (event substrate):** every observed trauma/gap/failure logs a row to `~/.local/state/flywheel/fuckup-log.jsonl` (manual via `flywheel-loop fuckup log` OR auto via `fuckup harvest`).
2. **Layer 2 — INCIDENTS.md (per-component doctrine):** when a trauma class hits frequency threshold (3+ events in 7 days, OR single event with severity=high + cost citation), promote to a per-component INCIDENTS.md entry with Forever-Rule + cost citation + at least ONE fuckup-log row range as evidence.
3. **Layer 3 — canonical L-rule (universal doctrine):** when multiple repos hit the same trauma class OR a single repo's INCIDENTS entry generalizes cleanly cross-repo, promote to a canonical L-rule in `~/Developer/flywheel/AGENTS.md` referencing the source INCIDENTS entries as evidence.

**Why:** Without the ladder, two failure modes recur:

- **Doctrine orphaning:** INCIDENTS.md entries appear with no fuckup-log evidence (un-grounded Forever-Rules that may not reflect real frequency); canonical rules appear with no INCIDENTS entries (premature universalization on N=1 anecdotes).
- **Substrate amnesia:** fuckup-log fills with rows that never get promoted; the same trauma class hits the next agent next week.

**Cost citation:** Tonight (2026-04-30), I logged a `doctrine-accretion` row in fuckup-log for the L51-L55 commit (`0482431`). That was wrong substrate placement — doctrine accretion is a permanent positive event, not a fuckup. Without L56 + a clear ladder, future agents will keep mis-routing signal between layers. L56 mechanizes the routing.

**Mechanism — evidence linkage requirements:**

Every layer-2 INCIDENTS.md entry MUST cite at least one of:

- Specific fuckup-log row range: `~/.local/state/flywheel/fuckup-log.jsonl#L<N>-L<M>`
- Specific bead ID(s): `bd-XXX`
- Specific commit sha(s): `<sha>`

Every layer-3 canonical L-rule MUST cite at least one of:

- INCIDENTS.md entry path: `<repo>/INCIDENTS.md#<entry>` OR `~/.claude/skills/<skill>/references/INCIDENTS.md#<entry>`
- 3+ fuckup-log rows from the same trauma class

`flywheel-loop doctor --strict` will (Step 6d, future) check evidence linkage across layers and flag orphan entries.

**Mechanism — promotion cadence:**

- **Frequency-based:** doctor's `fuckup_triage` section already surfaces 3-in-7d candidates as warn / 5-in-24h candidates as error (commit `71df912`). L56 makes that triage the explicit ladder decision point.
- **Severity-based:** single high-severity event with cost citation (real $ or hours) MAY promote without 3+ frequency, at human discretion via `/flywheel:learn --promote <class>`.
- **Cross-repo emergence:** when 2+ repos' INCIDENTS files have matching entries, candidate for canonical L-rule (manual review).

**Forbidden orchestrator outputs:**

- Authoring a canonical L-rule without citing an INCIDENTS entry OR 3+ fuckup-log rows
- Authoring an INCIDENTS entry without citing fuckup-log evidence (initial seed entries authored before fuckup-log existed are grandfathered — they may cite git commits or trauma narratives instead)
- Logging doctrine accretions / positive events as fuckup-log rows (those belong in INCIDENTS as historical context OR in a future petal-9 close digest, NOT in fuckup-log which is for traumas)

**Companion rules:** L48 (substrate-exhaustion) is the operational discipline; L52 (issues-to-beads) routes findings to bead substrate; L53 (fuckups-reported) ensures layer 1 captures every event; L54 (skill-deep-dive) consumes layer 2 + 3 as recovery substrate. L56 glues all of these into a coherent learning architecture.

**User surface:** `/flywheel:learn` is the unified command that hides the layer routing from the human (orchestrator handles classification). L56 is the architectural rule the command implements.


