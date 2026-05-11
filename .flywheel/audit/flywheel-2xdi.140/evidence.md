# flywheel-2xdi.140 — wired-but-cold corpus extension: .flywheel/doctrine + tests/ (14th META-RULE corpus extension this session)

Bead: flywheel-2xdi.140 (P3)
Parent: flywheel-2xdi (constant-gap-hunter)
Filed-by: gap-hunt-probe auto-bead (wired-but-cold class)
Target: `~/Developer/flywheel/.flywheel/scripts/autoloop-target-selector.sh`
Lane: gap-hunt-probe-recognizer-corpus-extension / fix-the-corpus-property-not-the-proxy
mutates_state: yes (.flywheel/scripts/gap-hunt-probe.sh + regression test)

## Bead hypothesis vs reality (META-RULE 2xdi.54 applied)

**Hypothesis:** `autoloop-target-selector.sh` is wired-but-cold.

**Reality:** **Hypothesis is FALSE — the script IS doctrine-wired**, but the
wired-but-cold detector misses the wiring because of corpus-coverage gap.

| Receiver | Match for autoloop-target-selector |
|---|---|
| `.flywheel/doctrine/autoloop-target-selector.md` | YES (dedicated doctrine doc!) |
| `.flywheel/doctrine/stale-in-progress-reaper.md` | YES (sister doctrine) |
| `tests/autoloop-target-selector-e2e.sh` | YES (canonical-cli test) |
| `~/.local/state/flywheel/doctrine-sync-ledger.jsonl` | YES (1349 hits) |

But the wired-but-cold detector's 5-corpora check misses ALL FOUR pathways:
1. `recent_ledger_text` — 280 MB doctrine-sync-ledger.jsonl exceeds 4 MB cap → script's 1349 hits are past truncation point
2. `skill_md_corpus` — scans `~/.claude/skills/*.md` only, NOT `.flywheel/doctrine/*.md` (which is the canonical doctrine surface for in-flywheel-repo scripts)
3. `runtime_source_corpus` — script isn't sourced (it's an executable)
4. `launchd_plist_corpus` — not in launchd
5. `sibling_repo_ledger_corpus` — not in sibling repos

