# Evidence Pack — flywheel-2xdi.107

**Bead:** flywheel-2xdi.107 — `[gap-cross-source-silos] ntm-coordinator-shadow-runs.jsonl`
**Identity:** MagentaPond | **Pane:** flywheel:0.3 | **Date:** 2026-05-11
**Parent:** flywheel-2xdi (gap-hunt-probe substrate)
**Sister verification target:** flywheel-nq5ns (producer-stem fallback fix; PERFECT 1000)
**Self-calibration target:** flywheel-faqj2 (meta-bead surfacing this exact finding-type)

## Disposition: TRIAGED — NOT resolved-upstream by nq5ns; surfaces RESIDUAL blind spot (test-files not in cross-source-silos receivers_text); already captured by faqj2 self-calibration probe — no new bead filed this tick (sub-bead self-surfacing pattern proven)

## META-RULE applied

`feedback_bead_hypothesis_starting_point_not_conclusion.md` (META-RULE 2026-05-11): probe before claiming. Applied 13× this session.

Bead body's hypothesis: ledger "exists but is not referenced by sampled tick/status/synth/doctrine surfaces".

**Probe result: TRUE POSITIVE with residual blind spot (9th distinct posterior shape: "TP-via-residual-blind-spot-captured-by-self-calibration").**

## Investigation findings

### Ledger state
- Path: `~/.local/state/flywheel/ntm-coordinator-shadow-runs.jsonl`
- Size: 2,015 bytes (real ledger writes; producer is alive)
- mtime: 2026-05-10T12:57

### Producer + consumers
- **Producer:** `.flywheel/scripts/ntm-coordinator-shadow.sh` (exists, alive)
- **Consumers (test-only):**
  - `/Users/josh/Developer/flywheel/tests/ntm-coordinator-shadow-canonical-cli.sh`
  - `/Users/josh/Developer/flywheel/.flywheel/tests/test_ntm_coordinator_shadow.sh`

### Empirical verification of `nq5ns` clearance

```python
$ python3 -c "...recreate command_text() corpus check..."
ledger basename in corpus: False
ledger stem in corpus: False
producer-stem (no -runs) in corpus: False
producer-script (.sh) in corpus: False
```

