---
title: "Phase 3 AUDIT — Findings Register + Joshua-Disposes"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 3 AUDIT — Findings Register + Joshua-Disposes

Plan: `agent-security-controls-fleet-wide-2026-05-04`
Phase 3 status: ✅ CONVERGED (r1 + r2, 2/2 zero-new-critical streak)
Pause: ⏸ MANDATORY Joshua-disposes before Phase 4 DECOMPOSE creates beads

## Round summary

| Round | Lens | Findings | Critical | High | Joshua-decisions |
|---|---|---|---|---|---|
| r1 | 1. security cross-cutting | 10 | 0 | 5 | 2 |
| r1 | 2. idempotency | 10 | 0 | 4 | 1 |
| r1 | 3. cross-runtime parity | 10 | 0 | 6 | 2 |
| r2 | consolidated convergence pass | 0 NEW | 0 | 0 | 0 |
| **Total** | | **30** | **0** | **15** | **5** |

Convergence verdict: r2 produced 0 new criticals + 0 new highs against r1's index of 30 findings — r1 ceiling confirmed.

## High-severity findings requiring bead amendments (15)

### Lens 1 — security cross-cutting (5 high)

- **F1** override-bypass — JSON override schema undefined; broad/wildcard overrides could neutralize deny block. Mitigates B01/B04/B09.
- **F2** runtime-output leak — `.env.test` doesn't test inherited parent-process env, child-process env dumps, debug logs, or pane capture. Mitigates B06/B09.
- **F3** singleton-trust — settings precedence not enumerated; permissive `settings.local.json` could override canonical block. Mitigates B01/B03/B04.
- **F7** container escape — B08 only enumerates `.env` mount; missing `~/.aws`, `~/.ssh`, infisical, MCP configs, browser profiles, host `$HOME`. Mitigates B08/B09.
- **F8** cross-orch token capture — pane scrub catches scrollback but not `/tmp/dispatch_*`, dispatch logs, callback payloads, ntm-send prompt files. Mitigates B04/B05/B09.

### Lens 2 — idempotency (4 high)

- I1, I2, I3, I4 — see `03-AUDIT-r1-lens2-idempotency.md` for details. Themes: re-apply safety, partial-failure resume, receipt collision, doctor-signal idempotency.

### Lens 3 — cross-runtime parity (6 high)

- P1-P10 — see `03-AUDIT-r1-lens3-cross-runtime-parity.md`. Themes: Claude vs Codex settings honor, MCP-spawned subprocess deny scope, agent-mail token redaction parity across runtimes, conformance harness coverage gap.

## Joshua-disposes decisions needed (5)

1. **F1** — Should security overrides for live secret paths be **disabled** until the JSONL override schema + strict doctor checks land? (Conservative: yes; ergonomic: no with risk_ack=true required)

2. **F10** — Should auth-marker expiry be a **hard abort before the next repo mutation** mid-rollout, even if that leaves a partial rollout requiring rollback/resume? (Conservative: yes; pragmatic: no, allow grace window)

3. **I-Joshua** — see Lens 2 artifact — idempotency-related decision (typically: idempotency-key required vs auto-generated)

4. **P-Joshua-1** — see Lens 3 artifact — cross-runtime decision (typically: which runtime is canonical for settings precedence)

5. **P-Joshua-2** — see Lens 3 artifact — MCP-spawned-process scope decision

## Recommendation to Joshua

All 30 findings are mitigatable via amendments to existing beads B01-B09 + 1 candidate new bead (cross-orch payload scrub) flagged in F8 if Lens 3 reaches same conclusion (it does — see P-related findings).

**Recommended path:** approve all 5 conservative defaults (yes/yes/required/canonical=Claude/include MCP). Phase 4 DECOMPOSE then creates the bead set with these amendments baked in.

**If you want to override** any default, write your decision in `03-AUDIT-FINDINGS-DECISIONS.md` (one-line per finding) and resume with `/flywheel:plan --resume agent-security-controls-fleet-wide-2026-05-04`.

## Phase 3 artifact pointers

- `03-AUDIT-r1-lens1-security.md` — 204 lines, 10 findings
- `03-AUDIT-r1-lens2-idempotency.md` — 211 lines, 10 findings
- `03-AUDIT-r1-lens3-cross-runtime-parity.md` — 217 lines, 10 findings
- `03-AUDIT-r2.md` — 180 lines, convergence pass (0 new findings)
- `00-PLAN.md` — 436 lines, converged Phase 2 plan being audited
