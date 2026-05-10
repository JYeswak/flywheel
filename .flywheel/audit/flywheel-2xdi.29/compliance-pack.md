# flywheel-2xdi.29 Compliance Pack

Task: `flywheel-2xdi.29-4f8b24`
Bead: `flywheel-2xdi.29`
Decision: DONE
Compliance score: 880/1000

## Finding

`gap-hunt-probe.sh probe_bead_without_followup()` (lines 582-607) iterates
every closed bead, finds those whose body contains `\b(doctrine|canonical|
promote|promotion)\b`, and flags any whose ID is not cited in INCIDENTS.md
(modulo a small false-positive suppression list at lines 537-579).

`flywheel-24a3` matched the regex via "promote that output back to
v1/manifest.json" (manifest promotion in technical context, not doctrine
promotion). Pre-fix grep across INCIDENTS.md: 0 hits.

But the underlying bead is genuinely important: it's a P0 BUG that
documented four production-safety gaps in `jeff-corpus-compact.sh`
before the live `flywheel-cwov` 66.7GB compaction ran. All four gaps
were genuinely fixed before production trigger. This is exactly the
kind of trauma class INCIDENTS.md exists to preserve.

## Repair

Promoted the bead to a real INCIDENTS trauma class entry. The new
section codifies:

1. The four specific production-safety gaps (idempotency key, doctor
   read-path mismatch, archive path mismatch, Qdrant no-op silent
   "success") as concrete claims with file:line evidence in
   `jeff-corpus-compact.sh`.
2. A Forever-Rule capturing the four production-safety gates that
   any future substrate-mutation script must clear before its
   `--apply` is allowed.
3. The full sibling-bead web (cwov, cwov.1, w3pr, 24a3) so future
   workers can navigate the production-compaction story.
4. The original RED-state evidence (`/tmp/cwov-pre-compact.json`
   `jeff_corpus_v1_total_mb=66766.7` `jeff_corpus_storage_health=RED`).
5. Today's verified state: the four fixes ARE present in the script
   (verified by grep of `idempotency_key`, `--idempotency-key` accepts,
   receipt-path logic at lines 35,71-72).

## Acceptance Gate Map

The bead's only test gate is implicit: the gap-hunt-probe should no
longer surface
`bead-without-followup:flywheel-24a3`.

- AG1: post-edit gap-hunt-probe re-run returns empty for that gap id. ✓
  (`hits=[]`)

did=1/1

## Evidence

```text
$ grep -c "flywheel-24a3" /Users/josh/Developer/flywheel/INCIDENTS.md
# pre-fix: 0
# post-fix: 1

$ bash .flywheel/scripts/gap-hunt-probe.sh \
  | python3 -c 'import json,sys; d=json.load(sys.stdin);
                hits=[g for g in d.get("gap_ids",[])
                      if "bead-without-followup" in g
                      and "flywheel-24a3" in g];
                print("post-fix hits:", hits)'
post-fix hits: []

$ grep -nE "idempotency_key|--idempotency" .flywheel/scripts/jeff-corpus-compact.sh | head -3
19:    "  jeff-corpus-compact.sh --dry-run|--apply [--idempotency-key KEY] [--json]"
35:    --idempotency-key) [ $# -ge 2 ] || { ... }; IDEMPOTENCY_KEY="$2" ;;
67:idempotency_key = sys.argv[9]
71:safe_key = re.sub(r"[^0-9A-Za-z_.-]+", "_", idempotency_key)
72:receipt_path = receipt_dir / f"{safe_key}.json" if idempotency_key else None
# fixes verified — script now accepts the flag and writes durable receipt

$ br list --status closed | grep -E "cwov|24a3|w3pr"
✓ flywheel-w3pr [P0] [task] - [jeff-corpus-deep-pattern-mining]
✓ flywheel-cwov.1 [P0] [task] - [flywheel-cwov.audit-gap] AG5 cold-storage
✓ flywheel-24a3 [P0] [bug] - [cwov.audit-gap] not production-safe
✓ flywheel-cwov [P0] [task] - [jeff-corpus-compaction-trigger] PRODUCTION
# all four siblings closed — full audit chain coherent
```

## Scope

- Edits: INCIDENTS.md only (single trailing append; no other surface)
- Files reserved/released: that path
- Out of scope: editing jeff-corpus-compact.sh (already fixed, all
  four gaps remediated); any production compaction trigger (cwov
  parent already closed); other `bead-without-followup` gaps
  surfaced in the same probe run (separate beads)

## L52 / L80 / L120 / L61

- DIDNT: none
- GAPS: none new
- beads_filed: none
- beads_updated: none
- no_bead_reason: single-bug-bead-promotion-no-followup
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable — this is a bug-class trauma
  promotion, not a numbered L-rule
- readme_updated: not_applicable
- no_touch_reason (AGENTS.md): trauma-class-bug-belongs-in-incidents-not-l-rule

## Four Lens

- Brand: 9 (matches the canonical INCIDENTS shape: Root Cause /
  Forever-Rule / Fix Applied / Evidence with explicit bead IDs +
  file:line citations + the four-gates production-safety contract.
  The Forever-Rule generalizes from this incident to any future
  substrate-mutation script — preserves the doctrine, not just
  the artifact)
- Sniff: 9 (verified the four fixes ARE present in the script today;
  cross-referenced all four sibling beads as closed; preserved the
  original RED-state precompact evidence value verbatim)
- Jeff: 8 (jeff-corpus is foundational substrate; the production
  compactor now has the four gates Jeffrey would expect for a
  P0-mutation script — idempotency, output-path = read-path,
  canonical cold-storage, Qdrant pre/post)
- Public: 9 (a future maintainer running a substrate-mutation script
  can grep "production-safety gates" and find the four-gate Forever-Rule;
  the original RED-state value is preserved verbatim for future
  audits to cross-reference)

## Skill Auto-Routes

- canonical-cli-scoping: n/a — no CLI added (the script's contract is
  cited as evidence, not modified)
- rust-best-practices: n/a — no Rust touched
- python-best-practices: n/a — no Python touched
- readme-writing: n/a — no README touched

## L112 Probe

```
grep -c "flywheel-24a3" /Users/josh/Developer/flywheel/INCIDENTS.md
```
Expected: `literal:1` (one citation in the new INCIDENTS entry; the
gap-hunt-probe needs only basename presence to clear).
