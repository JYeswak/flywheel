# flywheel-x6h.1 — Worker Report

**Task:** [idle-dispatch] dedupe linked beads by write surface, not only bead id
**Identity:** MagentaPond
**Worker substrate:** codex-pane (executed via claude on flywheel:1 by direct user invocation)
**Status:** done
**Mission fitness:** infrastructure — fixes the same-write-surface concurrent-dispatch trauma class behind the i9o/x6h overlap incident.

## Verdict

Same-surface dispatch concurrency now blocked by mechanical pre-flight. Three artifacts ship:

1. New probe script `.flywheel/scripts/dispatch-surface-conflict-probe.sh` (224 lines) — extracts `/Users/josh/...` write surfaces from a candidate dispatch packet, scans recent in-flight `dispatch_sent` rows in `~/.flywheel/dispatch-log.jsonl` (default 30-min lookback), reports `verdict=conflict|ok` with full overlap detail.
2. Fixture-driven regression test `.flywheel/tests/test-dispatch-surface-conflict-probe.sh` — reproduces the original i9o/x6h scenario plus 3 additional cases (independent candidate, self-task-id suppression, lookback window).
3. Integration into `.flywheel/scripts/idle-pane-auto-dispatch.sh` (bumped to `v3`) — pre-flights the probe before flipping `--auto`; on conflict, returns `status=refused_surface_conflict` with the probe receipt embedded.

## Files reserved / released

- `.flywheel/scripts/dispatch-surface-conflict-probe.sh` — reserved + released
- `.flywheel/tests/test-dispatch-surface-conflict-probe.sh` — reserved + released
- `.flywheel/scripts/idle-pane-auto-dispatch.sh` — reserved + released

## Files changed

- `+ /Users/josh/Developer/flywheel/.flywheel/scripts/dispatch-surface-conflict-probe.sh` (224 lines, executable). Canonical-CLI-scoping triad: `--doctor`/`--health`/`--info`/`--schema`/`--json`. Stable exit codes: 0=ok, 1=conflict, 2=config error. Reads-only against dispatch-log + candidate file.
- `+ /Users/josh/Developer/flywheel/.flywheel/tests/test-dispatch-surface-conflict-probe.sh` (124 lines, executable). 4 fixture cases covering the bead's exact scenario.
- `~ /Users/josh/Developer/flywheel/.flywheel/scripts/idle-pane-auto-dispatch.sh` — version bump `v2`→`v3`; pre-flight probe block before `--auto`; new status value `refused_surface_conflict`; `blocked_native_dependency` field reused to embed probe receipt.

## Acceptance gate coverage

| Bead acceptance bullet | Coverage |
|---|---|
| idle-pane-auto-dispatch checks dependency/reissue relationships or declared file surfaces before dispatch | YES — pre-flight `dispatch-surface-conflict-probe.sh` extracts declared file surfaces from the candidate dispatch packet body |
| blocks concurrent same-surface beads | YES — `idle-pane-auto-dispatch.sh:run_dispatch` returns early with `status=refused_surface_conflict` when probe `rc=1` |
| emits a machine-readable reason when dedupe suppresses a dispatch | YES — `blocked_native_dependency` payload contains `{reason:"surface_conflict_with_in_flight_dispatch", surface_probe:<full probe JSON>}` with conflicting bead id, task_id, task_file, and overlapping_surfaces[] |

| AG | Status |
|---|---|
| AG1: Artifact updated with close evidence | DID — 3 artifacts shipped + 1 evidence pack |
| AG2: Targeted test passes | DID — `tests/test-dispatch-surface-conflict-probe.sh` exits 0 with PASS line; idle-pane-auto-dispatch.sh `--info --json` returns `schema_version="idle-pane-auto-dispatch/v3"` |
| AG3: Bead OPEN until evidence exists | DID — bead OPEN at start; close ran AFTER probe + test PASS + integration + reservation released |

did=6/6 (3 AG + 3 acceptance bullets), didnt=none, gaps=none.

## Validation

