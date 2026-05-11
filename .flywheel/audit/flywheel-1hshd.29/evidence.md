# Evidence: flywheel-1hshd.29 — flywheel-adopt.sh canonical-CLI scaffold + 18-TODO fillin

**Bead**: flywheel-1hshd.29 (P2, wave-4-general-29)
**Task ID**: flywheel-1hshd.29-f2749f
**Identity**: MistyCliff
**Surface**: `.flywheel/scripts/flywheel-adopt.sh`
**Variant**: NO-BYPASS — scaffold owns all canonical surfaces; native flags fall through

## Per-flag baseline + variant

Native flags: --repo, --json, --dry-run, --apply, --reconcile, --first-run-audit, --start-loop, --apply-fs-rag, --idempotency-key. No native canonical verbs.

NO-BYPASS works because no native verb at args[0] conflicts with scaffold's doctor/health/repair/validate/audit/why. Native --apply and --idempotency-key handled correctly because scaffold's repair verb owns them as per-verb modifiers (verb-first), not as top-level flags.

## Doctor probes (7)

| Check                              | Probe                                       | Load-bearing? |
|------------------------------------|---------------------------------------------|---------------|
| bash_available                     | command -v bash                             | yes           |
| jq_available                       | command -v jq                               | yes           |
| git_available                      | command -v git                              | **yes** (adoption is git-aware) |
| target_repo_resolvable             | -d $REPO                                    | yes           |
| flywheel_install_templates_present | -d templates/flywheel-install/              | **yes** (adoption installs from these templates) |
| fs_rag_substrate_present           | -x .flywheel/scripts/fs-rag-linter.sh       | yes (--apply-fs-rag flag) |
| audit_log_dir_writable             | -w dirname($SCAFFOLD_AUDIT_LOG)             | yes           |

## Repair scopes (3)

| Scope                          | Target                                    |
|--------------------------------|-------------------------------------------|
| audit_log_dir                  | dirname($SCAFFOLD_AUDIT_LOG)              |
| fs_rag_backfill_receipt_dir    | $REPO/.flywheel/audit/                    |
| flywheel_dir                   | $REPO/.flywheel/                          |

## Validate subjects (3)

| Subject          | Contract                                                 | Cross-source                                  |
|------------------|----------------------------------------------------------|-----------------------------------------------|
| repo-path        | -d directory exists                                       | adoption target validation                    |
| adoption-mode    | enum {bootstrap, reconcile, first_run_audit, apply_fs_rag} | **native --reconcile / --first-run-audit / --apply-fs-rag flags** |
| idempotency-key  | `^[A-Za-z0-9._-]{4,128}$`                                | **native --idempotency-key flag shape**       |

## Test coverage

- 19/19 PASS
- adoption-mode full-enum sweep (test 15)
- 4-direction fidelity (test 19) verifies NO-BYPASS shape (scaffold + native both work)

## Lint

- `canonical-cli-lint.sh`: clean

## Mission fitness

`adjacent` — flywheel-adopt is THE primitive for onboarding legacy repos to the flywheel substrate. Canonical-CLI scaffold gives uniform machine-readable surfaces (doctor probes load-bearing templates/flywheel-install/, validate cross-sources native flag contracts) while preserving the full native adoption contract.

## Files changed

- `.flywheel/scripts/flywheel-adopt.sh` (426 → ~840 lines)
- `tests/flywheel-adopt-canonical-cli.sh` (94 → ~170 lines)

## L112 verify probe

`bash tests/flywheel-adopt-canonical-cli.sh 2>&1 | tail -1`
Expected: `grep:SUMMARY pass=19 fail=0`
