# flywheel-bxhxa Evidence Pack

Task: `storage-health-probe.sh` 5-tier classifier + dashboard line + doctor JSON wiring.

## Acceptance Checklist

| Requirement | Evidence | Status |
|---|---|---|
| Build `.flywheel/scripts/storage-health-probe.sh` | New executable script emits `schema_version=storage-health-probe/v1` with `tier`, `free_pct`, `accumulators[]`, `dispatch_gate`, and `dashboard_line`. | pass |
| Tier 0-5 classifier | Fixture sweep proved tier labels `comfortable`, `monitor`, `soft_prune`, `critical`, `fire`, `nuclear`; dispatch gate flips true at tier >=3. | pass |
| Thresholds match zesttube doctrine | Implemented `>50`, `30-50`, `15-30`, `5-15`, `<5`, plus nuclear signals (`compaction_failed`, `docker_raw_dominates`, `machine_blocked`, `nuclear_signal`, `storage_nuclear`). | pass |
| Dashboard line | `.flywheel/status-hook.sh` now emits `Storage: tier=<n>/<label> free=<pct>% gate=<allow|block> accumulators=<n>`. | pass |
| Doctor JSON wiring | `.flywheel/scripts/storage-probe.sh` now embeds `storage_tier`, `storage_tier_label`, `storage_gate_blocks_dispatch`, and `storage_health{...}`; `flywheel-loop doctor --json` includes those fields under `.storage`. | pass |
| Orchestrator gate data | `.storage.storage_health.dispatch_gate.blocks_dispatch` is boolean and true when tier >=3. | pass |
| Canonical CLI route | `storage-health-probe.sh` supports `--json`, `--schema`, `--info`, `--examples`, `doctor`, `health`, `validate`, and read-only `repair` n/a. | pass |
| Storage-pressure doctor introspection stays green | `storage-pressure-doctor.sh --schema` and `--info` now expose the read-only schema/mutates fields expected by its test. | pass |

## Verification

Commands run:

- `bash -n .flywheel/scripts/storage-health-probe.sh .flywheel/scripts/storage-probe.sh .flywheel/scripts/storage-pressure-doctor.sh .flywheel/status-hook.sh`
- `tests/storage-probe.sh` -> `Summary: 12 passed, 0 failed`
- `tests/storage-pressure-doctor.sh` -> `Summary: 11 passed, 0 failed`
- Fixture sweep for tiers 0-5 -> `storage fixture checks PASS`
- Critical edge fixture through `storage-probe.sh` -> `critical edge PASS`
- `flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json` with storage fixture -> `.storage.storage_health.dashboard_line == "Storage: tier=1/monitor free=42% gate=allow accumulators=6"`
- `bash .flywheel/validation-schema/v1/dispatch-template-audit.sh .flywheel/dispatches/codex-flywheel-bxhxa-2ba846.md` -> `valid=true`

## Skill Auto-Routes

`canonical-cli-scoping=yes`: health/doctor/repair addressed; validate/schema/JSON/exit-code behavior addressed; mutation discipline is read-only with repair n/a. No Rust or Python files touched, so `rust-best-practices=n/a`, `python-best-practices=n/a`. README writing is n/a; no README or public-doc prose changed.

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:9,jeff:9,public:9`

Brand: concise operational surface, no marketing prose. Sniff: fixture-proven threshold behavior and explicit gate field. Jeff: structured JSON and stable shell gates, no prose-only health claim. Public: passes Three Judges check for skeptical operator, maintainer, and future worker because the script is inspectable, fixtureable, schema-backed, and non-mutating.

## Compliance

`compliance_score=910/1000`

Residual risk: existing `storage_doctor_json` in the installed flywheel library still has legacy `.tier` overwrite logic, but the new embedded `.storage_health` object and top-level storage probe fields are present for consumers that need the tier 0-5 gate.
