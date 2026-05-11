# Evidence: flywheel-1hshd.28 — fleet-rotate-all-sessions.sh canonical-CLI scaffold + 18-TODO fillin

**Bead**: flywheel-1hshd.28 (P2, wave-4-general-28)
**Task ID**: flywheel-1hshd.28-2112a3
**Identity**: MistyCliff
**Surface**: `.flywheel/scripts/fleet-rotate-all-sessions.sh`
**Variant**: **NO-BYPASS** — scaffold owns all canonical surfaces; native flags (--apply/--profile/--exclude) fall through to cmd_run because they don't conflict with scaffold verbs at args[0].

## Per-flag baseline + variant

| Flag/verb           | Native pre-scaffold? | Owner after scaffold | Bypass class                        |
|---------------------|----------------------|----------------------|-------------------------------------|
| --info              | NO (unknown_arg)     | SCAFFOLD             | scaffold owns                       |
| --schema            | NO (unknown_arg)     | SCAFFOLD             | scaffold owns                       |
| --examples          | NO (unknown_arg)     | SCAFFOLD             | scaffold owns                       |
| doctor verb         | NO                   | SCAFFOLD             | scaffold owns                       |
| health              | NO                   | SCAFFOLD             | scaffold owns                       |
| repair              | NO                   | SCAFFOLD             | scaffold owns                       |
| validate            | NO                   | SCAFFOLD             | scaffold owns                       |
| audit               | NO                   | SCAFFOLD             | scaffold owns                       |
| why                 | NO                   | SCAFFOLD             | scaffold owns                       |
| --apply             | YES (native rotate)  | NATIVE               | falls through (args[0]==--apply not in scaffold set) |
| --profile NAME      | YES (caam activate)  | NATIVE               | falls through                       |
| --exclude S1,S2     | YES (skip sessions)  | NATIVE               | falls through                       |
| bare invocation     | YES (enumerate+rotate) | NATIVE             | falls through ($# == 0)             |

## Doctor probes (6 total)

| Check                              | Probe                                       | Load-bearing? |
|------------------------------------|---------------------------------------------|---------------|
| bash_available                     | command -v bash                             | yes           |
| jq_available                       | command -v jq                               | yes           |
| ntm_executable                     | -x $NTM_BIN                                 | **yes** (script orchestrates fleet rotation via ntm) |
| sister_fleet_rotate_on_caam_swap   | -x .flywheel/scripts/fleet-rotate-on-caam-swap.sh | yes (canonical per-session primitive) |
| ntm_state_dir_present              | -d ~/.local/state/ntm                       | yes           |
| audit_log_dir_writable             | -w dirname($SCAFFOLD_AUDIT_LOG)             | yes           |

## Repair scopes (2 total)

| Scope          | Target                              | Action            |
|----------------|-------------------------------------|-------------------|
| audit_log_dir  | dirname($SCAFFOLD_AUDIT_LOG)        | mkdir -p          |
| ntm_state_dir  | ~/.local/state/ntm                  | mkdir -p          |

## Validate subjects (3 total)

| Subject       | Contract                                                  | Cross-source                                |
|---------------|-----------------------------------------------------------|---------------------------------------------|
| session-name  | `^[a-z][a-z0-9_-]*$`                                      | ntm session-naming convention               |
| profile-name  | `^[a-z][a-z0-9_-]*$`                                      | **native --profile flag contract**          |
| exclude-list  | comma-separated session-names, each canonical            | **native --exclude flag contract**          |

## Test coverage

- 19/19 PASS
- Test 18 verifies exclude-list canonical CSV + invalid-member rejection (cross-sources native --exclude)
- Test 19 verifies NO-BYPASS shape (scaffold owns all canonical surfaces)

## Lint

- `canonical-cli-lint.sh`: clean (after lint-idiom-fix `set -euo pipefail; set +e` — 5th recurrence this session)

## Mission fitness

`adjacent` — fleet-rotate-all-sessions is the orchestrator primitive for caam profile rotation across all ntm sessions. Canonical-CLI scaffold gives uniform machine-readable surfaces (doctor probes ntm_executable load-bearing dependency; validate cross-sources --profile/--exclude flag contracts) while preserving the full native --apply/--profile/--exclude rotation contract.

## Files changed

- `.flywheel/scripts/fleet-rotate-all-sessions.sh` (139 → ~600 lines)
- `tests/fleet-rotate-all-sessions-canonical-cli.sh` (94 → ~160 lines)

## L112 verify probe

`bash tests/fleet-rotate-all-sessions-canonical-cli.sh 2>&1 | tail -1`
Expected: `grep:SUMMARY pass=19 fail=0`

