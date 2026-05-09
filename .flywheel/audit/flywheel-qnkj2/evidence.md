# flywheel-qnkj2 Evidence — superseded by flywheel-2tgl + dedup root-cause fix

Task: `flywheel-qnkj2-b0c54f`
Bead: `flywheel-qnkj2` (P2 OPEN → CLOSED this turn)
Title: [promotion-candidate] agent-mail-reservation-timeout (3 events in 7d)
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=infrastructure` — supersession-class
close + root-cause fix in the doctrine-ladder dedup heuristic so future
ladder scans don't re-file the same class.

## Headline finding — superseded + dedup heuristic bug

This bead is a **duplicate** of `flywheel-2tgl` (P2 CLOSED 2026-05-08).
Both were auto-filed by `doctrine-ladder-promote.sh` for the same
trauma class `agent-mail-reservation-timeout`. Sister bead
`flywheel-2tgl` already shipped the canonical INCIDENTS.md promotion
on 2026-05-08T... ("Promoted agent-mail-reservation-timeout to
layer-2 INCIDENTS coverage in
INCIDENTS.md#agent-mail-reservation-timeout"). Live INCIDENTS.md has
5 substantive references at lines 5730-6436.

The duplicate filing happened because **`default_incident_paths()` in
`doctrine-ladder-promote.sh` did not search the repo-local
`/Users/josh/Developer/flywheel/INCIDENTS.md`** — only the skill-area
INCIDENTS files and `AGENTS.md`. Pre-fix paths:

```
~/.claude/skills/.flywheel/INCIDENTS.md   (0 mentions)
~/.claude/skills/*/references/INCIDENTS.md (0 mentions)
$REPO/AGENTS.md                            (0 mentions)
```

Post-fix paths:

```
~/.claude/skills/.flywheel/INCIDENTS.md
~/.claude/skills/*/references/INCIDENTS.md
$REPO/INCIDENTS.md                         (5 substantive mentions ✓)
$REPO/AGENTS.md
```

This rework therefore:

1. Documents the supersession (this bead's work was already shipped under flywheel-2tgl on 2026-05-08).
2. Fixes the root-cause dedup gap so the heuristic stops creating duplicate promotion candidates.
3. Lands a smoke test that exercises the dedup path against a synthetic fuckup-log + the live regression for `agent-mail-reservation-timeout`.

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — substrate updated with close evidence | DID | `.flywheel/audit/flywheel-qnkj2/` carries this evidence pack, smoke output, supersession trail, pinned SHAs; `doctrine-ladder-promote.sh` patched + tested |
| AG2 — targeted test passes and named | DID | `bash tests/doctrine-ladder-promote-incidents-dedup-smoke.sh` returns `SUMMARY pass=7 fail=0`; canonical regression gate is "agent-mail-reservation-timeout is now skipped via repo-local INCIDENTS.md" |
| AG3 — `br show flywheel-qnkj2` open until evidence exists | DID | this evidence pack exists; bead is closed in the same turn |

did=3/3 didnt=none gaps=none.

## What changed

`/Users/josh/Developer/flywheel/.flywheel/scripts/doctrine-ladder-promote.sh`:

```diff
 default_incident_paths() {
   printf '%s\n' "$HOME/.claude/skills/.flywheel/INCIDENTS.md"
   printf '%s\n' "$HOME"/.claude/skills/*/references/INCIDENTS.md
+  printf '%s\n' "$REPO/INCIDENTS.md"
   printf '%s\n' "$REPO/AGENTS.md"
 }
```

One additional path entry. The `incidents_cover_class()` function (line 53) already searches each path with `grep -Fqi`, so the patch wires the missing repo-local surface in without changing the search semantics.

## Smoke coverage matrix

| # | Test | Behavior |
|---|---|---|
| 1 | doctrine-ladder-promote.sh exists + bash -n ok | substrate gate |
| 2 | default_incident_paths includes `$REPO/INCIDENTS.md` post-fix and `$REPO/AGENTS.md` | source-level guard |
| 3 | script exits rc=0 under synthetic fuckup-log | end-to-end gate |
| 4 | covered class skipped with reason=incidents_covered | dedup happy-path |
| 5 | uncovered class still gets created (heuristic active) | no over-suppression |
| 6 | live default-path run completed | live integration |
| 7 | **agent-mail-reservation-timeout skipped via repo-local INCIDENTS.md** (canonical regression gate) | confirms 0h0b-class duplicate-filing bug fixed |

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| script (post-fix) | `.flywheel/scripts/doctrine-ladder-promote.sh` | `a6ee3b3eaa2fc821276bc423b698cea2e44aad183b0bf5a8508f88a08660f67c` |
| smoke test | `tests/doctrine-ladder-promote-incidents-dedup-smoke.sh` | `0557c01353e58e9da56faf3988c1bb0bafedfa6e8f1c1c15db1a65bcca222885` |

## Supersession trail

| Bead | Status | Role |
|---|---|---|
| `flywheel-2tgl` | CLOSED 2026-05-08 | Canonical promotion: ran `/flywheel:learn --promote agent-mail-reservation-timeout`, landed INCIDENTS.md entry at line 5730. |
| `flywheel-qnkj2` (this) | CLOSED (this turn) | Duplicate auto-fired today because the dedup heuristic missed `$REPO/INCIDENTS.md`. Resolves as supersession + root-cause fix. |

## Why no `/flywheel:learn --promote` re-run

INCIDENTS.md already carries 5 substantive references (lines 5730, 5736, 5752, 5765, 6436) authored by sister bead `flywheel-2tgl`. Re-running `/flywheel:learn --promote agent-mail-reservation-timeout` would either:

1. Refuse because INCIDENTS coverage exists (no-op), OR
2. Append a duplicate INCIDENTS section (canonical surface drift).

Neither is a valid action. The canonical action is supersession-close + root-cause fix, exactly what this rework does.

## Verification commands (re-runnable)

```bash
# Smoke — 7/7 PASS
bash /Users/josh/Developer/flywheel/tests/doctrine-ladder-promote-incidents-dedup-smoke.sh

# Live: confirm the dedup catches agent-mail-reservation-timeout
/Users/josh/Developer/flywheel/.flywheel/scripts/doctrine-ladder-promote.sh \
  | jq -r '.skipped[] | select(test("agent-mail-reservation-timeout"))'
# expected: agent-mail-reservation-timeout:incidents_covered

# Confirm the path entry landed in the script
grep -n '"\$REPO/INCIDENTS.md"' /Users/josh/Developer/flywheel/.flywheel/scripts/doctrine-ladder-promote.sh
# expected: line 42 (between skills paths and AGENTS.md)
```

## L112 probe (worker callback)

```bash
bash /Users/josh/Developer/flywheel/tests/doctrine-ladder-promote-incidents-dedup-smoke.sh 2>/dev/null | tail -1
```

Expected (literal): `SUMMARY pass=7 fail=0`.

## Boundary

- **No INCIDENTS.md edit.** Sister bead `flywheel-2tgl` already shipped the canonical doctrine entry on 2026-05-08; the layer-2 coverage is intact and unchanged.
- **No `/flywheel:learn --promote` invocation.** Re-running would either no-op or duplicate-write — neither is a valid action.
- **No bead merge.** flywheel-qnkj2 closes as superseded with explicit reference to flywheel-2tgl; flywheel-2tgl stays closed at the canonical artifact.
- **No fixture-setup pattern.** Per the orch's recovery directive ("re-dispatching panes 2 and 4 to non-fixture-setup beads to avoid retriggering the same incident class"), this rework intentionally avoids the cd-into-tmp-fixture pattern that caused the earlier MISSION/STATE/GOAL clobber. Synthetic state lives entirely in `$TMP` with absolute paths; no `cd` to fragile constructed paths.

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — audit doc; smoke is a per-bug test.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no doctrine surface mutated. The dedup fix is a heuristic-narrowing patch, not an L-rule.
- `readme_updated=not_applicable`.
- `no_touch_reason=heuristic_path-list_extension_no_doctrine_or_AGENTS_change_required`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes AG1/AG2/AG3 verbatim. Names the supersession explicitly + fixes the root-cause path-list gap so future scans don't re-trip.
- **Sniff: 9** — synthetic fuckup-log + live regression both gate; canonical assertion is `agent-mail-reservation-timeout is now skipped via repo-local INCIDENTS.md`; no over-suppression (uncovered class still gets created in the synthetic fixture).
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small surface (one path-list entry + one smoke test); refuses to re-run `/flywheel:learn --promote` against existing canonical coverage; cites sister bead with date and line numbers.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: 7-gate smoke runs in <1s; one shell command confirms the dedup against the live trauma class.
  - **maintainer (extending later)**: the path-list shape makes adding new INCIDENTS surfaces (e.g., per-tentacle repos) a one-line patch.
  - **future worker (LLM agent)**: the supersession + root-cause-fix template is reusable for the next "auto-doctor heuristic re-fires after canonical coverage exists" duplicate.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-qnkj2
no_bead_reason=supersession_close_plus_root-cause_dedup_fix_no_followup_observed_canonical_coverage_already_present_via_flywheel-2tgl`.
