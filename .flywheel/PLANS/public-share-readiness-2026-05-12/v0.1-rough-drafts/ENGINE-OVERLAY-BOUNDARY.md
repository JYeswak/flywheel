# Engine / Overlay Boundary

> *What flywheel ships publicly versus what each user brings to their own installation.*

This document is the explicit declaration of the boundary between the **engine** (public, open-source, universal patterns) and the **overlay** (private to each user, instance-specific, idiosyncratic).

A clean boundary here matters because:

- Engine artifacts can be published, version-controlled in a public repo, taught, learned from
- Overlay artifacts contain personal mission, project history, client information, infrastructure identifiers, trauma corpus — they must never accidentally leak into the engine
- The boundary determines the publish/private classification of every file in the system

---

## The two layers

```
┌──────────────────────────────────────────────────────────────┐
│  ENGINE  (public)                                            │
│  ────────                                                    │
│  • The 9-petal cycle                                         │
│  • Plan / Bead / Code reasoning spaces                       │
│  • Trauma-class promotion ladder + meta-rule pattern         │
│  • Cross-orchestrator bilateral protocol                     │
│  • Doctor / health / repair CLI triad                        │
│  • Safety substrate (DCG, secret-leak hook, cross-repo)      │
│  • Substrate-class classifier paradigm                       │
│  • Universal doctrine corpus (after de-personalization)      │
│  • Universal memory rules (after de-personalization)         │
│  • Skill catalog conventions                                 │
│  • Completion-debt verification + audit-pass system          │
│  • Bead single-writer JSONL discipline                       │
│  • The installer + bootstrap scripts                         │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼  user composes overlay on top
┌──────────────────────────────────────────────────────────────┐
│  OVERLAY  (private to user)                                  │
│  ──────                                                      │
│  • MISSION.md content (your mission)                         │
│  • Client list / project list                                │
│  • Trauma corpus instances (your incidents)                  │
│  • Infrastructure identifiers (Infisical PIDs, Supabase refs,│
│    Vercel project IDs, etc.)                                 │
│  • Memory rules that name your specific clients, panes,      │
│    repos, dates                                              │
│  • Specific bead history                                     │
│  • Past dispatch logs                                        │
│  • Cross-orch handoff history                                │
│  • Your `.zs-tenant.yaml` declarations                       │
└──────────────────────────────────────────────────────────────┘
```

## The classification rule

Every artifact is classified per this rule:

> *If you removed every mention of specific names (yours, clients, projects, panes, dates, identifiers) and the artifact still made coherent sense as documentation of a pattern, it is **engine**. If removing those names makes the artifact empty or meaningless, it is **overlay**.*

Examples applied to memory rules:

| Memory rule | Class | Why |
|---|---|---|
| `feedback_data_decides_not_human_meatpuppet` | Engine | Universal pattern; no names needed |
| `feedback_orch_handshakes_never_gate_on_joshua` | Engine* | Replace "Joshua" with `{operator}` and the pattern holds |
| `project_alps_vrtx_onboarding_priority_2026_05_04` | Overlay | Without "ALPS", "vrtx", "2026-05-04", it's empty |
| `feedback_orchestrators_kill_panes_without_respawn` | Engine | Universal failure mode |
| `feedback_codex_workers_panes_234` | Overlay | Specific to one user's pane layout |

\*Engine after de-personalization sweep.

## Filesystem layout (intended end-state)

Once the engine/overlay split is fully materialized:

```
~/.flywheel/                      ← user-owned runtime state (overlay-class)
├── config.yaml                   ← user composition
├── cross-repo-authorized-writes.json
└── private/                      ← never published; user-specific
    ├── mission.md
    ├── projects.yaml
    └── trauma-history/

~/Developer/flywheel-engine/      ← public engine (cloned from public repo)
├── README.md
├── ARCHITECTURE.md
├── CHARTER.md
├── LICENSE
├── doctrine/                     ← universal doctrines
├── rules/                        ← universal L-rules
├── scripts/                      ← installer, doctor, health, repair
├── skills/                       ← universal skill scaffolds
├── templates/                    ← templates user can customize
└── universal-memory/             ← universal memory rules (de-personalized)

~/Developer/<your-project>/       ← any project where you run flywheel
└── .flywheel/                    ← project-level (mix of engine + overlay)
    ├── doctrine/                 ← can include engine doctrines + project-specific
    ├── rules/                    ← can include engine rules + project-specific
    ├── handoffs/                 ← overlay-class (project history)
    ├── beads/issues.jsonl        ← overlay-class (your task graph)
    ├── audit/                    ← overlay-class (your bead audit history)
    └── evidence/                 ← overlay-class
```

## What lives where, in detail

### Engine (public; eligible for the public repo)

**Foundational paradigms:**
- The 9-petal cycle documentation
- The three-reasoning-spaces (plan/bead/code) framework
- The trauma-class promotion ladder (N=1 → N=2 → N=3 → L-rule)
- The secrets-class meta-rule (skip-3-strike for irreversible classes)
- The substrate-class classifier (production / protection / test-fixture / self-documentation / audit-ledger)
- The cross-orchestrator bilateral protocol (inbox/outbox discipline)
- The doctor/health/repair CLI triad