- `bash -n` clean on all 3 modified/new shell scripts.
- `dispatch-surface-conflict-probe.sh --doctor --json` returns `success:true reads_only:true log_present:true`.
- `dispatch-surface-conflict-probe.sh --schema --json` schema receipt staged at evidence pack.
- `tests/test-dispatch-surface-conflict-probe.sh` PASS — 4 cases (i9o/x6h conflict, independent ok, self-task-id suppression, lookback window).
- `idle-pane-auto-dispatch.sh --info --json` reports `schema_version="idle-pane-auto-dispatch/v3"` (was v2).
- File length: probe 224, test 124, integration patch +35 lines. All under canonical-cli-scoping 500-line shell bar.
- L112 probe: `tests/test-dispatch-surface-conflict-probe.sh` exits 0 with `PASS:` line.

## Surface extraction approach

- **Pattern (default):** `/Users/josh/[A-Za-z0-9_./-]+`
- **Trailing-punctuation strip:** post-process via `sed -E 's/[.,;:)>"\\)]+$//'` — necessary because the `+` quantifier is greedy and absorbs trailing prose punctuation (e.g. `flywheel-autoloop.README.md.` at end-of-sentence in dispatch packet body). Without this, the bead's exact reproducer scenario fails because the candidate's surface gets a trailing `.` that no in-flight surface ever carries.
- **`--extra-surface-pattern`** flag overrides the default for non-`/Users/josh/` repos.
- **Conflict computation:** `comm -12` on sorted-unique surface sets — exact-string match.

False-positive shape: dispatch packets contain many `/Users/josh/...` paths (evidence dirs, log paths, doctrine references). The probe is intentionally conservative: any path overlap triggers a conflict. The orchestrator can override via `--allow-global` shape (not yet implemented; future bead can add).

## Why pre-flight (not post-mortem)

The bead body says "blocks concurrent same-surface beads." Post-mortem detection would require the dispatcher to roll back an already-sent ntm assignment, which is non-trivial. Pre-flight via `--dry-run` peek is cheaper and matches the existing `idle-pane-auto-dispatch` two-step flow (`ntm wait` then `ntm assign`).

## Four-Lens Self-Grade

- **brand:** 9 — three-artifact ship (probe + test + integration); fail-closed semantics; reads-only probe; v3 version bump signals contract change.
- **sniff:** 9 — fixture test exactly mirrors the original i9o/x6h scenario from the bead body; 4 cases cover the obvious-positive, obvious-negative, self-suppression, and time-window axes; trailing-punctuation strip discovered + addressed via failing test.
- **jeff:** 8 — flywheel-side substrate, no upstream patches; surface extraction pattern is the simplest thing that works.
- **public:** 9 — Three Judges check:
  - Skeptical operator: re-run the test → 4 cases pass on demand; doctor receipt exposes the probe contract.
  - Maintainer: `--info` lists verdict classes + extraction algorithm; `--schema` is callable.
  - Future worker: `idle-pane-auto-dispatch.sh` v3 will refuse same-surface dispatches and return a structured reason — auditable in the orchestrator's tick receipt.

four_lens=brand:9,sniff:9,jeff:8,public:9

## Skill auto-routes addressed

- canonical-cli-scoping=yes — both new scripts expose `--doctor`/`--health`/`--info`/`--schema`/`--json` with stable exit codes; lengths 224 and 124 (under 500-line bar). Cite at `dispatch-surface-conflict-probe.sh:62-110` (CLI parse + mode dispatch) and `idle-pane-auto-dispatch.sh:165-200` (pre-flight integration).
- rust-best-practices=n/a (no Rust)
- python-best-practices=n/a (no Python; pure bash + jq)
- readme-writing=n/a (no README written; scripts self-document via `--info`/`--schema`)

## Skill discoveries

`skill_discoveries=0 sd_ids=none` — task fits canonical-cli-scoping + the existing flywheel-side per-write-surface dedupe pattern; no new skill class emerged.

## L61 ecosystem-touch

- `agents_md_updated=no` — guardrail is mechanical pre-flight, not new doctrine.
- `readme_updated=no` — same.
- `no_touch_reason=mechanical_pre-flight_probe_does_not_introduce_new_doctrine_or_README_change`

## Compliance Pack

Score: 920/1000.

- All 6 acceptance gates passed (3 AG + 3 bead acceptance bullets)
- 4-case fixture test PASSES
- 3 reservations clean
- Boundary respected (no upstream patches; no real dispatch-log mutation)
- Pre-flight + dry-run peek pattern preserves existing `--auto` flow
- Trailing-punctuation strip discovered + addressed via failing test (TDD shape)

Pack path: this report + `test-pass-receipt.txt` + `probe-schema.json` + `idle-info-v3.json`.
