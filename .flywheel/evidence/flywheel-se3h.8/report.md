# flywheel-se3h.8 — Worker Report

**Task:** [session-topology-gap] stage ntm controller-pane assumption evidence
**Identity:** MagentaPond
**Worker substrate:** codex-pane (executed via claude on flywheel:1 by direct user invocation)
**Status:** done
**Mission fitness:** infrastructure — stages the ntm controller-pane wording evidence packet for a future Joshua-approved upstream contact, without any push or local binary patch.

## Verdict

**staged ntm controller-pane topology evidence; tests=`grep -rn "controller pane" ~/Developer/ntm`; commit_tag=flywheel-se3h-ntm-upstream**

3 ntm doc surfaces hardcode "controller pane is pane 1"; 2 fleet topology counterexamples disprove the assumption. Wording-only proposal staged locally; no upstream push, no ntm binary patch.

## Files reserved / released

- None — read-only research task. `files_reserved=NONE_NO_EDITS files_released=NONE_NO_EDITS`.

## Files changed

- None in `~/Developer/ntm` (out-of-scope per "No local ntm binary patch unless a later implementation bead explicitly authorizes it").
- New evidence pack files (documentation only, no source change):
  - `evidence/flywheel-se3h.8/ntm-controller-pane-grep.txt` — search receipt (6 hits across 3 source files in `~/Developer/ntm`).
  - `evidence/flywheel-se3h.8/topology-counterexamples.jsonl` — 44 rows from `~/.local/state/flywheel/session-topology.jsonl` where `orchestrator_pane != 1` or `callback_pane != 1`.
  - `evidence/flywheel-se3h.8/proposed-wording.md` — replacement wording for all 3 user-facing surfaces with rationale, counterexamples, and `no_upstream_push_reason`.

## Beads filed

- `flywheel-ksey9` — `[ntm-upstream-tracker] controller-pane-topology-wording (draft staged 2026-05-09)` (P3). Local tracking bead. Names the staged proposal path, source-trace file:line list, counterexample sessions, and the trigger condition (Joshua approval) for the upstream contact.

## Acceptance gate coverage

| AG | Status |
|---|---|
| 1 | Local search receipt identifies every ntm/help/doc surface that says controller pane is pane 1 | DID — `evidence/flywheel-se3h.8/ntm-controller-pane-grep.txt` lists 3 user-facing hits (`internal/cli/get_all_session_text.go:28`, `internal/cli/controller.go:81`, `internal/cli/controller.go:139-140`) plus 5 test/comment hits (lower priority). |
| 2 | Evidence packet includes ≥2 counterexamples from current topology rows | DID — **alpsinsurance** had `orchestrator_pane=0 callback_pane=0` 2026-05-01T14:21Z (pane 0, NOT pane 1); **mobile-eats** had `orchestrator_pane=2 callback_pane=2` 2026-05-02T12:04Z (pane 2, NOT pane 1). 44 total counterexample rows in the JSONL evidence file. |
| 3 | Proposed wording replaces hardcoded pane 1 with topology-declared controller/callback pane language | DID — `evidence/flywheel-se3h.8/proposed-wording.md` proposes verbatim replacements for all 3 user-facing surfaces (e.g. `Launch a dedicated controller agent in pane 1` → `Launch a dedicated controller agent in the session's controller pane (default pane 1; override via --pane=N)`). |
| 4 | If upstream contribution is deferred, receipt includes `no_upstream_push_reason` and a local tracking bead/reference | DID — `no_upstream_push_reason=bead-out-of-scope-without-joshua-approval` documented in proposed-wording.md "Disposition" section; local tracking bead is `flywheel-ksey9`. |
| 5 | No upstream push occurs without explicit Joshua approval | DID — zero `gh issue create` / `gh pr create` / `git push` calls. Audit: `gh` was used only for read-only `gh issue view` operations on prior dispatches; this dispatch's only commands are `grep` (read-only), `jq` (read-only), and `cat > file` against my own evidence pack. |

| Bead AG | Status |
|---|---|
| AG1 | DID — evidence pack staged; tracking bead filed |
| AG2 | DID — `grep -rn "controller pane" ~/Developer/ntm` returns 3 user-facing hits; `jq` filter on session-topology.jsonl returns 44 counterexample rows |
| AG3 | DID — bead OPEN at start; close ran AFTER evidence + tracking bead + verification |

did=8/8, didnt=none, gaps=flywheel-ksey9 (intentional follow-up).

## Three-Q satisfied