**Doctrines (after de-personalization):**
- Cross-repo write path discipline
- Closure-evidence contract version anchor (L154)
- Closure-evidence public lens anchor (L155)
- Inbox discipline 0th-probe (L156)
- Outbox discipline cross-orch ship notification (L157)
- Substrate-class classifier (L162; v0.2)
- ... (full list pending de-personalization sweep)

**Safety hooks (engine-distributed):**
- `~/.claude/hooks/pretooluse-bash-secret-guard.sh`
- `~/.claude/hooks/pretooluse-write-edit-cross-repo-guard.sh`
- `~/.claude/hooks/pretooluse-bash-cross-repo-guard.sh`
- `~/.claude/hooks/posttooluse-bash-secret-redact.sh`
- (registration template for `~/.claude/settings.json`)

**Scripts (engine-distributed):**
- Installer (`install.sh`)
- Uninstaller (`uninstall.sh`)
- Doctor / health / repair scaffolds
- Beads, NTM wrappers

**Universal memory rules (after sweep):**
- ~50-60 memory rules generalize cleanly to universal patterns
- These become published reference patterns in the engine

### Overlay (private; never published)

**Personal anchors:**
- `MISSION.md` — your mission statement, your goals
- `projects.yaml` — your project list and metadata
- `clients.yaml` — your client roster (if applicable)

**Personal trauma corpus:**
- Per-incident memory rules with dates, panes, repos, clients
- `fuckup-log.jsonl` — your fuckup ledger
- Cross-orch handoff history

**Personal infrastructure identifiers:**
- Infisical project IDs
- Supabase project refs
- Vercel project IDs
- Deploy target URLs
- API keys (never anywhere; these go in your secrets manager)

**Personal project state:**
- `.beads/issues.jsonl` per project
- `.flywheel/dispatch-log.jsonl` per project
- `.flywheel/audit/*` per project
- `.flywheel/evidence/*` per project

## How users compose

The intended user experience:

1. **Install the engine.** `curl -sSL https://flywheel.zeststream.ai/install.sh | bash` puts the public engine at `~/.flywheel/engine/` (or similar; final path TBD).

2. **Initialize their overlay.** `flywheel init` walks them through composing their personal `MISSION.md`, their project list, their orchestrator pane preferences. Writes to `~/.flywheel/private/`.

3. **Initialize a project.** `cd ~/Developer/myproject && flywheel project-init` creates a `.flywheel/` directory in the project with project-level overlay.

4. **Start a cycle.** `/flywheel:plan "what we're building"` reads the mission anchor, reads the engine doctrines, reads the project overlay, and produces a plan.

## What this means for existing flywheel installations

For Joshua's current installation (which contains both engine + overlay mixed together), the path to clean separation is:

1. **Sweep engine candidates** — identify all `.flywheel/doctrine/*.md`, `.flywheel/rules/*.md`, memory rules, scripts, hooks that classify as engine
2. **De-personalize the engine candidates** — replace specific names with placeholders (`Joshua` → `{operator}`, client names → `{client-A}`, etc.)
3. **Extract** — copy de-personalized engine artifacts into the public repo (`zeststream-flywheel/` or similar)
4. **Reference back** — the original installation references the engine via symlink or version-pinned import; overlay stays in place
5. **Verify** — run flywheel against the engine + overlay composition; confirm everything still works

This is the *de-Joshua-ification sweep* mentioned in the architecture spec. It's a Wave 2 deliverable.

## Honest status of the boundary today

| Aspect | Status |
|---|---|
| Engine/overlay paradigm documented | ✓ (this document, v0.1) |
| Engine artifacts identified | ~80% (this document's lists are approximate) |
| De-personalization sweep | ⏳ Wave 2 |
| Filesystem split materialized | ⏳ Wave 2 |
| Installer that composes engine + user-supplied overlay | ⏳ Wave 2 |
| Public repo extracted from monorepo | ⏳ Wave 3 |

The current single-repo installation works fine; the split is for adoption-friendliness, not because the current state is broken.

## Edge cases worth surfacing

**Memory rules in the gray zone.** Some memory rules are *universal in shape but instance-anchored in content* (e.g., a rule about "orchestrator behavior X" that uses a specific past incident as the example). These get de-personalized and become engine; the original instance-anchored version is preserved in overlay-private.

**Trauma class definitions.** The *class* of trauma (e.g., "cross-repo write clobber") is engine. The *instances* (e.g., "skillos:1 at 2026-05-12T09:51Z") are overlay. The L-rule is engine.

**Doctrines that document specific systems.** A doctrine about "how we coordinate skillos:1 + flywheel:1 + mobile-eats:1" is overlay-class as written. The *pattern* it describes (bilateral cross-orch protocol) is engine — and that's what gets published.

**Skills that wrap user-specific paths.** A skill that hardcodes `~/Developer/<specific-project>/` is overlay. Re-author with parameterization; it becomes engine.

---

*This document is part of the flywheel ecosystem. The de-Joshua-ification sweep that materializes this boundary is tracked in the Wave 2 work plan.*
