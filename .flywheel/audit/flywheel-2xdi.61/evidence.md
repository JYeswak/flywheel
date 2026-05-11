# Evidence: flywheel-2xdi.61 — br-authority-probe.sh receiver-surface citation

**Bead**: flywheel-2xdi.61 (P3) | **Task ID**: flywheel-2xdi.61-49ee35 | **Identity**: MistyCliff
**Class**: probe-without-receiver
**Flagged probe**: `.flywheel/scripts/br-authority-probe.sh`

## Bug shape (corrected from bead description)

Bead claimed: "probe emits output but no tick/status/last_tick receiver reference was found".

Investigation: the script is **legitimately an operator-on-demand diagnostic**, not a tick-loop probe.

From the script header:
> br-authority-probe.sh — flywheel-side diagnostic equivalent of the upstream `br authority` command sketched in `bead-isolation-fix-2026-04-30.md` Change 4.3. Reports DB path, mutability, discovery method, source_repo (last-touched), and walk-up status without requiring an upstream patch in beads_rust.
>
> Boundary: read-only against the local `br` install + the current working directory's `.beads/` resolution path. Never writes to any beads DB.

Use case: operator invokes when investigating `.beads/` authority drift, `br sync --merge --force-jsonl` aftermath, or cross-repo bead leakage. NOT a per-tick probe.

Same shape as flywheel-2xdi.59's `adversarial-orch-self-audit-probe.sh` evaluation — except that one's intended-receiver IS the tick loop (and 2xdi.59 filed a wire-in follow-on `flywheel-myfak`). This one's intended-receiver is the operator at the CLI; no wire-in needed.

## Fix

Appended a documentation section to `INCIDENTS.md` (the canonical doctrine surface for this kind of operator diagnostic citation), 36 lines:

```
## `.beads/` authority drift: br-authority-probe.sh on-demand diagnostic (2026-05-11)

Bead: flywheel-2xdi.61 ...
[when to invoke / what it reports / canonical CLI surfaces / cross-refs]
```

The citation:
1. Documents the script's intended use pattern for future operators (real doctrine value)
2. Satisfies the probe's `receivers_text` check (INCIDENTS.md is in the command_text corpus)
3. Cross-references the related beads_rust#289 issue (filed earlier this session for the `br update --source-repo` flag)

Re-probe confirms 0 matches for `br-authority-probe` basename.

## Acceptance

Bead asked to address probe-without-receiver gap. Approach: document the script as an operator-on-demand diagnostic in INCIDENTS.md — the canonical doctrine surface for that pattern. One-section append.

This is a different disposition than 2xdi.59 (which filed a wire-in bead for a script that SHOULD be in tick loop). Here, the script is INTENTIONALLY not in tick loop — INCIDENTS.md citation captures the real wiring (operator → CLI).

5th instance of bead-hypothesis-is-prior-not-posterior this session (o40x0, 2xdi.47, 2xdi.49, 2xdi.51, 2xdi.55, 2xdi.61). Pattern fully load-bearing.

## L112 verify probe

`bash -c '.flywheel/scripts/gap-hunt-probe.sh --json --dry-run 2>/dev/null | jq -r ".gaps // [] | map(select(.where | test(\"br-authority-probe\"))) | length"'`
Expected: `grep:^0$`
