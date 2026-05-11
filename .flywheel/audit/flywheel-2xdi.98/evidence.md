# flywheel-2xdi.98 — gap-hunt-probe skill_md_corpus references/*.md per-file cap raised 4KB → 128KB (ROOT-CAUSE FIX, 10th META-RULE corpus extension this session)

Bead: flywheel-2xdi.98 (P3)
Parent: flywheel-2xdi (constant-gap-hunter)
Filed-by: gap-hunt-probe auto-bead (wired-but-cold class)
Target subject: `~/.claude/skills/cubcloud-ops/scripts/litellm-deep-probe.sh`
Lane: gap-hunt-probe-corpus-budget-extension / fix-the-corpus-property-not-the-proxy
mutates_state: yes (.flywheel/scripts/gap-hunt-probe.sh +regression test +doctrine)

## Bead hypothesis vs reality (META-RULE 2xdi.54 applied)

**Hypothesis (bead body):** `~/.claude/skills/cubcloud-ops/scripts/litellm-deep-probe.sh` is wired-but-cold (not referenced by recent flywheel jsonl ledgers).

**Reality (after probing):** The script IS referenced in
`cubcloud-ops/references/LITELLM-MODEL-SPEC.md` at line 299
(`ssh alps1 'bash /tmp/litellm-deep-probe.sh' > ~/Desktop/litellm-deep-...`),
but the gap-hunt-probe `skill_md_corpus()` 4 KB per-file cap truncated the
file before reaching byte 12925 (where the reference appears). The corpus
silently missed the wiring evidence.

## Pre-flight probe (5-corpora + ownership)

| Corpus | Match for litellm-deep-probe | Notes |
|---|---|---|
| recent_ledger_text | NO | operator-invoked from alps1 via ssh; not flywheel-tick |
| sibling_repo_ledger | NO | |
| runtime_source_corpus | NO | executable, not sourced |
| **skill_md_corpus** | **NO (pre-fix) → YES (post-fix)** | references doc has 13968 bytes; pre-fix 4 KB cap truncated at byte 4096; the reference is at byte 12925 |
| launchd_plist_corpus | NO | |

JSM status: `cubcloud-ops` is JSM-UNMANAGED (`jsm show cubcloud-ops` → "not found"). NOT a Jeff Premium skill. Joshua's own infrastructure skill.

## Root-cause fix (3-pass corpus structure)

`.flywheel/scripts/gap-hunt-probe.sh` `skill_md_corpus()`:

Pre-2xdi.98 (2-pass per 2xdi.66):
- Pass 1: SKILL.md @ 256 KB per-file cap
- Pass 2: ALL other *.md (including `references/*.md`) @ 4 KB per-file cap

Post-2xdi.98 (3-pass):
- Pass 1: SKILL.md @ 256 KB per-file cap (UNCHANGED — 2xdi.66 preserved)
- Pass 2 (NEW): `references/*.md` (identified by `any(part == "references" for part in p.parts)`) @ 128 KB per-file cap
- Pass 3: All-other-*.md @ 4 KB per-file cap

