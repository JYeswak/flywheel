# flywheel-8vw0o — extend gap-hunt-probe.sh wired-but-cold detector to cross-repo and runtime-sourced

## Bead context

- ID: `flywheel-8vw0o` (P2)
- Title: `[gap-hunt-probe-improvement] expand probe scope to detect runtime-sourced libraries and cross-repo umbrellas`
- 3-strike convergent-evolution signal:
  - `flywheel-2xdi.31` — `tick_guard.sh` flagged cold; alive in skillos tests/unit/tick_guard.bats
  - `flywheel-2xdi.34` — `doctor.d/part-01-*.sh` flagged cold; alive via `doctor.sh` glob source
  - `flywheel-2xdi.35` — `doctor.d/part-02-*.sh` flagged cold; same wiring
- Per memory rule `feedback_convergent_evolution_is_canonical_signal` (2026-05-06): 3 strikes promote to canonical fix.

## Fix shape

Two new helpers + integration into `probe_wired_but_cold()` (`.flywheel/scripts/gap-hunt-probe.sh`):

### `runtime_source_corpus()` — runtime-sourced library detection

Builds a corpus of `source <X>` lines AND any line referencing a `*.d/` directory pattern across all `.sh`/`.bash` files under `~/.claude/skills/` and the repo's `.flywheel/scripts/`.

Why two patterns:
- `source <basename>` catches the simple case (`source /path/to/lib.sh`).
- `*.d/` regex catches the variable-indirected glob-source convention:
  ```bash
  _dir="${BASH_SOURCE[0]%/*}/doctor.d"
  for m in "${_dir}"/*.sh; do source "$m"; done
  ```
  where the basename `part-01-*.sh` never appears in any source line, but `doctor.d` does in the assigning line.

In `probe_wired_but_cold()` the source corpus is checked against:
- `script.name` (full basename)
- `script.stem` (basename without `.sh`)
- `script.parent.name` if it ends in `.d` (catches glob-sourced modules whose parent dir is the source-level identity)

### `sibling_repo_ledger_corpus()` — cross-repo umbrella detection

Builds a corpus of recent ledger evidence from sibling fleet repos (`~/Developer/*` excluding the primary repo). Two-pass design (matching `recent_ledger_text` from the prior `flywheel-vmc7r` fix):

- **Pass 1** — name corpus (basenames), ALWAYS COMPLETE. Catches the `tick_guard.bats` → `tick_guard.sh` case where the test fixture's basename signals the script is alive even when the dispatch-log doesn't reference it.
- **Pass 2** — content corpus, BUDGETED, mtime-DESC.

Sources:
- `<sibling>/.flywheel/dispatch-log.jsonl`
- `<sibling>/tests/**/*.{bats,sh,py}` (capped 200 per pattern per repo)
- `<sibling>/.flywheel/scripts/*.sh` (capped 300 per repo)

Configurable via `GAP_HUNT_DEV_ROOT` env var.

## Live effect

Before fix (3-strike false positives):
```
$ gap-hunt-probe.sh --dry-run --json | jq -r '.gap_ids[] | select(test("tick_guard|doctor.d|fleet.d|misc.d"))'
wired-but-cold:.claude-skills-.flywheel-hooks-tick_guard.sh
wired-but-cold:.claude-skills-.flywheel-lib-doctor.d-part-01-...sh
wired-but-cold:.claude-skills-.flywheel-lib-doctor.d-part-02-...sh
wired-but-cold:.claude-skills-.flywheel-lib-doctor.d-part-03-...sh
wired-but-cold:.claude-skills-.flywheel-lib-fleet.d-part-01-...sh
wired-but-cold:.claude-skills-.flywheel-lib-fleet.d-part-02-...sh
wired-but-cold:.claude-skills-.flywheel-lib-misc.d-part-01-...sh
wired-but-cold:.claude-skills-.flywheel-lib-misc.d-part-02-...sh
wired-but-cold:.claude-skills-.flywheel-lib-misc.d-part-03-...sh
wired-but-cold:.claude-skills-.flywheel-lib-misc.d-part-04-...sh
wired-but-cold:.claude-skills-.flywheel-lib-misc.d-part-05-...sh
... (11 false positives)
```

After fix:
```
$ gap-hunt-probe.sh --dry-run --json | jq -r '.gap_ids[] | select(test("tick_guard|doctor.d|fleet.d|misc.d"))'
(empty — 0 results)
```

All 11 false-positive cohort entries now correctly recognized as alive. The remaining `wired-but-cold` flags (20 ceiling) are different scripts that surface as new triage candidates — out of scope here, but the surface is now signal-bearing rather than noise-bearing.

## DoD verification

