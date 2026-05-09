## L119 — TEMPLATES-NAME-SOURCES-NOT-VALUES

---
id: L119
title: Templates name sources, not values
status: long_term
shipped: 2026-05-06
review_due: 2026-11-06
trauma_class: frozen-projection-of-mutable-state
---

Templates name sources, not values.
Any cron, launchd, watcher, scheduler, or dispatch template that references
mutable state must name the authoritative source path and field selector,
never copy the current field value into prompt text.
The receiving pane or agent must read the source at execution time and cite
the path in closeout.
Literal sampled values are allowed only when the value is immutable by
construction or a receipt names why sampling is intentional.
Doctor must count mutable-state literals in prompt templates and fail strict
mode when the count is nonzero.

Canonical token: `templates-name-sources-not-values`.

**Why:** A frozen projection of mutable state is a long-lived prompt, plist,
cron payload, watcher, scheduler, or dispatch template that captured a value at
render/install time and later acted as if that value were still authoritative.
The orch-uptime topology-stale gate, skillos cron-literal blocker payload, and
mobile-eats cached pane metrics all hit the same trauma class:
`frozen-projection-of-mutable-state`.

**How to apply:**
- Long-lived templates may name source paths, selectors, query names, schema
  fields, immutable hashes/version IDs, command names, static repo paths, and
  documented constant labels.
- They MUST NOT bake mutable blocker IDs, active profile names, pane roles or
  IDs, topology rows, freshness timestamps, secret values, current owner names,
  or current recovery decisions into payloads when those values can change
  before fire time.
- At execution time, the receiving pane or agent reads the named source and
  cites the path/selector in closeout.
- Intentional sampling requires a receipt naming why the value is immutable or
  why sampling is safe for the payload lifetime.
- Doctor invariant scans count mutable-state literals in prompt templates;
  existing debt may warn, newly modified templates fail strict mode.

**Forbidden outputs:**
- Installing a cron, launchd plist, watcher, scheduler, or dispatch packet that
  copies current mutable values instead of naming source paths/selectors.
- Treating a rendered prompt, topology row, active CAAM profile, blocker id, or
  recovery decision as durable truth after its source may have changed.
- Claiming a driver is refreshed when its payload can only replay values
  captured at install time.
- Embedding secret values or token fragments in templates; name vault paths or
  secret classes instead per SEC-001.

**Evidence:** Orch-uptime Lane C; skillos Option C Hybrid watcher +
heartbeat-cron fix; cross-orch handoff row 203
`blocker_class=frozen-projection-of-mutable-state`; mobile-eats sibling
topology/cached-metrics pattern.

**Cross-references:** SEC-001 mission-lock secret-values rule, L57
(loop-state marker is not driver), L110 (substrate primitives declare
self-repair loop), and L116 (tick is process, not document).

