# Classification Playbook — De-personalization Sweep

> *The rules for classifying every doctrine, memory rule, script, and skill in flywheel as **engine** (publishable) or **overlay** (private). Used to drive the Wave 2 sweep that materializes the engine/overlay boundary.*

This document is the operational companion to [ENGINE-OVERLAY-BOUNDARY.md](ENGINE-OVERLAY-BOUNDARY.md). Where that document declares the paradigm, this one tells a worker (human or AI) exactly how to make the classification call for any given artifact.

---

## The classification rule (restated)

For each artifact, apply this test:

> *If you removed every mention of specific names (operator name, client names, project names, pane numbers, dates, infrastructure identifiers) and the artifact still made coherent sense as documentation of a universal pattern, it is **engine**. If removing those names makes the artifact empty or meaningless, it is **overlay**.*

The classifier has three possible outputs per artifact:

| Class | Meaning | Action |
|---|---|---|
| `engine` | Universal pattern; ships in the public engine | Copy to `engine/` tree; de-personalize specific mentions; verify pattern still holds |
| `overlay` | Instance-specific; stays in user's private overlay | Leave at original path; verify nothing references it from engine-side |
| `engine-after-rewrite` | Has universal pattern but is currently too instance-anchored to publish as-is | Rewrite to extract the universal pattern; original stays as overlay-class instance-evidence |

## The four-question filter

When classifying any single artifact, ask in order:

### Q1 — What is this artifact's *purpose*?

- "Document a universal pattern" → likely engine
- "Capture a specific incident" → likely overlay (unless the incident illustrates a pattern worth universalizing)
- "Track project state" → overlay
- "Implement a behavior" → likely engine if generic, overlay if it hardcodes specific paths/IDs

### Q2 — What changes if we erased all proper nouns?

- Coherent and useful → engine
- Empty or meaningless → overlay
- "Has the pattern but loses the punch" → engine-after-rewrite

### Q3 — What is the artifact's *substrate class*?

(Per the [substrate-class classifier](../) L162 paradigm.)

- `production` (worker output, AaaS artifacts) → typically engine
- `protection` (hook, gate, detector) → engine
- `test-fixture` (synthetic test corpus) → engine
- `self-documentation` (doctrine describing a protection) → engine
- `audit-ledger` (logs, receipts, history) → overlay
- *unclassified or mixed* → re-examine; classify the dominant component

### Q4 — Does any other engine artifact *require* this one to make sense?

- Yes → must be engine
- No → free to classify by content

If the answers to Q1-Q4 don't converge, surface to the operator for review.

## Worked examples

### Doctrines

**`cross-repo-write-path-discipline.md`** (currently in `.flywheel/doctrine/`)
- Q1: Documents a universal pattern (cross-repo writes need a class-aware gate)
- Q2: Coherent without names — it's about the pattern, not about Joshua's specific incident
- Q3: `self-documentation` (describes the protection mechanism)
- Q4: Engine artifacts reference it; required
- **Classification:** `engine` (light de-personalization of incident citations)

**`(hypothetical) skillos-onboarding-2026-04-15.md`** (if it existed)
- Q1: Documents a specific onboarding event
- Q2: Erase "skillos" and "2026-04-15" → empty
- Q3: `audit-ledger` (historical record)
- Q4: No engine artifact depends on it
- **Classification:** `overlay`

**`substrate-class-classifier.md`** (currently in `.flywheel/doctrine/`)
- Q1: Documents the L162 paradigm primitive
- Q2: Coherent without names
- Q3: `self-documentation` (the paradigm description)
- Q4: All four-layer-paradigm artifacts reference it
- **Classification:** `engine` (lightly de-personalize incident citations; keep the paradigm content)

### Memory rules

