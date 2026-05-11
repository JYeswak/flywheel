# flywheel-eq9wv — test-receiver-wire-in-recipe doctrine doc shipped (N=3 trigger fired; Option D chosen)

Bead: flywheel-eq9wv (P2)
Lane: substrate-self-improvement / N=3 recipe-promotion
Sister to: pmg3c (forward-link-doctrine-doc-recipe), r9pri (cluster-maintainer-pattern)
mutates_state: yes (doctrine doc + regression test, both in flywheel.git)

## Decision: Option D (doctrine doc only)

Per bead body decision matrix:
- A. Standalone skill at `~/.claude/skills/test-receiver-wire-in/` — REJECTED (heavyweight; cross-repo)
- B. Auto-route in dispatch packet for `[gap-probe-without-receiver]` class — DEFERRED (depends on doc existing first)
- C. Embed in faqj2 self-calibration taxonomy — REJECTED (creates coupling)
- **D. Doctrine doc only (sister to pmg3c + r9pri pattern) — CHOSEN**

Rationale: sister beads pmg3c (forward-link) and r9pri (cluster-maintainer)
both shipped as **doctrine docs** at `.flywheel/doctrine/`. The pattern is
canonical for N=3+ substrate-self-improvement promotions:

| Recipe | Path | Source bead | N |
|---|---|---|---|
| cluster-maintainer-pattern | `.flywheel/doctrine/cluster-maintainer-pattern.md` | r9pri | 3 |
| forward-link-doctrine-doc-recipe | `.flywheel/doctrine/forward-link-doctrine-doc-recipe.md` | pmg3c | 4 |
| **test-receiver-wire-in-recipe** | `.flywheel/doctrine/test-receiver-wire-in-recipe.md` | **eq9wv (THIS)** | **3** |

Per `feedback_decompose_by_natural_unit_not_bundle`: recipe doc IS the
natural unit. Option B (dispatch-packet auto-injection) is a SEPARATE
mechanization layer — file as sister bead later if N≥1 recurrence
observed within ~1 week.

## N=3 trigger evidence

| # | Bead | Subject | Disposition |
|---|---|---|---|
| 1 | flywheel-2xdi.87 | fleet-canonical-rule-freshness-probe.sh | doctrinally-canonical-but-not-invoked subclass (probe-without-receiver baseline) |
| 2 | flywheel-2xdi.144 | canonical-cli-lint-precommit-installer.sh | flywheel_cli_surface registry allowlist + canonical-CLI test wired |
| 3 | flywheel-2xdi.146 | codex-pane-path-probe.sh | 10/10 PASS test receiver wire-in, double-class clearance |

All 3 verified via `br show` — closed beads.

## Recipe doc contents

`.flywheel/doctrine/test-receiver-wire-in-recipe.md` (170+ lines):

- **TL;DR:** for `[gap-probe-without-receiver]` OR `[gap-wired-but-cold]` beads
  on scripts with canonical-cli surface but no test, write
  `tests/<script>-canonical-cli.sh` exercising N≥5 surface commands.
  Test serves as receiver-evidence under flywheel-2xdi.88
  (`*-canonical-cli*.sh` glob in `test_files_corpus`) + flywheel-2xdi.140
  (wired-but-cold corpus extends to `test_files_corpus`).
  Double-class clearance via single test wire-in.
- **N=3 recurrence threshold:** all 3 trigger beads tabled with dispositions
- **5-step recipe:**
  1. Identify canonical CLI surface (doctor/health/repair triad)
  2. Write test file at canonical path with N≥5 commands + chmod 755
  3. Verify probe re-classification (live gap-hunt-probe --json check)
  4. Commit with double-class-clearance disposition note
  5. `br close` with implicit disposition tag
