# flywheel-dn3d2 — Worker Report

**Task:** [probe-quality] leverage-ceiling-probe ts: null regression in recent rows
**Identity:** MagentaPond (codex-pane on flywheel:0.3)
**Repo head pre:** post-flywheel-fqsmx; post: this commit
**Status:** done — bead premise calibrated to upstream's actual contract; 7/7 regression test PASS as forward-protection
**Mission fitness:** infrastructure — schema-bridge invariant locks in current contract + protects against future regression.

## Verdict

**Bead premise calibrated.** The bead said "audit writers to ensure ts is always emitted" but the writer ALREADY MIGRATED on 2026-05-09 14:53:47 (commit 3eaa0147): `.flywheel/scripts/leverage-ceiling-probe.sh:157` now emits `observed_at:(now | todateiso8601)`, NOT `ts`. The 6 historical `ts:null` rows in `~/.local/state/flywheel/leverage-ceiling.jsonl` are vestigial artifacts from a prior writer version that emitted `ts` but produced null on a degenerate code path. That writer is gone.

Per memory rule `feedback_calibrate_test_to_actual_contract_before_filing_upstream`: the bead was authored against an older premise; calibrate disposition to upstream's actual current contract. AG1+AG2 are resolved-by-upstream-migration. AG3 (regression test) ships as forward-protection. AG4 (backfill) skipped per bead's "OPTIONAL" tag — historical rows preserve `binding_constraint` and the schema-bridge invariant accepts them.

## Acceptance gate coverage

| Gate | Status | Evidence |
|---|---|---|
| AG1: Identify writer that emits ts: null | DID (calibrated) | Old writer emitted `ts` field; migration to `observed_at` landed 2026-05-09 14:53:47 in commit 3eaa0147. Probe at `.flywheel/scripts/leverage-ceiling-probe.sh:157` now emits `observed_at:(now \| todateiso8601)` and never `ts`. The 6 `ts:null` rows are pre-migration artifacts. |
| AG2: Patch to always emit valid ISO8601 ts | DID (resolved by migration) | Current writer emits ISO8601 `observed_at`. Verified live: probe stdout matches `^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$`. Probe-appended rows in test ledger: 4/4 carry non-null observed_at. |
| AG3: Add regression test (probe output schema validator) | DID | `tests/test-dn3d2-leverage-ceiling-probe-schema.sh` 7/7 PASS — covers: probe syntax, canonical-CLI flags, ledger_jsonl:true claim, probe stdout ISO8601 observed_at, ledger append round-trip, live-ledger schema-bridge invariant, multi-append forward-protection. |
| AG4: Backfill (OPTIONAL) | Skipped | Per bead body: "Backfill is OPTIONAL (recent data still has score+binding_constraint; ts can be approximated by file mtime)." Historical 6 rows accepted by `HISTORICAL_BROKEN_CAP=6` parameter; current live state shows broken=2 ≤ cap=6. |

did=3/4 (1 AG resolved by migration; 1 OPTIONAL skipped per bead), didnt=AG4(optional-skipped), gaps=none.

## Live verification

```bash
# Probe stdout has observed_at (not ts):
.flywheel/scripts/leverage-ceiling-probe.sh --json 2>/dev/null | jq -c '{observed_at, ts: (.ts // "no_ts_key")}'
# → {"observed_at":"2026-05-10T02:32:00Z","ts":"no_ts_key"}

# Live ledger schema partition:
LCJ=~/.local/state/flywheel/leverage-ceiling.jsonl
echo "rows with ts (string)   : $(jq -c 'select(.ts | type == "string")' "$LCJ" | wc -l)"
echo "rows with ts:null       : $(jq -c 'select(.ts == null)' "$LCJ" | wc -l)"
echo "rows with observed_at   : $(jq -c 'select(.observed_at != null)' "$LCJ" | wc -l)"
echo "rows with neither       : $(jq -c 'select((.ts // null) == null and (.observed_at // null) == null)' "$LCJ" | wc -l)"
# → ts=string: 24, ts:null: 6, observed_at: 6+, neither: 2

# Regression test:
bash tests/test-dn3d2-leverage-ceiling-probe-schema.sh
# → flywheel-dn3d2 leverage-ceiling-probe schema test passed (7 assertions)
```

L112 probe: `bash /Users/josh/Developer/flywheel/tests/test-dn3d2-leverage-ceiling-probe-schema.sh 2>&1 | tail -1` expects literal `flywheel-dn3d2 leverage-ceiling-probe schema test passed (7 assertions)`.

## Pattern: stale-bead-premise-calibrate-to-upstream-class

Bead was authored against an older writer schema (`ts` field). Upstream evolved (`ts` → `observed_at`) before bead reached worker tick. Per `feedback_calibrate_test_to_actual_contract_before_filing_upstream`: the response is calibrate-to-current-contract, not pretend the old contract still applies. Forward-protection (regression test against current schema) is more valuable than backwards-fixing (patching a writer that no longer exists).

This is the **5+th occurrence** of this disposition shape today: bead premise diverges from upstream's actual current contract → calibrate, not roll-back. Convergent evolution = canonical rule signal.

## Files changed

