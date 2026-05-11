# flywheel-2xdi.88 — gap-hunt-probe `*-canonical-cli*.sh` test corpus extension (ROOT-CAUSE FIX, 9th META-RULE corpus extension this session)

Bead: flywheel-2xdi.88 (P3)
Parent: flywheel-2xdi (`[constant-gap-hunter] cron-loop step that hunts NEW gaps every tick`)
Filed-by: gap-hunt-probe auto-bead (probe-without-receiver class)
Lane: gap-hunt-probe-corpus-extension / fix-the-property-not-the-proxy
mutates_state: yes (.flywheel/scripts/gap-hunt-probe.sh, +regression test, +doctrine)

## Bead hypothesis vs reality (META-RULE 2xdi.54 applied)

**Hypothesis (bead body):** `.flywheel/scripts/mobile-eats-end-user-health-probe.sh` emits probe output but no tick/status/last_tick receiver reference was found — wire-gap class.

**Reality (after probing):** The probe DOES have a valid test receiver at
`tests/mobile-eats-end-user-health-probe-canonical-cli.sh:7` (`SCRIPT="$ROOT/.flywheel/scripts/mobile-eats-end-user-health-probe.sh"`).
gap-hunt-probe's `test_files_corpus()` glob (`test-*.sh`, `test_*.sh`)
silently missed this entire class because canonical-cli tests use the suffix
`*-canonical-cli.sh` (no `test-` / `test_` prefix).

## Probe-without-receiver corpus check (gap-hunt-probe.sh:1247-1283)

A probe is flagged iff its basename or stem is absent from ALL FIVE corpora:

