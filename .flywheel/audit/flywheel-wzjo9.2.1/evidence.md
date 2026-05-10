---
title: clobber-recovery.sh canonical-CLI scaffold + 18-TODO fillin
type: evidence
bead: flywheel-wzjo9.2.1
task: flywheel-wzjo9.2.1-359a1b
priority: P2
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
parent_wave: flywheel-wzjo9.2 (wave-2.0b — recovery infrastructure)
sister_wave_2_0a_avg: 982 (7/9 closed)
---

# Evidence — flywheel-wzjo9.2.1

## Surface

| Attribute | Value |
|---|---|
| Path | `.flywheel/scripts/clobber-recovery.sh` |
| Lines (before) | 164 |
| Lines (after) | 619 |
| Pre status | canonical_cli_scoping=partial |
| Post status | canonical_cli_scoping=passing (full surface filled) |
| Verb collisions | NONE — clean scaffold (no native overlap) |

## Acceptance gates

| Gate | Result | Evidence |
|---|---|---|
| AG1: 18 TODO markers replaced | ✓ | TODO 18→0 (incl. meta-comment paraphrased) |
| AG2: bash -n exits 0 | ✓ | syntax-ok |
| AG3: lint exits 0 | ✓ | 0 violations |
| AG4: tests >= 13 PASS | ✓ | 19/19 PASS (13 baseline + 6 fillin assertions) |
| AG5a: doctor 5+ named probes | ✓ | 6 probes: git_available, in_git_repo, recovery_log_dir, fuckup_log_dir, canonical_doctrine_paths_present, head_content_nonempty |
| AG5b: health binds audit log | ✓ | tails $SCAFFOLD_AUDIT_LOG; reports last_run_ts + age_seconds + recent_runs + total_runs; >24h stale → warn |
| AG5c: repair scope-specific | ✓ | 2 scopes (log_dir, truncated_doctrine); apply-contract enforced |
| AG5d: validate per-subject | ✓ | 3 subjects (doctrine-path, canonical-set, recovery-row) |
| AG5e: audit cli_emit_audit_tail | ✓ | path-then-schema positional order |
| AG5f: why provenance | ✓ | found / not_found / unavailable |

## Domain-specific fillins (clobber-recovery context)

The 18 TODOs were filled with surface impl that respects the script's
load-bearing safety contract:

- **doctor's `head_content_nonempty` probe** is THE load-bearing check: it
  verifies that EACH canonical doctrine doc (MISSION/STATE/GOAL/AGENTS/
  INCIDENTS) has non-empty content in HEAD. If HEAD is empty, restoring would
  null-restore — exactly the safety bug the script's exit code 3 already
  guards against. The doctor surfaces this state proactively.
- **validate `doctrine-path` subject** enforces canonical-set membership +
  HEAD content ≥10 bytes (rejects accidental --paths arg pointing outside
  the canonical 5).
- **validate `canonical-set` subject** verifies all 5 doctrine docs present
  in working tree (a smoke-test for "did the worktree get restored?").
- **validate `recovery-row` subject** asserts JSONL ledger row shape
  (ts + action required) — guards the recovery log's schema.
- **repair `log_dir` scope** ensures recovery + fuckup + audit log dirs all
  exist (safe one-shot mkdir -p).
- **repair `truncated_doctrine` scope** is a documented invocation pointer
  to the canonical cmd_run path (does not duplicate logic).

## Live smoke

```
doctor: status=pass with 6 checks
health: status=warn (audit log absent — first-run state)
validate canonical-set: status=pass
validate doctrine-path MISSION.md: status=pass
repair log_dir --dry-run: status=ok action=all_log_dirs_exist_noop
```

## Skill auto-routes

- canonical-cli-scoping: yes (full surface filled per skill)
- rust/python/readme: n/a (pure bash)

## L112 verify probe

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/clobber-recovery.sh \
  && grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/clobber-recovery.sh | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/clobber-recovery.sh \
  && bash tests/clobber-recovery-canonical-cli.sh \
  && echo "AG1-5 PASS"
# expected: AG1-5 PASS + SUMMARY pass=19 fail=0
```