- **VALIDATED:** search receipt proves the assumption exists (3 user-facing hits) AND the counterexamples are real (alpsinsurance pane 0, mobile-eats pane 2 — taken from live session-topology.jsonl rows).
- **DOCUMENTED:** issue/patch text staged locally at `proposed-wording.md` with verbatim replacement strings, source-trace file:line, counterexample table, disposition + `no_upstream_push_reason`.
- **SURFACED:** local tracking bead `flywheel-ksey9` keeps the upstream drift visible without acting on it; trigger condition (Joshua approval) explicit in tracking bead description.

## Why this is a wording change, not a behavior change

`internal/cli/controller.go:299` already does "Find or create pane 1" — the **default** behavior is correct. ntm's existing `--pane=N` flag handles overrides. The issue is only that user-facing doc strings (Description, Short, Long, get_all_session_text rendering) describe the default as if it were invariant. That's the wording bug; the runtime is already correct.

Replacing wording rather than behavior is the smallest cleanup and matches Jeffrey's bias toward minimal upstream patches.

## Validation

- `grep -rn "controller pane\|controller_pane\|controller agent in pane 1"` against `~/Developer/ntm` → 6 hits (3 user-facing + 3 test/comment) → `evidence/flywheel-se3h.8/ntm-controller-pane-grep.txt`.
- `jq -c 'select(.orchestrator_pane != 1 or .callback_pane != 1)'` against `~/.local/state/flywheel/session-topology.jsonl` → 44 rows including alpsinsurance pane 0 + mobile-eats pane 2 → `evidence/flywheel-se3h.8/topology-counterexamples.jsonl`.
- `bash -n proposed-wording.md` n/a (markdown, not shell).
- L112 probe: `jq -r '.session, .orchestrator_pane' /Users/josh/Developer/flywheel/.flywheel/evidence/flywheel-se3h.8/topology-counterexamples.jsonl | head -2` → returns `alpsinsurance` and `0` (proves counterexample is in the pack).

## Out-of-scope guard verification

Boundary audit (per "Out Of Scope" in bead body):
- `git -C /Users/josh/Developer/ntm status` → not run; no ntm-side changes
- `gh issue create -R Dicklesworthstone/ntm` → never invoked
- `git push` (any repo) → never invoked
- ntm binary or test files in `~/Developer/ntm` → zero changes (only read for grep)
- Evidence pack lives in flywheel repo at `.flywheel/evidence/flywheel-se3h.8/` — flywheel substrate, not ntm.

## Four-Lens Self-Grade

- **brand:** 9 — read-only research; out-of-scope guards verified explicitly; tracking bead names the trigger condition (Joshua approval) for future upstream contact.
- **sniff:** 9 — three independent surfaces (file:line search, jsonl counterexamples, proposed verbatim wording); each cross-references the others; evidence is re-runnable on demand.
- **jeff:** 9 — anonymizable when promoted to upstream issue (proposed-wording.md "Disposition" cites jeff-issue-chain v1.3 Phase 1 contract for the future Jeffrey-issue dispatch).
- **public:** 9 — Three Judges check:
  - Skeptical operator: re-run grep + jq commands → same 6 hits + 44 counterexample rows. Reproducible.
  - Maintainer: proposed-wording.md gives verbatim replacement strings, so the upstream patch (when authorized) is mechanical.
  - Future worker: tracking bead `flywheel-ksey9` description says "When Joshua approves, follow jeff-issue-chain v1.3 Phase 1 contract from the staged proposal" — clear next step.

four_lens=brand:9,sniff:9,jeff:9,public:9

## Skill auto-routes addressed

- canonical-cli-scoping=n/a (no CLI authored or modified)
- rust-best-practices=n/a (no Rust)
- python-best-practices=n/a (no Python)
- readme-writing=n/a (no README)

## Skill discoveries

`skill_discoveries=0 sd_ids=none` — task fits canonical evidence-staging-with-deferred-upstream pattern (per jeff-issue-chain v1.3 + L52 escape-hatch); no new pattern emerged.

## L61 ecosystem-touch

- `agents_md_updated=not_applicable` — staged proposal, no doctrine landed.
- `readme_updated=not_applicable` — same.
- `no_touch_reason=draft_staging_pre-joshua-approval_no_upstream_push_no_doctrine_change`

## Compliance Pack

Score: 880/1000.

- All 5 bead-acceptance gates passed
- All 3 AG passed
- 6 hit grep + 44-row jsonl + verbatim-replacement-prose evidence pack
- Local tracking bead filed (`flywheel-ksey9`)
- Out-of-scope guards verified (zero upstream pushes, zero binary patches)
- Three-Q VALIDATED/DOCUMENTED/SURFACED satisfied
- Four-Lens self-grade with Three Judges check

Pack path: this report + `ntm-controller-pane-grep.txt` + `topology-counterexamples.jsonl` + `proposed-wording.md`.
