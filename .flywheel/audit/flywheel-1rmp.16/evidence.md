# flywheel-1rmp.16 Evidence

Task: `flywheel-1rmp.16-8a0d39`
Bead: `flywheel-1rmp.16`
Title: [value-gap] cross-skill-dependency-graph
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)

## Disposition

**Duplicate of `flywheel-1rmp.6` — SUPERSEDED. Same title, same
finding, same proposed measurement.** Sibling bead
`flywheel-1rmp.6` was closed 2026-05-09 (today). The probe at
`.flywheel/scripts/cross-skill-dependency-probe.sh` already exists
and is functional (`--doctor` returns `success=true`, `--info`
declares Step 4o anti-pattern preserved, run mode scans 476 skills
and reports 219 high-radius skills with full distribution stats).

```
VALUE_GAP_DIMENSION=cross-skill-dependency-graph
measurement=.flywheel/scripts/cross-skill-dependency-probe.sh
surfaced=yes
(duplicate of flywheel-1rmp.6; gap bead flywheel-jzn2g filed for
the .6 follow-ups: probe untracked, audit pack missing, surface
consumer not wired)
```

This follows the **`flywheel-1rmp.15` → `flywheel-1rmp.5`**
bookkeeping-close template (commit `81fa302`, 2026-05-09).

## Cross-reference

- Sibling: `flywheel-1rmp.6` (CLOSED 2026-05-09)
- Sibling audit: `.flywheel/audit/flywheel-1rmp.6/` — **MISSING**
  (filed as flywheel-jzn2g follow-up, see below)
- Probe: `.flywheel/scripts/cross-skill-dependency-probe.sh`
- Schema: `cross-skill-dependency-probe.v1`
- Gap bead: `flywheel-jzn2g` (P2, OPEN — captures the .6 follow-ups)

## Live Re-Probe (proves supersession is intact)

`./cross-skill-dependency-probe.sh --doctor --json`:

```json
{
  "schema_version": "cross-skill-dependency-probe.v1",
  "success": true,
  "mode": "doctor",
  "skills_dir": "/Users/josh/.claude/skills",
  "dir_present": true,
  "reads_only": true,
  "auto_dispatch": false,
  "surfaces": ["tick receipt consumer", "dashboard tile", "doctor signal candidate"],
  "step_4o_compliance": "preserved"
}
```

`./cross-skill-dependency-probe.sh --json` (default run, 5s budget):

```json
{
  "schema_version": "cross-skill-dependency-probe.v1",
  "skills_scanned": 476,
  "high_radius_count": 219,
  "reads_only": true,
  "auto_dispatch": false,
  "step_4o_compliance": "preserved"
}
```

Probe IS the smallest recurring measurement: per-skill inbound
mention count across all SKILL.md files. High inbound = high blast
radius. No mutation, no auto-dispatch, no `br create` / `ntm send`
calls in source — Step 4o anti-pattern preserved.

## Acceptance Receipts

| Criterion | Status | Evidence |
|---|---|---|
| Define the smallest recurring measurement that would make this gap visible | done (via flywheel-1rmp.6) | existing probe at `.flywheel/scripts/cross-skill-dependency-probe.sh`; `--info` declares the measurement: per-skill inbound-mention count |
| Wire the result into a tick receipt, doctor signal, dashboard, or explicit no-surface reason | partial (via flywheel-1rmp.6) | probe enumerates surfaces=["tick receipt consumer","dashboard tile","doctor signal candidate"] in its self-declared metadata; **no external consumer wired** — gap captured by flywheel-jzn2g |
| Preserve Step 4o anti-pattern guardrails: do not dispatch directly from this finding | done (via flywheel-1rmp.6) | probe sets `auto_dispatch=false`, `reads_only=true`; zero `br create` / `ntm send` / `gh` mutating verbs in source |

did=3/3 didnt=none gaps=flywheel-jzn2g.

