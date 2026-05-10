# flywheel-tpprm — Worker Report

**Task:** [clobber-recovery] canonical primitive shipped 2026-05-09
**Identity:** MagentaPond (codex-pane on flywheel:0.3)
**Repo head pre:** post-62vdo; post: this commit
**Status:** done — all 4 ACs satisfied; INCIDENTS + dispatch-template updated
**Mission fitness:** infrastructure — canonical recovery primitive doctrine + orch policy.

## Verdict

**All 4 acceptance gates pass.** The canonical recovery primitive (`clobber-recovery.sh` + smoke test) was already shipped 2026-05-09. This dispatch closes the loop on AG3 (orch dispatch policy) + AG4 (doctrine + dispatch-template pointer):

| AG | Status | Evidence |
|---|---|---|
| AG1: `bash tests/clobber-recovery-smoke.sh` exits 0 with 5/5 PASS | DID — verified | "SUMMARY pass=5 fail=0" |
| AG2: `--dry-run` on canonical set reports NOOP+NOT_CLOBBER (no false-restore on legit drift) | DID — verified | `{restored:[], refused:[], noop_count:3, not_clobber_count:2}` |
| AG3: orch dispatch policy (when callback contains `clobbered_doctrine_docs` OR `damage=mission.md_*->1`, invoke recovery non-interactively) | DID | INCIDENTS section "Canonical orch dispatch policy" landed |
| AG4: doctrine + dispatch-template pointer | DID | INCIDENTS entry `## clobbered_doctrine_docs` (canonical primitive shipped 2026-05-09); dispatch-template.md TMP LIFECYCLE BLOCK now cites the safe `cd-or-exit` pattern + the recovery script |

did=4/4, didnt=none, gaps=none.

## What this dispatch shipped (vs what was already shipped)

**Pre-dispatch (already shipped 2026-05-09):**
- `.flywheel/scripts/clobber-recovery.sh` — recovery script with `--dry-run`, heuristic gate, exit codes 0/3/4
- `tests/clobber-recovery-smoke.sh` — 5-assertion smoke test
- `.flywheel/clobber-recovery-log.jsonl` — receipt ledger

**This dispatch (AG3 + AG4):**
- `INCIDENTS.md` — added `## clobbered_doctrine_docs` section (~80 lines):
  - Trauma class definition + flywheel-m49r2 event evidence
  - Recovery script + smoke test references
  - Canonical orch dispatch policy (non-interactive recovery on callback markers)
  - Worker-side prevention (safe `cd-or-exit` pattern with explicit error handling)
  - DO/DON'T code examples
  - Donella leverage point mapping
- `~/.claude/commands/flywheel/_shared/dispatch-template.md` — TMP LIFECYCLE BLOCK:
  - Replaced naked `mktemp` with `mktemp -d || exit 1` + `cd || exit 1` two-line idiom
  - Added clobber-recovery callout: orch invokes `.flywheel/scripts/clobber-recovery.sh` non-interactively when worker callback contains the trauma markers

## Why the worker-side prevention pattern matters

The original clobber pattern from flywheel-m49r2:

```bash
# UNSAFE — silently keeps OLD pwd if cd fails
cd "$WORK_TMP" && printf '%s' "$content" > target.md
```

When `WORK_TMP` is unset (e.g., `mktemp` failed silently because TMPDIR fills, or special-char-escape fails), `cd ""` keeps the current pwd. The redirect then writes to `target.md` in the repo root, clobbering whatever doctrine doc shares that name (MISSION.md, STATE.md, etc.).

The safe pattern enforces explicit error handling at both gates:

```bash
WORK_TMP="$(mktemp -d -t my-task.XXXXXX)" || { echo "ERR: mktemp failed" >&2; exit 1; }
cd "$WORK_TMP" || { echo "ERR: cd failed: $WORK_TMP" >&2; exit 1; }
printf '%s' "$content" > target.md
```

This prevents the class structurally — no clobber is possible because:
1. mktemp failure → exit immediately; never reach the redirect
2. cd failure → exit immediately; never reach the redirect
3. Only after both gates pass does the redirect execute

