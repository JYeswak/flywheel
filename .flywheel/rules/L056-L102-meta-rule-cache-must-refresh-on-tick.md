## L102 — META-RULE-CACHE-MUST-REFRESH-ON-TICK

---
id: L102
title: META-RULE cache must refresh on every tick
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: fleet-meta-rule-propagation-drift
---

Every tick driver MUST run the canonical META-RULE sync at tick start so that
`<repo>/.flywheel/META-RULE-CACHE.md` mirrors
`/Users/josh/.flywheel/canonical-meta-rules/INDEX.md` (plus the four
`feedback_*.md` rules) on every cycle. Sister orchestrators that share the same
tick driver (flywheel, alpsinsurance, skillos, mobile-eats, vrtx) inherit fleet
META-RULE freshness by construction — no per-repo doctrine edit is required.

**Why:** Prior fleet propagation relied on broadcast capsules + manual
re-reads. Capsules drift, panes compact, sessions reboot. Bake the sync into
the tick path and the canonical META-RULE bundle becomes a stock the tick
keeps refilled, not a flow that has to be remembered (Donella #4 self-organize
+ #6 information). New ntm sessions onboarded after 2026-05-04 inherit the 4
fleet META-RULEs at install time via the `/flywheel:onboard` step.

**How to apply:**
- `flywheel-loop-tick` invokes `/Users/josh/.flywheel/canonical-meta-rules/sync.sh --apply --json`
  immediately after the canonical-doctrine-pull step; result emits as
  `event:"meta_rule_cache_sync"` in the per-tick log.
- `/flywheel:onboard` installs the canonical META-RULE-CACHE on first run
  and stamps the loop record with `meta_rule_sync_enabled: true`.
- Doctor probe `fleet-canonical-rule-freshness-probe.sh --json` reports
  per-session `lag_seconds` + `status` (fresh|stale|missing); follow-up bead
  threads `fleet_canonical_rule_freshness_seconds_max` into doctor JSON.
- Touching the canonical INDEX.md is enough to trigger fleet-wide refresh on
  the next tick across every session running this driver.

**Forbidden outputs:**
- Editing per-repo META-RULE files directly instead of the canonical bundle.
- Skipping the sync step on tick to "save time" — the sync is a few ms.
- Treating the cache as documentation; it is the live freshness substrate.
- Onboarding a new ntm session without running the META-RULE install step.

**Cross-references:** L96 (doctrine-3-surface-diff), L98
(architecture-health-measured-not-individuals), and the canonical-meta-rules
broadcast 2026-05-04. Probe at
`.flywheel/scripts/fleet-canonical-rule-freshness-probe.sh`.

