# Evidence: flywheel-2xdi.51 — stale bead resolved by upstream probe fixes

**Bead**: flywheel-2xdi.51 (P3) | **Task ID**: flywheel-2xdi.51-28044d | **Identity**: MistyCliff
**Flagged**: `~/.claude/skills/.flywheel/scripts/substrate-doctor-critical-gaps-test.sh`
**Filed**: 2026-05-11T06:02:04Z

## Disposition: STALE — already resolved when bead was processed

This bead was auto-filed by gap-hunt-probe at 06:02Z. Between filing and this dispatch, I shipped two probe fixes:

- **flywheel-2xdi.47** (commit 69a0680): for-loop indirect-source corpus extension
- **flywheel-2xdi.49** (commit 1045e6e): SKILL.md documentation corpus (4th corpus)

Current state: live probe reports the script as NOT cold.

```json
{
  "total_gaps": ...,
  "wired_but_cold": 0,
  "matches": []
}
```

## Why no longer flagged

The script is legitimately wired:
- Documented in `~/.claude/skills/.flywheel/scripts/substrate-doctor-common.README.md` as the canonical fixture-test invocation path (with copy-pasteable bash block)
- Documented in `~/.claude/skills/.flywheel/INCIDENTS.md` as the verification surface for the substrate-doctor critical-gaps incident (cf-access empty-IDP class)

The script's name (`substrate-doctor-critical-gaps-test`) appears in the `recent_ledger_text` corpus via `gap-hunt.jsonl` (where 2xdi.51 was logged when filed) and `fuckup-log.jsonl`. That's enough for the probe's existing match logic to see it as warm — though it's worth noting this is a *self-referential evidence path* (the probe filing the bead created the ledger row that now makes it appear warm).

## Acceptance

Bead asked to address wired-but-cold gap. Current probe state already satisfies the implicit goal (gap closed). No script-side change needed; no probe-side change needed (2xdi.47 + .49 already shipped + the ledger self-reference exists).

## Follow-up signal (out-of-scope for this bead)

The script's GENUINE wiring is in `*.README.md` + `INCIDENTS.md` documentation files. My 2xdi.49 fix added a SKILL.md corpus but NOT a broader README/INCIDENTS corpus. The probe currently relies on self-referential ledger rows to see this script as warm, which is fragile.

**Recommended follow-up bead** (file as `gap-hunt-probe-extend-doc-corpus`):

Extend the probe's `skill_md_corpus()` (or add a sibling `doc_corpus()`) to also scan:
- `*.README.md` files at canonical paths (per-script + per-skill)
- `INCIDENTS.md` files (already a canonical documentation surface)
- Potentially `AGENTS.md` and `AGENTS-CANONICAL.md`

Same Meadows #5 shape as 2xdi.49 — broaden the documentation-as-wiring corpus rather than adding per-script registry entries.

This is a 4th application of the META-rule lineage `feedback_bead_hypothesis_starting_point_not_conclusion`:
1. o40x0: race → canonicalization mismatch
2. 2xdi.47: dead code → for-loop indirect-source blind spot
3. 2xdi.49: dead code → SKILL.md documentation blind spot
4. 2xdi.51: this bead (would have been dead code → README/INCIDENTS documentation blind spot, but the probe self-reference catches it incidentally)

## L112 verify probe

`bash -c '.flywheel/scripts/gap-hunt-probe.sh --json --dry-run 2>/dev/null | jq -r ".gaps // [] | map(select(.where | test(\"substrate-doctor-critical-gaps-test\"))) | length"'`
Expected: `grep:^0$`
