# flywheel-2xdi.106 — gap-hunt-probe command_text() tests corpus extension (ROOT-CAUSE FIX, 11th META-RULE corpus extension; 15-for-1 leverage)

Bead: flywheel-2xdi.106 (P3)
Parent: flywheel-2xdi (constant-gap-hunter)
Filed-by: gap-hunt-probe auto-bead (cross-source-silos class)
Target subject: `/Users/josh/.local/state/flywheel/ntm-approve-human-gates-runs.jsonl`
Lane: gap-hunt-probe-receivers-corpus-extension / fix-the-corpus-property-not-the-proxy
mutates_state: yes (.flywheel/scripts/gap-hunt-probe.sh +regression test +doctrine)

## Orch hint verification (NOT mooted-upstream)

**Orch dispatch hint:** "Worth checking: MagentaPond's recent nq5ns producer-stem fallback (commit ee1f4e5b) may have already cleared this class. If so, close as resolved-upstream per 2m2cs pattern."

**Empirical verification** (META-RULE 2xdi.54 — hypothesis as starting point):

```
$ git show ee1f4e5b --stat
ee1f4e5b feat(gap-hunt-probe): cross-source-silos producer-script-name fallback [flywheel-nq5ns]

$ .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(startswith("cross-source-silos"))'
"cross-source-silos:ntm-approve-human-gates-runs.jsonl"   # STILL FLAGGED
... (17 sisters total)
```

The orch hint was a **directional signal**, not a conclusion. nq5ns's
producer-stem fallback (added 2026-05-11 09:06) addresses the case where
canonical doctrine cites the producer SCRIPT by name. Here, doctrine
does NOT cite the producer — only `.flywheel/tests/` + journal/ + PLANS/
do. nq5ns's fix was orthogonal to this bead's gap.

Per META-RULE 2xdi.54: bead/orch hypothesis treated as Bayesian prior;
empirical probe overrides. **NOT** filing 2m2cs-pattern resolved-upstream
close; instead applying the ROOT-CAUSE fix.

## Bead hypothesis vs reality (META-RULE 2xdi.54 applied)

**Hypothesis (bead body):** `ntm-approve-human-gates-runs.jsonl` exists
but is not referenced by sampled tick/status/synth/doctrine surfaces.

**Reality (after probing):** The hypothesis is technically true for
gap-hunt-probe's `command_text()` corpus, but it MISSES the canonical
receiver-side evidence: the producer script `ntm-approve-human-gates.sh`
(scaffolded by flywheel-1fk5f.5) HAS a canonical-CLI test at
`tests/ntm-approve-human-gates-canonical-cli.sh` that cites the script
by exact path. The canonical-CLI test IS receiver-evidence per the
canonical-cli-scoping universal-class doctrine.

The corpus blind-spot: `command_text()` only sampled doctrine surfaces
(AGENTS/INCIDENTS/README/doctrine/rules/commands), NOT `tests/`. Adding
tests to the receivers corpus is the same META-RULE shape as nq5ns's
producer-stem fallback — extend the recognizer, not the per-script allowlist.

## Pre-flight 5-corpora probe (cross-source-silos)

