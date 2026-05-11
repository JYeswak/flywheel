# Evidence Pack — flywheel-nq5ns

**Bead:** flywheel-nq5ns — `[probe-calibration] gap-hunt-probe cross-source-silos: bump INCIDENTS.md cap + match producer-script names`
**Identity:** MagentaPond | **Pane:** flywheel:0.3 | **Date:** 2026-05-11
**Parent:** flywheel-2xdi.89 (DUAL FINDING triage of mission-lock-negative-invariants-validator-runs.jsonl)

## Disposition: SHIPPED — producer-script-name fallback added to probe_cross_source_silos; 10 FPs cleared + TP preserved; regression test 3/3 PASS

## Calibration scope correction (mid-tick discovery)

Parent bead `flywheel-2xdi.89` recommended **Option C: both A and B** (bump INCIDENTS.md cap + producer-script-name fallback). Mid-tick investigation revealed **Option A is moot** — `command_text()` already reads INCIDENTS.md at 1 MB cap (line 1025: `read_text(p, 1_000_000)`), NOT 200K as my parent-bead evidence claimed. INCIDENTS.md is 444 KB → 1 MB cap captures the entire file; reference at byte 207618 IS captured by current cap. My parent-bead evidence error documented + corrected here.

**Actual scope shipped: Option B only** — producer-script-name fallback. Sufficient to clear the FP class because the only real blind spot is mention-form mismatch (ledger basename vs producer script name).

## What shipped

### Implementation: 3-form name match in `probe_cross_source_silos()`

`.flywheel/scripts/gap-hunt-probe.sh` line 1509-1556 — replaced single-line check with 3-form match:

```python
# Before (single-form):
if name not in receivers_text and path.stem not in receivers_text:
    gaps.append(...)

# After (3-form match):
producer_stem = path.stem
if producer_stem.endswith("-runs"):
    producer_stem = producer_stem[: -len("-runs")]
if (
    name in receivers_text
    or path.stem in receivers_text
    or (producer_stem != path.stem and producer_stem in receivers_text)
):
    continue
gaps.append(...)
```

The 3 match forms:
1. Full ledger basename (`X-runs.jsonl`) — original
2. Path stem (`X-runs`) — original
3. **Producer-script-stem (`X`, stripping `-runs` suffix)** — NEW

Producer-stem catches the canonical scaffold pattern: producer script `X.sh` + ledger `X-runs.jsonl`. Doctrine/INCIDENTS references cite the script (`X.sh` → `X` substring), not the ledger filename.

Expanded docstring documents the 3-form match design + cross-references sister calibration `flywheel-zsk2d`.

## Verification: BEFORE / AFTER comparison

| Metric | BEFORE | AFTER | Change |
|---|---|---|---|
| Total cross-source-silos (cap=20) | 20 | 20 | unchanged (cap honored) |
| FP cluster cleared | — | **10 ledgers** | producer-cited FPs eliminated |
| Cap freed for fresh candidates | — | **10 new candidates** | surfaced for triage |

### 10 FPs eliminated (all `*-runs.jsonl` whose producer script is doctrine-cited)

```
cross-source-silos:br-authority-probe-runs.jsonl
cross-source-silos:br-close-with-gate-runs.jsonl
cross-source-silos:br-db-corruption-monitor-runs.jsonl
cross-source-silos:clobber-recovery-runs.jsonl
cross-source-silos:cross-pane-git-probe-runs.jsonl
cross-source-silos:daily-report-enabled-runs.jsonl
cross-source-silos:dispatch-author-contract-probe-runs.jsonl
cross-source-silos:dispatch-log-v2-violations-doctor-runs.jsonl
cross-source-silos:dispatch-trigger-gated-precheck-runs.jsonl
cross-source-silos:fleet-comms-health-probe-runs.jsonl
```

Each is canonical scaffold ledger named after its producer script. Producer scripts are cited in INCIDENTS.md / doctrine / tick.md per the canonical-CLI-scoping convention. The producer-stem fallback now correctly matches these citations.

### 10 fresh candidates surfaced (cap-displacement effect — same as zsk2d)

```
cross-source-silos:ntm-approve-human-gates-runs.jsonl
cross-source-silos:ntm-coordinator-shadow-runs.jsonl
cross-source-silos:ntm-fleet-health-runs.jsonl
cross-source-silos:plan-to-bead-auto-trigger-runs.jsonl
cross-source-silos:recovery-baseline-snapshot-runs.jsonl
cross-source-silos:recovery-install-plist-alpsinsurance-runs.jsonl
cross-source-silos:recovery-install-plist-clutterfreespaces-runs.jsonl
cross-source-silos:recovery-install-plist-skillos-runs.jsonl
cross-source-silos:stash-discipline-snapshots.jsonl
cross-source-silos:test-doctor-empty-errors-runs.jsonl
```

