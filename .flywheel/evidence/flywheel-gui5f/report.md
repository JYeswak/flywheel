# flywheel-gui5f — Worker Report

**Task:** [gap-hunt-probe-improvement] cross-source-silos probe needs self-instrumentation ledger awareness
**Identity:** MagentaPond (codex-pane on flywheel:0.3)
**Repo head pre:** post-pjfqw; post: this commit
**Status:** done — Option 2 fix (config file allowlist); cross-source-silos: 20→0; 7/7 regression test PASS
**Mission fitness:** infrastructure — gap-hunt-probe systemic improvement; closes the per-class INCIDENTS-cross-reference loop.

## Verdict

**Option 2 fix landed.** Created `.flywheel/gap-hunt-known-silos.jsonl` allowlist (94 rows: 3 self-instrumentation + 91 operational-telemetry). Extended `probe_cross_source_silos()` with a new `known_silos()` helper that loads the allowlist and skips listed ledgers. Cross-source-silos finding count dropped from 20 (capped, ~46 actual) to **0**.

Today's per-class cross-reference work (u5ml3, 8io1s, 2xdi.40, l7ssi, wwinm, v8yr7, dfs9y) was the operational pivot until this systemic fix landed. The 7 INCIDENTS cross-reference entries remain valid (each captures the doctrine for that trauma class); now future ledgers join the allowlist instead of needing per-class INCIDENTS edits.

## Acceptance gate coverage

| Bead AG | Status | Evidence |
|---|---|---|
| `gap-hunt-probe.sh probe_cross_source_silos()` updated to skip known-silo ledgers | DID | `known_silos()` helper added (loads `.flywheel/gap-hunt-known-silos.jsonl`); `probe_cross_source_silos()` now consults `skip = known_silos()` instead of hardcoded set |
| Known-silo list documented (config file) | DID | `.flywheel/gap-hunt-known-silos.jsonl` (94 rows, each with `name`/`class`/`writer`/`rationale` fields) |
| Existing 15+ findings resolved without per-ledger INCIDENTS edits | DID | Pre-fix: 20 findings (capped); post-fix: 0 findings; 7 prior per-class INCIDENTS cross-references remain valid (their doctrine value is independent of the systemic fix) |
| Test: re-run gap-hunt-probe + verify cross-source-silos count drops | DID | `tests/test-gui5f-known-silos-allowlist.sh` 7/7 PASS; live probe confirms cross-source-silos count = 0 |

did=4/4, didnt=none, gaps=none.

## Live verification

```bash
# Pre-fix: 20 cross-source-silos findings (capped; actual was 46)
# Post-fix: 0 findings
.flywheel/scripts/gap-hunt-probe.sh --json --quiet --dry-run | tail -1 \
  | jq -r '.gap_class_distribution["cross-source-silos"] // 0'
# (post) → 0

# Allowlist has 94 rows, each with required fields
jq -e '.name and .class and .writer and .rationale' \
  .flywheel/gap-hunt-known-silos.jsonl | wc -l | tr -d ' '
# → 94 (each row passes the required-fields predicate)

# Probe defines known_silos() helper that consults the allowlist
grep -nE "def known_silos\(\)|known_silos\(\)" .flywheel/scripts/gap-hunt-probe.sh
# → matches at the helper def + the call site in probe_cross_source_silos

# Probe code references the allowlist file path
grep -c "gap-hunt-known-silos.jsonl" .flywheel/scripts/gap-hunt-probe.sh
# → 1+ matches in the docstring/load path

# Regression test
bash tests/test-gui5f-known-silos-allowlist.sh
# → 7/7 PASS, "flywheel-gui5f known-silos allowlist test passed (7 assertions)"
```

L112 probe: `bash /Users/josh/Developer/flywheel/tests/test-gui5f-known-silos-allowlist.sh 2>&1 | tail -1` expects literal `flywheel-gui5f known-silos allowlist test passed (7 assertions)`.

## Pattern: probe-class-systemic-fix-via-config-allowlist

When a probe class flags an entire surface family that's intentionally not modeled (per `flywheel-2xdi.45`'s skill-discovery `probe-class-doesnt-model-surface-family-class`), the right systemic fix is:

1. **Config file** lists the known cases with rationale (allows operator-tunable additions without code changes)
2. **Probe consults the config** at runtime (graceful degradation if missing)
3. **Each row carries `class` + `writer` + `rationale`** so future operators can see why this entry exists
4. **Regression test** asserts the probe + allowlist contract

This is canonical Jeff functional-shell discipline: data-as-config beats code-as-rule. Adding a new known-silo is a 1-line allowlist edit, not a probe code change.

## Why Option 2 over Option 1 or 3

The bead body listed 3 alternatives:

| Option | Approach | Trade-off |
|---|---|---|
| 1 | Add `*-self-instrumentation/v1` schema marker to writers + skip in probe | Requires editing every writer; doesn't cover operational-telemetry class (which has no marker); 60+ writers to touch |
| **2 (chosen)** | Config file allowlist with `name`/`class`/`writer`/`rationale` per row | One file; operator-tunable; covers both self-instrumentation AND operational-telemetry; 94 entries total |
| 3 | INCIDENTS.md section naming canonical ledger families | Wider INCIDENTS.md noise; convergent with the per-class cross-reference work that was already operational pivot today |

Option 2 chosen because:
- Single source of truth (one file)
- No writer-side coordination required
- Covers both self-instrumentation AND operational-telemetry classes
- Each entry carries a `rationale` so future operators understand why
- Regression test asserts the contract is honored

## Files changed

- `~ /Users/josh/Developer/flywheel/.flywheel/scripts/gap-hunt-probe.sh` — added `known_silos()` helper (+24 lines); refactored `probe_cross_source_silos()` to call it (+2 lines net replacing hardcoded skip set)
- `+ /Users/josh/Developer/flywheel/.flywheel/gap-hunt-known-silos.jsonl` — new config file (94 rows)
- `+ /Users/josh/Developer/flywheel/tests/test-gui5f-known-silos-allowlist.sh` — 7-assertion regression test
- `+ /Users/josh/Developer/flywheel/.flywheel/evidence/flywheel-gui5f/report.md` — this file

## Three-Q

- **VALIDATED:** 7/7 regression test PASS; live probe cross-source-silos count dropped from 20 (capped) to 0; 94 allowlist rows all have required fields; malformed-line tolerance verified.
- **DOCUMENTED:** Option 2 trade-off rationale named; allowlist row schema (`name`/`class`/`writer`/`rationale`) documented with 3 self-instrumentation precedents (autoloop-executor, polish, security-posture) + 91 operational-telemetry rows.
- **SURFACED:** today's 7 per-class INCIDENTS cross-references (u5ml3, 8io1s, 2xdi.40, l7ssi, wwinm, v8yr7, dfs9y) remain valid as doctrine-citation work; the systemic fix means future similar dispatches get auto-resolved at the probe level. New ledgers added to the fleet should append to the allowlist (1-line edit).

## Pattern: doctrine-cross-reference-as-operational-pivot-until-systemic-fix-lands

Today's 7 cross-reference dispatches were the operational pivot pattern: each closed an L56 ladder finding by adding an INCIDENTS entry, even though they were repetitive. The systemic fix (this dispatch) couldn't have shipped first because:

1. The pattern needed to converge across 7 instances before the right systemic shape was clear
2. Each cross-reference produced doctrine-citation value (each L-rule is now visible in INCIDENTS, useful for future workers)
3. Filing the systemic fix earlier would have required guessing at the allowlist scope; the 7 instances revealed the actual surface family

This validates the convergent-evolution-as-canonical-rule-signal pattern from `feedback_convergent_evolution_is_canonical_signal`: 7 instances = strong signal; systemic fix lands AFTER convergence is observed, not before.

## Four-Lens Self-Grade

four_lens=brand:9,sniff:9,jeff:10,public:9 — **4/4 PASS**

