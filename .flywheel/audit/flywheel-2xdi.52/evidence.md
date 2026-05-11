# Evidence: flywheel-2xdi.52 — stale wired-but-cold bead resolved by upstream probe fixes

**Bead**: flywheel-2xdi.52 (P3) | **Task ID**: flywheel-2xdi.52-1d6e94 | **Identity**: MistyCliff
**Flagged**: `~/.claude/skills/.flywheel/scripts/substrate-doctor-infisical-test.sh`
**Filed**: 2026-05-11T06:02Z (same batch as 2xdi.51)

## Disposition: STALE — already resolved when bead was processed

Filed in the same 06:02Z auto-batch as 2xdi.51. By processing time:
- flywheel-2xdi.47 (commit 69a0680): for-loop indirect-source corpus fix shipped
- flywheel-2xdi.49 (commit 1045e6e): SKILL.md documentation corpus fix shipped

Current probe state:
```json
{"total_gaps": 0, "wired_but_cold": 0, "matches_infisical": []}
```

## Why no longer flagged

The script is referenced in `~/.claude/skills/.flywheel/INCIDENTS.md` — the substrate-doctor-infisical-test fixture is the canonical verification surface for the infisical-substrate-doctor incidents. Same shape as 2xdi.51's `substrate-doctor-critical-gaps-test.sh`: documented in INCIDENTS.md, caught by `recent_ledger_text` corpus via self-referential ledger row.

The deeper fix (extend probe to scan `*.README.md` + `INCIDENTS.md` directly, not just self-referential ledger rows) is the same follow-up captured in 2xdi.51 evidence — same META-rule lineage.

## Acceptance

Bead asked to address wired-but-cold gap. Current probe state already satisfies the implicit goal. No script-side or probe-side change needed.

This is the **5th instance** of the `bead-hypothesis-is-prior-not-posterior` META-rule lineage this session:
1. o40x0: race → canonicalization mismatch (fix shipped)
2. 2xdi.47: dead code → for-loop indirect-source blind spot (fix shipped)
3. 2xdi.49: dead code → SKILL.md documentation blind spot (fix shipped)
4. 2xdi.51: stale by the time processed (resolved upstream by 2xdi.47 + .49)
5. 2xdi.52: this bead — stale, identical shape to 2xdi.51

The fact that 2xdi.51 and 2xdi.52 BOTH arrived from the same 06:02Z auto-batch + BOTH are already resolved is convergent evidence that the auto-bead-filer should suppress wired-but-cold beads when the next probe pass shows the gap closed.

## Follow-up signals captured (out-of-scope here)

Same two follow-ups as 2xdi.51:
1. **Extend probe docs-as-wiring corpus** to include `*.README.md` + `INCIDENTS.md` (beyond just `SKILL.md`)
2. **Self-referential evidence loop**: probe-filed beads write ledger rows that the next probe sees as evidence. Suppress probe's own gap-hunt.jsonl from `recent_ledger_text` corpus.

PLUS new signal from this bead:

3. **Stale-bead suppression**: auto-bead filer should be one-shot per gap-id — if the previous filing closed the gap (whether by fix or by the gap dissolving), skip re-filing. Currently 2xdi.51 + 2xdi.52 were filed in the same batch even though the underlying probe semantics drift between filing-time and processing-time.

## L112 verify probe

`bash -c '.flywheel/scripts/gap-hunt-probe.sh --json --dry-run 2>/dev/null | jq -r ".gaps // [] | map(select(.where | test(\"substrate-doctor-infisical\"))) | length"'`
Expected: `grep:^0$`
