# flywheel-vl0c9 — extend doctrine-ladder-promote.sh incident_paths to scan .flywheel/rules/

## Bead context

- ID: `flywheel-vl0c9` (P3)
- Title: `[doctrine-ladder-improvement] extend doctrine-ladder-promote.sh incident_paths to scan .flywheel/rules/`
- Filed by: surfaced today across multiple cross-references (`u5ml3` daily_report_missing, `wb6oc` mobile-eats-dispatch, `q1y1d` sister-orch-2-tick, `2xdi.40` autoloop-executor, etc.) — each documented this same gap as a future improvement and intentionally not file-and-forget. This bead is the canonical implementation.
- DoD (4 gates): rules-glob added; synthetic L-rule-only class returns `skipped:incidents_covered`; existing INCIDENTS.md scan still works; bash -n clean.

## Fix shape

Three additions to `default_incident_paths()` (`.flywheel/scripts/doctrine-ladder-promote.sh:50`):

```bash
printf '%s\n' "$REPO"/.flywheel/rules/*.md
printf '%s\n' "$HOME"/.claude/skills/.flywheel/rules/*.md
printf '%s\n' /Users/josh/Developer/flywheel/.flywheel/rules/*.md
```

Same shape as the prior `flywheel-iyaym` precedent: triple coverage (REPO-relative + CLAUDE_ROOT + canonical absolute) so worktree-relative `$REPO` never masks coverage. Existing `incidents_cover_class()` already filters non-existent paths via `[ -f "$path" ] || continue`, so unmatched globs print harmlessly through.

## Live effect

Before fix:
```
$ doctrine-ladder-promote.sh ... | jq '.skipped'
[]   # 60+ classes were going to be filed as new promotion-candidate beads
```

After fix (with FUCKUP_LOG containing the historical 7-day window):
```
$ FUCKUP_LOG=$HOME/.local/state/flywheel/fuckup-log.jsonl doctrine-ladder-promote.sh /Users/josh/Developer/flywheel | jq -c '.skipped | length'
60+
```

Specific classes that now skip via L-rule-body coverage (each previously generated cross-reference INCIDENTS entries today):

| Class | Covered by L-rule |
|---|---|
| `daily_report_missing_dispatch_gate` | L91 `dispatch-delivery-is-a-four-state-receipt` Why section |
| `sister-orch-2-tick-blocker` | `two-blocker-ticks-escalate` (sibling INCIDENTS) — also matched by L-rule fixtures |
| `mobile-eats-dispatch-health-gate-fail` | L91+L92 cite the trauma family |
| `three_q_surface_gap` | L92 `audit-findings-route-by-data` Why section |
| `worker_capacity_gate_failed` | L95 worker-stall-recovery + integrate-prelude-blocked rules |
| `orch-punt-to-next-tick-instead-of-next-actionable` | L70 + L152 |
| (and 50+ more) | various L-rule citations |

This is exactly the Donella #5→#6 leverage point the cross-references identified: rules (canonical doctrine) wired into information flow (the ladder probe's coverage gate).

## DoD verification

| Gate | Done |
|---|---|
| `default_incident_paths()` scans `.flywheel/rules/*.md` | yes — 3 globs added (REPO + CLAUDE_ROOT + canonical) |
| Synthetic class with only L-rule coverage returns `skipped:incidents_covered` | yes — T4 PASS with fixture rule file |
| Existing INCIDENTS.md scan still works | yes — T6 PASS with INCIDENTS.md-only fixture |
| `bash -n` clean | yes — T1 PASS |

`did=4/4`

## Regression test

`.flywheel/tests/test-doctrine-ladder-promote-rules-coverage.sh` (7/7 PASS):

- T1 bash -n clean
- T2 static grep — function source contains 3 rules-glob `printf` lines
- T3 empty FUCKUP_LOG → 0 created, 0 skipped
- T4 synthetic class with L-rule fixture coverage → `skipped:incidents_covered`
- T5 same class WITHOUT rules fixture → NOT covered (proves rules-glob is the gate)
- T5b br_bin stub forces `bead_exists` path → no live bead created
- T6 INCIDENTS.md-only fixture still returns covered (backward compat)

## fuckup_logged: l52-test-design-spillage

The initial test design used `bash -c "source $PROMOTE; ..."` to test the function directly. But `doctrine-ladder-promote.sh` runs its main flow at file end (no main guard), so sourcing triggered the live-FUCKUP_LOG processing path on every invocation. **58 promotion-candidate beads were accidentally created** during the first test run (one for each currently-uncovered trauma class in the live fuckup-log, since the fixture INCIDENTS_SEARCH_PATHS deliberately excluded the rules dir for the negative test).

**Recovery**: all 58 spillage beads batch-closed via `br close $(cat /tmp/vl0c9-bead-ids.txt)`. Verified post-close: 0 of those 58 remain open.

**Test rewrite**: subprocess-only (no `source`). Every invocation uses `FUCKUP_LOG=<empty fixture>` (no classes accumulate) OR `FUCKUP_LOG=<synthetic-only fixture>` (single synthetic class) plus `BR_BIN=<stub>` for the negative-coverage T5 path so the script falls through to `skipped:bead_exists` instead of creating a real bead. Test now produces ZERO live beads.

`fuckups_logged=l52-test-design-spillage`

## Skill auto-routes

| Route | Status | Note |
|---|---|---|
| canonical-cli-scoping | yes-partial | The promote script is shell-first; my edit preserves its shape (function-only addition, no new flags). The existing script doesn't have a full triad — that's pre-existing scope, not introduced by this edit. |
| rust-best-practices | n/a | Bash + python3 heredoc |
| python-best-practices | n/a | The python heredoc is unchanged by this edit |
| readme-writing | n/a | No README touched |

## Four-Lens Self-Grade

- **brand: 8** — straightforward 3-line accretion matches Joshua-style "extend coverage at canonical source"; lost 1 point for the spillage incident even though recovered cleanly.
- **sniff: 8** — fix is small and right, but test design had a real failure mode (sourcing main-flow script); rewrite + cleanup recovered cleanly. Honest reduction from 9 because spillage-class incidents waste fleet attention.
- **jeff: 9** — single-source-of-truth: L-rules ARE the canonical doctrine; the ladder's coverage scan now matches the actual canonical surface. Closes a pattern that had 6+ duplicate cross-reference filings today.
- **public: 9** — Three Judges: skeptical operator (60+ classes flip to covered immediately on the live fuckup-log), maintainer (rewritten test is subprocess-only with stubs; 7/7 PASS), future worker (the spillage class is now logged + recovery procedure documented).

`four_lens=brand:8,sniff:8,jeff:9,public:9`

## Mission fitness

`infrastructure` — the L56 ladder is the orchestrator's structural promotion path from fuckup-log → INCIDENTS → canonical L-rule. By teaching it that L-rules are canonical INCIDENTS coverage, this fix collapses an entire class of cross-reference noise that was eating ~5+ orchestrator dispatches per day. Directly serves continuous-orchestrator-uptime by tightening Step L56 signal-to-noise.

## L61 ECOSYSTEM-TOUCH

This work touches `.flywheel/scripts/doctrine-ladder-promote.sh` — a doctrine surface (the L56 ladder probe). Per L61:

- `agents_md_updated=no` — AGENTS.md doesn't need to mirror this; the change is mechanism, not doctrine.
- `readme_updated=not_applicable` — no README touched.
- `no_touch_reason=this is a probe-mechanism enhancement; the canonical L56 ladder doctrine in AGENTS.md remains accurate; the change tightens the gate to match the actual L-rule canonical surface that already exists.`
