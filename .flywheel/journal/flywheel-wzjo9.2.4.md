---
bead: flywheel-wzjo9.2.4
title: recovery-install-plist-alpsinsurance.sh canonical-CLI scaffold + 18-TODO fillin
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P2
mission_fitness: direct
parent_wave: flywheel-wzjo9.2 (wave-2.0b)
family: recovery-install-plist-{alpsinsurance,clutterfreespaces,mobile-eats,skillos}
followup_bead: flywheel-mbt3z
---

# Journey: flywheel-wzjo9.2.4

## What Joshua asked for

Wave 2.0b-d (alpsinsurance variant of recovery-install-plist family).
Sister wave-2.0b 3/9 closed avg 990. Dispatch flagged refactor opportunity
for shared pattern across 4 family sister scripts.

## What I shipped

1. Reserved + backed up; dry-run + apply scaffold (no verb collisions)
2. Filled 18 TODO markers with substantive surface-specific impl:
   - 7 per-surface schemas
   - 9 single-printf topic helpers (gl7om SIGPIPE-safe)
   - 7 named substrate probes in scaffold_cmd_doctor (python3, launchctl,
     launch_agents_dir_writable, repo_exists, ntm_executable,
     audit_script_executable, plist_label_valid — load-bearing for the
     LaunchAgent install workflow)
   - $SCAFFOLD_AUDIT_LOG-binding scaffold_cmd_health
   - 2 surface-specific scopes in scaffold_cmd_repair (log_dir,
     audit_log_dir); apply contract enforced
   - 3 subjects in scaffold_cmd_validate (plist-config, repo-path, audit-row)
   - cli_emit_audit_tail wiring
   - Provenance lookup with 3 states
3. Audit-log wiring at repair terminal envelope (cli_audit_append)
4. Extended baseline 13-test suite to 19 (calibrated 2 + added 6 fillin)
5. **Filed follow-up bead `flywheel-mbt3z`** for the family canonical-cli
   helper extract (~1800 lines duplication savings across 4 sister scripts)

## AG verification

| Gate | Result |
|---|---|
| AG1: 18 TODO replaced | ✓ |
| AG2: bash -n exits 0 | ✓ |
| AG3: lint exits 0 | ✓ |
| AG4: tests pass | ✓ 19/19 |
| AG5a-f: per-surface impl | ✓ |

Strict apply-spec validation predicate: **AG1-5 PASS**.

## Per-client identity preservation

The script is one of 4 client-specific variants (alpsinsurance + 3 sisters).
The fillin captures per-client identity in:
- `doctor.session = "alpsinsurance"` (named output field)
- `validate plist-config` enforces label pattern `com.zeststream.<session>.watcher`
- `validate repo-path` defaults to `/Users/josh/Developer/alpsinsurance`
- Schema default envelope names this specific install target

Test 16 regression-guards the per-client identity (asserts `session=alpsinsurance`).

## Family refactor opportunity (filed)

Per dispatch hint, 4 sister scripts are nearly identical. After this fillin,
~2400 lines of near-duplicate canonical-cli code exist across the family.
Filed `flywheel-mbt3z` (P3) to extract a shared helper at
`.flywheel/lib/recovery-install-plist-canonical-cli.sh`.

Sister beads (wzjo9.2.5 clutterfreespaces, 2.6 mobile-eats, 2.7 skillos)
can either follow this same fillin pattern OR adopt the extracted helper
once flywheel-mbt3z lands.

## Files touched

- `.flywheel/scripts/recovery-install-plist-alpsinsurance.sh` (237→663 lines)
- `tests/recovery-install-plist-alpsinsurance-canonical-cli.sh` (13→19 tests)
- `.flywheel/audit/flywheel-wzjo9.2.4/{evidence,journey,compliance,smoke,test-run,lint,diff,before}`
- `.flywheel/journal/flywheel-wzjo9.2.4.md`
- Filed: `flywheel-mbt3z` (P3 family extract)

## Mission fitness

Class: **direct**. P2 wave-2.0b-d sub-bead; canonical-cli scaffold + fillin
on a recovery primitive that was missing it.
