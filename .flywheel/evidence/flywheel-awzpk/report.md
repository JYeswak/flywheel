# flywheel-awzpk — Worker Report

**Task:** [skill-grader] suppress second-person false-positives causing composite-score under-reporting (per flywheel-cbmsx finding)
**Identity:** MagentaPond (codex-pane on flywheel:0.3)
**Repo head pre:** post-t9iva; post: this commit
**Status:** done — citation-context suppression landed; composite 9.0 → 9.29; 8/8 regression test PASS
**Mission fitness:** infrastructure — skill-grader fix surfaced by flywheel-cbmsx audit.

## Verdict

**Citation-context suppression landed in `count_second_person()`.** The grader's second-person regex was firing on SKILL.md sections that DOCUMENT the rule (citing `"you should"` inside double-quotes or backticks while explaining what the grader penalizes). Extended the helper to strip three citation contexts before running the regex:

1. Fenced code blocks (multiline; non-greedy)
2. Double-quoted citations on a single line
3. Inline backtick citations on a single line

Genuine instructional `you should` / `you must` / etc. still caught (test 4 verifies this).

| Metric | Pre-fix | Post-fix |
|---|---|---|
| skill-autoresearch composite_score | 9.0 | **9.29** (+0.29) |
| trigger_quality gate score | 8.0/10 | **10.0/10** |
| Second-person hits in skill-autoresearch SKILL.md | 2 (both inside `("you should")` citations) | 0 |
| Weakest gate | trigger_quality (8.0) | progressive_disclosure (8.0) — different gate now |

## Acceptance gate coverage

The bead description was empty; `flywheel-cbmsx` provides the implicit acceptance: "composite_score under-reporting" → fix the second-person false positives.

| Implicit gate | Status | Evidence |
|---|---|---|
| Identify the FP root cause | DID | Lines 110+194 of `skill-autoresearch/SKILL.md` cite `"you should"` inside table cells documenting what the grader penalizes; the regex `\byou should\b` matched both citations |
| Patch `count_second_person()` to skip citations | DID | Added 3 `re.sub()` strip-passes before the regex loop: fenced code blocks, double-quoted strings, backtick strings |
| Verify composite uplift | DID | skill-autoresearch composite: 9.0 → 9.29; trigger_quality: 8.0 → 10.0 |
| Verify no over-suppression (genuine instructions still caught) | DID | Regression test 4: `"For best results, you should run the validator first."` → 1 hit (caught) |
| Add regression test | DID | `tests/test-awzpk-skill-grader-second-person-fp.sh` (8 assertions, all PASS) |

did=5/5, didnt=none, gaps=none.

## Why citation-context matters

`count_second_person()`'s job is to detect direct INSTRUCTIONAL second-person voice (`you should run X`). When a SKILL.md teaches the grader's rule, it has to CITE the patterns: `"you should"` in a table column or backtick. Penalizing those citations creates a perverse incentive — the more thoroughly a skill documents its quality rules, the worse it scores on the rules.

Convergent with the `feedback_calibrate_test_to_actual_contract_before_filing_upstream` memory rule: the grader's test should match the actual rule (instructional 2nd-person), not its surface form (any literal match of "you should"). The fix narrows the regex to its intended scope.

## Live verification

```bash
# Pre-fix grader output: 2 second-person hits (FPs)
# Post-fix grader output: 0 second-person hits (FPs eliminated)
cd /tmp && python3 ~/.claude/skills/skill-autoresearch/scripts/skill-grader.py \
  --skill-path ~/.claude/skills/skill-autoresearch --verbose 2>&1 \
  | grep "Second-person voice"
# (post) →     [+] Second-person voice: none found

# Composite score uplifted
cd /tmp && python3 ~/.claude/skills/skill-autoresearch/scripts/skill-grader.py \
  --skill-path ~/.claude/skills/skill-autoresearch --json 2>&1 \
  | jq -c '{composite_score, weakest_gate, weakest_score, verdict}'
# (post) → {"composite_score":9.29,"weakest_gate":"progressive_disclosure","weakest_score":8.0,"verdict":"PASS"}

# Regression test 8/8 PASS
bash /Users/josh/Developer/flywheel/tests/test-awzpk-skill-grader-second-person-fp.sh
# (post) → "flywheel-awzpk skill-grader second-person FP test passed (8 assertions)"
```

L112 probe: `bash /Users/josh/Developer/flywheel/tests/test-awzpk-skill-grader-second-person-fp.sh 2>&1 | tail -1` expects literal `flywheel-awzpk skill-grader second-person FP test passed (8 assertions)`.

## Pattern: strip-citation-contexts-before-rule-match

For any pattern-detection rule that's documented in the SKILL.md it grades, the rule must distinguish between:
- **Citing the pattern** (table cells, backticks, fenced code blocks describing the rule)
- **Using the pattern** (actual instructional voice in the prose)

The canonical fix shape: pre-process the input by stripping citation contexts before running the detection regex. Three stripping passes cover the 3 common citation forms (code-block, double-quote, backtick).

This is reusable across any future grader-rule that has the same self-documentation circularity (e.g., banned-words checks, anti-pattern detection, voice-tone rules).

## Files changed

