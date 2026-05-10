# flywheel-2xdi.20 Compliance Pack

Task: `flywheel-2xdi.20-051e76`
Bead: `flywheel-2xdi.20`
Decision: DONE
Compliance score: 870/1000

## Finding

`gap-hunt-probe.sh probe_memory_without_cross_link()`
(`.flywheel/scripts/gap-hunt-probe.sh:498-512`) checks every memory file under
`~/.claude/projects/-Users-josh-Developer-flywheel/memory/*.md` (skipping
MEMORY.md) against six sampled surfaces (`command_text()` at
`.flywheel/scripts/gap-hunt-probe.sh:403-412`):

- `~/.claude/commands/flywheel/tick.md`
- `~/.claude/commands/flywheel/status.md`
- `~/.claude/commands/flywheel/synth.md`
- `<repo>/AGENTS.md`
- `<repo>/INCIDENTS.md`
- `<repo>/README.md`
- plus `<repo>/.flywheel/plans/*.md`

If neither the memory file's basename nor stem appears in any of those, the
probe files a `memory-without-cross-link:<basename>` gap.

`feedback_dcg_redirect_in_bead_body_text.md` is a load-bearing trauma-class
rule (DCG false positive on `>` literals inside `br create --description`).
Pre-fix grep returned 0 mentions across all six surfaces — the rule lived in
memory only, invisible to substrate grep.

## Repair

Promoted the memory-only rule to canonical substrate by appending an INCIDENTS
entry that:

1. Names the trauma class (`DCG redirect-truncate false-positive on > literals
   in bead description prose`).
2. States the Forever-Rule (write body to temp file first, inject via
   `br create --description "$(cat /tmp/bead-body.md)"`).
3. Cites the memory file by full path so the gap-hunter regex finds it.
4. Cites the probe code path (`gap-hunt-probe.sh:498-512`) and the
   `command_text()` source list so future maintainers can audit the
   cross-link contract itself.
5. Names the bead (`flywheel-2xdi.20`) and the trigger phrases for future
   pattern-emerged detection.

## Acceptance Gate Map

The bead body inherits gates from the standard auto-filed gap-hunt
template; the binding success criterion is "memory file is cited by sampled
surfaces". One gate, one proof.

- AG1: gap-hunt-probe re-run shows
  `memory-without-cross-link:feedback_dcg_redirect_in_bead_body_text.md`
  is no longer in `gap_ids`. ✓ (post-fix python `gap_hits=[]`).

## Evidence

```text
$ grep -c "feedback_dcg_redirect_in_bead_body_text" /Users/josh/Developer/flywheel/INCIDENTS.md
# pre-fix: 0
# post-fix: 4

$ bash .flywheel/scripts/gap-hunt-probe.sh \
    | python3 -c "import json,sys; d=json.load(sys.stdin); \
        print([g for g in d.get('gap_ids',[]) \
               if 'memory-without-cross-link' in g \
               and 'feedback_dcg_redirect_in_bead_body_text' in g])"
[]
```

The 4 post-fix mentions in INCIDENTS.md cover (1) the section heading title,
(2) the explicit Memory: bullet, (3) the doctrine prose,
(4) the probe-source citation — overdetermined cross-link is fine; under-
determined would re-fire the gap on minor edits.

## Scope

- Edits: `INCIDENTS.md` only (single trailing append; no other surface
  modified)
- Files reserved/released: that path
- Out of scope: `gap-hunt-probe.sh` itself (the probe is correct; the gap
  was real); promoting the rule to AGENTS.md as a numbered L-rule (this
  is a trauma class with operational guidance, not a load-bearing
  doctrine rule that demands a numbered slot — keeping it in INCIDENTS
  matches the precedent for similar memory-rule cross-links visible in
  the file).

## L52 / L80 / L120 / L61

- DIDNT: none
- GAPS: none new
- beads_filed: none
- beads_updated: none
- no_bead_reason: single-cross-link-promotion-no-followup
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: no — not_applicable; trauma class belongs in
  INCIDENTS, not as a numbered AGENTS L-rule
- readme_updated: not_applicable — operational rule for bead authoring
  scope, not a user-facing README narrative
- no_touch_reason (AGENTS.md): trauma-class-belongs-in-incidents-not-l-rule

## Four Lens

- Brand: 8 (matches the canonical INCIDENTS entry shape — Root Cause /
  Forever-Rule / Fix Applied / Evidence / cited memory path / cited bead;
  the same shape Joshua uses for memory-rule promotions)
- Sniff: 9 (pre/post grep delta + probe re-run + cited line numbers in
  the probe source code; the entry is auditable end-to-end)
- Jeff: 7 (no Jeff-substrate touch; pure flywheel-local doctrine)
- Public: 8 (a future operator hitting the DCG false positive can grep
  "redirect-truncate" or "br create --description" in this repo and find
  the rule + the workaround in one INCIDENTS entry)

## Skill Auto-Routes

- canonical-cli-scoping: n/a — no CLI added
- rust-best-practices: n/a — no Rust touched
- python-best-practices: n/a — gap-hunt-probe.sh is read-only here, not
  modified
- readme-writing: n/a — INCIDENTS prose follows existing entry shape

## L112 Probe

```
grep -c "feedback_dcg_redirect_in_bead_body_text" /Users/josh/Developer/flywheel/INCIDENTS.md
```
Expected: `literal:4` (4 distinct citations in the new INCIDENTS entry).
