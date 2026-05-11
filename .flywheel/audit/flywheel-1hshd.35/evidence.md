# Evidence: flywheel-1hshd.35 — headless-browser-reap.sh canonical-CLI scaffold + 18-TODO fillin

**Bead**: flywheel-1hshd.35 | **Task ID**: flywheel-1hshd.35-b74a89 | **Identity**: MistyCliff
**Surface**: `.flywheel/scripts/headless-browser-reap.sh` (reaps stale agent-browser-chrome processes)
**Variant**: NO-BYPASS — scaffold owns all canonical surfaces; native --apply/--dry-run/--json/--fixture/--now-epoch fall through.

## Doctor probes (7)
bash, jq, ps (load-bearing — enumerates processes), pkill (load-bearing — kills on --apply), process_pattern (agent-browser-chrome), thresholds (age=30m, count=5), audit_log_dir.

## Repair scopes (2)
audit_log_dir, fixture_dir.

## Validate subjects (3)
- process-pattern: `^[A-Za-z][A-Za-z0-9_.-]*$`
- age-minutes: int [1, 1440]; default 30 (matches native 30m threshold)
- reap-mode: enum {dry_run, apply} — cross-sources native --apply/--dry-run (**N=6** of native-flags-to-enum projection META-RULE)

## Test coverage
19/19 PASS. Lint clean.

## Mission fitness
`adjacent` — headless-browser-reap is the canonical primitive for reaping stuck agent-browser-chrome processes. Recovery substrate for hung headless browser sessions. Canonical-CLI scaffold gives uniform machine-readable surfaces while preserving native --apply/--dry-run/--fixture/--now-epoch reap contract.

## Skill recurrence
- `native-flags-to-validate-enum projection` — N=6 (reap-mode from --apply/--dry-run). META-RULE already promoted at N=3.

## Files changed
- `.flywheel/scripts/headless-browser-reap.sh` (165 → ~620 lines)
- `tests/headless-browser-reap-canonical-cli.sh` (94 → ~170 lines)

## L112 verify probe
`bash tests/headless-browser-reap-canonical-cli.sh 2>&1 | tail -1`
Expected: `grep:SUMMARY pass=19 fail=0`