- `~ /Users/josh/.claude/skills/skill-autoresearch/scripts/skill-grader.py` — `count_second_person()` extended with 3 citation-strip passes (+12 lines)
- `+ /Users/josh/Developer/flywheel/tests/test-awzpk-skill-grader-second-person-fp.sh` — 8-assertion regression test (3-state matrix + live grader uplift verification)
- `+ /Users/josh/Developer/flywheel/.flywheel/evidence/flywheel-awzpk/jsm-import-ready.patch` — paired patch artifact (skill is unmanaged but living outside repo)
- `+ /Users/josh/Developer/flywheel/.flywheel/evidence/flywheel-awzpk/report.md` — this file

## Three-Q

- **VALIDATED:** 8/8 regression test PASS; live grader on skill-autoresearch shows composite 9.0 → 9.29; trigger_quality gate 8.0 → 10.0; second-person hits 2 → 0; genuine instructional 2nd-person still caught.
- **DOCUMENTED:** the citation-vs-use distinction is named with rationale; 3 strip-pass mechanism documented; perverse-incentive rationale (more thorough docs = worse score) called out.
- **SURFACED:** the strip-citation-contexts-before-rule-match pattern is reusable across other self-documenting grader rules (banned-words, anti-patterns, voice-tone). Future grader-rule additions should apply the same pattern.

## Four-Lens Self-Grade

four_lens=brand:9,sniff:9,jeff:10,public:9 — **4/4 PASS**

- **Brand (9/10):** narrowest fix; only `count_second_person()` modified; 12-line pre-process; existing 5-pattern regex preserved.
- **Sniff (9/10):** 8/8 regression test PASS; live grader uplift verified empirically (9.0 → 9.29); over-suppression test ensures genuine instructions still caught.
- **Jeff (10/10):** Jeff functional-shell discipline applied to Python — strip the noise before the signal-detection regex runs. Test fixtures cover both sides (FP suppression + over-suppression check). Reusable pattern for any rule that's documented in the file it grades.
- **Public (9/10):** **Three Judges check** — skeptical operator can re-run the grader and see the score uplift; maintainer reads the citation-vs-use distinction and immediately understands; future grader-rule authors have the pattern as a template.

`evidence_schema_version=worker-evidence/v1`. `extraction_pattern=strip-citation-contexts-before-rule-match/v1`. `four_lens_close_validator_version=four-lens-close-validator/v1`.

## Skill auto-routes addressed

- `canonical-cli-scoping=n/a` — no CLI surface authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=yes` — modified function has type hints (`-> list[str]`); under file-length threshold for the helper; tests use isolated `importlib.util.spec_from_file_location` (no module-pollution); regression test mocks live grader path.
- `readme-writing=n/a` — no README.

## Skill discoveries

`skill_discoveries=1 sd_ids=strip-citation-contexts-before-rule-match-class`

| Kind | Discovery |
|---|---|
| `pattern-emerged` | **Strip-citation-contexts-before-rule-match class:** for any pattern-detection rule that's documented in the SKILL.md it grades, pre-process the input by stripping citation contexts (fenced code blocks, double-quoted strings, backtick strings) before running the detection regex. Otherwise the more thoroughly a skill documents its quality rules, the worse it scores. Reusable across grader rules for second-person voice, banned words, anti-patterns, voice-tone, and similar self-documenting checks. |

## L52 / L70 receipt

- L52 (issues-to-beads): **`no_bead_reason=phase-awzpk-fix-completed-no-new-bead-needed`**.
- L70 (no-punt): the next-actionable IS this fix — completed in this tick.

## L61 ecosystem-touch

- `agents_md_updated=no` — no L-rule promotion (yet).
- `readme_updated=not_applicable` — no README touched.
- `no_touch_reason=narrow-grader-fix-no-doctrine-change-yet`

## Compliance Pack

Score: 940/1000.

- 5/5 acceptance gates DID
- 8/8 regression test PASS
- Empirical composite uplift verified (9.0 → 9.29)
- L107 reservation acquired + released after commit (per flywheel-y4e47 lifecycle)
- 4/4 lenses with 9-10/10 self-grades

Pack path: `.flywheel/evidence/flywheel-awzpk/`.

## Cross-references

- Surfaced by: `flywheel-cbmsx` (canonical-cli-scoping resolve skill-autoresearch major-rework residuals)
- This dispatch: `flywheel-awzpk`
- Subject grader: `~/.claude/skills/skill-autoresearch/scripts/skill-grader.py::count_second_person()` (lines 331-365 post-edit)
- Subject SKILL.md (where FPs were found): `~/.claude/skills/skill-autoresearch/SKILL.md` lines 110, 194
- Regression test: `tests/test-awzpk-skill-grader-second-person-fp.sh` (8 assertions: syntax + 3 citation-strip + over-suppression check + live grader + composite uplift + gate-score uplift)
- L107 lifecycle (applied): reserve → write → git add → git commit → release (per `flywheel-y4e47`)
- Patch artifact: `.flywheel/evidence/flywheel-awzpk/jsm-import-ready.patch`
- Memory cross-refs:
  `feedback_calibrate_test_to_actual_contract_before_filing_upstream.md`
- L-rules cited: L107 (reservation, applied), L70 (no-punt — same-tick disposition), L52 (no new bead — narrow grader fix completes the loop)
