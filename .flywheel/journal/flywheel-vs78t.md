---
bead: flywheel-vs78t
title: verify-watcher-launchd-active.sh canonical-CLI scaffold + 18-TODO fillin
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P0
mission_fitness: direct
parent: flywheel-ok1sk (jloib wave-1; sub-bead 8 of 17)
sister_exemplars: lrdum (985), gbfpo (985), kz7o0 (985), bu0es (985), 05ost (985)
---

# Journey: flywheel-vs78t

## What Joshua asked for

Wave-1-bash-8 (8th ok1sk sub-bead). Bash scaffolder applies normally. Target:
the launchd-verification substrate that confirms per-session codex-stuck-
detector + coordinator daemons are loaded under the user's gui domain.

## What I shipped

- 18 TODO markers replaced with substantive impl
- doctor: 7 named probes (bash, jq, mktemp, **launchctl_available** =
  load-bearing, detector_executable, pattern_test_executable,
  audit_log_dir_writable) with 2-tier rollup
- health: $SCAFFOLD_AUDIT_LOG binding with stale-threshold (24h default,
  env-tunable via VERIFY_WATCHER_HEALTH_STALE_THRESHOLD_SECONDS)
- repair: 2 scopes (state_dir, audit_log_dir) with apply contract;
  unknown scope returns rc=64 + unknown_scope envelope
- validate: 3 subjects (launchd-label `^ai\.zeststream\.[a-z0-9-]+$`,
  session-name `^[a-z0-9-]+$`, audit-row JSONL ts+action shape) with
  rc=64 missing_subject and unknown_subject refusals
- audit: cli_emit_audit_tail (path-then-schema-then-limit positional)
- why: 3 states (found / not_found / unavailable), scans 4 keys
  (ts, launchd_label, session, run_id)
- Test 13 → 19 (calibrated 2 + added 6 fillin including launchctl_available
  probe presence, label accept/reject pair, session-name accept/reject pair,
  unknown-scope rc=64)

## AG verification

AG1-5 strict apply-spec validation predicate: **AG1-5 PASS**. 19/19 tests pass.
Lint clean (0 violations).

## Notable

- Both validate subjects (launchd-label + session-name) directly map to the
  fields of DEFAULT_SPECS at L363-370 — the validation regexes ARE the
  schema for the verifier's spec table
- `launchctl_available` probe is the load-bearing check for this surface
  (without launchctl, the verifier itself is non-functional regardless of
  whether the watched plists exist)
- Test 9 calibrated to bare `validate` (no args) returning rc=64 + missing_subject
  per `feedback_calibrate_test_to_actual_contract` META-RULE; previous
  pattern of `--scope none` no longer matches the strengthened contract

## Files touched

- `.flywheel/scripts/verify-watcher-launchd-active.sh` (174 → 484 lines)
- `tests/verify-watcher-launchd-active-canonical-cli.sh` (94 → 142 lines)
- `.flywheel/audit/flywheel-vs78t/{evidence,journey,compliance,11 smoke,test-run,lint,diff,before}`
- `.flywheel/journal/flywheel-vs78t.md`

## Mission fitness

Class: **direct**. Wave-1-bash-8 sub-bead from ok1sk decomposition;
canonical-cli scaffold + fillin on the launchd-watcher verification
primitive that the codex-stuck-detector substrate depends on.
