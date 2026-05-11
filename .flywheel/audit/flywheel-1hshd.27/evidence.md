# Evidence: flywheel-1hshd.27 — fleet-coherence-launchd.sh canonical-CLI scaffold + 18-TODO fillin

**Bead**: flywheel-1hshd.27 (P2, wave-4-general-27)
**Task ID**: flywheel-1hshd.27-2b581e
**Identity**: MistyCliff
**Surface**: `.flywheel/scripts/fleet-coherence-launchd.sh`
**Variant**: **SELECTIVE-VERB-BYPASS** (1st explicit application this session)

## Per-flag baseline + variant

Native has its own subcommand grammar: `install/load/unload/status/run/validate plist` (with --apply/--dry-run on mutating verbs). Bare invocation emits status JSON.

| Flag/verb        | Native pre-scaffold? | Owner after scaffold | Bypass class                              |
|------------------|----------------------|----------------------|-------------------------------------------|
| --info           | NO                   | SCAFFOLD             | scaffold owns                             |
| --schema         | NO                   | SCAFFOLD             | scaffold owns                             |
| --examples       | NO                   | SCAFFOLD             | scaffold owns                             |
| --doctor         | NO                   | SCAFFOLD             | scaffold owns via verb                    |
| doctor verb      | NO                   | SCAFFOLD             | scaffold owns                             |
| health           | NO                   | SCAFFOLD             | scaffold owns                             |
| repair           | NO                   | SCAFFOLD             | scaffold owns                             |
| **validate plist** | **YES (legacy)**   | **NATIVE**           | **SELECTIVE-VERB-BYPASS — sub-arg routes back to native** |
| validate {label,cadence-seconds,state-dir} | NO | SCAFFOLD     | scaffold owns                             |
| audit            | NO                   | SCAFFOLD             | scaffold owns                             |
| why              | NO                   | SCAFFOLD             | scaffold owns                             |
| install/load/unload/status/run | YES (legacy) | NATIVE            | scaffold yields (verb not in canonical set) |
| bare invocation  | YES (status JSON)    | NATIVE               | scaffold yields                           |

**Variant unique-feature**: SELECTIVE-VERB-BYPASS at the **sub-arg** level — `validate` verb is in the scaffold canonical set, but `validate plist` (with `plist` as args[1]) is bypassed to NATIVE because native owns the legacy plist-validation contract. Scaffold's validate handles other subjects (label, cadence-seconds, state-dir).

## Fillin completeness

- TODO markers remaining: **0**
- 8 stubs filled per recipe

## Doctor probes (7 total)

| Check                       | Probe                                       | Load-bearing? |
|-----------------------------|---------------------------------------------|---------------|
| launchctl_available         | command -v launchctl                        | **yes** (load/unload/status on macOS) |
| plutil_available            | command -v plutil                           | yes (plist validation) |
| jq_available                | command -v jq                               | yes           |
| state_dir_writable          | -w $STATE_DIR or parent                     | yes           |
| install_plist_present       | -r ~/Library/LaunchAgents/com.zeststream.flywheel.fleet-coherence.plist | yes |
| launchagents_dir_present    | -d ~/Library/LaunchAgents                   | yes           |
| audit_log_dir_writable      | -w dirname($SCAFFOLD_AUDIT_LOG)             | yes           |

## Repair scopes (3 total)

| Scope             | Target                              | Action            |
|-------------------|-------------------------------------|-------------------|
| state_dir         | $STATE_DIR                          | mkdir -p          |
| audit_log_dir     | dirname($SCAFFOLD_AUDIT_LOG)        | mkdir -p          |
| launchagents_dir  | ~/Library/LaunchAgents              | mkdir -p          |

## Validate subjects (3 scaffold + 1 native bypass = 4 total)

| Subject              | Owner    | Contract                                            |
|----------------------|----------|-----------------------------------------------------|
| label                | SCAFFOLD | `^com\.zeststream\.flywheel\.[a-z][a-z0-9_-]*$`     |
| cadence-seconds      | SCAFFOLD | integer in [10, 3600]; default 60 (launchd StartInterval) |
| state-dir            | SCAFFOLD | absolute path required                              |
| **plist**            | **NATIVE** | **legacy: cadence_ok/helper_command_ok/install_plist/install_plist_lint** |

## Test coverage

- 19/19 PASS
- 6 fillin tests added incl SELECTIVE-VERB-BYPASS native-bypass verification (test 18) + 4-direction fidelity verifying both scaffold AND native paths preserved (test 19)

## Lint

- `canonical-cli-lint.sh`: **CLEAN** (post-scaffold)
- Pre-existing brace-default-ambiguity at line 99 (pre-scaffold) → fixed by introducing `local empty_obj='{}'` intermediate variable per L3 canonical pattern. Bonus fix within owned scope.

## Smoke captures

22 surfaces captured including native bypass paths (validate plist, status, bare invocation).

## Mission fitness

`adjacent` — substrate work. fleet-coherence-launchd is the LaunchAgent installer for the fleet coherence scanner. Canonical-CLI scaffold gives uniform machine-readable surfaces (doctor/health/repair/validate/audit/why) while preserving the full native subcommand grammar (install/load/unload/status/run + legacy validate plist).

## Skill discovery

- `pattern-emerged`: **SELECTIVE-VERB-BYPASS at sub-arg level** — when scaffold canonical verb (validate) collides with native subcommand using sub-args (validate plist), bypass at args[1] discrimination preserves both. 1st explicit application this session.

## Files changed

- `.flywheel/scripts/fleet-coherence-launchd.sh` (618 → ~900 lines; 18 stubs filled; brace-ambiguity fix)
- `tests/fleet-coherence-launchd-canonical-cli.sh` (94 → ~165 lines)

## L112 verify probe

`bash tests/fleet-coherence-launchd-canonical-cli.sh 2>&1 | tail -1`
Expected: `grep:SUMMARY pass=19 fail=0`

