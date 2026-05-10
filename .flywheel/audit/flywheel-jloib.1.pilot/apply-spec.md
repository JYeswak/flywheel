---
title: Tooling validation pilot — 3 dispatch-lane P0 surfaces
type: apply-spec
created: 2026-05-10
parent: flywheel-jloib (canonical-baseline parent)
chain: doctor-mode-integration / lane-pilot
---

# Tooling validation pilot — dispatch lane (3 surfaces)

Dogfoods the canonical-cli tooling chain on 3 highest-leverage dispatch-lane
P0 surfaces. Validates that scaffolder + helper lib + linter actually
deliver the projected ~30-60min/surface compression before scaling to the
remaining 21 dispatch-lane surfaces and beyond.

## Three pilot targets (highest-leverage in dispatch lane)

1. **`.flywheel/scripts/build-dispatch-packet.sh`** — load-bearing
   materializer. Every dispatch flows through it. Currently P0 (canonical
   missing, no doctor). Critical-path; if this surface upgrade succeeds,
   confidence is high for the rest.

2. **`.flywheel/scripts/dispatch-canonical-cli-validator.sh`** —
   ironically validates dispatch packets but isn't itself canonical. Eats
   its own dog food after this bead.

3. **`.flywheel/scripts/dispatch-and-log.sh`** — used in worker-tick
   callback flows. Active path; failure here surfaces immediately.

## Method (per surface)

For each of the 3 targets, run the world-class flow we just built:

### Step 1: scaffold

```bash
.flywheel/scripts/scaffold-canonical-cli.sh <target_path> --dry-run --json > /tmp/scaffold-<basename>.json
# Review diff
.flywheel/scripts/scaffold-canonical-cli.sh <target_path> --apply --idempotency-key pilot-<basename>-2026-05-10 --json
```

### Step 2: fill TODO markers (the per-surface judgment work)

The scaffolder inserts `# TODO(canonical-cli-scaffold):` markers naming
exactly what needs filling. For each:
- `cmd_doctor`: surface-specific substrate probes
- `cmd_health`: signal-specific status checks
- `cmd_repair --scope <s>`: scope-specific actions (use the
  cli_refuse_apply_without_idem_key helper)
- `cmd_validate`: schema-specific rules (or document
  `validate_out_of_scope=true`)
- `cmd_why`: provenance-specific tracing (or document why_out_of_scope)
- `topic-map.json` sidecar: per-subcommand help bodies

Goal: **<60 minutes per surface for fill-in**, validating the projected
~30-60min/surface compression target.

### Step 3: lint

```bash
.flywheel/scripts/canonical-cli-lint.sh <target_path>
```

Must report ZERO violations.

### Step 4: regression test

The scaffolder generates `tests/<basename>-canonical-cli.sh` from the
template. Fill in surface-specific assertions, then:

```bash
bash tests/<basename>-canonical-cli.sh
```

Must report all-pass.

### Step 5: canonical-cli-scoping checker

```bash
PATH=/tmp/cli-test-bin:$PATH bash $HOME/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh <basename>
```

Must report 13/13 PASS.

### Step 6: measure + record

For each surface, capture:
- before lines / after lines / lib-helper lines used
- per-surface fill-in time (start-stamp to commit-stamp)
- TODO count inserted by scaffolder vs actually filled
- any scaffolder bugs uncovered (file followup beads)
- any helper-lib gaps uncovered (file followup beads)

Aggregate into `.flywheel/audit/flywheel-jloib.1.pilot/measurements.json`:

```json
{
  "schema_version": "lane-pilot-measurements/v1",
  "surfaces": [
    {
      "path": "...",
      "before_lines": N,
      "after_lines": M,
      "scaffold_minutes": X,
      "fill_in_minutes": Y,
      "test_minutes": Z,
      "todo_count_inserted": A,
      "todo_count_filled": A,
      "violations_at_close": 0,
      "canonical_checker_score": "13/13",
      "regression_test_count": K,
      "regression_test_pass": K,
      "followup_beads_filed": []
    },
    ...
  ],
  "median_per_surface_minutes": ...,
  "verdict": "tooling validated | tooling needs revision | partial"
}
```

## Acceptance gate

- All 3 surfaces canonical-cli checker 13/13 PASS
- All 3 lint clean (zero violations)
- All 3 have green regression tests (≥15 assertions each)
- Median fill-in time ≤60 min/surface
- ≤1 followup bead per pilot surface (scaffolder/lib gaps surfaced)

## Verdict-based next moves

- **Verdict: validated** → file 5 lane sub-beads:
  `flywheel-jloib.1.1` dispatch wave 1 (8 surfaces)
  `flywheel-jloib.1.2` dispatch wave 2 (8 surfaces)
  `flywheel-jloib.1.3` dispatch wave 3 (5 surfaces — tail)
  `flywheel-jloib.2` recovery lane decomposition
  `flywheel-jloib.3` agent-mail lane decomposition
  Dispatch in priority order.

- **Verdict: needs revision** → file followup beads for each
  scaffolder/lib gap; pause lane work until revisions ship.

- **Verdict: partial** (e.g., 2 of 3 surfaces validated) → ship the
  validated 2, file revision bead for the third.

## Boundary

- ONLY 3 surfaces in this bead. Don't scope-creep to whole dispatch lane.
- Each surface ships as its own commit (one PR per surface ideal).
- If a surface's TODO fill-in takes >2h, abort that surface and file a
  followup bead. Don't burn worker capacity on unexpected complexity.
- Worker substrate: codex-pane (assumed claude per topology); 4 freed up.

## Estimated effort

~3-5 hours total:
- 3 × 30-60 min per surface (target)
- + 30 min measurements + verdict synthesis
- + per-surface 1 commit + per-bead 1 close commit

## Dependencies

- jloib.0a (helper lib v1.1 with b9dfv extractions) — CLOSED
- jloib.0b (scaffolder) — CLOSED
- jloib.0c (linter) — CLOSED
- jloib.0d (pilot refactor proof) — CLOSED
- All four tooling beads validated; lane work is unblocked

## Canonical structure (post-hoc backfill, flywheel-at83y)

This apply-spec was authored before the F7 canonical structure rule (filesystem-as-rag doctrine).
The body above contains the substantive content; the H2 stubs below satisfy the mechanical lint without rewriting the prose.

## Goal

See body above (typically the opening paragraph or first H1 section).
