---
title: "Scope-Aware Rename: Domain-Collision Protection for Cross-Repo Apply"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
---

# Scope-Aware Rename: Domain-Collision Protection for Cross-Repo Apply

Version: `scope-aware-rename-domain-collision-protection/v1`
Owner: anyone executing the apply phase of a Yuzu-Method naming-convention rename
Status: canonical, shipped 2026-05-11
Source bead: flywheel-2xdi.142 (memory-without-cross-link wire-in)

## TL;DR

Every rename apply phase in the Yuzu Method naming-convention rollout MUST
**scope-mask** its target paths. Blanket repo-wide grep-replace is
**FORBIDDEN**. Generic terms (`doctor`, `ledger`, `worker`, `dispatch`,
`tick`, `reap`) collide with legitimate non-flywheel domain vocabulary
— especially in ALPS healthcare-insurance territory. The apply tool MUST
enforce `--allowed-paths` fail-closed.

Joshua's 2026-05-05T~21:20Z directive (verbatim):
> "scope-aware rename is the rule"

## Canonical memory source

This doctrine summarizes
`feedback_scope_aware_rename_is_the_rule.md` — the META-rule memory
documenting the discipline. Read the memory for the full per-repo
path-allowlist (5 repos) and the rationale anchored in the BG-C
inventory (`/tmp/naming-rename-consumer-inventory-2026-05-05.md`).

## Sister doctrine

This is the **HOW (apply-phase scope)** companion to
`.flywheel/doctrine/naming-rename-cross-repo-wire-or-explain.md` (the
**WIRE-AND-FLAG mechanism**). Together they form the rename gate:

1. **Cross-repo discovery** (the WIRE-AND-FLAG doctrine — N=13 ecosystem consumer set)
2. **Zest Ledger consumer enumeration** (the WIRE-AND-FLAG doctrine)
3. **Scope-allowlist declaration** (THIS doctrine)
4. **Sampling-verify before apply** (THIS doctrine)
5. **Coordinated multi-repo apply** (the WIRE-AND-FLAG doctrine)
6. **Grep-verify post-apply** (the WIRE-AND-FLAG doctrine)

## Domain-collision table

The top-6 highest-impact rename candidates ALL collide with legitimate
non-flywheel domain vocabulary, per the 2026-05-05 BG-C inventory:

| Generic term | Flywheel meaning | Domain collision at ALPS |
|---|---|---|
| `doctor` | flywheel-loop doctor (substrate health check) | medical doctor (healthcare insurance) |
| `ledger` | wire-or-explain ledger | financial accounting ledger |
| `worker` | codex/claude worker pane | workers'-comp (insurance class code) |
| `dispatch` | flywheel-dispatch (NTM send) | dispatch-tables / MCP symbol tables |
| `tick` | tick.md substrate | timer-tick / Workato recipe fixture (ALPS has 104k of these) |
| `reap` | dispatch reaper | substring of `reapply` / `reappear` (false-positive) |

A blanket `rg -l doctor | xargs sed -i s/doctor/zest-medic/g` would
corrupt every ALPS document referring to actual medical doctors. ALPS
is an active client repo, **not just substrate** — corruption is
catastrophic.

## Per-repo path-allowlists (canonical)

