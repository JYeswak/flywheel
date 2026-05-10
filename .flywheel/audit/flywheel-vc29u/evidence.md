---
title: flywheel-vc29u evidence — doctrine-ladder-promote.sh substantive 18-TODO fill-in
type: evidence
created: 2026-05-10
bead: flywheel-vc29u
parent: flywheel-frm53 (scaffold-only) / flywheel-wgitr (decomposition family)
chain: doctor-mode-integration / doctrine-lane-fillin
---

# flywheel-vc29u evidence

**Status:** DONE — all 18 TODO markers replaced with substantive surface-specific implementations; 13/13 canonical-CLI tests PASS; lint clean.

## Acceptance gates met

| AG | Status |
|---|:-:|
| AG1: doctor returns substantive checks (≥3 dimensions) | DID — 6 checks: fuckup_log/br/jq/incidents/period/runs |
| AG2: health probe consults real signal | DID — tail runs ledger; warn stale >14 days |
| AG3: repair --scope --dry-run lists planned actions; --apply --idem mutates | DID — 2 scopes: ladder-rerun, runs-log-rotate |
| AG4: validate <subject> has runnable contract | DID — 3 subjects: row, class (INCIDENTS coverage), config |
| AG5: scaffolded test passes per-surface assertions | DID — 13/13 PASS |
| AG6: canonical-cli-scoping checker still 13/13 | DID |
| AG7: canonical-cli-lint exits 0 | DID — clean |

did=7/7, didnt=none.

## Substantive fill-in

- **doctor**: 6 checks (fuckup_log_readable, br_on_path, jq_on_path, incidents_files_present (search expanded to repo root not just `.flywheel/`), period_days_sane, runs_log_writable)
- **health**: tail 20 ledger rows; recent_count + candidates_created_in_window + last_run_ts + age_seconds
- **repair**: ladder-rerun (plan-only points at canonical run path) + runs-log-rotate (5MB threshold, mv to .timestamped)
- **validate**: row (--row-json against ts/class/severity), class (--class CLASS; greps INCIDENTS files for word-boundary match), config (env validation)
- **audit**: tail with --tail=N; canonical envelope when ledger absent (count:0 not null)
- **why <class>**: 3-tier provenance — fuckup-log occurrence count over PERIOD_DAYS + br open-bead check + INCIDENTS coverage (with matched_files); emits `promotion_recommended` boolean (true when ≥3 occurrences AND no INCIDENTS coverage AND no existing bead)

## Calibrations during fill-in

1. **`set +e`/`set -e` block in why**: pipefail tripped on jq/grep not-found rc; wrap diagnostic block with `set +e` then restore.
2. **Doctor INCIDENTS scan**: original implementation searched only `.flywheel/`; expanded to `find $repo -maxdepth 4 -name INCIDENTS.md` because the canonical INCIDENTS.md lives at repo root.
3. **Audit absent-ledger path**: ensured `count:0` is in the envelope rather than missing field.

## Sister beads in family today

- **vc3zs** (dispatch-and-log.sh) shipped 950/1000
- **gam2k** (private-tmp-prune.sh) shipped 950/1000
- **vc29u** (this — doctrine-ladder-promote.sh)

Per-surface fillin compresses to ~25-30 min wall clock with the
template established. Sister sub-beads from the wgitr family + the
broader doctor-mode-integration chain all use this pattern.

## Cross-references

- Direct parent: `flywheel-frm53` (scaffold-only)
- Decomposition family: `flywheel-wgitr` (parent class)
- Sister fill-ins today: `flywheel-vc3zs`, `flywheel-gam2k`
- Tooling: scaffold-canonical-cli.sh (flywheel-ws02m), canonical-cli-lint.sh (flywheel-etp5n)

## Skill discovery

`sd_ids=substantive-stub-fillin-with-pipefail-set-plus-e-block-class` — when a fill-in needs to run multiple jq/grep diagnostics that may legitimately return non-zero (no matches), wrap with `set +e ... set -e` to prevent pipefail from killing the whole function. Sister to `substantive-stub-fillin-with-source-grep-fallback-class` (gam2k).
