# flywheel-2xdi.96 — MOOT-BY-PARALLEL-FIX (xhevf landed before this bead's dispatch)

Bead: flywheel-2xdi.96 (P3)
Parent: flywheel-2xdi (constant-gap-hunter)
Filed-by: gap-hunt-probe auto-bead (wired-but-cold class)
Lane: audit-only / parallel-fix-mooted
mutates_state: no (no code mutation; AUDIT-ONLY close documenting the moot-by-parallel-fix pattern)

## Bead hypothesis vs reality (META-RULE 2xdi.54 applied)

**Hypothesis (bead body):**
> `.claude/skills/agent-ergonomics-and-intuitiveness-maximization-for-cli-tools/scripts/diff_test.sh`
> emits probe output but is not referenced by recent flywheel jsonl ledgers
> (wired-but-cold class).

**Reality (after probing):** The hypothesis is now FALSE. A parallel fix
(flywheel-xhevf, commit 434f88b, 2026-05-11 03:57:48 -0600) landed BEFORE this
bead was dispatched and added `scripts/diff_test.sh` to the
`agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools/SKILL.md`
scripts/ table at line 640. The gap-hunt-probe `skill_md_corpus()` now catches
the basename, so `wired-but-cold` no longer flags it.

## Empirical verification

```bash
# (1) xhevf patch hunk that added diff_test to SKILL.md:
grep 'diff_test' .flywheel/audit/flywheel-xhevf/patches/SKILL.md.patch
#   +| `scripts/diff_test.sh` | Differential idempotency test ...

# (2) post-xhevf SKILL.md confirms presence:
grep -n 'diff_test' ~/.claude/skills/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools/SKILL.md
#   640:| `scripts/diff_test.sh` | Differential idempotency test ...

# (3) pre-xhevf SKILL.md.original did NOT mention diff_test:
grep -c 'diff_test' .flywheel/audit/flywheel-xhevf/patches/SKILL.md.original
#   0

# (4) live gap-hunt-probe post-fix: zero diff_test hits in wired-but-cold class:
.flywheel/scripts/gap-hunt-probe.sh --json | python3 -c "..."
#   diff_test hits: []
#   wired-but-cold count: 20 (none are diff_test)
```

## Wired-but-cold detector check (gap-hunt-probe.sh:1188-1210)

A script is wired-but-cold iff its basename or stem is absent from ALL FIVE corpora:

