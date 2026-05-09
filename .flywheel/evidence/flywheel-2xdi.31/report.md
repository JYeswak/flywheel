# flywheel-2xdi.31 — Worker Report

**Task:** [gap-wired-but-cold] .claude/skills/.flywheel/hooks/tick_guard.sh
**Identity:** MagentaPond (codex-pane on flywheel:1)
**Repo head:** 1e7f415 (master)
**Status:** done
**Mission fitness:** infrastructure — disposition for an auto-filed gap-hunt-probe wired-but-cold candidate; verifies the script is alive (in skillos, not flywheel) and recommends a probe-scope refinement to prevent the false-positive class.

## Verdict

**Probe false-positive — script is `alive_in_skillos`, not cold.**

The gap-hunt-probe correctly observed that `~/.claude/skills/.flywheel/hooks/tick_guard.sh` is not referenced by any flywheel jsonl ledger modified in the last 30 days. But the script is a skillos-targeted helper that happens to live in the `.flywheel` skill umbrella (which is canonical, since `.flywheel/` provides shared substrate to all flywheel-managed repos). The script has 6 bats tests + e2e usage + 3+ skillos beads — it is actively wired in skillos.

This is the "cross-repo helper misclassified by single-repo probe scope" pattern.

## Acceptance gate coverage

The bead body has no explicit AG list (auto-filed by gap-hunt-probe). The implicit gate is "decide disposition: cold-and-decommission / alive-and-document / wire-in".

| Implicit gate | Status | Evidence |
|---|---|---|
| Determine if the script is genuinely cold | DID | 6-source survey across `.claude`, flywheel, skillos confirms script is alive in skillos |
| Decide disposition | DID | `alive_in_skillos` (document the cross-repo usage; do not decommission) |
| Surface Phase-4 follow-up if improvement is warranted | DID | Recommended improvement to the gap-hunt-probe to check sibling repos OR honor an exemption metadata file |

did=3/3, didnt=none, gaps=none.

## Live data probe

| Signal | Value | Interpretation |
|---|---|---|
| Script exists | `~/.claude/skills/.flywheel/hooks/tick_guard.sh` 8245 bytes mode `-rwxr-xr-x` | Present and executable |
| Last modified | 2026-05-05 22:22:45 (4 days ago) | Recent — well under any 30d staleness threshold |
| Defaults target | `SKILLOS_REPO_ROOT=/Users/josh/Developer/skillos` (and other `SKILLOS_*` env vars) | Script is skillos-targeted by design |
| Skillos test wiring | `tests/unit/tick_guard.bats` (6 `@test` blocks); `tests/unit/test_manager_runtime.py`; `tests/e2e/e2e_manager_service.sh`; `tests/e2e/e2e_substrate_smoke.sh` | Multiple test surfaces actively reference it |
| Skillos beads | `skillos-1zuy` (PB-0 Build phantom substrate FIRST: tick_guard.sh + …); `skillos-2izb` (PB-11 Cross-orch handoff with tick_guard); `skillos-53f7` (E1 Manager-as-a-service runtime gated on PB-11) | Authored as canonical phantom-substrate compile target |
| Flywheel skill PATTERNS reference | `~/.claude/skills/.flywheel/PATTERNS.md` row "loop-enforcement/SKILL.md → tick_guard.sh (cron substrate compile target)" | Doctrine-grounded purpose |
| Flywheel jsonl ledgers (30d) | 0 hits | Probe's specific check returns true (the script is not invoked by flywheel ledger writes) — but this is correct by design |

**Aggregate signal: alive in skillos; cold in flywheel ledgers because it's a skillos-targeted helper, not a flywheel-internal hook.**

## Disposition

`alive_in_skillos` — keep the script in place; do not decommission; do not wire-in to flywheel ledgers (it does not belong there).

The script's location under `~/.claude/skills/.flywheel/hooks/` is canonical: `.flywheel/` is the shared skill umbrella that flywheel-managed repos (skillos, alps, mobile-eats, cfs, flywheel itself) all consume. A script under `.flywheel/hooks/` may legitimately target a specific consumer-repo. The bats/e2e/bead evidence in skillos confirms this is the case here.

## Recommended Phase-4 follow-up (single bead, low priority)

`flywheel-2xdi.31.1` — improve the gap-hunt-probe (parent `flywheel-2xdi`) to:
- Check sibling-repo ledgers for scripts located under `~/.claude/skills/.flywheel/hooks/*` (or any cross-repo umbrella path)
- Honor an optional `# gap-hunt-target: skillos` metadata header in scripts under shared umbrellas
- Drop "wired-but-cold" verdict when sibling-repo activity is found

Estimated effort: ~30 minutes. Risk: low (probe-only change). Reversible by reverting the probe edit.

## Validation

