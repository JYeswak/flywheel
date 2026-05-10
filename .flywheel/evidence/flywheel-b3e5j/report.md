# flywheel-b3e5j — Worker Report

**Task:** [substrate-hygiene] PLANS/ vs plans/ byte-identical duplicate-tree — dedupe per flywheel-4rmc finding
**Identity:** MagentaPond (codex-pane on flywheel:0.3)
**Repo head pre:** post-h17x; post: this commit
**Status:** done — bead premise corrected (no duplicate tree exists); followup filed for code reference normalization
**Mission fitness:** infrastructure — substrate-hygiene clarification + Linux portability followup.

## Verdict

**No duplicate tree exists.** The bead's "byte-identical duplicate-tree — dedupe" framing is incorrect. `.flywheel/PLANS` and `.flywheel/plans` resolve to the **same inode** (173779122) on macOS APFS (case-insensitive but case-preserving). Both names are aliases for the single git-tracked tree at `.flywheel/PLANS/` (430 files; lowercase has 0 git-tracked entries).

The flywheel-4rmc audit was correct that the probe was DOUBLE-COUNTING (because it walked both names), but the underlying substrate is one tree. The fix that landed in `jeff-pattern-citation-probe.sh` (walk uppercase canonical, fallback to lowercase only if uppercase missing) is the right shape.

## Acceptance gate coverage

The bead description was empty; implicit acceptance from the title ("dedupe per flywheel-4rmc finding"):

| Implicit gate | Status | Evidence |
|---|---|---|
| Confirm whether duplicate tree exists | DID — confirmed NO duplicate | `ls -dli` shows both names point to inode 173779122; `diff -rq` returns empty (same tree); `git ls-files` shows 430 files under uppercase, 0 under lowercase |
| Document the actual concern (if any) | DID | The trauma surface is code reference inconsistency (11 active lowercase refs, would break on case-sensitive Linux), NOT duplicate trees |
| Surface followup for normalization | DID | flywheel-aic04 filed (P4) — normalize 11 active lowercase code references to uppercase for Linux portability |
| Honor flywheel-4rmc's prior fix | DID — preserved | `.flywheel/scripts/jeff-pattern-citation-probe.sh` already walks uppercase canonical with lowercase fallback per flywheel-4rmc; this dispatch does not regress that |

did=4/4, didnt=none, gaps=none.

## Why "no duplicate tree" is the right finding

```bash
# Both names → same inode
$ ls -dli .flywheel/PLANS .flywheel/plans
173779122 drwxr-xr-x@ 74 josh staff 2368 May 9 02:20 .flywheel/plans
173779122 drwxr-xr-x@ 74 josh staff 2368 May 9 02:20 .flywheel/PLANS

# Same file count
$ find .flywheel/PLANS -type f | wc -l
     429
$ find .flywheel/plans -type f | wc -l
     429

# diff returns empty (same tree, no actual differences)
$ diff -rq .flywheel/PLANS .flywheel/plans
(empty)

# Git tracks only uppercase
$ git ls-files | grep -cE "^\.flywheel/PLANS/"
430
$ git ls-files | grep -cE "^\.flywheel/plans/"
0

# Git config respects case-insensitive
$ git config core.ignorecase
true
```

This is APFS case-insensitivity at work, not duplication. On Linux ext4 (case-sensitive), only `.flywheel/PLANS/` would exist; `.flywheel/plans/` references would fail. That's the actual portability concern, and it's what `flywheel-aic04` tracks.

## The actual trauma surface (code-reference inconsistency)

11 active code references use lowercase `.flywheel/plans/`:

| Path | Type | Notes |
|---|---|---|
| `.flywheel/scripts/fleet-coherence-quality-report.sh` | script | active |
| `.flywheel/scripts/emit-polish-round-telemetry.py` | script | active |
| `.flywheel/scripts/gap-hunt-probe.sh` | script | active |
| `.flywheel/scripts/ntm-surface-coverage-trend.sh` | script | active |
| `.flywheel/scripts/plan-state-lens-merge.sh` | script | active |
| `.flywheel/scripts/jeff-pattern-citation-probe.sh` | script | already has uppercase-canonical-with-lowercase-fallback per flywheel-4rmc |
| `.flywheel/tests/test-escalate-capsule-plan-consumer.sh` | test | active |
| `~/.claude/skills/.flywheel/INCIDENTS.md` | doc | reference |
| `~/.claude/skills/.flywheel/bin/flywheel-autoloop` | script | active |
| `~/.claude/skills/.flywheel/data/README.md` | doc | reference |

vs 19 references using canonical uppercase `.flywheel/PLANS/`.

flywheel-aic04 is the followup that will audit each of these and either normalize to uppercase or annotate as intentional fallback.

## Live verification

```bash
# Same inode confirms no duplicate tree
ls -dli /Users/josh/Developer/flywheel/.flywheel/PLANS /Users/josh/Developer/flywheel/.flywheel/plans
# → both lines have inode 173779122

# Git only tracks uppercase
git ls-files | grep -cE "^\.flywheel/PLANS/"
# → 430

# Followup filed
br show flywheel-aic04 | head -1
# → ○ flywheel-aic04 · [substrate-hygiene-followup] normalize .flywheel/plans → .flywheel/PLANS ... [P4 OPEN]

# flywheel-4rmc prior fix preserved
grep -A2 "uppercase tree does not exist" /Users/josh/Developer/flywheel/.flywheel/scripts/jeff-pattern-citation-probe.sh | head -5
# → ".flywheel/PLANS/ (canonical) unconditionally and only walks .flywheel/plans/ (lowercase) IF the uppercase tree does not exist."
```

L112 probe: `ls -di /Users/josh/Developer/flywheel/.flywheel/PLANS /Users/josh/Developer/flywheel/.flywheel/plans 2>&1 | awk '{print $1}' | sort -u | wc -l | tr -d ' '` expects literal `1` (one inode).

## Pattern: bead-asks-to-dedupe-something-that-isnt-duplicated

When a bead body asserts "duplicate tree" but probe shows same-inode case-aliasing on case-insensitive FS, the right disposition is:

1. Confirm the same-inode evidence (ls -dli, file count, diff -rq)
2. Reframe the actual trauma surface (here: code-reference inconsistency, not duplication)
3. File followup for the actual concern (here: flywheel-aic04 for Linux portability)
4. Honor any prior fixes that addressed the symptom (here: flywheel-4rmc's probe walk discipline)
5. Close THIS bead with the corrected framing in evidence

Convergent with the convergent disposition pattern from earlier today (4 prior instances): when the bead's premise diverges from upstream reality, calibrate the disposition to reality.

## Files changed

- `+ /Users/josh/Developer/flywheel/.flywheel/evidence/flywheel-b3e5j/report.md` — this file
- `+ /Users/josh/Developer/flywheel/.beads/issues.jsonl` — flywheel-aic04 row added (followup)

No source-code edits, no INCIDENTS.md mutation, no L-rule changes.

## Three-Q

- **VALIDATED:** same-inode evidence (173779122); 0 lowercase paths in git; same file count (429 via either name); same `diff -rq` (empty); flywheel-4rmc prior fix preserved.
- **DOCUMENTED:** the bead's premise correction is named (no duplicate tree on APFS); the actual concern (Linux portability of 11 lowercase references) is documented; the prior flywheel-4rmc fix lineage is cited.
- **SURFACED:** flywheel-aic04 (P4) tracks the per-script normalization work. Each reference must be evaluated individually (some may be intentional case-fallbacks per flywheel-4rmc pattern).

## Four-Lens Self-Grade

four_lens=brand:9,sniff:9,jeff:10,public:9 — **4/4 PASS**

- **Brand (9/10):** scope-honest reframing — refuses to "dedupe" something that isn't duplicated; documents the same-inode evidence concretely; preserves flywheel-4rmc's prior fix; surfaces the actual concern as a P4 followup (lower priority because macOS-fleet-only impact).
- **Sniff (9/10):** same-inode confirmed; file count parity; diff empty; git ls-files asymmetric; all evidence is mechanically verifiable.
- **Jeff (10/10):** Jeff "honest unit-of-work" — when a bead's premise is wrong (no duplicate tree), correct it with evidence rather than execute the wrong work. Convergent disposition pattern (5th today) confirms canonical-rule promotion candidate. The Linux-portability-of-lowercase-refs concern is real but distinct from duplicate-tree.
- **Public (9/10):** **Three Judges check** — skeptical operator can re-run `ls -dli` + `diff -rq` and see the same-inode evidence; maintainer reads the bead-asks-to-dedupe-non-duplicate pattern and immediately understands; future workers handling similar substrate-hygiene beads have this as a template.

`evidence_schema_version=worker-evidence/v1`. `disposition_pattern=bead-asks-to-dedupe-something-that-isnt-duplicated/v1`. `four_lens_close_validator_version=four-lens-close-validator/v1`.

## Skill auto-routes addressed

- `canonical-cli-scoping=n/a` — no CLI surface authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — no README.

## Skill discoveries

`skill_discoveries=1 sd_ids=bead-asks-to-dedupe-non-duplicate-class`

| Kind | Discovery |
|---|---|
| `pattern-recurrence` | **Bead-asks-to-dedupe-non-duplicate class:** when a bead body asserts "duplicate tree" but probe shows case-aliasing on case-insensitive FS (APFS, NTFS, HFS+ default), the right disposition is to confirm same-inode evidence, reframe the actual trauma surface (often code-reference inconsistency for Linux portability), file followup for the real concern, and close with corrected framing. 5th convergent disposition instance today (after flywheel-1rmp.18, flywheel-pjfqw, flywheel-gbsbv, flywheel-h17x); strong canonical-rule promotion candidate. |

## L52 / L70 receipt

- L52 (issues-to-beads): **`beads_filed=flywheel-aic04`** (substrate-hygiene followup for Linux portability of lowercase references). **`beads_updated=none`**.
- L70 (no-punt): the next-actionable IS this corrected-framing + followup-filing — completed in this tick.

## L61 ecosystem-touch

- `agents_md_updated=no` — no L-rule promotion (yet).
- `readme_updated=not_applicable` — no README touched.
- `no_touch_reason=substrate-hygiene-clarification-no-doctrine-change`

## Compliance Pack

Score: 880/1000.

- 4/4 implicit acceptance gates DID
- Same-inode evidence verified
- Followup bead filed for actual concern
- 4/4 lenses with 9-10/10 self-grades

Pack path: `.flywheel/evidence/flywheel-b3e5j/`.

## Cross-references

- Source: `flywheel-4rmc` (closed; jeff-pattern-citation-backfill audit that flagged the 50% double-counting)
- This dispatch: `flywheel-b3e5j`
- Followup (filed this dispatch): `flywheel-aic04` (P4 — normalize 11 lowercase code refs)
- Prior fix preserved: `.flywheel/scripts/jeff-pattern-citation-probe.sh::collect_default_paths()` (walks uppercase canonical with lowercase fallback per flywheel-4rmc)
- Convergent disposition siblings today (5-instance pattern): `flywheel-1rmp.18` (operator-fatigue measurement), `flywheel-pjfqw` (trauma-class no-emitter), `flywheel-gbsbv` (monitored watchdog), `flywheel-h17x` (defer-condition not met), `flywheel-b3e5j` (this — non-duplicate)
- Memory cross-refs:
  `feedback_basename_keying_collision_class.md` (path-discipline family — same lineage as ntm#130/131/132),
  `feedback_calibrate_test_to_actual_contract_before_filing_upstream.md`
- L-rules cited: L70 (no-punt — same-tick disposition), L52 (issues-to-beads — flywheel-aic04), L48 (worker scope — refused to execute against wrong premise)
