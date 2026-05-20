# Substrate-Class Classifier — Meadows L2 Paradigm Primitive

**Status:** v0.2 promoted — 2026-05-15 by Codex
**L-rule:** L162 (standard 3-strike cadence; N=3 reached 2026-05-14 on secret-bank fixture trip; NOT secrets-class exemption)
**Owning bead:** flywheel-substrate-class-paradigm (parent)
**Substrate class of this document:** `self-documentation`

---

## Why this exists

Three recent traumas share one paradigm failure shape — the system cannot distinguish its own self-referential substrate from the production substrate it protects:

| Trauma | When | Surface | Root |
|---|---|---|---|
| N=3 SATURATION propagator clobber | 2026-05-12T03:36Z | Propagator scripts clobbered 9 skillos canonical doctrine files | Mitigation document authored AT the path it documents protecting |
| L160 hook fires on its own AKID test fixture | 2026-05-12 (N=2 today) | PostToolUse hook halts agentic loop on canonical synthetic `AKIA…` sentinel | Detector cannot recognize its own test corpus |
| 425 dirty files + 677 commits ahead in flywheel repo | accreted over weeks | Flywheel orchestrates client repos with discipline; can't keep its own | Cobbler's children — orchestrator exempt from its own standard |

Per Donella Meadows' systems-thinking and leverage-points work: **when a system's mitigation has to be applied INSIDE the same boundary it's trying to protect, the abstraction is wrong.**

Adding more rules (L5), more negative feedback (L8), or bigger buffers (L11) **does not fix this**. The fix lives at L2 — the paradigm out of which the system arises.

## The paradigm primitive

**Every artifact in the flywheel ecosystem carries a `substrate_class`.** Protection mechanisms consult this class before halting.

### The five classes

| Class | Description | Examples | Protection behavior |
|---|---|---|---|
| `production` | Load-bearing user-facing content, AaaS deliverables, doctrine published to clients, canonical worker output | `~/Developer/zesttube/`, client doctrine, AaaS report PDFs, customer-facing CLIs | Full protection: secret-detect halts; gitleaks blocks; DCG enforces |
| `protection` | The detector/hook/gate code that protects production | `~/.claude/hooks/posttooluse-bash-secret-redact.sh`, gitleaks config, pre-commit guards, DCG rules, this manifest | **Self-exempt** — protection cannot trip on itself; reading the regex source is not a leak |
| `test-fixture` | Synthetic content that exercises protection code | `tests/test_ntm_coordinator_wire.sh:110` synthetic AKID, `.flywheel/security/v1/secret-patterns.json` corpus, mock credentials | Path-or-marker allowlist; protection acknowledges the match with `SUPPRESSED_SYNTHETIC_MATCH` event-class without halting the agentic loop |
| `self-documentation` | Doctrine documenting protection mechanisms; describes patterns it does not embody | This file; `.flywheel/doctrine/cross-repo-write-path-discipline.md` (which documents the propagator gate) | Read-only protection: cannot be propagated to peer repos as if canonical of the peer |
| `audit-ledger` | Receipts of protection firing; dispatch logs; fuckup logs; leak ledgers | `~/.claude/secret-leak-ledger.jsonl`, `.flywheel/dispatch-log.jsonl`, `~/.local/state/flywheel/fuckup-log.jsonl` | Append-only; logging own writes does not recurse (self-exempt by paradigm design) |

### The classification rule

A protection mechanism (hook, gate, detector) executes this check before deciding to halt:

```
on shape-match:
    substrate_class = classify(artifact_path, matched_value)
    case substrate_class:
        production       → HALT (current behavior preserved)
        protection       → SUPPRESS (silent; would otherwise recurse)
        test-fixture     → SUPPRESS + log SUPPRESSED_SYNTHETIC_MATCH event
        self-documentation → SUPPRESS (it describes the pattern, doesn't embody it)
        audit-ledger     → SUPPRESS (we're reading our own history)
        UNKNOWN          → HALT (default-deny; require explicit class declaration)
```

`classify()` consults `.flywheel/security/v1/substrate-class-manifest.json`. UNKNOWN halts ensure default-deny — new files must be classified, not assumed.

## How this dissolves the three traumas

| Trauma | Pre-paradigm | Post-paradigm |
|---|---|---|
| Propagator clobber | Propagator assumes flywheel-canonical → peer-canonical | Propagator checks peer-side `substrate_class=production`; if peer-owned, refuses write |
| L160 fires on test fixture | Hook trips on AKID shape regardless of context | Hook checks substrate_class of file in command; `test-fixture` paths → suppress + log |
| Cobbler's children dirty tree | Flywheel exempt from its own discipline because "orchestrator role" | Flywheel artifacts MUST declare substrate_class; `unclassified` count is the alarm; close-out receipts include `git_hygiene` block |