| Corpus | Match for diff_test (post-xhevf) |
|---|---|
| recent_ledger_text (local flywheel jsonl) | NO (correctly — it's on-demand) |
| sibling_repo_ledger_corpus | NO |
| runtime_source_corpus | NO (executable, not sourced) |
| **skill_md_corpus** | **YES — line 640 of agent-ergonomics SKILL.md (post-xhevf)** |
| launchd_plist_corpus | NO |

The skill_md_corpus hit is sufficient to clear wired-but-cold.

## Timeline reconstruction

| Time | Event |
|---|---|
| 2026-05-11 03:57 | flywheel-xhevf commit 434f88b — adds 21-row scripts/ table extension including `scripts/diff_test.sh` to agent-ergonomics SKILL.md |
| 2026-05-11 ~04:00 | flywheel-b6p1m commit d6f868c — chains 10-row tools/ table extension |
| 2026-05-11 (later) | gap-hunt-probe ran with stale state OR the corpus cache didn't yet reflect the new SKILL.md content; auto-filed 2xdi.96 against diff_test |
| 2026-05-11 (this dispatch) | Worker re-probes → bead claim is MOOT |

## New pattern surfaced (skill discovery candidate)

**Pattern:** "Auto-filed gap beads can become MOOT via parallel substrate work
between gap-hunt filing time and worker dispatch time."

Mitigation options (out of scope for this bead — captured for future
gap-hunt-probe maintainer beads):

1. Re-probe gap subject AT DISPATCH TIME (this is what META-RULE 2xdi.54
   already prescribes — probe before implementing — applied here)
2. Auto-defer / auto-close gap beads when the underlying gap can no longer be
   reproduced (currently the operator/worker does this manually; could be
   automated as a value-add)
3. Note in dispatch packet: include current gap-hunt --json hit count for the
   bead's subject; if 0, route to auto-audit-only close

This is the **2nd MOOT-BY-PARALLEL-FIX class** observed this session (sister
to 2xdi.88's 2-for-1 retroactive resolution of 2xdi.90).

## Acceptance gates

Bead body has no explicit AC list (auto-filed gap bead, title-only description).
Inferred AGs:

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Verify the bead's wired-but-cold hypothesis empirically | **DONE** | 5-corpora check applied; skill_md_corpus matches diff_test via xhevf patch. |
| AG2 | If real wire-gap: file fix; if moot: document why | **DONE (moot disposition)** | xhevf commit 434f88b cited; pre/post grep confirms diff_test was added today by the unrelated scripts/ table extension. |
| AG3 | Verify post-fix: gap-hunt-probe no longer flags the subject | **DONE** | Live `gap-hunt-probe --json` returns 0 diff_test hits in wired-but-cold class. |
| AG4 | Document the moot-by-parallel-fix pattern for future workers | **DONE** | This evidence pack documents the timeline + pattern + 3 mitigation options for future gap-hunt-probe maintainer beads. |

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/audit/flywheel-2xdi.96/evidence.md` | NEW (this file) |

No code mutation. No new beads filed. No cross-repo edits. AUDIT-ONLY close.

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: bead is moot-by-parallel-fix (xhevf commit 434f88b already added diff_test to skill_md_corpus). The 3 mitigation options for the moot-by-parallel-fix pattern (re-probe at dispatch, auto-defer, dispatch-packet-hit-count) are gap-hunt-probe maintainer concerns; filing a follow-up bead here would be premature — let the pattern recur N≥2 more times before mechanizing. Sister observation 2xdi.88 already demonstrates the pattern shape; this is N=2 evidence.

## Skill auto-routes addressed

- **canonical-cli-scoping=n/a** — no CLI surface authored; AUDIT-ONLY disposition.
- **rust-best-practices=n/a** — no Rust touched.
- **python-best-practices=n/a** — no Python touched.
- **readme-writing=n/a** — no README touched.

## Four-Lens Self-Grade

- **brand** (10): META-RULE 2xdi.54 applied (probe before implementing); identified moot-by-parallel-fix early; didn't ship redundant fix or per-script allowlist; documented the new pattern for future maintainers; cited the specific commit (434f88b) and line number (SKILL.md:640) that resolved the gap.
- **sniff** (10): empirical 5-corpora membership check; pre/post grep on SKILL.md.original vs current; live gap-hunt-probe --json invocation confirms zero diff_test hits; xhevf commit timestamp cited.
- **jeff** (10): scoped to audit + close (no code mutation when none is needed); flagged the moot-by-parallel-fix pattern for observation but did NOT file premature maintainer bead (N=2 evidence is signal, not yet mechanization trigger).
- **public** (10): Three Judges —
  - Skeptical operator: reproducible verification commands provided; commit SHA + line number cited.
  - Maintainer: timeline reconstruction shows exactly WHY the bead was correctly filed at gap-hunt time but is now moot.
  - Future worker: explicit "new pattern surfaced" section + 3 mitigation options for if the pattern recurs.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1-AG4: all DONE. ✓
- Bead hypothesis empirically tested (META-RULE 2xdi.54). ✓
- Moot disposition documented with timeline + commit cite. ✓
- Live gap-hunt-probe verification post-fix. ✓
- New pattern surfaced for future maintainer observation. ✓

cli_canonical=n/a
rust_clean=n/a
python_clean=n/a
readme_quality=n/a

## L112 probe

Command:
```bash
.flywheel/scripts/gap-hunt-probe.sh --json 2>/dev/null | python3 -c '
import sys, json
d = json.load(sys.stdin)
ids = d.get("gap_ids", [])
hits = [g for g in ids if "diff_test" in g and "wired-but-cold" in g]
print("hit_count:", len(hits))
' | grep -q "hit_count: 0" && echo gap_resolved || echo gap_persists
```
Expected: `literal:gap_resolved`
Timeout: 60 seconds (gap-hunt-probe takes ~40s)