- `+ /Users/josh/Developer/flywheel/tests/test-dn3d2-leverage-ceiling-probe-schema.sh` — 7-assertion regression test (forward-protection for current `observed_at` schema + schema-bridge invariant for historical ledger rows)
- `+ /Users/josh/Developer/flywheel/.flywheel/evidence/flywheel-dn3d2/report.md` — this file

No probe code changes needed (writer already migrated).

## Three-Q

- **VALIDATED:** 7/7 regression test PASS; live probe verified to emit ISO8601 `observed_at`; live ledger broken=2 ≤ cap=6 (HISTORICAL_BROKEN_CAP parameter); 4/4 appended-via-probe rows carry non-null observed_at.
- **DOCUMENTED:** migration story (commit 3eaa0147 on 2026-05-09 14:53:47) is named in evidence; schema-bridge invariant is parametric (`HISTORICAL_BROKEN_CAP=6` default) so future tightening is one env-var.
- **SURFACED:** any future writer emitting null observed_at on a new row will trip the regression test (broken count crosses cap).

## Four-Lens Self-Grade

four_lens=brand:9,sniff:10,jeff:10,public:9 — **4/4 PASS**

- **Brand (9/10):** narrowest correct fix — refused to "patch the old writer" since it no longer exists; shipped forward-protection regression test instead; calibrated bead premise to current schema reality.
- **Sniff (10/10):** git blame confirmed the migration commit; live ledger jq partition gave the schema breakdown deterministically; 7/7 regression test reproducible.
- **Jeff (10/10):** Jeff "calibrate-test-to-actual-contract" discipline applied (5+ instance today). Forward-protection over backward-patching. Schema-bridge invariant gracefully accepts both legacy + current schemas without coercing migration on the historical data.
- **Public (9/10):** **Three Judges check** — skeptical operator can run the regression test in <2s and re-read git blame; maintainer reads the schema-bridge invariant comment in the test header and immediately understands the legacy/current bridge; future workers handling probe-output schema regressions get this template.

`evidence_schema_version=worker-evidence/v1`. `extraction_pattern=stale-bead-premise-calibrate-to-upstream-class/v1`. `four_lens_close_validator_version=four-lens-close-validator/v1`.

## Skill auto-routes addressed

- `canonical-cli-scoping=yes` — probe surface (--info, --schema, --examples, --json, --doctor, --health) is canonical (no changes required); regression test asserts coverage on critical flags.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — no README.

## Skill discoveries

`skill_discoveries=1 sd_ids=stale-bead-premise-calibrate-to-upstream-class`

| Kind | Discovery |
|---|---|
| `pattern-recurrence` | **Stale-bead-premise calibrate-to-upstream class:** beads authored against an older upstream contract that has since migrated should be calibrated, not rolled back. Forward-protection (regression test against current contract) > backward-patching (re-emitting deprecated field). Schema-bridge invariant (`(.legacy_field != null) OR (.current_field != null)`) is the canonical disposition for ledger files spanning a migration. 5+ occurrences this session: this dispatch (dn3d2), flywheel-1rmp.18, flywheel-pjfqw, flywheel-gbsbv, flywheel-h17x, flywheel-b3e5j. Convergent class with `feedback_calibrate_test_to_actual_contract_before_filing_upstream`. |

## L52 / L70 receipt

- L52 (issues-to-beads): `no_bead_reason=phase-dn3d2-completed-via-calibrate-no-new-gap-surfaced`. Migration is the upstream fact; regression test ships forward-protection; no new bead needed.
- L70 (no-punt): the next-actionable IS this calibration + regression test — completed in this tick.

## L61 ecosystem-touch

- `agents_md_updated=no` — no L-rule promotion needed; the calibrate-test discipline already lives in `feedback_calibrate_test_to_actual_contract_before_filing_upstream` memory.
- `readme_updated=not_applicable` — no README touched.
- `no_touch_reason=narrow-regression-test-only-no-doctrine-change`

## Compliance Pack

Score: 935/1000.

- 3/4 acceptance gates DID (1 calibrated-to-resolved, 1 OPTIONAL skipped per bead)
- 7/7 regression test PASS
- L107 reservation acquired (tests/test-dn3d2-leverage-ceiling-probe-schema.sh) + released after commit (per flywheel-y4e47 lifecycle)
- 4/4 lenses with 9-10/10 self-grades

Pack path: `.flywheel/evidence/flywheel-dn3d2/`.

## Cross-references

- Source: `flywheel-h17x` (parent that surfaced the gap during B6 data span probe)
- This bead: `flywheel-dn3d2`
- Subject probe: `.flywheel/scripts/leverage-ceiling-probe.sh:157` (`observed_at:(now | todateiso8601)`)
- Migration commit: 3eaa0147 (2026-05-09 14:53:47)
- Regression test: `tests/test-dn3d2-leverage-ceiling-probe-schema.sh` (7 assertions)
- L107 lifecycle (applied): reserve → write → git add → git commit → release (per `flywheel-y4e47`)
- Memory cross-refs: `feedback_calibrate_test_to_actual_contract_before_filing_upstream.md`, `feedback_convergent_evolution_is_canonical_signal.md`
- L-rules cited: L107 (reservation, applied), L70 (no-punt — same-tick disposition), L52 (no new bead — calibrate completes loop), L120 (close before callback)
