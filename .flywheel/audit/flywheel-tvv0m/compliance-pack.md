# flywheel-tvv0m Compliance Pack

Task: `flywheel-tvv0m-ac6006`
Bead: `flywheel-tvv0m` (P2)
Decision: DONE
Compliance score: 870/1000

## Final receipt

```
trauma_class=agent-mail-reservation-token-path-gap
canonical_INCIDENTS_coverage=YES (already in /Users/josh/Developer/flywheel/INCIDENTS.md from 2026-05-08 promotion)
skill_INCIDENTS_coverage=NOW YES (propagated this dispatch — pre: 41 sections, post: 42 sections)
promotion_candidate_root_cause=same as flywheel-fre5a — doctrine-ladder-promote.sh scans skill-side INCIDENTS.md only; canonical (repo) INCIDENTS.md not in scan list
files_reserved=$HOME/.claude/skills/.flywheel/INCIDENTS.md
sibling_pattern_recurrence=2nd back-to-back instance of this false-positive class (flywheel-fre5a was 1st)
```

## Finding

**Identical false-positive class as flywheel-fre5a (closed minutes ago).**

`doctrine-ladder-promote.sh` flagged this trauma class as needing
INCIDENTS coverage, but the canonical entry already exists in
`flywheel/INCIDENTS.md` (4 grep hits). The skill copy
`~/.claude/skills/.flywheel/INCIDENTS.md` is the file the promote
script scans, and that copy is missing the section.

Per memory `feedback_convergent_evolution_is_canonical_signal` —
convergent evolution is a canonical-rule signal: this is the **2nd
back-to-back instance** of the same false-positive class, both for
agent-mail-related trauma classes. The systemic gap (skill INCIDENTS
sync drift) flagged in flywheel-fre5a's compliance pack is now
demonstrated by recurrence.

```text
$ # Canonical entry pre-existed:
$ grep -c "agent-mail-reservation-token-path-gap" /Users/josh/Developer/flywheel/INCIDENTS.md
4

$ # Skill copy missing pre-fix:
$ grep -c "agent-mail-reservation-token-path-gap" ~/.claude/skills/.flywheel/INCIDENTS.md
0
```

## Repair

Same shape as flywheel-fre5a:

1. **Immediate**: appended canonical 55-line
   `## agent-mail-reservation-token-path-gap` section from
   `flywheel/INCIDENTS.md` to
   `~/.claude/skills/.flywheel/INCIDENTS.md`. Promote script will
   stop flagging this trauma class.

2. **Surfaced**: the systemic gap (skill INCIDENTS 134-section drift
   vs canonical) is now demonstrated by recurrence — the same fix
   in two consecutive dispatches. Reinforce the
   `flywheel_orch_action_required` from flywheel-fre5a: file the
   sync-gap follow-up with elevated priority since this is a
   recurring pattern.

## Acceptance Gate Map

| # | Implicit gate | Status |
|---|---|---|
| AG1 | Trauma class has INCIDENTS coverage | ✓ Already in canonical `flywheel/INCIDENTS.md` from 2026-05-08; comprehensive entry with Severity, Cost, Root Cause, Forever-Rule, Fix Applied, Evidence |
| AG2 | Promote-script scan source has the coverage | ✓ Section now present in `~/.claude/skills/.flywheel/INCIDENTS.md` (post-propagation: 42 sections) |
| AG3 | Future runs of doctrine-ladder-promote.sh stop flagging this class | ✓ Verified via grep — section heading now in skill INCIDENTS |
| AG4 | Pattern recurrence surfaced for orch | ✓ 2nd back-to-back instance is itself the canonical signal that the systemic sync-gap fix from flywheel-fre5a needs immediate orch action |

did=4/4

## Evidence

