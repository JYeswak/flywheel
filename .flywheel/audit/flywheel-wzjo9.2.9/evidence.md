---
title: flywheel-wzjo9.2.9 evidence — skillos-template-handshake.sh canonical-CLI scaffold + 18-TODO fillin
type: evidence
created: 2026-05-10
bead: flywheel-wzjo9.2.9
parent: flywheel-wzjo9.2 (wave-2.0b)
sister: wave-2.0a 8/9 closed avg 984 + wzjo9.2.3 just closed 990
chain: doctor-mode-lane-2 / canonical-cli-coverage / wave-2.0b-i
---

# flywheel-wzjo9.2.9 evidence

**Status:** DONE — skillos-template-handshake.sh scaffolded + 18-TODO fillin shipped. **20/20 PASS** (13 baseline + 7 fillin-specific). AG1-5 strict-pass. Lint clean. Live signal caught real shared-ledger row-shape variability (the fillin's `validate --ledger` adapted to filter handshake-specific rows mid-tick).

## Acceptance gates

| AG | Status | Evidence |
|---|:-:|---|
| AG1: 18 TODO markers replaced | DID — `grep -c = 0` (strict) |
| AG2: bash -n clean | DID |
| AG3: canonical-cli-lint clean | DID — 0 L1–L8 violations |
| AG4: scaffold-test PASS | DID — 20/20 |
| AG5: each surface returns concrete data | DID — see live-signal table |

did=5/5, didnt=none, gaps=none.

## Pre/post state

| Aspect | Pre | Post |
|---|---|---|
| canonical_cli_scoping_status | partial | passing |
| Lines | 198 | 720 |
| Magic comment | absent | present |
| Backup | n/a | `skillos-template-handshake.sh.bak.scaffold-20260510T215027569122000Z-80239` |

## Substantive fillin

Cross-orch skillos template handshake. cmd_run subcommands: `request`, `await-ack`, `validate-request`, `validate-ack`. Persists coordination via JSONL ledger at `~/.local/state/flywheel/cross-orch-coordination.jsonl` (shared with other cross-orch surfaces).

### Substrate probes (doctor)

| Probe | Description |
|---|---|
| `request_schema_readable` | `.flywheel/validation-schema/v1/skillos-template-handshake-request.schema.json` |
| `ack_schema_readable` | `.flywheel/validation-schema/v1/skillos-template-handshake-ack.schema.json` |
| `coord_ledger_writable` | `$SKILLOS_TEMPLATE_HANDSHAKE_LEDGER` (default `~/.local/state/flywheel/cross-orch-coordination.jsonl`) |
| `jq_on_path` | required for JSON schema validation |
| `producer_version_required` | `$SKILLOS_TEMPLATE_PRODUCER_VERSION_REQUIRED` (default `skillos-skill-injection-template/v1`) |

### Surface impls

- **scaffold_emit_schema:** per-surface schemas (doctor / health / repair / validate / audit / why / audit-row / default)
- **scaffold_emit_topic_help:** single-printf bodies per gl7om SIGPIPE discipline
- **scaffold_cmd_doctor:** 5 substrate probes
- **scaffold_cmd_health:** tail audit log; distinct subcommands + states; warn stale >24h
- **scaffold_cmd_repair:** 2 scopes (`audit-log-rotate` 5MB, `coord-ledger-prime` read-only probe of cross-orch ledger)
- **scaffold_cmd_validate:** 4 subjects (row / schema / config / **ledger** — handshake-specific)
- **scaffold_cmd_audit:** delegates to `cli_emit_audit_tail`
- **scaffold_cmd_why:** searches BOTH the scaffold audit log AND the coord-ledger for matching idempotency_key — dual-source provenance

## Live signals + mid-fillin refinement (sniff lens at work)

The fillin's `validate --ledger` initially required every row to have `idempotency_key`. Live invocation against the real fleet ledger returned `tail_with_idempotency_key:0` — surfacing that the coord-ledger is **SHARED** across cross-orch surfaces, holding many row types (events, handoffs, acks, summaries), not just handshake rows.

**Refined the implementation:** `validate --ledger` now filters handshake rows specifically (`event` matches `skillos.*handshake` or `template.handshake` regex) and only requires `idempotency_key` on those rows. Added a comment in code documenting the shared-ledger architecture.

Live signals:
1. **`repair --scope coord-ledger-prime`** → **`row_count:234`** — the cross-orch coord-ledger has 234 historical rows on this fleet
2. **`validate --ledger`** (post-refinement) → **`status:pass, tail_total:50, tail_valid_json:50, tail_handshake_rows:0`** — last 50 ledger rows are all well-formed JSON, 0 are handshake events (the recent activity is from other cross-orch surfaces sharing the ledger)
3. **doctor 5/5 pass** — all substrate present (both schemas readable, ledger writable, jq on PATH)

This is the fillin doing its job — caught a real architectural fact (ledger is shared) and adapted the validation to be honest about it.

## why command searches dual sources

`scaffold_cmd_why <idempotency_key>` searches BOTH `SCAFFOLD_AUDIT_LOG` (this surface's per-run ledger) AND the shared `SKILLOS_TEMPLATE_HANDSHAKE_LEDGER` (cross-orch coord ledger) for matching idempotency_key. Emits `source_log` in the provenance so operators see which ledger held the row.

## Test scaffold extensions (13 → 20)

- Test 14: `--info schema_version` matches `skillos-template-handshake/v1`
- Test 15: `--schema` envelope well-formed
- Test 16: doctor 5+ probes incl. `request_schema_readable` + `coord_ledger_writable`
- Test 17: repair `--scope coord-ledger-prime` non-stub envelope with row_count
- Test 18: validate `--row-json` enforces schema
- Test 19: validate `--ledger` probes coord JSONL — **handshake-specific subject**
- Test 20: why provenance enum

## Apply-spec validation predicate (strict)

```bash
$ bash -n .flywheel/scripts/skillos-template-handshake.sh \
  && grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/skillos-template-handshake.sh | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/skillos-template-handshake.sh \
  && bash tests/skillos-template-handshake-canonical-cli.sh > /dev/null \
  && echo "AG1-5 PASS"
AG1-5 PASS
```

## Cross-references

- Parent (wave): `flywheel-wzjo9.2` (wave-2.0b, 9 surfaces)
- Wave-2.0a sister fillins (avg 984; 8/9 closed): wzjo9.1.{1,2,3,4,6,7,8 + one more}
- Wave-2.0b sister just closed: wzjo9.2.3 (990) — recovery-baseline-status
- Sister-lane exemplar: `flywheel-1fk5f.{1..8}` (avg 974)
- Live target: `.flywheel/scripts/skillos-template-handshake.sh` (198 → 720 lines)
- Backup: `skillos-template-handshake.sh.bak.scaffold-20260510T215027569122000Z-80239`
- Test: `tests/skillos-template-handshake-canonical-cli.sh` (20/20 PASS)
- Coord ledger (live): `~/.local/state/flywheel/cross-orch-coordination.jsonl` (234 rows; shared cross-orch)

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:10,jeff:9,public:9`

- **brand: 9** — second wave-2.0b surface shipped; pattern matches sister exemplars
- **sniff: 10** — caught shared-ledger architectural fact via my own `validate --ledger` against live 234-row data, refined the implementation to filter handshake-specific rows, added comment-in-code documenting the shared-ledger truth. This is sniff working as designed: assumption → live verification → refinement → honest envelope
- **jeff: 9** — preserves cmd_run subcommand discipline (request / await-ack / validate-request / validate-ack); helper-lib API contracts respected; `why` searches dual sources (audit + coord ledger) for true provenance
- **public: 9** — three judges check: skeptical operator (20/20 PASS + 234-row coord ledger), maintainer (comment in code explains the shared-ledger refinement), future worker (handshake-specific `ledger` subject with regex filter is reusable for other surfaces that share the same coord ledger)

## Compliance score

5/5 AGs PASS strict + 20/20 scaffold-test + lint clean + 7 fillin-specific extensions + handshake-specific `ledger` validate subject + dual-source `why` lookup + shared-ledger architectural truth surfaced + refinement-in-code documented = **990/1000**. -10 because the initial `validate --ledger` shipped briefly with the wrong-assumption (idempotency_key required on every row) before live-data correction (caught and fixed mid-tick; comment documents).
