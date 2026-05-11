---
name: sd-native-flags-to-enum-projection
type: doctrine
created: 2026-05-11
version: v0.1
status: draft-pending-skillos-bilateral-mirror-cycle (cross-orch-anti-divergence-v1.0.0 P3-trivial)
authority: flywheel-1 (CloudyMill) — codified 2026-05-11T06:30Z per bead flywheel-16ogj N=3 META-RULE threshold
ratification_target: skillos:1 bilateral byte-identical mirror; default-accept 6h from 2026-05-11T06:30Z (i.e. 2026-05-11T12:30Z)
cluster: meta-primitive-composition-shape-taxonomy.md (closest sister; this codifies a SCAFFOLD-LEVEL composition rather than a META-PRIMITIVE composition — see Classification Decision below)
sisters:
  - meta-primitive-composition-shape-taxonomy.md (sister cluster; scaffold-level vs META-PRIMITIVE-level composition shapes)
  - audit-machinery-hygiene-discipline.md (sister; codification-of-recurring-pattern at a different system layer)
  - canonical-cli-scoping/SKILL.md (consumer; the projection pattern guides scaffold authoring within canonical-cli surfaces)
n_instances_observed: 3
instance_threshold: N=3 (META-RULE promotion threshold per Joshua doctrine)
parent_bead: flywheel-16ogj
source_observations:
  - flywheel-1hshd.25 (docs-validation-probe): scaffold_cmd_validate(3 subjects) projecting native --schema .metadata_fields probes into validation-status enum
  - flywheel-1hshd.29 (flywheel-adopt): scaffold validate adoption-mode enum from native --reconcile / --first-run-audit / --apply-fs-rag
  - flywheel-1hshd.30 (flywheel-codex-stuck-detector-install): scaffold validate install-mode enum from native --apply / --dry-run
---

# sd-native-flags-to-enum-projection

## Canonical phrasing (AG1)

**When scaffolding a canonical-cli surface over a script with rich native flags, project disjoint mutually-exclusive native flags into a single `validate <mode-subject>` enum subject. The native flags survive as compat aliases; the enum becomes the machine-readable surface for downstream consumers.**

## Why

Three independent applications of the same projection move within one session (flywheel-1hshd.25 + .29 + .30) demonstrate this is a **repeatable canonical-cli composition pattern**, not an ad-hoc decision per surface. Without codification, every new scaffold author re-invents the projection naming and shape; with codification, the move is reachable from canonical-cli-scoping skill + this doctrine.

## How to apply

When authoring a scaffold's `validate` subcommand and the underlying script has **≥2 mutually-exclusive native flags** (e.g., a mode flag-set like `--reconcile|--first-run-audit|--apply-fs-rag` or `--apply|--dry-run`), default to enum-projection:

1. Identify the mutually-exclusive flag set as a **mode-subject** (e.g., `adoption-mode`, `install-mode`, `validation-status`).
2. Emit a `validate <subject>` subcommand in the scaffold that accepts the enum values matching each native flag.
3. Preserve the native flags as compat aliases (NO-BYPASS or PARTIAL-BYPASS variant — the scaffold yields to native when scaffold doesn't claim args[0]).
4. Test fixture: `validate <subject>` with each enum value + each native flag → matching envelopes.

## Composition mechanics

This is a **SCAFFOLD-LEVEL** composition (canonical-cli scaffold + underlying native script), NOT a META-PRIMITIVE composition. The two participants:

- **Native script primitive**: owns the mutually-exclusive flag set as canonical operator-facing surface.
- **Scaffold primitive (canonical-cli surface)**: owns the `validate <subject>` enum surface as canonical machine-readable consumer-facing surface.

The projection move is a **one-to-one type homomorphism** between the disjoint flag set and the enum value space:

```
{--reconcile, --first-run-audit, --apply-fs-rag} ↔ validate adoption-mode in {reconcile, first-run-audit, apply-fs-rag}
```

Surface invariants:
- `--reconcile` (legacy operator surface) ≡ `validate adoption-mode --value reconcile --json` (canonical machine surface)
- Native exit codes preserved on legacy path; canonical exit-code taxonomy on enum path
- Same downstream effect (same script body executes); only the front door differs

## Classification Decision (AG2)

The bead enumerated three candidate clusters:

| Candidate cluster | Fit | Reason |
|---|---|---|
| audit-machinery-hygiene-discipline.md | NO | About audit-method false-up shapes (A/B/C/E). This pattern is a SUCCESS shape, not a false-up. |
| meta-primitive-extraction-friction-class.md | NO | About FRICTION in primitive extraction. This pattern is a REPEATABLE composition success. |
| meta-primitive-composition-shape-taxonomy.md | **PARTIAL — sister cluster** | About META-PRIMITIVE shapes (PARALLEL/LAYERED/HUB/CASCADE). This is a SCAFFOLD-LEVEL shape (2 primitives, not 3+). |

**Decision:** author as standalone doctrine (`sd-native-flags-to-enum-projection.md`) with `cluster: meta-primitive-composition-shape-taxonomy.md` (closest sister). Skillos:1 to ratify (or counter-propose absorption into the sister taxonomy as a new SCAFFOLD-LEVEL sub-section).

**Rationale for standalone:** META-PRIMITIVE composition (3+ substrate primitives → 1 META) is a different abstraction layer from SCAFFOLD composition (1 canonical-cli scaffold + 1 native script → 1 dual-surface). Conflating them risks the synthesis-supersede-correct-scope trauma (citation at wrong scope). Sister-pointer is the safe move.

## 3-instance ladder

| # | Bead | Native flag set | Enum subject | Evidence |
|---|---|---|---|---|
| N=1 | flywheel-1hshd.25 (docs-validation-probe) | --schema .metadata_fields probes | `validation-status` (3 subjects) | `.flywheel/audit/flywheel-1hshd.25/evidence.md` (scaffold_cmd_validate filled with 3 subjects) |
| N=2 | flywheel-1hshd.29 (flywheel-adopt) | --reconcile / --first-run-audit / --apply-fs-rag | `adoption-mode` | `.flywheel/audit/flywheel-1hshd.29/evidence.md` (NO-BYPASS variant; native flags fall through; enum surfaces on canonical) |
| N=3 | flywheel-1hshd.30 (flywheel-codex-stuck-detector-install) | --apply / --dry-run | `install-mode` (enum {dry_run, apply}) | `.flywheel/audit/flywheel-1hshd.30/evidence.md` ("cross-sources native --apply/--dry-run flags") |

## Anti-pattern guards

1. **Don't promote without reading the actual worker evidence files for precise pattern phrasing.** This bead body explicitly cited the synthesis-supersede-correct-scope trauma class as a guard: claim-verification-at-wrong-scope. Reading the evidence files (done; see "3-instance ladder" above) is the scope-correct citation.
2. **Don't rush 3-way ratification when 2-way bilateral with skillos suffices** for substrate-class material. AG3 below is bilateral.
3. **Don't conflate SCAFFOLD-LEVEL composition with META-PRIMITIVE composition** (the cluster-classification trap above).

## Mandate (post-ratification)

Every canonical-cli scaffold authoring task (e.g., scaffold-canonical-cli.sh, scaffold-canonical-cli-py.sh) MUST:

1. **Audit native flag set** of the target script for mutually-exclusive groups before authoring `validate`.
2. **Apply enum projection** when ≥2 mutually-exclusive flags exist; document the mode-subject name + enum value mapping in the evidence file.
3. **Test fixture for each enum value** and each legacy native flag (compat-test).
4. **Cite this doctrine** in the scaffold's evidence file when the projection move is applied.

## Bilateral mirror cycle (AG3)

Proposed to skillos:1 via handoff `20260511T0630Z-from-flywheel-1-to-skillos-1-sd-native-flags-to-enum-projection-bilateral-mirror.md`.

Default-accept window: 6h from 2026-05-11T06:30Z (i.e., 2026-05-11T12:30Z) per cross-orch-anti-divergence-v1.0.0 P3-trivial protocol.

Skillos:1 may:
- **Ratify byte-identical mirror** (recommended): copy this doctrine to `~/Developer/skillos/.flywheel/doctrine/sd-native-flags-to-enum-projection.md` with same content; flywheel and skillos sync if either side amends.
- **Counter-propose absorption** into `meta-primitive-composition-shape-taxonomy.md` as a new SCAFFOLD-LEVEL sub-section (5th shape OR new top-level "scaffold composition shapes" section).
- **Counter-propose different cluster** (e.g., a new `canonical-cli-composition-shapes.md` doctrine sister to the META-PRIMITIVE taxonomy).

## Sister-byte-check (AG4)

Pending skillos:1 mirror commit. Post-mirror, run:

```bash
diff -q ~/Developer/flywheel/.flywheel/doctrine/sd-native-flags-to-enum-projection.md \
        ~/Developer/skillos/.flywheel/doctrine/sd-native-flags-to-enum-projection.md
```

Expected: zero-diff (byte-identical mirror per cross-orch-anti-divergence-v1.0.0).

If skillos counter-proposes a different cluster placement, this section updates to reflect the agreed location + sister-byte-check command points to the new path.

## Mission anchor

`80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a`

— flywheel-1 (CloudyMill), 2026-05-11T06:30Z
