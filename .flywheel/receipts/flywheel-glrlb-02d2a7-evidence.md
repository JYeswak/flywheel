# flywheel-glrlb-02d2a7 Evidence

Task: flywheel-glrlb `[git-stash-janitor] fix empty untracked-tree and macOS polish verifier gaps`

## Acceptance

- AG1: PASS. `verify-bundle.sh` now compares expected and materialized untracked manifests, and treats an empty third-parent tree plus an empty materialized directory as byte-equal.
- AG2: PASS. `polish-bar-check.sh` now counts canonical `NNN.diff` files with BSD/macOS-compatible `find -name '*.diff'` plus `awk`, avoiding GNU `find -regextype`.
- AG3: PASS. A local fixture with one stash whose third parent is an empty tree passes both scripts.

## Socraticode Survey

- socraticode_queries=3
- indexed_chunks_observed=30
- Findings: prior stash-janitor hygiene and wire-in tests exist; no existing fix for empty third-parent manifest equivalence or BSD `find -regextype` surfaced.

## Verification

Commands run:

```bash
bash -n /Users/josh/.claude/skills/git-stash-janitor/scripts/verify-bundle.sh
bash -n /Users/josh/.claude/skills/git-stash-janitor/scripts/polish-bar-check.sh
shellcheck -x -P /Users/josh/.claude/skills/git-stash-janitor/scripts /Users/josh/.claude/skills/git-stash-janitor/scripts/verify-bundle.sh /Users/josh/.claude/skills/git-stash-janitor/scripts/polish-bar-check.sh
bash /Users/josh/.claude/skills/git-stash-janitor/scripts/verify-bundle.sh /Users/josh/Developer/alpsinsurance
bash /Users/josh/.claude/skills/git-stash-janitor/scripts/polish-bar-check.sh /Users/josh/Developer/alpsinsurance
```

ALPS verify after patch: Mismatch / missing: 0.

ALPS polish P1 after patch:

```text
PASS every stash has backup ref + diff + meta + index row (n=82)
PASS byte-equality verified
PASS every has_untracked=true stash has byte-equal materialized untracked files (n=58)
```

ALPS polish still reports `FAIL 47 rows have empty/unknown verdict`; this is the existing triage-data gap from the x5f0e run, not part of this verifier/macOS fix.

Fixture setup:

```text
repo: /var/folders/d0/09qgt_0n1m1ff8nyzbxppx9c0000gn/T/flywheel-glrlb.XXXXXX.bvMJprVLFX/empty-third-parent-fixture/repo
stash: stash@{0}
third_parent_tree_entries: 0
```

Fixture verify result:

```text
Verification complete:
  Total stashes:           1
  OK rows:          2
  Mismatch / missing: 0
Gate passed. Bundle is byte-equality-verified. Safe to proceed.
```

Fixture polish result:

```text
P1: Recovery completeness
  PASS every stash has backup ref + diff + meta + index row (n=1)
  PASS byte-equality verified
  PASS every has_untracked=true stash has byte-equal materialized untracked files (n=1)
Total fails: 0
```

## L112 Probe

```bash
bash -n /Users/josh/.claude/skills/git-stash-janitor/scripts/verify-bundle.sh && bash -n /Users/josh/.claude/skills/git-stash-janitor/scripts/polish-bar-check.sh && shellcheck -x -P /Users/josh/.claude/skills/git-stash-janitor/scripts /Users/josh/.claude/skills/git-stash-janitor/scripts/verify-bundle.sh /Users/josh/.claude/skills/git-stash-janitor/scripts/polish-bar-check.sh && grep -q 'ALPS verify after patch: Mismatch / missing: 0' .flywheel/receipts/flywheel-glrlb-02d2a7-evidence.md && grep -q 'Fixture polish result:' .flywheel/receipts/flywheel-glrlb-02d2a7-evidence.md && grep -q 'Total fails: 0' .flywheel/receipts/flywheel-glrlb-02d2a7-evidence.md
```

Expected: literal exit_0.

l112_marker=alps_mismatch_missing_0
l112_marker=fixture_polish_total_fails_0

## Four-Lens Self-Grade

- brand:9
- sniff:9
- jeff:9
- public:9

Three Judges check: the skeptical operator gets rerunnable script checks, the maintainer gets minimal scoped diffs, and a future worker gets durable fixture and ALPS evidence without relying on the temporary directory.

## Receipts

- files_reserved=/Users/josh/.claude/skills/git-stash-janitor/scripts/verify-bundle.sh,/Users/josh/.claude/skills/git-stash-janitor/scripts/polish-bar-check.sh,.beads/issues.jsonl,.flywheel/receipts/flywheel-glrlb-02d2a7-evidence.md
- beads_updated=flywheel-glrlb:closed
- beads_filed=none
- tmp_dir_released=true
- fuckups_logged=dcg-scratch-cleanup-blocked
- skill_discoveries=0
- agents_md_updated=no
- readme_updated=no
- no_touch_reason=skill-script-bugfix-only-no-doctrine-or-readme-change-required
