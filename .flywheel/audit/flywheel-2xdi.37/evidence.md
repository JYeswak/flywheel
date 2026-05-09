# flywheel-2xdi.37 Evidence — gap-hunter false-positive on bead-without-followup:flywheel-0h0b

Task: `flywheel-2xdi.37-305afd`
Bead: `flywheel-2xdi.37` (P3 OPEN → CLOSED this turn)
Title: [gap-bead-without-followup] flywheel-0h0b
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Source: `gap-hunt-probe.sh probe_bead_without_followup` flagged closed
bead `flywheel-0h0b` because its body matches the regex
`\b(doctrine|canonical|promote|promotion)\b` but the bead is not
cited in `INCIDENTS.md`.
Mission fitness: `mission_fitness=infrastructure` — narrows the
gap-hunter's false-positive class so future bead-without-followup
surfaces stay signal-rich.

## Headline finding — false positive (regex hits boilerplate, not doctrine claim)

Bead `flywheel-0h0b` is upstream-issue draft work: "Lane B drafted
upstream issue body for source_health/pane_pid/pane_dead/collected_at
on --robot-tail/--robot-activity. Existing #114 closed — decide
comment-on-114 vs new-with-backref via L66 Phase 2 multi-model
triangulation + Joshua signoff." It does NOT promote any local
doctrine surface.

The regex hit two tokens that come from boilerplate, not from a
promotion claim:

| Token | Where it appears | Real signal? |
|---|---|---|
| `doctrine` | AG1 standard template line: "The artifact, command, or **doctrine** surface named in `<title>` is updated with close evidence." | NO — appears in every closed bead's AG1 |
| `canonical` | Skill reference: "Skills: dicklesworthstone-stack, jeff-planning-enhanced, **canonical**-cli-scoping" | NO — that's a skill name, not a canonical-doctrine claim |
| `promote` / `promotion` | NOT present | n/a |

Same shape as the 4 existing false-positive entries in
`bead_followup_false_positive_reason()` (lines 542-575 of the script):
plan-space, mkdir-lock-fallback-plan, external-issue-reply-draft,
recover-pane-command-spec.

## What this rework does

| Action | Status |
|---|---|
| Add 5th suppression entry — `upstream-issue-draft-or-comment-decision` | DID — `.flywheel/scripts/gap-hunt-probe.sh` lines extended with the new tuple inside `bead_followup_false_positive_reason()` |
| Verify the suppression catches 0h0b | DID — `bash tests/gap-hunt-probe-0h0b-suppression-smoke.sh` 7/7 PASS; live `--dry-run` no longer surfaces `bead-without-followup:flywheel-0h0b` in `gap_ids` |
| Verify no over-match across cohort | DID — manual scan of 8 other "upstream"-titled closed beads (`flywheel-ithky`, `flywheel-txeui.1`, `flywheel-kvta`, `flywheel-wy0uh`, `flywheel-6zgt`, `flywheel-wutd`, `flywheel-eala`, `flywheel-dm83`); zero matched all 3 needles, so the suppression fires only on 0h0b today |

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — substrate updated with close evidence | DID | `.flywheel/audit/flywheel-2xdi.37/` carries this evidence pack, smoke output, false-positive-evidence.txt, pinned SHAs |
| AG2 — targeted test passes and named | DID | `bash tests/gap-hunt-probe-0h0b-suppression-smoke.sh` returns `SUMMARY pass=7 fail=0`; the canonical assertion `flywheel-0h0b is suppressed in --dry-run gap_ids` passes |
| AG3 — `br show flywheel-2xdi.37` open until evidence exists | DID | this evidence pack exists; bead is closed in the same turn |

did=3/3 didnt=none gaps=none.

## Suppression entry (lowercase needles, ALL must match)

```python
(
    # 2026-05-09 (flywheel-2xdi.37): bead flywheel-0h0b drafts an
    # upstream ntm#114 issue body and routes the comment-vs-new
    # decision through Joshua signoff. The body mentions "doctrine"
    # only via the standard AG1 boilerplate ("doctrine surface
    # named in...") and "canonical" only via skill name reference
    # ("canonical-cli-scoping"), neither of which signals a local
    # INCIDENTS/AGENTS promotion.
    "upstream-issue-draft-or-comment-decision",
    [
        "[upstream-issue]",
        "comment-on-114",
        "joshua signoff",
    ],
),
```

Needle precision (verified across cohort):

