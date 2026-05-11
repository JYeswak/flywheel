# Evidence Pack — flywheel-2xdi.145

**Bead:** flywheel-2xdi.145 — `[gap-wired-but-cold] Developer/flywheel/.flywheel/scripts/codex-deathtrap-launcher.sh`
**Identity:** MagentaPond | **Pane:** flywheel:0.3 | **Date:** 2026-05-11
**Parent:** flywheel-2xdi (gap-hunt-probe substrate)
**Sister case:** flywheel-2xdi.114 (1st MOOT-BY-CURRENT-PROBE-CLEARANCE this session)

## Disposition: MOOT-BY-CURRENT-PROBE-CLEARANCE — bead hypothesis REFUTED; script IS canonically wired (own doctrine doc + sister test + 6+ evidence/receipt cites); current probe does NOT flag

## META-RULE applied (27th)

`feedback_bead_hypothesis_starting_point_not_conclusion.md` — probe before claiming.

Bead body's hypothesis: script not referenced by recent flywheel jsonl ledgers (last 30d).

**Probe result: FULL REFUTATION (2nd MOOT-BY-CURRENT-PROBE-CLEARANCE instance this session).** Current probe state returns empty for this script:

```bash
$ .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids | map(select(test("codex-deathtrap")))'
[]
```

Bead was auto-filed at 2026-05-11T16:54:36Z; mid-session probe calibrations between auto-bead-file and this tick cleared the flag. Same shape as flywheel-2xdi.114 (install-petal9-close.sh).

## Investigation findings

### Script state
- Path: `.flywheel/scripts/codex-deathtrap-launcher.sh` (6547 bytes, May 9)
- Origin: `flywheel-delp` "Required next step 1" — instrument codex worker launch for forensics
- Purpose: tee stderr to evidence dir; emit exit-evidence JSON receipt on codex exit
- Canonical-CLI-scoping triad: doctor / health / info / schema available per header

### Canonical wiring (heavily cited)

| Surface | Citation |
|---|---|
| `.flywheel/doctrine/codex-death-event-flow.md` | **DEDICATED DOCTRINE DOC** — "the producer of evidence" |
| `.flywheel/tests/test-codex-death-event-classifier.sh` | Sister test |
| `.flywheel/evidence/flywheel-delp/{deathtrap-info,deathtrap-doctor,report}.{json,md}` | 3 origin-bead evidence files |
| `.flywheel/evidence/flywheel-nsjse/{report.md,smoke-pipeline-receipt/exit_evidence-*.json}` | 2 sibling evidence files |
| `.flywheel/receipts/flywheel-ukm9f/audit/{evidence.md,compliance-pack.json,launcher-info.json,pinned-shas.txt,pane-state-at-launch.txt,process-tree.txt}` | 6 receipt files |
| `.flywheel/handoffs/handoff-2026-05-01T1356Z-fleet-overnight-death.md` | Handoff cite |

**13+ canonical cites total.** The script is heavily wired. Bead's hypothesis ("not referenced") is empirically wrong.

### 5-corpus probe state (current)

Probe corpus 1 (recent_ledger_text via gap-hunt.jsonl) currently clears it. The probe's wired-but-cold flag DOES NOT currently fire for this script — confirmed via jq filter returning `[]`.

## Disposition decision — REFUTATION (no fix needed)

Per 2xdi.114 precedent (MOOT-BY-CURRENT-PROBE-CLEARANCE sub-class):

| Option | Description | Cost |
|---|---|---|
| A | Substrate-registry allowlist | Unnecessary — probe already cleared |
| B | SKILL.md / doctrine doc cite | Already cited in `.flywheel/doctrine/codex-death-event-flow.md` |
| **C (CHOSEN)** | REFUTATION close — document hypothesis was wrong | No edits; close bead |

The doctrine doc at `.flywheel/doctrine/codex-death-event-flow.md` ALREADY
provides the canonical name cross-link. Probe doesn't currently flag.
Nothing to fix.

## Sister-pattern reinforcement — MOOT-BY-CURRENT-PROBE-CLEARANCE recurs (2nd instance)

| # | Bead | Script | Why moot |
|---|---|---|---|
| 1 | 2xdi.114 | install-petal9-close.sh | flywheel CLI doctor cite at bin/flywheel:2012 |
| 2 | **2xdi.145** (this) | codex-deathtrap-launcher.sh | dedicated doctrine doc + sister test + 13+ receipts/evidence cites |

N=2 instances of MOOT-BY-CURRENT-PROBE-CLEARANCE. Per my 2xdi.114 evidence pack proposal:

> "If 5th MOOT-BY-CURRENT-PROBE-CLEARANCE occurs in the wired-but-cold class,
> that warrants an orch-tick-level calibration: auto-close beads at tick-time
> that current-probe no longer flags. faqj2's self-calibration probe could add
> a new finding type: `stale_auto_bead_no_longer_flagged_by_current_probe`."

Currently 2/5 toward that threshold. Pattern is recurring but not yet
canonical promotion candidate.

## Why no SKILL.md / doctrine / registry edits

- **Substrate-registry allowlist (Option A)**: Unnecessary. Probe already cleared.
- **SKILL.md citation (Option B)**: Already cited via `.flywheel/doctrine/codex-death-event-flow.md`.
- **NEW doctrine doc**: Duplicative of existing `codex-death-event-flow.md`.
- **NEW calibration bead**: 2/5 threshold not met for orch-tick auto-close calibration.

## AG receipt

