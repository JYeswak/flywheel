# Evidence: flywheel-1hshd.30 — flywheel-codex-stuck-detector-install.sh canonical-CLI scaffold + 18-TODO fillin

**Bead**: flywheel-1hshd.30 (P2, wave-4-general-30) | **Task ID**: flywheel-1hshd.30-c3d93b | **Identity**: MistyCliff
**Surface**: `.flywheel/scripts/flywheel-codex-stuck-detector-install.sh`
**Variant**: NO-BYPASS — scaffold owns all canonical surfaces; native --apply/--dry-run/--json flags fall through (LaunchAgent installer)

## Per-flag baseline

| Flag/verb           | Native pre-scaffold? | Owner after scaffold |
|---------------------|----------------------|----------------------|
| --info/--schema/--examples | NO            | SCAFFOLD             |
| doctor/health/repair/validate/audit/why/quickstart | NO | SCAFFOLD |
| --apply/--dry-run/--json | YES              | NATIVE (fall through to cmd_run) |
| bare invocation      | YES (label + loaded JSON) | NATIVE             |

## Doctor probes (7)

bash, jq, launchctl (load-bearing), plutil (load-bearing), source_plist (.flywheel/launchd/ — load-bearing for installer copy), install_plist (~/Library/LaunchAgents/), audit_log_dir.

## Repair scopes (2)

audit_log_dir, launchagents_dir (mkdir -p ~/Library/LaunchAgents). Apply needs --idempotency-key.

## Validate subjects (3)

- **label**: `^ai\.zeststream\.[a-z][a-z0-9_-]*$`
- **plist-path**: -r FILE + .plist extension (rejects non-.plist with `unsupported_extension`)
- **install-mode**: enum {dry_run, apply} — cross-sources native --apply/--dry-run flags (3rd recurrence of native-flags-to-enum projection pattern; META-RULE candidate at N=3)

## Test coverage

19/19 PASS. Test 17 verifies install-mode full-enum sweep. Test 18 verifies plist-path extension rejection. Test 19 verifies NO-BYPASS preservation of native bare invocation.

## Lint

Clean.

## Mission fitness

`adjacent` — installs codex-stuck-detector LaunchAgent that automates Joshua's "L91 auto-retry helper FAILED — respawn is canonical" META-RULE recovery for stuck codex panes. Canonical-CLI scaffold gives uniform machine-readable surfaces while preserving native installer contract.

## Skill recurrence

`native-flags-to-validate-enum projection` — 3rd application this session:
1. 1hshd.25 (docs-validation-probe): validation-status enum from native --schema .metadata_fields
2. 1hshd.29 (flywheel-adopt): adoption-mode enum from native --reconcile/--first-run-audit/--apply-fs-rag
3. 1hshd.30 (this): install-mode enum from native --apply/--dry-run

**N=3 → META-RULE candidate**: when scaffolding a script with rich native flag set, project disjoint mutually-exclusive native flags into a single `validate <mode-subject>` enum subject for uniform machine-readable validation surface. flywheel_orch_action_required.

## Files changed

- `.flywheel/scripts/flywheel-codex-stuck-detector-install.sh` (80 → ~620 lines)
- `tests/flywheel-codex-stuck-detector-install-canonical-cli.sh` (94 → ~170 lines)

## L112 verify probe

`bash tests/flywheel-codex-stuck-detector-install-canonical-cli.sh 2>&1 | tail -1`
Expected: `grep:SUMMARY pass=19 fail=0`
