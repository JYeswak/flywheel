---
bead: flywheel-wz5rh
dispatch_task: flywheel-wz5rh-e4c32e
worker: MistyCliff
identity: flywheel:0.4
date: 2026-05-10
total_score: 920/1000
mode: data-normalization-with-upstream-issue-draft
---

# Compliance Pack — flywheel-wz5rh

## Sniff-rubric

| Axis | Weight | Score | Evidence |
|---|---|---|---|
| Path-(a) empirical verification | 150 | 150 | Tested `br update --notes` AND `br doctor --repair` directly; both confirmed not to normalize source_repo; documented in evidence |
| Root-cause hunt | 150 | 150 | Discovered DURING fix-verify that `br create` reads `issue_prefix` and writes it as `source_repo` (the bug-source for the entire leakage class) |
| Test load-bearingness | 150 | 150 | 6 tests including (a) JSONL canonical count (b) DB leakage count (c) regression guard for bug-shape literal |
| Workaround discipline | 100 | 100 | Used `br sync --merge --force-jsonl` (canonical write path that round-trips JSONL through merge) instead of touching DB directly |
| Backup discipline | 100 | 100 | Backup to WORK_TMP + audit pack before edit; hash-check before atomic install |
| AC honesty | 100 | 80 | leakage=0 ✓; top-level status still fail BUT new cause (publishability_bar empty-fail rollup) — disclosed honestly + filed flywheel-9vb9i for the new finding; -20 because bead AC was 2-part and only 1 part fully met |
| Mission fitness clarity | 50 | 50 | direct + final-blocker arc completion (e5f2f → zh43y → kmf4z → wz5rh) |
| Self-grade integrity | 50 | 50 | Honest 4-lens with sniff-10 + acknowledged 2-of-2 AC-parts honestly |
| Evidence pack completeness | 100 | 100 | evidence + journey + compliance + 2 backups + smoke + test-run + upstream-issue-draft (8 artifacts) |
| Bead chain hygiene | 100 | 100 | Filed 1 new bead (flywheel-9vb9i) for the publishability_bar finding; updated upstream issue draft with root-cause |
| **Total** | **1000** | **920** | |

## Four-Lens

### Brand (10/10)
- Empirically verified path (a) blocked before falling to (b)
- Discovered upstream root cause during fix-verify (br create copies
  issue_prefix → source_repo); updated upstream issue draft accordingly
- Filed new bead (flywheel-9vb9i) for the publishability_bar empty-fail
  pattern (postcheck sentinel surfaced during my doctor verification)
- DCG-respected throughout; no destructive operations

### Sniff (10/10)
- Tested fix on COPY before applying to production
- Hash-checked production hadn't drifted since backup before atomic install
- 6/6 regression tests pass including bug-shape literal regression guard
- AC honest: leakage=0 confirmed at JSONL+DB layers; top-level status disclosed
  as "still fail BUT new cause filed as flywheel-9vb9i"
- Re-ran fix after flywheel-9vb9i creation regressed it (proved the
  upstream root cause empirically, then re-applied to land at 0)

### Jeff (8/10)
- Used canonical `br sync --merge --force-jsonl` for the rebuild
- 1 net-new test + 1 evidence pack + 1 upstream issue draft + 1 new bead
- -2: had to use direct JSONL edit (path b) because path a was blocked;
  documented as one-time exception per dispatch authorization, but
  this isn't ideal — proper fix lives upstream

### Public (10/10)
- Three judges check passes:
  - Operator: leakage=0 verified DB-side; tests pass; backups preserved
  - Maintainer: evidence + journey explain why path (a) failed and why
    path (b) was authorized
  - Future worker: regression test guards against bug-shape return
- Upstream issue draft is publishable as-is (sister to feedback_no_push_ntm_br)

## DID/DIDNT/GAPS

### DID
- Empirically verified path (a) blocked (br update doesn't touch source_repo)
- Reserved .beads/issues.jsonl, backed up to WORK_TMP + audit pack
- Built fix in copy via jq, verified count preservation, hash-checked production
- Atomic install + `br sync --merge --force-jsonl` rebuild
- Re-fix after flywheel-9vb9i creation regressed by 1
- 6/6 regression tests pass
- Filed upstream issue draft with TWO recommendations (br create + br update)
- Filed flywheel-9vb9i for publishability_bar empty-fail finding
- Discovered + documented root cause: `br create` reads `issue_prefix` as `source_repo`

### DIDNT
- **Top-level doctor status=pass|warn (literal AC)**: not achieved.
  Caused by `publishability_bar` probe status=fail flipping top-level
  status=fail without populating errors[] (postcheck sentinel kicks in).
  Filed as flywheel-9vb9i. Out of scope for source_repo bead.
- **Fix br create source_repo upstream**: filed as upstream issue draft;
  not patched (per `feedback_no_push_ntm_br`).

### GAPS
- **publishability_bar empty-fail rollup**: documented in flywheel-9vb9i
  (P2 bug). Was masked by beads_db_health_failed before this bead.
- **br create source_repo bug-source**: every new bead created from this
  directory will continue leaking until upstream lands. Documented in
  upstream issue draft.

## Skill auto-routes

- **canonical-cli-scoping**: yes (used canonical br sync --merge surface; documented blocked path)
- **rust/python/readme**: n/a

## Skill discoveries

`skill_discoveries=0 sd_ids=none`. Pure root-cause investigation +
single-bead fix; no new reusable pattern emerged that warrants discovery.
The pattern of "use `br sync --merge --force-jsonl` to round-trip
JSONL-side data fixes" could be a skill-discovery candidate but it's
already in the existing project_bead_isolation_plan domain.

## L112 verify probe

```bash
# Regression test
bash /Users/josh/Developer/flywheel/tests/beads-source-repo-basename-normalization.sh 2>&1 | tail -1
# expected: SUMMARY pass=6 fail=0

# DB leakage check
sqlite3 /Users/josh/Developer/flywheel/.beads/beads.db \
  "SELECT COUNT(*) FROM issues WHERE source_repo IS NULL OR source_repo != '/Users/josh/Developer/flywheel';"
# expected: 0

# JSONL canonical-only check
jq -r '.source_repo // "NULL"' /Users/josh/Developer/flywheel/.beads/issues.jsonl | sort -u
# expected: only "/Users/josh/Developer/flywheel"
```