| AG | Status | Evidence |
|---|---|---|
| AG1 verify bead hypothesis | DONE | current probe returns []; bead hypothesis empirically wrong |
| AG2 catalog canonical wiring | DONE | 13+ cites table |
| AG3 disposition decision (REFUTATION) | DONE | 3-option triage |
| AG4 sister-pattern reinforcement | DONE | 2/5 toward MOOT-BY-CURRENT-PROBE-CLEARANCE calibration threshold |
| AG5 no edits rationale | DONE | "Why no edits" section |
| AG6 receipt + close | DONE | this file |

did=6/6. didnt=none. gaps=none.

## Verification chain

```bash
# 1. Current probe does NOT flag this script
.flywheel/scripts/gap-hunt-probe.sh --json 2>/dev/null | jq -e '
  .gap_ids | map(select(test("codex-deathtrap"))) | length == 0
' >/dev/null && echo "PROBE CLEARED"

# 2. Doctrine doc cite (canonical wiring path)
grep -q 'codex-deathtrap-launcher.sh' .flywheel/doctrine/codex-death-event-flow.md

# 3. Sister test exists
test -f .flywheel/tests/test-codex-death-event-classifier.sh

# 4. Receipt evidence chain (sample 3)
test -d .flywheel/receipts/flywheel-ukm9f/audit && \
  test -f .flywheel/evidence/flywheel-delp/report.md
```

## Posterior shape census update

| Shape | Count | Latest |
|---|---|---|
| TP-with-semantic-embedding-AND-name-grep-blind-spot | 5 | 2xdi.141 |
| probe-self-clears-via-own-findings-ledger | 2 | 2xdi.119 |
| **MOOT-BY-CURRENT-PROBE-CLEARANCE** | **2** | **2xdi.145 (this)** |
| memory-proposes-future-class-not-yet-promoted | 2 | 2xdi.129 |
| script-wired-via-flywheel-hooks-or-tests-but-probe-corpus-3-too-narrow | 1 | 2xdi.144 |
| ... | ... | ... |

13 distinct posterior shapes after 27 META-RULE 2026-05-11 applications.

## Boundary preservation

- Did NOT modify gap-hunt-probe.sh (probe correctly clears)
- Did NOT modify the script (canonical wiring intact)
- Did NOT modify `.flywheel/doctrine/codex-death-event-flow.md` (already cites the script)
- Did NOT add registry entry (unnecessary; probe doesn't flag)
- Did NOT file calibration bead (2/5 threshold not met)

## L107 Reservations

0 reservations (no edits this tick).

## Doctrine compliance

- META-RULE 2026-05-11: 27th application; 2nd MOOT-BY-CURRENT-PROBE-CLEARANCE
- L52: 0 new beads filed; `no_bead_reason=hypothesis_refuted_current_probe_clears_canonical_doctrine_doc_already_cites_script_no_action_needed`
- `feedback_audit_findings_are_data_decided_not_joshua_gated.md` (META-RULE 2026-05-04): empirical probe → data-decided refutation
- `feedback_calibrate_test_to_actual_contract_before_filing_upstream.md` (META-RULE 2026-05-09): bead was filed pre-calibration; close aligns to current probe contract

## Skill Auto-Routes

| Skill | Status | Evidence |
|---|---|---|
| canonical-cli-scoping | n/a | refutation triage |
| rust-best-practices | n/a | bash |
| python-best-practices | n/a | bash |
| readme-writing | n/a | no doc edit |

## Four-Lens Self-Grade

- **Brand:** 10 — clean refutation; 2nd MOOT-BY-CURRENT-PROBE-CLEARANCE documented; calibration threshold (2/5) tracked
- **Sniff:** 10 — empirical probe + 13-cite wiring table; no fabricated remediation
- **Jeff:** 10 — substrate honesty about already-canonicalized script
- **Public:** 10 — Three Judges check passes (operator can verify probe state; maintainer has the threshold tracking; future worker sees the calibration candidate state)

`four_lens=brand:10,sniff:10,jeff:10,public:10`

## Compliance Score

| Dimension | Points | Evidence |
|---|---|---|
| AG1 hypothesis verification (current probe empty) | 200/200 | jq filter returns [] |
| AG2 canonical wiring catalog (13+ cites) | 200/200 | 6-surface table |
| AG3 disposition rationale (REFUTATION) | 150/150 | 3-option triage |
| AG4 sister-pattern reinforcement (2/5 threshold) | 100/100 | MOOT-BY-CURRENT-PROBE-CLEARANCE 2nd instance |
| AG5 no-edits rationale | 100/100 | explicit boundary preservation section |
| AG6 receipt + close | 100/100 | this document |
| META-RULE 27th application + 13th shape census update | 50/50 | shape table |
| Boundary preservation | 50/50 | 0 edits |
| L107 + L52 discipline | 50/50 | unnecessary actions skipped explicitly |
| **TOTAL** | **1000/1000** | |

`compliance_score=1000/1000`

## L112 Verify Probe

```bash
test -f .flywheel/audit/flywheel-2xdi.145/evidence.md && \
  .flywheel/scripts/gap-hunt-probe.sh --json 2>/dev/null | jq -e '.gap_ids | map(select(test("codex-deathtrap"))) | length == 0' >/dev/null && \
  grep -q 'codex-deathtrap-launcher' .flywheel/doctrine/codex-death-event-flow.md && \
  test -f .flywheel/tests/test-codex-death-event-classifier.sh
```
Expected: rc=0 (evidence + probe-cleared + doctrine cite + sister test). Timeout 30s.
