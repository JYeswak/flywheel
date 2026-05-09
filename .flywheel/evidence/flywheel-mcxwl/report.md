# flywheel-mcxwl — Worker Report

**Task:** [file-length-split] flywheel-hzsro.2 — split phase 2 per `.flywheel/audit/flywheel-hzsro/split-plan.md`
**Identity:** MagentaPond (codex-pane on flywheel:1)
**Repo head:** 02830cf (master)
**Status:** done — Phase 2 file 1/3 split executed; parity fixture passes
**Mission fitness:** infrastructure — executes the split-plan File 1 per the parity contract authored in `flywheel-n5wa5`. Removes the `canonical-cli-scoping-allow-large` exemption from `loop_driver_doctor_json.py` by extracting helpers into a sibling lib module with function-argument threading.

## Verdict

**File 1 split executed:** 582 lines → 288 (entry) + 297 (lib) = 585 total. Both files now under the canonical 400-line Python threshold; allow-large exemption removed.

| Metric | Pre | Post |
|---|---:|---:|
| `loop_driver_doctor_json.py` lines | 582 | 288 |
| `loop_driver_doctor_lib.py` lines | (didn't exist) | 297 |
| Combined size | 582 | 585 (+3 lines for new module header) |
| `canonical-cli-scoping-allow-large` exemption | YES (line 1) | REMOVED |
| Phase 1 parity fixture | PASS | PASS (unchanged shape contract) |
| Functions thread module-scope vars | 3 untreaded | 3 threaded (`latest_topology(session, topology_path)`, `find_loop_marker(loops_dir, project, repo)`, `inactive_marker_post_stop_ticks(loops_dir)`) |

## Acceptance gate coverage

The bead body is empty. Implicit gates from the title (`split phase 2 per split-plan.md`) and the phase-1 fixture (`flywheel-n5wa5`):

| Implicit gate | Status | Evidence |
|---|---|---|
| Execute the split per split-plan File 1 motion | DID | helpers extracted to `loop_driver_doctor_lib.py` with function-argument threading (preferred per split-plan caveat about module-scope side effects); entry script now imports + calls with threaded args |
| Verify parity with the n5wa5 fixture | DID | `tests/loop_driver_doctor_json_parity_fixture.sh` returns "loop_driver_doctor_json shape-parity fixture passed" — 20 top-level keys + drain_receipts substructure + array types all preserved |
| File sizes drop under canonical threshold | DID | entry 288 (was 582; under 400 threshold); lib 297 (under 400 threshold); both files no longer need allow-large receipt |
| Files 2 and 3 remain routed to follow-up beads | DID | flywheel-tymof (identity.py) and flywheel-xmd4y (part-02-portable_doctor.sh) still pending Phase 1 fixtures; this dispatch only executes File 1's Phase 2 |

did=4/4, didnt=files-2-and-3-still-await-their-phase-1-fixture-then-phase-2-split, gaps=none.

## Function-argument threading (per split-plan canonical preference)

The split-plan flagged 3 helpers that used module-scope state:

| Helper | Pre-split signature | Post-split (threaded) signature |
|---|---|---|
| `latest_topology` | `(session)` — read module `topology_path` | `(session, topology_path)` |
| `find_loop_marker` | `()` — read module `loops_dir`, `project`, `repo` | `(loops_dir, project, repo)` |
| `inactive_marker_post_stop_ticks` | `()` — read module `loops_dir` | `(loops_dir)` |

The other 10 helpers (`load_json`, `load_toml`, `nested`, `parse_interval_seconds`, `parse_ts`, `plist_info`, `launchctl_loaded`, `ntm_pane_live`, `pane_prompt_observed`, `latest_dispatch_ts`, `latest_drain_receipt`) were already pure of module-scope dependencies and moved unchanged.

Entry-script call sites updated:
- `marker_path, marker = find_loop_marker()` → `find_loop_marker(loops_dir, project, repo)`
- `topology = latest_topology(str(session))` → `latest_topology(str(session), topology_path)`
- `inactive_marker_post_stop_tick = inactive_marker_post_stop_ticks()` → `inactive_marker_post_stop_ticks(loops_dir)`

This is the canonical pattern split-plan named (function-argument threading > module-scope re-export) because the entry script's module-scope `repo`, `topology_path`, etc. come from `sys.argv` and env vars — those values are best treated as pipe-input that flows through function calls, not as ambient state.

## Live verification

```bash
# Pre-split: file was over threshold
# wc -l: 582 lines (vs 400 Python threshold = 1.5x over)
# Header line 1: "# canonical-cli-scoping-allow-large: ..."

# Post-split: split executed
wc -l /Users/josh/.claude/skills/.flywheel/lib/loop.d/loop_driver_doctor_json.py \
      /Users/josh/.claude/skills/.flywheel/lib/loop.d/loop_driver_doctor_lib.py
# → 288 + 297 = 585 lines total (each under 400 threshold)

# Allow-large exemption removed
grep -c canonical-cli-scoping-allow-large /Users/josh/.claude/skills/.flywheel/lib/loop.d/loop_driver_doctor_json.py
# → 0

# Parity fixture (Phase 1 oracle from flywheel-n5wa5) passes post-split
bash /Users/josh/Developer/flywheel/tests/loop_driver_doctor_json_parity_fixture.sh
# → "PASS shape-parity (20 top-level keys + drain_receipts substructure + array types)"
# → "PASS rc=0 under fixture env"
# → "loop_driver_doctor_json shape-parity fixture passed"
```

L112 probe: `bash /Users/josh/Developer/flywheel/tests/loop_driver_doctor_json_parity_fixture.sh 2>&1 | tail -1` expects literal `loop_driver_doctor_json shape-parity fixture passed`.

## Files changed

- `~ ~/.claude/skills/.flywheel/lib/loop.d/loop_driver_doctor_json.py` — header rewritten; helpers (lines 28-330 in pre-split) replaced with `from loop_driver_doctor_lib import ...`; 3 call sites threaded with module-scope args; allow-large exemption removed (582 → 288 lines)
- `+ ~/.claude/skills/.flywheel/lib/loop.d/loop_driver_doctor_lib.py` — new helper module (297 lines); 13 helpers moved here; 3 with threaded module-scope args
- `+ /Users/josh/Developer/flywheel/.flywheel/evidence/flywheel-mcxwl/report.md` — this file

No changes to call sites OUTSIDE the entry script (the helpers' post-split function bodies are byte-equivalent to pre-split for the 10 pure helpers; signatures changed for 3 threaded helpers; main code's invocation patterns updated to match).

## Three-Q

- **VALIDATED:** Phase 1 fixture passes post-split with identical shape contract; both files under 400-line Python threshold.
- **DOCUMENTED:** function-argument threading rationale cited from split-plan; 13 helpers tabulated by purity vs threaded; call-site changes enumerated.
- **SURFACED:** Files 2 and 3 (identity.py, part-02-portable_doctor.sh) still need Phase 1 fixtures (`flywheel-tymof`, `flywheel-xmd4y`) before their Phase 2 splits can run safely.

## Four-Lens Self-Grade

four_lens=brand:9,sniff:9,jeff:9,public:9 — **4/4 PASS**

- **Brand (9/10):** scope-respecting — File 1 split only, with parity fixture as oracle; Files 2/3 follow-up routing preserved; allow-large exemption removed honestly (not deferred).
- **Sniff (9/10):** parity verified by the existing fixture; pre/post line counts captured; call-site changes enumerated; no new test infrastructure invented.
- **Jeff (9/10):** function-argument threading is the canonical Jeff pattern (preferred over module-scope ambient state); cited operational primitives (`sed`, `wc -l`, `grep`, `bash`); split-plan author's caveat honored.
- **Public (9/10):** **Three Judges check** — skeptical operator can re-run the fixture and confirm parity; maintainer reads the threading-rationale section and understands why the 3 helpers got new args; future worker doing Files 2 or 3 has this dispatch as a template.

`evidence_schema_version=worker-evidence/v1`. `parity_contract=shape-parity-fixture/v1`. `four_lens_close_validator_version=four-lens-close-validator/v1`.

## Skill auto-routes addressed

- `canonical-cli-scoping=n/a` — no new CLI surface; the split removes an allow-large exemption (a canonical-cli-scoping gate) by getting the file under threshold.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=yes` — Python files. Both post-split files use type hints (preserved from pre-split), function signatures are explicit, no module-level side effects in lib (helpers are pure or take their dependencies as args), entry script's module-scope path constants are explicit and minimal. Both files under 400-line threshold.
- `readme-writing=n/a` — no README.

## Skill discoveries

`skill_discoveries=0 sd_ids=none` — task fits the canonical "fixtures first, splits second" pattern documented in the split-plan. No new convergent_evolution / meta_rule / trauma_class signal surfaced.

## L52 / L70 receipt

- L52 (issues-to-beads): **`no_bead_reason=phase-2-file-1-of-3-completed-files-2-and-3-already-routed-to-follow-up-beads-flywheel-tymof-and-flywheel-xmd4y-by-flywheel-n5wa5-no-new-bead-needed`**.
- L70 (no-punt): the next-actionable IS this split + parity verification — running it in the same tick satisfies L70.

## L61 ecosystem-touch

- `agents_md_updated=no` — no L-rule promotion.
- `readme_updated=not_applicable` — no README touched.
- `no_touch_reason=phase-2-split-execution-no-doctrine-change`

## Compliance Pack

Score: 920/1000.

- Phase 2 file 1/3 split executed
- Parity fixture passes post-split (shape contract preserved)
- Both files under canonical 400-line Python threshold
- Allow-large exemption removed
- 3 helpers threaded with module-scope args (function-argument threading is canonical)
- 4/4 lenses with 9/10 self-grades
- L107 reservations acquired/released

Pack path: `.flywheel/evidence/flywheel-mcxwl/`.

## Cross-references

- Parent: `flywheel-hzsro` (closed; produced split-plan)
- Phase 1 file 1/3 fixture (precedent): `flywheel-n5wa5` (closed; authored `tests/loop_driver_doctor_json_parity_fixture.sh`)
- Phase 1 follow-ups (Files 2 and 3): `flywheel-tymof`, `flywheel-xmd4y`
- Split-plan: `.flywheel/audit/flywheel-hzsro/split-plan.md` File 1
- Subject entry: `~/.claude/skills/.flywheel/lib/loop.d/loop_driver_doctor_json.py` (288 lines, was 582)
- Subject lib (new): `~/.claude/skills/.flywheel/lib/loop.d/loop_driver_doctor_lib.py` (297 lines)
- Parity oracle: `tests/loop_driver_doctor_json_parity_fixture.sh`
- L-rules cited: L107 (shared-surface reservation, applied), L70 (no-punt), L52 (issues-to-beads receipt — files 2/3 already routed by sibling)
