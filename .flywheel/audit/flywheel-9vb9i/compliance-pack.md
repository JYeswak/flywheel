---
bead: flywheel-9vb9i
dispatch_task: flywheel-9vb9i-e44a02
worker: MistyCliff
identity: flywheel:0.4
date: 2026-05-10
total_score: 920/1000
mode: substrate-rollup-fix
---

# Compliance Pack — flywheel-9vb9i

## Sniff-rubric

| Axis | Weight | Score | Evidence |
|---|---|---|---|
| Path-(B) substrate fidelity | 150 | 150 | Identified canonical sister-pattern (6 sister probes use `+ (.X.errors // [])`); publishability_bar was the outlier; fix mirrors sister shape |
| Root-cause hunt | 150 | 150 | Discovered the gate at line 808 has TWO triggers, postcheck only handled one; probe ALREADY emits a real error that was being dropped by the rollup |
| Test load-bearingness | 150 | 150 | 5 tests including (a) sister-pattern presence (b) loud-failure invariant clause presence (c) fixture-level propagation (d) live AC verification |
| Belt-and-suspenders fix design | 100 | 100 | Combines canonical sister-pattern (natural case) + synth error (bug-guard) |
| .claude commit honesty | 100 | 80 | Honestly disclosed why .claude not committed (peer-orch in-flight extraction); -20 for not also filing a follow-up bead naming the doctor.d/ persistence task |
| Reservation discipline | 100 | 100 | Reserved postcheck file before edit; backed up pre-fix |
| AC honesty | 100 | 90 | fail_codes[] populated correctly ✓; top-level status still fail (publishability_bar content issues out of scope) — disclosed; -10 because dispatch AC was 2-part |
| Mission fitness clarity | 50 | 50 | direct + 5-bead arc completion narrative |
| Self-grade integrity | 50 | 50 | 4-lens with sniff-10 + acknowledged AC-parts and .claude state honestly |
| Evidence pack completeness | 100 | 100 | evidence + journey + compliance + postcheck.before + postcheck.diff + smoke + test-run |
| **Total** | **1000** | **920** | |

## Four-Lens

### Brand (10/10)
- Substrate-doctrine fix (loud-failure invariant) per dispatch path B
- Sister-pattern application — fix mirrors 6 existing sister probes
- Honest disclosure of .claude untracked-state limitation
- Did NOT sweep up peer-orch in-flight extraction work

### Sniff (10/10)
- 5/5 regression tests pass including fixture-level + live AC
- Belt-and-suspenders shape (sister-pattern + synth-guard)
- Re-fixed the new leak (wz5rh recipe replay) when peer-orch's intermediate
  bead-creation regressed leakage_count to 1
- Caught + named the publishability_bar empty-fail pattern that surfaced
  AFTER wz5rh removed the beads_db_health_failed cover

### Jeff (9/10)
- 3-line addition to ONE function in ONE file (minimal blast radius)
- Reused canonical sister-pattern shape (no new pattern invented)
- -1: didn't probe whether jeff's beads_rust DB schema also has analogous
  "status without error" rollup pattern in the canonical write path

### Public (10/10)
- Three judges check passes:
  - Operator: live doctor proves AC at probe layer + clean diff captured for replay
  - Maintainer: regression test guards canonical sister-pattern shape going forward
  - Future worker: evidence narrates 5-bead arc + names the persistence-blocker
    (peer-orch doctor.d/ extraction commit pending)

## DID/DIDNT/GAPS

### DID
- Investigated postcheck source; identified gate-vs-emit asymmetry
- Found canonical sister-pattern in 6 sister probes (storage, jeff_corpus,
  daily_report, file_length, quality_bar_close_gate, agent_mail_fd_pressure)
- Applied 3-line fix matching canonical shape + loud-failure synth guard
- Reserved file before edit; backed up pre-fix to audit pack
- 5/5 regression tests pass
- Live doctor verification: sentinel `doctor_internal_empty_fail` GONE;
  real `brand_voice_banned_words` now in fail_codes
- Re-applied wz5rh recipe to clean 1 new source_repo leak (peer-orch
  filed flywheel-6kdnf which leaked per upstream br create bug)

### DIDNT
- **Commit .claude side**: file is untracked (peer-orch in-flight
  doctor.d/ extraction not committed); cannot extract HEAD-version to
  isolate my hunk. Fix is LIVE at runtime; persistence blocked on
  peer-orch commit.
- **Top-level doctor status pass**: publishability_bar content issues
  (banned_words_count=2, public_repo=false) drive the underlying
  status=fail. Out of scope (content fix, not rollup fix).

### GAPS
- **doctor.d/ persistence**: peer-orch needs to commit the 3 untracked
  doctor.d/ files. My 3-line addition rides along when they do. Could be
  a separate follow-up bead.
- **publishability_bar content fixes**: brand_voice_banned_words +
  public_repo=false require content-side work, not substrate.

## Skill auto-routes

- **canonical-cli-scoping**: yes (sister-pattern fix mirrors canonical shape)
- **rust/python/readme**: n/a

## Skill discoveries

`skill_discoveries=0 sd_ids=none`. Pure sister-pattern application + bug-shape
identification. The pattern of "every probe propagates its .errors[]" is now
documented in evidence + regression test.

## L112 verify probe

```bash
# 1. Regression test
bash /Users/josh/Developer/flywheel/tests/doctor-publishability-bar-loud-failure.sh 2>&1 | tail -1
# expected: SUMMARY pass=5 fail=0

# 2. Postcheck source has both new clauses
grep -E '^\s*\+ \(\.publishability_bar\.errors // \[\]\)' \
  ~/.claude/skills/.flywheel/lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh
grep -E 'publishability_bar_status_failed_silent' \
  ~/.claude/skills/.flywheel/lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh

# 3. Live doctor: real publishability_bar code present (not sentinel-only)
"$HOME/.claude/skills/.flywheel/bin/flywheel-loop" doctor --json \
  | jq -e '[.errors[]?.code] | unique | (length > 0 and . != ["doctor_internal_empty_fail"])'
# expected: true
```
