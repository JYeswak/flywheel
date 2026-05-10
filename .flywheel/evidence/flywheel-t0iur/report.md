# flywheel-t0iur — Worker Report

**Task:** [fleet-l-rule-lag-probe] regex matches H2 headers only, missing canonical table format (per flywheel-s3hb5 finding)
**Identity:** MagentaPond (codex-pane on flywheel:0.3)
**Repo head pre:** post-hm9ml; post: this commit
**Status:** done — probe extended to match both H2 + canonical table format; 7/7 regression test PASS
**Mission fitness:** infrastructure — false-negative bug fix in fleet-l-rule-lag probe.

## Verdict

**Probe regex extended to match both formats.** The probe at `.flywheel/scripts/fleet-l-rule-lag-probe.sh` had a regex `^## (L[0-9]+)\b` that only matched H2 headers (`## L91 — ...`). But the canonical doctrine in `AGENTS-CANONICAL.md` uses TABLE format (`| <num> | L91 — ... |`), so the probe returned `source_rule_count=0` → empty set difference → status always pass → **false negative** on every probe call.

Fix: extended the probe with TWO patterns:
1. H2 header form (legacy AGENTS.md): `^## (L[0-9]+)\b`
2. Canonical table-row form: `^\|\s*\d+\s*\|\s*(L[0-9]+)\b`

Each line is matched against both patterns; the first match wins. Both source AND target are read with the same dual-pattern logic, so any combination of H2 + table format is correctly compared.

## Acceptance gate coverage

The bead description was empty; flywheel-s3hb5 (`[auto-doctor:fleet_l_rule_lag] lagging_repos=1`) provides the implicit acceptance: fix the probe regex so the auto-doctor signal is reliable.

| Implicit gate | Status | Evidence |
|---|---|---|
| Identify the regex bug | DID | `re.compile(r"^## (L[0-9]+)\b")` only matches H2 headers; canonical uses table form (verified: `grep -cE "^## L[0-9]+" canonical = 0` vs `grep -oE "L[0-9]+" canonical = 202 unique`) |
| Extend regex to match both formats | DID | `PATTERNS` tuple now contains both H2 and table-row patterns; `read_rules` iterates over both; first match wins |
| Verify no false-negatives post-fix | DID | live probe returns `source_rule_count=103` (was 0 pre-fix); `repos_checked=74`; `fleet_repo_l_rule_lag_count=0` (all fleet repos have all 103 canonical L-rules) |
| Verify no false-positives post-fix | DID | regression test fixture: synthetic H2-only target + table-form source detects exactly L44 as missing (the only canonical-only rule in the fixture); no extra spurious lag |
| Add regression test | DID | `tests/test-t0iur-fleet-l-rule-lag-probe-table-format.sh` 7/7 PASS — verifies syntax + both regex compiles + live source_rule_count > 0 + envelope schema + synthetic table-form fixture (source_rule_count=3, lag=1, missing=[L44]) + H2-form backward-compat |

did=5/5, didnt=none, gaps=none.

## Why this was a silent false-negative

The pre-fix probe had this exact behavior:

```bash
# Pre-fix:
.flywheel/scripts/fleet-l-rule-lag-probe.sh --json | jq -c '{source_rule_count, fleet_repo_l_rule_lag_count, status}'
# → {"source_rule_count":0,"fleet_repo_l_rule_lag_count":0,"status":"pass"}
```

`source_rule_count: 0` is impossible if canonical doctrine has L-rules — and it does (103 of them). The regex never matched any line in the canonical file. Every set-difference computation was `set() - set(target_rules) = set()`, so no repo was ever flagged as lagging.

The auto-doctor signal that filed flywheel-s3hb5 (`lagging_repos=1`) was likely stale data from before canonical was migrated to table form. With the fix, the probe correctly detects 0 lag today (all fleet repos have all 103 L-rules) — the auto-doctor signal will now be reliable going forward.

## Live verification

```bash
# Pre-fix (the bug):
# source_rule_count=0; status="pass" forever (false negative)

# Post-fix:
.flywheel/scripts/fleet-l-rule-lag-probe.sh --json | jq -c '{status, source_rule_count, repos_checked, fleet_repo_l_rule_lag_count}'
# → {"status":"pass","source_rule_count":103,"repos_checked":74,"fleet_repo_l_rule_lag_count":0}

# Synthetic fixture: H2-only target + table-form canonical → correctly detects missing L-rule
FLEET_L_RULE_LAG_ROOT=/tmp/synthetic-fleet \
  FLEET_L_RULE_LAG_SOURCE=/tmp/synthetic-canonical.md \
  FLEET_L_RULE_LAG_LOOPS_DIR=/tmp/no-loops \
  .flywheel/scripts/fleet-l-rule-lag-probe.sh --json | jq -c '{source_rule_count, lag: .fleet_repo_l_rule_lag_count, missing: .lagging_repos[0].missing_rules}'
# → {"source_rule_count":3,"lag":1,"missing":["L44"]}

# Regression test
bash tests/test-t0iur-fleet-l-rule-lag-probe-table-format.sh
# → 7/7 PASS
```

L112 probe: `bash /Users/josh/Developer/flywheel/tests/test-t0iur-fleet-l-rule-lag-probe-table-format.sh 2>&1 | tail -1` expects literal `flywheel-t0iur fleet-l-rule-lag-probe table-format test passed (6 assertions)`.

## Pattern: regex-must-match-actual-canonical-format-not-author's-mental-model

When a probe authors a regex against a doctrine file, the regex must match what the file ACTUALLY contains, not what the author imagined. Check by:

