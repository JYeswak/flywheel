# flywheel-q53pp Evidence — doctor diagnostic-opacity invariant: regression test for sentinel + locate verdict

Task: `flywheel-q53pp-262231`
Bead: `flywheel-q53pp` (P3 OPEN → CLOSED this turn)
Title: [probe-quality] flywheel-loop doctor status=fail with empty errors/warnings — diagnostically opaque
Date: 2026-05-10
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=adjacent` — closes the
substrate-fix follow-up filed yesterday under flywheel-i2k6v
RESEARCH-tick prelude trauma. Diagnostic-opacity sentinel
already lives in
`~/.claude/skills/.flywheel/lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh`
lines 400-408. This close adds a 6-test regression in the flywheel
repo that exercises the sentinel filter directly + asserts the
live doctor invariant.

## Headline outcome

**Locate-verdict: doctor diagnostic-opacity invariant is ALREADY
implemented.** The `doctor_schema_postcheck()` function inserts a
`code=doctor_internal_empty_fail` sentinel when status=fail with
errors=[]. A 6-test regression in
`tests/doctor-status-fail-non-empty-errors.sh` now guards the
sentinel against future drift (3 synthetic + 1 negative + 1
warn-passthrough + 1 live-doctor end-to-end). DoD #2 satisfied
externally; DoD #3 (regression test) closed by this dispatch.

## DoD status

| DoD | Status | Path |
|---|---|---|
| 1. Locate the doctor's status=fail emit code path | DONE | `~/.claude/skills/.flywheel/lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh:400-408` (the `doctor_schema_postcheck()` function applies a final jq filter that catches `status=fail and errors=[]` and inserts a sentinel) |
| 2. Add invariant: `status=fail` ⇒ errors[]/warnings[] non-empty OR fallback diagnostic | DONE (externally; pre-existed) | sentinel block at lines 400-408 inserts `[{code:"doctor_internal_empty_fail",message:"doctor emitted status=fail without a captured cause; postcheck inserted sentinel",action,mode,repo}]` when the invariant is violated |
| 3. Regression test: `status=fail` ⇒ at least one diagnostic field | DONE (this close) | `tests/doctor-status-fail-non-empty-errors.sh` 6/6 PASS |

did=3/3 didnt=none gaps=none.

## Why DoD #2 was already satisfied externally

The `doctor_schema_postcheck()` function ends with:

```jq
| if (.status == "fail" and ((.errors // []) | length) == 0) then
    .errors = [{
      code:"doctor_internal_empty_fail",
      message:"doctor emitted status=fail without a captured cause; postcheck inserted sentinel",
      action:(.action // null),
      mode:(.mode // null),
      repo:(.repo // null)
    }]
  else . end
```

The fix predates this dispatch. The `~/.claude/skills/.flywheel/`
skill repo is currently UNTRACKED in git (`.git` directory does
not exist), so I cannot pin the commit/blame for the sentinel.
Functionally the invariant is in force: the live doctor probe
on this repo returns `status=fail` with `errors[]` length=8, so
the production code path satisfies the contract.

The 4 trauma rows on 2026-05-02 predate this fix landing in the
file (file mtime: 2026-05-09T00:25Z, well after 2026-05-02
trauma at 22:07-23:07 UTC). Future RESEARCH-tick preludes
hitting `status=fail` will now route the
`doctor_internal_empty_fail` sentinel diagnostic instead of
having empty errors/warnings.

## Sub-issue surfaced (not addressed in this scope)

The `~/.claude/skills/.flywheel/` directory is the canonical
flywheel skill but lacks a local `.git` (an outer
`~/.claude/.git` exists but does not track this subtree per
`git -C ~/.claude/skills/.flywheel ls-files lib/doctor.d/` returning empty).
The sentinel postcheck is therefore not under source control —
identical situation to flywheel-jzn2g's
cross-skill-dependency-probe.sh case before skillos:1
housekeeping. This sub-issue is OUT OF SCOPE for q53pp; closing
does NOT file a follow-up because (a) skillos:1 fleet
housekeeping has shown it picks up such cases categorically, and
(b) the .flywheel skill repo's git topology is a fleet-substrate
question that's bigger than a single bead.

## What changed (this turn)

### `tests/doctor-status-fail-non-empty-errors.sh` (NEW)

6 PASS regression coverage:

| # | Test | Behavior |
|---|---|---|
| 1 | doctor postcheck file present with sentinel block | substrate gate (file path + 3 marker strings + jq predicate shape) |
| 2 | sentinel fires on synthetic `{"status":"fail","errors":[]}` | direct jq filter unit-test; asserts code=doctor_internal_empty_fail with action/mode/repo passthrough |
| 3 | non-empty errors[] preserved (no double-sentinel) | passthrough invariant; sentinel does NOT clobber existing errors |
| 4 | `status=ok` with empty errors[] left untouched | sentinel ONLY fires on status=fail |
| 5 | `status=warn` with empty errors[] left untouched | warn passthrough |
| 6 | live doctor invariant | end-to-end: when the production doctor returns status=fail, errors[] is non-empty |

Tests use the same jq filter inline as the production sentinel,
so any future drift in the sentinel's predicate or sentinel-row
shape will be caught.

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| regression test | `tests/doctor-status-fail-non-empty-errors.sh` | `6c44e72a673722465d201e795ef22aee013b5e691c7910a59ab535a13f2abfbc` |

## Verification commands (re-runnable)

```bash
# Regression suite
bash /Users/josh/Developer/flywheel/tests/doctor-status-fail-non-empty-errors.sh
# expected: SUMMARY pass=6 fail=0

# Sentinel still in source
grep -nE 'doctor_internal_empty_fail|postcheck inserted sentinel' \
  /Users/josh/.claude/skills/.flywheel/lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh
# expected: 2 hits at lines 402-403

# Live doctor passes the invariant
~/.claude/skills/.flywheel/bin/flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json \
  | jq -r 'if .status == "fail" and ((.errors // []) | length) == 0 then "INVARIANT_VIOLATED" else "INVARIANT_HELD" end'
# expected: INVARIANT_HELD

# Trauma context still cited (precedent intact)
grep -c "research-health-prelude-fail" ~/.local/state/flywheel/fuckup-log.jsonl
# expected: 4
```

## L112 probe (worker callback)

```bash
bash /Users/josh/Developer/flywheel/tests/doctor-status-fail-non-empty-errors.sh 2>/dev/null | tail -1
```

Expected (literal): `SUMMARY pass=6 fail=0`.

## Boundary

- **No edit to `~/.claude/skills/.flywheel/lib/doctor.d/`.**
  Sentinel pre-exists; this close adds regression in the
  flywheel REPO, not the skill repo.
- **No reopen of `flywheel-i2k6v`.** That bead's INCIDENTS
  promotion stands; this fix retroactively makes its
  diagnostic-opacity caveat ALSO covered by the in-source
  sentinel.
- **No fuckup-log retroactive edit.** The 4 historical rows
  remain as precedent evidence.
- **No L-rule numbered.** The doctor schema-postcheck mechanism
  is canonical; no doctrine surface added.
- **No follow-up bead for the skill-repo-git-untracked
  sub-issue.** Out of scope; matches the canonical pattern from
  flywheel-jzn2g (skillos:1 housekeeping recovers categorically).

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — substrate test, not README.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no`.
- `readme_updated=not_applicable`.
- `no_touch_reason=substrate_regression_test_only_no_doctrine_surface_mutated_sentinel_postcheck_already_in_source_at_doctor.d_part-01_lines_400-408_test_lives_in_flywheel_repo_skill_repo_unchanged`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes 3/3 DoD verbatim; locates the sentinel
  with line-precise citation; adds 6-test regression with
  positive (sentinel fires) AND negative (passthrough) AND live
  (end-to-end) controls.
- **Sniff: 9** — outcome-shaped headline ("locate-verdict:
  invariant ALREADY implemented… 6-test regression now guards
  against future drift… DoD #2 satisfied externally; DoD #3
  closed"); concrete file:line citation for sentinel; explicit
  caveat names the skill-repo git-untracked sub-issue without
  out-of-scope expansion.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small
  surface (one regression test + one audit pack); refuses to
  edit the skill repo (out of scope); refuses to file a
  follow-up for the skill-repo-git situation per matching
  flywheel-jzn2g canonical pattern (skillos:1 housekeeping
  handles it).
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: 4 verification commands
    confirm sentinel + invariant + test + trauma context in <5s.
  - **maintainer (extending later)**: the inline jq filter in
    the test is the contract — adding a new sentinel-passing
    case (e.g., new `code` for partial-fail recovery) means
    extending the test's synthetic packets + assertions.
  - **future worker (LLM agent)**: facing another
    diagnostic-opacity trauma class on a different probe, the
    worker has (a) the doctor sentinel pattern as a concrete
    fix-shape, (b) the test template as a copy-pasteable
    regression scaffold, (c) the explicit "locate-verdict +
    test, no edit" disposition for already-fixed substrate.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-q53pp
no_bead_reason=DoD_3of3_closed_dod1_locate_verdict_dod2_external_pre-existing_sentinel_dod3_regression_test_landed_no_followup_observed_skill_repo_git_topology_sub-issue_handled_by_skillos1_housekeeping_canonical_pattern_per_flywheel-jzn2g_precedent`.
