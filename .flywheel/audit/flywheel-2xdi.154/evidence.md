# flywheel-2xdi.154 — AUDIT-ONLY (Joshua-domain cluster, non-canonical-skill-shape sub-class)

Bead: flywheel-2xdi.154 (P3)
Class: `gap-wired-but-cold-cluster` (per flywheel-xn5bm cluster-maintainer doctrine)
Target: `~/.claude/skills/.flywheel/scripts/*` (6+ scripts in skillos's flywheel-substrate skill)
Lane: audit-only / joshua-domain-cluster-non-canonical-skill
mutates_state: no

## Probe (META-RULE 2xdi.54 applied)

**Substrate ownership:**
```
$ jsm show .flywheel
Skill '.flywheel' not found.
```

**jsm-UNMANAGED + Joshua-domain** (NOT Jeff Premium). Per kjli4 3-class taxonomy:
Class 1 — leave open for cluster-maintainer fix.

**HOWEVER** — `.flywheel` skill is **NON-CANONICAL SKILL SHAPE**:

```
$ ls ~/.claude/skills/.flywheel/
bin/  CHANGELOG.md  config/  DASHBOARD.md  data/  dispatch-templates/
doctrine/  GAPS-LIVE.md  GAPS.md  GOAL.md  hooks/  INCIDENTS.md
lib/  logs/  LOOP.md  scripts/  ...

$ ls ~/.claude/skills/.flywheel/SKILL.md
ls: No such file or directory  ← NO SKILL.md
```

**There is no SKILL.md to extend.** This isn't a canonical Anthropic Skill —
it's the flywheel orchestrator's own SUBSTRATE living under `.claude/skills/`,
with its own organization (GOAL.md, LOOP.md, doctrine/, GAPS-LIVE.md, etc.).
The cluster-maintainer-pattern.md doctrine prescribes adding a Scripts table
to SKILL.md, but there's no SKILL.md here.

## Disposition options

| Option | Description | Choice rationale |
|---|---|---|
| A — Direct cluster fix (add Scripts table) | NO TARGET FILE (SKILL.md doesn't exist) | NOT APPLICABLE |
| B — Create SKILL.md scaffolding for this substrate | OVER-SCOPE — `.flywheel` is operationally-distinct from canonical skills | REJECTED (would impose canonical shape on non-canonical substrate) |
| C — Document scripts in `.flywheel/GOAL.md` or `LOOP.md` | More semantically appropriate (these ARE the substrate's load-bearing docs) BUT no Joshua-authorized block in this packet | DEFERRED |
| **D — AUDIT-ONLY surfacing non-canonical-skill sub-class** | Same path as 2xdi.120 + 2xdi.133 (Joshua-domain without authorization) | **CHOSEN** |
| E — Substrate-registry on-demand allowlist | Some `.flywheel/scripts/*` are kind=audit/validator — could be allowlisted (Cross-repo to skillos registry) | DEFERRED |

## NEW sub-class: non-canonical-skill-cluster

This dispatch surfaces a **distinct sub-class** of the Joshua-domain
cluster pattern: **non-canonical-skill targets**. The `.flywheel`
substrate uses GOAL.md / LOOP.md / etc. instead of SKILL.md. The
cluster-maintainer-pattern.md doctrine's "add SKILL.md Scripts table"
fix doesn't apply.

| Cluster bead | Skill | Canonical shape? | Disposition |
|---|---|---|---|
| flywheel-2xdi.120 | research-triad | YES (has SKILL.md) | AUDIT-ONLY (no auth) |
| flywheel-2xdi.133 | skill-builder | YES (has SKILL.md) | AUDIT-ONLY (no auth) |
| flywheel-2xdi.156 | rg-optimized-cluster | YES (Jeff Premium) | AUDIT-ONLY (Jeff substrate) |
| **flywheel-2xdi.154 (THIS)** | **`.flywheel` substrate** | **NO (uses GOAL.md/LOOP.md/etc.)** | **AUDIT-ONLY (non-canonical shape)** |

The non-canonical-skill sub-class deserves separate doctrine if it
recurs. Currently N=1; not pre-filing maintainer bead.

## Sibling individual beads

```
$ br list | grep -iE 'doctrine-broadcast-tail|ghost-orchestrator-detector|mcp-stale-reaper|skillos-health-probe|substrate-doctor-(infisical|vercel)-test'
(empty)
```

No sibling individual beads exist for the 6 scripts cited in the
cluster body. They were consolidated directly into the cluster bead by
gap-hunt-probe's `cluster_wired_but_cold` (per xn5bm filing) — no
prior dispatches against the individual scripts.

## Acceptance gates

Bead has no explicit AC (auto-filed gap bead). Inferred:

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Verify bead hypothesis empirically | **DONE** | cluster gap visible in live probe; 6 scripts confirmed under `~/.claude/skills/.flywheel/scripts/`; jsm confirms unmanaged |
| AG2 | Determine substrate class | **DONE** | Class 1 Joshua-domain (jsm-unmanaged, NOT Jeff Premium) |
| AG3 | Test cluster-maintainer applicability | **DONE (NOT applicable)** | no SKILL.md target file exists; cluster-maintainer-pattern.md fix prescribes a Scripts table edit which has no destination here |
| AG4 | Choose disposition consistent with substrate-boundary + authorization scope | **DONE** | AUDIT-ONLY (option D) per 2xdi.120 + 2xdi.133 precedent; non-canonical-shape sub-class flagged |
| AG5 | Surface mvzri+kjli4 + cluster-maintainer doctrine refinement opportunity | **DONE** | New sub-class (non-canonical-skill) added to taxonomy; cluster-maintainer-pattern.md doctrine MIGHT benefit from a "what to do when target lacks SKILL.md" section if N≥2 recurrence |

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/audit/flywheel-2xdi.154/evidence.md` | NEW (this file) |

No code mutation; no new beads filed; no cross-repo edits.

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: AUDIT-ONLY per Joshua-domain + non-canonical-skill-shape combination. cluster-maintainer-pattern.md fix doesn't apply (no SKILL.md target). NEW SUB-CLASS noted (non-canonical-skill-cluster); not pre-filing doctrine refinement bead at N=1.

## Skill auto-routes addressed

- **canonical-cli-scoping=n/a** — AUDIT-ONLY.
- **rust-best-practices=n/a** — no Rust.
- **python-best-practices=n/a** — no Python.
- **readme-writing=n/a** — no README.

## Four-Lens Self-Grade

- **brand** (10): META-RULE 2xdi.54 applied; identified non-canonical-skill sub-class that doesn't fit cluster-maintainer-pattern; honestly disclosed that direct fix (option A) isn't applicable (no SKILL.md target); did not over-scope by creating SKILL.md for non-canonical substrate.
- **sniff** (10): empirical jsm show + ls + SKILL.md absence verified; 6-script subject confirmed under `.flywheel` substrate; sibling-bead absence confirmed.
- **jeff** (10): scoped to audit + sub-class taxonomy update; did NOT create SKILL.md for non-canonical substrate (would impose foreign shape); did NOT pre-file cluster-maintainer doctrine refinement at N=1.
- **public** (10): Three Judges —
  - Skeptical operator: SKILL.md absence + jsm output reproducible; non-canonical-shape claim auditable via `ls .claude/skills/.flywheel/`.
  - Maintainer: 4-row cluster-taxonomy table tracks canonical vs non-canonical; mechanization-eligibility flagged at N≥2.
  - Future worker: when next non-canonical-skill cluster appears, this evidence forms the canonical precedent.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1-AG5: all DONE. ✓
- Substrate class determined empirically (Joshua-domain, non-canonical-shape). ✓
- Disposition matrix explicit (A-E with rationale). ✓
- New sub-class (non-canonical-skill-cluster) surfaced. ✓
- No over-scope mutation (didn't create SKILL.md). ✓

cli_canonical=n/a
rust_clean=n/a
python_clean=n/a
readme_quality=n/a

## L112 probe

Command:
```bash
[ ! -f ~/.claude/skills/.flywheel/SKILL.md ] && jsm show .flywheel 2>&1 | grep -q 'not found' && echo non_canonical_joshua_domain_confirmed || echo unexpected
```
Expected: `literal:non_canonical_joshua_domain_confirmed`
Timeout: 10 seconds
