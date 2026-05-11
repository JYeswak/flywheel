---
bead: flywheel-64hud
title: jeff-issue-response-poll.sh canonical-CLI scaffold + 18-TODO fillin
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P0
mission_fitness: adjacent
parent: flywheel-ok1sk (jloib wave-1; sub-bead 10 of 17)
sister_exemplars: x0k3j (985), vs78t (985), lrdum (985), gbfpo (985), kz7o0 (985), bu0es (985), 05ost (985)
---

# Journey: flywheel-64hud

## What Joshua asked for

Wave-1-jeff-corpus-10 (10th ok1sk sub-bead). Surface:
jeff-issue-response-poll.sh — the dogfood-loop primitive that polls
$JEFF_ISSUES_REGISTRY and auto-creates triage beads when Jeff
responds upstream.

## What I shipped

- 18 TODO markers replaced with substantive impl
- doctor: 8 named probes (br_available + jeff_issues_status_available
  are load-bearing; registry_readable warns rather than fails because
  source script returns noop on missing registry; repo_dir_is_git
  required for br create context)
- health: 12h stale threshold (intra-day cadence; tunable via
  JEFF_ISSUE_RESPONSE_POLL_HEALTH_STALE_THRESHOLD_SECONDS)
- repair: 2 scopes (registry_dir → dirname of $JEFF_ISSUES_REGISTRY,
  audit_log_dir); apply contract rc=3, unknown scope rc=64
- validate: 3 subjects (jeff-issue-ref `^owner/repo#N$`, registry-row
  with required `repo` + `number` typed fields, audit-row standard);
  rc=64 missing_subject + unknown_subject refusals
- audit: cli_emit_audit_tail; why: scans 4 keys (ts/issue_ref/bead_id/run_id)
- Test 13 → 19 (calibrated 2 + added 6 fillin)

## AG verification

AG1-5 strict apply-spec validation predicate: **AG1-5 PASS**. 19/19 tests pass.
Lint clean (0 violations).

## Notable bug-catch

- Initial registry-row validator used `(.number // empty) == ""` which
  is correct for string-typed required fields but FAILS for numeric
  fields because `null // empty == ""` evaluates `empty == ""` → no
  result, so select emits nothing and validator returns "ok" for
  malformed rows. Test 18 caught this immediately (rc=0 instead of 1).
  Fixed with `has(...) | not` + `.number == null` + `(.number | type)
  != "number"` to catch missing/null/wrong-type. Sister scripts (which
  use string-only required fields) are unaffected.

## Files touched

- `.flywheel/scripts/jeff-issue-response-poll.sh` (128 → 374 lines)
- `tests/jeff-issue-response-poll-canonical-cli.sh` (94 → 152 lines)
- `.flywheel/audit/flywheel-64hud/{evidence,journey,compliance,15 smoke,test-run,lint,diff,before,sample-registry}`
- `.flywheel/journal/flywheel-64hud.md`

## Mission fitness

Class: **adjacent** (per dispatch). jeff-issue-response-poll.sh is the
upstream-response-to-bead converter for the dogfood loop; making it
canonical-CLI inspectable lets the orchestrator probe pipeline health
and validate registry-rows before triggering bead-creation runs.
