# flywheel-2xdi.25 Compliance Pack

Task: `flywheel-2xdi.25-a34da0`
Bead: `flywheel-2xdi.25`
Decision: DONE
Compliance score: 870/1000

## Finding

Same gap class as flywheel-2xdi.20: `gap-hunt-probe.sh
probe_memory_without_cross_link()` (lines 498-512) checks every memory
file under `~/.claude/projects/-Users-josh-Developer-flywheel/memory/*.md`
against six sampled receiver surfaces (`command_text()` at
`gap-hunt-probe.sh:403-412` plus `<repo>/.flywheel/plans/*.md`). If
neither basename nor stem appears, the probe files
`memory-without-cross-link:<basename>`.

`feedback_meadows_rules_unblock_paradigm_intact.md` is a load-bearing
META-RULE: it codifies Donella Meadows leverage-point selection for the
specific case of "paradigm correct but stuck — no producing-loop." The
rule names a trauma class
(`paradigm-correct-but-stuck-no-producing-loop`), a candidate L-rule
(L73 — first-authenticated-action-requires-marker-receipt), and a
canonical schema-extension family (`validation-receipt/v1`). Pre-fix
grep across all six receivers: zero mentions. The doctrine lived in
memory only.

## Repair

Promoted the memory-only rule to canonical substrate by appending an
INCIDENTS entry that:

1. Names the trauma class
   (`paradigm-correct-but-stuck-no-producing-loop`).
2. States the Forever-Rule: when a fail-closed gate has no
   producing-loop, ratify the missing contract (Meadows #5 RULES) —
   not paradigm change (#2) or info flow alone (#6).
3. Lists the three anti-pattern checks (Leverage Theater, Parameter
   Thrashing, Reminder Substitution) before rule-ratification.
4. Documents the four when-NOT-to-apply branches so future workers
   don't misclassify (paradigm broken → #2 Joshua-disposes; goal
   wrong → #3 mission-anchor; info missing → #6 doctor signal;
   contract canonical-but-unenforced → wire-in not re-ratify).
5. Cites the original trigger instance (skillos-1kc fail-closed
   `missing_or_unproven_sandbox_auth_marker` 2026-05-04T00:15Z,
   ~50min wedge) and the resolution dispatch (`d07f7a96` to
   skillos:2 post-ratification).
6. Cites the memory file by full path so the gap-hunter regex finds
   it; cites the companion memories
   (`feedback_orch_paralysis_recurring`,
   `feedback_orchestrator_must_dispatch`); cites the
   donella-meadows-systems-thinking skill references; cites the probe
   source line numbers.

## Acceptance Gate Map

The bead's only test gate is implicit: the gap-hunt-probe should no
longer surface
`memory-without-cross-link:feedback_meadows_rules_unblock_paradigm_intact.md`.

- AG1: post-edit gap-hunt-probe re-run returns empty for that gap id. ✓
  (`hits=[]`)

did=1/1

## Evidence

```text
$ grep -c "feedback_meadows_rules_unblock_paradigm_intact" /Users/josh/Developer/flywheel/INCIDENTS.md
# pre-fix: 0
# post-fix: 3

$ bash .flywheel/scripts/gap-hunt-probe.sh \
  | python3 -c 'import json,sys; d=json.load(sys.stdin);
                hits=[g for g in d.get("gap_ids",[])
                      if "memory-without-cross-link" in g
                      and "feedback_meadows_rules_unblock_paradigm_intact" in g];
                print("post-fix hits:", hits)'
post-fix hits: []
```

The 3 post-fix mentions cover (1) section heading not directly named
the file but cites it in (2) the explicit Memory: bullet, (3) probe
source citation. Three citations is a comfortable margin against minor
edits accidentally re-triggering the gap.

## Scope

- Edits: INCIDENTS.md only (single trailing append; no other surface)
- Files reserved/released: that path
- Out of scope: promoting the memory to AGENTS.md as a numbered
  L-rule. The memory itself names L73 as a CANDIDATE L-rule
  ("propagate via ft04 sync after real-use validation") — that's a
  separate doctrine-promotion bead, not the cross-link gap closure
  this bead asks for.

## L52 / L80 / L120 / L61

- DIDNT: none
- GAPS: none new
- beads_filed: none
- beads_updated: none
- no_bead_reason: single-cross-link-promotion-no-followup
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable — META-RULE belongs in INCIDENTS,
  not as a numbered AGENTS L-rule (memory itself defers L73 promotion
  to "after real-use validation")
- readme_updated: not_applicable — operational rule for orchestrator
  leverage-point selection; not user-facing README narrative
- no_touch_reason (AGENTS.md): meta-rule-belongs-in-incidents-not-l-rule

## Four Lens

- Brand: 9 (matches the canonical INCIDENTS shape established by
  flywheel-2xdi.20: Root Cause / Forever-Rule with anti-pattern
  checks / when-NOT-to-apply / Fix Applied / Evidence with explicit
  memory + bead + companion-memory + skill + probe-source citations.
  The Meadows framing is preserved verbatim.)
- Sniff: 9 (pre/post grep delta + probe re-run + cited line numbers
  in probe source code; the entry is auditable end-to-end)
- Jeff: 7 (no Jeff-substrate touch)
- Public: 9 (a future operator hitting a fail-closed-no-producing-loop
  state can grep "paradigm-correct-but-stuck" or
  "missing_or_unproven_sandbox_auth_marker" in this repo and find the
  rule + the original instance + the resolution shape in one INCIDENTS
  entry)

## Skill Auto-Routes

- canonical-cli-scoping: n/a — no CLI added
- rust-best-practices: n/a — no Rust touched
- python-best-practices: n/a — no Python touched
- readme-writing: n/a — INCIDENTS prose follows existing entry shape

## L112 Probe

```
grep -c "feedback_meadows_rules_unblock_paradigm_intact" /Users/josh/Developer/flywheel/INCIDENTS.md
```
Expected: `literal:3` (3 distinct citations in the new INCIDENTS entry).
