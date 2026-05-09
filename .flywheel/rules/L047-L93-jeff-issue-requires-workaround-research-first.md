## L93 — JEFF-ISSUE-REQUIRES-WORKAROUND-RESEARCH-FIRST

---
id: L93
title: Jeff issue requires workaround research first
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: upstream-escalation-without-workaround-research
---

Before proposing or filing any Jeff upstream issue, the orchestrator MUST prove workaround research first. The receipt must show indexed-source mining across the failing repo and relevant Jeff dependency repos with at least 2-3 query phrasings and K>=10 results per query, at least five ranked workaround candidates with source citations, and copy-test receipts for the top two candidates on a disposable copy of the affected substrate. A Jeff issue is warranted only when all five or more workarounds fail copy-test, or when the bug is foundational and no workaround exists.

If a reversible workaround passes copy-test, apply the workaround through the repo's normal validation path and document the upstream evidence instead of filing. If filing is warranted, the issue body must include full repro steps, copy-test evidence for every failed workaround, environment factors such as concurrency, version, and live-vs-copy differences, and a fix direction framed as an observed contract gap rather than a prescriptive patch. L93 extends L66; L66's source-probe/rubric/submission gates are necessary but not sufficient without the workaround-research precondition.

**Why:** v2a1 REINDEX repair rolled back after only shallow attempts, and Joshua corrected the reflex to file a Jeff issue with the question: what workarounds do we have in indexed Jeff sources? The Jeff corpus is already load-bearing substrate, and prior issues show this distinction matters: frankensqlite#85 was intentional behavior with a workaround, while beads_rust#270 was a true upstream repair case only after evidence and dogfood receipt existed.

**How to apply:** any dispatch, callback, or draft containing `jeff issue`, `file upstream`, `Jeff-worthy`, or `escalate to Jeff` must link a preceding `*-workarounds-research-*` task or receipt from the last 24 hours. A mechanical validator may treat the receipt as eligible only when this predicate passes: `jq -e '(.socraticode_queries >= 2 and .socraticode_k_per_query >= 10) and (.workarounds_ranked >= 5) and (.top_workarounds_copy_tested >= 2) and ((.jeff_issue_warranted == false) or (.all_workarounds_failed == true or .foundational_no_workaround == true))'`. Doctor should expose `jeff_issue_pending_without_workaround_research_count`, target `0`, and the issue-filing hook should block when no qualifying workaround-research callback exists.

**2026-05-04 beads_rust dep-add note:** skillos hit `br dep add`
`OpenRead root page 184`, then `root page 121` after fresh JSONL rebuild. L93
prevented a duplicate upstream issue: the exact edge failed on installed
`br 0.1.20`, but passed on disposable `br 0.2.4`; direct SQL + flush + rebuild
also passed as a reversible fallback. Receipt:
`/tmp/beads-rust-dep-add-corruption-jeff-issue-output.md`.

**Cross-references:** L48 (substrate exhaustion before escalation), L63 (Jeff intel network), L64 (Jeff as mentor), L66 (outbound Jeff issue phased gate), L71 (validate-and-redispatch), L78 (Jeff corpus accretive ingestion), `feedback_jeff_issue_chain.md`, `feedback_jeff_issue_requires_full_workaround_research_first.md`, `reference_jeff_substrate_inventory.md`, `reference_upstream_issues.md`, and the `jeff-issue-chain` skill.