## The recursion terminator

This manifest declares itself `protection`, listed in its own `protection_paths`. The manifest's existence is self-exempt by design — there is no "manifest of the manifest" needed. Recursion terminates at the paradigm level, not via special-case logic.

The Meadows mirror-stage check that prevents recurrence-of-the-recurrence:

> **Every new mechanism declares its own substrate_class at the moment of creation, not retrofit later.**

A new launchd job, a new doctrine doc, a new audit ledger — each MUST carry a `substrate_class` declaration in its frontmatter or a manifest entry. The retention/protection/propagation behavior follows from the class automatically.

## Downstream cascades

Once the L2 paradigm primitive ships, the L3–L12 cascades fall out for free:

- **L3 Goals:** MISSION.md amendment — *"Repo hygiene is mission-critical infrastructure of the AaaS product."* The cobbler now wears shoes.
- **L4 Self-organization:** `.gitignore` auto-extends when sibling project of shape `<basename>__<word>_<word>/` appears with declared `substrate_class=external-tool-scratch`. Skill arsenal auto-discovers new skills via SKILL.md frontmatter.
- **L5 Rules:** L120 worker close requires `{git_committed, untracked_delta, substrate_classified}`. L156/L157 cross-orch contracts extend to declare substrate-class of every shipped artifact.
- **L6 Information flows:** Daily-report surfaces `{production_dirty, test_fixture_dirty, audit_ledger_growth, unclassified}` — unclassified is the alarm; classified accretion is normal.
- **L7 Reinforcing feedback:** Sessions closing with `unclassified=0` earn substrate-quality credit; threshold-breached sessions cannot enter next dispatch wave until classified.
- **L8 Negative feedback:** Dispatch gate refuses new work when `production_dirty > 100 OR unclassified > 20`. Production class is the gated stock, not raw dirty count.
- **L9 Delays:** Hygiene probe runs every Nth tick AND on every protection-class halt fire (the system uses its own halts as signals).
- **L10 Stock-and-flow:** Retention launchd: handoffs/→30d, audit/→60d, evidence/→90d, doctrine/→keep-forever. All gated by substrate_class.
- **L11 Buffers:** Per-class buffer sizes declared AT creation (mirror-stage prevention).
- **L12 Numbers:** Tunable parameters at the bottom because they're least leverage.

## Sister rules

- `.flywheel/doctrine/cross-repo-write-path-discipline.md` (substrate_class=self-documentation) — the propagator gate this paradigm makes coherent
- `feedback_propagator_canonical_ownership_class_aware_gate.md` (memory) — the N=3 SATURATION feedback rule
- `feedback_secrets_class_skip_3_strike_gate.md` (memory) — the secrets-class exemption; this paradigm sits ABOVE it (substrate-class is more general than incident-class)
- L154 closure-evidence-contract-version-anchor
- L156/L157 inbox/outbox-discipline (cross-orch shipping)
- L160 agentic-loop-halt-via-posttooluse-hook (the firing mechanism this paradigm shapes)
- L161 operator-directed-mission-continuation-after-leak (the recovery path post-fire)

## Repo hygiene cross-reference (bszgl.1 — 2026-05-14)

Git state IS substrate state. Every session close must include a `git_hygiene` block (see `last_closeout_receipt.json` template). Unclassified file accretion is the same alarm class as unclassified substrate mutation — surface it, don't ignore it. See `.flywheel/MISSION.md` anchor extension 2026-05-14.

Gated-loop halt applies the same class framework: if a loop's blocker set is 100% `owner: external`, the loop is in the same state as an unclassifiable substrate — halt rather than mutate.

## Promotion criteria

This is **not secrets-class** (no irreversibility on incorrect classification — wrong calls are recoverable via re-classification). Standard 3-strike cadence applies:

| Strike | Date | Surface |
|---|---|---|
| N=1 | 2026-05-12 | L160 fires on synthetic AKID in `tests/test_ntm_coordinator_wire.sh:110` (first occurrence this session) |
| N=2 | 2026-05-12 | L160 fires again on same fixture in my secret-scan probe (this incident, ~4h later) |
| N=3 | 2026-05-14 | Hook fires on `.flywheel/tests/fixtures/ntm-scrub-secret-scan/secret-bank.txt` after the fixture was missing both marker and path coverage → SATURATION → canonical L162 promotion |

After N=3 SATURATION, this ships as canonical L162 rule +
flywheel-local doctrine + manifest. Cross-orch propagation still follows the
ownership-gated propagator path; peer repos adopt only through their declared
ownership class.


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
