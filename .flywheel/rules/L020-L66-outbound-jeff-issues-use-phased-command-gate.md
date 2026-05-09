## L66 — OUTBOUND-JEFF-ISSUES-USE-PHASED-COMMAND-GATE

---
id: L66
title: Outbound Jeff issues use phased command gate
status: long_term
shipped: 2026-05-03
review_due: 2026-11-09
trauma_class: jeff-issue-gate-bypass
---


Issues filed to Jeff's repos are part of the flywheel substrate, not casual
GitHub comments. Every future outbound Jeff issue MUST pass through the phased
`/flywheel:jeff-issue` process once implemented, or an equivalent ledger that
proves the same phases.

**Reason:** `mcp_agent_mail#154` passed a 7-axis quality rubric and was a good
issue, but the path bypassed three older canonical proposal artifacts:
G82 source probing, the Jeff issue template, and outbound issue tracking. A
rubric alone catches issue quality; it does not guarantee source freshness,
template discipline, Joshua approval, post-submit body verification, and watcher
registration.

**How to apply:**
- Before drafting: run the source-probe phase against the target repo, local
  clone, issue dedup searches, and command identities.
- Draft with the Jeff issue template unless recent repo tone evidence justifies
  a tighter shape.
- Run the 7-axis rubric from a phase ledger, not from memory.
- Submission requires Joshua approval, idempotency key, non-empty post-submit
  body verification, and outbound tracker registration.
- If the command does not exist yet, workers must write the same phase ledger in
  their receipt and file/update the implementation bead rather than filing ad
  hoc.

**Forbidden outputs:**
- Filing a Jeff issue from a one-off dispatch checklist with no source-probe
  ledger.
- Treating "7/7 rubric PASS" as sufficient when dedup, tracker, or Joshua gate
  evidence is missing.
- Submitting an issue before verifying the posted body is non-empty.
- Filing without updating the outbound issue memory/tracker or giving an
  explicit no-track reason.

**Evidence:** bead `flywheel-svi6`; design artifacts in
`/tmp/jeff-issue-process-DESIGN/`; `mcp_agent_mail#154` receipt
`/tmp/jeff-upstream-token-echo-issue_findings.md`; proposals
`G82-jeff-doctrine-source-probe-2026-04-27.md`,
`jeff-issue-template-2026-04-30.md`, and
`outbound-issue-tracker-phase3-2026-04-30.md`.

**Companion rules:** L61 ecosystem touch, L63 Jeff substrate dependency, L64
Jeff-as-mentor pattern mining, L65 CLI identity proof, and
`dicklesworthstone-stack` skill issue protocol.