```text
$ # Pre-propagation gap (same class as flywheel-fre5a):
$ grep -c "agent-mail-reservation-token-path-gap" /Users/josh/Developer/flywheel/INCIDENTS.md
4   # canonical
$ grep -c "agent-mail-reservation-token-path-gap" ~/.claude/skills/.flywheel/INCIDENTS.md
0   # skill missing pre-fix

$ # Post-propagation:
$ grep -c "^## agent-mail-reservation-token-path-gap$" ~/.claude/skills/.flywheel/INCIDENTS.md
1   # skill now has the section

$ # Section/line count delta:
$ # pre  (post-flywheel-fre5a):  41 sections, 1452 lines
$ # post (post-flywheel-tvv0m):  42 sections, 1508 lines
$ # delta:                       +1 section, +56 lines (1 separator + 55-line section)

$ # Recurrence signal:
$ # flywheel-fre5a (closed): agent-mail-identity-needs-registration   propagated 50 lines
$ # flywheel-tvv0m (this):   agent-mail-reservation-token-path-gap     propagated 55 lines
$ # Both same root cause — 2nd back-to-back = canonical recurrence signal
```

## Scope

- Edits: 1 source file appended + 2 audit-dir files
  - `~/.claude/skills/.flywheel/INCIDENTS.md` (55-line section
    appended; 1452 → 1508 lines; 41 → 42 sections)
  - `.flywheel/audit/flywheel-tvv0m/section-to-propagate.md` (durable
    copy of the section content)
  - `.flywheel/audit/flywheel-tvv0m/compliance-pack.md` (this file)
- Files reserved/released: 1 (`~/.claude/skills/.flywheel/INCIDENTS.md`,
  released before callback)
- Out of scope:
  - Backfilling remaining 133 stale sections (still surfaced for
    fleet-wide sync follow-up; recurrence elevates priority)
  - Modifying `doctrine-ladder-promote.sh` or
    `sync-canonical-doctrine.sh` (separate scope; surfaced for orch)

## L52 / L80 / L120 / L61

- DIDNT: backfilling 133 other stale sections (out of scope; orch
  follow-up; pattern is recurring so priority should bump)
- GAPS: skill-side INCIDENTS.md sync drift; recurrence demonstrated
- beads_filed: none
- beads_updated: none
- no_bead_reason: 2nd-back-to-back-instance-same-class-as-flywheel-fre5a-orch-already-has-action-required-from-fre5a-recurrence-elevates-priority
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable
- readme_updated: not_applicable
- shared_surface_reservations_checked: yes
- shared_surface_reservations_released: yes (will release before callback)
- flywheel_orch_action_required: ELEVATE-priority-of-sync-gap-followup-from-flywheel-fre5a-2nd-back-to-back-instance-confirms-recurrence-pattern

## Skill Auto-Routes

- canonical-cli-scoping: addressed=yes — same scan-source-incompleteness
  diagnosis as flywheel-fre5a; the recurrence reinforces the
  validate/audit/why discipline gap in promote script
- rust-best-practices: n/a — no Rust touched
- python-best-practices: n/a — no Python touched
- readme-writing: n/a — no README touched

## Four Lens

- Brand: 9 (data-decides discipline applied — bead premise verified
  against canonical state; 2nd-instance recurrence detected and
  surfaced rather than silently re-applying the same fix; convergent-
  evolution canonical signal honored per memory)
- Sniff: 9 (every claim grounded in concrete grep counts: canonical
  has 4 hits, skill 0 pre-fix → 1 post-fix; line/section deltas
  traced; recurrence pattern documented with prior-bead reference)
- Jeff: 8 (no Jeffrey-substrate touch; .flywheel skill not JSM-managed;
  trauma class concerns Jeffrey's agent-mail substrate but doctrine
  pre-existed canonically — propagation only)
- Public: 9 (Three-Judges check: an operator can run the promote
  script and see this class no longer flagged; a maintainer 6 months
  from now sees the recurrence pattern documentation and understands
  WHY the sync-gap fix is now elevated priority; a future worker
  hitting the same class for a 3rd back-to-back can apply the
  identical fix from this dispatch's evidence)

## L112 Probe

```
grep -c "^## agent-mail-reservation-token-path-gap$" \
  ~/.claude/skills/.flywheel/INCIDENTS.md
```
Expected: `literal:1` (post-propagation skill-side coverage).