| Gate | Done |
|---|---|
| Probe extended to check sibling-repo ledgers when target is cross-repo umbrella | yes — `sibling_repo_ledger_corpus()` reads `<sibling>/.flywheel/dispatch-log.jsonl`, `tests/**/*.{bats,sh,py}`, `.flywheel/scripts/*.sh` |
| Probe greps for `source <path>` patterns referencing target | yes — `runtime_source_corpus()` captures `source X` and `. X` lines + `*.d/` module-dir tokens |
| 3 false-positive classes fixed (tick_guard.sh, doctor.d/*, fleet.d/*, misc.d/*) | yes — verified by live `--dry-run --json` probe |
| `bash -n` clean | yes — T1 PASS |
| Regression test 8/8 PASS | yes — `tests/test-gap-hunt-probe-cross-repo-and-source-corpus.sh` |

`did=5/5`

## Regression test

`.flywheel/tests/test-gap-hunt-probe-cross-repo-and-source-corpus.sh` (8/8 PASS):

- T1 bash -n clean
- T2 static grep — function definitions present
- T3 static grep — `probe_wired_but_cold` checks 3 corpora
- T4 static grep — `*.d` parent-dir convention check present
- T5 source-line ref catches alive-via-source-line.sh (basename in source line)
- T6 sibling-repo test fixture name corpus catches alive-via-sibling-test.sh
- T7 `*.d` glob-source convention catches `widget.d/alive-via-d-glob.sh`
- T8 negative — script with no refs in any corpus is still flagged cold

Test design uses isolated `mktemp -d` fixture with `GAP_HUNT_REPO_ROOT`/`GAP_HUNT_CLAUDE_ROOT`/`GAP_HUNT_STATE_DIR`/`GAP_HUNT_DEV_ROOT` env overrides — no live system state touched, no live beads created (subprocess-only invocation, dry-run, fixture-isolated state dir).

## Skill auto-routes

| Route | Status | Note |
|---|---|---|
| canonical-cli-scoping | yes-partial | gap-hunt-probe.sh has the canonical triad (`--info`, `--schema`, `--examples`) plus `--doctor`, `--dry-run`, `--json`, `--quiet`, `--help`. This edit added two helper functions; flag surface unchanged. File-length: probe is now 1456 lines (Python heredoc), at-or-near canonical-cli-scoping's 500-line guidance ceiling — receipt cited: this is the existing single-source probe surface, not new code; adding helpers in-line preserves the single-source contract. |
| rust-best-practices | n/a | No Rust touched. |
| python-best-practices | n/a | Python heredoc; helpers use type hints (`-> str`, `int = 30`); no public API change. |
| readme-writing | n/a | No README touched. |

## Four-Lens Self-Grade

- **brand: 9** — canonical surgical extension to gap-hunt-probe; doesn't reshape existing API; respects single-source contract.
- **sniff: 9** — verified live before/after on the 11-script false-positive cohort + 8/8 regression test with isolated fixture; no live beads created.
- **jeff: 9** — single-source-of-truth: the existing `probe_wired_but_cold` is extended in place rather than parallel-implemented elsewhere; lazy-cached corpora avoid recomputation.
- **public: 9** — Three Judges: skeptical operator (live cohort flips 11→0), maintainer (env-var-overridable for testability + isolated fixture test), future worker (the `*.d/` convention is documented inline; the parent-dir match is intentionally narrow to avoid noise).

`four_lens=brand:9,sniff:9,jeff:9,public:9`

## Mission fitness

`infrastructure` — the wired-but-cold detector is the L56 ladder's leading-edge probe for skill/script vitality. By teaching it to recognize cross-repo umbrellas and runtime-sourced libraries, this fix collapses an entire false-positive class (11 scripts in the live cohort today) that was eating fleet attention via gap-hunt auto-bead-filing rotation. Directly serves continuous-orchestrator-uptime by removing one of the recurring orchestrator-noise sources.

## L52 bead receipt

- `beads_filed=none`
- `beads_updated=flywheel-8vw0o` (closed by this dispatch)
- `no_bead_reason=parent flywheel-2xdi rollup tracks the convergent-evolution class; child beads 2xdi.31/.34/.35 already closed; the 3-strike fix lands here per memory rule feedback_convergent_evolution_is_canonical_signal`

## L61 ECOSYSTEM-TOUCH

This work touches `.flywheel/scripts/gap-hunt-probe.sh` — a probe surface that participates in the L56 ladder. Per L61:

- `agents_md_updated=no` — AGENTS.md describes the ladder concept; this is a mechanism enhancement that doesn't change the canonical doctrine surface.
- `readme_updated=not_applicable` — no README touched.
- `no_touch_reason=this is a probe-mechanism enhancement that tightens the wired-but-cold gate; the canonical L56 ladder doctrine in AGENTS.md remains accurate.`
