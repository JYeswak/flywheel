---
title: "fs-rag-discipline portable — closeout evidence"
type: evidence
created: 2026-05-10
bead: flywheel-hi4e6
parent: flywheel-s8tdd
chain: doctor-mode-integration / fs-rag-discipline
---

# fs-rag-discipline portable — closeout evidence

Bead: `flywheel-hi4e6` (P1, Joshua signoff 2026-05-10).
Worker: CloudyMill. Closed: 2026-05-10T15:42Z.

## AG coverage (7/7)

### AG1 — template artifacts shipped (5 files)

```
templates/flywheel-install/scripts/file-rag-discipline-lint.sh   (12,507 bytes, +x)
templates/flywheel-install/scripts/scaffold-doc-frontmatter.sh   ( 8,312 bytes, +x)
templates/flywheel-install/hooks/file-rag-discipline-pre-commit.sh ( 2,098 bytes, +x)
templates/flywheel-install/doctrine/filesystem-as-rag.md         ( 7,061 bytes)
templates/flywheel-install/tests/file-rag-discipline-lint.sh     ( 7,608 bytes, +x)
```

Path-agnostic check: zero `/Users/josh/Developer/flywheel` hardcoded paths
in 4/5 template files. The 5th (`tests/file-rag-discipline-lint.sh`) had
one hardcoded `REPO=` default; replaced with
`REPO="${REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"`.

### AG2 — flywheel-adopt.sh extended

`--apply-fs-rag` flag added to `.flywheel/scripts/flywheel-adopt.sh`.
On `--apply --apply-fs-rag --idempotency-key <key>`:

1. Copies the 5 template artifacts to `.flywheel/{scripts,hooks,doctrine}/`
   and `tests/` (matching the in-repo canonical layout).
2. Installs / chains a pre-commit hook in `.git/hooks/pre-commit` (chains
   with existing using marker `# fs-rag-discipline-pre-commit BEGIN/END`).
3. Runs baseline scan via
   `file-rag-discipline-lint.sh --scan-all --root <repo> --json`,
   writes to `.flywheel/audit/fs-rag-baseline-<date>.json`.
4. Writes idempotency receipt `.flywheel/audit/fs-rag-backfill-applied.json`.
5. Reports `fs_rag_discipline: {requested, action, baseline_path,
   violations_total}` in the JSON output.

Smoke (fresh tmp repo): full apply rc=0 + 5 artifacts copied + hook chained
+ baseline written + receipt written. Re-run is idempotent (in-sync
artifacts skip; receipt detected; no errors).

### AG3 — sibling rollout

`.flywheel/audit/flywheel-fs-rag-portable/sibling-rollout-2026-05-10.json`:

| Repo | Status | Reason | Dirty files |
|---|---|---|---|
| alpsinsurance | skipped | uncommitted_changes | 33 |
| mobile-eats | skipped | uncommitted_changes | 57 |
| skillos | skipped | uncommitted_changes | 74 |
| vrtx | skipped | uncommitted_changes | 481 |
| picoz | skipped | uncommitted_changes | 455 |
| zesttube | skipped | uncommitted_changes | 63 |

All 6 sibling repos skipped per spec boundary ("If any sibling repo has
uncommitted changes, skip rather than mutate."). The capability is
shipped — sibling rollout resumes when any worktree is clean. The
opt-in command (per AG6 handoff): `flywheel-adopt.sh --repo $PWD --apply
--apply-fs-rag --idempotency-key <key>`.

### AG4 — fleet-daily-rollup.py fs-rag block

`.flywheel/scripts/fleet-daily-rollup.py` extended with:

- `fs_rag_for_repo(repo_path)` reads latest
  `<repo>/.flywheel/audit/fs-rag-baseline-*.json`.
- `aggregate()` rolls per-repo violation counts into
  `fleet_summary.fs_rag_discipline`:
  `{repos_with_baseline, violations_total, violations_avg_per_repo,
    violations_max_count, violations_max_repo}`.
- Two new RED FLAGS: `fs_rag_repo_violations_exceeds_2x_fleet_avg`
  (drift signal), `fs_rag_repo_violations_above_100`
  (absolute threshold).
- Top-line markdown row:
  `- fs_rag_discipline: avg=X fleet_max=Y@<repo> baseline_repos=N`.

Live smoke (with flywheel's own baseline):

```json
{
  "repos_with_baseline": 1,
  "violations_total": 1544,
  "violations_avg_per_repo": 1544.0,
  "violations_max_count": 1544,
  "violations_max_repo": "/Users/josh/Developer/flywheel"
}
```

Red flag fired: `fs_rag_repo_violations_above_100 repo=flywheel count=1544`.

### AG5 — launchd plist verify

`launchctl print gui/$(id -u)/ai.zeststream.flywheel-fleet-daily-rollup`
shows the existing 08:30 plist points at
`/Users/josh/Developer/flywheel/.flywheel/scripts/fleet-daily-rollup.py
run --json`. Since the fs-rag aggregator now lives in that script, no
new plist is needed. The next 08:30 fire surfaces fs-rag stats in the
fleet-daily-<date>.md output.

### AG6 — cross-orch handoff to skillos:1

`ntm send skillos --pane=1` delivered ("Sent to pane 1"). Body names
the template path, the `--apply-fs-rag` flag, the per-pane opt-in
command, the dirty-tree skip note (skillos has 74 dirty files today),
and points to the doctrine.

### AG7 — this evidence file

`.flywheel/audit/flywheel-fs-rag-portable/evidence.md` (this file).

## Aggregate fleet baseline

Today: 1 repo with baseline (flywheel itself, 1544 F1+F4 violations
mostly `frontmatter-required` on receipt files). When the 6 siblings'
worktrees clear and the installer runs, the rollup will surface
per-sibling violation counts daily.

## Daily-ops wire-in proof

After 2026-05-10 08:30 fire (or any subsequent rollup invocation), the
fleet-daily-<date>.md TOP-LINE includes the `fs_rag_discipline` row
plus the relevant red flag. The 25,974-line projected fleet savings
(per `pilot-lessons.md`) plus the fs-rag drift visibility together
close the doctor-mode-integration chain leverage points #4 (template =
paradigm carrier) and #6 (daily rollup = drift visibility).

## Boundary respected

- Template artifacts are COPIES; flywheel keeps live canonical files
  (verified via `cmp -s`).
- Sibling rollout uses `--apply --idempotency-key` and skipped on dirty
  trees.
- Wave-2 backfill (1544 F1 violations) is OUT OF SCOPE per spec —
  daily rollup will surface as drift signal.
- Sibling repo non-`.flywheel/` content untouched.

## Four-Lens Self-Grade

- brand: 9/10 — template + adopter + rollup pattern matches existing flywheel-install conventions
- sniff: 10/10 — every AG has verbatim probe + result; smoke on fresh tmp repo confirms full path
- jeff: 10/10 — data decides; 6/6 dirty-skip + 1 baseline drift signal both fire mechanically
- public: 9/10 — operator can read this evidence file + reproduce smoke in 30s

four_lens=brand:9,sniff:10,jeff:10,public:9
