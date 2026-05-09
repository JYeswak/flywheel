# flywheel-35exy Evidence — promote worker-close-git-commit-skipped-* via L143 cross-reference

Task: `flywheel-35exy-b5b572`
Bead: `flywheel-35exy` (P2 OPEN → CLOSED this turn)
Title: [promotion-candidate] worker-close-git-commit-skipped-dirty-shared-doctrine-surfaces (3 events in 7d)
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=infrastructure` — L143
cross-reference INCIDENTS section (same shape as pane 3's
`flywheel-u5ml3` cross-reference for `daily_report_missing_dispatch_gate`).

## Headline finding — L143 cross-reference INCIDENTS section

`worker-close-git-commit-skipped-dirty-shared-doctrine-surfaces` is
the **specific sub-shape** ("skipped due to shared dirty doctrine
surfaces") of the canonical trauma class
`worker-closes-bead-without-git-commit` already covered by L143
(`.flywheel/rules/L094-L143-worker-close-requires-git-commit.md`,
status: long_term, shipped 2026-05-08, review_due 2026-11-08).

L143 ships the canonical Forever-Rule:

> Workers MUST emit `git_committed=<yes|no_changes|skipped>` alongside
> `br_close_executed=yes` in every DONE callback. `skipped` is a
> workflow violation and a fuckup-log promotion candidate.

The 3 events are L143 working as intended — workers correctly
recorded `skipped` per the contract, surfacing the workflow
violation to the fuckup-log. The L56 ladder then promoted the
pattern. Without an INCIDENTS.md surface, the ladder's dedup
heuristic kept seeing "no INCIDENTS coverage" for the class even
though L143 covers it canonically. This entry closes that
visibility loop.

## Why L143 cross-reference (not Path A merge, not standalone)

| Path | Choice | Why |
|---|---|---|
| **L143 cross-reference** (chosen) | `## worker-close-git-commit-skipped-dirty-shared-doctrine-surfaces — already covered by L143` | Same shape as pane 3's `flywheel-u5ml3` cross-reference (line 7421+). L-rule canonical coverage exists; INCIDENTS surface exists only for ladder-dedup discoverability. |
| Path A (Sibling Classes merge) | Append to existing INCIDENTS section | No suitable parent INCIDENTS section — the canonical surface is L143 in `.flywheel/rules/`, NOT an INCIDENTS section. Path A merge into `shared-repo-dirty-preflight` (orch-side) or `concurrent-dirty-validation-drift` (worker-side validation) would be incorrect because those classes are different traumas. |
| Path B (standalone Promotion Action: NEW) | Full L56 promotion section | Would duplicate L143's Forever-Rule across two surfaces. Donella leverage #5 — fewer doctrine surfaces is higher leverage. |

Path C (cross-reference) is the load-bearing template for "L-rule
canonical exists, but L56 ladder doesn't scan `.flywheel/rules/` so
needs an INCIDENTS surface for dedup."

## What changed

### `INCIDENTS.md`

Added new `## worker-close-git-commit-skipped-dirty-shared-doctrine-surfaces — already covered by L143 (2026-05-09 cross-reference)` section at line 6342, immediately after `## concurrent-dirty-validation-drift` (line 6258, my own from earlier). All required template fields populated (Date, Class, Event Count, Severity, Cost, Root Cause, Forever-Rule (already shipped), Fix Applied/Status, Evidence). Plus a `Recurrence Prevention` note documenting the same L56 ladder gap pane 3 flagged.

### `~/.local/state/flywheel/fuckup-processed.jsonl`

Appended row keyed by `bead_id=flywheel-35exy`,
`processed_into=INCIDENTS.md#worker-close-git-commit-skipped-dirty-shared-doctrine-surfaces`,
`processed_by=/flywheel:learn --promote (L143 cross-reference)`,
with the 3 fuckup-log line numbers (4614, 4623, 4627) and the
`skills_extend` note proposing the doctrine-ladder enhancement.

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — substrate updated with close evidence | DID | INCIDENTS.md gains new section at line 6342; `.flywheel/audit/flywheel-35exy/` carries this evidence pack + pinned SHA |
| AG2 — targeted validator passes and named | DID | `bash .flywheel/scripts/incidents-evidence-link-validator.sh --json` returns `status=pass`, `incidents_evidence_missing_count=0`, `entries_checked=112`; template-coverage probe confirms 9/9 required fields |
| AG3 — `br show flywheel-35exy` open until evidence exists | DID | this evidence pack exists; bead is closed in the same turn |