| Bead | `[upstream-issue]` | `comment-on-114` | `joshua signoff` | All-3? |
|---|---|---|---|---|
| flywheel-0h0b | 2 | 1 | 1 | YES (suppress) |
| flywheel-ithky / txeui.1 / kvta / wy0uh / eala / dm83 | 0 | 0 | 0 | no |
| flywheel-6zgt | 0 | 0 | 0 | no |
| flywheel-wutd | 0 | 0 | 1 | no |

Only 0h0b matches — zero over-suppression risk.

## Smoke coverage matrix

| # | Test | Behavior |
|---|---|---|
| 1 | gap-hunt-probe.sh is executable | substrate gate |
| 2 | bash -n syntax ok | wrapper integrity |
| 3 | suppression entry + 3 needles present in source | source-level guard |
| 4 | `--info --json` envelope still valid | full-script integrity (no Python compile-time break) |
| 5 | `--dry-run --json` envelope valid (`dry_run=true`, non-empty `gap_class_distribution`) | end-to-end probe runs |
| 6 | flywheel-0h0b not in `gap_ids` | **canonical suppression assertion** |
| 7 | `gap_class_distribution.bead-without-followup` is a number | shape stability |

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| gap-hunt-probe (post-edit) | `.flywheel/scripts/gap-hunt-probe.sh` | `7d7ebf0f76bcdd67225f1d611c855f3a40c1a436343c4ecd957b3cb83b2b3a38` |
| smoke test | `tests/gap-hunt-probe-0h0b-suppression-smoke.sh` | `b79afcbae3df99144e530773d113e970494a1ef7e97905e4f80f35b2bc6b7641` |

## Verification commands (re-runnable)

```bash
# Suppression smoke (7/7 PASS, ~30s for the dry-run pass)
bash /Users/josh/Developer/flywheel/tests/gap-hunt-probe-0h0b-suppression-smoke.sh

# Live: confirm 0h0b is NOT in gap_ids
/Users/josh/Developer/flywheel/.flywheel/scripts/gap-hunt-probe.sh \
  --json --dry-run 2>/dev/null | jq -r '.gap_ids[]' | grep "0h0b" \
  && echo NOT-suppressed || echo suppressed-correctly
```

## L112 probe (worker callback)

```bash
bash /Users/josh/Developer/flywheel/tests/gap-hunt-probe-0h0b-suppression-smoke.sh 2>/dev/null | tail -1
```

Expected (literal): `SUMMARY pass=7 fail=0`.

## Boundary

- **No INCIDENTS.md edit.** The suppression is the right fix for a regex false positive; adding 0h0b to INCIDENTS.md would falsify the doctrine surface (this was upstream-issue draft work, not a local doctrine event).
- **No 0h0b mutation.** The closed bead's body and close note are unchanged; we just teach the gap-hunter to recognize this work shape.
- **No other suppression entries touched.** The 4 existing entries remain intact.
- **Same false-positive resolution template** as `external-issue-reply-draft` (which suppresses ntm#113 reply-draft work). 0h0b is the ntm#114 sibling.

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — embedded Python; one new tuple in an existing list. No new function or signature; no public API change.
- `readme-writing=n/a` — audit doc.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no doctrine surface mutated; the suppression is per-bead heuristic narrowing.
- `readme_updated=not_applicable`.
- `no_touch_reason=heuristic_narrowing_only_no_doctrine_or_AGENTS_change_required`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — names the false positive precisely (regex matches AG1 boilerplate + skill-name reference, not promotion claim) and resolves it via the existing suppressions list pattern.
- **Sniff: 9** — needle precision verified across 8 other upstream-titled closed beads (zero over-match); 7/7 PASS smoke with explicit suppression assertion + script-integrity gates.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small surface (one suppression tuple + one smoke test); refuses to mutate the closed bead's body or push to INCIDENTS just to satisfy the heuristic.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: one bash command runs the smoke; one shell line confirms 0h0b suppression on the live probe.
  - **maintainer (extending later)**: the suppressions list is now 5 entries, each per-class with bead-specific needles; the documented inline comment explains why this entry exists so future maintainers don't lose the context.
  - **future worker (LLM agent)**: the false-positive class for `upstream-issue-draft-or-comment-decision` is now a named cohort; sibling beads (e.g., a hypothetical ntm#115 draft) can be added by extending the same tuple's needles.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-2xdi.37
no_bead_reason=heuristic_narrowing_complete_no_followup_observed`.