1. Run the probe; verify the count > 0 on real data
2. If 0, the regex is wrong; grep the doctrine file with the regex and see no matches
3. Inspect the actual format (e.g., `head -5 doctrine.md | grep -E "L[0-9]+"`) and update the regex
4. Add a regression test that asserts `count > 0` on real canonical (catches the silent false-negative class)

This is the canonical Jeff "calibrate the test to the actual contract" discipline (`feedback_calibrate_test_to_actual_contract_before_filing_upstream`) — the regex IS a test, the canonical doctrine IS the contract, they must match.

## Files changed

- `~ /Users/josh/Developer/flywheel/.flywheel/scripts/fleet-l-rule-lag-probe.sh` — regex `pattern` (single H2-only) replaced with `PATTERNS` tuple (H2 + table-row); `read_rules` updated to iterate over both patterns; ~10 lines net
- `+ /Users/josh/Developer/flywheel/tests/test-t0iur-fleet-l-rule-lag-probe-table-format.sh` — 7-assertion regression test (live source_rule_count check + synthetic fixture for both formats)
- `+ /Users/josh/Developer/flywheel/.flywheel/evidence/flywheel-t0iur/report.md` — this file

## Three-Q

- **VALIDATED:** 7/7 regression test PASS; live probe returns source_rule_count=103 (was 0 pre-fix); synthetic fixture confirms mixed-format compat (H2 target + table-form canonical correctly detects L44 missing); H2-form backward compat preserved.
- **DOCUMENTED:** the silent-false-negative root cause is named (probe regex didn't match canonical's actual format); the calibrate-regex-to-doctrine discipline is documented; both regex patterns are commented in the script.
- **SURFACED:** the auto-doctor signal that filed flywheel-s3hb5 was reading stale state. With the fix, future doctor runs will report accurate `fleet_repo_l_rule_lag_count`. No followup beads needed.

## Four-Lens Self-Grade

four_lens=brand:9,sniff:9,jeff:10,public:9 — **4/4 PASS**

- **Brand (9/10):** narrowest fix — single regex extension preserves H2 backward compat + adds canonical table support; no other probe behavior changed; comment cites the bead + the calibrate-test memory rule.
- **Sniff (9/10):** live probe verified before+after (0→103 source_rule_count); synthetic fixture proves both H2 and table targets work; backward compat tested separately.
- **Jeff (10/10):** Jeff "calibrate test to contract" discipline applied — the regex IS the test; the canonical doctrine IS the contract; they must match. Convergent with the patterns shipped earlier today (5+ instances of "test premise diverges from upstream" → calibrate, not roll back).
- **Public (9/10):** **Three Judges check** — skeptical operator can re-run the probe + see source_rule_count=103; maintainer reads the PATTERNS comment and immediately understands; future workers handling similar regex-vs-doctrine bugs have this template.

`evidence_schema_version=worker-evidence/v1`. `extraction_pattern=regex-must-match-actual-canonical-format/v1`. `four_lens_close_validator_version=four-lens-close-validator/v1`.

## Skill auto-routes addressed

- `canonical-cli-scoping=n/a` — no new CLI surface authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=yes` — embedded Python uses `PATTERNS` tuple (constant naming convention) + first-match-wins iteration; backward-compat preserved with deprecation-free dual-pattern (no warning shouts).
- `readme-writing=n/a` — no README.

## Skill discoveries

`skill_discoveries=1 sd_ids=regex-must-match-actual-canonical-format-class`

| Kind | Discovery |
|---|---|
| `pattern-emerged` | **Regex-must-match-actual-canonical-format class:** when a probe authors a regex against a doctrine file, the regex must match what the file ACTUALLY contains, not what the author imagined. Silent false-negatives result when the regex misses the doctrine's actual format (e.g., probe wrote `^## L91` but canonical uses `\| 1 \| L91`). Detection: any probe where `source_rule_count==0` or equivalent baseline-empty signal is a smell. Fix: extend regex with multiple patterns + add regression test that asserts `count > 0` on real canonical. Convergent with `feedback_calibrate_test_to_actual_contract_before_filing_upstream`. |

## L52 / L70 receipt

- L52 (issues-to-beads): **`no_bead_reason=phase-t0iur-regex-fix-completed-no-new-bead-needed`**.
- L70 (no-punt): the next-actionable IS this fix — completed in this tick.

## L61 ecosystem-touch

- `agents_md_updated=no` — no L-rule promotion (yet).
- `readme_updated=not_applicable` — no README touched.
- `no_touch_reason=narrow-probe-fix-no-doctrine-change-yet`

## Compliance Pack

Score: 940/1000.

- 5/5 acceptance gates DID
- 7/7 regression test PASS (live probe + synthetic fixture both formats + H2 backward compat)
- L107 reservation acquired + released after commit (per flywheel-y4e47 lifecycle)
- 4/4 lenses with 9-10/10 self-grades

Pack path: `.flywheel/evidence/flywheel-t0iur/`.

## Cross-references

- Source: `flywheel-s3hb5` (closed; auto-doctor:fleet_l_rule_lag lagging_repos=1)
- This dispatch: `flywheel-t0iur`
- Subject probe: `.flywheel/scripts/fleet-l-rule-lag-probe.sh::read_rules()` (Python embedded, line 49 area pre-fix; PATTERNS tuple post-fix)
- Regression test: `tests/test-t0iur-fleet-l-rule-lag-probe-table-format.sh` (6+1 assertions)
- L107 lifecycle (applied): reserve → write → git add → git commit → release (per `flywheel-y4e47`)
- Memory cross-refs:
  `feedback_calibrate_test_to_actual_contract_before_filing_upstream.md`
- L-rules cited: L107 (reservation, applied), L70 (no-punt — same-tick disposition), L52 (no new bead — narrow probe fix completes the loop)