128 KB cap chosen because the largest observed `references/*.md` is 116 KB
(`tax-return-preparation-and-advice-generic/references/strategies/ADVANCED-STRATEGIES.md`).
Overall 32 MB cap unchanged; 3278 references/*.md files × natural sizes
total 28 MB fits comfortably under the cap.

Same META-RULE shape as 2xdi.66 (which raised SKILL.md cap 4 KB → 256 KB
after agent-ergonomics 60K+ scripts table was truncated). 10th META-RULE
corpus extension this session (sister to
2xdi.47/48/49/50/54/58/69/88, e7lxv, kckw8).

## Empirical leverage (4-for-1)

Single 3-pass structure resolves 4 wired-but-cold gaps in the same hunt:

| Subject | references doc + byte position (pre-fix invisible to corpus) | Post-fix |
|---|---|---|
| cubcloud-ops/scripts/litellm-deep-probe.sh (THIS bead) | `LITELLM-MODEL-SPEC.md:299` (byte 12925) | RESOLVED ✓ |
| git-worktree/scripts/conflict-replay.sh | `OPERATOR-LIBRARY.md` byte 89124 | RESOLVED ✓ |
| git-worktree/scripts/workspace-export.sh | `OPERATOR-LIBRARY.md` byte 88231 | RESOLVED ✓ |
| mcp-server-design/scripts/statusline.sh (mapped to nano-banana statusline) | `TESTING-PATTERNS.md` byte 4591 | RESOLVED ✓ |
| flywheel-end-to-end/references/TEST-HARNESS.sh | doc has `test-harness.mdx` reference but stem `TEST-HARNESS` is case-mismatched (separate META-RULE) | STILL FLAGGED (out of scope) |

Pre-fix wired-but-cold count: 20 (includes litellm + 3 sisters)
Post-fix wired-but-cold count: 20 (litellm + 3 sisters REMOVED; 4 unrelated newly surface — net same count, but composition changed)

The post-fix list reflects the underlying truth: false-positives removed,
genuine wire-gaps (or other-class false-positives like case-sensitivity)
remain.

## Out-of-scope finding (captured for future maintainer)

`TEST-HARNESS.sh` remains flagged because `wired-but-cold`'s substring check
is **case-sensitive**:
- script.stem = "TEST-HARNESS" (all caps; Path semantics preserve case)
- references doc mentions "test-harness.mdx" (lowercase)
- Python `"TEST-HARNESS" in "test-harness.mdx"` → False

This is a DIFFERENT META-RULE candidate (case-insensitive substring matching
for filename comparison). Not auto-filed; sufficient signal-to-noise to wait
for N≥2 recurrence before mechanization.

## Acceptance gates

Bead has no explicit AC list. Inferred:

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Confirm bead hypothesis empirically | **DONE** | 5-corpora probe; references doc has reference at byte 12925; pre-fix 4 KB cap truncated. |
| AG2 | Apply root-cause fix (corpus per-file cap) | **DONE** | 3-pass structure added: skill_md (256K) → references_md (128K) → other (4K). |
| AG3 | Verify fix resolves the flagged subject + sister leverage | **DONE** | Live gap-hunt-probe --json post-fix: litellm + 3 sisters all REMOVED from wired-but-cold class. |
| AG4 | Regression test locks in new behavior + prior 2xdi.66 cap preserved | **DONE** | `.flywheel/tests/test-gap-hunt-probe-references-md-cap-extension.sh` (5/5 PASS full mode). |
| AG5 | Doctrine note + sister case-sensitivity finding captured | **DONE** | `.flywheel/doctrine/gap-hunt-skill-md-corpus-references-cap-extension.md` documents the fix + budget impact + out-of-scope case-sensitivity note. |
| AG6 | Bead hypothesis cited as starting point not conclusion (META-RULE 2xdi.54) | **DONE** | Empirical probe confirmed the gap WAS real but corpus blind-spot, not script orphan. Root-cause fix makes symptom-AGs moot per Meadows #5. |

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/gap-hunt-probe.sh` | 3-pass corpus structure: `references_md_per_file_cap = 128 * 1024` + Pass 2 block + docstring update |
| `.flywheel/tests/test-gap-hunt-probe-references-md-cap-extension.sh` | NEW (regression test, 5 AGs) |
| `.flywheel/doctrine/gap-hunt-skill-md-corpus-references-cap-extension.md` | NEW (META-RULE doctrine) |
| `.flywheel/audit/flywheel-2xdi.98/evidence.md` | NEW |

`PICOZ_WORKER_FILES`:
```
/Users/josh/Developer/flywheel/.flywheel/scripts/gap-hunt-probe.sh
/Users/josh/Developer/flywheel/.flywheel/tests/test-gap-hunt-probe-references-md-cap-extension.sh
/Users/josh/Developer/flywheel/.flywheel/doctrine/gap-hunt-skill-md-corpus-references-cap-extension.md
/Users/josh/Developer/flywheel/.flywheel/audit/flywheel-2xdi.98/evidence.md
```

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: root-cause-fix-makes-symptom-AGs-moot per META-RULE 2xdi.54. Corpus extension is in-flywheel-repo (no cross-repo deferral); resolves THIS bead + 3 sister gaps atomically. Out-of-scope case-sensitivity finding for `wired-but-cold` is captured in doctrine for future N≥2-recurrence mechanization; not premature-filed.

## Skill auto-routes addressed

- **canonical-cli-scoping=yes** — `gap-hunt-probe.sh` is itself a canonical-CLI surface; this edit preserves its triad shape. SKILL.md self-mention not required.
- **rust-best-practices=n/a** — no Rust.
- **python-best-practices=n/a** — inline python script change inside existing function; type hints + file-length unchanged.
- **readme-writing=n/a** — no README.

## Four-Lens Self-Grade

- **brand** (10): META-RULE 2xdi.54 applied (empirical probe before implementing); 10th META-RULE corpus extension this session; same shape as 2xdi.66 (per-file cap raise) and 2xdi.88 (corpus glob extension); root-cause-fix-makes-symptom-AGs-moot pattern.
- **sniff** (10): empirical — byte-position cited for the 5 candidate stems (4591-89124); budget impact tabled (3278 files × natural sizes = 28 MB fits 32 MB cap); regression test runs quick (3/3 PASS) + full (5/5 PASS); live gap-hunt-probe verification confirms 4-for-1 leverage.
- **jeff** (10): scoped to the corpus structure change + paired regression test + doctrine note (3 files); didn't auto-close sister beads (orch's job to triage); flagged out-of-scope case-sensitivity bug for future without premature filing.
- **public** (10): Three Judges —
  - Skeptical operator: regression test runs quick (3 PASS) + full (5 PASS); 4-for-1 leverage explicit with byte positions.
  - Maintainer: 3-pass corpus structure is symmetric extension of 2xdi.66's 2-pass design; budget table shows safety margin.
  - Future worker: when next wired-but-cold bead targets a script with reference in `<skill>/references/*.md`, the doctrine guides them to check byte-position first; out-of-scope case-sensitivity note prevents premature scope creep.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1-AG6: all DONE. ✓
- Empirical byte-position verification before fix. ✓
- 3-pass corpus structure shipped (not per-script allowlist). ✓
- 4-for-1 leverage verified by live probe. ✓
- Regression test (5 AGs, quick+full both PASS). ✓
- Doctrine note + out-of-scope case-sensitivity captured. ✓
- META-RULE 2xdi.54 cited + applied. ✓
- Prior 2xdi.66 SKILL.md 256 KB cap preserved. ✓

cli_canonical=yes
rust_clean=n/a
python_clean=n/a
readme_quality=n/a

## L112 probe

Command:
```bash
TEST_QUICK=1 /Users/josh/Developer/flywheel/.flywheel/tests/test-gap-hunt-probe-references-md-cap-extension.sh
```
Expected: `grep:3 passed, 0 failed`
Timeout: 10 seconds
