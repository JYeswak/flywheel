# Journey: flywheel-1hshd.28

## Phase 1: baseline — NO-BYPASS variant
- Native flags --apply/--profile/--exclude don't conflict with scaffold verbs at args[0]
- Native has no --info/--schema/--examples — scaffold owns all canonical surfaces

## Phase 2: scaffold + 18-TODO fillin
- 139 → 385 lines pre-fillin
- doctor probes ntm_executable load-bearing
- validate cross-sources native --profile (profile-name subject) and --exclude (exclude-list subject)
- exclude-list is comma-separated; per-member canonical pattern check (novel CSV validation pattern)

## Phase 3: lint-idiom-fix
- `set -uo pipefail` → `set -euo pipefail; set +e` (5th recurrence this session)

## Phase 4: ship — 19/19 PASS, lint clean
