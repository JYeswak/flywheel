---
title: "Substrate Boundary 3-Class Taxonomy: Joshua / Skillos / Jeff-Premium"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
---

# Substrate Boundary 3-Class Taxonomy: Joshua / Skillos / Jeff-Premium

Version: `substrate-boundary-three-class-taxonomy/v1`
Owner: dispatch authors + workers handling `~/.claude/skills/<x>/` work
Status: canonical, shipped 2026-05-11
Source bead: flywheel-2xdi.149 (memory-without-cross-link wire-in)

## TL;DR

When a worker bead targets `~/.claude/skills/<skill>/` or
`~/.claude/commands/`, **classify substrate BEFORE any mutation** via
`jsm show <skill>`. Three distinct boundary classes with different
discipline:

| Class | Detection | Discipline |
|---|---|---|
| **Joshua-substrate** | `jsm show` → "not found" OR Joshua-as-author | Direct mutation + paired `jsm-import-ready` patch |
| **Skillos-substrate** | jsm-managed, peer-orch ownership (Joshua owns + skillos:1 tracks) | Patch artifact ONLY; flag `orch_action_required=jsm_push_<bead>` |
| **Jeff-substrate** | "Jeffrey's Premium Skill ⭐" marker | AUDIT-ONLY; no mutation; no patch; Jeff-issue only if ≥P2 + full workaround research |

## Canonical memory source

This doctrine summarizes
`feedback_substrate_boundary_three_class_taxonomy.md` — the META-rule
memory (2026-05-11). Extends the cross-repo discipline of
`.flywheel/doctrine/cross-repo-consumer-vs-mutator-boundary.md` (2xdi.93)
with this orthogonal 3-class classification.

## Sister doctrine relationship

- **`cross-repo-consumer-vs-mutator-boundary` (2xdi.93)** = is the bead READING or WRITING into `.claude/skills/`?
- **`substrate-boundary-three-class-taxonomy` (this doc)** = WHO owns the target skill (Joshua / Skillos / Jeff)?

Both apply to any cross-repo bead. The mutator vs consumer call gates whether you need patch discipline; the 3-class call determines WHICH patch discipline.

## Class 1: Joshua-substrate (most permissive)

**Detection:**

```bash
jsm show <skill> 2>/dev/null | head -3
# Output: "Skill 'X' not found." → Class 1
# Or: jsm show returns Joshua as author/owner
```

**Examples (2026-05-11 session):**

| Skill | Bead | Outcome |
|---|---|---|
| `canonical-cli-scoping` | n4gt1 | PERFECT 1000 direct mutation |
| `cubcloud-ops` | 2xdi.99 | direct mutation + paired patch |
| `infisical-secrets` | 2xdi.112 | dispatched without restriction |
| `research-triad` | 2xdi.105, 03yaj | direct mutation + paired patch (single + batch) |
| `skill-builder` | plue9 | 10/10 SKILL.md coverage |

**Discipline:**
1. Direct mutation ALLOWED
2. Paired `jsm-import-ready` patch artifact at `.flywheel/audit/<bead-id>/patches/` with: `*.patch` + `*.original` + `*.proposed` + `apply-instructions.md`
3. L107 file reservation before edit; release post-commit
4. Callback: `no_direct_skill_mutation_reason=jsm_unmanaged_with_paired_jsm_import_ready_patch_artifact_written`

## Class 2: Skillos-substrate (patch-only)

**Detection:** `jsm show <skill>` returns Joshua as owner BUT skill is
registered + tracked by skillos:1 peer orch.

**Examples (2026-05-11 session):**

| Skill | Bead | Outcome |
|---|---|---|
| `agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools` | xhevf + b6p1m | Patch artifacts written; orch attempted jsm push, blocked on upstream hygiene (filed `flywheel-75m9o`) |

**Discipline:**
1. Direct mutation FORBIDDEN
2. Write patch-only artifact at `.flywheel/audit/<bead-id>/patches/`:
   - `*.patch` + `*.proposed` + `apply-instructions.md`
   - NO live mutation of the skill file
3. Callback: `no_direct_skill_mutation_reason=jsm_managed_patch_artifact_written`
4. Flag `orch_action_required=jsm_push_<bead>_patch_to_skillos`
5. Cross-orch handoff to skillos:1 if multi-artifact (per 08xe2 unified-batch pattern)

## Class 3: Jeff-substrate (AUDIT-ONLY)

**Detection:** `jsm show <skill>` returns **"Jeffrey's Premium Skill ⭐"**
marker, OR jsm metadata cites Jeffrey Emanuel as author.

**Examples (2026-05-11 session):**