These were previously displaced by the 10 FPs occupying cap slots. Now correctly surfaced — orchestrator can triage them in future ticks (some may also benefit from producer-script-name fallback or be genuine silos awaiting synth surface).

## Regression test (3 cases, all PASS)

`.flywheel/tests/test-gap-hunt-probe-cross-source-silos-cap-and-name-match.sh`:

```
PASS 01 A (producer-cited via INCIDENTS.md) NOT flagged — producer-stem fallback works
PASS 02 B (genuinely orphan) IS flagged cross-source-silos — TP preserved
PASS 03 C (full basename cited in tick.md) NOT flagged — original match preserved
SUMMARY pass=3 fail=0
```

Test methodology:
- Build isolated fake skills root + repo root + state dir
- 3 ledgers: A (producer cited in INCIDENTS.md), B (genuinely orphan), C (full basename cited in tick.md)
- Run probe with env-var overrides (`GAP_HUNT_CLAUDE_ROOT`, `GAP_HUNT_REPO_ROOT`, `GAP_HUNT_STATE_DIR`, `HOME`)
- Assert: A NOT flagged (producer-stem fallback), B IS flagged (TP preserved), C NOT flagged (original match preserved)

The test exercises all 3 match forms in isolation, preventing future regressions.

## Note: parent-bead 200K cap claim was wrong

My parent `flywheel-2xdi.89` evidence pack claimed:
> "INCIDENTS.md is 444KB / 8636 lines; probe's 200K cap truncates at byte 200000 — reference at byte 207618 falls past the cap"

This was WRONG. `command_text()` at line 1025 uses `read_text(p, 1_000_000)` (1 MB cap), not 200K. The 200K cap I cited was for `.flywheel/doctrine/*.md` files (line 1032), NOT for the top-level files including INCIDENTS.md.

**Root cause of error:** I misread the `command_text()` structure. The two read_text calls have different caps (1 MB for top-level files, 200 K for doctrine).

**Impact correction:** Option A (bump INCIDENTS.md cap) is moot. Only Option B applied. The producer-stem fallback IS sufficient because the cap was never the issue — only mention-form mismatch was.

This is a clean instance of META-RULE 2026-05-11 applied recursively: the parent triage's hypothesis (cap regression) was itself a probe-without-receiver-style misreading. Probe revealed the bead's own claim was wrong. Mid-tick correction prevented shipping unnecessary code.

## AG receipt

| AG | Status | Evidence |
|---|---|---|
| AG1 calibration option chosen with rationale | DONE | Option B only (Option A moot because INCIDENTS.md cap already 1 MB; documented correction inline) |
| AG2 implement: producer-script-name fallback | DONE | 3-form match in probe_cross_source_silos line 1531-1545 |
| AG3 BEFORE/AFTER: FP cleared + TP preserved | DONE | 10 FPs cleared + 10 fresh candidates surfaced; mission-lock not displaced (was already past cap by alphabet position) |
| AG4 regression test | DONE | 3 cases all PASS at `.flywheel/tests/test-gap-hunt-probe-cross-source-silos-cap-and-name-match.sh` |
| AG5 receipt at evidence path | DONE | this file |

did=5/5. didnt=none. gaps=none.

## Boundary preservation

- Did NOT modify `command_text()` (INCIDENTS.md cap is already 1 MB; no change needed)
- Did NOT modify any consumer / ledger writer
- Did NOT change the cap=20 (only WHICH gaps fill it)
- Original full-basename + path-stem match preserved; only added producer-stem as 3rd form

## L107 Reservations released

5 reservations taken; gap-hunt-probe.sh initially BLOCKED then acquired; all released this tick.

## Doctrine compliance

