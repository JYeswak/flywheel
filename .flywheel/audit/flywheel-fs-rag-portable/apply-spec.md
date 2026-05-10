---
title: fs-rag-discipline portable via flywheel-install + daily-ops wire-in
type: apply-spec
created: 2026-05-10
bead: flywheel-fs-rag-portable
parent: flywheel-s8tdd (closed)
chain: doctor-mode-integration / fs-rag-discipline
leverage_points:
  - "#4 self-organization (template = paradigm carrier)"
  - "#6 information flow (daily rollup = drift visibility)"
---

# fs-rag-discipline portable via flywheel-install + daily-ops wire-in

Joshua signoff 2026-05-10 (Meadows-lens reframe of the original 6-bead
cross-repo propagation): replaces 6 per-repo followup beads with ONE
bead that closes the structural gap at higher leverage.

## Goal

Move the fs-rag-discipline (linter + scaffolder + hook + doctrine) from
flywheel-internal substrate to **portable flywheel-install template
substrate** — so:

1. Any NEW repo that runs `flywheel-install` automatically inherits the
   discipline (paradigm-level fix; #4 self-organization).
2. Any EXISTING flywheel-installed repo that runs `flywheel-install --update`
   gets the discipline retroactively + baseline + initial backfill.
3. The daily-ops fleet rollup (shipped this morning via lb2gk → u2yc0)
   surfaces per-repo violation counts daily — drift becomes visible the
   morning after it happens (#6 information flow).

This is the structural counterpart to canonical-cli-helpers being a
runtime contract. fs-rag-discipline becomes the at-rest contract for
ALL flywheel-installed repos, not just flywheel-the-repo.

## Scope

### AG1: move artifacts to flywheel-install template

Copy (not move — flywheel itself keeps live copies as the canonical
reference impl):

| Source (flywheel-internal) | Template destination |
|---|---|
| `.flywheel/scripts/file-rag-discipline-lint.sh` | `templates/flywheel-install/scripts/file-rag-discipline-lint.sh` |
| `.flywheel/scripts/scaffold-doc-frontmatter.sh` | `templates/flywheel-install/scripts/scaffold-doc-frontmatter.sh` |
| `.flywheel/hooks/file-rag-discipline-pre-commit.sh` | `templates/flywheel-install/hooks/file-rag-discipline-pre-commit.sh` |
| `.flywheel/doctrine/filesystem-as-rag.md` | `templates/flywheel-install/doctrine/filesystem-as-rag.md` |
| `tests/file-rag-discipline-lint.sh` | `templates/flywheel-install/tests/file-rag-discipline-lint.sh` |

Verify the moved artifacts are repo-path agnostic (they should be —
they accept `--scan-all` and resolve from CWD; if any hardcoded paths
exist, fix in this bead).

### AG2: extend flywheel-install installer

Update `templates/flywheel-install/install.sh` (or the canonical
flywheel-install entrypoint, whichever it is — discover via
`grep -r 'flywheel-install' .flywheel/scripts/`) to:

1. On fresh install: copy the 5 template files into `.flywheel/{scripts,hooks,doctrine,tests}/`
2. Install the pre-commit hook into `.git/hooks/pre-commit` (or chain
   with existing) — gate on F1 + F4 errors only
3. Run baseline scan: `file-rag-discipline-lint.sh --scan-all --json > .flywheel/audit/fs-rag-baseline-<install-date>.json`
4. Run initial F1 backfill on `.flywheel/doctrine/`, `.flywheel/PLANS/`
   (if present) — but DON'T touch user-authored content outside .flywheel/
5. Add to install receipt: `fs_rag_discipline: installed`

For `--update` mode (existing flywheel-installed repos):
- Compare existing artifacts to template; apply diff if drift detected
- Re-run baseline scan + emit delta JSON (before vs after)
- Skip backfill if previously run (idempotency receipt:
  `.flywheel/audit/fs-rag-backfill-applied.json`)

### AG3: install on 6 sibling repos

After AG1+AG2 ship, run the installer on:
- `~/Developer/alpsinsurance` (alps)
- `~/Developer/mobile-eats`
- `~/Developer/skillos`
- `~/Developer/vrtx`
- `~/Developer/picoz` (or polymarket-pico-z, whichever is canonical)
- `~/Developer/zesttube`

Per-repo:
1. Verify `.flywheel/` exists (skip if not — record `flywheel_not_installed: true`)
2. Run `flywheel-install --update --apply-fs-rag --idempotency-key fs-rag-rollout-2026-05-10`
3. Capture baseline + post-backfill JSON deltas
4. Aggregate into `.flywheel/audit/flywheel-fs-rag-portable/sibling-rollout-2026-05-10.json`

If a repo install fails (e.g., uncommitted changes block), record the
class and continue. Don't halt rollout for one repo.

### AG4: daily-ops fleet rollup wire-in

Update `.flywheel/scripts/fleet-daily-rollup.py` (the daily-ops aggregator)
to:
1. Read each repo's `fs-rag-baseline-<latest-date>.json` (or run live
   `--scan-all` if no recent baseline)
2. Aggregate violation counts per repo into the daily rollup
3. RED FLAG when:
   - Any repo's F1+F4 violation count INCREASED since previous day
     (drift detection)
   - Any repo's total violations >2× the fleet median
4. Add to fleet-rollup top-line: `fs_rag_discipline: avg=X, fleet_max=Y@<repo>, drift_alerts=N`

### AG5: launchd plist

The daily-ops plists already run at 08:30 (post per-repo at 08:00).
Verify the rollup includes fs-rag stats; if not, add a sibling
fs-rag-rollup plist that runs at 08:35.

### AG6: cross-orch handoff

Ship a brief handoff to skillos:1 (NIGHTHAWK) noting that fs-rag-discipline
is now installable via flywheel-install. They can opt in via
`flywheel-install --update --apply-fs-rag` if they want the same
substrate.

### AG7: receipt

Write `.flywheel/audit/flywheel-fs-rag-portable/evidence.md`:
- Template artifacts shipped (5 files)
- Installer extension diff
- Sibling rollout summary (6 repos × {installed | skipped | failed})
- Aggregate fleet baseline (sum of violations across all flywheel-installed repos)
- Daily-ops wire-in proof (next morning's rollup includes fs_rag stats)
- Handoff sent to skillos:1

## Boundary

- Template artifacts are COPIES of flywheel's, not moves. Flywheel keeps
  the canonical reference; template is the propagation vehicle.
- Sibling rollout is `--apply` (not dry-run) but uses idempotency-key
  for safety. If any sibling repo has uncommitted changes, skip rather
  than mutate.
- Wave-2 backfill (the remaining 844 F1 violations in flywheel + similar
  per-sibling-repo) is OUT OF SCOPE — that's parameter-level work that
  the daily-ops rollup will surface as drift signals over time.
- Doesn't touch sibling repo's non-`.flywheel/` content. Their docs
  outside `.flywheel/` are owned by the sibling team's structural
  discipline.

## Acceptance gate

- 5 template artifacts exist in `templates/flywheel-install/`
- `flywheel-install --apply-fs-rag` works on a fresh repo (smoke)
- `flywheel-install --update --apply-fs-rag` works on existing repo (smoke)
- 6 sibling repos either: installed cleanly OR explicitly recorded as
  skipped/failed with reason class
- Daily-ops fleet rollup includes `fs_rag_discipline` block
- Handoff to skillos:1 sent + committed
- Pre-commit hook reaches all sibling repos that installed cleanly

## Estimated effort

~2-3 hours total:
- AG1 (move artifacts): 15 min
- AG2 (extend installer): 45 min
- AG3 (run on 6 siblings): 30 min (mostly running scripts)
- AG4 (daily-ops wire): 30 min
- AG5 (launchd verify): 10 min
- AG6 (handoff): 10 min
- AG7 (receipt): 20 min

## Dependencies

- jloib.0a/0b/0c/0d (canonical-cli tooling chain) — CLOSED
- s8tdd (fs-rag-discipline base ship) — CLOSED
- daily-ops fleet rollup (lb2gk + u2yc0) — operational