Dispatch-template now stamps this pattern as the canonical worker entry-point.

## Live verification

```bash
# AG1
bash tests/clobber-recovery-smoke.sh | tail -3
# → SUMMARY pass=5 fail=0

# AG2 (no false-restore on canonical set)
.flywheel/scripts/clobber-recovery.sh --dry-run | tail -1 \
  | jq -c '{restored, refused, noop_count: (.noop|length), not_clobber_count: (.not_clobber|length)}'
# → {"restored":[],"refused":[],"noop_count":3,"not_clobber_count":2}
# (3 doctrine docs match HEAD; 2 have legit drift that doesn't trigger restore)

# AG3 + AG4 (doctrine landed)
grep -c "## clobbered_doctrine_docs" INCIDENTS.md
# → 1
grep -c "Canonical orch dispatch policy" INCIDENTS.md
# → 1
grep -c "clobber-recovery.sh" /Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md
# → 1
grep -c "clobbered_doctrine_docs" /Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md
# → 2 (cite + DO-NOT-do reference)
```

L112 probe: `grep -c "## clobbered_doctrine_docs" /Users/josh/Developer/flywheel/INCIDENTS.md` expects literal `1`.

## Pattern: canonical-recovery-primitive-with-orch-policy

When a high-severity destructive class lands (here: doctrine doc clobber), the canonical fix shape is:

1. **Recovery script** with `--dry-run`, heuristic gate (only restore on truncation signature), refuse-tiny-HEAD safety, JSON receipts (`.flywheel/<class>-recovery-log.jsonl`), and stable exit codes
2. **Smoke test** with all 4 corner cases (NOOP, restore, drift, refused) plus receipt-emission check
3. **INCIDENTS doctrine** documenting the class, root cause, recovery contract, AND orch dispatch policy (non-interactive invocation criteria)
4. **Dispatch-template update** stamping the worker-side prevention pattern + recovery callout
5. **Memory rule** (already in `feedback_dcg_prose_trigger_strip_dangerous_substrings.md` for the DCG context)

The 5-piece shape is reusable for future destructive classes (e.g., accidental `rm` of git-tracked files, force-push overwrites, etc.).

## Files changed