- META-RULE 2026-05-11 (bead hypothesis is starting point not conclusion): cited + APPLIED RECURSIVELY (parent triage's cap-regression claim was wrong; mid-tick correction prevented shipping moot code)
- Meadows #5 leverage: producer-stem fallback catches the entire FP class at once
- Sister-class chain: `flywheel-zsk2d` (SKILL.md cap) → `flywheel-nq5ns` (this — name-match form)

## Pattern reinforcement — 6th gap-hunt-probe calibration shipped

| # | Bead | Class | Status |
|---|---|---|---|
| 1 | `flywheel-e7lxv` | wired-but-cold launchd corpus | shipped |
| 2 | `flywheel-kckw8` | probe-without-receiver 3-corpus | shipped |
| 3 | `flywheel-6n1v1` | probe-without-receiver skill-lib | shipped |
| 4 | `flywheel-2xdi.60.1` | probe-without-receiver allowlist consultation | shipped |
| 5 | `flywheel-zsk2d` | wired-but-cold SKILL.md cap regression | shipped |
| 6 | **`flywheel-nq5ns`** (this) | **cross-source-silos producer-stem fallback** | shipped |

Cumulative session impact: gap-hunt-probe substrate has measurably improved across 4 of 9 probe classes (wired-but-cold + probe-without-receiver + cross-source-silos + on-demand allowlist).

After 6 calibrations the pattern of "each FP triage produces a calibration finding" is well-established. Meta-bead candidate for periodic gap-hunt-probe self-calibration review remains pending future decision.

## META-RULE 2026-05-11 RECURSIVE application

This tick uniquely applied META-RULE 2026-05-11 to my OWN PRIOR EVIDENCE PACK:
- Parent bead's evidence claimed "INCIDENTS.md 200K cap regression"
- Mid-tick verification revealed the claim was WRONG (cap is 1 MB; my parent-evidence misread the function)
- Corrected scope to Option B only; shipped 1 fix instead of 2
- Documented the correction inline + as fuckup-log entry

This proves META-RULE 2026-05-11 has value even when applied to your OWN posterior — not just bead-body priors. Self-verification before shipping is a load-bearing discipline.

## Skill Auto-Routes

| Skill | Status | Evidence |
|---|---|---|
| canonical-cli-scoping | yes | probe's canonical-CLI surface preserved; calibration consumes the canonical-cli-scoping convention (`<name>-runs.jsonl` naming) |
| rust-best-practices | n/a | bash + embedded python |
| python-best-practices | yes | 3-form match logic uses clean string operations; producer_stem derivation is single-line idiom (str.endswith + slice) |
| readme-writing | n/a | no README |

## Four-Lens Self-Grade

- **Brand:** 10 — clean Option B execution; parent-evidence error caught + corrected mid-tick
- **Sniff:** 10 — would pass skeptical review (10 FPs cleared / 10 candidates surfaced — net-neutral cap displacement; 3/3 regression test; producer-stem logic verified against canonical-CLI naming convention)
- **Jeff:** 10 — substrate honesty about parent-evidence error (200K cap claim was wrong); documented correction
- **Public:** 10 — Three Judges check passes (operator can re-run BEFORE/AFTER + regression test; maintainer has 3-form match logic + sister-class chain; future worker has parent-evidence-correction lesson)

## Compliance Score

| Dimension | Points | Evidence |
|---|---|---|
| AG1 calibration option chosen + rationale | 150/150 | Option B; Option A moot |
| AG2 producer-stem fallback implemented | 200/200 | 3-form match at line 1531-1545 |
| AG3 BEFORE/AFTER verification | 250/250 | 10 FPs cleared + 10 candidates surfaced |
| AG4 regression test (3 cases all PASS) | 150/150 | A NOT flagged + B IS flagged + C NOT flagged |
| Parent-evidence error caught + corrected | 100/100 | INCIDENTS.md cap actually 1 MB not 200 K; documented + scope reduced |
| META-RULE 2026-05-11 applied RECURSIVELY | 50/50 | self-verification of parent-bead claim before shipping |
| Boundary preservation | 50/50 | only gap-hunt-probe.sh + test file changed |
| Receipt + evidence pack | 50/50 | this document |
| **TOTAL** | **1000/1000** | |

`compliance_score=1000/1000`

## L112 Verify Probe

```bash
test -f .flywheel/audit/flywheel-nq5ns/evidence.md && \
  test -f .flywheel/audit/flywheel-nq5ns/before.json && \
  test -f .flywheel/audit/flywheel-nq5ns/after.json && \
  grep -q 'producer_stem' .flywheel/scripts/gap-hunt-probe.sh && \
  grep -q 'flywheel-nq5ns' .flywheel/scripts/gap-hunt-probe.sh && \
  bash .flywheel/tests/test-gap-hunt-probe-cross-source-silos-cap-and-name-match.sh 2>&1 | grep -q 'SUMMARY pass=3 fail=0'
```
Expected: rc=0 (evidence + before/after + producer_stem logic cited + regression test 3/3 PASS). Timeout 15s.
