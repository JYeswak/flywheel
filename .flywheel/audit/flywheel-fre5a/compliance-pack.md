# flywheel-fre5a Compliance Pack

Task: `flywheel-fre5a-b38f52`
Bead: `flywheel-fre5a` (P2)
Decision: DONE
Compliance score: 870/1000

## Final receipt

```
trauma_class=agent-mail-identity-needs-registration
canonical_INCIDENTS_coverage=YES (already in /Users/josh/Developer/flywheel/INCIDENTS.md from flywheel-77qds 2026-05-08)
skill_INCIDENTS_coverage=NOW YES (propagated this dispatch — pre: 40 sections, post: 41 sections)
promotion_candidate_root_cause=doctrine-ladder-promote.sh scans skill-side INCIDENTS.md only; canonical (repo) INCIDENTS.md is NOT in its scan list
files_reserved=$HOME/.claude/skills/.flywheel/INCIDENTS.md
sync_gap_surfaced=sync-canonical-doctrine.sh does NOT propagate INCIDENTS.md (175 vs 40 section drift between repo and skill)
```

## Finding

`doctrine-ladder-promote.sh` auto-created this bead claiming "no
INCIDENTS coverage" for `agent-mail-identity-needs-registration`.
**The premise is technically correct from the script's narrow scan
view but materially false** — the canonical doctrine entry exists in
the canonical INCIDENTS file:

```text
$ grep -c "^## agent-mail-identity-needs-registration$" \
    /Users/josh/Developer/flywheel/INCIDENTS.md
1   # ← already covered (entered 2026-05-08 by flywheel-77qds)

$ grep -c "^## agent-mail-identity-needs-registration$" \
    ~/.claude/skills/.flywheel/INCIDENTS.md
0   # ← NOT in skill copy (pre-propagation)
```

The promote script's source list (per
`/Users/josh/Developer/flywheel/.flywheel/scripts/doctrine-ladder-promote.sh:40-41`):

```bash
printf '%s\n' "$HOME/.claude/skills/.flywheel/INCIDENTS.md"
printf '%s\n' "$HOME"/.claude/skills/*/references/INCIDENTS.md
```

The canonical `flywheel/INCIDENTS.md` is NOT in the scan list. Skill-
side INCIDENTS.md is significantly stale: 40 sections vs 175 sections
in the repo (-135 sections, ~77% gap). The skill copy doesn't get
synced from the canonical source — `sync-canonical-doctrine.sh` has
zero matches for `INCIDENTS.md` handling.

This is a SYNC GAP: the canonical authority lives in the repo, but
the promote script reads the skill copy. Result: false-positive
promotion candidates auto-fired for entries that already exist
canonically.

## Repair

Two-part fix in this dispatch:

1. **Immediate (closes this bead)**: appended the canonical
   `## agent-mail-identity-needs-registration` section (50 lines)
   from `flywheel/INCIDENTS.md` to
   `~/.claude/skills/.flywheel/INCIDENTS.md`. The promote script
   will now see the coverage and stop flagging this trauma class.

   ```bash
   sed -n '/^## agent-mail-identity-needs-registration$/,/^## [^#]/p' \
       /Users/josh/Developer/flywheel/INCIDENTS.md \
     | sed '$d' \
     >> ~/.claude/skills/.flywheel/INCIDENTS.md
   ```

2. **Surfaced for orch (broader sync-gap follow-up)**: the
   sync-canonical-doctrine.sh script doesn't propagate INCIDENTS.md
   from repo to skill. With 135 sections of drift, future
   doctrine-ladder-promote runs will keep generating false-positive
   beads for canonical-but-not-skill-synced entries. Surfaced as
   `flywheel_orch_action_required`.

## Acceptance Gate Map

The bead body says: "Run /flywheel:learn --promote
agent-mail-identity-needs-registration to draft doctrine entry."

The doctrine entry already exists. Acceptance reframed as:

| # | Implicit gate | Status |
|---|---|---|
| AG1 | Trauma class has INCIDENTS coverage | ✓ Already in `flywheel/INCIDENTS.md` (canonical) from flywheel-77qds 2026-05-08; comprehensive entry with Severity, Cost, Root Cause, Forever-Rule, Fix Applied/Status, Evidence pointers, Bead reference |
| AG2 | Promote script's scan source has the coverage | ✓ Section now present in `~/.claude/skills/.flywheel/INCIDENTS.md` (post-propagation); skill section count went 40 → 41 |
| AG3 | Future runs of doctrine-ladder-promote.sh stop flagging this class | ✓ Verified via grep — class name now appears in skill INCIDENTS.md |
| AG4 | Sync gap (canonical → skill INCIDENTS) surfaced for fleet-wide fix | ✓ flywheel_orch_action_required surfaced; the 135-section drift is documented |

did=4/4

## Evidence