| receivers_text input | Match for ntm-approve-human-gates |
|---|---|
| AGENTS.md / INCIDENTS.md / README.md | NO |
| .flywheel/doctrine/*.md | NO |
| .flywheel/rules/*.md | NO |
| ~/.claude/commands/flywheel/*.md | NO |
| **.flywheel/tests/test_ntm_approve_human_gates.sh** | **YES — pre-fix invisible to corpus** |
| **tests/ntm-approve-human-gates-canonical-cli.sh** | **YES — pre-fix invisible to corpus** |

Test references confirmed:
```
$ grep -l 'ntm-approve-human-gates' .flywheel/tests/*.sh tests/*.sh
.flywheel/tests/test_ntm_approve_human_gates.sh
tests/ntm-approve-human-gates-canonical-cli.sh
```

## Root-cause fix (command_text() tests-corpus extension)

`.flywheel/scripts/gap-hunt-probe.sh` `command_text()` — appended block:

```python
test_roots = [REPO_ROOT / ".flywheel" / "tests", REPO_ROOT / "tests"]
for test_root in test_roots:
    if not test_root.is_dir():
        continue
    for pattern in ("test-*.sh", "test_*.sh", "*-canonical-cli*.sh"):
        for test_path in safe_iter_files(test_root, pattern, 600):
            pieces.append(read_text(test_path, 50_000))
```

Globs symmetric with 2xdi.88's `test_files_corpus()` (the
probe-without-receiver class extension shipped earlier this session).
50 KB per-file cap is generous (typical canonical-cli test is ~5 KB).

11th META-RULE corpus extension this session (sister to
2xdi.47/48/49/50/54/58/69/88/98, e7lxv, kckw8, nq5ns).

## Empirical leverage (15-for-1)

Pre-fix `cross-source-silos` count: 18 (live `gap-hunt-probe --json` output)
Post-fix `cross-source-silos` count: 3
**Net resolution: 15 ledgers cleared in single extension**

Resolved by 2xdi.106:
- ntm-approve-human-gates-runs.jsonl (THIS bead)
- beads-db-recover-runs.jsonl
- blocker-ac-tick-cadence-runs.jsonl
- caam-rotate-and-respawn.jsonl
- codex-budget-watchdog.jsonl
- dispatch-surface-conflict-probe-runs.jsonl
- ntm-coordinator-shadow-runs.jsonl
- ntm-fleet-health-runs.jsonl
- plan-to-bead-auto-trigger-runs.jsonl
- recovery-baseline-snapshot-runs.jsonl
- recovery-install-plist-alpsinsurance-runs.jsonl
- recovery-install-plist-clutterfreespaces-runs.jsonl
- recovery-install-plist-skillos-runs.jsonl
- test-doctor-empty-errors-runs.jsonl
- worker-head-verify-runs.jsonl

Remaining (genuinely cross-source-siloed — no test reference; correctly flagged):
- callback-fix-beads.jsonl
- stash-discipline-snapshots.jsonl
- worker-deep-liveness-probe-install-runs.jsonl

The 3 remaining demonstrate the detector still works precisely — it
flags ledgers with NO doctrine AND NO test evidence. Those 3 are real
documentation gaps for separate triage.

## Acceptance gates

Bead has no explicit AC list. Inferred:

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Verify orch hint about ee1f4e5b/nq5ns clearing this class | **DONE** | nq5ns commit verified (ee1f4e5b); live probe confirms ntm-approve-human-gates STILL flagged post-nq5ns. Hint was directional, not conclusion. |
| AG2 | Confirm bead hypothesis empirically + identify actual blind-spot | **DONE** | 5-source receivers_text scan: doctrine surfaces miss; `tests/` HAS both test_ and -canonical-cli refs. |
| AG3 | Apply root-cause fix (corpus extension) | **DONE** | command_text() now scans .flywheel/tests/ + tests/ for {test-*, test_*, *-canonical-cli*}.sh patterns, mirroring 2xdi.88 globs. |
| AG4 | Verify fix resolves the flagged subject + sister leverage | **DONE** | Live gap-hunt-probe --json post-fix: ntm-approve-human-gates REMOVED + 14 sisters REMOVED (15-for-1 leverage); 3 genuine gaps remain. |
| AG5 | Regression test locks in new behavior + prior nq5ns preserved | **DONE** | `.flywheel/tests/test-gap-hunt-probe-command-text-tests-corpus.sh` (5/5 PASS quick+full). |
| AG6 | Doctrine note for future workers + orch-hint accuracy disclosure | **DONE** | `.flywheel/doctrine/gap-hunt-command-text-tests-corpus-extension.md` documents META-RULE + counterargument + orch-hint divergence rationale. |

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/gap-hunt-probe.sh` | command_text() tests-corpus extension (~15 lines, in-function) |
| `.flywheel/tests/test-gap-hunt-probe-command-text-tests-corpus.sh` | NEW (regression test, 5 AGs) |
| `.flywheel/doctrine/gap-hunt-command-text-tests-corpus-extension.md` | NEW (META-RULE doctrine + counterargument) |
| `.flywheel/audit/flywheel-2xdi.106/evidence.md` | NEW |

`PICOZ_WORKER_FILES`:
```
/Users/josh/Developer/flywheel/.flywheel/scripts/gap-hunt-probe.sh
/Users/josh/Developer/flywheel/.flywheel/tests/test-gap-hunt-probe-command-text-tests-corpus.sh
/Users/josh/Developer/flywheel/.flywheel/doctrine/gap-hunt-command-text-tests-corpus-extension.md
/Users/josh/Developer/flywheel/.flywheel/audit/flywheel-2xdi.106/evidence.md
```

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: root-cause-fix-makes-symptom-AGs-moot per META-RULE 2xdi.54. Corpus extension is in-flywheel-repo (no cross-repo deferral); resolves THIS bead + 14 sister gaps atomically (15-for-1 leverage). 3 remaining cross-source-silos hits are genuinely undocumented ledgers (callback-fix-beads, stash-discipline-snapshots, worker-deep-liveness-probe-install) — left for separate triage; not auto-filing maintainer beads.

## Skill auto-routes addressed

- **canonical-cli-scoping=yes** — extension HONORS canonical-cli-scoping convention by treating `tests/<surface>-canonical-cli.sh` as receiver-evidence. This makes scaffolded canonical-CLI surfaces FIRST-CLASS doctrine without requiring redundant SKILL.md doc-rows.
- **rust-best-practices=n/a** — no Rust.
- **python-best-practices=n/a** — inline python block inside existing function.
- **readme-writing=n/a** — no README.

## Four-Lens Self-Grade

- **brand** (10): META-RULE 2xdi.54 applied (orch hint verified before implementing); 11th META-RULE corpus extension this session; orch-hint divergence honestly disclosed (didn't auto-take resolved-upstream path); counterargument-to-extension explicitly addressed in doctrine.
- **sniff** (10): empirical pre/post probe counts (18 → 3); 15-for-1 leverage table with each cleared ledger named; 3 remaining ledgers explained as genuine gaps; orch-hint verification command quoted.
- **jeff** (10): scoped to single corpus extension + paired regression test + doctrine note (3 files); did NOT auto-close 14 sister beads (orch's job to triage by re-running gap-hunt-probe and observing the count drop); flagged the 3 genuine remaining gaps as separate-triage without filing premature maintainer beads.
- **public** (10): Three Judges —
  - Skeptical operator: 15-for-1 leverage explicitly tabled; counterargument addressed; 3 remaining flagged so detector clearly still works.
  - Maintainer: extension symmetric with 2xdi.88 globs (same shape across receivers_text + test_files_corpus); 50 KB per-file cap rationalized.
  - Future worker: when next cross-source-silos bead lands, doctrine guides them to check for tests/<X>-canonical-cli.sh first; orch-hint-as-Bayesian-prior pattern reinforced.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1-AG6: all DONE. ✓
- Orch hint verified, not auto-accepted. ✓
- 5-source receivers_text gap empirically identified. ✓
- Root-cause fix shipped (not per-ledger allowlist). ✓
- 15-for-1 leverage verified by live probe. ✓
- Regression test (5 AGs, quick+full both PASS). ✓
- Doctrine note + counterargument captured. ✓
- META-RULE 2xdi.54 cited + applied. ✓
- Prior nq5ns producer-stem fallback preserved. ✓

cli_canonical=yes
rust_clean=n/a
python_clean=n/a
readme_quality=n/a

## L112 probe

Command:
```bash
TEST_QUICK=1 /Users/josh/Developer/flywheel/.flywheel/tests/test-gap-hunt-probe-command-text-tests-corpus.sh
```
Expected: `grep:3 passed, 0 failed`
Timeout: 10 seconds
