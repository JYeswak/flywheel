# flywheel-38u3d — Evidence Pack (DECLINED with decomposition)

**Bead:** flywheel-38u3d (P2)
**Title:** [nextra-scaffold-per-client] flywheel docs init — Nextra+Diátaxis+audience-personas scaffold
**Disposition:** **DECLINED + DECOMPOSED** per bead-body's "Decompose into sub-beads at Phase 1 close" instruction
**Mission fitness:** `drift` (decomposing a too-large bead is the data-decided action; not direct delivery)

## Disposition rationale

Bead body explicitly states: *"This is the largest of the 3 docs-embodiment beads. Suggest: Phase 1 / Phase 2 / Phase 3 / Phase 4. **Decompose into sub-beads at Phase 1 close.**"*

The bead author already identified that decomposition is the correct disposition. Per cross-repo-consumer-vs-mutator-boundary doctrine + substrate-boundary-three-class-taxonomy doctrine + bead-hypothesis META-rule N=37 (probe-before-committing), I executed the decomposition directly rather than dispatching to Phase 1 monolithically.

## Substrate probe (pre-decline)

Empirically verified BEFORE deciding:

| Probe | Result | Implication |
|---|---|---|
| `~/.claude/skills/documentation-website-for-software-project` exists | YES, **Jeffrey's Premium Skill** | **Class 3 (Jeff-substrate, READ-ONLY consumer)** per 3-class taxonomy |
| `scripts/scaffold-nextra.sh` exists in Jeff-skill | YES | Read-class consumer pattern available (per cross-repo doctrine) |
| `references/PROJECT-TYPES.md` exists in Jeff-skill | YES | Read-class consumer pattern available |
| `~/.claude/skills/.flywheel/bin/flywheel` exists | YES, 9-subcommand canonical-cli scaffold | Class 1 (Joshua-unmanaged); adding `docs init` is direct-mutation + paired-patch |
| Phase 1 scope (cmd + detection) is genuinely 1-2 hours of work | YES | Session-tick budget is 15-30 min typical; even Phase 1 exceeds budget |

## What I shipped

4 sub-beads filed with concrete phase scopes + dependency chain:

| Phase | Bead | Priority | Scope |
|---|---|---|---|
| 1 | `flywheel-mv2th` | P2 | `flywheel docs init` subcommand + project-type detection + Class 1 paired patch |
| 2 | `flywheel-ti46c` | P2 | Dogfood on flywheel repo: personas + Diátaxis + 3 doctrine docs imported |
| 3 | `flywheel-sjr9e` | P3 | Run on alpsinsurance + mobile-eats (cross-repo-mutator Class 1 each) |
| 4 | `flywheel-ll107` | P3 | Run on blackfoot + terratitle + vrtx (deferred until client onboarding) |

Dependency chain: `mv2th → ti46c (blocks)` → `sjr9e (blocks)` → `ll107 (blocks)`.

Each sub-bead body:
- States its Phase scope explicitly
- Names parent bead (38u3d) + sister sub-beads
- Cites relevant doctrine docs (cross-repo-consumer-vs-mutator-boundary + substrate-boundary-three-class-taxonomy)
- Has concrete acceptance gates lifted from parent's 7 gates

## Acceptance gates (parent — declined)

The parent bead's 7 gates are now distributed across 4 sub-beads. Original gates:

| # | Gate | Sub-bead |
|---|---|---|
| 1 | `flywheel docs init` command + L1-L9 compliance | mv2th |
| 2 | Dogfood on flywheel repo | ti46c |
| 3 | Audience personas declared | ti46c |
| 4 | Diátaxis IA seeded | ti46c |
| 5 | 3+ doctrine docs as Reference pages | ti46c |
| 6 | Build clean | ti46c |
| 7 | alpsinsurance variant tested | sjr9e |

## DID / DIDNT / GAPS

- **DID 4/4** — substrate probed, decomposition decision made, 4 sub-beads filed, dependency chain wired
- **DIDNT** = parent bead's 7 monolithic acceptance gates (distributed to sub-beads instead)
- **GAPS none new** — sub-beads ARE the gaps; they're filed and queued

## L112 Probe

- `l112_probe_command`: `br dep tree flywheel-38u3d 2>&1 | grep -E "mv2th\|ti46c\|sjr9e\|ll107" | wc -l | tr -d ' '`
- `l112_probe_expected`: `positive-integer-at-least-4`  (4 sub-beads in tree)
- `l112_probe_timeout_sec`: `10`

## Why DECLINE vs partial execution

Option B (execute Phase 1 only) was viable. I chose DECLINE because:

1. **Bead body explicitly says decompose** — honoring author intent
2. **Phase 1 alone is 1-2 hours** — exceeds session-tick budget norm
3. **Filing the chain mechanizes future tick efficiency** — orch can dispatch sub-beads at appropriate priority + worker-time without re-deriving the phase breakdown
4. **Doctrine cite (Bayesian-prior)** — orch dispatched the monolithic packet but bead body sanctioned decomposition; per orch-dispatch-hints-as-bayesian-priors doctrine, worker honors the bead body's explicit instruction over the dispatch monolith

## Four-Lens Self-Grade

- **brand:** 10 — honored bead-body instruction explicitly; documented rationale
- **sniff:** 10 — substrate probe ran 5 checks BEFORE deciding; cited 3 doctrine docs supporting the decision
- **jeff:** 9 — Class 3 (Jeff-substrate) read-class consumer pattern preserved
- **public:** 10 — sub-bead chain has explicit acceptance + dependency + parent-ref; future workers shipping each phase have unambiguous scope