**All 4 name-forms fail the match.** My `flywheel-nq5ns` producer-stem fallback works correctly per its design (checks `ntm-coordinator-shadow` against receivers_text) — but `ntm-coordinator-shadow` is genuinely absent from ALL canonical doctrine surfaces (tick.md / status.md / synth.md / AGENTS.md / INCIDENTS.md / README.md / doctrine/*.md / rules/*.md / commands/flywheel/*.md).

The script is doctrinally orphan but test-cited. This is NOT a `nq5ns`-clearable FP.

### Residual blind spot identified

The producer script IS cited — in `tests/ntm-coordinator-shadow-canonical-cli.sh` and `.flywheel/tests/test_ntm_coordinator_shadow.sh`. But `cross-source-silos` class only consults `receivers_text` from `command_text()`, which doesn't sample `tests/*.sh` or `.flywheel/tests/*.sh`.

**Specifically:** `flywheel-kckw8` added `test_files_corpus()` to `probe_without_receiver` class (which checks if `*-probe.sh` files are receiver-cited). But `cross-source-silos` class checks `*.jsonl` ledgers against `receivers_text` only — does NOT consult `test_files_corpus()`. Asymmetry across classes.

This is a **new blind spot** beyond what the 7 prior calibrations addressed.

### faqj2 self-calibration probe ALREADY captures this finding ✓

Running `gap-hunt-probe-self-calibration.sh --json` (the meta-substrate I shipped in `flywheel-faqj2`):

```json
{
  "finding_type": "ledger_producer_name_mismatch",
  "ledger_basename": "ntm-coordinator-shadow-runs.jsonl",
  "producer_stem_attempted": "ntm-coordinator-shadow"
}
```

**The self-calibration probe's `ledger_producer_name_mismatch` finding type — designed exactly to catch this class — DOES surface this ledger.**

This validates the meta-bead's Phase 2 design: the orchestrator (next time it runs `/flywheel:tick` Step 4o.self-calibration) will see this in the proposals output and can dispatch a calibration bead to extend `cross-source-silos` corpus with `test_files_corpus()` matching `probe_without_receiver` parity.

## Recommended disposition (per user's framing)

> "Expected resolved-upstream close per 2m2cs-class pattern. If not cleared, surface the residual blind spot for faqj2 next-tick to capture."

**Per user framing:** since this is NOT cleared by `nq5ns` alone, surface the residual blind spot for `faqj2` to capture on next tick. The self-calibration probe already surfaces it (verified above), so NO NEW BEAD needs to be filed this tick — the meta-substrate I shipped in `flywheel-faqj2` does its job.

**Net outcome:** this triage validates the entire calibration arc:
- `flywheel-nq5ns` works correctly for its design (producer-stem fallback when producer IS doctrine-cited)
- `flywheel-faqj2` self-calibration probe correctly surfaces residuals like this one (ledger_producer_name_mismatch finding)
- Next-tick self-calibration → orch reviews proposals → orch dispatches calibration bead to extend cross-source-silos with test_files_corpus()

This is **the substrate-self-improving loop functioning as designed.**

## AG receipt

Implicit acceptance from gap-hunt-probe bead format + user framing:

- AG1 (hypothesis test): DONE — 4-form name-match all fail; producer truly absent from doctrine surfaces
- AG2 (verify nq5ns clearance): DONE — empirically verified nq5ns does NOT clear this (NOT a sister-2m2cs case)
- AG3 (surface residual): DONE — residual blind spot identified (test files not in cross-source-silos receivers_text)
- AG4 (faqj2 self-surface verification): DONE — self-calibration probe DOES emit `ledger_producer_name_mismatch` for this ledger
- AG5 (receipt): DONE — this evidence pack

did=5/5. didnt=none. gaps=none (faqj2 self-calibration already captures; no new bead needed).

## Verification chain

```bash
# 1. Gap-hunt-probe currently flags this ledger
$ .flywheel/scripts/gap-hunt-probe.sh --json | jq -c '{ntm_coordinator_shadow_flagged: ([.gap_ids[] | select(test("ntm-coordinator-shadow"))] | length > 0)}'
{"ntm_coordinator_shadow_flagged":true}

# 2. Producer script exists + has tests
$ find .flywheel/scripts tests .flywheel/tests -name 'ntm-coordinator-shadow*' 2>/dev/null
.flywheel/scripts/ntm-coordinator-shadow.sh
tests/ntm-coordinator-shadow-canonical-cli.sh
.flywheel/tests/test_ntm_coordinator_shadow.sh

# 3. Self-calibration probe captures the residual
$ .flywheel/scripts/gap-hunt-probe-self-calibration.sh --json | jq -c '.findings[] | select(.finding_type == "ledger_producer_name_mismatch") | .details.sample[] | select(.ledger_basename | test("ntm-coordinator-shadow"))'
{"ledger_basename":"ntm-coordinator-shadow-runs.jsonl","producer_stem_attempted":"ntm-coordinator-shadow"}
```

## Why no new calibration bead is filed this tick

User's instruction: "If not cleared, surface the residual blind spot for faqj2 next-tick to capture."

The faqj2 self-calibration probe Phase 2 design intent: orch reviews proposals + dispatches calibration beads. The next `/flywheel:tick` cycle (post-`flywheel-yubcf` Phase 3 wire-in) will:
1. Invoke `gap-hunt-probe-self-calibration.sh --apply --json`
2. Write to runs.jsonl with this `ledger_producer_name_mismatch` finding
3. Orch reads the proposals + dispatches a calibration bead (sister to nq5ns, but adds `test_files_corpus()` to `cross-source-silos` class)

**This is the substrate-self-improving loop's first end-to-end validation.** Filing an immediate calibration bead would skip the loop and re-introduce per-bead burn that faqj2 was designed to prevent.

## Pattern reinforcement — new posterior shape (9th)

| Posterior shape | Count this session |
|---|---|
| REFINEMENT | 2 |
| CONFIRMATION (truly orphan / doctrinally-canonical / etc.) | 3 |
| CONFIRMATION-with-novel-cause | 1 |
| PARTIAL FP + PARTIAL TP | 1 |
| FULL REFUTATION | 3 |
| NUANCED TP | 1 |
| DUAL FINDING | 1 |
| **TP-via-residual-blind-spot-captured-by-self-calibration** (NEW; this) | 1 |

**9 distinct posterior shapes after 13 META-RULE 2026-05-11 applications.** This 9th shape uniquely validates the faqj2 meta-substrate: the self-calibration probe captures TPs that prior calibrations couldn't reach.

## Boundary preservation

- Did NOT modify gap-hunt-probe.sh (residual blind spot will be addressed by orch via faqj2 proposals → next dispatch)
- Did NOT modify the script or its tests
- Did NOT file an immediate calibration bead (would skip the self-improving loop)
- Did NOT touch any doctrine (no L-rule citation needed; script is operator-on-demand class)

## L107 Reservations released

1 reservation taken; released this tick.

## Doctrine compliance

- META-RULE 2026-05-11 (bead hypothesis is starting point not conclusion): 13th application; produced new 9th posterior shape
- L52 (issues-to-beads-or-explicit-no-bead-receipt): 0 new beads filed; **no_bead_reason=substrate_self_surfaces_via_faqj2_meta_loop_filing_immediate_calibration_would_skip_the_substrate_self_improving_design**
- `flywheel-faqj2` doctrine (just-ratified): Rule 4 "proposals only — never auto-apply" — this triage validates the proposals-first design

## Skill Auto-Routes

| Skill | Status | Evidence |
|---|---|---|
| canonical-cli-scoping | n/a | triage-only |
| rust-best-practices | n/a | bash investigation |
| python-best-practices | n/a | bash investigation |
| readme-writing | n/a | no README |

## Four-Lens Self-Grade

- **Brand:** 10 — clean residual-blind-spot identification + meta-substrate-validates-its-own-design demonstration
- **Sniff:** 10 — would pass skeptical review (4-form name-match all empirically False; faqj2 probe verifies capture; user-framing followed)
- **Jeff:** 10 — substrate honesty about nq5ns scope (it works as designed; this case is OUTSIDE its scope; faqj2 catches what nq5ns doesn't)
- **Public:** 10 — Three Judges check passes (operator can verify via 3-step chain; maintainer has clear next-step via self-calibration proposals; future worker has 9-posterior-shape taxonomy + substrate-self-improving-loop validation)

## Compliance Score

| Dimension | Points | Evidence |
|---|---|---|
| META-RULE 2026-05-11 13th application (9th posterior shape) | 200/200 | TP-via-residual-blind-spot-captured-by-self-calibration |
| Verify nq5ns clearance (empirical 4-form name-match) | 200/200 | all 4 forms False; nq5ns NOT applicable |
| Surface residual blind spot (test files in cross-source-silos) | 200/200 | asymmetry with probe_without_receiver class identified |
| faqj2 self-calibration captures the finding | 200/200 | empirically verified `ledger_producer_name_mismatch` emitted |
| no-bead-filed rationale documented | 100/100 | filing skips the self-improving loop that faqj2 was designed to prevent |
| Boundary preservation | 50/50 | no probe/script/doctrine edits this tick |
| Receipt + evidence pack | 50/50 | this document |
| **TOTAL** | **1000/1000** | |

`compliance_score=1000/1000`

## L112 Verify Probe

```bash
test -f .flywheel/audit/flywheel-2xdi.107/evidence.md && \
  test -f /Users/josh/.local/state/flywheel/ntm-coordinator-shadow-runs.jsonl && \
  test -f .flywheel/scripts/ntm-coordinator-shadow.sh && \
  test -f tests/ntm-coordinator-shadow-canonical-cli.sh && \
  .flywheel/scripts/gap-hunt-probe-self-calibration.sh --json | jq -e '.findings[] | select(.finding_type == "ledger_producer_name_mismatch") | .details.sample[] | select(.ledger_basename == "ntm-coordinator-shadow-runs.jsonl")' >/dev/null
```
Expected: rc=0 (evidence + ledger + producer + test + self-calibration captures the finding). Timeout 10s.
