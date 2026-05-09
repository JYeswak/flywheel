# flywheel-luzk7 — Worker Report

**Task:** [file-length-split] hzsro Phase 6.1 — extract `01-arg-parse.sh` from `part-02-portable_doctor.sh`
**Identity:** MagentaPond (codex-pane on flywheel:0.3)
**Repo head pre:** d5cdb74; post: this commit
**Status:** done
**Mission fitness:** infrastructure — file-length-discipline split execution; pattern proof for sub-beads 6.2-6.8.

## Verdict

**Phase 6.1 (lowest-risk pattern proof) executed.** Argument parsing extracted into `portable_doctor.d/01-arg-parse.sh` via bash dynamic scoping. Helper assigns to caller's `local`-declared vars without redefining them — the canonical no-self-local extraction shape that sub-beads 6.2-6.8 will reuse.

| Metric | Pre | Post |
|---|---:|---:|
| `part-02-portable_doctor.sh` lines | 1836 | 1803 (-33) |
| `portable_doctor.d/01-arg-parse.sh` lines | (didn't exist) | 59 (incl. header + comments) |
| Inline arg-parse loop in entry | 43 lines (lines 11-51) | 1 line (`_portable_doctor_parse_args "$@"`) |
| Helper sourced before function definition | n/a | `source "$_PD_HELPER_DIR/01-arg-parse.sh"` |
| Parity fixture | 8/8 PASS | 8/8 PASS (after fixture calibration to multi-file search) |
| `bash -n` clean | YES | YES (both files) |
| Behavioral parity (3 synthetic invocations) | n/a | ALL PASS |

**Note on line-drop estimate:** bead body said "drops by ~50". Actual drop is 33 lines. Difference is because the original inline `local strict=...` declaration line stays in the entry function (the helper depends on it being in caller scope), and 6 new lines were added (helper-source preamble: 5 comment+code lines + 1 source line). Net loss of inline-arg-parse-loop body = 42 lines (43 → 1). The bead's "~50" was an estimate; the canonical motion is preserved.

## Acceptance gate coverage

The bead body's acceptance is enumerated:

| Bead AG | Status | Evidence |
|---|---|---|
| New file `portable_doctor.d/01-arg-parse.sh` exists | DID | `ls /Users/josh/.claude/skills/.flywheel/lib/portable/core.d/portable_doctor.d/01-arg-parse.sh` (59 lines) |
| Entry sources it before main aggregation | DID | line ~7 of entry: `source "$_PD_HELPER_DIR/01-arg-parse.sh"` (sourced at file-load time, before `portable_doctor()` runs) |
| Parity fixture PASSES (8/8) | DID | `bash tests/part-02-portable_doctor_parity_fixture.sh` → "part-02-portable_doctor shape-parity fixture passed (8 assertions)" |
| `bash -n` clean on both files | DID | `bash -n` exits 0 on both entry and helper |
| Entry line count drops ~50 | PARTIAL — drops 33 (not 50) | bead estimate was approximate; the 43-line inline loop becomes 1 line + 6 lines of source-preamble; net -33 (or -42 from the loop body alone) |

did=4/5 (1 partial), didnt=none, gaps=none.

## Calibration of parity fixture (META)

**Issue:** original fixture asserted flag literals exist in `$LIB_PATH` (entry file only). Post-extraction, the literals live in the helper.

**Fix per `feedback_calibrate_test_to_actual_contract_before_filing_upstream`:** the contract is "flag-surface preserved in the loaded code", not "literals in entry file". Updated assertion 5+6 to search `$LIB_PATH` AND any sibling `portable_doctor.d/*.sh` helpers. The expanded search-path list is built at fixture-time via `find -maxdepth 1 -type f -name "*.sh"`. This pattern naturally absorbs each future sub-bead extraction (6.2-6.8) without further fixture edits.

This is the FIRST canonical fixture-calibration for the Phase 6 split. The fixture's reach grows as new helpers land.

## Live verification

```bash
# Pre-edit: 1836 lines, allow-large receipt cited, no portable_doctor.d/
wc -l /Users/josh/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh
# → 1836

# Post-edit: 1803 lines + helper exists
wc -l /Users/josh/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh \
      /Users/josh/.claude/skills/.flywheel/lib/portable/core.d/portable_doctor.d/01-arg-parse.sh
# → 1803 + 59 = 1862 total

# Allow-large receipt still cited (will be removed when 6.8 lands and entry shrinks below threshold)
grep -c canonical-cli-scoping-allow-large /Users/josh/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh
# → 1

# Parity fixture green post-extraction
bash /Users/josh/Developer/flywheel/tests/part-02-portable_doctor_parity_fixture.sh
# → 8/8 PASS, "part-02-portable_doctor shape-parity fixture passed (8 assertions)"

# Both functions load via core.sh dispatcher
bash -c 'source ~/.claude/skills/.flywheel/lib/portable/core.sh && type _portable_doctor_parse_args portable_doctor | head -2'
# → "_portable_doctor_parse_args is a function"
# → "portable_doctor is a function"

# Behavioral parity: 3 invocation shapes parse identically
# (synthetic caller with portable_doctor's local-decl shape)
# 1. --strict --fix --scope wire-or-explain validate --storage-min-free-gb 99 --storage-min-free-pct=5 some-positional
#    → strict=1 fix=1 scope=wire-or-explain scope_cmd=validate gb=99 pct=5 args=some-positional ✓
# 2. --scope=wire-or-explain why some-bead-id
#    → scope=wire-or-explain scope_cmd=why scope_cmd_arg=some-bead-id ✓
# 3. plain-positional --strict
#    → strict=1 args=plain-positional ✓
```

L112 probe: `bash /Users/josh/Developer/flywheel/tests/part-02-portable_doctor_parity_fixture.sh 2>&1 | tail -1` expects literal `part-02-portable_doctor shape-parity fixture passed (8 assertions)`.

## Pattern: bash dynamic scoping for caller-local population

The canonical no-self-local extraction shape (sub-beads 6.2-6.8 will reuse this):

**Caller (entry function):**
```bash
portable_doctor() {
    local strict=0 fix=0 scope="" scope_cmd="" scope_cmd_arg="" \
          storage_min_free_gb="${FLYWHEEL_STORAGE_MIN_FREE_GB:-50}" \
          storage_min_free_pct="${FLYWHEEL_STORAGE_MIN_FREE_PCT:-10}"
    local args=()
    _portable_doctor_parse_args "$@"
    # caller's locals are now populated by helper
    parse_repo_args "${args[@]+"${args[@]}"}"
    ...
}
```

**Helper (`01-arg-parse.sh`):**
```bash
_portable_doctor_parse_args() {
    local arg              # helper-local; doesn't shadow caller's vars
    while [[ $# -gt 0 ]]; do
        arg="$1"
        if [[ "$arg" == "--strict" ]]; then
            strict=1       # bash dynamic scoping → caller's `local strict`
            shift
        ...
    done
}
```

**Why this works:** bash's `local` creates dynamic scope. When a function calls another, the called function sees the caller's locals as in-scope, mutable variables. Assignments resolve to the nearest enclosing `local` declaration. The helper's `arg` is its own (`local arg`), but `strict`, `scope`, `args`, etc. all resolve to caller's locals.

**Why this is the safest extraction shape:** no `declare -g` (avoids polluting global namespace); no return-channel marshalling (no JSON or eval); helper is purely procedural with caller-scope side effects. The contract is small: caller declares the locals, helper modifies them.

**Risk class for 6.2-6.8:** the larger Section blocks (6.4-6.6) and especially the scoped-probe blocks (6.7, 6.8) close over more caller locals (e.g. `JSON_OUT`, `json_section_*`, accumulator arrays). Same pattern applies — caller declares, helper modifies. Behavioral fixtures must catch any forgotten `local` declaration.

## Files changed

- `~ /Users/josh/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh` — entry: source helper preamble (5 lines added) + replace 43-line inline arg-parse with 1-line call (1836 → 1803)
- `+ /Users/josh/.claude/skills/.flywheel/lib/portable/core.d/portable_doctor.d/01-arg-parse.sh` — new helper module (59 lines incl. header)
- `~ /Users/josh/Developer/flywheel/tests/part-02-portable_doctor_parity_fixture.sh` — assertion 5+6 calibrated to multi-file search (entry + portable_doctor.d/*.sh)
- `+ /Users/josh/Developer/flywheel/.flywheel/evidence/flywheel-luzk7/jsm-import-ready.patch` — paired patch artifact for unmanaged-skill direct mutation (per dispatch JSM block)
- `+ /Users/josh/Developer/flywheel/.flywheel/evidence/flywheel-luzk7/report.md` — this file

## Three-Q

- **VALIDATED:** 8/8 fixture assertions PASS post-extraction; 3 synthetic invocations parse correctly; both functions load via dispatcher; bash -n clean.
- **DOCUMENTED:** the bash-dynamic-scoping pattern is named with rationale and a code template for sub-beads 6.2-6.8; fixture-calibration META section names the contract (flag-surface preserved in loaded code) vs the prior implementation (literals in entry-only).
- **SURFACED:** Pattern proven for the safest case (no JSON_OUT crossing, no accumulator arrays). Sub-bead 6.2 (`flywheel-0h6ko`, Section C) is the next-actionable; expect more caller locals in scope.

## Four-Lens Self-Grade

four_lens=brand:9,sniff:9,jeff:9,public:9 — **4/4 PASS**

- **Brand (9/10):** scope-respecting — only the arg-parse block extracted; no other refactor; allow-large receipt left cited (will be removed by 6.8 when entry shrinks below threshold); paired jsm-import-ready patch artifact saved per unmanaged-skill discipline.
- **Sniff (9/10):** parity fixture green; behavioral parity verified across 3 invocation shapes; line-drop honest (33, not the bead's "~50" estimate).
- **Jeff (9/10):** bash dynamic scoping is the canonical Jeff pattern for shell function-body extraction (avoids `declare -g` namespace pollution; avoids return-channel marshalling); cited operational primitives (`source`, `wc -l`, `grep -qhE`); fixture-calibration follows `feedback_calibrate_test_to_actual_contract_before_filing_upstream`.
- **Public (9/10):** **Three Judges check** — skeptical operator can re-run fixture + behavioral test and confirm parity; maintainer reads the pattern section and understands the dynamic-scoping contract; future workers (sub-beads 6.2-6.8) have a working code template + risk-class guidance.

`evidence_schema_version=worker-evidence/v1`. `extraction_pattern=bash-dynamic-scoping/v1`. `four_lens_close_validator_version=four-lens-close-validator/v1`.

## Skill auto-routes addressed

- `canonical-cli-scoping=yes` — flag surface preserved (6 flags + scope-subcommand matrix); helper file under file-length threshold (59 lines vs 500-line shell threshold); allow-large receipt on entry left cited honestly (will be removed when post-Phase-6 split brings entry under 500).
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — no README.

## Skill discoveries

`skill_discoveries=1 sd_ids=fixture-calibration-on-extraction-class`

| Kind | Discovery |
|---|---|
| `pattern-emerged` | Fixture-calibration on extraction: when a parity fixture asserts properties of a single file but the file gets split, the fixture must expand its search-path to cover the new helper(s), not be reverted. The contract is the property (flags preserved in loaded code), not the file (entry-file only). Per `feedback_calibrate_test_to_actual_contract_before_filing_upstream`. Reusable across all 8 sub-beads of Phase 6. |

## L52 / L70 receipt

- L52 (issues-to-beads): **`no_bead_reason=phase-6.1-pattern-proof-completed-sub-beads-6.2-through-6.8-already-filed-by-flywheel-v1dlm-no-new-bead-needed`**.
- L70 (no-punt): the next-actionable IS this extraction + fixture re-verification — completed in this tick.

## L61 ecosystem-touch

- `agents_md_updated=no` — no L-rule promotion (yet); the dynamic-scoping pattern + fixture-calibration class could be promoted later if 6.2-6.8 reuse them cleanly.
- `readme_updated=not_applicable` — no README touched.
- `no_touch_reason=phase-6.1-extraction-execution-no-doctrine-change-yet`

## Compliance Pack

Score: 910/1000.

- 4/5 acceptance gates DID + 1 partial (line-drop estimate); fixture green; behavioral parity verified
- jsm-import-ready patch artifact saved (unmanaged-skill direct mutation discipline)
- Pattern documented for 6.2-6.8 reuse
- 4/4 lenses with 9/10 self-grades
- L107 reservations acquired (entry + new helper) and released

Pack path: `.flywheel/evidence/flywheel-luzk7/`.

## Cross-references

- Parent: `flywheel-v1dlm` (closed; produced 8-sub-bead decomposition)
- Sibling Phase 6 sub-beads (6.2-6.8): `flywheel-0h6ko`, `flywheel-tdeft`, `flywheel-jzndo`, `flywheel-4ivbe`, `flywheel-wekpa`, `flywheel-blmd8`, `flywheel-08jug`
- Phase 6 BLOCKED parent: `flywheel-4wmqc` (reopens after 6.8)
- Grandparent plan: `flywheel-hzsro` (closed; produced split-plan)
- Parity oracle: `tests/part-02-portable_doctor_parity_fixture.sh` (fixture-calibrated this dispatch to multi-file search)
- Subject entry: `~/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh` (1803 lines post; was 1836)
- New helper: `~/.claude/skills/.flywheel/lib/portable/core.d/portable_doctor.d/01-arg-parse.sh` (59 lines)
- Patch artifact: `.flywheel/evidence/flywheel-luzk7/jsm-import-ready.patch`
- L-rules cited: L107 (shared-surface reservation, applied), L70 (no-punt), L52 (issues-to-beads — no new bead, sub-bead 6.2 already filed by v1dlm)
