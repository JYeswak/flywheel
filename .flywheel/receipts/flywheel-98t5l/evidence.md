# flywheel-98t5l Evidence

Task: `fix(security-promotion): route security doctor drift to beads and daily report`

Implemented:
- Added security doctor promotion routes in `.flywheel/scripts/doctor-signal-bead-promotion.sh`:
  - `security_leaked_secret_patterns`
  - `security_missing_deny_rules`
  - `security_precommit_missing`
  - `security_runtime_visible_secrets`
- Added recent-closed dedupe support for hyphenated `[auto-doctor:<slug>]` titles.
- Added `.security` rollup to `.flywheel/scripts/daily-report.py` with status, counts, and top failing repos.
- Added `tests/security-doctor-promotion.sh` covering the six bead acceptance gates.

Validation:
- PASS: `bash -n .flywheel/scripts/doctor-signal-bead-promotion.sh`
- PASS: `python3 -m py_compile .flywheel/scripts/daily-report.py`
- PASS: `bash tests/security-doctor-promotion.sh` (`13 passed, 0 failed`)
- PASS: `bash tests/test_dispatch_contract_promotion.sh`
- PASS: `bash tests/test_fleet_skill_discovery_promotion.sh`
- PASS: `bash tests/test_doctor_pws_promotion_dry_run.sh`
- PASS: `bash tests/canary-secret-scan.sh`
- PASS: `.flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-98t5l-0ce3f0.md`
- NOTE: `bash tests/daily-report.sh` reached `19 passed, 1 failed`; the failure was the pre-existing local LaunchAgent fixture path `~/Library/LaunchAgents/ai.zeststream.flywheel-daily-report.plist` missing, unrelated to the security rollup path.

Acceptance Mapping:
1. `leaked_secret_pattern_count` fixture creates a P0 auto-doctor bead and rerun matches it.
2. Missing deny, pre-commit, and runtime-visible fixtures create three class-specific beads and rerun matches all three.
3. Healthy security fixture returns `noop`.
4. Daily-report fixture renders `## Security` with status, counts, and top failing repos.
5. Recently closed `[auto-doctor:security-leaked-secret-patterns]` bead suppresses duplicate creation.
6. Created security bead descriptions use counts/classes only and do not include fixture secret values.

Socraticode:
- `socraticode_queries=10`
- `indexed_chunks_observed=1561`

Four-Lens Self-Grade:
- `brand:9` - Keeps the security substrate truthful without broad product churn.
- `sniff:9` - Small routing patch, direct regression fixture, no raw secret value propagation.
- `jeff:9` - Operator-facing evidence and dedupe behavior are concrete and rerunnable.
- `public:8` - A skeptical maintainer gets a focused test; broader daily-report suite still has a local LaunchAgent prerequisite outside this patch.