```bash
# Script exists and is executable
ls -la /Users/josh/.claude/skills/.flywheel/hooks/tick_guard.sh
# → -rwxr-xr-x@ 1 josh staff 8245 May 5 22:22 (4 days ago)

# Skillos test count
grep -c '^@test' /Users/josh/Developer/skillos/tests/unit/tick_guard.bats
# → 6

# Skillos bead references
grep -c "tick_guard" /Users/josh/Developer/skillos/.beads/issues.jsonl
# → at least 3 distinct beads (skillos-1zuy, skillos-2izb, skillos-53f7)

# Defaults are skillos-pointing
grep -E '^[A-Z_]+="\${SKILLOS_' /Users/josh/.claude/skills/.flywheel/hooks/tick_guard.sh | wc -l
# → 5 (SKILLOS_REPO_ROOT, SKILLOS_DISPATCH_EVENTS, SKILLOS_MISSION_FILE, SKILLOS_OPEN_WORK_FILE, SKILLOS_SUBSTRATE_STATUS_FILE)
```

L112 probe: `grep -c '^@test' /Users/josh/Developer/skillos/tests/unit/tick_guard.bats` expects integer >= 6.

## Three-Q

- **VALIDATED:** 6 independent signals confirm alive-in-skillos status; the gap-hunt-probe's specific check (no flywheel ledger references) returns true but the conclusion is wrong because the probe is single-repo-scoped.
- **DOCUMENTED:** disposition `alive_in_skillos` named; cross-repo umbrella pattern (`.claude/skills/.flywheel/hooks/`) called out; Phase-4 follow-up specced.
- **SURFACED:** the recommended probe improvement prevents this false-positive class for the next gap-hunt sweep.

## Four-Lens Self-Grade

four_lens=brand:9,sniff:9,jeff:9,public:9 — **4/4 PASS**

- **Brand (9/10):** P3 disposition kept proportional — short triage, no churn, no edits to active substrate.
- **Sniff (9/10):** every claim has independent evidence (bats count, bead IDs, env-var grep, file mtime, doctrine reference); the probe's true-positive signal and the wrong-conclusion are separately named.
- **Jeff (9/10):** cites operational primitives — `grep`, `ls`, `stat`, doctrine reference (`loop-enforcement → tick_guard.sh cron substrate compile target`). Phase-4 follow-up names the exact probe-scope refinement.
- **Public (9/10):** **Three Judges check** — skeptical operator can re-run the 6-signal probe and reproduce; maintainer sees that `.flywheel/hooks/` is a canonical cross-repo umbrella and the probe needs sibling-repo awareness; future worker has the Phase-4 spec for the probe edit.

## Skill auto-routes addressed

- `canonical-cli-scoping=n/a` — no new CLI surface.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — disposition evidence, not a README.

## Skill discoveries

`skill_discoveries=0 sd_ids=none` — task fits the canonical gap-hunt-probe disposition pattern. The "cross-repo umbrella misclassified by single-repo probe" observation is a candidate convergent-evolution signal (similar to s69zu basename-keying-collision patterns) but not yet 3-strike — log to memory only if it surfaces twice more.

## L52 / L70 receipt

- L52 (issues-to-beads): **`no_bead_reason=p3_gap_disposition_with_phase_4_follow_up_specced_in_evidence_no_bead_filed_until_orch_authorizes`** — one Phase-4 follow-up specced (`flywheel-2xdi.31.1` probe-scope refinement). P3 gap-hunt beads should not auto-spawn more beads at the same priority.
- L70 (no-punt): the next-actionable IS this disposition — running it in the same tick satisfies L70.

## L61 ecosystem-touch

- `agents_md_updated=no` — disposition evidence only.
- `readme_updated=not_applicable` — same.
- `no_touch_reason=p3_gap_disposition_only_no_doctrine_change`

## Compliance Pack

Score: 920/1000.

- All implicit gates DID
- 6-signal probe pipeline reproducible
- Disposition named with evidence per signal
- Phase-4 follow-up specced with effort/risk/rollback
- 4/4 lenses with 9/10 self-grades
- L107 reservation acquired/released

Pack path: `.flywheel/evidence/flywheel-2xdi.31/`.

`evidence_schema_version=gap-hunt-disposition/v1`. `four_lens_close_validator_version=four-lens-close-validator/v1`. `publishability_bar_version=publishability-bar/v1`.

## Cross-references

- Parent: `flywheel-2xdi` ([constant-gap-hunter] cron-loop step that hunts NEW gaps every tick)
- Grandparent: `flywheel-wxth` ([bitter-lesson-integration] EPIC: 1000 ways to leverage tokens)
- Related skillos beads: `skillos-1zuy`, `skillos-2izb`, `skillos-53f7`
- Doctrine: `~/.claude/skills/.flywheel/PATTERNS.md` (loop-enforcement → tick_guard.sh cron substrate compile target)
- Skill umbrella: `~/.claude/skills/.flywheel/hooks/` (cross-repo shared substrate)
- L-rules cited: L107 (shared-surface reservation, applied), L70 (no-punt), L80 (closed-bead-audit-mining — informs the parent dependency context)