did=3/3 didnt=none gaps=none.

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| INCIDENTS.md (post-promotion) | `INCIDENTS.md` | (see `pinned-shas.txt`) |

## Verification commands (re-runnable)

```bash
# Confirm new section
grep -n "^## worker-close-git-commit-skipped-dirty-shared-doctrine-surfaces" /Users/josh/Developer/flywheel/INCIDENTS.md
# expected: line 6342

# Validator passes
bash /Users/josh/Developer/flywheel/.flywheel/scripts/incidents-evidence-link-validator.sh --json \
  | jq '{status, incidents_evidence_missing_count, entries_checked}'
# expected: status=pass, incidents_evidence_missing_count=0, entries_checked >= 112

# Confirm dedup heuristic now skips the class
/Users/josh/Developer/flywheel/.flywheel/scripts/doctrine-ladder-promote.sh \
  | jq -r '.skipped[] | select(test("worker-close-git-commit-skipped"))'
# expected (post-close): worker-close-git-commit-skipped-dirty-shared-doctrine-surfaces:incidents_covered

# Confirm L143 canonical coverage
ls -la /Users/josh/Developer/flywheel/.flywheel/rules/L094-L143-worker-close-requires-git-commit.md
grep -n "L143 — WORKER-CLOSE-REQUIRES-GIT-COMMIT" /Users/josh/Developer/flywheel/AGENTS.md
```

## L112 probe (worker callback)

```bash
grep -q "^## worker-close-git-commit-skipped-dirty-shared-doctrine-surfaces" /Users/josh/Developer/flywheel/INCIDENTS.md \
  && bash /Users/josh/Developer/flywheel/.flywheel/scripts/incidents-evidence-link-validator.sh --json \
       | jq -e '.status == "pass" and .incidents_evidence_missing_count == 0 and (.entries_checked >= 112)' >/dev/null \
  && echo ok || echo missing
```

Expected (literal): `ok`.

## Boundary

- **No L143 edit.** Canonical L-rule unchanged (`.flywheel/rules/L094-L143-worker-close-requires-git-commit.md`).
- **No close-handler edit.** L143's apply path lives in
  `~/.claude/commands/flywheel/_shared/close-handler.md`; this bead
  doesn't touch it.
- **No mechanical doctrine-ladder fix.** The L56 ladder gap (no
  `.flywheel/rules/` scan) is a known follow-up surfaced in
  `skills_extend` of the processed-ledger row; not authored here.
- **Pane 3's section unchanged.** `## daily_report_missing_dispatch_gate`
  cross-reference section is the template I followed; no edit to it.

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — INCIDENTS doctrine, not README.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — INCIDENTS.md gained a layer-2
  cross-reference entry; AGENTS.md L143 row is unchanged.
- `readme_updated=not_applicable`.
- `no_touch_reason=L143_canonical_L-rule_unchanged_INCIDENTS_cross-reference_only`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes AG1/AG2/AG3 verbatim. Names L143 as canonical
  + uses pane 3's cross-reference template.
- **Sniff: 9** — verified L143 exists at the cited path; AGENTS.md
  citation grep confirmed; validator passes; 9/9 template fields.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small surface
  (one INCIDENTS section + one ledger row); refuses Path A merge or
  standalone NEW section because L143 already canonically covers
  the trauma; surfaces the L56 ladder enhancement as a `skills_extend`
  candidate without authoring it.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: one grep confirms the section;
    one validator command confirms health; L143 path is one `ls`.
  - **maintainer (extending later)**: cross-reference template is
    now used twice in INCIDENTS.md (pane 3's `daily_report_missing_dispatch_gate`
    + this section); the pattern is load-bearing for the next
    "L-rule canonical, INCIDENTS surface needed for ladder
    discoverability" case.
  - **future worker (LLM agent)**: the Path-C decision logic
    (cross-reference vs Path A merge vs Path B standalone) is now
    captured for the next L-rule-canonical/L56-ladder-discovery gap.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-35exy
no_bead_reason=L143_cross-reference_INCIDENTS_section_canonical_L-rule_at_.flywheel/rules/L094-L143-worker-close-requires-git-commit.md_already_covers_trauma_no_followup_observed_L56_ladder_rules_scan_extension_surfaced_as_skills_extend_candidate_for_future_dispatch`.