**`feedback_data_decides_not_human_meatpuppet.md`**
- Q1: Universal pattern (data + methodology decide; AI doesn't gate on operator)
- Q2: Coherent — rule applies in any flywheel installation
- Q3: `self-documentation` (operational principle)
- Q4: Not strictly required by engine artifacts but reinforces engine doctrines
- **Classification:** `engine`

**`feedback_codex_workers_panes_234.md`**
- Q1: Documents one user's specific pane assignment
- Q2: Erase "codex" + "234" → empty
- Q3: `audit-ledger`
- Q4: No engine artifact requires it
- **Classification:** `overlay`

**`project_alps_vrtx_onboarding_priority_2026_05_04.md`**
- Q1: Captures specific project priority on a specific date
- Q2: Erase "alps" + "vrtx" + "2026-05-04" → empty
- Q3: `audit-ledger`
- Q4: No engine requirement
- **Classification:** `overlay`

**`feedback_orch_handshakes_never_gate_on_joshua.md`**
- Q1: Universal pattern about orch coordination
- Q2: Replace "Joshua" with `{operator}` → still coherent
- Q3: `self-documentation`
- Q4: Multiple engine artifacts reference the principle
- **Classification:** `engine-after-rewrite` (substitute `Joshua` → `{operator}` throughout)

**`feedback_substrate_watchtower_must_be_wired.md`**
- Q1: Pattern about how systems detect external substrate changes
- Q2: Coherent without names
- Q3: `self-documentation`
- Q4: Not required, but valuable
- **Classification:** `engine`

### Scripts

**`canonical-doctrine-sync.sh`**
- Q1: A specific propagator implementation
- Q2: Mostly coherent without names; some path hardcoding
- Q3: Mixed; the *script* is engine, the *paths it propagates* are overlay
- Q4: Required by other engine workflows
- **Classification:** `engine-after-rewrite` (parameterize paths)
- **Note:** This script is currently halted; halted-state itself is overlay metadata

**`flywheel-loop`** (the heartbeat driver)
- Q1: Implements the universal flywheel cycle
- Q2: Coherent without names; logic is generic
- Q3: `production` (worker output substrate)
- Q4: Required
- **Classification:** `engine`

### Beads

**`flywheel-bszgl` and sub-beads**
- Q1: Track specific work waves
- Q2: Erase IDs and dates → empty
- Q3: `audit-ledger`
- Q4: No engine artifact requires
- **Classification:** `overlay`
- **Note:** The *pattern* of "parent bead + sub-beads with substrate-class labels" IS engine; an individual instance isn't.

## Output format (per artifact)

After classification, each artifact gets an addition to its frontmatter (or, for non-frontmatter files, a sidecar `.classification.json`):

For markdown files with YAML frontmatter:

```markdown
---
# existing frontmatter
...
# added by classification sweep:
substrate_class: engine | overlay | engine-after-rewrite
classified_at: 2026-05-12T...
classified_by: <human-or-agent-id>
classification_rationale: |
  Q1 answer → ...
  Q2 answer → ...
  Q3 answer → ...
  Q4 answer → ...
rewrite_required: <list of de-personalizations required if engine-after-rewrite>
---
```

For scripts:

```bash
# substrate_class: engine
# classified_at: 2026-05-12T...
# classification_rationale: see classifications/<script-name>.json
```

For sidecar JSON:

```json
{
  "artifact": "path/to/artifact",
  "substrate_class": "engine | overlay | engine-after-rewrite",
  "classified_at": "2026-05-12T...",
  "classified_by": "...",
  "q1_purpose": "...",
  "q2_proper_nouns_test": "...",
  "q3_substrate_class": "...",
  "q4_engine_requires": "...",
  "rewrite_required": []
}
```

## De-personalization patterns (for `engine-after-rewrite`)

When an artifact qualifies as engine but contains specific names, apply these substitutions:

| Specific | Generic |
|---|---|
| `Joshua` or `Joshua Nowak` | `{operator}` |
| `joshua@` (email-shape) | `{operator}@` |
| Specific client names (ALPS Insurance, TerraTitle, Blackfoot Telecom, mobile-eats, ZestStream clients) | `{client-A}`, `{client-B}`, etc. (or omit when not load-bearing) |
| `~/Developer/flywheel/` (when describing canonical structure) | `~/Developer/<project>/` |
| Specific bead IDs (`flywheel-jloib`, `skillos-…`) | `{bead-id}` |
| Specific dates (`2026-05-12T05:30Z`) | `<incident-date>` (or omit when generic-pattern) |
| Specific pane numbers (`pane 3`, `pane 2/3/4`) | `<worker-pane>` |
| `skillos:1`, `mobile-eats:1`, `flywheel:1` (when illustrative) | `orch-A`, `orch-B`, `orch-C` |
| Specific Infisical PIDs, Supabase refs, Vercel IDs | always remove; never publish |
| Specific NTM session names | `<session>` |

**Preserve verbatim:**
- L-rule numbers and titles (engine artifacts)
- Doctrine document titles
- Skill names
- Paradigm names (substrate-class, four-layer-tenant-isolation, etc.)
- Inspirations + citations (Meadows, PAI, NTM, beads_rust, etc.)
- Technical patterns (`AKIA[0-9A-Z]{16}`, the 9 petals, etc.)

## Edge cases

### "Instance is the pattern" — the doctrine cites the incident as its proof

Some doctrines use a specific incident as load-bearing evidence (e.g., the N=3 SATURATION clobber that produced the propagator-ownership doctrine). The *pattern* is engine; the *specific incident* is overlay.

Resolution: rewrite the doctrine to describe the pattern, citing the incident abstractly ("an N=3 cross-repo clobber observed during early development"). Move the specific incident details to the overlay-class trauma corpus.

### Skills that wrap specific paths

Some skills hardcode `~/Developer/<specific-project>/`. The skill *pattern* is engine; the *hardcoding* is overlay.

Resolution: parameterize. The skill takes a project path argument or reads from `~/.flywheel/config.yaml`.

### Doctrines that document specific tooling versions

A doctrine that says "codex 0.125.0 has bug X" is overlay (tool-version-anchored). A doctrine that says "CLI tools change flag conventions across versions; here's how to handle the class" is engine.

Resolution: separate the *class-of-issue* doctrine (engine) from the *specific-version-receipts* (overlay).

### Cross-orch protocol artifacts

Handoff documents under `.flywheel/handoffs/` are overlay (specific cross-orch coordination history). The *protocol* they implement (L156 inbox, L157 outbox) is engine.

Resolution: handoffs are overlay-class always; protocol doctrines are engine-class.

### Mixed-content scripts

A script that has engine *logic* but overlay *configuration*: parameterize. The script becomes engine; the configuration moves to overlay (e.g., `~/.flywheel/config.yaml`).

## How to dispatch the sweep

Once Joshua ratifies this playbook + Wave 2 begins:

1. **Inventory phase:** enumerate every doctrine + memory rule + script + skill (~250 artifacts total)
2. **Triage phase:** each worker takes a batch of 10-20 artifacts; applies the four-question filter; produces classification JSON for each
3. **Review phase:** flywheel:1 reviews the classification JSON; flags any low-confidence calls for Joshua
4. **Rewrite phase:** for `engine-after-rewrite` artifacts, apply the de-personalization patterns; verify pattern still holds
5. **Migration phase:** copy `engine` artifacts to the public `engine/` tree; `overlay` artifacts stay in place
6. **Verification phase:** run flywheel against the new engine + existing overlay composition; confirm everything still works

Estimated total effort: ~10-15 worker-hours across parallel panes.

## What success looks like

After the sweep:

- Every artifact has an explicit substrate_class declaration
- The `engine/` tree contains only universal patterns; nothing identifies any specific person, client, or project
- Overlay artifacts stay where they are
- A fresh user can `curl | bash` the installer, get the engine, supply their own MISSION.md + project list, and have flywheel working

Until success: the public repo extraction (Wave 2c) waits.

---

*This playbook is part of the flywheel ecosystem. It is itself classified as `engine` — universal pattern for any project that needs to materialize a public-engine boundary cleanly.*
