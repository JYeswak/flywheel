# flywheel-4w0a0 Evidence — sync-canonical-doctrine ergonomics: --info / --schema / --examples + allow-large receipt

Task: `flywheel-4w0a0-a7b166`
Bead: `flywheel-4w0a0` (P2 OPEN → CLOSED this turn)
Title: [agent-ergo-cli-max] sync-canonical-doctrine: land --info, --schema and document/split 1080-line oversized file
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Source: per-surface follow-up from `flywheel-62mf9` agent-ergo audit;
recommendation `sync-canonical-doctrine-R001` (acceptance target 820,
baseline 690).
Mission fitness: `mission_fitness=infrastructure` — closes the
agent-ergonomics gap on a high-blast fleet-propagation aggregator
without splitting (oversized-receipt path per audit note).

## Headline finding — target 820 met via introspection + allow-large

| Metric | Pre (per audit) | Post |
|---|---|---|
| help_exists | true | true |
| info_json | **false** | **true** ✓ |
| schema | **false** | **true** ✓ |
| examples flag | usage-only | **discrete `--examples` flag** ✓ |
| dry_run_in_source | true | true |
| apply_in_source | true | true |
| json_in_source | 3 | 4 |
| line_count | 1080 | 1267 (introspection added 187 lines) |
| oversized-receipt comment | absent | **present at line 4** (cites flywheel-62mf9 R001) ✓ |
| score | 690 | **~830** (target 820 met) |

Per audit recommendation: "oversized-receipt path is acceptable given
the script's role as fleet-propagation aggregator; if oversized-receipt
is chosen, document the threshold exception in a code comment near the
head." That's exactly what landed.

## What changed

### `.flywheel/scripts/sync-canonical-doctrine.sh`

1. **`canonical-cli-scoping-allow-large` receipt comment** at lines 3-13
   citing audit recommendation `sync-canonical-doctrine-R001` and the
   per-surface bead `flywheel-4w0a0`. Documents why the oversize is
   acceptable (fleet-propagation aggregator role; splitting would
   fragment per-surface idempotency/drift contract).
2. **`VERSION="sync-canonical-doctrine/v1"`** constant introduced
   (anchors all envelope schema versions).
3. **`emit_info()`** function emits `tool-info/v1` JSON envelope:
   `name`, `version`, `path`, `default_source`, `canonical_index_target`,
   `template_index_target`, `ledger_path`, `loops_dir`,
   `orch_validation_skill_source`, `shared_script_allowlist` (split
   into array), `modes`, `flags` (11 entries), `env_vars` (19
   entries), `mutates`, `default_mode`, `exit_codes` (0/1/2),
   `receipt_schema`, `oversized_receipt` (line_count, threshold,
   ratio, receipt_id, note).
4. **`emit_schema()`** function emits a JSON Schema (`draft-07`)
   describing the `sync-canonical-doctrine-receipt/v1` envelope —
   the `--check` / `--apply` `--json` output. Required fields:
   `ts`, `mode`, `status`, `source`, `ledger_path`, `source_hash`,
   `target_count`, `drifted_count`, `synced_count`. 24+ optional
   `*_count` properties for the per-surface drift tallies.
5. **`emit_examples()`** function emits 9 curated invocation
   examples covering default check, machine-readable check, apply,
   source override, root scoping, all introspection flags, and 2
   environment-variable patterns (`SYNC_CANONICAL_LEDGER_DISABLE`,
   `SYNC_CANONICAL_NOW` for reproducible receipts).
6. **Arg-parser additions**: `--info`, `--schema`, `--examples`
   each fast-exit with the corresponding emit function. Existing
   surfaces (`--dry-run|--check`, `--apply`, `--json`, `--source`,
   `--root`, `-h|--help`) preserved.

### `tests/sync-canonical-doctrine-introspection.sh` (NEW)

Regression coverage with 9 PASS gates:

| # | Test | Behavior |
|---|---|---|
| 1 | sync-canonical-doctrine.sh exists + bash -n ok | substrate gate |
| 2 | --info emits tool-info/v1 envelope with required keys | new surface |
| 3 | --schema emits sync-canonical-doctrine-receipt/v1 JSON Schema | new surface |
| 4 | --examples cites --check/--apply/--source/--root + at least one env var | new surface |
| 5 | --help still emits canonical usage + exit codes + environment | regression guard |
| 6 | unknown flag exits with rc=2 | canonical-cli-scoping stable exit code |
| 7 | -h short form matches --help | regression guard |
| 8 | allow-large receipt comment present at file head | source-level guard |
| 9 | --info oversized_receipt.receipt_id matches source-comment receipt | machine-readable receipt parity |

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — substrate updated with close evidence | DID | sync-canonical-doctrine.sh gains `--info`/`--schema`/`--examples` + allow-large receipt; tests/sync-canonical-doctrine-introspection.sh lands; `.flywheel/audit/flywheel-4w0a0/` carries this evidence pack + post-score delta + pinned SHAs |
| AG2 — targeted test passes and named | DID | `bash tests/sync-canonical-doctrine-introspection.sh` returns `SUMMARY pass=9 fail=0`; live `--info`/`--schema`/`--examples` invocations all return well-formed JSON or text |
| AG3 — `br show flywheel-4w0a0` open until evidence exists | DID | this evidence pack exists; bead is closed in the same turn |
| Audit recommendation `sync-canonical-doctrine-R001` (target 820) | DID | introspection gates (info, schema, examples) all flip false→true; allow-large receipt comment lands at line 4; estimated post-score ~830 (target 820 met per the rubric: +50 info + +50 schema + +20 examples-flag-vs-prose + +20 oversized-receipt-comment ≈ +140 over baseline 690 → 830) |
| Reserve file via L107 before edit | DID | `shared-surface-reservation-check.sh --reserve` returned `status=reserved` for both target script and new test path; released after commit |
| Add regression test | DID | `tests/sync-canonical-doctrine-introspection.sh` 9/9 PASS |
| Record post-score delta | DID | `post-score-delta.txt` in audit pack: pre 690, post ~830, target 820 met |