| Repo | Allowed paths | Why |
|---|---|---|
| flywheel | `.flywheel/`, `~/.local/state/flywheel/`, `~/.flywheel/`, `flywheel-loop`, `flywheel-install/` (templates) | All substrate; no domain collision |
| skillos | `.skillos/`, paths matching skillos substrate | Substrate-only |
| **alpsinsurance** | **ONLY `.flywheel/` subdir** — NEVER root-level | Root is healthcare/insurance domain owned by client |
| ~/.claude/skills | ONLY skills with `flywheel*` or `flywheel:` namespace | Skill-substrate isolation |
| ~/.claude/projects/*/memory | only files referencing flywheel substrate | Memory cross-session |
| swarm-daemon | full repo IS in scope (canon source-of-truth) | Yuzu Method canon |

## How to apply (8-step procedure)

1. **Every rename apply MUST declare a path-allowlist BEFORE the apply
   runs.** Per-repo allowlist from the table above. Allowlist appears in
   the rename-plan declaration AND in the apply tool's `--allowed-paths`
   flag (fail-closed enforcement).

2. **Word-boundary regex mandatory** for terms with regex-stem ambiguity.
   Use `\b(reap|reaper|reaping|reaped)\b`, NOT bare `reap` (which would
   match `reapply` / `reappear`).

3. **ALPS-specific:** the rename can ONLY touch `.flywheel/` subdir of
   `alpsinsurance`. Any rename touching ALPS root is a **refused
   operation**.

4. **Freeze historical artifacts:** `*.bak.*` snapshots and
   `.beads/issues.jsonl` (append-only audit logs) keep their original
   vocabulary. Rename applies forward only.

5. **Excluded categories:** Workato JSON fixtures and any auto-generated
   content are explicitly excluded from the path-allowlist.

6. **Pre-flight sampling:**
   - Compute the candidate file set via path-allowlist + grep
   - Sample 10 random matches and read them
   - If ANY match is in domain-collision territory → **ABORT and re-scope**
   - Only after sampling-clean does the apply run

7. **Zest Ledger schema extension:** `naming_rename_consumer` rows get
   two new fields:
   - `scope_path` — the allowlist that captured this consumer
   - `domain_collision_check_passed` — boolean, sampling-verified

8. **Apply-tool fail-closed contract:** the rename apply tool MUST refuse
   to write outside the declared `--allowed-paths`. No silent
   path-escape; no override-by-flag (operator can re-run with an
   expanded allowlist, never bypass).

## Safe vs domain-collision vs off-limits (by-term)

**SAFE (low domain collision; mostly substrate-internal):**
- `flywheel-loop` (binary name; well-scoped, 520 consumers = coordination event but no domain collision)
- `wire-or-explain` (doctrine name; substrate-only)
- `Zest Ledger` / `Zest Press` / `Zest Pour` (NEW Yuzu vocabulary; zero existing collisions per BG-C)

**DOMAIN-COLLISION (path-allowlist MANDATORY):**
- `doctor`, `ledger`, `worker`, `dispatch`, `tick`, `reap` — all 6 require scope-masking
- ALPS root is the primary collision zone; `flywheel/.flywheel/` is the safe zone

**OFF-LIMITS (don't rename even with scope mask):**
- Jeff-owned upstream surfaces: `ntm`, `br`, `bv`, `beads-rust`, `agent-mail`, `dcg`, `cass`, `frankensqlite` — upstream contracts, not ours to rename
- Anything in `.beads/issues.jsonl*` — append-only audit log, rename forward only

## Anti-patterns (4)

| Anti-pattern | Why it fails |
|---|---|
| `rg -l doctor \| xargs sed -i` blanket apply | Catastrophic at ALPS — corrupts every document referring to actual medical doctors |
| Word-stem matching ("good enough") | `reap` matches `reapply`/`reappear` — word boundaries (`\b`) are mandatory |
| "Templates can rename freely" | flywheel-install templates propagate to NEW client repos with their OWN domain collisions; templates must use sufficiently-distinctive renames |
| "ALPS Workato counts are too high to ignore" | They're domain noise; exclude from rename scope, don't try to rewrite client integration recipes |

## Conformance

A rename apply proves conformance via:
- Rename-plan declaration includes explicit per-repo path-allowlist
- Apply tool ran with `--allowed-paths` flag matching the declaration
- Pre-flight 10-sample read returned all-clean (no domain-collision matches)
- Zest Ledger rows include `scope_path` + `domain_collision_check_passed=true`
- ALPS apply did NOT touch root-level (only `.flywheel/` subdir)
- Word-boundary regex applied for ambiguous stems

## Lifecycle

This is a HARD RULE for any future Yuzu-Method naming rename. The
domain-collision table is empirically grounded in the BG-C inventory; the
6 named terms are the canonical collision-set. New collision-prone terms
should be added to the table as they're discovered.

## Sister doctrine + memory

- `feedback_scope_aware_rename_is_the_rule` (this doctrine's canonical memory source)
- `.flywheel/doctrine/naming-rename-cross-repo-wire-or-explain.md` (the WIRE-AND-FLAG mechanism)
- `feedback_naming_rename_is_cross_repo_wire_or_explain` (sister memory)
- `feedback_naming_convention_distinguishable_ownership` (the WHAT)
- `feedback_post_wire_or_explain_three_skill_polish_gate` (polish gate; runs scope-masked rename)
- `project_alps_quintessential_member_2026_05_01` — ALPS-as-quintessential-flywheel-member; ALPS's existence is what teaches us scope-masking


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-09 — info-source watchtower:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md` for the canonical pattern.
- **MP-13 — living documentation:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-13-living-documentation.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