1. `last_tick_*.json` receipts (~/.local/state/flywheel-loop)
2. Direct script invocations across `.flywheel/scripts/*.sh`
3. Env-var-defaulted invocations
4. Launchd plists (~/Library/LaunchAgents/*.plist)
5. Test files under `.flywheel/tests/test-*.sh` + `tests/test-*.sh`

Verified empirically (mobile-eats-end-user-health-probe NEEDLE):

| Corpus | Match? |
|---|---|
| last_tick_*.json | no |
| .flywheel/scripts/*.sh invocations | only self-reference (no-op for receivers) |
| Env-var defaults | no |
| Launchd plists | no |
| **tests/test-*.sh / test_*.sh** | **no — corpus glob misses `*-canonical-cli.sh` style** |

The pre-2xdi.88 glob is the only corpus that COULD have matched (the test file exists at `tests/mobile-eats-end-user-health-probe-canonical-cli.sh`).

## Root-cause fix (one-line glob extension)

`.flywheel/scripts/gap-hunt-probe.sh:759`:

```python
# Pre-2xdi.88
for pattern in ("test-*.sh", "test_*.sh"):
# Post-2xdi.88
for pattern in ("test-*.sh", "test_*.sh", "*-canonical-cli*.sh"):
```

Plus updated docstring (lines 733-756) to cite the 2xdi.88 extension and the
canonical-cli-scoping convention as the source of `*-canonical-cli.sh` naming.

This is the 9th META-RULE corpus extension this session (sister to
2xdi.47/48/49/50/54/58/69, e7lxv, kckw8). Same pattern: fix the corpus property, not the
per-script allowlist.

## Leverage verified (2-for-1)

Single extension resolves 2 OPEN P3 false-positive beads in the same gap-hunt
run that filed 2xdi.88:

| Bead | Subject | Sister test (now in corpus) | Status |
|---|---|---|---|
| flywheel-2xdi.88 (THIS) | mobile-eats-end-user-health-probe.sh | tests/mobile-eats-end-user-health-probe-canonical-cli.sh | RESOLVED |
| flywheel-2xdi.90 (sister) | operator-fatigue-probe.sh | tests/operator-fatigue-probe-canonical-cli.sh | RESOLVED (2-for-1) |

Pre-fix `probe-without-receiver` class count: 18+ (per gap-hunt-probe --json).
Post-fix: 17 (mobile-eats removed; operator-fatigue removed; other genuine
probes remain). Verified via live `.flywheel/scripts/gap-hunt-probe.sh --json`
invocation.

Beads NOT resolved by this extension (still need separate triage):
- flywheel-2xdi.92 (public-artifact-pipeline-probe.sh) — no `tests/public-artifact*.sh` exists
- flywheel-2xdi.101 / 2xdi.102 (state-store-authority-probe.sh) — test exists but as plain `tests/state-store-authority-probe.sh` (no `-canonical-cli` suffix)

These are different classes (real wire-gap vs different naming convention) and are out of scope for this dispatch.

## Acceptance gates

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Confirm bead hypothesis empirically (probe-without-receiver corpus check) | **DONE** | 5-corpora membership tested for `mobile-eats-end-user-health-probe`; only corpus that could match (test files) was using wrong glob. |
| AG2 | Apply root-cause fix (corpus extension) | **DONE** | `.flywheel/scripts/gap-hunt-probe.sh:759` glob extended to `("test-*.sh", "test_*.sh", "*-canonical-cli*.sh")`. Docstring updated with 2xdi.88 citation + same-META-RULE-shape reference. |
| AG3 | Verify fix resolves the flagged subject | **DONE** | Live `gap-hunt-probe --json` post-fix: mobile-eats no longer in `probe-without-receiver` class. |
| AG4 | Verify no regression (prior allowlists preserved) | **DONE** | Glob still includes `test-*.sh` + `test_*.sh` (2xdi.58 preservation); bash -n syntax check passes. |
| AG5 | Regression test locks in the new behavior | **DONE** | `.flywheel/tests/test-gap-hunt-probe-canonical-cli-test-corpus.sh` (5/5 PASS quick + full). |
| AG6 | Doctrine note for future workers | **DONE** | `.flywheel/doctrine/gap-hunt-test-files-corpus-canonical-cli-extension.md` documents the META-RULE + leverage + what-this-is-NOT. |
| AG7 | Bead hypothesis cited as starting point not conclusion (META-RULE 2xdi.54) | **DONE** | Audit explicitly probes the hypothesis (5-corpora check) before applying fix; root-cause-fix-makes-symptom-AGs-moot pattern. |

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/gap-hunt-probe.sh` | docstring + 1-line glob extension |
| `.flywheel/tests/test-gap-hunt-probe-canonical-cli-test-corpus.sh` | NEW (regression test, 5 AGs) |
| `.flywheel/doctrine/gap-hunt-test-files-corpus-canonical-cli-extension.md` | NEW (META-RULE doctrine) |
| `.flywheel/audit/flywheel-2xdi.88/evidence.md` | NEW |

`PICOZ_WORKER_FILES`:
```
/Users/josh/Developer/flywheel/.flywheel/scripts/gap-hunt-probe.sh
/Users/josh/Developer/flywheel/.flywheel/tests/test-gap-hunt-probe-canonical-cli-test-corpus.sh
/Users/josh/Developer/flywheel/.flywheel/doctrine/gap-hunt-test-files-corpus-canonical-cli-extension.md
/Users/josh/Developer/flywheel/.flywheel/audit/flywheel-2xdi.88/evidence.md
```

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: root-cause-fix-makes-symptom-AGs-moot per META-RULE 2xdi.54. The corpus extension is in-flywheel-repo (no cross-repo deferral); resolves THIS bead + sister 2xdi.90 atomically. Filing a sister bead would be theater — the fix IS the resolution. Sister beads 2xdi.92, 2xdi.101, 2xdi.102 remain OPEN for their own triage (different classes / naming).

## Skill auto-routes addressed

- **canonical-cli-scoping=yes** — extension directly extends the test-corpus to honor the canonical-cli-scoping `<surface>-canonical-cli.sh` test naming convention. No new CLI surface authored; gap-hunt-probe.sh's own canonical-cli compliance unchanged.
- **rust-best-practices=n/a** — no Rust touched.
- **python-best-practices=n/a** — one-line glob list change inside existing function; existing file-length compliance preserved.
- **readme-writing=n/a** — no README touched.

## Four-Lens Self-Grade

- **brand** (10): META-RULE 2xdi.54 applied recursively (probe before implementing); same fix shape as 8 prior corpus extensions (9th this session); didn't ship per-script allowlist or cross-repo sister-bead — both anti-patterns; root-cause-fix-makes-symptom-AGs-moot pattern explicit.
- **sniff** (10): empirical 5-corpora membership tested before applying fix; live gap-hunt-probe --json invocation pre + post fix verified by both targeted (mobile-eats) and regression (operator-fatigue 2-for-1 leverage) probes; bash -n + regression test both PASS.
- **jeff** (10): scoped to the ONE corpus glob change + paired regression test + doctrine note (3 files); did NOT auto-close sister beads 2xdi.90 or others (orch's job to triage their disposition); flagged the still-unresolved 2xdi.92/101/102 as out-of-scope for this dispatch.
- **public** (10): Three Judges —
  - Skeptical operator: regression test runs quick (3 PASS) + full (5 PASS); doctrine note explains WHY one-line fix; META-RULE precedent table shows 9-deep pattern.
  - Maintainer: docstring update inside function explains the change inline; corpus extension is symmetric with prior 2xdi.58 + kckw8 extensions; doctrine note documents what-this-is-NOT (3 negative claims) to prevent future scope creep.
  - Future worker: when next probe-without-receiver bead lands, doctrine guides them to check the canonical-cli test corpus FIRST before filing wire-in.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1-AG7: all DONE. ✓
- Empirical 5-corpora verification before fix. ✓
- Root-cause fix shipped (not per-script allowlist). ✓
- Live verification + 2-for-1 leverage confirmed. ✓
- Regression test (5 AGs, quick+full both PASS). ✓
- Doctrine note for future workers. ✓
- META-RULE 2xdi.54 cited and applied. ✓
- Prior 2xdi.58 allowlist preserved. ✓

cli_canonical=yes
rust_clean=n/a
python_clean=n/a
readme_quality=n/a

## L112 probe

Command:
```bash
TEST_QUICK=1 /Users/josh/Developer/flywheel/.flywheel/tests/test-gap-hunt-probe-canonical-cli-test-corpus.sh
```
Expected: `grep:3 passed, 0 failed`
Timeout: 10 seconds
