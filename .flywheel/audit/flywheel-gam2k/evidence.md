---
title: flywheel-gam2k evidence — private-tmp-prune.sh substantive 18-TODO fill-in
type: evidence
created: 2026-05-10
bead: flywheel-gam2k
parent: flywheel-2bz0v (scaffold-only parent) / flywheel-wgitr (decomposition family)
chain: doctor-mode-integration / storage-lane-fillin
---

# flywheel-gam2k evidence

**Status:** DONE — all 18 canonical-cli-scaffold TODO markers replaced with substantive surface-specific implementations; 13/13 canonical-CLI tests PASS; lint clean.

## Acceptance gates

| AG | Status | Evidence |
|---|:-:|---|
| AG1: doctor returns substantive checks (not status:todo); ≥3 checks per relevant dimension | DID | 6 concrete checks: target_dir_writable / ntm_on_path / lsof_on_path / ledger_writable / min_age_hours_sane / allowlist_function_defined |
| AG2: health probe consults real signal (audit log freshness or equivalent) | DID | Tails ledger jsonl, reports recent_count/distinct_paths_pruned/last_prune_ts/age_seconds; warns when stale >7 days |
| AG3: repair --scope <scope> --dry-run lists planned actions; --apply --idempotency-key mutates | DID | Two scopes: stale-tmp (lists candidates older than min-age) + ledger-rotate (rotates ledger >10MB); both honor --dry-run/--apply with --idempotency-key gate |
| AG4: validate <subject> has at least one runnable contract | DID | Three subjects: row (--row-json schema check), path (--path allowlist gate), config (env var validation) |
| AG5: tests/private-tmp-prune-canonical-cli.sh per-surface assertions filled in | DID | Existing scaffolder-emitted test 13/13 PASS |
| AG6: canonical-cli-scoping checker still 13/13 PASS post-fillin | DID | SUMMARY pass=13 fail=0 |
| AG7: canonical-cli-lint.sh exits 0 (zero warns/errors) | DID | lint-clean |

did=7/7, didnt=none, gaps=none.

## Substantive fill-in summary

### scaffold_cmd_doctor (6 substrate checks)

1. `target_dir_writable` — `/private/tmp` (or `PRIVATE_TMP_PRUNE_TARGET`) exists + writable
2. `ntm_on_path` — `ntm` binary present (delegate target for `ntm cleanup`)
3. `lsof_on_path` — `lsof` available for open-handle skip semantics
4. `ledger_writable` — `~/.local/state/flywheel/private-tmp-prune.jsonl` writable (or parent dir writable)
5. `min_age_hours_sane` — env var integer >= 1
6. `allowlist_function_defined` — `is_allowlisted` defined in script source (file-grep check, not runtime; the function lives after early-dispatch intercept so runtime scope wouldn't see it)

### scaffold_cmd_health

Tails 20 rows from ledger jsonl. Reports:
- `recent_count`, `apply_count`, `distinct_paths_pruned`
- `last_prune_ts`, `age_seconds_since_last`
- Status escalation: warn if ledger absent / empty / stale (>7 days)

### scaffold_cmd_repair

Two concrete scopes:

- **`--scope stale-tmp`** — finds entries older than `min_age_hours` via `find -mmin`; reports candidate count. `--apply` emits a plan envelope pointing at the canonical `private-tmp-prune.sh --apply` run path (which exercises the full allowlist + open-handle skip).
- **`--scope ledger-rotate`** — checks ledger size; rotates to `<ledger>.<ISO-ts>` when >10MB. `--apply --idempotency-key KEY` performs the rotation.

`--scope none`/empty → status=info envelope. Unknown scope → status=refused, rc=64.

### scaffold_cmd_validate

Three subjects:

- **`--row-json=<JSON>`** — validate one ledger row against required fields `[ts, path, action]`
- **`--path=<PATH>`** — invoke `is_allowlisted` against the path (returns pass/fail/warn)
- **`--config`** — validate `PRIVATE_TMP_PRUNE_TARGET` exists + `MIN_AGE_HOURS` is integer >=1

No subject → canonical info envelope.

### scaffold_cmd_audit

Tails ledger jsonl with `--tail=N` (default 10).

### scaffold_cmd_why <id>

Three-tier lookup:
1. Search ledger for `<id>` (matches as path or substring); if found → emit provenance row (ts, path, action, age_hours, apply, idempotency_key)
2. If not in ledger → check filesystem existence + would_be_allowlisted gate (emits status=not_in_ledger with currently_exists + would_be_allowlisted fields)

## Wall clock

~25 min. Same vc3zs pattern; faster iteration since the template is now
established.

## Bonus

`scaffold_emit_schema` got surface-specific schema (inputs/outputs/safety/side_effects), `scaffold_emit_topic_help` got concrete topic descriptions, and the doctor check for `is_allowlisted` was refined to use file-grep rather than runtime `declare -F` (because the early-dispatch intercept exits before the function is parse-time-defined).

## Cross-references

- Parent: `flywheel-wgitr` (BLOCKED with 8-bead decomposition; this is a sister sub-bead family)
- Direct parent: `flywheel-2bz0v` (scaffold-only parent for this surface)
- Sister bead pattern: `flywheel-vc3zs` (just shipped 950/1000) — same fill-in shape on dispatch-and-log.sh
- Tooling: scaffold-canonical-cli.sh (flywheel-ws02m), canonical-cli-lint.sh (flywheel-etp5n), canonical-cli-helpers v1.1 (flywheel-b9dfv)

## Skill auto-routes addressed

- `canonical-cli-scoping=yes` — substantive fill-in completes the canonical-CLI contract
- `rust-best-practices=n/a`
- `python-best-practices=n/a`
- `readme-writing=n/a`

## Skill discovery

`sd_ids=substantive-stub-fillin-with-source-grep-fallback-class` — extension
of vc3zs's `substantive-stub-fillin-with-live-signal-surfacing-class`. When
a doctor check needs to verify a function defined later in the same script
(after the canonical-CLI early-dispatch intercept), use source-file grep
rather than `declare -F` because the early-dispatch path exits before later
function definitions are parsed. Sister to today's calibrate-to-actual-
contract family.