- **Brand (9/10):** scope-respecting systemic fix; 94 allowlist rows each carry a rationale; prior per-class INCIDENTS work is honored as doctrine-citation rather than throwaway.
- **Sniff (9/10):** 7/7 regression test PASS; live probe count verified 20→0; allowlist row schema enforced via test.
- **Jeff (10/10):** Jeff functional-shell discipline — data-as-config beats code-as-rule. The probe is now operator-tunable: adding a new known silo is a 1-line allowlist edit. Reusable shape for any probe-class-doesn't-model-surface-family fix.
- **Public (9/10):** **Three Judges check** — skeptical operator can re-run the probe + see count=0; maintainer reads the allowlist + rationale per row; future workers handling new ledgers know to append to the allowlist.

`evidence_schema_version=worker-evidence/v1`. `extraction_pattern=probe-class-systemic-fix-via-config-allowlist/v1`. `four_lens_close_validator_version=four-lens-close-validator/v1`.

## Skill auto-routes addressed

- `canonical-cli-scoping=n/a` — no new CLI surface authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=yes` — `known_silos()` helper has type hints (`-> set[str]`); uses safe try/except for malformed lines; under file-length threshold.
- `readme-writing=n/a` — no README.

## Skill discoveries

`skill_discoveries=1 sd_ids=probe-class-systemic-fix-via-config-allowlist-class`

| Kind | Discovery |
|---|---|
| `pattern-emerged` | **Probe-class-systemic-fix-via-config-allowlist class:** when a probe class flags an entire surface family that's intentionally not modeled, the right systemic fix is a config file allowlist with `name`/`class`/`writer`/`rationale` per row + a probe-side `known_<thing>()` helper that consults it. Operator-tunable, no writer-side coordination required, regression-test-locked. Reusable for cross-source-silos, wired-but-cold, and any other gap-hunt probe class that benefits from a known-good allowlist. |

## L52 / L70 receipt

- L52 (issues-to-beads): **`no_bead_reason=phase-gui5f-systemic-fix-completed-no-new-bead-needed`**.
- L70 (no-punt): the next-actionable IS this fix — completed in this tick.

## L61 ecosystem-touch

- `agents_md_updated=no` — no L-rule promotion (yet); the allowlist pattern could be promoted later if 2+ probe classes adopt it.
- `readme_updated=not_applicable` — no README touched.
- `no_touch_reason=systemic-probe-fix-no-doctrine-change-yet`

## Compliance Pack

Score: 940/1000.

- 4/4 acceptance gates DID
- 7/7 regression test PASS
- Live probe count 20→0 verified
- 4/4 lenses with 9-10/10 self-grades
- L107 reservations acquired (probe + allowlist) + RELEASED AFTER COMMIT (per the L107 lifecycle that flywheel-y4e47 just clarified)

Pack path: `.flywheel/evidence/flywheel-gui5f/`.

## Cross-references

- Surfaced by: `flywheel-2xdi.40` (autoloop-executor.jsonl cross-source-silos finding) + `flywheel-2xdi.45` (skill-pack validators wired-but-cold; convergent meta-pattern)
- This dispatch: `flywheel-gui5f`
- Sibling systemic-fix bead: `flywheel-9x7j5` (filed by 2xdi.45 for wired-but-cold class; same allowlist pattern would apply)
- Today's 7 per-class INCIDENTS cross-references (operational pivot until this fix landed): `flywheel-u5ml3`, `flywheel-8io1s`, `flywheel-2xdi.40`, `flywheel-l7ssi`, `flywheel-wwinm`, `flywheel-v8yr7`, `flywheel-dfs9y`
- Subject probe: `.flywheel/scripts/gap-hunt-probe.sh::probe_cross_source_silos()` (lines 784-820 post-edit)
- Subject allowlist: `.flywheel/gap-hunt-known-silos.jsonl` (94 rows: 3 self-instrumentation + 91 operational-telemetry)
- Regression test: `tests/test-gui5f-known-silos-allowlist.sh` (7 assertions)
- L107 lifecycle (applied this dispatch per flywheel-y4e47): reserve → write → git add → git commit → release
- Memory cross-refs:
  `feedback_convergent_evolution_is_canonical_signal.md`,
  `feedback_calibrate_test_to_actual_contract_before_filing_upstream.md`
- L-rules cited: L107 (shared-surface reservation, applied per new lifecycle), L70 (no-punt — same-tick disposition), L52 (no new bead — systemic fix completes the loop)
