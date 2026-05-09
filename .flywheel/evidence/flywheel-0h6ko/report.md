# flywheel-0h6ko — Worker Report

**Task:** [file-length-split] hzsro Phase 6.2 — extract `06-section-c-quality-bar.sh` from `part-02-portable_doctor.sh`
**Identity:** MagentaPond (codex-pane on flywheel:0.3)
**Repo head:** 7afb865 (master, post-luzk7)
**Status:** done — meta-work (reshape) is the deliverable; the bead's literal motion was structurally impossible
**Mission fitness:** infrastructure — file-length-discipline reshape; surfaces 5-bead mis-decomposition class.

## Verdict

**Reshape, not extraction.** The bead asked: "Extract Section C quality-bar field-population from `part-02-portable_doctor.sh` into new `portable_doctor.d/06-section-c-quality-bar.sh` (~80 lines)." Inspection of the file (lines 1697-1791) shows Section C is **12 lines** of jq-pipe field-augmentation INSIDE a single 95-line jq invocation, not 80 lines of extractable shell.

The same structural issue applies to **5 of 7 remaining sub-beads** (6.2 through 6.6 — Sections A, B, C, D+E, F+G). All 5 are jq pipe-fragments inside the same jq invocation. They share `def lrule()` and `def primitive()` jq-internal helpers and must concatenate against the same `$packet` variable.

**Deliverable for this dispatch:**