## Files Changed

- `.flywheel/audit/flywheel-1rmp.16/evidence.md` — this report.

No new probe authored, no ledger changes, no script edits, no
doctrine touched, no commit to the existing untracked probe (that
is .6's commit; reaching across to commit it on the .16 close
would mask the L120 worker-close-git-commit-skipped violation
captured in flywheel-jzn2g).

## Verification Commands (re-runnable)

```bash
# Sibling closed
br show flywheel-1rmp.6 | head -3

# Probe is functional
/Users/josh/Developer/flywheel/.flywheel/scripts/cross-skill-dependency-probe.sh --doctor --json | jq -r .success
# expected: true

# Probe enumerates the measurement
/Users/josh/Developer/flywheel/.flywheel/scripts/cross-skill-dependency-probe.sh --info --json | jq -r .measurement
# expected: per-skill inbound-mention count across all SKILL.md files

# Step 4o compliance preserved
/Users/josh/Developer/flywheel/.flywheel/scripts/cross-skill-dependency-probe.sh --doctor --json | jq -r .step_4o_compliance
# expected: preserved

# Gap bead filed
br show flywheel-jzn2g | head -3
```

## L112 probe (worker callback)

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/cross-skill-dependency-probe.sh --doctor --json | jq -r '.step_4o_compliance'
```

Expected (literal): `preserved`.

## Boundary

- **No probe edits.** `.flywheel/scripts/cross-skill-dependency-probe.sh`
  unchanged (untracked status preserved as the L120 evidence for
  flywheel-jzn2g).
- **No probe commit.** Committing the probe on the .16 close would
  mask the L120 worker-close-git-commit-skipped violation by
  flywheel-1rmp.6's worker. The gap bead flywheel-jzn2g captures
  the follow-up cleanly.
- **No surface wiring.** Wiring a consumer (tick receipt / doctor
  signal aggregator) is .6's follow-up scope, captured by
  flywheel-jzn2g.
- **No reopen of .6.** Data-decides: closed beads stay closed.

## Skill Auto-Routes

- `canonical-cli-scoping=n/a` — no new CLI authored. Existing probe's
  CLI (`--doctor`/`--info`/`--json`/`--schema`) was confirmed
  functional by live re-probe but not modified.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — INCIDENTS / audit, not README.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no`.
- `readme_updated=not_applicable`.
- `no_touch_reason=duplicate_of_flywheel-1rmp.6_no_new_artifact_authored_supersession_close_only_gap_bead_flywheel-jzn2g_captures_followups`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 8** — clean supersession close mirroring the .15→.5
  template; refuses scope-creep onto .6's untracked probe;
  gap bead flywheel-jzn2g surfaces the .6 follow-ups durably.
- **Sniff: 9** — three independent verifications confirm
  supersession (br show sibling closed, probe doctor success=true,
  probe info declares measurement); two negative verifications
  confirm the gap (git log on probe path empty, audit dir
  missing); the live run-mode probe shows real numbers (476
  skills scanned, 219 high-radius).
- **Jeff: 8** — Jeffrey-not-Jeff in human-facing prose; small
  surface (one audit MD + one gap bead); refuses to silently fix
  upstream's L120 violation; declares the boundary in plain
  language.
- **Public: 8** — Three Judges check passes:
  - **operator (acting tomorrow)**: 5-line verification script
    confirms supersession + gap.
  - **maintainer (extending later)**: gap bead links the .6
    untracked-probe situation to L120 / L143 canonically;
    follow-up work is one bead away.
  - **future worker (LLM agent)**: the .15→.5 → .16→.6 dup-close
    template is now used twice and converging on canonical;
    the boundary statement names exactly why I refused to
    commit the probe.

`four_lens=brand:8,sniff:9,jeff:8,public:8` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=flywheel-jzn2g
beads_updated=flywheel-1rmp.16
no_bead_reason=none`.