did=6/6 didnt=none gaps=none.

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| sync-canonical-doctrine.sh (post-rework) | `.flywheel/scripts/sync-canonical-doctrine.sh` | `80e4e891e44d6fa575229992ac6ded8beab495fa48795e48e1b396c5cfa13fdd` |
| regression test | `tests/sync-canonical-doctrine-introspection.sh` | `d4b64d53da44ea00ef6c792dedb5ebff12425a298cbff9e8929580eef6714ef6` |

## Verification commands (re-runnable)

```bash
# Regression smoke (9 PASS)
bash /Users/josh/Developer/flywheel/tests/sync-canonical-doctrine-introspection.sh

# Live --info envelope (machine-readable tool metadata)
/Users/josh/Developer/flywheel/.flywheel/scripts/sync-canonical-doctrine.sh --info \
  | jq '{schema_version, name, version, default_mode, oversized_receipt}'

# Live --schema envelope (receipt JSON Schema)
/Users/josh/Developer/flywheel/.flywheel/scripts/sync-canonical-doctrine.sh --schema \
  | jq '{schema_version, type, required: (.required | length)}'

# Live --examples (curated invocations)
/Users/josh/Developer/flywheel/.flywheel/scripts/sync-canonical-doctrine.sh --examples | head -10

# Allow-large receipt comment in source
sed -n '1,15p' /Users/josh/Developer/flywheel/.flywheel/scripts/sync-canonical-doctrine.sh \
  | grep -E "canonical-cli-scoping-allow-large|flywheel-62mf9|fleet-propagation"
```

## L112 probe (worker callback)

```bash
bash /Users/josh/Developer/flywheel/tests/sync-canonical-doctrine-introspection.sh 2>/dev/null | tail -1
```

Expected (literal): `SUMMARY pass=9 fail=0`.

## Boundary

- **No split.** Per audit recommendation, oversized-receipt path was
  chosen over semantic split. Splitting would fragment per-surface
  drift detection across modules.
- **No --check / --apply / --json behavior change.** All 5 existing
  flags (`--dry-run|--check`, `--apply`, `--json`, `--source`,
  `--root`) preserved verbatim. The 3 new flags fast-exit before
  any sync logic runs.
- **No doctrine surface mutated.** `AGENTS.md` / `.flywheel/AGENTS-CANONICAL.md`
  and the L-rule files are unchanged. The script is what got the
  ergonomics upgrade.
- **No fleet-propagation triggered.** This bead is read-only on
  every other doctrine surface; only the script itself + a new
  regression test touched.
- **L107 reservation honored.** `.flywheel/scripts/sync-canonical-doctrine.sh`
  + `tests/sync-canonical-doctrine-introspection.sh` both reserved
  pre-edit; released post-commit.

## Skill auto-routes

- `canonical-cli-scoping=yes` — full triad (--info, --schema,
  --examples) landed; --help/-h preserved; unknown-flag rc=2;
  --json on existing modes preserved; allow-large receipt comment
  per the canonical-cli-scoping-allow-large convention. File-length
  threshold receipt cited at line 4 (2.54x ratio, audit
  recommendation id, fleet-propagation rationale).
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — script-level CLI work, not README.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no doctrine surface mutated; ergonomics
  fix on a script.
- `readme_updated=not_applicable`.
- `no_touch_reason=script-level_ergonomics_upgrade_no_doctrine_surface_changed`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes AG1/AG2/AG3 + audit-rec R001 verbatim;
  hits the 820 score target (estimated 830). All five surfaces
  documented + tested.
- **Sniff: 9** — every introspection surface gated by a `jq -e`
  predicate; --info / --schema / --examples each tested for shape
  AND for content (specific keys/strings); existing surfaces have
  regression guards so future arg-parser refactors can't drop
  them silently.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small
  surface (one script, one test, one audit pack); no split,
  matching audit recommendation; allow-large receipt cites the
  audit recommendation id so the trail back to the audit data is
  one grep.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: one bash command runs the
    9-test suite; one shell line each for --info/--schema/--examples.
  - **maintainer (extending later)**: tool-info/v1 + receipt/v1
    schema versions are pinned, so future schema bumps are explicit;
    allow-large receipt cites the audit-recommendation id so the
    next audit pass has direct provenance.
  - **future worker (LLM agent)**: --info JSON envelope is the
    machine-readable canonical metadata; agents can introspect the
    tool without grepping the source; the env_vars list (19 entries)
    eliminates the "what envs does this tool read?" question.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-4w0a0
no_bead_reason=per-surface_ergonomics_rework_complete_audit_recommendation_R001_satisfied_target_820_met_no_followup_observed`.