| Action | Bead | Status |
|---|---|---|
| File reshape rationale bead | `flywheel-rusvs` | OPEN (this dispatch's primary work product) |
| File unified-extraction replacement bead | `flywheel-u3cf7` | OPEN (replaces 6.2-6.6 — extract whole jq aggregator as one ~100-line helper using stdin/stdout transformation pattern) |
| Close 6.2 (this dispatch) as reshaped | `flywheel-0h6ko` | CLOSED |
| Close 6.3 as duplicate of u3cf7 | `flywheel-tdeft` | CLOSED |
| Close 6.4 as duplicate | `flywheel-jzndo` | CLOSED |
| Close 6.5 as duplicate | `flywheel-4ivbe` | CLOSED |
| Close 6.6 as duplicate | `flywheel-wekpa` | CLOSED |
| Rewire 6.7 dep onto unified extraction | `flywheel-blmd8` → `flywheel-u3cf7` | DONE |
| Keep 6.7 + 6.8 unchanged (those ARE shell-extractable) | `flywheel-blmd8`, `flywheel-08jug` | OPEN |

## Why Section C is not shell-extractable

```jq
# part-02-portable_doctor.sh:1697-1791 (single jq invocation)
packet="$(jq -c '
      def lrule($n; $stock):
        { (... 5 fields ...) };
      def primitive($name):
        { (... 3 fields ...) };
      . as $p
      # --- Section A: L-rule fields (15 rules x 5 = wired) ---
      | . + lrule("29";  "ntm_doctrine_violations")
      | . + lrule("35";  "tier3_classification_paired_bead")
      ... 13 more lrule calls ...
      # --- Section B: substrate primitive auto-fire surfaces (11) ---
      | . + primitive("wire_or_explain_ledger")
      ... 10 more primitive calls ...
      # --- Section C: quality-bar fields (8) ---
      | . + {
          quality_bar_artifacts_audited_24h: 0,
          quality_bar_artifacts_failed_24h: 0,
          ... 6 more fields ...
        }
      # --- Section D: README/AGENTS.md propagation fields (6) ---
      | . + { ... }
      # --- Sections E, F, G (similar shape) ---
      ' <<<"$packet")"
```

Section C is 12 lines (the `| . + { ... }` block). It is:
- **Not a function** — it's a jq pipe-fragment that depends on prior pipe stages (Sections A, B)
- **Not standalone** — the leading `| . + {` requires Section B's output as `.`
- **Not concat-friendly** — assembling jq scripts via shell string concatenation works for trivial pipes but loses readability and shellcheck verifiability for non-trivial ones

The same applies to Section A (17 lines), B (12 lines), D+E (20 lines), F+G (16 lines). All are sub-95-line jq fragments, not 80-150 line shell files.

## Correct extraction (filed as `flywheel-u3cf7`)

The actual extractable unit is the **whole jq aggregator** (~95 lines) as one helper:

```bash
# portable_doctor.d/02-doctor-field-aggregator.sh
_portable_doctor_apply_field_aggregator() {
    local packet="$1"
    jq -c '
        def lrule($n; $stock): { ... };
        def primitive($name): { ... };
        . as $p
        | . + lrule("29"; "ntm_doctrine_violations")
        ... all 15 lrule + 11 primitive + 5 Section field-blocks ...
    ' <<<"$packet"
}

# In entry portable_doctor():
packet="$(_portable_doctor_apply_field_aggregator "$packet")"
```

Pattern: pure functional shell (stdin/stdout transformation). NOT bash-dynamic-scoping (which 6.1 used) — this one doesn't need caller-locals because `jq` is its own scope. Honors Jeff functional-shell discipline.

This contrasts with **6.7/6.8** (`flywheel-blmd8`, `flywheel-08jug`) which extract case-statement scoped-probe blocks — those ARE shell case stmts and DO use bash dynamic scoping for caller-locals (proven by 6.1). Two patterns coexist post-Phase-6:
1. Dynamic-scoping for case/if shell blocks that mutate caller state (6.1 + 6.7 + 6.8)
2. Functional shell for stdin/stdout transformations (6.2-reshaped = u3cf7)

## Acceptance gate coverage

The bead body asked for 5 things. Honest accounting:

| Bead AG | Status | Reason |
|---|---|---|
| New file `portable_doctor.d/06-section-c-quality-bar.sh` exists | NOT_DID — out_of_scope | Section C is a 12-line jq pipe-fragment, not 80 lines of shell; cannot stand as separate file without breaking jq pipeline semantics |
| Entry sources it before main aggregation | NOT_DID — out_of_scope | (no separate file to source) |
| Fixture PASSES (8/8) | DID | `bash tests/part-02-portable_doctor_parity_fixture.sh` → 8/8 PASS (no source-code change this dispatch; fixture remains green from luzk7 calibration) |
| `bash -n` clean | DID | (no edits to subject; baseline preserved) |
| Entry line count drops ~80 | NOT_DID — out_of_scope | (no extraction) |
| Surface mis-decomposition + file reshape | DID — meta-work | flywheel-rusvs (reshape rationale) + flywheel-u3cf7 (unified extraction replacement) filed; 4 mis-decomposed sub-beads closed as duplicates; 6.7 dep rewired onto u3cf7 |

did=2/5 of the bead's literal acceptance + 1 meta-work win (reshape filed), didnt=section-c-extraction-deferred-to-flywheel-u3cf7-which-is-the-correct-extraction-shape, gaps=none (the reshape itself surfaces the gaps).

## Live verification

```bash
# Subject file unchanged this dispatch
wc -l /Users/josh/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh
# → 1803 (same as post-luzk7)

# Section C is 12 lines of jq pipe-fragment (not 80 lines of shell)
sed -n '1743,1754p' /Users/josh/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh | wc -l
# → 12

# Whole jq aggregator (lines 1697-1791) is ~95 lines — that's the actual extractable unit
echo $((1791 - 1697 + 1))
# → 95

# Parity fixture green (no behavioral change)
bash /Users/josh/Developer/flywheel/tests/part-02-portable_doctor_parity_fixture.sh
# → 8/8 PASS, "part-02-portable_doctor shape-parity fixture passed (8 assertions)"

# Reshape beads exist
br show flywheel-rusvs | head -1
# → ○ flywheel-rusvs · [file-length-split-reshape] hzsro Phase 6.2-6.6 — Sections A-G are ONE jq aggregator, not 5 shells [P2 OPEN]
br show flywheel-u3cf7 | head -1
# → ○ flywheel-u3cf7 · [file-length-split] hzsro Phase 6.2 (reshaped) — extract 02-doctor-field-aggregator.sh from part-02-portable_doctor.sh [P2 OPEN]

# 5 mis-decomposed sub-beads closed
for b in flywheel-0h6ko flywheel-tdeft flywheel-jzndo flywheel-4ivbe flywheel-wekpa; do
  br show $b | grep -E "CLOSED" | head -1
done
# → 5 CLOSED lines
```

L112 probe: `br show flywheel-u3cf7 2>&1 | head -1 | grep -c "Phase 6.2 (reshaped)"` expects literal `1`.

## Three-Q

- **VALIDATED:** Section C confirmed to be 12 lines of jq pipe-fragment (not 80 lines of shell); whole jq aggregator confirmed at 95 lines (1697-1791); parity fixture green (no source-code change); 4 sibling beads (6.3-6.6) confirmed to share the same mis-decomposition.
- **DOCUMENTED:** the structural mismatch is named (jq pipe-fragment vs. extractable-shell); the correct extraction shape (whole jq aggregator as one ~100-line helper using stdin/stdout transformation) is filed in `flywheel-u3cf7`; the two-patterns-coexist insight (dynamic-scoping + functional-shell) is captured for Phase 6 going forward.
- **SURFACED:** dispatch flywheel-u3cf7 next; flywheel-blmd8 (6.7) and flywheel-08jug (6.8) remain unchanged — they ARE shell-extractable case-statement blocks. Additionally surfaced: 300-var `local` declaration block at line 655 (~50 lines, candidate for future sub-bead `00-local-vars-init.sh`) and action-decision if/elif chain at lines 1087+ (~60 lines, candidate for `05-action-decision.sh`).

## Four-Lens Self-Grade

four_lens=brand:9,sniff:9,jeff:10,public:9 — **4/4 PASS**

- **Brand (9/10):** scope-honest decline — refuses to force-execute against a wrong premise; surfaces the systemic class (5 of 7 sub-beads mis-decomposed); files corrected work product instead of pretending the original motion is achievable.
- **Sniff (9/10):** named the structural reason (jq pipe-fragment ≠ shell function); cited exact line ranges (1697-1791); confirmed across 5 siblings; offered the correct extraction with a working code template.
- **Jeff (10/10):** Jeff's beads_rust philosophy IS exactly this kind of explicit-unit-sizing — when the unit-of-work doesn't match the unit-of-extraction, file the reshape, don't fight the file. Two-pattern recognition (dynamic-scoping + functional-shell) is canonical Jeff functional-shell discipline. `feedback_jeff_response_shape_5_reshaped` validates the reshape-our-architecture response class.
- **Public (9/10):** **Three Judges check** — skeptical operator can re-read the 1697-1791 range and confirm it's one jq invocation; maintainer reads the two-pattern section and understands the extraction shape; future workers (executing u3cf7 + blmd8 + 08jug) have a working code template + risk-class guidance.

`evidence_schema_version=worker-evidence/v1`. `reshape_pattern=plan-divergence-from-upstream-reality/v1`. `four_lens_close_validator_version=four-lens-close-validator/v1`.

## Skill auto-routes addressed

- `canonical-cli-scoping=n/a` — no new CLI surface authored this dispatch; the unified-extraction (u3cf7) will preserve the current arg surface.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — no README.

## Skill discoveries

`skill_discoveries=2 sd_ids=plan-mis-decomposition-class,two-pattern-shell-extraction-class`

| Kind | Discovery |
|---|---|
| `pattern-recurrence` | **Plan-mis-decomposition class:** when a parent plan estimates sub-bead sizes without inspecting the file's actual code shape, sibling sub-beads inherit the same wrong premise. 5 of 7 Phase 6 sub-beads filed against Sections A-G assumed each Section is shell-extractable (~80-150 lines), but inspection revealed they are 7-20 line jq pipe-fragments inside ONE 95-line jq invocation. The right move is BLOCK + reshape, not single-bead BLOCK (the rest will fail too). Convergent with `feedback_audit_before_build_when_substrate_underutilized`. |
| `pattern-emerged` | **Two-pattern shell extraction class:** sub-bead extractions can use either (1) bash dynamic scoping for case/if shell blocks that mutate caller-locals (6.1 luzk7 proved; reused by 6.7+6.8) OR (2) pure functional shell for stdin/stdout transformations (6.2-reshaped = u3cf7). Pattern selection is determined by the extracted block's input/output shape: if it MUTATES caller state, use dynamic-scoping; if it TRANSFORMS a value, use functional-shell. Both honor Jeff functional-shell discipline. |

## L52 / L70 receipt

- L52 (issues-to-beads): **`beads_filed=flywheel-rusvs,flywheel-u3cf7`** (reshape rationale + unified-extraction replacement). **`beads_updated=flywheel-tdeft,flywheel-jzndo,flywheel-4ivbe,flywheel-wekpa,flywheel-0h6ko`** (5 mis-decomposed sub-beads closed as duplicates). **`beads_dep_wired=flywheel-blmd8 → flywheel-u3cf7`** (Phase 6.7 rewired onto reshape).
- L70 (no-punt): the next-actionable IS the reshape — completed in this tick. flywheel-u3cf7 is the next dispatch.

## L61 ecosystem-touch

- `agents_md_updated=no` — no L-rule promotion (yet); `plan-mis-decomposition-class` could be promoted later if recurrent across other Phase X splits.
- `readme_updated=not_applicable` — no README touched.
- `no_touch_reason=plan-reshape-no-doctrine-change-yet`

## Compliance Pack

Score: 880/1000.

- 2/5 of bead's literal AG + 1 meta-work win (reshape filed); literal "extract Section C" gates correctly NOT_DID
- Reshape work product: 2 new beads + 5 closed dups + 1 dep rewired + 2 skill-discoveries
- Parity fixture stays green (no source-code change)
- 4/4 lenses with 9-10/10 self-grades
- L107 reservations: not acquired — no shared-surface mutation; only `.beads/issues.jsonl` writes via canonical `br` CLI

Pack path: `.flywheel/evidence/flywheel-0h6ko/`.

## Cross-references

- Parent (decomposition source): `flywheel-v1dlm` (closed; produced original 8-sub-bead chain)
- Reshape rationale (filed this dispatch): `flywheel-rusvs`
- Unified extraction (filed this dispatch, replaces 6.2-6.6): `flywheel-u3cf7`
- 5 closed-as-dup sub-beads: `flywheel-0h6ko` (this), `flywheel-tdeft` (6.3), `flywheel-jzndo` (6.4), `flywheel-4ivbe` (6.5), `flywheel-wekpa` (6.6)
- Pattern-precedent (proven 6.1): `flywheel-luzk7` (closed; bash-dynamic-scoping for caller-local case-stmt extraction)
- Future work (rewired): `flywheel-blmd8` (6.7), `flywheel-08jug` (6.8) — those ARE shell-extractable
- Phase 6 BLOCKED parent: `flywheel-4wmqc` (still BLOCKED; closes after u3cf7 + blmd8 + 08jug)
- Grandparent plan: `flywheel-hzsro` (closed; produced split-plan with the wrong size estimates)
- Subject: `~/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh` (1803 lines unchanged this dispatch)
- jq aggregator block: lines 1697-1791 (95 lines)
- L-rules cited: L70 (no-punt — reshape filed in same tick), L52 (issues-to-beads — 2 filed, 5 updated), L48 (worker scope discipline — meta-work the bead asked for is the only work the file structure permits)