- `~ /Users/josh/Developer/flywheel/INCIDENTS.md` — added `## clobbered_doctrine_docs` section (+78 lines: class def + recovery contract + orch policy + worker prevention + DO/DON'T examples + Donella mapping + evidence cross-refs)
- `~ /Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md` — TMP LIFECYCLE BLOCK extended with safe `mktemp -d || exit + cd || exit` two-line idiom + clobber-recovery callout (+11 lines)
- `+ /Users/josh/Developer/flywheel/.flywheel/evidence/flywheel-tpprm/report.md` — this file

(Recovery script + smoke test were ALREADY shipped 2026-05-09; this dispatch landed only the doctrine + dispatch-template updates that AG3/AG4 require.)

## Three-Q

- **VALIDATED:** all 4 ACs pass mechanically (smoke 5/5, dry-run NOOP+NOT_CLOBBER, INCIDENTS section present, dispatch-template pointer present); pre/post grep counts captured.
- **DOCUMENTED:** worker-side prevention pattern explicit with DO/DON'T code; orch dispatch policy named (when callback markers present, non-interactive recovery + re-dispatch); 5-piece canonical-recovery-primitive shape captured.
- **SURFACED:** L56 ladder will auto-fire a new bead if the class accumulates 3+ events. Until then, the canonical primitive + dispatch-template prevention should keep the class at 0 recurrences. If that holds for 7+ days, the class can be promoted to a canonical L-rule.

## Four-Lens Self-Grade

four_lens=brand:9,sniff:9,jeff:10,public:9 — **4/4 PASS**

- **Brand (9/10):** narrowest fix — only INCIDENTS + dispatch-template touched; recovery script + smoke test were pre-existing; no script edits this dispatch.
- **Sniff (9/10):** AG1-4 mechanically verified; AG2 dry-run output shows correct NOOP+NOT_CLOBBER mix; pre/post grep counts cited.
- **Jeff (10/10):** Jeff functional-shell discipline — `git show HEAD:<path> > <path>` instead of `git checkout` (DCG-blocked); per-file NOOP idempotency; refuse-tiny-HEAD safety; bounded execution; clear exit codes. The 5-piece canonical-recovery-primitive shape is the canonical Jeff "primitive + doctrine + worker-side-prevention" pattern.
- **Public (9/10):** **Three Judges check** — skeptical operator can re-run the smoke + dry-run + grep INCIDENTS + grep dispatch-template; maintainer reads the worker-side prevention pattern and immediately stops writing the unsafe form; future workers handling similar destructive classes have the 5-piece template.

`evidence_schema_version=worker-evidence/v1`. `extraction_pattern=canonical-recovery-primitive-with-orch-policy/v1`. `four_lens_close_validator_version=four-lens-close-validator/v1`.

## Skill auto-routes addressed

- `canonical-cli-scoping=n/a` — recovery script's CLI surface was authored pre-dispatch; this dispatch only updated doctrine.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — no README.

## Skill discoveries

`skill_discoveries=1 sd_ids=canonical-recovery-primitive-with-orch-policy-class`

| Kind | Discovery |
|---|---|
| `pattern-emerged` | **Canonical-recovery-primitive-with-orch-policy class:** for high-severity destructive classes (doctrine clobber, file truncation, etc.), the canonical fix is a 5-piece bundle: (1) recovery script with --dry-run + heuristic + refuse-tiny + JSON receipts + stable exit codes, (2) smoke test covering NOOP/restore/drift/refused, (3) INCIDENTS section with class definition + recovery contract + orch dispatch policy, (4) dispatch-template stamps worker-side prevention pattern + recovery callout, (5) memory cross-ref for DCG/safety context. Reusable for future destructive classes. |

## L52 / L70 receipt

- L52 (issues-to-beads): **`no_bead_reason=phase-tpprm-canonical-recovery-primitive-shipped-and-doctrine-landed-no-new-bead-needed-l56-ladder-auto-fires-on-recurrence`**.
- L70 (no-punt): the next-actionable IS this AG3+AG4 doctrine landing — completed in this tick.

## L61 ecosystem-touch

- `agents_md_updated=no` — the doctrine landed in INCIDENTS (the L56 ladder's canonical surface for 1-event classes); 3-event recurrence would promote to a numbered L-rule.
- `readme_updated=not_applicable` — no README touched.

## Compliance Pack

Score: 920/1000.

- 4/4 acceptance gates DID (verified mechanically)
- INCIDENTS + dispatch-template updates landed
- L107 reservations acquired (INCIDENTS + dispatch-template) + released after commit (per flywheel-y4e47 lifecycle)
- 4/4 lenses with 9-10/10 self-grades

Pack path: `.flywheel/evidence/flywheel-tpprm/`.

## Cross-references

- Trauma event: `flywheel-m49r2` (2026-05-09; clobbered MISSION/STATE/GOAL; restored from HEAD 9c1f61f)
- This dispatch: `flywheel-tpprm`
- Recovery script (pre-existing): `.flywheel/scripts/clobber-recovery.sh`
- Smoke test (pre-existing): `tests/clobber-recovery-smoke.sh` (5 assertions)
- Receipt ledger (pre-existing): `.flywheel/clobber-recovery-log.jsonl`
- INCIDENTS section (this dispatch): `INCIDENTS.md` `## clobbered_doctrine_docs`
- Dispatch-template (this dispatch): `~/.claude/commands/flywheel/_shared/dispatch-template.md` TMP LIFECYCLE BLOCK
- L107 lifecycle (applied): reserve → write → git add → git commit → release (per `flywheel-y4e47`)
- Memory cross-refs:
  `feedback_dcg_prose_trigger_strip_dangerous_substrings.md` (DCG context for `git checkout` replacement)
- L-rules cited: L107 (reservation, applied), L70 (no-punt — same-tick disposition), L52 (no new bead — L56 ladder handles recurrence), L56 (promotion ladder — auto-fires if class hits 3+ events)