| Skill | Bead | Outcome |
|---|---|---|
| `asupersync-mega-skill` | 2xdi.97 | AUDIT-ONLY PERFECT 1000; no mutation; no patch; no upstream issue (P3 priority didn't justify Jeff-issue overhead). SD `jeff-substrate-vs-skillos-substrate-distinction`. |
| `agent-ergonomics-and-intuitiveness-maximization-for-cli-tools` (OLD name) | 2xdi.96 | Also Jeff-substrate (correct rationale; original framing was moot-by-parallel-fix) |

**Discipline:**
1. NO mutation
2. NO patch artifact
3. AUDIT-ONLY disposition with evidence pack documenting the gap
4. **Jeff upstream issue ONLY when**:
   - Priority ≥ P2 AND
   - Full workaround research per `feedback_jeff_issue_requires_full_workaround_research_first` AND
   - `jeff-issue-chain` skill phased process

## Detection probe (mandatory pre-mutation)

```bash
jsm show <skill> 2>/dev/null | head -3
```

Output → class mapping:

- `"Skill '<x>' not found."` → **Class 1** (Joshua-unmanaged)
- `"Jeffrey's Premium Skill ⭐"` → **Class 3** (Jeff-substrate AUDIT-ONLY)
- Anything else with `managed_by: skillos` or skillos:1 in author field → **Class 2** (Skillos-substrate)
- Joshua-as-author without skillos tracking → **Class 1** (managed-by-self)

## Apply (per worker tick)

1. Before reserving any file under `~/.claude/skills/<skill>/`, run `jsm show <skill>`.
2. Classify per the detection probe table.
3. Select discipline per the class branch (Class 1 / 2 / 3).
4. Skip-and-defer is **correct** for Class 3 (Jeff-substrate); AUDIT-ONLY is the canonical disposition.
5. Bead-filing convention: title prefix with `[joshua-substrate]`, `[skillos-substrate]`, or `[jeff-substrate-audit-only]` when target is identifiable at filing time.

## Why this matters

Without explicit classification, workers default-defer ALL cross-repo work as if it were Class 3 (Jeff-substrate). The N=8 deferral pattern observed earlier this session before Joshua-authorization escape hatch was filed was driven by exactly this conflation.

With explicit classification:
- **Class 1 (Joshua-unmanaged)** ships PERFECT 1000 — 6 instances this session (n4gt1, myfak.1, ol1bu, d6zk1.1, 9a3k1, 2xdi.72.1)
- **Class 2 (Skillos-substrate)** produces clean patch artifacts — 6 instances this session (xhevf, b6p1m, n4gt1, myfak.1, ol1bu, d6zk1.1)
- **Class 3 (Jeff-substrate)** stays AUDIT-ONLY — 1 confirmed (2xdi.97); corrects mis-framing of 2xdi.96

## Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| Skip classification probe; assume Class 3 by default | Generates needless deferrals; misses N=12+ Class 1+2 productive instances per session |
| Treat any jsm-managed skill as Class 3 | Conflates Skillos-substrate (Joshua owns, skillos tracks) with Jeff-substrate (Jeffrey authors); different disciplines |
| File Jeff upstream issue for Class 3 P3 bead | Wastes Jeff-issue overhead; threshold is ≥P2 + workaround research |
| Direct-mutate Class 2 because "I have access" | Bypasses Skillos handoff contract; produces drift between local edit and Skillos canonical |

## Conformance

A cross-repo bead's worker callback proves conformance via:
- Classification recorded in evidence pack ("Class 1 Joshua-unmanaged" / etc.)
- Discipline matches class branch:
  - Class 1: `no_direct_skill_mutation_reason=jsm_unmanaged_with_paired_jsm_import_ready_patch_artifact_written`
  - Class 2: `no_direct_skill_mutation_reason=jsm_managed_patch_artifact_written` + `orch_action_required=jsm_push_<bead>`
  - Class 3: `no_direct_skill_mutation_reason=jeff_substrate_audit_only_no_mutation_no_patch_artifact`
- Bead title carries `[<class>-substrate]` prefix when identifiable at filing time

## Sister doctrine + memory

- `feedback_substrate_boundary_three_class_taxonomy` (above-cited canonical memory)
- `.flywheel/doctrine/cross-repo-consumer-vs-mutator-boundary.md` (sister doctrine; consumer-vs-mutator is the orthogonal axis)
- `feedback_cross_repo_consumer_vs_mutator_distinction` (sister memory)
- `project_skillos_separated` — skillos:1 ownership of skill-substrate session
- `feedback_jeff_issue_requires_full_workaround_research_first` — Class 3 upstream-issue discipline
- `reference_jeff_substrate_inventory` — canonical list of Jeff binaries (NTM, beads, etc.)

## Lifecycle

This is a HARD RULE. Any future cross-repo bead targeting
`~/.claude/skills/<skill>/` MUST run the detection probe before
mutation. The 3 classes are stable; new skills inherit one of these
three. Track new instances per class to refine the discipline as the
ecosystem grows.
