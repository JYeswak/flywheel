---
bead: flywheel-1hshd.18
title: continuous-productivity-detector-install.sh canonical-CLI scaffold + 18-TODO fillin (NUANCED-PARTIAL-BYPASS, 4th application)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P2
mission_fitness: adjacent
parent: flywheel-1hshd (jloib wave-4; sub-bead 18 of 37)
sister_exemplars: 5ke66.8 + 1hshd.{11,16} (NUANCED siblings)
---

# Journey: flywheel-1hshd.18

## What Joshua asked for

Wave-4-general-18. Surface:
continuous-productivity-detector-install.sh = installs the GUI-domain
LaunchAgent (`ai.zeststream.continuous-productivity-detector`) running
the productivity detector every 5min.

## What I shipped

NUANCED-PARTIAL-BYPASS variant — 4th application. Native owns
`--info|--examples` (canonical envelope + text invocations); native
does NOT have `--schema` or verbs. Pattern is mature; recipe transferred
mechanically.

- 18 TODO markers replaced with substantive impl
- _scaffold_is_canonical_arg returns 1 for --info|--examples; returns 0
  for --schema (NOT bypassed) + verbs
- doctor: 8 named probes (python3 + launchctl + detector load-bearing
  trio for plist install + bootstrap)
- health: 30d stale threshold (one-shot install — longest of session)
- repair: 3 scopes (launch_agents_dir + ledger_dir + audit_log_dir;
  3-scope DUAL-state pattern sister to 5ke66.13 + 1hshd.14)
- validate: 3 subjects (launchd-label `^ai\.zeststream\.[a-z0-9-]+$` —
  5TH occurrence of this pattern (sister to vs78t); interval-seconds
  [30,3600] matching default 300; audit-row standard)
- audit: cli_emit_audit_tail; why: 4 keys
- Test 13 → 19 with calibration:
  - Tests 2/4: native --info + --examples
  - Test 3: scaffold --schema (NOT bypassed)
  - Tests 14-19: NUANCED annotation + load-bearing trio + label
    accept/reject (5th occurrence note) + interval boundary + below-min reject

## AG verification

AG1-5 strict apply-spec validation predicate: **AG1-5 PASS**. 19/19 tests pass.
Lint clean (0 violations).

## Notable

- **5th occurrence of launchd-label pattern check** — `^ai\.zeststream\.
  [a-z0-9-]+$` is the canonical fleet-wide LaunchAgent label format.
  Sister surfaces: vs78t verify-watcher-launchd-active (1st), 1hshd.18
  (this, 5th). Pattern is now strongly mature; META-RULE candidate.
- **3-scope DUAL-state repair pattern** matches 5ke66.13 + 1hshd.14.
  Three-occurrence pattern; canonical for surfaces with separate
  production state + event log + audit log dirs.
- **30d stale threshold** is the longest of the session. Install scripts
  run once per upgrade — distinct cadence from budget-probe (2h),
  recovery (7d), and operational scripts.
- Coordination packet from skillos:1 was forwarded to flywheel:1 (orch)
  per orchestrator-scope-boundary META-RULE before this bead started.
  Worker pane (me) does not ratify doctrine-tier coordination packets.

## Files touched

- `.flywheel/scripts/continuous-productivity-detector-install.sh` (120 → 366 lines)
- `tests/continuous-productivity-detector-install-canonical-cli.sh` (94 → 162 lines)
- `.flywheel/audit/flywheel-1hshd.18/{evidence,journey,compliance,15 smoke,test-run,lint,diff,before}`
- `.flywheel/journal/flywheel-1hshd.18.md`

## Mission fitness

Class: **adjacent**. continuous-productivity-detector-install.sh is the
LaunchAgent installer for the productivity detector; canonical-CLI
surface lets orchestrator probe substrate + validate args before install.