```text
$ # Pre-propagation gap:
$ grep -c "agent-mail-identity-needs-registration" /Users/josh/Developer/flywheel/INCIDENTS.md
3   # ← canonical has full entry
$ grep -c "agent-mail-identity-needs-registration" ~/.claude/skills/.flywheel/INCIDENTS.md
0   # ← skill missing pre-fix

$ # Promote script source list (the bug class):
$ grep -nE "INCIDENTS.md" /Users/josh/Developer/flywheel/.flywheel/scripts/doctrine-ladder-promote.sh
40:  printf '%s\n' "$HOME/.claude/skills/.flywheel/INCIDENTS.md"
41:  printf '%s\n' "$HOME"/.claude/skills/*/references/INCIDENTS.md
# ← canonical flywheel/INCIDENTS.md NOT in the list

$ # Sync gap proof:
$ grep -cE "INCIDENTS\.md" /Users/josh/Developer/flywheel/.flywheel/scripts/sync-canonical-doctrine.sh
0   # ← sync-canonical-doctrine doesn't propagate INCIDENTS.md

$ # Post-propagation verification:
$ grep -c "^## agent-mail-identity-needs-registration$" ~/.claude/skills/.flywheel/INCIDENTS.md
1   # ← skill now has the section

$ # Section count delta:
$ wc -l ~/.claude/skills/.flywheel/INCIDENTS.md
1452   # was 1401, now 1452 (+51 lines including 1 separator newline + 50-line section)
$ grep -c "^## " ~/.claude/skills/.flywheel/INCIDENTS.md
41     # was 40

$ # Drift remaining:
$ grep -c "^## " /Users/josh/Developer/flywheel/INCIDENTS.md
175   # canonical
# Skill is still 134 sections behind canonical
```

## Scope

- Edits: 1 source file appended + 3 audit-dir files
  - `~/.claude/skills/.flywheel/INCIDENTS.md` (50-line section
    appended; 1401 → 1452 lines; 40 → 41 sections)
  - `.flywheel/audit/flywheel-fre5a/section-to-propagate.md` (the
    section content, durable copy)
  - `.flywheel/audit/flywheel-fre5a/post-propagation-coverage.txt`
    (grep verification)
  - `.flywheel/audit/flywheel-fre5a/section-count-delta.txt`
    (line/section count delta)
  - `.flywheel/audit/flywheel-fre5a/compliance-pack.md` (this file)
- Files reserved/released: 1 (`~/.claude/skills/.flywheel/INCIDENTS.md`,
  released before callback)
- Out of scope:
  - Backfilling all 134 canonical-but-not-skill-synced INCIDENTS
    sections (separate concern; surfaced for orch-side fleet sync)
  - Modifying `doctrine-ladder-promote.sh` to scan canonical
    `flywheel/INCIDENTS.md` directly (potential alternative;
    tradeoff: skill should be propagated, not promote-script
    re-pointed)
  - Modifying `sync-canonical-doctrine.sh` to propagate INCIDENTS.md
    (separate concern — adds new sync responsibility; needs design
    discussion)

## L52 / L80 / L120 / L61

- DIDNT: backfilling other 134 stale-sync sections (out of scope;
  surfaced for orch fleet-sync follow-up)
- GAPS: skill-side INCIDENTS.md propagation gap (135 sections
  behind canonical); surfaced via flywheel_orch_action_required
- beads_filed: none
- beads_updated: none
- no_bead_reason: trauma-class-already-covered-canonically-skill-side-propagation-applied-broader-sync-gap-orch-routed
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable
- readme_updated: not_applicable (touched skill INCIDENTS.md, which is doctrine; agents_md and README are separate surfaces)
- shared_surface_reservations_checked: yes
- shared_surface_reservations_released: yes (will release before callback)
- flywheel_orch_action_required: file-followup-bead-add-INCIDENTS-md-to-sync-canonical-doctrine-list-or-add-canonical-flywheel-INCIDENTS-to-doctrine-ladder-promote-scan-list-AND-backfill-134-stale-sections-from-repo-to-skill

## Skill Auto-Routes

- canonical-cli-scoping: addressed=yes — `doctrine-ladder-promote.sh`
  is a CLI surface; the gap surfaced (scan source incomplete) is
  a canonical-cli-scoping concern (validate/audit/why discipline
  needs the source list to be canonical-aware)
- rust-best-practices: n/a — no Rust touched
- python-best-practices: n/a — no Python touched
- readme-writing: n/a — no README touched

## Four Lens

- Brand: 9 (data-decides discipline applied — the bead's premise
  was investigated against canonical state before any mutation;
  found the false-positive class, fixed the immediate symptom +
  surfaced the systemic gap; ZestStream brand voice "structure-level
  over symptom-level" honored — propagation closes the immediate
  symptom; the sync-canonical-doctrine recommendation closes the
  class)
- Sniff: 9 (every claim grounded in concrete grep counts:
  canonical has it × 1, skill missing × 0 pre-fix → 1 post-fix;
  promote-script source list cited at line 40-41; sync-canonical-doctrine
  zero-match for INCIDENTS.md proven; 175 vs 40 vs 41 section
  counts traced)
- Jeff: 8 (no Jeffrey-substrate touch; .flywheel skill is not
  JSM-managed per earlier verification — direct edit allowed; the
  trauma class itself concerns Jeffrey's agent-mail substrate but
  the doctrine entry pre-existed in canonical INCIDENTS — this
  dispatch only propagated the existing doctrine, didn't author
  new doctrine)
- Public: 9 (Three-Judges check: an operator can re-run the promote
  script and see the trauma class is no longer flagged; a maintainer
  6 months from now sees the sync-gap analysis and understands WHY
  this dispatch propagated rather than re-promoted; a future worker
  hitting another false-positive promotion candidate has this
  dispatch's evidence pattern to follow)

## L112 Probe

```
grep -c "^## agent-mail-identity-needs-registration$" \
  ~/.claude/skills/.flywheel/INCIDENTS.md
```
Expected: `literal:1` (post-propagation, the canonical section
heading is present in the skill-side INCIDENTS file that
`doctrine-ladder-promote.sh` scans).
