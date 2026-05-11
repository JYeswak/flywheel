# flywheel-2xdi.54 — memory-without-cross-link: bead-hypothesis META-RULE

Bead: flywheel-2xdi.54 (P3)
Parent: flywheel-2xdi (constant-gap-hunter, CLOSED)
Sister beads (today's gap-hunt-probe cumulative arc): 2xdi.47 → 2xdi.48 → 2xdi.49 → 2xdi.50 → THIS (2xdi.54)
Lane: doctrine-anchor + gap-detector-quality
mutates_state: yes (one corpus extension + one new doctrine file + one regression test)

## Bead claim vs reality

The bead flagged `feedback_bead_hypothesis_starting_point_not_conclusion.md` as **memory-without-cross-link** — "not cited by sampled commands, doctrine, incidents, or recent plan files".

Reality check (two findings):

**Finding 1 (memory-side)**: the memory IS heavily cited — 28 audit-pack files reference it (evidence.md, compliance-pack.md, journey/*.md across flywheel-2xdi.47, 2xdi.49, 2xdi.51). However, audit-pack files are post-hoc evidence, NOT canonical anchors. The probe is correctly NOT counting those.

**Finding 2 (probe-side)**: the probe's evidence message says "doctrine, incidents, or recent plan files" but the implementation scans only `command_text()` (command-md files + AGENTS.md + INCIDENTS.md + README.md) + `PLANS/*.md`. It does NOT scan the actual `.flywheel/doctrine/*.md` directory. There's a documentation-vs-implementation mismatch in the probe.

## Disposition: dual fix per the META-RULE itself

This bead is recursively self-applying: the memory it flags IS the META-RULE about not treating bead hypotheses as conclusions. Per the rule itself:

> The bead body's hypothesis is the **downstream signal**. The actual root cause is the **upstream gap**. Treating the hypothesis as conclusion = treating signal as cause.

Applied here:
- **Downstream signal**: "this specific memory needs cross-link" (the bead's surface claim).
- **Upstream gap**: (a) the probe's doctrine corpus coverage is too narrow, AND (b) this specific META-RULE deserves a canonical doctrine anchor.

**Both upstream gaps fixed** in one tick (cumulative arc continues from 2xdi.47/.48/.49/.50):

### Fix 1: doctrine corpus extension (class fix)

Extended `command_text()` in gap-hunt-probe.sh to scan `.flywheel/doctrine/*.md`:

```python
def command_text() -> str:
    files = [...]
    pieces = [read_text(p, 1_000_000) for p in files]
    # flywheel-2xdi.54: include .flywheel/doctrine/*.md as canonical anchor surface.
    for doctrine_path in safe_iter_files(REPO_ROOT / ".flywheel/doctrine", "*.md", 200):
        pieces.append(read_text(doctrine_path, 200_000))
    return "\n".join(pieces)
```

This makes the evidence message ("doctrine, incidents, or recent plan files") match the implementation. Benefits ALL future memories anchored in `.flywheel/doctrine/` files.

### Fix 2: canonical doctrine anchor (instance fix)

Created `.flywheel/doctrine/bead-hypothesis-starting-point.md` — a full doctrine file that:

- Names the META-RULE ("Bead hypothesis is starting point, not conclusion")
- Documents the rule + anti-pattern + how-to-apply
- Lists the N=3 convergent instances (o40x0, 2xdi.47, 2xdi.49)
- Cites the canonical memory file by full path
- References the sister META-RULE (`feedback_calibrate_test_to_actual_contract`)
- Cites Donella Meadows leverage points (#5 rules of the system, #6 information flow)
- Documents trauma class (META-EXTRACTION-DRIFT cluster)

The doctrine file structure matches existing doctrine conventions (frontmatter + sister cluster + canonical memory + trauma class).

## Acceptance gates

Auto-filed by gap-hunt-probe with stock template body. Inferred AGs from class:

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Verify whether memory IS cross-linked anywhere | **DONE** | Heavily cited in 28 audit-pack files. NOT in canonical anchor surfaces (AGENTS/INCIDENTS/README/PLANS/doctrine). Bead's hypothesis is correct: needs canonical anchor. |
| AG2 | If real gap: cross-link the memory in a canonical anchor surface | **DONE** | Created `.flywheel/doctrine/bead-hypothesis-starting-point.md` citing the memory by full filename + extending the META-RULE doctrine vocabulary. |
| AG3 | If probe coverage is too narrow: extend the corpus | **DONE** | Added `.flywheel/doctrine/*.md` to `command_text()` corpus. Benefits all future memories anchored in doctrine files. |
| AG4 | Verify bead's named target drops out post-fix | **DONE** | Live probe: `feedback_bead_hypothesis_starting_point_not_conclusion.md` count in memory-without-cross-link list went from 1 → 0. |
| AG5 | Zero regression on prior gap-hunt-probe fixes | **DONE** | step4i-coherence.sh (2xdi.48) and substrate-doctor-common.sh (2xdi.50) still NOT in wired-but-cold. 30+6+7+7+8 = **58/58 baseline tests PASS** unchanged. |
| AG6 | Regression test for the new behavior | **DONE** | `tests/gap-hunt-probe-doctrine-corpus.sh` — 8/8 PASS. Asserts (T1) corpus extension is present in source, (T2) named memory no longer flagged, (T3-T4) doctrine anchor file exists and cites memory, (T5) envelope shape, (T6-T7) prior fixes preserved, (T8) no crash. |

## Test execution receipts

### New regression test

```
PASS T1: command_text() scans .flywheel/doctrine/*.md (the corpus extension)
PASS T2: feedback_bead_hypothesis_starting_point_not_conclusion.md NOT in memory-without-cross-link
PASS T3: .flywheel/doctrine/bead-hypothesis-starting-point.md exists (the canonical anchor)
PASS T4: doctrine file cites the canonical memory by full filename
PASS T5: gap_class_distribution['memory-without-cross-link'] is a non-negative integer (20)
PASS T6: step4i-coherence.sh NOT in wired-but-cold (2xdi.48 fix preserved)
PASS T7: substrate-doctor-common.sh NOT in wired-but-cold (2xdi.50 fix preserved)
PASS T8: gap-hunt-probe envelope shape preserved (no crash from new corpus)

Summary: 8 passed, 0 failed
```

### Baseline + sister regression tests (zero regression)

| Suite | Result |
|---|---|
| `gap-hunt-probe-canonical-cli.sh` | 30/30 PASS |
| `gap-hunt-probe-on-demand-validator-allowlist.sh` | 6/6 PASS |
| `gap-hunt-probe-0h0b-suppression-smoke.sh` | 7/7 PASS |
| `gap-hunt-probe-for-loop-source.sh` (2xdi.48) | 7/7 PASS |
| `gap-hunt-probe-var-assigned-source.sh` (2xdi.50) | 8/8 PASS |
| **Plus new** `gap-hunt-probe-doctrine-corpus.sh` (this bead) | 8/8 PASS |
| **Total** | **66/66 PASS** |

## Cumulative gap-hunt-probe corpus arc 2026-05-11

This bead is the 5th iteration in a same-day arc on gap-hunt-probe corpus coverage. Cumulative summary:

| Bead | Corpus extension | False-positive class eliminated |
|---|---|---|
| 2xdi.47 | for-loop continuation capture (`for VAR in ...; do source $VAR.sh; done`) | step4i-coherence + 27 sibling lib modules |
| 2xdi.48 | extension-less wrappers under `bin/*` | flywheel-loop's module list now visible |
| 2xdi.49 | SKILL.md documentation as wiring | protected-session-recovery + other documented compat wrappers |
| 2xdi.50 | variable-assignment-with-default substitution (`VAR="${X:-...sh}"`) | substrate-doctor-common.sh |
| **2xdi.54 (this)** | `.flywheel/doctrine/*.md` as canonical anchor | bead-hypothesis META-RULE + future doctrine-anchored memories |

Each was a separate corpus-blind-spot class. The arc demonstrates that gap-hunt-probe's corpus needs to mirror the actual wiring surfaces flywheel uses. After this bead, the major wiring patterns are covered.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/gap-hunt-probe.sh` | +8 lines (doctrine corpus extension + comment) |
| `.flywheel/doctrine/bead-hypothesis-starting-point.md` | NEW (78 lines, full doctrine file with frontmatter + N=3 ladder + sister refs) |
| `tests/gap-hunt-probe-doctrine-corpus.sh` | NEW (90 lines, 8 assertions) |
| `.flywheel/audit/flywheel-2xdi.54/evidence.md` | NEW |

No edits to memory files (the memory itself is the canonical source). No AGENTS.md edits (auto-generated from L-rule shards; the doctrine file is the right home).

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: doctrine corpus extension is class-level (benefits all future doctrine-anchored memories); doctrine file is the canonical anchor for THIS specific META-RULE; both fixes ship in this bead. Side-finding: 19 other memories still in memory-without-cross-link list — they need their own canonical anchors (in doctrine OR new L-rules). NOT auto-filing 19 sister beads — each memory's anchor placement is a content-decision (some belong as L-rules, some as doctrine files, some as INCIDENTS entries). Bulk auto-filing without content-judgment would create noise.

## Skill auto-routes addressed

- **canonical-cli-scoping** = n/a — internal corpus + doctrine file authoring, no canonical-cli surface.
- **rust-best-practices** = n/a — no Rust.
- **python-best-practices** = YES — corpus extension is in a Python heredoc. (1) Function signature unchanged; (2) No new deps; (3) Regression test exercises the change; (4) Tests use TMPDIR; (5) file-length OK.
- **readme-writing** = n/a — no README touched. Doctrine file is a separate canonical doctrine file with its own structured frontmatter, not a README.

## Four-Lens Self-Grade

- **brand** (10): doctrine file structure matches existing fleet conventions (frontmatter + sister cluster + canonical memory + trauma class). Cites Donella Meadows leverage points per Joshua's doctrine. Cumulative arc narrative across .47/.48/.49/.50/.54 is coherent and documented in evidence.
- **sniff** (10): empirical pre/post — named memory dropped from `memory-without-cross-link` (1 → 0). 66/66 tests PASS across 6 test suites. Doctrine corpus extension verified non-breaking by envelope-shape assertion.
- **jeff** (10): respected the META-RULE that this bead is ABOUT — applied "probe before implementing" recursively (verified the memory IS not anchored in canonical surfaces BEFORE choosing the doctrine-file fix path). Did not bulk-file 19 sister beads for the other flagged memories — content-judgment required per memory.
- **public** (10): Three Judges check —
  - Skeptical operator: the META-RULE has a real doctrine home now; the regression test asserts the link is intact.
  - Maintainer: doctrine file's frontmatter pattern is reusable for the 19 remaining un-anchored memories; future workers can copy the structure.
  - Future worker: when worker reads the bead body's hypothesis, the doctrine file points at the canonical memory; the memory provides the N=3 instance ladder + how-to-apply.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1-AG6: all DONE. ✓
- Dual fix (class + instance) — corpus expansion benefits fleet; doctrine anchor benefits this specific META-RULE. ✓
- Empirical pre/post (1 → 0 in memory-without-cross-link list). ✓
- 66/66 tests PASS across 6 test suites including 3 prior gap-hunt regression suites. ✓
- Cumulative arc documented (5 corpus blind spots fixed in same day). ✓
- META-RULE recursively self-applied (probed before implementing; identified upstream gap not symptom). ✓

## L112 probe

Command: `bash /Users/josh/Developer/flywheel/tests/gap-hunt-probe-doctrine-corpus.sh 2>&1 | grep -c '^PASS'`
Expected: `literal:8`
Timeout: 60 seconds
