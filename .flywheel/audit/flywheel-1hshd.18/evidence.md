---
bead: flywheel-1hshd.18
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
score: 985/1000
mode: scaffold-plus-fillin-bash + WZJO9.1.7-NUANCED-PARTIAL-BYPASS (4th application)
sister_exemplars: 5ke66.8 + 1hshd.{11,16} (NUANCED siblings — 4-occurrence family)
---

# Evidence Pack — flywheel-1hshd.18

## Scope

Wave-4-general-18. Apply canonical-cli scaffold + substantive fillin to
`.flywheel/scripts/continuous-productivity-detector-install.sh` —
installs the GUI-domain LaunchAgent (`ai.zeststream.continuous-
productivity-detector`) that runs the productivity detector every 5min.

## Files touched

`.flywheel/scripts/continuous-productivity-detector-install.sh` (120 → 366
lines after scaffold; TODO=0)
`tests/continuous-productivity-detector-install-canonical-cli.sh` (94 → 162
lines, 13 → 19 tests)

## AG1-5 verification

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/continuous-productivity-detector-install.sh \
  && [[ "$(grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/continuous-productivity-detector-install.sh)" == "0" ]] \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/continuous-productivity-detector-install.sh \
  && bash tests/continuous-productivity-detector-install-canonical-cli.sh \
  && echo "AG1-5 PASS"
```

Result: **AG1-5 PASS** + 19/19 tests passing.

## NUANCED-PARTIAL-BYPASS — 4th application

Pattern is now mature enough to be mechanical. Applications:

| Bead | Surface | Native bypass list |
|---|---|---|
| 5ke66.8 | freshness-probe | --info / --schema |
| 1hshd.11 | canonical-root-drift-fleet-check | --info / --examples |
| 1hshd.16 | bare-enter-primitive | --info / --examples |
| **1hshd.18** | **continuous-productivity-detector-install** | **--info / --examples** |

Note that NUANCED's defining trait is "subset" — the specific subset
varies by surface. Per-flag baseline probe pre-scaffold determines the
exact bypass list. This surface follows the {--info, --examples} subset.

## Domain-specific fillins

### doctor (8 named probes)

- `bash`, `jq`, `mktemp` — universal
- `python3_available` — load-bearing for plistlib write_plist heredoc
- `launchctl_available` — load-bearing for plist load/unload + bootstrap
- `detector_executable` — load-bearing (the script INSTALLS the wrapper
  that runs `$CPD_DETECTOR`)
- `launch_agents_dir_writable` — `~/Library/LaunchAgents` plist target
- `audit_log_dir_writable`

### health

30d stale threshold (one-shot install — runs once per upgrade; long
stale acceptable; tunable via `CPD_INSTALL_HEALTH_STALE_THRESHOLD_SECONDS`).

### repair (3 scopes — 3-scope DUAL-state pattern)

Sister to 5ke66.13 / 1hshd.14 3-scope pattern:
- `launch_agents_dir` → `mkdir -p $CPD_LAUNCH_AGENTS_DIR`
- `ledger_dir` → `mkdir -p dirname($CPD_LEDGER)`
- `audit_log_dir` → standard
- Apply contract rc=3 + unknown_scope rc=64

### validate (3 subjects, domain-precise)

- `launchd-label` regex `^ai\.zeststream\.[a-z0-9-]+$` — matches
  `$CPD_LABEL` default `ai.zeststream.continuous-productivity-detector`
  (5th occurrence of this canonical-label pattern, sister to vs78t
  verify-watcher-launchd-active)
- `interval-seconds` integer in `[30, 3600]` — matches
  `$CPD_INTERVAL_SECONDS` default 300 (5min)
- `audit-row` standard

### audit / why

Standard `cli_emit_audit_tail` + 4-key why scan
(ts/label/plist/run_id matching the per-install row schema).

## Test calibration (13 → 19)

- Test 2 (`--info`): native shape (continuous-productivity-detector-install/v1)
- Test 3 (`--schema`): scaffold shape (NOT bypassed)
- Test 4 (`--examples`): native text invocations
- Tests 5-13: scaffold owns subcommands

6 fillin assertions:

- Test 14: NUANCED-PARTIAL-BYPASS annotation (4th application notation)
- Test 15: doctor probes python3 + launchctl + detector load-bearing trio
- Test 16: launchd-label accepts canonical ai.zeststream.*
- Test 17: launchd-label rejects non-canonical (5th occurrence — sister to vs78t)
- Test 18: interval-seconds boundary values (30/300/3600)
- Test 19: interval-seconds rejects 10 (below 30s minimum)

## Notable

- **5th occurrence of launchd-label pattern check** — sister to vs78t
  verify-watcher-launchd-active. Pattern `^ai\.zeststream\.[a-z0-9-]+$`
  is the canonical fleet-wide LaunchAgent label format. Strong META-RULE
  candidate after 5 occurrences across the wave-2 + wave-4 series.
- **3-scope DUAL-state repair pattern** matches 5ke66.13 + 1hshd.14
  (production state dir + event log dir + canonical audit log dir).
  3-scope pattern is now mature at 3 occurrences.
- **30d stale threshold** is the longest of the session — install scripts
  run only once per upgrade; long stale is acceptable. Distinct from
  budget-probe's 2h or recovery's 7d cadences.

## Smoke captures

15 smoke captures: native --info + --examples + scaffold doctor/health/
3 repair scopes/2 validate subjects accept+reject pairs/audit/why/
quickstart/--schema.

## Mission fitness

Class: **adjacent**. continuous-productivity-detector-install.sh is the
LaunchAgent installer for the productivity detector; canonical-CLI
surface lets orchestrator probe substrate (python3 + launchctl +
detector) and validate label + interval before triggering install.
