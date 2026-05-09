## L100 — IDENTITY-PRIMARY-KEY-IS-SESSION-PANE-PROJECT

---
id: L100
title: Identity primary key is session pane project
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: agent-mail-identity-name-churn
---

Agent Mail identity substrate MUST key durable ownership by
`(session, pane, fleet_mail_project_key)`. `identity_name` is only the current
pointer attached to that tuple. Rotating the name may update the pointer, token
path, predecessor chain, and rotation reason, but it MUST NOT create a new
logical identity owner.

**Why:** CoralRaven's 2026-05-04 gap report showed six independent triggers
rotating names while the actual owner stayed stable: name-policy enforcement,
resolver-MCP generated names, compaction continuity, missing-token recovery,
path canonicalization, and Agent Mail strict-mode preallocation. Counting the
name as the identity created churn, orphan-token residue, cross-session false
halts, and agent-shaming narratives. Donella #5 and #6: change the rule and
surface the right stock/flow metrics.

**How to apply:**
- Registry rows carry `identity_primary_key` and `identity_primary_key_text`
  derived from session, pane, and fleet mail project.
- Rotations preserve `predecessor_identity_chain[]`; allowed
  `rotation_reason` values are `agent-mail-name-policy`,
  `resolver-mcp-generated-identity`, `compaction-continuity`,
  `missing-token-recovery`, `path-canonicalization`, and
  `strict-mode-preallocation`.
- Rotation transactions clean predecessor token residue immediately or surface
  `orphan_tokens_unswept_count`.
- `flywheel-loop doctor --json` exposes `identity_rotation_count_24h`,
  `orphan_tokens_unswept_count`, and `identity_chain_max_length`.
- High churn is an architecture-health signal, never an individual agent score.

**Forbidden outputs:**
- Treating an adjective+noun mailbox name as the durable primary key.
- Minting a new logical identity owner for a known session/pane/project tuple.
- Reporting identity churn as agent failure rather than substrate churn.
- Sending raw Agent Mail tokens through cross-orch coordination while repairing
  tuple drift.

**Cross-references:** L58 (secret material never in pane text), L76
(AgentMail identity canonical), L92 (audit findings route by data), L96
(doctrine three-surface diff), L98 (architecture-health frame), and memory
`feedback_identity_stability_session_pane_project_primary_key.md`.