- **What this is NOT** (4 negatives):
  - Not a substitute for canonical-cli scaffolding (if surface doesn't exist)
  - Not applicable to Jeff Premium skills (per Jeff-substrate AUDIT-ONLY)
  - Not a substitute for cluster-maintainer-pattern (skill-wide doc gaps)
  - Not a substitute for forward-link-doctrine-doc-recipe (memory gaps)
- **When to apply** decision table (6 rows mapping gap-class × surface-state → recipe)
- **Substrate-self-improvement family:** 3-recipe convergence table
- **Cross-references** including source bead, N=3 triggers, receiver-corpus
  extensions, sister recipes, scaffold-canonical-cli, META-RULE doctrine

## Regression test

`.flywheel/tests/test-doctrine-test-receiver-wire-in-recipe.sh` (6 AGs):
- AG1 doc exists at canonical path
- AG2 frontmatter present
- AG3 N=3 precedent beads cited (2xdi.87 + .144 + .146)
- AG4 5-step recipe present
- AG5 receiver-corpus extensions cited (2xdi.88 + .140)
- AG6 sister recipes cross-referenced (cluster-maintainer + forward-link)

Result: **6/6 PASS** (live invocation).

## Acceptance gates (mirrors bead body)

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Choose A/B/C/D with rationale | **DONE** | Option D chosen; sister-doc pattern (pmg3c + r9pri) precedent cited; B deferred as separate sister-mechanization |
| AG2 | Ship per chosen option | **DONE** | doctrine doc at `.flywheel/doctrine/test-receiver-wire-in-recipe.md` (170+ lines, 5-step recipe + decision matrix + cross-refs) |
| AG3 | Document N=3 strike count in resulting surface | **DONE** | "Recurrence threshold (N=3 MET)" section with 3-row precedent table |

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/doctrine/test-receiver-wire-in-recipe.md` | NEW (doctrine doc) |
| `.flywheel/tests/test-doctrine-test-receiver-wire-in-recipe.sh` | NEW (6 AGs) |
| `.flywheel/audit/flywheel-eq9wv/evidence.md` | NEW |

`PICOZ_WORKER_FILES`:
```
/Users/josh/Developer/flywheel/.flywheel/doctrine/test-receiver-wire-in-recipe.md
/Users/josh/Developer/flywheel/.flywheel/tests/test-doctrine-test-receiver-wire-in-recipe.sh
/Users/josh/Developer/flywheel/.flywheel/audit/flywheel-eq9wv/evidence.md
```

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: P2 mission-bead shipped (doctrine doc + regression test). Option B (dispatch-packet auto-injection sister to inject-forward-link-recipe.sh) deferred — file as sister bead when N≥1 recurrence observed (let the next gap-probe-without-receiver dispatch surface the need empirically).

## Skill auto-routes addressed

- **canonical-cli-scoping=n/a** — doctrine doc, not CLI surface.
- **rust-best-practices=n/a** — no Rust.
- **python-best-practices=n/a** — no Python.
- **readme-writing=n/a** — doctrine, not README.

## Four-Lens Self-Grade

- **brand** (10): sister-doctrine pattern (pmg3c + r9pri) replicated faithfully; Option D rationale explicit + 3 other options addressed with rejection reasoning; substrate-self-improvement family convergence (3 recipes) documented.
- **sniff** (10): empirical 3-bead precedent verified via `br show`; receiver-corpus extension citations (2xdi.88 + 2xdi.140) load-bearing; regression test 6/6 PASS.
- **jeff** (10): scoped to doctrine + paired regression test (3 files); did NOT auto-file Option B sister bead (let recurrence drive); did NOT pile on skill-creation overhead (Option A rejected).
- **public** (10): Three Judges —
  - Skeptical operator: 5-step recipe is copy-paste-runnable with concrete code block; 6-row decision matrix tabled.
  - Maintainer: 3-recipe family convergence table; what-this-is-NOT enumerated (4 negatives).
  - Future worker: when next `[gap-probe-without-receiver]` arrives, the recipe is canonical 5 steps; cross-references guide which sister recipe applies for adjacent classes.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1-AG3: all DONE. ✓
- Option D rationale explicit per sister-doc precedent. ✓
- N=3 strike count documented in doc. ✓
- 5-step recipe + 4 negatives + decision matrix + family-convergence table. ✓
- Regression test 6/6 PASS. ✓
- Substrate-self-improvement family convergence captured. ✓

cli_canonical=n/a
rust_clean=n/a
python_clean=n/a
readme_quality=n/a

## L112 probe

Command:
```bash
bash /Users/josh/Developer/flywheel/.flywheel/tests/test-doctrine-test-receiver-wire-in-recipe.sh
```
Expected: `grep:6 passed, 0 failed`
Timeout: 30 seconds
