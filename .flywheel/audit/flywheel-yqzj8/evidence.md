# Evidence Pack — flywheel-yqzj8

**Bead:** flywheel-yqzj8 — `[decision-tree-coverage-gap] held-stash decision tree step 2 — extend binary-class semantically to substrate-runtime ledgers (alps-held-stash-triage-v1 surface)`
**Identity:** MagentaPond | **Pane:** flywheel:0.3 | **Date:** 2026-05-11

## Disposition: AG1 + AG2 SHIPPED; AG3 deferred to orch (cross-orch ratification is orch-class)

This bead has 3 acceptance gates:
- AG1: `git-stash-discipline.md` decision tree updated with explicit artifact-class definition (binary OR substrate-runtime ledger)
- AG2: substrate-runtime ledger list canonicalized in doctrine appendix
- AG3: ratification cross-orch (next sister-orch tick)

Worker-tick scope ships AG1 + AG2 (doctrine fold-in). AG3 is naturally orch-class (cross-orch dispatch is forbidden from `/flywheel:worker-tick` per the contract); the doctrine update IS the artifact the orch will dispatch for ratification.

did=2/3 (AG1 ✓, AG2 ✓, AG3 deferred-orch-class)

## What shipped

`.flywheel/doctrine/git-stash-discipline.md` extended (122 lines → ~210 lines) with:

### NEW section: "Held-stash triage decision tree (held-stash class)"

7-step decision tree (table form):

1. SUPERSEDED — reverse-apply test passes
2. **ARTIFACT-CLASS — binary OR substrate-runtime ledger (NEW per this bead)**
3. FOLD-INTO-BEAD — open bead reference
4. HISTORY-PRESERVE — closed bead reference
5. ALTERNATE-IMPL — alternate code path
6. ABANDONED — unverifiable against HEAD
7. ESCALATE-TO-JOSHUA — substantive content; preserve

Step 2 firing BEFORE step 3 (FOLD-INTO-BEAD) is documented with the alps `adf00c4b` exemplar (6 PNG screenshots whose stash message contained a bead-id-shape but binary-only wins).

### NEW appendix: artifact-class canonical definition

Two classes folded into ARTIFACT-CLASS:

**Binary class (literal binary content):** images, archives, hypothesis cache, playwright artifacts, OS noise, language bytecode, build cache (9 enumerated patterns).

**Substrate-runtime ledger class (regenerable runtime state, NEW per this bead):**
- `.beads/issues.jsonl` (regenerable from `.beads/issues.db` via `br sync --import-only`)
- `.beads/issues.db`, `.beads/*.wal`, `.beads/*.shm` (SQLite runtime)
- `.ntm/rate_limits.json` (ntm runtime rate-limit state)
- `.flywheel/dispatch-log.jsonl` (append-only audit trail)
- `.flywheel/lock-log.jsonl` (lock-acquisition audit trail)
- `.flywheel/STATE.md` (orch tick state snapshot)
- `.flywheel/runtime/**` (tick-runtime scratch)
- `.flywheel/state/scaffold-runs.jsonl` (scaffolder runtime ledger)
- `.flywheel/validation-learn-ledger.jsonl` (validation history ledger)
- `.cass/**`, `.socraticode/**` (top-level runtime cache dirs)
- `~/.local/state/flywheel/**` (out-of-repo by design; mentioned for completeness)

**Decision rule for ambiguous cases:** if regenerable from authoritative sources AND not in-flight worker thought → ARTIFACT-CLASS; if IS the authoritative source (code, doctrine, test, fixture) → fall through to step 3.

### NEW: verdict-class canonical labels

7 labels (one per decision-tree step) for use in evidence packs + stash-archive bundle metadata:
SUPERSEDED, ARTIFACT-CLASS, FOLD-INTO-BEAD, HISTORY-PRESERVE, ALTERNATE-IMPL, ABANDONED, ESCALATE-TO-JOSHUA. Bundle byte-equality recovery preserved for ALTERNATE-IMPL + ABANDONED + ESCALATE-TO-JOSHUA.

### NEW: substrate-discovery citation

Cites:
- alps-held-stash-triage-v1 execution 2026-05-10T18:33Z (MistyCliff) — surfacing event
- alpsinsurance triage report at `.flywheel/audit/2026-05-10-held-stash-triage/report.md` — exemplar
- This bead `flywheel-yqzj8` — doctrine ratification
- AG3 cross-orch ratification — explicitly deferred to orch tick

## AG receipt

| AG | Status | Evidence |
|---|---|---|
| AG1 — decision tree updated with explicit artifact-class definition | DONE | `.flywheel/doctrine/git-stash-discipline.md` "Held-stash triage decision tree" section (NEW) |
| AG2 — substrate-runtime ledger list canonicalized | DONE | "Artifact-class definition (appendix)" section enumerates 11 substrate-runtime ledger paths + decision rule |
| AG3 — cross-orch ratification | DEFERRED to orch | worker-tick contract forbids cross-orch dispatch; doctrine update is the dispatch-ready artifact |

did=2/3

## Traceability — alps surfacing → flywheel doctrine

The bead body cites the surfacing chain:

> Triage execution found 4-of-15 held stashes were single-file substrate-runtime ledgers (`.beads/issues.jsonl`, `.ntm/rate_limits.json`) — not literally binary, but same 'shouldn't have been stashed' intent. Routed under semantic-extension reading; flagged for doctrine clarification.

The flywheel doctrine fold-in canonicalizes that semantic extension as the artifact-class definition + enumerates the substrate-runtime ledger paths. The decision rule ("regenerable AND not in-flight worker thought") preserves the spirit while removing the "binary literal vs semantic" ambiguity that prompted the bead.

## Skill Auto-Routes

| Skill | Status | Evidence |
|---|---|---|
| canonical-cli-scoping | n/a | doctrine fold-in only |
| rust-best-practices | n/a | markdown only |
| python-best-practices | n/a | markdown only |
| readme-writing | n/a | doctrine, not README |

## Compliance Score

| Dimension | Points | Evidence |
|---|---|---|
| AG1 — decision tree explicit | 250/250 | 7-step table with first-match-wins ordering |
| AG2 — substrate-runtime ledger canonical list | 250/250 | 11 paths + decision rule |
| Step-2-firing-before-step-3 rationale | 100/100 | alps adf00c4b exemplar cited |
| Verdict-class canonical labels | 100/100 | 7 labels + bundle recovery contract |
| Substrate-discovery citation | 100/100 | alps surfacing + report exemplar + bead ratification chain |
| AG3 honest deferral (orch-class) | 100/100 | did=2/3 with explicit deferral note |
| Boundary preservation (worker-time discipline retained) | 50/50 | NO modification to existing worker/orch responsibility sections; pure additive fold-in |
| Receipt + evidence pack | 50/50 | this document |
| **TOTAL** | **1000/1000** | |

`compliance_score=1000/1000`

## L112 Verify Probe

```bash
grep -c 'substrate-runtime ledger\|ARTIFACT-CLASS\|.beads/issues.jsonl' .flywheel/doctrine/git-stash-discipline.md
```
Expected: `grep:>= 5` (multiple mentions confirm the fold-in landed). Timeout 30s.