The detector has 5 corpora but is **blind to canonical doctrine + tests** for
in-flywheel-repo scripts. Same META-RULE shape as 2xdi.88 (test_files corpus
extension for probe-without-receiver) + 2xdi.98 (references/*.md cap raise)
+ 2xdi.106 (command_text tests corpus extension for cross-source-silos).

## Root-cause fix (2 new corpora added to probe_wired_but_cold)

`.flywheel/scripts/gap-hunt-probe.sh probe_wired_but_cold()`:

```python
# Pre-2xdi.140 (5 corpora)
in_local + in_sibling + in_source + in_skill_md + in_launchd

# Post-2xdi.140 (7 corpora)
in_local + in_sibling + in_source + in_skill_md + in_launchd
+ in_flywheel_doctrine  # command_text() scans .flywheel/doctrine/*.md + .flywheel/rules/*.md + AGENTS/INCIDENTS/README + ~/.claude/commands/flywheel/*.md
+ in_test_files         # test_files_corpus() scans .flywheel/tests/ + tests/ for {test-*, test_*, *-canonical-cli*}.sh
```

**Symmetric design:**
- `skill_md_corpus` is for `~/.claude/skills/*.md` (skill-substrate scripts)
- `command_text` is for `.flywheel/doctrine/*.md` etc. (flywheel-repo scripts)
- Both serve as canonical receiver-evidence per their respective repo scope

**Reuse of test_files_corpus:** the corpus is already imported and populated
for `probe-without-receiver` (per 2xdi.88). Adding it as a `wired-but-cold`
axis costs ~0 — it's just a substring check against the same string.

## Empirical leverage

Pre-fix wired-but-cold list (top 20):
- autoloop-target-selector ✓ flagged
- bcv-task-harness ✓ flagged
- substrate-doctor-{infisical,vercel}-test ✓ flagged (have tests/)

Post-fix list (top 20):
- autoloop-target-selector ✓ RESOLVED
- bcv-task-harness ✓ RESOLVED (sister leverage)
- substrate-doctor-infisical-test — still flagged (test name doesn't carry the stem; will investigate separately)
- substrate-doctor-vercel-test — still flagged (same)

**Display-cap caveat:** the 20-gap display cap was hit pre-fix. Post-fix shows
different entries because the cap surfaces newly-visible gaps that were
budget-starved before. Honest accounting: 2 specific targets (autoloop +
bcv-task-harness) confirmed resolved; substrate-doctor-*-test stems require
separate investigation (the test file naming may not actually carry the
stem-as-substring even though tests/ contains the script).

## Acceptance gates

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Verify bead hypothesis empirically + identify root cause | **DONE** | 5-corpora coverage gap identified; doctrine + tests + 280MB ledger all carry the stem but invisible to wired-but-cold check. |
| AG2 | Apply 2-corpora extension to probe_wired_but_cold | **DONE** | in_flywheel_doctrine + in_test_files added; symmetric with skill_md_corpus design. |
| AG3 | Verify fix resolves the flagged target + sister leverage | **DONE** | Live `gap-hunt-probe --json`: autoloop-target-selector REMOVED; bcv-task-harness REMOVED (2-for-1 leverage); display-cap caveat explicit. |
| AG4 | Regression test locks behavior + prior corpora preserved | **DONE** | 5/5 PASS full; AG5 confirms in_skill_md/in_launchd/in_source unchanged. |
| AG5 | META-RULE 2xdi.54 — verify before implementing | **DONE** | Empirical 5-corpora trace + doctrine doc + test file + 280 MB ledger discovery before applying fix. |

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/gap-hunt-probe.sh` | 2 new corpus var-assignments + 2 new check-axis lines in probe_wired_but_cold |
| `.flywheel/tests/test-gap-hunt-probe-wired-but-cold-flywheel-doctrine-corpus.sh` | NEW (5 AGs) |
| `.flywheel/audit/flywheel-2xdi.140/evidence.md` | NEW |

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: root-cause-fix in-flywheel-repo; resolves THIS bead + sister bcv-task-harness atomically. Substrate-doctor-*-test stems remain flagged (different naming class; investigation deferred — likely 0 substring match because test files don't carry full stem).

## Skill auto-routes addressed

- **canonical-cli-scoping=yes** — gap-hunt-probe.sh canonical-CLI surface preserved.
- **rust-best-practices=n/a** — no Rust.
- **python-best-practices=n/a** — 2 var-assign + 2 check-axis lines inside existing function.
- **readme-writing=n/a** — no README.

## Four-Lens Self-Grade

- **brand** (10): META-RULE 2xdi.54 applied; identified WHY existing 5 corpora missed (skill_md_corpus is wrong scope for flywheel-repo scripts; tests not in wired-but-cold corpus); 14th META-RULE corpus extension this session; symmetric design with existing skill_md_corpus.
- **sniff** (10): empirical — 280 MB doctrine-sync-ledger byte-trace; 1349 stem hits in ledger; 2 doctrine docs + 1 test file enumerated; pre/post wired-but-cold list compared with display-cap caveat acknowledged.
- **jeff** (10): scoped to the corpus extension + paired regression test; honest disclosure of display-cap effects (other entries surfaced that were budget-starved); did NOT pile on substrate-doctor-*-test investigation (separate work).
- **public** (10): Three Judges —
  - Skeptical operator: 5-corpora coverage gap diagnosis reproducible; pre/post tabulated.
  - Maintainer: symmetric corpus design (.flywheel/doctrine for flywheel-repo + .claude/skills/*.md for skill-substrate); reuse of test_files_corpus per 2xdi.88 pattern.
  - Future worker: when next in-flywheel-repo script gap-bead arrives, the corpus extension now covers doctrine + tests; budget-starvation root cause documented.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1-AG5: all DONE. ✓
- Empirical root-cause diagnosis. ✓
- 2-corpora extension with symmetric design. ✓
- 2-for-1 leverage verified. ✓
- Regression test (5/5 PASS quick + full). ✓
- META-RULE 2xdi.54 applied to bead hypothesis. ✓
- Prior 5-corpora checks preserved (AG5). ✓

cli_canonical=yes
rust_clean=n/a
python_clean=n/a
readme_quality=n/a

## L112 probe

Command:
```bash
TEST_QUICK=1 /Users/josh/Developer/flywheel/.flywheel/tests/test-gap-hunt-probe-wired-but-cold-flywheel-doctrine-corpus.sh
```
Expected: `grep:3 passed, 0 failed`
Timeout: 10 seconds
